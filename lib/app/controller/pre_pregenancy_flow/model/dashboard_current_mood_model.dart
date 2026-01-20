class DashboardCurrentMood {
  bool? success;
  String? message;
  Data? data;

  DashboardCurrentMood({this.success, this.message, this.data});

  DashboardCurrentMood.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
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
  String? logDate;
  String? mood;
  String? stressLevel;
  String? anxietyLevel;
  List<String>? symptoms;

  Data(
      {this.logDate,
        this.mood,
        this.stressLevel,
        this.anxietyLevel,
        this.symptoms});

  Data.fromJson(Map<String, dynamic> json) {
    logDate = json['logDate']?.toString();
    mood = json['mood']?.toString();
    stressLevel = json['stressLevel']?.toString();
    anxietyLevel = json['anxietyLevel']?.toString();
    symptoms = json['symptoms'] != null ? List<String>.from(json['symptoms']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['logDate'] = logDate;
    data['mood'] = mood;
    data['stressLevel'] = stressLevel;
    data['anxietyLevel'] = anxietyLevel;
    data['symptoms'] = symptoms;
    return data;
  }
}
