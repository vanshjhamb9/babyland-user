class LoginModel {
  bool? success;
  String? message;
  String? authToken;
  User? user;

  LoginModel({this.success, this.message, this.authToken, this.user});

  LoginModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    final data = json['data'];
    if (data != null) {
      authToken = data['authToken']?.toString();
      user = data['user'] != null ? User.fromJson(data['user']) : null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['data'] = {
      'authToken': authToken,
      'user': user?.toJson(),
    };
    return data;
  }
}

class User {
  String? id;
  String? name;
  String? email;
  String? role;

  User({this.id, this.name, this.email, this.role});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    email = json['email']?.toString();
    role = json['role']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['role'] = role;
    return data;
  }
}
