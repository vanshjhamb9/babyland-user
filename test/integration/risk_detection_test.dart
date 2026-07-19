import 'package:babyland/core/ai/ai_risk_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Risk detection integration', () {
    test('triggers high risk alert for dangerous symptom patterns', () {
      final detector = AiRiskDetector();
      final result = detector.detect(
        text: 'I am experiencing severe bleeding and sharp abdominal pain',
      );

      expect(result.level, isNot(AiRiskLevel.low));
      expect(result.requiresUrgentCare, isTrue);
      expect(result.recommendation, contains('medical attention'));
    });
  });
}
