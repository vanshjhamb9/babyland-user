import 'package:babyland/features/symptom_checker/models/symptom_check_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Symptom checker integration', () {
    test('returns structured symptom data from AI markdown response', () {
      final result = SymptomCheckResult.fromAiReply(
        '''
## Possible Causes
- Dehydration
- Migraine
## Risk Level: Medium
## Recommended Actions
- Drink water
- Rest in a dark room
## When to Contact Doctor
If symptoms worsen or persist for 24 hours.
''',
      );

      expect(result.possibleCauses, contains('Dehydration'));
      expect(result.recommendedActions, contains('Drink water'));
      expect(result.riskLevel.toLowerCase(), contains('medium'));
      expect(result.whenToContactDoctor.toLowerCase(), contains('worsen'));
    });
  });
}
