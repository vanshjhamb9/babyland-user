import 'package:babyland/core/constants/api_endpoints.dart';
import 'package:babyland/core/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Insights API integration contract', () {
    test('uses configured AI insights endpoint', () {
      expect(ApiEndpoints.aiInsights, '/ai/insights');
    });

    test('AI insights response parses structured insights list', () {
      final response = AIInsightsResponse.fromJson({
        'insights': [
          {'id': '1', 'title': 'Nutrition tip'}
        ],
        'generated_at': '2026-03-12T12:00:00Z',
      });

      expect(response.insights.length, 1);
      expect(response.generatedAt, '2026-03-12T12:00:00Z');
    });
  });
}
