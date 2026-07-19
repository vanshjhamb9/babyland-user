class forgot_password_model {
  bool? success;
  String? message;
  Data? data;

  forgot_password_model({this.success, this.message, this.data});

  forgot_password_model.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? email;
  String? code;
  String? expiry;

  Data({this.email, this.code, this.expiry});

  Data.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    code = json['code'];
    expiry = json['expiry'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['code'] = code;
    data['expiry'] = expiry;
    return data;
  }
}
