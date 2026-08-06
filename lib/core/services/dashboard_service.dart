import 'dart:async';

import '../constants/api_endpoints.dart';
import '../error/app_exceptions.dart';
import '../error/error_handler.dart';
import '../network/api_client.dart';

/// Dashboard data model
class DashboardData {
  final HealthSummary healthSummary;
  final List<AIInsight> aiInsights;
  final List<PredictiveAlert> predictiveAlerts;
  final List<Recommendation> recommendations;
  final DateTime lastUpdated;

  DashboardData({
    required this.healthSummary,
    this.aiInsights = const [],
    this.predictiveAlerts = const [],
    this.recommendations = const [],
    required this.lastUpdated,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return DashboardData(
      healthSummary: HealthSummary.fromJson(data['healthSummary'] ?? data),
      aiInsights:
          (data['aiInsights'] as List<dynamic>?)
              ?.map((e) => AIInsight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      predictiveAlerts:
          (data['predictiveAlerts'] as List<dynamic>?)
              ?.map((e) => PredictiveAlert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations:
          (data['recommendations'] as List<dynamic>?)
              ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.parse(data['lastUpdated'])
          : DateTime.now(),
    );
  }

  factory DashboardData.empty() {
    return DashboardData(
      healthSummary: HealthSummary(
        hydration: HydrationSummary(today: 0, weeklyAverage: 0, goal: 2500),
        sleep: SleepSummary(lastNight: 0, weeklyAverage: 0, goal: 480),
        symptoms: SymptomSummary(activeCount: 0),
        medications: MedicationSummary(todayCount: 0),
        supplements: SupplementSummary(todayCount: 0),
      ),
      lastUpdated: DateTime.now(),
    );
  }
}

/// Health summary model
class HealthSummary {
  final HydrationSummary hydration;
  final SleepSummary sleep;
  final SymptomSummary symptoms;
  final MedicationSummary medications;
  final SupplementSummary supplements;
  final BabyGrowthSummary? babyGrowth;
  final PostpartumRecoverySummary? postpartumRecovery;

  HealthSummary({
    required this.hydration,
    required this.sleep,
    required this.symptoms,
    required this.medications,
    required this.supplements,
    this.babyGrowth,
    this.postpartumRecovery,
  });

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      hydration: HydrationSummary.fromJson(json['hydration'] ?? {}),
      sleep: SleepSummary.fromJson(json['sleep'] ?? {}),
      symptoms: SymptomSummary.fromJson(json['symptoms'] ?? {}),
      medications: MedicationSummary.fromJson(json['medications'] ?? {}),
      supplements: SupplementSummary.fromJson(json['supplements'] ?? {}),
      babyGrowth: json['babyGrowth'] != null
          ? BabyGrowthSummary.fromJson(json['babyGrowth'])
          : null,
      postpartumRecovery: json['postpartumRecovery'] != null
          ? PostpartumRecoverySummary.fromJson(json['postpartumRecovery'])
          : null,
    );
  }
}

class PostpartumRecoverySummary {
  final double physicalHealingScore;
  final double uterineRecoveryScore;
  final double energyStrengthScore;
  final double overallScore;
  final bool alertsTriggered;
  final String? physicalStatus;
  final String? uterineStatus;
  final String? energyStatus;

  PostpartumRecoverySummary({
    required this.physicalHealingScore,
    required this.uterineRecoveryScore,
    required this.energyStrengthScore,
    this.overallScore = 0.0,
    this.alertsTriggered = false,
    this.physicalStatus,
    this.uterineStatus,
    this.energyStatus,
  });

  factory PostpartumRecoverySummary.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested 'scores' structure from backend
    final scores = json['scores'] as Map<String, dynamic>?;

    return PostpartumRecoverySummary(
      physicalHealingScore:
          (scores?['physicalScore'] ?? json['physicalHealingScore'] as num?)
              ?.toDouble() ??
          0.0,
      uterineRecoveryScore:
          (json['uterineRecoveryScore'] as num?)?.toDouble() ?? 0.0,
      energyStrengthScore:
          (json['energyStrengthScore'] as num?)?.toDouble() ?? 0.0,
      overallScore:
          (scores?['overallScore'] ?? json['overallScore'] as num?)
              ?.toDouble() ??
          0.0,
      alertsTriggered: json['alertsTriggered'] as bool? ?? false,
      physicalStatus: json['physicalStatus']?.toString(),
      uterineStatus: json['uterineStatus']?.toString(),
      energyStatus: json['energyStatus']?.toString(),
    );
  }
}

class HydrationSummary {
  final int today;
  final double weeklyAverage;
  final int goal;
  final String trend;

  HydrationSummary({
    required this.today,
    required this.weeklyAverage,
    required this.goal,
    this.trend = 'stable',
  });

  factory HydrationSummary.fromJson(Map<String, dynamic> json) {
    return HydrationSummary(
      today: (json['today'] as num?)?.toInt() ?? 0,
      weeklyAverage: (json['weeklyAverage'] as num?)?.toDouble() ?? 0.0,
      goal: (json['goal'] as num?)?.toInt() ?? 2500,
      trend: json['trend']?.toString() ?? 'stable',
    );
  }
}

