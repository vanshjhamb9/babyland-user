import 'dart:developer';

import '../../../core/ai/ai_risk_detector.dart';
import '../../../core/services/ai_service.dart';
import '../models/symptom_check_model.dart';

/// Repository for symptom checker operations.
class SymptomCheckerRepository {
  final AIService _aiService;
  final AiRiskDetector _riskDetector = AiRiskDetector();

  SymptomCheckerRepository({required AIService aiService})
      : _aiService = aiService;

  /// Sends symptoms to AI and returns structured result.
  Future<SymptomCheckResult> checkSymptoms(List<String> symptoms) async {
    try {
      final symptomList = symptoms.join(', ');
      final prompt =
          'User is experiencing the following symptoms during pregnancy: $symptomList.\n\n'
          'Provide a structured analysis with the following sections:\n'
          '## Possible Causes\n'
          '## Risk Level\n'
          '## Recommended Actions\n'
          '## When to Contact Doctor\n\n'
          'Be informative but always recommend consulting a healthcare provider.';

      final response = await _aiService.sendMessage(prompt);
      final parsed = SymptomCheckResult.fromAiReply(response.reply);
      final riskAssessment = _riskDetector.detect(
        text: symptomList,
        additionalText: response.reply,
      );
      return SymptomCheckResult(
        possibleCauses: parsed.possibleCauses,
        riskLevel: parsed.riskLevel,
        riskTag: riskAssessment.tag,
        alertMessage:
            riskAssessment.requiresUrgentCare ? riskAssessment.recommendation : null,
        recommendedActions: parsed.recommendedActions,
        whenToContactDoctor: parsed.whenToContactDoctor,
        rawResponse: parsed.rawResponse,
      );
    } catch (e) {
      log('Symptom check error: $e', name: 'SymptomCheckerRepo');
      rethrow;
    }
  }
}
