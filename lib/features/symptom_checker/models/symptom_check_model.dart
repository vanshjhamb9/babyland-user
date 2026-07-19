/// Model for symptom checker result.
class SymptomCheckResult {
  final List<String> possibleCauses;
  final String riskLevel;
  final String riskTag;
  final String? alertMessage;
  final List<String> recommendedActions;
  final String whenToContactDoctor;
  final String rawResponse;

  const SymptomCheckResult({
    required this.possibleCauses,
    required this.riskLevel,
    this.riskTag = 'LOW',
    this.alertMessage,
    required this.recommendedActions,
    required this.whenToContactDoctor,
    this.rawResponse = '',
  });

  factory SymptomCheckResult.fromAiReply(String reply) {
    final causes = <String>[];
    final actions = <String>[];
    String riskLevel = 'Unknown';
    String contactDoctor = '';

    final lines = reply.split('\n');
    String currentSection = '';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final lower = trimmed.toLowerCase();

      if (lower.contains('possible cause') || lower.contains('potential cause')) {
        currentSection = 'causes';
        continue;
      } else if (lower.contains('risk level')) {
        currentSection = 'risk';
        // Extract risk level from the same line if present
        final afterColon = trimmed.split(':').length > 1
            ? trimmed.split(':').sublist(1).join(':').trim()
            : '';
        if (afterColon.isNotEmpty) {
          riskLevel = afterColon.replaceAll(RegExp(r'[*#]'), '').trim();
        }
        continue;
      } else if (lower.contains('recommended action') ||
          lower.contains('recommendation')) {
        currentSection = 'actions';
        continue;
      } else if (lower.contains('when to contact') ||
          lower.contains('contact doctor') ||
          lower.contains('seek medical')) {
        currentSection = 'doctor';
        final afterColon = trimmed.split(':').length > 1
            ? trimmed.split(':').sublist(1).join(':').trim()
            : '';
        if (afterColon.isNotEmpty) {
          contactDoctor = afterColon.replaceAll(RegExp(r'[*#]'), '').trim();
        }
        continue;
      }

      final cleaned = trimmed
          .replaceAll(RegExp(r'^[\d]+\.\s*'), '')
          .replaceAll(RegExp(r'^[-•*]\s*'), '')
          .replaceAll(RegExp(r'^\*\*.*?\*\*:?\s*'), '')
          .replaceAll(RegExp(r'[*#]'), '')
          .trim();

      if (cleaned.isEmpty) continue;

      switch (currentSection) {
        case 'causes':
          causes.add(cleaned);
          break;
        case 'risk':
          if (riskLevel == 'Unknown') riskLevel = cleaned;
          break;
        case 'actions':
          actions.add(cleaned);
          break;
        case 'doctor':
          contactDoctor += contactDoctor.isEmpty ? cleaned : '\n$cleaned';
          break;
      }
    }

    // Fallback if parsing didn't capture sections
    if (causes.isEmpty && actions.isEmpty) {
      return SymptomCheckResult(
        possibleCauses: ['See detailed analysis below'],
        riskLevel: 'Consult your doctor',
        riskTag: 'MEDIUM',
        recommendedActions: ['Review the AI analysis for recommendations'],
        whenToContactDoctor:
            'If symptoms persist or worsen, contact your healthcare provider.',
        rawResponse: reply,
      );
    }

    return SymptomCheckResult(
      possibleCauses: causes,
      riskLevel: riskLevel,
      riskTag: riskLevel.toUpperCase(),
      recommendedActions: actions,
      whenToContactDoctor: contactDoctor.isNotEmpty
          ? contactDoctor
          : 'If symptoms persist or worsen, contact your healthcare provider.',
      rawResponse: reply,
    );
  }
}
