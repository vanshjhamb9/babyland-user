import 'dart:convert';

AvailableSlotDataModel availableSlotDataModelFromJson(String str) => AvailableSlotDataModel.fromJson(json.decode(str));

String availableSlotDataModelToJson(AvailableSlotDataModel data) => json.encode(data.toJson());

class AvailableSlotDataModel {
  bool? success;
  String? message;
  List<Datum>? data;

  AvailableSlotDataModel({
    this.success,
    this.message,
    this.data,
  });

  factory AvailableSlotDataModel.fromJson(Map<String, dynamic> json) => AvailableSlotDataModel(
    success: json["success"],
    message: json["message"],
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  String? time;
  bool? status;

  Datum({
    this.time,
    this.status,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    time: json["time"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "time": time,
    "status": status,
  };
}
