/// Model for a saved/bookmarked AI conversation message.
class SavedInsightModel {
  final String id;
  final String content;
  final String? traceId;
  final DateTime savedAt;
  final bool isBookmarked;
  final String category;

  const SavedInsightModel({
    required this.id,
    required this.content,
    this.traceId,
    required this.savedAt,
    this.isBookmarked = true,
    this.category = 'general',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'traceId': traceId,
        'savedAt': savedAt.toIso8601String(),
        'isBookmarked': isBookmarked,
        'category': category,
      };

  factory SavedInsightModel.fromJson(Map<String, dynamic> json) {
    return SavedInsightModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      traceId: json['traceId']?.toString(),
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isBookmarked: json['isBookmarked'] == true,
      category: json['category']?.toString() ?? 'general',
    );
  }
}
