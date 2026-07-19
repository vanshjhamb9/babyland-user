import 'package:babyland/core/ai/ai_context_builder.dart';
import 'package:babyland/models/user_ai_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Personalization integration', () {
    test('includes user context in prompt payload shape', () {
      final userContext = const UserAiContext(
        userId: 'u123',
        pregnancyWeek: 24,
        age: 29,
        dietPreferences: ['vegetarian'],
        medicalConditions: ['anemia'],
        location: 'India',
        previousQuestions: ['What should I eat today?'],
      );

      final context = AiContextBuilder().buildContext(
        userContext: userContext,
      );
      final payload = {
        'message': 'What should I eat today?',
        'context': context,
      };

      expect(payload['context'], isA<Map<String, dynamic>>());
      final body = payload['context']! as Map<String, dynamic>;
      expect(body['pregnancy_week'], 24);
      expect(body['diet_preferences'], ['vegetarian']);
      expect(body['medical_conditions'], ['anemia']);
      expect(body['location'], 'India');
    });
  });
}
