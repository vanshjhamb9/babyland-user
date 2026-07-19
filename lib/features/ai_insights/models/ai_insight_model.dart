/// Model for a single AI insight item.
class AiInsightModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? icon;
  final DateTime? createdAt;

  const AiInsightModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.icon,
    this.createdAt,
  });

  factory AiInsightModel.fromJson(Map<String, dynamic> json) {
    return AiInsightModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      icon: json['icon']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'icon': icon,
        'createdAt': createdAt?.toIso8601String(),
      };
}

/// Model for daily AI guidance recommendations.
class AiDailyGuidance {
  final List<String> recommendations;
  final String date;
  final String? greeting;

  const AiDailyGuidance({
    required this.recommendations,
    required this.date,
    this.greeting,
  });

  factory AiDailyGuidance.fromJson(Map<String, dynamic> json) {
    return AiDailyGuidance(
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      date: json['date']?.toString() ?? '',
      greeting: json['greeting']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'recommendations': recommendations,
        'date': date,
        'greeting': greeting,
      };
}
