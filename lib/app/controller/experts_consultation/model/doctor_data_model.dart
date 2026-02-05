// To parse this JSON data, do
//
//     final doctorDataModel = doctorDataModelFromJson(jsonString);

import 'dart:convert';

DoctorDataModel doctorDataModelFromJson(String str) => DoctorDataModel.fromJson(json.decode(str));

String doctorDataModelToJson(DoctorDataModel data) => json.encode(data.toJson());

class DoctorDataModel {
  bool? success;
  String? message;
  List<Doctor>? data;  // ✅ Datum → Doctor (List of doctors) [cite:36]

  DoctorDataModel({
    this.success,
    this.message,
    this.data,
  });

  factory DoctorDataModel.fromJson(Map<String, dynamic> json) => DoctorDataModel(
    success: json["success"],
    message: json["message"],
    data: json["data"] == null ? [] : List<Doctor>.from(json["data"]!.map((x) => Doctor.fromJson(x))),  // ✅ Doctor.fromJson
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Doctor {  // ✅ Datum → Doctor (clean name for doctor list)
  String? id;
  bool? isVerified;
  bool? approved;
  String? name;  // ✅ Direct doctor.name access
  String? email;
  String? roleId;
  String? password;
  String? nextAvailable;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;
  DoctorDetails? doctorDetails;

  Doctor({
    this.id,
    this.isVerified,
    this.approved,
    this.name,
    this.email,
    this.nextAvailable,
    this.roleId,
    this.password,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.doctorDetails,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
    id: json["_id"],
    isVerified: json["isVerified"],
    approved: json["approved"],
    name: json["name"],  // ✅ Doctor name
    email: json["email"],
    roleId: json["roleId"],
    password: json["password"],
    nextAvailable: json["nextAvailable"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
    doctorDetails: json["doctorDetails"] == null ? null : DoctorDetails.fromJson(json["doctorDetails"]),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "isVerified": isVerified,
    "approved": approved,
    "name": name,
    "email": email,
    "roleId": roleId,
    "password": password,
    "nextAvailable": nextAvailable,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
    "doctorDetails": doctorDetails?.toJson(),
  };
}

class DoctorDetails {
  List<String>? languages;
  int? consultationFee;
  List<WeeklySlot>? weeklySlots;  // Doctor के time slots
  List<dynamic>? speciality;
  int? totalAvgRating;
  int? totalReviewCount;

  DoctorDetails({
    this.languages,
    this.consultationFee,
    this.weeklySlots,
    this.speciality,
    this.totalAvgRating,
    this.totalReviewCount,
  });

  factory DoctorDetails.fromJson(Map<String, dynamic> json) => DoctorDetails(
    languages: json["languages"] == null ? [] : List<String>.from(json["languages"]!.map((x) => x)),
    consultationFee: json["consultationFee"],
    weeklySlots: json["weeklySlots"] == null ? [] : List<WeeklySlot>.from(json["weeklySlots"]!.map((x) => WeeklySlot.fromJson(x))),
    speciality: json["speciality"] == null ? [] : List<dynamic>.from(json["speciality"]!.map((x) => x)),
    totalAvgRating: json["totalAvgRating"],
    totalReviewCount: json["totalReviewCount"],
  );

  Map<String, dynamic> toJson() => {
    "languages": languages == null ? [] : List<dynamic>.from(languages!.map((x) => x)),
    "consultationFee": consultationFee,
    "weeklySlots": weeklySlots == null ? [] : List<dynamic>.from(weeklySlots!.map((x) => x.toJson())),
    "speciality": speciality == null ? [] : List<dynamic>.from(speciality!.map((x) => x)),
    "totalAvgRating": totalAvgRating,
    "totalReviewCount": totalReviewCount,
  };
}

class WeeklySlot {
  String? day;  // Monday, Tuesday etc.
  String? startTime;  // "09:00"
  String? endTime;    // "10:00"
  String? id;

  WeeklySlot({
    this.day,
    this.startTime,
    this.endTime,
    this.id,
  });

  factory WeeklySlot.fromJson(Map<String, dynamic> json) => WeeklySlot(
    day: json["day"],
    startTime: json["startTime"],
    endTime: json["endTime"],
    id: json["_id"],
  );

  Map<String, dynamic> toJson() => {
    "day": day,
    "startTime": startTime,
    "endTime": endTime,
    "_id": id,
  };
}
