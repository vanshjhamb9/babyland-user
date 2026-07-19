enum AiRiskLevel { low, medium, high, critical }

class AiRiskAssessment {
  final AiRiskLevel level;
  final List<String> matchedPatterns;
  final String recommendation;

  const AiRiskAssessment({
    required this.level,
    this.matchedPatterns = const [],
    this.recommendation = '',
  });

  String get tag => level.name.toUpperCase();
  bool get requiresUrgentCare =>
      level == AiRiskLevel.high || level == AiRiskLevel.critical;
}

class AiRiskDetector {
  static const String medicalAlertMessage =
      '⚠️ This symptom may require medical attention.\n'
      'Please contact a doctor immediately.';

  static const String criticalAlertMessage =
      '🚨 SEEK IMMEDIATE MEDICAL ATTENTION\n'
      'These symptoms may indicate a serious condition.\n'
      'Seek immediate medical attention or contact a healthcare provider.';

  final Map<AiRiskLevel, List<String>> _rules;

  AiRiskDetector({
    Map<AiRiskLevel, List<String>>? rules,
  }) : _rules = rules ??
            {
              AiRiskLevel.critical: const [
                'severe bleeding',
                'heavy vaginal bleeding',
                'loss of consciousness',
                'seizure',
                'fainting',
                'vision loss',
                'complete vision loss',
                'cannot see',
                'passed out',
                'unconscious',
              ],
              AiRiskLevel.high: const [
                'sharp abdominal pain',
                'high fever',
                'blurred vision',
                'severe headache',
                'fainting',
                'vision loss',
                'severe dizziness',
                'chest pain',
                'difficulty breathing',
                'rapid heartbeat',
              ],
              AiRiskLevel.medium: const [
                'dizziness',
                'persistent vomiting',
                'dehydration',
              ],
            };

  AiRiskAssessment detect({
    required String text,
    String? additionalText,
  }) {
    final corpus = '${text.toLowerCase()} ${additionalText?.toLowerCase() ?? ''}';
    final matched = <String>[];

    AiRiskLevel finalLevel = AiRiskLevel.low;
    for (final entry in _rules.entries) {
      final hits = entry.value.where(corpus.contains).toList();
      if (hits.isNotEmpty) {
        matched.addAll(hits);
        if (_severity(entry.key) > _severity(finalLevel)) {
          finalLevel = entry.key;
        }
      }
    }

    String recommendation = '';
    if (finalLevel == AiRiskLevel.critical) {
      recommendation = criticalAlertMessage;
    } else if (finalLevel == AiRiskLevel.high) {
      recommendation = medicalAlertMessage;
    } else if (finalLevel == AiRiskLevel.medium) {
      recommendation =
          '⚠️ Please monitor these symptoms and consult a healthcare provider if they persist or worsen.';
    }

    return AiRiskAssessment(
      level: finalLevel,
      matchedPatterns: matched,
      recommendation: recommendation,
    );
  }

  int _severity(AiRiskLevel level) {
    switch (level) {
      case AiRiskLevel.low:
        return 1;
      case AiRiskLevel.medium:
        return 2;
      case AiRiskLevel.high:
        return 3;
      case AiRiskLevel.critical:
        return 4;
    }
  }
}
