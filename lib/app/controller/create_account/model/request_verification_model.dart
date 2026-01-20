class RequestVerificationModel {
  bool? success;
  String? message;
  VerificationData? data;

  RequestVerificationModel({this.success, this.message, this.data});

  RequestVerificationModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    data = json['data'] != null
        ? VerificationData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
  }
}

class VerificationData {
  String? email;
  String? code;

  VerificationData({this.email, this.code});

  VerificationData.fromJson(Map<String, dynamic> json) {
    email = json['email']?.toString();
    code = json['code']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['email'] = email;
    map['code'] = code;
    return map;
  }
}
