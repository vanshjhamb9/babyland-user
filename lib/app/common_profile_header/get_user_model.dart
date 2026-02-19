class GetUserModel {
  bool? success;
  String? message;
  User? user;

  GetUserModel({this.success, this.message, this.user});

  GetUserModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  bool? success;
  String? profileCompletion;
  Users? user;
  Map<String, dynamic>? pregnancyTracker;

  User({this.success, this.profileCompletion, this.user, this.pregnancyTracker});

  User.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    profileCompletion = json['profileCompletion']?.toString();
    user = json['user'] != null ? Users.fromJson(json['user']) : null;
    pregnancyTracker = json['pregnancyTracker'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['profileCompletion'] = profileCompletion;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['pregnancyTracker'] = pregnancyTracker;
    return data;
  }
}

class Users {
  IrregularCycleRangeDays? irregularCycleRangeDays;
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
  String? iV;
  String? verificationCode;
  String? verificationExpiresAt;
  String? averagePeriodLengthDays;
  String? cycleLengthDays;
  String? lastPeriodStartDate;
  String? medicalHistory;
  String? profilePicture;
  String? phone;
  String? weight;
  String? pregnancyStartDate;
  String? stage;

  Users(
      {this.irregularCycleRangeDays,
        this.conditions,
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
        this.verificationCode,
        this.verificationExpiresAt,
        this.averagePeriodLengthDays,
        this.cycleLengthDays,
        this.lastPeriodStartDate,
        this.profilePicture,
        this.phone,
        this.weight,
        this.pregnancyStartDate,
        this.stage,
        this.medicalHistory});

  Users.fromJson(Map<String, dynamic> json) {
    irregularCycleRangeDays = json['irregularCycleRangeDays'] != null
        ? IrregularCycleRangeDays.fromJson(json['irregularCycleRangeDays'])
        : null;
    conditions = json['conditions'] != null
        ? Conditions.fromJson(json['conditions'])
        : null;
    sId = json['_id']?.toString();
    name = json['name']?.toString();
    email = json['email']?.toString();
    isVerified = json['isVerified'];
    role = json['role']?.toString();
    approved = json['approved'];
    cycleType = json['cycleType']?.toString();
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
    iV = json['__v']?.toString();
    verificationCode = json['verificationCode']?.toString();
    verificationExpiresAt = json['verificationExpiresAt']?.toString();
    averagePeriodLengthDays = json['averagePeriodLengthDays']?.toString();
    cycleLengthDays = json['cycleLengthDays']?.toString();
    lastPeriodStartDate = json['lastPeriodStartDate']?.toString();
    medicalHistory = json['medicalHistory']?.toString();
    profilePicture = json['profilePicture']?.toString();
    phone = json['phone']?.toString();
    weight = json['weight']?.toString();
    pregnancyStartDate = json['pregnancyStartDate']?.toString();
    stage = json['stage']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (irregularCycleRangeDays != null) {
      data['irregularCycleRangeDays'] = irregularCycleRangeDays!.toJson();
    }
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
    data['verificationCode'] = verificationCode;
    data['verificationExpiresAt'] = verificationExpiresAt;
    data['averagePeriodLengthDays'] = averagePeriodLengthDays;
    data['cycleLengthDays'] = cycleLengthDays;
    data['lastPeriodStartDate'] = lastPeriodStartDate;
    data['lastPeriodStartDate'] = lastPeriodStartDate;
    data['medicalHistory'] = medicalHistory;
    data['profilePicture'] = profilePicture;
    data['phone'] = phone;
    data['weight'] = weight;
    data['stage'] = stage;
    return data;
  }
}

class IrregularCycleRangeDays {
  String? min;
  String? max;

  IrregularCycleRangeDays({this.min, this.max});

  IrregularCycleRangeDays.fromJson(Map<String, dynamic> json) {
    min = json['min']?.toString();
    max = json['max']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['min'] = min;
    data['max'] = max;
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
