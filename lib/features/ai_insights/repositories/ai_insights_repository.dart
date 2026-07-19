import 'dart:convert';
import 'dart:developer';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/ai_insight_model.dart';

/// Repository for AI insights and daily guidance data.
class AiInsightsRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;
  final ConnectivityService _connectivityService;

  static const _insightsCacheKey = 'ai_insights';
  static const _dailyGuidanceCacheKey = 'ai_daily_guidance';

  AiInsightsRepository({
    required ApiClient apiClient,
    required CacheService cacheService,
    required ConnectivityService connectivityService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService,
        _connectivityService = connectivityService;

  /// Fetches AI pregnancy insights from server or cache.
  Future<List<AiInsightModel>> getInsights() async {
    // Try cache first if offline
    if (!_connectivityService.isOnline) {
      return _getCachedInsights();
    }

    try {
      final response = await _apiClient.get(ApiEndpoints.aiInsights);

      if (response is Map<String, dynamic>) {
        final insightsList = (response['insights'] as List<dynamic>?)
                ?.map((e) => AiInsightModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        // Cache the results
        await _cacheService.put(
          _insightsCacheKey,
          jsonEncode(insightsList.map((e) => e.toJson()).toList()),
          expiry: const Duration(hours: 6),
        );

        return insightsList;
      }

      return _getCachedInsights();
    } catch (e) {
      log('Error fetching insights: $e', name: 'AiInsightsRepo');
      return _getCachedInsights();
    }
  }

  /// Fetches daily AI guidance. Cached once per day.
  Future<AiDailyGuidance> getDailyGuidance() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cacheKey = '${_dailyGuidanceCacheKey}_$today';

    // Check day-specific cache
    final cached = _cacheService.get(cacheKey);
    if (cached != null) {
      try {
        final data = cached is String ? jsonDecode(cached) : cached;
        return AiDailyGuidance.fromJson(data as Map<String, dynamic>);
      } catch (_) {}
    }

    if (!_connectivityService.isOnline) {
      return _getDefaultGuidance();
    }

    try {
      final response = await _apiClient.post(
        ApiEndpoints.aiChat,
        data: {
          'message':
              'Provide daily health guidance for a pregnant woman today. '
              'Return a JSON object with fields: greeting (string), '
              'recommendations (array of 4-5 short actionable health tips), '
              'date (today\'s date as string).',
          'context': {
            'source': 'ai_daily_guidance',
            'personalization_enabled': true,
          },
        },
      );

      if (response is Map<String, dynamic> && response['reply'] != null) {
        // Try to parse structured guidance from AI reply
        final guidance = _parseGuidanceFromReply(response['reply'].toString());

        await _cacheService.put(
          cacheKey,
          jsonEncode(guidance.toJson()),
          expiry: const Duration(hours: 24),
        );

        return guidance;
      }

      return _getDefaultGuidance();
    } catch (e) {
      log('Error fetching daily guidance: $e', name: 'AiInsightsRepo');
      return _getDefaultGuidance();
    }
  }

  List<AiInsightModel> _getCachedInsights() {
    final cached = _cacheService.get(_insightsCacheKey);
    if (cached == null) return _getDefaultInsights();

    try {
      final data = cached is String ? jsonDecode(cached) : cached;
      return (data as List<dynamic>)
          .map((e) => AiInsightModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _getDefaultInsights();
    }
  }

  List<AiInsightModel> _getDefaultInsights() {
    return const [
      AiInsightModel(
        id: 'default_1',
        title: 'Baby Growth Update',
        description:
            'Your baby is developing rapidly. Track your growth milestones regularly.',
        type: 'growth',
      ),
      AiInsightModel(
        id: 'default_2',
        title: 'Nutrition Tip',
        description:
            'Increase iron-rich foods like spinach, lentils, and lean meat this week.',
        type: 'nutrition',
      ),
      AiInsightModel(
        id: 'default_3',
        title: 'Exercise Recommendation',
        description:
            'Try 20 minutes of gentle walking today. Stay active and hydrated.',
        type: 'exercise',
      ),
      AiInsightModel(
        id: 'default_4',
        title: 'Medical Reminder',
        description:
            'Schedule your routine prenatal checkup if you haven\'t already.',
        type: 'medical',
      ),
      AiInsightModel(
        id: 'default_5',
        title: 'Weekly Development',
        description:
            'Your baby\'s organs are forming. Ensure adequate folic acid intake.',
        type: 'development',
      ),
    ];
  }

  AiDailyGuidance _getDefaultGuidance() {
    return AiDailyGuidance(
      recommendations: [
        'Drink 2.5L of water throughout the day',
        'Walk for 20 minutes at a gentle pace',
        'Eat iron-rich foods like spinach and lentils',
        'Get 8 hours of quality sleep tonight',
        'Take your prenatal vitamins',
      ],
      date: DateTime.now().toIso8601String().substring(0, 10),
      greeting: 'Good day! Here\'s your personalized health plan.',
    );
  }

  AiDailyGuidance _parseGuidanceFromReply(String reply) {
    // Try to extract recommendations from AI text reply
    final lines = reply.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final recommendations = <String>[];

    for (final line in lines) {
      final cleaned = line
          .replaceAll(RegExp(r'^[\d]+\.\s*'), '')
          .replaceAll(RegExp(r'^[-•*]\s*'), '')
          .replaceAll(RegExp(r'^\*\*.*?\*\*:?\s*'), '')
          .trim();
      if (cleaned.isNotEmpty && cleaned.length > 10 && cleaned.length < 200) {
        recommendations.add(cleaned);
      }
    }

    if (recommendations.isEmpty) {
      return _getDefaultGuidance();
    }

    return AiDailyGuidance(
      recommendations: recommendations.take(5).toList(),
      date: DateTime.now().toIso8601String().substring(0, 10),
      greeting: 'Here\'s your personalized health plan for today!',
    );
  }
}
