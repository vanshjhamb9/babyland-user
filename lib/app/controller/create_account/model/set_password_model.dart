class SetPasswordModel {
  bool? success;
  String? message;
  Data? data;

  SetPasswordModel({this.success, this.message, this.data});

  SetPasswordModel.fromJson(Map<String, dynamic> json) {
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
  String? id;
  String? authToken;
  String? refreshToken;
  User? user;

  Data({this.email, this.id, this.authToken, this.refreshToken, this.user});

  Data.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    id = json['id'];
    authToken = json['authToken'];
    refreshToken = json['refreshToken']?.toString();
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['id'] = id;
    data['authToken'] = authToken;
    data['refreshToken'] = refreshToken;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  Conditions? conditions;
  String? sId;
  String? name;
  String? email;
  bool? isVerified;
  String? role;
  bool? approved;
  String? cycleType;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? password;

  User(
      {this.conditions,
        this.sId,
        this.name,
        this.email,
        this.isVerified,
        this.role,
        this.approved,
        this.cycleType,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.password});

  User.fromJson(Map<String, dynamic> json) {
    conditions = json['conditions'] != null
        ? Conditions.fromJson(json['conditions'])
        : null;
    sId = json['_id'];
    name = json['name'];
    email = json['email'];
    isVerified = json['isVerified'];
    role = json['role'];
    approved = json['approved'];
    cycleType = json['cycleType'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (conditions != null) {
      data['conditions'] = conditions!.toJson();
    }
    data['_id'] = sId;
    data['name'] = name;
    data['email'] = email;
    data['isVerified'] = isVerified;
    data['role'] = role;
    data['approved'] = approved;
    data['cycleType'] = cycleType;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['password'] = password;
    return data;
  }
}

class Conditions {
  bool? pCOS;
  bool? pMS;
  bool? endometriosis;
  bool? thyroidIssues;
  bool? diabetes;
  bool? hypertension;

  Conditions(
      {this.pCOS,
        this.pMS,
        this.endometriosis,
        this.thyroidIssues,
        this.diabetes,
        this.hypertension});

  Conditions.fromJson(Map<String, dynamic> json) {
    pCOS = json['PCOS'];
    pMS = json['PMS'];
    endometriosis = json['Endometriosis'];
    thyroidIssues = json['ThyroidIssues'];
    diabetes = json['Diabetes'];
    hypertension = json['Hypertension'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['PCOS'] = pCOS;
    data['PMS'] = pMS;
    data['Endometriosis'] = endometriosis;
    data['ThyroidIssues'] = thyroidIssues;
    data['Diabetes'] = diabetes;
    data['Hypertension'] = hypertension;
    return data;
  }
}