class SleepSummary {
  final int lastNight;
  final double weeklyAverage;
  final int goal;
  final double quality;

  SleepSummary({
    required this.lastNight,
    required this.weeklyAverage,
    required this.goal,
    this.quality = 0.0,
  });

  factory SleepSummary.fromJson(Map<String, dynamic> json) {
    return SleepSummary(
      lastNight: (json['lastNight'] as num?)?.toInt() ?? 0,
      weeklyAverage: (json['weeklyAverage'] as num?)?.toDouble() ?? 0.0,
      goal: (json['goal'] as num?)?.toInt() ?? 480,
      quality: (json['quality'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SymptomSummary {
  final int activeCount;
  final List<String> recent;

  SymptomSummary({required this.activeCount, this.recent = const []});

  factory SymptomSummary.fromJson(Map<String, dynamic> json) {
    return SymptomSummary(
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      recent:
          (json['recent'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class MedicationSummary {
  final int todayCount;
  final double compliance;

  MedicationSummary({required this.todayCount, this.compliance = 0.0});

  factory MedicationSummary.fromJson(Map<String, dynamic> json) {
    return MedicationSummary(
      todayCount: (json['todayCount'] as num?)?.toInt() ?? 0,
      compliance: (json['compliance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SupplementSummary {
  final int todayCount;
  final double compliance;

  SupplementSummary({required this.todayCount, this.compliance = 0.0});

  factory SupplementSummary.fromJson(Map<String, dynamic> json) {
    return SupplementSummary(
      todayCount: (json['todayCount'] as num?)?.toInt() ?? 0,
      compliance: (json['compliance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BabyGrowthSummary {
  final double? latestWeight;
  final double? latestHeight;
  final DateTime? lastMeasurement;

  BabyGrowthSummary({
    this.latestWeight,
    this.latestHeight,
    this.lastMeasurement,
  });

  factory BabyGrowthSummary.fromJson(Map<String, dynamic> json) {
    return BabyGrowthSummary(
      latestWeight: (json['latestWeight'] as num?)?.toDouble(),
      latestHeight: (json['latestHeight'] as num?)?.toDouble(),
      lastMeasurement: json['lastMeasurement'] != null
          ? DateTime.parse(json['lastMeasurement'])
          : null,
    );
  }
}

class AIInsight {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime generatedAt;

  AIInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.generatedAt,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : DateTime.now(),
    );
  }
}

class PredictiveAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // "low", "medium", "high", "critical"
  final DateTime createdAt;

  PredictiveAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  factory PredictiveAlert.fromJson(Map<String, dynamic> json) {
    return PredictiveAlert(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'low',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Recommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final double confidence;

  Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.confidence = 0.0,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Service for dashboard data with real-time updates
class DashboardService {
  final ApiClient _apiClient;
  Timer? _pollingTimer;
  StreamController<DashboardData>? _dashboardStreamController;

  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get current dashboard data
  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.healthInsights);

      if (response is Map<String, dynamic>) {
        // FIXED: Support both success==true and direct data format
        if (response['success'] == true ||
            response.containsKey('healthSummary')) {
          return DashboardData.fromJson(response);
        }
      }
      // FIXED: Provide better error message with response type
      ErrorHandler.logError('Invalid health insights response: $response');
      return DashboardData.empty();
    } catch (e) {
      ErrorHandler.logError(e);
      return DashboardData.empty();
    }
  }

  /// Get predictive alerts
  Future<List<PredictiveAlert>> getPredictiveAlerts() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.predictiveAlerts);

      if (response is Map<String, dynamic> && response['success'] == true) {
        final data = response['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => PredictiveAlert.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      ErrorHandler.logError(e);
      return [];
    }
  }

  /// Get recommendations
  Future<List<Recommendation>> getRecommendations({
    String? category,
    int days = 30,
  }) async {
    try {
      final params = <String, dynamic>{'days': days};
      if (category != null) params['category'] = category;

      final response = await _apiClient.get(
        ApiEndpoints.recommendations,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final data = response['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      ErrorHandler.logError(e);
      return [];
    }
  }

  /// Start real-time dashboard updates via polling
  Stream<DashboardData> startRealTimeUpdates({
    Duration interval = const Duration(seconds: 10),
  }) {
    _dashboardStreamController ??= StreamController<DashboardData>.broadcast();

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      try {
        final data = await getDashboardData();
        _dashboardStreamController?.add(data);
      } catch (e) {
        ErrorHandler.logError(e);
        // Continue polling even on error
      }
    });

    // Initial fetch
    getDashboardData()
        .then((data) {
          _dashboardStreamController?.add(data);
        })
        .catchError((e) {
          ErrorHandler.logError(e);
        });

    return _dashboardStreamController!.stream;
  }

  /// Stop real-time updates
  void stopRealTimeUpdates() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _dashboardStreamController?.close();
    _dashboardStreamController = null;
  }

  /// Refresh dashboard data (manual trigger)
  Future<DashboardData> refresh() async {
    return getDashboardData();
  }

  /// Dispose resources
  void dispose() {
    stopRealTimeUpdates();
  }
}
