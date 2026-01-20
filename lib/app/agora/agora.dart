class TokenGeneratorModel {
  bool? success;
  Token? token;
  String? message;

  TokenGeneratorModel({this.success, this.token, this.message});

  TokenGeneratorModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    token = json['token'] != null ? Token.fromJson(json['token']) : null;
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (token != null) {
      data['token'] = token!.toJson();
    }
    data['message'] = message;
    return data;
  }
}

class Token {
  String? token;
  String? expireIn;

  Token({this.token, this.expireIn});

  Token.fromJson(Map<String, dynamic> json) {
    token = json['token']?.toString();
    expireIn = json['expireIn']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = token;
    data['expireIn'] = expireIn;
    return data;
  }
}
