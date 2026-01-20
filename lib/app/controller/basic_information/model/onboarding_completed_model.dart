class OnboardingCompletedModel {
  bool? success;
  String? message;
  Data? data;

  OnboardingCompletedModel({this.success, this.message, this.data});

  OnboardingCompletedModel.fromJson(Map<String, dynamic> json) {
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
  String? lastPeriodStartDate;
  String? cycleType;
  String? cycleLengthDays;
  String? averagePeriodLengthDays;
  Conditions? conditions;
  String? medicalHistory;

  Data(
      {this.sId,
        this.lastPeriodStartDate,
        this.cycleType,
        this.cycleLengthDays,
        this.averagePeriodLengthDays,
        this.conditions,
        this.medicalHistory});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id']?.toString();
    lastPeriodStartDate = json['lastPeriodStartDate']?.toString();
    cycleType = json['cycleType']?.toString();
    cycleLengthDays = json['cycleLengthDays']?.toString();
    averagePeriodLengthDays = json['averagePeriodLengthDays']?.toString();
    conditions = json['conditions'] != null
        ? Conditions.fromJson(json['conditions'])
        : null;
    medicalHistory = json['medicalHistory']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['lastPeriodStartDate'] = lastPeriodStartDate;
    data['cycleType'] = cycleType;
    data['cycleLengthDays'] = cycleLengthDays;
    data['averagePeriodLengthDays'] = averagePeriodLengthDays;
    if (conditions != null) {
      data['conditions'] = conditions!.toJson();
    }
    data['medicalHistory'] = medicalHistory;
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
