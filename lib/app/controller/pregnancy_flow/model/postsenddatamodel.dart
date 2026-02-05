// To parse this JSON data, do
//
//     final postSendDataModel = postSendDataModelFromJson(jsonString);

import 'dart:convert';

PostSendDataModel postSendDataModelFromJson(String str) => PostSendDataModel.fromJson(json.decode(str));

String postSendDataModelToJson(PostSendDataModel data) => json.encode(data.toJson());

class PostSendDataModel {
  bool? success;
  String? message;
  Data? data;

  PostSendDataModel({
    this.success,
    this.message,
    this.data,
  });

  factory PostSendDataModel.fromJson(Map<String, dynamic> json) => PostSendDataModel(
    success: json["success"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  String? userId;
  String? message;
  List<dynamic>? hashtags;
  String? id;
  List<dynamic>? likes;
  List<dynamic>? comments;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  Data({
    this.userId,
    this.message,
    this.hashtags,
    this.id,
    this.likes,
    this.comments,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    userId: json["userId"],
    message: json["message"],
    hashtags: json["hashtags"] == null ? [] : List<dynamic>.from(json["hashtags"]!.map((x) => x)),
    id: json["_id"],
    likes: json["likes"] == null ? [] : List<dynamic>.from(json["likes"]!.map((x) => x)),
    comments: json["comments"] == null ? [] : List<dynamic>.from(json["comments"]!.map((x) => x)),
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "message": message,
    "hashtags": hashtags == null ? [] : List<dynamic>.from(hashtags!.map((x) => x)),
    "_id": id,
    "likes": likes == null ? [] : List<dynamic>.from(likes!.map((x) => x)),
    "comments": comments == null ? [] : List<dynamic>.from(comments!.map((x) => x)),
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}
