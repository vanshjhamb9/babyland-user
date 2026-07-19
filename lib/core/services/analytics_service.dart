import 'dart:developer' as dev;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized analytics and crash reporting service.
///
/// Integrates Firebase Analytics and Firebase Crashlytics.
class AnalyticsService {
  static AnalyticsService? _instance;

  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;

  AnalyticsService._();

  factory AnalyticsService() {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  Future<void> init() async {
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;

    // Crashlytics collection — global error hooks are set once in [main] (chained).
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ─── User Identification ────────────────────────────────

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setUserProperties({
    String? stage,
    String? subscriptionType,
  }) async {
    if (stage != null) {
      await _analytics.setUserProperty(name: 'pregnancy_stage', value: stage);
    }
    if (subscriptionType != null) {
      await _analytics.setUserProperty(
          name: 'subscription_type', value: subscriptionType);
    }
  }

  // ─── AI Chat Analytics ──────────────────────────────────

  Future<void> logAiChatSent({
    required String sessionId,
    int? messageLength,
  }) async {
    await _analytics.logEvent(
      name: 'ai_chat_message_sent',
      parameters: {
        'session_id': sessionId,
        'message_length': messageLength ?? 0,
      },
    );
  }

  Future<void> logAiChatReceived({
    required String traceId,
    required int latencyMs,
    required double evaluationScore,
    required String safetyStatus,
  }) async {
    await _analytics.logEvent(
      name: 'ai_chat_response_received',
      parameters: {
        'trace_id': traceId,
        'latency_ms': latencyMs,
        'evaluation_score': evaluationScore,
        'safety_status': safetyStatus,
      },
    );
  }

  Future<void> logAiFeedback({
    required String traceId,
    required String feedback,
  }) async {
    await _analytics.logEvent(
      name: 'ai_feedback_submitted',
      parameters: {
        'trace_id': traceId,
        'feedback': feedback,
      },
    );
  }

  Future<void> logAiVoiceInput() async {
    await _analytics.logEvent(name: 'ai_voice_input_used');
  }

  // ─── Feature Engagement ─────────────────────────────────

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logFeatureUsed(String featureName, {Map<String, dynamic>? params}) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': featureName,
        ...?params?.map((k, v) => MapEntry(k, v.toString())),
      },
    );
  }

  Future<void> logBookingCreated({required String doctorId}) async {
    await _analytics.logEvent(
      name: 'booking_created',
      parameters: {'doctor_id': doctorId},
    );
  }

  Future<void> logVideoCallStarted({required String sessionId}) async {
    await _analytics.logEvent(
      name: 'video_call_started',
      parameters: {'session_id': sessionId},
    );
  }

  // ─── Generic Event Logging ──────────────────────────────

  /// Logs a generic event (convenience method).
  static Future<void> logEvent(String eventName, {Map<String, dynamic>? params}) async {
    await FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: params?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  // ─── Error Reporting ────────────────────────────────────

  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason ?? 'Non-fatal error',
      fatal: fatal,
    );

    if (kDebugMode) {
      dev.log('Crashlytics error recorded: $error', name: 'Analytics');
    }
  }

  Future<void> logMessage(String message) async {
    await _crashlytics.log(message);
  }
}
