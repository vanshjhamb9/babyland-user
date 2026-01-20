class BookingAddModel {
  bool? success;
  String? message;
  Data? data;

  BookingAddModel({this.success, this.message, this.data});

  BookingAddModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
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
  String? sId;
  DoctorId? doctorId;
  DoctorId? patientId;
  String? date;
  String? time;
  String? status;
  String? paymentStatus;
  String? consultationFee;
  String? currency;
  String? paymentMethod;
  String? createdAt;
  String? updatedAt;
  String? iV;

  Data(
      {this.sId,
        this.doctorId,
        this.patientId,
        this.date,
        this.time,
        this.status,
        this.paymentStatus,
        this.consultationFee,
        this.currency,
        this.paymentMethod,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id']?.toString();
    doctorId = json['doctorId'] != null
        ? DoctorId.fromJson(json['doctorId'])
        : null;
    patientId = json['patientId'] != null
        ? DoctorId.fromJson(json['patientId'])
        : null;
    date = json['date']?.toString();
    time = json['time']?.toString();
    status = json['status']?.toString();
    paymentStatus = json['paymentStatus']?.toString();
    consultationFee = json['consultationFee']?.toString();
    currency = json['currency']?.toString();
    paymentMethod = json['paymentMethod']?.toString();
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
    iV = json['__v']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    if (doctorId != null) {
      data['doctorId'] = doctorId!.toJson();
    }
    if (patientId != null) {
      data['patientId'] = patientId!.toJson();
    }
    data['date'] = date;
    data['time'] = time;
    data['status'] = status;
    data['paymentStatus'] = paymentStatus;
    data['consultationFee'] = consultationFee;
    data['currency'] = currency;
    data['paymentMethod'] = paymentMethod;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class DoctorId {
  String? sId;
  String? name;

  DoctorId({this.sId, this.name});

  DoctorId.fromJson(Map<String, dynamic> json) {
    sId = json['_id']?.toString();
    name = json['name']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    return data;
  }
}
