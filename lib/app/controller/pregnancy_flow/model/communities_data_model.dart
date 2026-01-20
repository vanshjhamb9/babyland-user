class Communities_Data_Model {
  bool? success;
  String? message;
  CommunitiesData? data;

  Communities_Data_Model({this.success, this.message, this.data});

  Communities_Data_Model.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? CommunitiesData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};
    dataMap['success'] = success;
    dataMap['message'] = message;
    if (data != null) {
      dataMap['data'] = data!.toJson();
    }
    return dataMap;
  }
}

class CommunitiesData {
  int? page;
  int? limit;
  int? total;
  List<PostData>? posts;

  CommunitiesData({this.page, this.limit, this.total, this.posts});

  CommunitiesData.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    limit = json['limit'];
    total = json['total'];
    if (json['data'] != null) {
      posts = <PostData>[];
      json['data'].forEach((v) {
        posts!.add(PostData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};
    dataMap['page'] = page;
    dataMap['limit'] = limit;
    dataMap['total'] = total;
    if (posts != null) {
      dataMap['data'] = posts!.map((v) => v.toJson()).toList();
    }
    return dataMap;
  }
}

class PostData {
  String? sId;
  UserId? userId;
  String? message;
  List<String>? hashtags;
  List<CommentModel>? comments;
  List<dynamic>? likes;
  String? commentsCount;
  String? createdAt;
  String? updatedAt;
  int? iV;

  PostData({
    this.sId,
    this.userId,
    this.message,
    this.hashtags,
    this.likes,
    this.commentsCount,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  PostData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'] != null ? UserId.fromJson(json['userId']) : null;
    message = json['message'];
    hashtags = json['hashtags'] != null ? List<String>.from(json['hashtags']) : null;
     likes = json['likes'] as List<dynamic>? ?? [];
    commentsCount = json['commentsCount']?.toString();
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    comments: (json['comments'] as List<dynamic>?)
        ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};
    dataMap['_id'] = sId;
    if (userId != null) {
      dataMap['userId'] = userId!.toJson();
    }
    dataMap['message'] = message;
    if (hashtags != null) {
      dataMap['hashtags'] = hashtags;
    }
    if (comments != null) {
      dataMap['hashtags'] = comments;
    }
    dataMap['likes'] = likes;
    dataMap['commentsCount'] = commentsCount;
    dataMap['createdAt'] = createdAt;
    dataMap['updatedAt'] = updatedAt;
    dataMap['__v'] = iV;
    return dataMap;
  }
}

class UserId {
  String? sId;
  String? name;

  UserId({this.sId, this.name});

  UserId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};
    dataMap['_id'] = sId;
    dataMap['name'] = name;
    return dataMap;
  }
}

class CommentModel {
  final String? userId;
  final String? comment;
  final String? id;
  final String? createdAt;

  CommentModel({this.userId, this.comment, this.id, this.createdAt});

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      userId: json['userId'] as String?,
      comment: json['comment'] as String?,
      id: json['_id'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }}