// class BabyGrowthApiData {
//   bool? success;
//   String? message;
//   String? userId;
//   String? babyName;
//   String? dob;
//   List<BabyGrowthSummary>? babyGrowthSummary;
//   List<Milestones>? milestones;
//   List<VaccinationSchedule>? vaccinationSchedule;
//   List<DailyLogs>? dailyLogs;
//   List<PhotoJournal>? photoJournal;
//   AiPredictions? aiPredictions;
//
//   BabyGrowthApiData(
//       {this.userId,
//         this.babyName,
//         this.dob,
//         this.babyGrowthSummary,
//         this.milestones,
//         this.vaccinationSchedule,
//         this.dailyLogs,
//         this.photoJournal,
//         this.aiPredictions});
//
//   BabyGrowthApiData.fromJson(Map<String, dynamic> json) {
//     success = json['success'];
//     message = json['message']?.toString();
//     userId = json['userId']?.toString();
//     babyName = json['babyName']?.toString();
//     dob = json['dob']?.toString();
//     if (json['babyGrowthSummary'] != null) {
//       babyGrowthSummary = <BabyGrowthSummary>[];
//       json['babyGrowthSummary'].forEach((v) {
//         babyGrowthSummary!.add(BabyGrowthSummary.fromJson(v));
//       });
//     }
//     if (json['milestones'] != null) {
//       milestones = <Milestones>[];
//       json['milestones'].forEach((v) {
//         milestones!.add(Milestones.fromJson(v));
//       });
//     }
//     if (json['vaccinationSchedule'] != null) {
//       vaccinationSchedule = <VaccinationSchedule>[];
//       json['vaccinationSchedule'].forEach((v) {
//         vaccinationSchedule!.add(VaccinationSchedule.fromJson(v));
//       });
//     }
//     if (json['dailyLogs'] != null) {
//       dailyLogs = <DailyLogs>[];
//       json['dailyLogs'].forEach((v) {
//         dailyLogs!.add(DailyLogs.fromJson(v));
//       });
//     }
//     if (json['photoJournal'] != null) {
//       photoJournal = <PhotoJournal>[];
//       json['photoJournal'].forEach((v) {
//         photoJournal!.add(PhotoJournal.fromJson(v));
//       });
//     }
//     aiPredictions = json['aiPredictions'] != null
//         ? AiPredictions.fromJson(json['aiPredictions'])
//         : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['success'] = success;
//     data['userId'] = userId;
//     data['message'] = message;
//     data['babyName'] = babyName;
//     data['dob'] = dob;
//     if (babyGrowthSummary != null) {
//       data['babyGrowthSummary'] =
//           babyGrowthSummary!.map((v) => v.toJson()).toList();
//     }
//     if (milestones != null) {
//       data['milestones'] = milestones!.map((v) => v.toJson()).toList();
//     }
//     if (vaccinationSchedule != null) {
//       data['vaccinationSchedule'] =
//           vaccinationSchedule!.map((v) => v.toJson()).toList();
//     }
//     if (dailyLogs != null) {
//       data['dailyLogs'] = dailyLogs!.map((v) => v.toJson()).toList();
//     }
//     if (photoJournal != null) {
//       data['photoJournal'] = photoJournal!.map((v) => v.toJson()).toList();
//     }
//     if (aiPredictions != null) {
//       data['aiPredictions'] = aiPredictions!.toJson();
//     }
//     return data;
//   }
// }
//
// class BabyGrowthSummary {
//   String? date;
//   String? height;
//   String? weight;
//   String? headCircumference;
//
//   BabyGrowthSummary(
//       {this.date, this.height, this.weight, this.headCircumference});
//
//   BabyGrowthSummary.fromJson(Map<String, dynamic> json) {
//     date = json['date']?.toString();
//     height = json['height']?.toString();
//     weight = json['weight']?.toString();
//     headCircumference = json['headCircumference']?.toString();
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['date'] = date;
//     data['height'] = height;
//     data['weight'] = weight;
//     data['headCircumference'] = headCircumference;
//     return data;
//   }
// }
//
// class Milestones {
//   String? date;
//   String? title;
//   String? photo;
//   String? note;
//
//   Milestones({this.date, this.title, this.photo, this.note});
//
//   Milestones.fromJson(Map<String, dynamic> json) {
//     date = json['date']?.toString();
//     title = json['title']?.toString();
//     photo = json['photo']?.toString();
//     note = json['note']?.toString();
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['date'] = date;
//     data['title'] = title;
//     data['photo'] = photo;
//     data['note'] = note;
//     return data;
//   }
// }
//
// class VaccinationSchedule {
//   String? vaccine;
//   String? dueDate;
//   bool? completed;
//
//   VaccinationSchedule({this.vaccine, this.dueDate, this.completed});
//
//   VaccinationSchedule.fromJson(Map<String, dynamic> json) {
//     vaccine = json['vaccine']?.toString();
//     dueDate = json['dueDate']?.toString();
//     completed = json['completed'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['vaccine'] = vaccine;
//     data['dueDate'] = dueDate;
//     data['completed'] = completed;
//     return data;
//   }
// }
//
// class DailyLogs {
//   String? date;
//   String? mood;
//   List<String>? symptoms;
//   String? stressLevel;
//   String? anxietyLevel;
//   String? notes;
//   String? sleepQuality;
//
//   DailyLogs(
//       {this.date,
//         this.mood,
//         this.symptoms,
//         this.stressLevel,
//         this.anxietyLevel,
//         this.notes,
//         this.sleepQuality});
//
//   DailyLogs.fromJson(Map<String, dynamic> json) {
//     date = json['date']?.toString();
//     mood = json['mood']?.toString();
//     symptoms = json['symptoms'].cast<String>();
//     stressLevel = json['stressLevel']?.toString();
//     anxietyLevel = json['anxietyLevel']?.toString();
//     notes = json['notes']?.toString();
//     sleepQuality = json['sleepQuality']?.toString();
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['date'] = date;
//     data['mood'] = mood;
//     data['symptoms'] = symptoms;
//     data['stressLevel'] = stressLevel;
//     data['anxietyLevel'] = anxietyLevel;
//     data['notes'] = notes;
//     data['sleepQuality'] = sleepQuality;
//     return data;
//   }
// }
//
// class PhotoJournal {
//   String? date;
//   String? photoUrl;
//   String? caption;
//
//   PhotoJournal({this.date, this.photoUrl, this.caption});
//
//   PhotoJournal.fromJson(Map<String, dynamic> json) {
//     date = json['date']?.toString();
//     photoUrl = json['photoUrl']?.toString();
//     caption = json['caption']?.toString();
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['date'] = date;
//     data['photoUrl'] = photoUrl;
//     data['caption'] = caption;
//     return data;
//   }
// }
//
// class AiPredictions {
//   String? nextGrowthMilestone;
//   String? growthInsights;
//   String? predictedNextVaccination;
//   String? aiGeneratedAdvice;
//
//   AiPredictions(
//       {this.nextGrowthMilestone,
//         this.growthInsights,
//         this.predictedNextVaccination,
//         this.aiGeneratedAdvice});
//
//   AiPredictions.fromJson(Map<String, dynamic> json) {
//     nextGrowthMilestone = json['nextGrowthMilestone']?.toString();
//     growthInsights = json['growthInsights']?.toString();
//     predictedNextVaccination = json['predictedNextVaccination']?.toString();
//     aiGeneratedAdvice = json['aiGeneratedAdvice']?.toString();
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['nextGrowthMilestone'] = nextGrowthMilestone;
//     data['growthInsights'] = growthInsights;
//     data['predictedNextVaccination'] = predictedNextVaccination;
//     data['aiGeneratedAdvice'] = aiGeneratedAdvice;
//     return data;
//   }
// }


class BabyGrowthApiData {
  bool? success;
  Tracker? tracker;

  BabyGrowthApiData({this.success, this.tracker});

  BabyGrowthApiData.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    tracker =
    json['tracker'] != null ? Tracker.fromJson(json['tracker']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['success'] = success;
    if (tracker != null) {
      data['tracker'] = tracker!.toJson();
    }
    return data;
  }
}

class Tracker {
  String? sId;
  String? userId;
  List<VaccinationSchedule>? vaccinationSchedule;
  List<BabyGrowthSummary>? babyGrowthSummary;
  List<Milestones>? milestones;
  List<dynamic>? dailyLogs;
  List<PhotoJournal>? photoJournal;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Tracker({
    this.sId,
    this.userId,
    this.vaccinationSchedule,
    this.babyGrowthSummary,
    this.milestones,
    this.dailyLogs,
    this.photoJournal,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  Tracker.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    if (json['vaccinationSchedule'] != null) {
      vaccinationSchedule = <VaccinationSchedule>[];
      json['vaccinationSchedule'].forEach((v) {
        vaccinationSchedule!.add(VaccinationSchedule.fromJson(v));
      });
    }
    if (json['babyGrowthSummary'] != null) {
      babyGrowthSummary = <BabyGrowthSummary>[];
      json['babyGrowthSummary'].forEach((v) {
        babyGrowthSummary!.add(BabyGrowthSummary.fromJson(v));
      });
    }
    if (json['milestones'] != null) {
      milestones = <Milestones>[];
      json['milestones'].forEach((v) {
        milestones!.add(Milestones.fromJson(v));
      });
    }
    if (json['dailyLogs'] != null) {
      dailyLogs = [];
      json['dailyLogs'].forEach((v) {
        dailyLogs!.add(v);
      });
    }
    if (json['photoJournal'] != null) {
      photoJournal = <PhotoJournal>[];
      json['photoJournal'].forEach((v) {
        photoJournal!.add(PhotoJournal.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    data['userId'] = userId;
    if (vaccinationSchedule != null) {
      data['vaccinationSchedule'] =
          vaccinationSchedule!.map((v) => v.toJson()).toList();
    }
    if (babyGrowthSummary != null) {
      data['babyGrowthSummary'] =
          babyGrowthSummary!.map((v) => v.toJson()).toList();
    }
    if (milestones != null) {
      data['milestones'] = milestones!.map((v) => v.toJson()).toList();
    }
    if (dailyLogs != null) {
      data['dailyLogs'] = dailyLogs;
    }
    if (photoJournal != null) {
      data['photoJournal'] = photoJournal!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class VaccinationSchedule {
  String? vaccine;
  String? dueDate;
  String? status;
  String? sId;

  VaccinationSchedule({this.vaccine, this.dueDate, this.status, this.sId});

  VaccinationSchedule.fromJson(Map<String, dynamic> json) {
    vaccine = json['vaccine'];
    dueDate = json['dueDate'];
    status = json['status'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['vaccine'] = vaccine;
    data['dueDate'] = dueDate;
    data['status'] = status;
    data['_id'] = sId;
    return data;
  }
}

class BabyGrowthSummary {
  String? date;
  double? height;
  double? weight;
  double? headCircumference;
  String? sId;
  String? createdAt;
  String? updatedAt;

  BabyGrowthSummary({
    this.date,
    this.height,
    this.weight,
    this.headCircumference,
    this.sId,
    this.createdAt,
    this.updatedAt,
  });

  BabyGrowthSummary.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    height = (json['height'] != null)
        ? json['height'].toDouble()
        : null;
    weight = (json['weight'] != null)
        ? json['weight'].toDouble()
        : null;
    headCircumference = (json['headCircumference'] != null)
        ? json['headCircumference'].toDouble()
        : null;
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['date'] = date;
    data['height'] = height;
    data['weight'] = weight;
    data['headCircumference'] = headCircumference;
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}

class Milestones {
  String? date;
  String? title;
  String? photo;
  String? note;
  String? sId;
  String? createdAt;
  String? updatedAt;

  Milestones({
    this.date,
    this.title,
    this.photo,
    this.note,
    this.sId,
    this.createdAt,
    this.updatedAt,
  });

  Milestones.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    title = json['title'];
    photo = json['photo'];
    note = json['note'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['date'] = date;
    data['title'] = title;
    data['photo'] = photo;
    data['note'] = note;
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}

class PhotoJournal {
  String? date;
  String? photoUrl;
  String? caption;
  String? sId;
  String? createdAt;
  String? updatedAt;

  PhotoJournal({
    this.date,
    this.photoUrl,
    this.caption,
    this.sId,
    this.createdAt,
    this.updatedAt,
  });

  PhotoJournal.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    photoUrl = json['photoUrl'];
    caption = json['caption'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['date'] = date;
    data['photoUrl'] = photoUrl;
    data['caption'] = caption;
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
