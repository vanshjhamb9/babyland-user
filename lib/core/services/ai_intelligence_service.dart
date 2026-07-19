import 'dart:async';

import '../constants/api_endpoints.dart';
import '../error/app_exceptions.dart';
import '../error/error_handler.dart';
import '../network/api_client.dart';

/// AI Intelligence Service - Handles all AI intelligence endpoints
/// Recommendations, Predictive Alerts, Trends, Analysis, Insights
class AIIntelligenceService {
  final ApiClient _apiClient;
  final int _maxRequestsPerMinute = 30;
  final List<DateTime> _requestWindow = <DateTime>[];

  AIIntelligenceService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─── Rate Limiting ────────────────────────────────────────

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

  // ─── AI Recommendations ───────────────────────────────────

  /// Get AI recommendations
  /// 
  /// [days] - Number of days to analyze (default: 30)
  /// [category] - Optional category filter (nutrition, exercise, etc.)
  Future<List<AIRecommendation>> getRecommendations({
    int days = 30,
    String? category,
  }) async {
    try {
      _enforceRateLimit();

      final data = <String, dynamic>{'days': days};
      if (category != null) data['category'] = category;

      final response = await _apiClient.post(
        ApiEndpoints.aiRecommendations,
        data: data,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final recommendations = response['data'] as List<dynamic>? ?? [];
        return recommendations
            .map((e) => AIRecommendation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is AIServiceException) rethrow;
      throw AppException('Error fetching recommendations: $e');
    }
  }

  // ─── Predictive Alerts ─────────────────────────────────────

  /// Get predictive health alerts
  Future<List<PredictiveAlert>> getPredictiveAlerts() async {
    try {
      _enforceRateLimit();

      final response = await _apiClient.get(ApiEndpoints.aiPredictiveAlerts);

      if (response is Map<String, dynamic> && response['success'] == true) {
        final alerts = response['data'] as List<dynamic>? ?? [];
        return alerts
            .map((e) => PredictiveAlert.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is AIServiceException) rethrow;
      throw AppException('Error fetching predictive alerts: $e');
    }
  }

  // ─── Health Trends ─────────────────────────────────────────

  /// Get health trends analysis
  /// 
  /// [from] - Start date for trend analysis
  /// [to] - End date for trend analysis
  /// [metric] - Optional metric to analyze (hydration, sleep, etc.)
  Future<HealthTrends> getTrends({
    required DateTime from,
    required DateTime to,
    String? metric,
  }) async {
    try {
      _enforceRateLimit();

      final params = <String, dynamic>{
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      };
      if (metric != null) params['metric'] = metric;

      final response = await _apiClient.get(
        ApiEndpoints.aiTrends,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return HealthTrends.fromJson(response['data'] ?? response);
      }
      throw AppException('Failed to fetch health trends');
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is AIServiceException) rethrow;
      throw AppException('Error fetching health trends: $e');
    }
  }

  // ─── Health Analysis ───────────────────────────────────────

  /// Get comprehensive health analysis
  Future<HealthAnalysis> getAnalysis({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      _enforceRateLimit();

      final data = <String, dynamic>{};
      if (from != null) data['from'] = from.toIso8601String();
      if (to != null) data['to'] = to.toIso8601String();

      final response = await _apiClient.post(
        ApiEndpoints.aiAnalysis,
        data: data,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return HealthAnalysis.fromJson(response['data'] ?? response);
      }
      throw AppException('Failed to fetch health analysis');
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is AIServiceException) rethrow;
      throw AppException('Error fetching health analysis: $e');
    }
  }

  // ─── AI Insights ───────────────────────────────────────────

  /// Get AI-generated insights
  /// 
  /// [category] - Optional category filter
  Future<List<AIInsight>> getInsights({String? category}) async {
    try {
      _enforceRateLimit();

      final params = <String, dynamic>{};
      if (category != null) params['category'] = category;

      final response = await _apiClient.get(
        ApiEndpoints.aiInsights,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final insights = response['data'] as List<dynamic>? ?? 
                        response['insights'] as List<dynamic>? ?? [];
        return insights
            .map((e) => AIInsight.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is AIServiceException) rethrow;
      throw AppException('Error fetching AI insights: $e');
    }
  }
}

// ─── Models ──────────────────────────────────────────────────

class AIRecommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final double confidence;
  final String? source;
  final DateTime? createdAt;

  AIRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.confidence = 0.0,
    this.source,
    this.createdAt,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      source: json['source']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

class PredictiveAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // "low", "medium", "high", "critical"
  final DateTime createdAt;
  final bool dismissed;

  PredictiveAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.dismissed = false,
  });

  factory PredictiveAlert.fromJson(Map<String, dynamic> json) {
    return PredictiveAlert(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'low',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      dismissed: json['dismissed'] == true,
    );
  }
}

class HealthTrends {
  final Map<String, TrendData> trends;
  final String period;
  final DateTime analyzedAt;

  HealthTrends({
    required this.trends,
    required this.period,
    required this.analyzedAt,
  });

  factory HealthTrends.fromJson(Map<String, dynamic> json) {
    final trendsData = json['trends'] as Map<String, dynamic>? ?? {};
    return HealthTrends(
      trends: trendsData.map(
        (key, value) => MapEntry(
          key,
          TrendData.fromJson(value as Map<String, dynamic>),
        ),
      ),
      period: json['period']?.toString() ?? '',
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'])
          : DateTime.now(),
    );
  }
}

class TrendData {
  final String direction; // "increasing", "decreasing", "stable"
  final double changePercent;
  final List<DataPoint> dataPoints;

  TrendData({
    required this.direction,
    required this.changePercent,
    this.dataPoints = const [],
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      direction: json['direction']?.toString() ?? 'stable',
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
      dataPoints: (json['dataPoints'] as List<dynamic>?)
              ?.map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DataPoint {
  final DateTime date;
  final double value;

  DataPoint({
    required this.date,
    required this.value,
  });

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HealthAnalysis {
  final String summary;
  final List<String> keyFindings;
  final List<AIRecommendation> recommendations;
  final Map<String, dynamic> metrics;
  final DateTime analyzedAt;

  HealthAnalysis({
    required this.summary,
    this.keyFindings = const [],
    this.recommendations = const [],
    this.metrics = const {},
    required this.analyzedAt,
  });

  factory HealthAnalysis.fromJson(Map<String, dynamic> json) {
    return HealthAnalysis(
      summary: json['summary']?.toString() ?? '',
      keyFindings: (json['keyFindings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => AIRecommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'])
          : DateTime.now(),
    );
  }
}

class AIInsight {
  final String id;
  final String title;
  final String description;
  final String category;
  final double relevance;
  final DateTime generatedAt;

  AIInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.relevance = 0.0,
    required this.generatedAt,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : DateTime.now(),
    );
  }
}
