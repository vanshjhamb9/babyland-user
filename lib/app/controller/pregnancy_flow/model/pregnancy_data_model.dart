class PregnancyDashboardModel {
  bool? success;
  String? message;
  Data? data;

  PregnancyDashboardModel({this.success, this.message, this.data});

  PregnancyDashboardModel.fromJson(Map<String, dynamic> json) {
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
  bool? success;
  Data1? data;

  Data({this.success, this.data});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? Data1.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data1 {
  String? percentage;
  String? daysSinceStart;
  String? currentWeek;
  String? trimester;
  String? expectedDueDate;
  String? fetalGrowthStage;
  Predictions? predictions;
  String? logDate;
  String? mood;
  String? stressLevel;
  String? anxietyLevel;
  List<String>? symptoms;
  Tracker? tracker;

  Data1(
      {this.percentage,
        this.daysSinceStart,
        this.currentWeek,
        this.trimester,
        this.expectedDueDate,
        this.fetalGrowthStage,
        this.predictions,
        this.logDate,
        this.mood,
        this.stressLevel,
        this.anxietyLevel,
        this.symptoms,
        this.tracker});

  Data1.fromJson(Map<String, dynamic> json) {
    percentage = json['percentage']?.toString();
    daysSinceStart = json['daysSinceStart']?.toString();
    currentWeek = json['currentWeek']?.toString();
    trimester = json['trimester']?.toString();
    expectedDueDate = json['expectedDueDate']?.toString();
    fetalGrowthStage = json['fetalGrowthStage']?.toString();
    predictions = json['predictions'] != null
        ? Predictions.fromJson(json['predictions'])
        : null;
    logDate = json['logDate']?.toString();
    mood = json['mood']?.toString();
    stressLevel = json['stressLevel']?.toString();
    anxietyLevel = json['anxietyLevel']?.toString();
    symptoms = json['symptoms'].cast<String>();
    tracker =
    json['tracker'] != null ? Tracker.fromJson(json['tracker']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['percentage'] = percentage;
    data['daysSinceStart'] = daysSinceStart;
    data['currentWeek'] = currentWeek;
    data['trimester'] = trimester;
    data['expectedDueDate'] = expectedDueDate;
    data['fetalGrowthStage'] = fetalGrowthStage;
    if (predictions != null) {
      data['predictions'] = predictions!.toJson();
    }
    data['logDate'] = logDate;
    data['mood'] = mood;
    data['stressLevel'] = stressLevel;
    data['anxietyLevel'] = anxietyLevel;
    data['symptoms'] = symptoms;
    if (tracker != null) {
      data['tracker'] = tracker!.toJson();
    }
    return data;
  }
}

class Predictions {
  String? dueDate;
  String? trimesterProgress;
  String? fetalSize;
  String? nextMilestone;

  Predictions(
      {this.dueDate,
        this.trimesterProgress,
        this.fetalSize,
        this.nextMilestone});

  Predictions.fromJson(Map<String, dynamic> json) {
    dueDate = json['dueDate']?.toString();
    trimesterProgress = json['trimesterProgress']?.toString();
    fetalSize = json['fetalSize']?.toString();
    nextMilestone = json['nextMilestone']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dueDate'] = dueDate;
    data['trimesterProgress'] = trimesterProgress;
    data['fetalSize'] = fetalSize;
    data['nextMilestone'] = nextMilestone;
    return data;
  }
}

class Tracker {
  Predictions? predictions;
  String? sId;
  String? userId;
  String? iV;
  List<AiData>? aiInsights;
  List<Appointments>? appointments;
  String? createdAt;
  String? currentWeek;
  List<DailyLogs>? dailyLogs;
  String? pregnancyStartDate;
  String? trimester;
  String? updatedAt;
  String? expectedDueDate;
  String? fetalGrowthStage;

  Tracker(
      {this.predictions,
        this.sId,
        this.userId,
        this.iV,
        this.aiInsights,
        this.appointments,
        this.createdAt,
        this.currentWeek,
        this.dailyLogs,
        this.pregnancyStartDate,
        this.trimester,
        this.updatedAt,
        this.expectedDueDate,
        this.fetalGrowthStage});

  Tracker.fromJson(Map<String, dynamic> json) {
    predictions = json['predictions'] != null
        ? Predictions.fromJson(json['predictions'])
        : null;
    sId = json['_id']?.toString();
    userId = json['userId']?.toString();
    iV = json['__v']?.toString();
    if (json['aiInsights'] != null) {
      aiInsights = <AiData>[];
      json['aiInsights'].forEach((v) {
        aiInsights!.add(AiData.fromJson(v));
      });
    }
    if (json['appointments'] != null) {
      appointments = <Appointments>[];
      json['appointments'].forEach((v) {
        appointments!.add(Appointments.fromJson(v));
      });
    }
    createdAt = json['createdAt']?.toString();
    currentWeek = json['currentWeek']?.toString();
    if (json['dailyLogs'] != null) {
      dailyLogs = <DailyLogs>[];
      json['dailyLogs'].forEach((v) {
        dailyLogs!.add(DailyLogs.fromJson(v));
      });
    }
    pregnancyStartDate = json['pregnancyStartDate']?.toString();
    trimester = json['trimester']?.toString();
    updatedAt = json['updatedAt']?.toString();
    expectedDueDate = json['expectedDueDate']?.toString();
    fetalGrowthStage = json['fetalGrowthStage']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (predictions != null) {
      data['predictions'] = predictions!.toJson();
    }
    data['_id'] = sId;
    data['userId'] = userId;
    data['__v'] = iV;
    if (aiInsights != null) {
      data['aiInsights'] = aiInsights!.map((v) => v.toJson()).toList();
    }
    if (appointments != null) {
      data['appointments'] = appointments!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = createdAt;
    data['currentWeek'] = currentWeek;
    if (dailyLogs != null) {
      data['dailyLogs'] = dailyLogs!.map((v) => v.toJson()).toList();
    }
    data['pregnancyStartDate'] = pregnancyStartDate;
    data['trimester'] = trimester;
    data['updatedAt'] = updatedAt;
    data['expectedDueDate'] = expectedDueDate;
    data['fetalGrowthStage'] = fetalGrowthStage;
    return data;
  }
}

class Appointments {
  String? title;
  String? date;
  String? time;
  bool? reminder;
  String? notes;
  String? sId;

  Appointments(
      {this.title, this.date, this.time, this.reminder, this.notes, this.sId});

  Appointments.fromJson(Map<String, dynamic> json) {
    title = json['title']?.toString();
    date = json['date']?.toString();
    time = json['time']?.toString();
    reminder = json['reminder'];
    notes = json['notes']?.toString();
    sId = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['date'] = date;
    data['time'] = time;
    data['reminder'] = reminder;
    data['notes'] = notes;
    data['_id'] = sId;
    return data;
  }
}

class DailyLogs {
  String? date;
  String? mood;
  List<String>? symptoms;
  String? stressLevel;
  String? anxietyLevel;
  String? notes;
  String? sId;

  DailyLogs(
      {this.date,
        this.mood,
        this.symptoms,
        this.stressLevel,
        this.anxietyLevel,
        this.notes,
        this.sId});

  DailyLogs.fromJson(Map<String, dynamic> json) {
    date = json['date']?.toString();
    mood = json['mood']?.toString();
    if(json['symptoms'] != null) {
      symptoms = json['symptoms'].cast<String>();
    }else{
      symptoms = [];
    }
    stressLevel = json['stressLevel']?.toString();
    anxietyLevel = json['anxietyLevel']?.toString();
    notes = json['notes']?.toString();
    sId = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['mood'] = mood;
    data['symptoms'] = symptoms;
    data['stressLevel'] = stressLevel;
    data['anxietyLevel'] = anxietyLevel;
    data['notes'] = notes;
    data['_id'] = sId;
    return data;
  }
}
class AiData {
  String? type;
  String? message;
  String? createdAt;

  AiData({this.type, this.message, this.createdAt});

  AiData.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    message = json['message']?.toString();
    createdAt = json['createdAt']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['message'] = message;
    data['createdAt'] = createdAt;
    return data;
  }
}
