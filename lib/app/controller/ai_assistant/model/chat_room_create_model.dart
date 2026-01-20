class CreateAiChatRoomModel {
  bool? success;
  Chat? chat;
  String? message;

  CreateAiChatRoomModel({this.success, this.chat, this.message});

  CreateAiChatRoomModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    chat = json['chat'] != null ? Chat.fromJson(json['chat']) : null;
    message = json['message']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (chat != null) {
      data['chat'] = chat!.toJson();
    }
    data['message'] = message;
    return data;
  }
}

class Chat {
  String? userId;
  String? conversationTitle;
  bool? isArchived;
  String? sId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Chat(
      {this.userId,
        this.conversationTitle,
        this.isArchived,
        this.sId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Chat.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];

    conversationTitle = json['conversationTitle'];
    isArchived = json['isArchived'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;

    data['conversationTitle'] = conversationTitle;
    data['isArchived'] = isArchived;
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
