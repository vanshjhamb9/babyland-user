import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'app_exceptions.dart';

/// Centralized error handler for the application.
class ErrorHandler {
  ErrorHandler._();

  /// Converts any error into a user-friendly [AppException].
  static AppException handle(dynamic error) {
    if (error is AppException) return error;

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is SocketException) {
      return const NetworkException(
        'No internet connection. Please check your network.',
        code: 'NO_INTERNET',
      );
    }

    if (error is FormatException) {
      return NetworkException(
        'Invalid response format.',
        code: 'FORMAT_ERROR',
        originalError: error,
      );
    }

    return AppException(
      error.toString(),
      code: 'UNKNOWN',
      originalError: error,
    );
  }

  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timed out. Please try again.',
          statusCode: error.response?.statusCode,
          code: 'TIMEOUT',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final data = error.response?.data;
        String message = 'Something went wrong.';

        if (data is Map<String, dynamic>) {
          message = data['message']?.toString() ?? message;
        }

        if (statusCode == 401) {
          return AuthException(
            'Session expired. Please login again.',
            code: 'UNAUTHORIZED',
            originalError: error,
          );
        }

        if (statusCode == 403) {
          // Check if it's a subscription error
          if (data is Map<String, dynamic>) {
            final errorCode = data['error']?['code']?.toString().toLowerCase() ?? '';
            final errorMessage = message.toLowerCase();
            
            // Check for subscription-related error codes or messages
            if (errorCode.contains('subscription') ||
                errorCode.contains('premium') ||
                errorCode.contains('plan') ||
                errorCode.contains('purchase') ||
                errorCode.contains('upgrade') ||
                errorMessage.contains('subscription') ||
                errorMessage.contains('premium') ||
                errorMessage.contains('purchase') ||
                errorMessage.contains('upgrade') ||
                errorMessage.contains('not purchased') ||
                errorMessage.contains('requires subscription')) {
              return SubscriptionException(
                message.isNotEmpty ? message : 'This feature requires a subscription.',
                code: 'SUBSCRIPTION_REQUIRED',
                originalError: error,
              );
            }
          }
          
          return AuthException(
            'You don\'t have permission for this action.',
            code: 'FORBIDDEN',
            originalError: error,
          );
        }
        
        // Also check for subscription errors in 400 status codes
        if (statusCode == 400 && data is Map<String, dynamic>) {
          final errorCode = data['error']?['code']?.toString().toLowerCase() ?? '';
          final errorMessage = message.toLowerCase();
          
          if (errorCode.contains('subscription') ||
              errorCode.contains('premium') ||
              errorCode.contains('plan') ||
              errorMessage.contains('subscription') ||
              errorMessage.contains('premium') ||
              errorMessage.contains('not purchased') ||
              errorMessage.contains('requires subscription')) {
            return SubscriptionException(
              message.isNotEmpty ? message : 'This feature requires a subscription.',
              code: 'SUBSCRIPTION_REQUIRED',
              originalError: error,
            );
          }
        }

        if (statusCode == 429) {
          final retryAfter = error.response?.headers.value('retry-after');
          return NetworkException(
            retryAfter != null
                ? 'Too many requests. Please wait $retryAfter seconds.'
                : 'Too many requests. Please wait a moment and try again.',
            statusCode: statusCode,
            code: 'RATE_LIMIT_EXCEEDED',
            originalError: error,
          );
        }

        if (statusCode == 502 || statusCode == 503) {
          return AIServiceException(
            '${AppConstants.aiAssistantDisplayName} is temporarily unavailable. Please try again later.',
            code: 'AI_SERVICE_UNAVAILABLE',
            originalError: error,
          );
        }

        if (statusCode == 400) {
          // Extract validation errors if available
          Map<String, String>? fieldErrors;
          if (data is Map<String, dynamic>) {
            final errorData = data['error'] as Map<String, dynamic>?;
            if (errorData?['details'] is Map<String, dynamic>) {
              fieldErrors = (errorData!['details'] as Map<String, dynamic>)
                  .map((key, value) => MapEntry(key, value.toString()));
            }
          }
          return ValidationException(
            message,
            fieldErrors: fieldErrors,
            code: 'VALIDATION_ERROR',
          );
        }

        return NetworkException(
          message,
          statusCode: statusCode,
          code: 'HTTP_$statusCode',
          originalError: error,
        );

      case DioExceptionType.cancel:
        return const NetworkException(
          'Request was cancelled.',
          code: 'CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          'Could not connect to the server.',
          code: 'CONNECTION_ERROR',
        );

      default:
        return NetworkException(
          error.message ?? 'An unexpected error occurred.',
          code: 'UNKNOWN_DIO',
          originalError: error,
        );
    }
  }

  /// Logs error with full stack trace in debug mode.
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      log(
        'ERROR: $error',
        name: 'ErrorHandler',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Framework errors (after Crashlytics records them in [main]).
  static void handleFlutterFrameworkError(FlutterErrorDetails details) {
    logError(details.exception, details.stack);
  }
}
