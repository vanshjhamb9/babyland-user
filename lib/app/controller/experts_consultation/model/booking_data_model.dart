class BookingDataModel {
  bool? success;
  List<Booking>? bookings;

  BookingDataModel({this.success, this.bookings});

  factory BookingDataModel.fromJson(Map<String, dynamic> json) {
    return BookingDataModel(
      success: json['success'],
      bookings: json['bookings'] != null
          ? List<Booking>.from(
          json['bookings'].map((x) => Booking.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'bookings': bookings?.map((x) => x.toJson()).toList(),
  };
}

class Doctor {
  String? id;
  String? name;

  Doctor({this.id, this.name});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
  };
}


class Booking {
  String? sId;
  Doctor? doctorId;
  String? patientId;
  DateTime? date;
  String? time;
  String? status;
  String? paymentStatus;
  int? consultationFee;
  String? currency;
  String? paymentMethod;
  List<dynamic>? records;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? iV;

  Booking({
    this.sId,
    this.doctorId,
    this.patientId,
    this.date,
    this.time,
    this.status,
    this.paymentStatus,
    this.consultationFee,
    this.currency,
    this.paymentMethod,
    this.records,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      sId: json['_id'],
      doctorId: json['doctorId'] != null ? Doctor.fromJson(json['doctorId']) : null,
      patientId: json['patientId'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      time: json['time'],
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      consultationFee: json['consultationFee'],
      currency: json['currency'],
      paymentMethod: json['paymentMethod'],
      records: json['records'] != null ? List<dynamic>.from(json['records']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      iV: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': sId,
    'doctorId': doctorId?.toJson(),
    'patientId': patientId,
    'date': date?.toIso8601String(),
    'time': time,
    'status': status,
    'paymentStatus': paymentStatus,
    'consultationFee': consultationFee,
    'currency': currency,
    'paymentMethod': paymentMethod,
    'records': records,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    '__v': iV,
  };
}
