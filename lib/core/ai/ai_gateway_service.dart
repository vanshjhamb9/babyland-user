import 'dart:async';

import 'package:flutter/foundation.dart';

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
    String? conversationId,
  }) async {
    _enforceRateLimit();

    final slimContext = Map<String, dynamic>.from(context)
      ..remove('hydration_logs')
      ..remove('mental_logs')
      ..remove('menstrual_logs')
      ..remove('pregnancy_data');

    final payload = {
      'message': message,
      'context': slimContext,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      if (conversationId != null && conversationId.isNotEmpty)
        'conversationId': conversationId,
      if (conversationId != null && conversationId.isNotEmpty)
        'conversation_id': conversationId,
    };

    try {
      if (kDebugMode) {
        debugPrint('[IRA-AUDIT] POST ${ApiEndpoints.aiChat}');
      }
      return await _postChat(ApiEndpoints.aiChat, payload);
    } catch (e) {
      if (e is AIServiceException && e.code == 'RATE_LIMIT_EXCEEDED') {
        rethrow;
      }
      if (kDebugMode) {
        debugPrint(
          '[IRA-AUDIT] ${ApiEndpoints.aiChat} failed (${e.runtimeType}); trying ${ApiEndpoints.aiChatV1}',
        );
      }
      return _postChat(ApiEndpoints.aiChatV1, payload);
    }
  }

  Future<Map<String, dynamic>> _postChat(
    String url,
    Map<String, dynamic> payload,
  ) {
    return _withRetry(() async {
      final response = await _apiClient.post(
        url,
        data: payload,
        timeout: AppConstants.aiApiTimeout,
      );
      if (response is! Map) {
        throw const AIServiceException('Invalid AI gateway response format');
      }
      final map = Map<String, dynamic>.from(response);
      if (map['success'] == false) {
        throw AIServiceException(
          map['error']?.toString() ??
              map['message']?.toString() ??
              'AI request failed',
          code: 'AI_GATEWAY_ERROR',
        );
      }
      return map;
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
        if (e is AIServiceException &&
            (e.code == 'AI_GATEWAY_ERROR' ||
                e.code == 'RATE_LIMIT_EXCEEDED')) {
          rethrow;
        }
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
