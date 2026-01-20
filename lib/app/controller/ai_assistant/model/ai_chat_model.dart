class GetAiChatModel {
  bool? success;
  List<Chats>? chats;
  String? message;

  GetAiChatModel({this.success, this.chats, this.message});

  GetAiChatModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['chats'] != null) {
      chats = <Chats>[];
      json['chats'].forEach((v) {
        chats!.add(Chats.fromJson(v));
      });
    }
    message = json['message']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (chats != null) {
      data['chats'] = chats!.map((v) => v.toJson()).toList();
    }
    data['message'] = message;
    return data;
  }
}

class Chats {
  TokensUsed? tokensUsed;
  String? role;
  String? content;
  String? model;
  String? sId;
  String? createdAt;

  Chats(
      {this.tokensUsed,
        this.role,
        this.content,
        this.model,
        this.sId,
        this.createdAt});

  Chats.fromJson(Map<String, dynamic> json) {
    tokensUsed = json['tokensUsed'] != null
        ? TokensUsed.fromJson(json['tokensUsed'])
        : null;
    role = json['role']?.toString();
    content = json['content']?.toString();
    model = json['model']?.toString();
    sId = json['_id']?.toString();
    createdAt = json['createdAt']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (tokensUsed != null) {
      data['tokensUsed'] = tokensUsed!.toJson();
    }
    data['role'] = role;
    data['content'] = content;
    data['model'] = model;
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    return data;
  }
}

class TokensUsed {
  String? prompt;
  String? completion;
  String? total;

  TokensUsed({this.prompt, this.completion, this.total});

  TokensUsed.fromJson(Map<String, dynamic> json) {
    prompt = json['prompt']?.toString();
    completion = json['completion']?.toString();
    total = json['total']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['prompt'] = prompt;
    data['completion'] = completion;
    data['total'] = total;
    return data;
  }
}
