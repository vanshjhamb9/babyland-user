import '../../models/user_ai_context.dart';

class AiContextBuilder {
  Map<String, dynamic> buildContext({
    required UserAiContext userContext,
    String? currentMessage,
    Map<String, dynamic>? extra,
  }) {
    final base = <String, dynamic>{
      if (userContext.stage != null && userContext.stage!.trim().isNotEmpty)
        'stage': userContext.stage,
      'pregnancy_week': userContext.pregnancyWeek,
      'age': userContext.age,
      'diet_preferences': userContext.dietPreferences,
      'medical_conditions': userContext.medicalConditions,
      'location': userContext.location,
      'previous_questions': userContext.previousQuestions,
      if (currentMessage != null && currentMessage.isNotEmpty)
        'current_message': currentMessage,
    };

    if (extra != null && extra.isNotEmpty) {
      base.addAll(extra);
    }

    base.removeWhere((_, value) {
      if (value == null) return true;
      if (value is String) return value.trim().isEmpty;
      if (value is List) return value.isEmpty;
      return false;
    });
    return base;
  }
}
