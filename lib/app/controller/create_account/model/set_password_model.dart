class SetPasswordModel {
  bool? success;
  String? message;
  Data? data;

  SetPasswordModel({this.success, this.message, this.data});

  SetPasswordModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
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
  User? user;

  Data({this.email, this.id, this.authToken, this.user});

  Data.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    id = json['id'];
    authToken = json['authToken'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['email'] = this.email;
    data['id'] = this.id;
    data['authToken'] = this.authToken;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
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
        ? new Conditions.fromJson(json['conditions'])
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.conditions != null) {
      data['conditions'] = this.conditions!.toJson();
    }
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['email'] = this.email;
    data['isVerified'] = this.isVerified;
    data['role'] = this.role;
    data['approved'] = this.approved;
    data['cycleType'] = this.cycleType;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['password'] = this.password;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['PCOS'] = this.pCOS;
    data['PMS'] = this.pMS;
    data['Endometriosis'] = this.endometriosis;
    data['ThyroidIssues'] = this.thyroidIssues;
    data['Diabetes'] = this.diabetes;
    data['Hypertension'] = this.hypertension;
    return data;
  }
}
