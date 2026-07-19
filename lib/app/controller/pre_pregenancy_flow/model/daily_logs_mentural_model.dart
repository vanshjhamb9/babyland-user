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
  int? sleepQuality;

  MentalHealth? mentalHealth;
  HydrationInfo? hydration;

  Data({
    this.date,
    this.mood,
    this.stressLevel,
    this.anxietyLevel,
    this.symptoms,
    this.notes,
    this.id,
    this.sleepQuality,
    this.mentalHealth,
    this.hydration,
  });

  Data.fromJson(Map<String, dynamic> json) {
    date = json['date']?.toString();
    mood = json['mood']?.toString();
    stressLevel = json['stressLevel']?.toString();
    anxietyLevel = json['anxietyLevel']?.toString();
    if (json['symptoms'] is List) {
      symptoms = (json['symptoms'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      symptoms = [];
    }
    notes = json['notes']?.toString();
    id = json['_id']?.toString();
    sleepQuality = (json['sleepQuality'] as num?)?.toInt();

    mentalHealth = json['mentalHealth'] is Map<String, dynamic>
        ? MentalHealth.fromJson(json['mentalHealth']!)
        : null;
    hydration = json['hydration'] is Map<String, dynamic>
        ? HydrationInfo.fromJson(json['hydration']!)
        : null;
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
    if (sleepQuality != null) data['sleepQuality'] = sleepQuality;
    if (mentalHealth != null) data['mentalHealth'] = mentalHealth!.toJson();
    if (hydration != null) data['hydration'] = hydration!.toJson();
    return data;
  }
}

class MentalHealth {
  final String? mood;
  final String? notes;
  final int? score;

  const MentalHealth({this.mood, this.notes, this.score});

  factory MentalHealth.fromJson(Map<String, dynamic> json) {
    return MentalHealth(
      mood: json['mood']?.toString(),
      notes: json['notes']?.toString(),
      score: (json['score'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mood': mood,
        'notes': notes,
        'score': score,
      };
}

class HydrationInfo {
  final int? waterIntake;
  final int? target;

  const HydrationInfo({this.waterIntake, this.target});

  factory HydrationInfo.fromJson(Map<String, dynamic> json) {
    return HydrationInfo(
      waterIntake: (json['waterIntake'] as num?)?.toInt(),
      target: (json['target'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'waterIntake': waterIntake,
        'target': target,
      };
}

/// Response for GET /menstruals/logs (list of logs, optionally by date)
class MenstrualLogsListModel {
  bool? success;
  String? message;
  List<Data>? data;

  MenstrualLogsListModel({this.success, this.message, this.data});

  factory MenstrualLogsListModel.fromJson(Map<String, dynamic> json) {
    List<Data>? list;
    if (json['data'] != null) {
      if (json['data'] is List) {
        list = (json['data'] as List)
            .map((e) {
              if (e is Map<String, dynamic>) return Data.fromJson(e);
              if (e is Map) return Data.fromJson(Map<String, dynamic>.from(e));
              return null;
            })
            .whereType<Data>()
            .toList();
      } else if (json['data'] is Map<String, dynamic>) {
        list = [Data.fromJson(json['data'] as Map<String, dynamic>)];
      }
    }
    return MenstrualLogsListModel(
      success: json['success'],
      message: json['message']?.toString(),
      data: list ?? [],
    );
  }
}
