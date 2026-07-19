import 'dart:async';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../error/app_exceptions.dart';
import '../network/api_client.dart';

class AiGatewayService {
  final ApiClient _apiClient;
  final int _maxRequestsPerMinute;
  final List<DateTime> _requestWindow = <DateTime>[];

  AiGatewayService({
    required ApiClient apiClient,
    int maxRequestsPerMinute = 30,
  })  : _apiClient = apiClient,
        _maxRequestsPerMinute = maxRequestsPerMinute;

  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required Map<String, dynamic> context,
    String? userId,
  }) async {
    _enforceRateLimit();

    final payload = {
      'message': message,
      'context': context,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };

    return _withRetry(() async {
      final response = await _apiClient.post(
        ApiEndpoints.aiChat,
        data: payload,
        timeout: AppConstants.aiApiTimeout,
      );
      if (response is Map<String, dynamic>) return response;
      throw const AIServiceException('Invalid AI gateway response format');
    });
  }

  Future<void> storeMemory({
    required String userQuestion,
    required String aiResponse,
    required String topic,
    required DateTime timestamp,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.aiMemoryStore,
        data: {
          'user_question': userQuestion,
          'ai_response': aiResponse,
          'topic': topic,
          'timestamp': timestamp.toIso8601String(),
        },
      );
    } catch (_) {
      // Memory sync is best effort and should not block user chat.
    }
  }

  Future<T> _withRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        if (attempts >= AppConstants.maxRetryAttempts) rethrow;
        await Future.delayed(
          AppConstants.retryBaseDelay * (1 << (attempts - 1)),
        );
      }
    }
  }

  void _enforceRateLimit() {
    final now = DateTime.now();
    _requestWindow.removeWhere(
      (time) => now.difference(time) > const Duration(minutes: 1),
    );
    if (_requestWindow.length >= _maxRequestsPerMinute) {
      throw const AIServiceException(
        'Too many AI requests. Please wait a moment and try again.',
        code: 'RATE_LIMIT_EXCEEDED',
      );
    }
    _requestWindow.add(now);
  }
}
