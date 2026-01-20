class DoctorDataModel {
  bool? success;
  String? message;
  List<Doctor>? data;

  DoctorDataModel({this.success, this.message, this.data});

  factory DoctorDataModel.fromJson(Map<String, dynamic> json) {
    return DoctorDataModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<Doctor>.from(json['data'].map((x) => Doctor.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.map((x) => x.toJson()).toList(),
  };
}

class Doctor {
  String? sId;
  bool? isVerified;
  bool? approved;
  String? name;
  String? email;
  String? roleId;
  String? password;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? iV;

  Doctor({
    this.sId,
    this.isVerified,
    this.approved,
    this.name,
    this.email,
    this.roleId,
    this.password,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      sId: json['_id'],
      isVerified: json['isVerified'],
      approved: json['approved'],
      name: json['name'],
      email: json['email'],
      roleId: json['roleId'],
      password: json['password'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      iV: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': sId,
    'isVerified': isVerified,
    'approved': approved,
    'name': name,
    'email': email,
    'roleId': roleId,
    'password': password,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    '__v': iV,
  };
}
