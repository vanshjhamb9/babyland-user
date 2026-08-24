class CreateAiChatModel {
  bool? success;
  Chat? chat;
  String? message;

  CreateAiChatModel({this.success, this.chat, this.message});

  CreateAiChatModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    if (json['chat'] is Map) {
      chat = Chat.fromJson(Map<String, dynamic>.from(json['chat'] as Map));
    } else if (json['data'] is Map) {
      chat = Chat.fromJson(Map<String, dynamic>.from(json['data'] as Map));
    }
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
  bool? success;
  String? userMessage;
  String? aiMessage;
  String? chatId;

  Chat({this.success, this.userMessage, this.aiMessage, this.chatId});

  Chat.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    userMessage = json['userMessage']?.toString();
    aiMessage = json['aiMessage']?.toString() ??
        json['aiResponse']?.toString() ??
        json['reply']?.toString();
    chatId = json['chatId']?.toString() ??
        json['conversationId']?.toString() ??
        json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['userMessage'] = userMessage;
    data['aiMessage'] = aiMessage;
    data['chatId'] = chatId;
    return data;
  }
}
