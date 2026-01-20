class PregnancyInfoModel {
  bool? success;
  String? message;
  String? userId;
  String? pregnancyStartDate;
  String? currentWeek;
  String? trimester;
  String? expectedDueDate;
  String? fetalGrowthStage;
  List<DailyLogs>? dailyLogs;
  List<Appointments>? appointments;
  List<AiInsights>? aiInsights;
  Predictions? predictions;
  String? notes;

  PregnancyInfoModel(
      {
        this.success,
        this.message,
        this.userId,
        this.pregnancyStartDate,
        this.currentWeek,
        this.trimester,
        this.expectedDueDate,
        this.fetalGrowthStage,
        this.dailyLogs,
        this.appointments,
        this.aiInsights,
        this.predictions,
        this.notes});

  PregnancyInfoModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    userId = json['userId']?.toString();
    pregnancyStartDate = json['pregnancyStartDate']?.toString();
    currentWeek = json['currentWeek']?.toString();
    trimester = json['trimester']?.toString();
    expectedDueDate = json['expectedDueDate']?.toString();
    fetalGrowthStage = json['fetalGrowthStage']?.toString();
    if (json['dailyLogs'] != null) {
      dailyLogs = <DailyLogs>[];
      json['dailyLogs'].forEach((v) {
        dailyLogs!.add(DailyLogs.fromJson(v));
      });
    }
    if (json['appointments'] != null) {
      appointments = <Appointments>[];
      json['appointments'].forEach((v) {
        appointments!.add(Appointments.fromJson(v));
      });
    }
    if (json['aiInsights'] != null) {
      aiInsights = <AiInsights>[];
      json['aiInsights'].forEach((v) {
        aiInsights!.add(AiInsights.fromJson(v));
      });
    }
    predictions = json['predictions'] != null
        ? Predictions.fromJson(json['predictions'])
        : null;
    notes = json['notes']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['userId'] = userId;
    data['pregnancyStartDate'] = pregnancyStartDate;
    data['currentWeek'] = currentWeek;
    data['trimester'] = trimester;
    data['expectedDueDate'] = expectedDueDate;
    data['fetalGrowthStage'] = fetalGrowthStage;
    if (dailyLogs != null) {
      data['dailyLogs'] = dailyLogs!.map((v) => v.toJson()).toList();
    }
    if (appointments != null) {
      data['appointments'] = appointments!.map((v) => v.toJson()).toList();
    }
    if (aiInsights != null) {
      data['aiInsights'] = aiInsights!.map((v) => v.toJson()).toList();
    }
    if (predictions != null) {
      data['predictions'] = predictions!.toJson();
    }
    data['notes'] = notes;
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
  String? sleepQuality;

  DailyLogs(
      {this.date,
        this.mood,
        this.symptoms,
        this.stressLevel,
        this.anxietyLevel,
        this.notes,
        this.sleepQuality});

  DailyLogs.fromJson(Map<String, dynamic> json) {
    date = json['date']?.toString();
    mood = json['mood']?.toString();
    symptoms = json['symptoms'].cast<String>();
    stressLevel = json['stressLevel']?.toString();
    anxietyLevel = json['anxietyLevel']?.toString();
    notes = json['notes']?.toString();
    sleepQuality = json['sleepQuality']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['mood'] = mood;
    data['symptoms'] = symptoms;
    data['stressLevel'] = stressLevel;
    data['anxietyLevel'] = anxietyLevel;
    data['notes'] = notes;
    data['sleepQuality'] = sleepQuality;
    return data;
  }
}

class Appointments {
  String? title;
  String? date;
  String? time;
  bool? reminder;
  String? notes;

  Appointments({this.title, this.date, this.time, this.reminder, this.notes});

  Appointments.fromJson(Map<String, dynamic> json) {
    title = json['title']?.toString();
    date = json['date']?.toString();
    time = json['time']?.toString();
    reminder = json['reminder'];
    notes = json['notes']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['date'] = date;
    data['time'] = time;
    data['reminder'] = reminder;
    data['notes'] = notes;
    return data;
  }
}

class AiInsights {
  String? date;
  List<String>? nutritionTips;
  List<String>? mentalHealthTips;
  List<String>? physicalActivityTips;
  String? fetalGrowthUpdate;
  RiskAssessment? riskAssessment;
  String? aiSummary;

  AiInsights(
      {this.date,
        this.nutritionTips,
        this.mentalHealthTips,
        this.physicalActivityTips,
        this.fetalGrowthUpdate,
        this.riskAssessment,
        this.aiSummary});

  AiInsights.fromJson(Map<String, dynamic> json) {
    date = json['date']?.toString();
    nutritionTips = json['nutritionTips'].cast<String>();
    mentalHealthTips = json['mentalHealthTips'].cast<String>();
    physicalActivityTips = json['physicalActivityTips'].cast<String>();
    fetalGrowthUpdate = json['fetalGrowthUpdate']?.toString();
    riskAssessment = json['riskAssessment'] != null
        ? RiskAssessment.fromJson(json['riskAssessment'])
        : null;
    aiSummary = json['aiSummary']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['nutritionTips'] = nutritionTips;
    data['mentalHealthTips'] = mentalHealthTips;
    data['physicalActivityTips'] = physicalActivityTips;
    data['fetalGrowthUpdate'] = fetalGrowthUpdate;
    if (riskAssessment != null) {
      data['riskAssessment'] = riskAssessment!.toJson();
    }
    data['aiSummary'] = aiSummary;
    return data;
  }
}

class RiskAssessment {
  String? riskLevel;
  String? notes;

  RiskAssessment({this.riskLevel, this.notes});

  RiskAssessment.fromJson(Map<String, dynamic> json) {
    riskLevel = json['riskLevel']?.toString();
    notes = json['notes']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['riskLevel'] = riskLevel;
    data['notes'] = notes;
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
