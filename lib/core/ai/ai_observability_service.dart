import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../services/analytics_service.dart';

class AiObservabilityService {
  final AnalyticsService _analyticsService;
  final ApiClient _apiClient;

  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  int _safetyViolations = 0;

  AiObservabilityService({
    required AnalyticsService analyticsService,
    required ApiClient apiClient,
  })  : _analyticsService = analyticsService,
        _apiClient = apiClient;

  Future<void> logEvent(Map<String, dynamic> event) async {
    _totalRequests += event['type'] == 'ai_request' ? 1 : 0;
    if (event['status']?.toString().toLowerCase() == 'success') {
      _successfulRequests += 1;
    } else if (event['status']?.toString().toLowerCase() == 'error') {
      _failedRequests += 1;
    }
    if (event['safety_violation'] == true) {
      _safetyViolations += 1;
    }

    final enrichedEvent = {
      ...event,
      'success_rate': successRate,
      'error_rate': errorRate,
      'safety_violations_total': _safetyViolations,
      'ts': DateTime.now().toIso8601String(),
    };

    // Firebase Analytics
    await _analyticsService.logFeatureUsed('ai_observability', params: {
      for (final entry in enrichedEvent.entries)
        entry.key: entry.value?.toString() ?? '',
    });

    // Crashlytics breadcrumbs for AI tracing
    await _analyticsService.logMessage('AI_EVENT: $enrichedEvent');

    // Backend Observer API (best effort)
    try {
      await _apiClient.post(
        ApiEndpoints.aiObserverEvent,
        data: enrichedEvent,
      );
    } catch (_) {
      // Keep observability non-blocking for user-facing requests.
    }
  }

  Future<void> logPerformanceDashboard({
    required int aiResponseTimeMs,
    required int screenRenderTimeMs,
    required double cacheHitRate,
    required double apiFailureRate,
  }) async {
    await logEvent({
      'type': 'performance_dashboard',
      'ai_response_time_ms': aiResponseTimeMs,
      'screen_render_time_ms': screenRenderTimeMs,
      'cache_hit_rate': cacheHitRate,
      'api_failure_rate': apiFailureRate,
      'status': 'success',
    });
  }

  double get successRate =>
      _totalRequests == 0 ? 0.0 : _successfulRequests / _totalRequests;
  double get errorRate =>
      _totalRequests == 0 ? 0.0 : _failedRequests / _totalRequests;
}
