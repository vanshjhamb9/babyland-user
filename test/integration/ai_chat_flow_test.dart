import 'package:babyland/core/ai/ai_context_builder.dart';
import 'package:babyland/core/ai/ai_response_parser.dart';
import 'package:babyland/core/ai/ai_risk_detector.dart';
import 'package:babyland/models/user_ai_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI chat integration flow', () {
    test('builds context, parses response, and detects risk', () {
      final contextBuilder = AiContextBuilder();
      final parser = AiResponseParser();
      final riskDetector = AiRiskDetector();

      final context = contextBuilder.buildContext(
        userContext: const UserAiContext(
          userId: 'user_1',
          pregnancyWeek: 24,
          dietPreferences: ['vegetarian'],
          medicalConditions: ['anemia'],
          location: 'India',
          previousQuestions: ['What should I eat today?'],
        ),
        currentMessage: 'I feel severe headache and blurred vision',
      );

      expect(context['pregnancy_week'], 24);
      expect(context['location'], 'India');

      final parsed = parser.parseChatResponse({
        'reply': 'Your symptoms include severe headache and blurred vision.',
        'trace_id': 'trace_123',
        'latency_ms': 1200,
        'token_usage': 350,
      });

      expect(parsed.traceId, 'trace_123');
      expect(parsed.tokenUsage, 350);

      final risk = riskDetector.detect(
        text: 'severe headache',
        additionalText: parsed.reply,
      );

      expect(risk.tag, 'HIGH');
      expect(risk.requiresUrgentCare, isTrue);
    });
  });
}
