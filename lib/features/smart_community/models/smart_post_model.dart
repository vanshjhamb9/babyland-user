/// Model for a smart community post with AI personalization.
class SmartPostModel {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String? authorAvatar;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isRecommended;
  final bool isTrending;
  final int? relevantWeek;
  final DateTime createdAt;
  final List<String> tags;

  const SmartPostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.authorAvatar,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isRecommended = false,
    this.isTrending = false,
    this.relevantWeek,
    required this.createdAt,
    this.tags = const [],
  });

  factory SmartPostModel.fromJson(Map<String, dynamic> json) {
    return SmartPostModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? json['description']?.toString() ?? '',
      authorName: json['user']?['name']?.toString() ??
          json['authorName']?.toString() ??
          'Community Member',
      authorAvatar: (json['user']?['photo'] ??
              json['user']?['profilePicture'])
          ?.toString(),
      likes: (json['likes'] as num?)?.toInt() ??
          (json['likesCount'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ??
          (json['commentsCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
      isRecommended: json['isRecommended'] == true,
      isTrending: json['isTrending'] == true,
      relevantWeek: (json['relevantWeek'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'likes': likes,
      'comments': comments,
      'isLiked': isLiked,
      'isRecommended': isRecommended,
      'isTrending': isTrending,
      'relevantWeek': relevantWeek,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }
}
