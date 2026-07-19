class UserAiContext {
  final String userId;
  final String? stage;
  final int? pregnancyWeek;
  final int? age;
  final List<String> dietPreferences;
  final List<String> medicalConditions;
  final String? location;
  final List<String> previousQuestions;

  const UserAiContext({
    required this.userId,
    this.stage,
    this.pregnancyWeek,
    this.age,
    this.dietPreferences = const [],
    this.medicalConditions = const [],
    this.location,
    this.previousQuestions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'stage': stage,
      'pregnancy_week': pregnancyWeek,
      'age': age,
      'diet_preferences': dietPreferences,
      'medical_conditions': medicalConditions,
      'location': location,
      'previous_questions': previousQuestions,
    };
  }

  factory UserAiContext.fromJson(Map<String, dynamic> json) {
    return UserAiContext(
      userId: json['user_id']?.toString() ?? '',
      stage: json['stage']?.toString(),
      pregnancyWeek: (json['pregnancy_week'] as num?)?.toInt(),
      age: (json['age'] as num?)?.toInt(),
      dietPreferences: (json['diet_preferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      medicalConditions: (json['medical_conditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      location: json['location']?.toString(),
      previousQuestions: (json['previous_questions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  UserAiContext copyWith({
    String? userId,
    String? stage,
    int? pregnancyWeek,
    int? age,
    List<String>? dietPreferences,
    List<String>? medicalConditions,
    String? location,
    List<String>? previousQuestions,
  }) {
    return UserAiContext(
      userId: userId ?? this.userId,
      stage: stage ?? this.stage,
      pregnancyWeek: pregnancyWeek ?? this.pregnancyWeek,
      age: age ?? this.age,
      dietPreferences: dietPreferences ?? this.dietPreferences,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      location: location ?? this.location,
      previousQuestions: previousQuestions ?? this.previousQuestions,
    );
  }
}
