class DailyLogsMenturalModel {
  bool? success;
  String? message;
  Data? data;

  DailyLogsMenturalModel({this.success, this.message, this.data});

  DailyLogsMenturalModel.fromJson(Map<String, dynamic> json) {
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
  String? date;
  String? mood;
  String? stressLevel;
  String? anxietyLevel;
  List<String>? symptoms;
  String? notes;
  String? id;

  Data({
    this.date,
    this.mood,
    this.stressLevel,
    this.anxietyLevel,
    this.symptoms,
    this.notes,
    this.id,
  });

  Data.fromJson(Map<String, dynamic> json) {
    date = json['date']?.toString();
    mood = json['mood']?.toString();
    stressLevel = json['stressLevel']?.toString();
    anxietyLevel = json['anxietyLevel']?.toString();
    symptoms = json['symptoms'] != null
        ? List<String>.from(json['symptoms'])
        : [];
    notes = json['notes']?.toString();
    id = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['mood'] = mood;
    data['stressLevel'] = stressLevel;
    data['anxietyLevel'] = anxietyLevel;
    data['symptoms'] = symptoms;
    data['notes'] = notes;
    data['_id'] = id;
    return data;
  }
}
