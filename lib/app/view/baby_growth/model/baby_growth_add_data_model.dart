class BabyGrowthAddData {
  bool? success;
  String? message;
  Tracker? tracker;

  BabyGrowthAddData({this.success, this.tracker});

  BabyGrowthAddData.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    tracker =
    json['tracker'] != null ? Tracker.fromJson(json['tracker']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (tracker != null) {
      data['tracker'] = tracker!.toJson();
    }
    return data;
  }
}

class Tracker {
  String? userId;
  String? babyName;
  String? dob;
  List<VaccinationSchedule>? vaccinationSchedule;
  String? sId;
  String? createdAt;
  String? updatedAt;
  String? iV;

  Tracker(
      {this.userId,
        this.babyName,
        this.dob,
        this.vaccinationSchedule,
        this.sId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Tracker.fromJson(Map<String, dynamic> json) {
    userId = json['userId']?.toString();
    babyName = json['babyName']?.toString();
    dob = json['dob']?.toString();
    if (json['vaccinationSchedule'] != null) {
      vaccinationSchedule = <VaccinationSchedule>[];
      json['vaccinationSchedule'].forEach((v) {
        vaccinationSchedule!.add(VaccinationSchedule.fromJson(v));
      });
    }
    sId = json['_id']?.toString();
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
    iV = json['__v']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['babyName'] = babyName;
    data['dob'] = dob;
    if (vaccinationSchedule != null) {
      data['vaccinationSchedule'] =
          vaccinationSchedule!.map((v) => v.toJson()).toList();
    }
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class VaccinationSchedule {
  String? vaccine;
  String? dueDate;
  bool? completed;
  String? sId;

  VaccinationSchedule({this.vaccine, this.dueDate, this.completed, this.sId});

  VaccinationSchedule.fromJson(Map<String, dynamic> json) {
    vaccine = json['vaccine']?.toString();
    dueDate = json['dueDate']?.toString();
    completed = json['completed'];
    sId = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['vaccine'] = vaccine;
    data['dueDate'] = dueDate;
    data['completed'] = completed;
    data['_id'] = sId;
    return data;
  }
}
