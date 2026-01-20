class RecoveryProgressModel {
  bool? success;
  String? message;
  Tasks? tasks;

  RecoveryProgressModel({this.success, this.tasks,this.message});

  RecoveryProgressModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    tasks = json['tasks'] != null ? Tasks.fromJson(json['tasks']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (tasks != null) {
      data['tasks'] = tasks!.toJson();
    }
    return data;
  }
}

class Tasks {
  String? totalTasks;
  String? completedTasks;
  String? completionPercentage;
  List<Tasks1>? tasks;
  String? logDate;
  String? mood;
  String? stressLevel;
  String? anxietyLevel;
  List<dynamic>? symptoms;
  List<Feedings>? feedings;

  Tasks(
      {this.totalTasks,
        this.completedTasks,
        this.completionPercentage,
        this.tasks,
        this.logDate,
        this.mood,
        this.stressLevel,
        this.anxietyLevel,
        this.symptoms,
        this.feedings});

  Tasks.fromJson(Map<String, dynamic> json) {
    totalTasks = json['totalTasks']?.toString();
    completedTasks = json['completedTasks']?.toString();
    completionPercentage = json['completionPercentage']?.toString();
    if (json['tasks'] != null) {
      tasks = <Tasks1>[];
      json['tasks'].forEach((v) {
        tasks!.add(Tasks1.fromJson(v));
      });
    }
    logDate = json['logDate']?.toString();
    mood = json['mood']?.toString();
    stressLevel = json['stressLevel']?.toString();
    anxietyLevel = json['anxietyLevel']?.toString();
    if (json['symptoms'] != null) {
      symptoms = <Null>[];
      json['symptoms'].forEach((v) {
        // symptoms!.add(Null.fromJson(v));
      });
    }
    if (json['feedings'] != null) {
      feedings = <Feedings>[];
      json['feedings'].forEach((v) {
        feedings!.add(Feedings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalTasks'] = totalTasks;
    data['completedTasks'] = completedTasks;
    data['completionPercentage'] = completionPercentage;
    if (tasks != null) {
      data['tasks'] = tasks!.map((v) => v.toJson()).toList();
    }
    data['logDate'] = logDate;
    data['mood'] = mood;
    data['stressLevel'] = stressLevel;
    data['anxietyLevel'] = anxietyLevel;
    if (symptoms != null) {
      data['symptoms'] = symptoms!.map((v) => v.toJson()).toList();
    }
    if (feedings != null) {
      data['feedings'] = feedings!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Tasks1 {
  String? task;
  String? taskCompleted;
  String? dateAssigned;
  String? dueDate;
  bool? completed;
  String? sId;
  String? dateCompleted;

  Tasks1(
      {this.task,
        this.taskCompleted,
        this.dateAssigned,
        this.dueDate,
        this.completed,
        this.sId,
        this.dateCompleted});

  Tasks1.fromJson(Map<String, dynamic> json) {
    task = json['task']?.toString();
    taskCompleted = json['taskCompleted']?.toString();
    dateAssigned = json['dateAssigned']?.toString();
    dueDate = json['dueDate']?.toString();
    completed = json['completed'];
    sId = json['_id']?.toString();
    dateCompleted = json['dateCompleted']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['task'] = task;
    data['taskCompleted'] = taskCompleted;
    data['dateAssigned'] = dateAssigned;
    data['dueDate'] = dueDate;
    data['completed'] = completed;
    data['_id'] = sId;
    data['dateCompleted'] = dateCompleted;
    return data;
  }
}

class Feedings {
  String? time;
  String? type;
  String? side;
  String? durationMinutes;
  String? quantity;
  String? notes;
  String? sId;
  String? createdAt;
  String? updatedAt;

  Feedings(
      {this.time,
        this.type,
        this.side,
        this.durationMinutes,
        this.quantity,
        this.notes,
        this.sId,
        this.createdAt,
        this.updatedAt});

  Feedings.fromJson(Map<String, dynamic> json) {
    time = json['time']?.toString();
    type = json['type']?.toString();
    side = json['side']?.toString();
    durationMinutes = json['durationMinutes']?.toString();
    quantity = json['quantity']?.toString();
    notes = json['notes']?.toString();
    sId = json['_id']?.toString();
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['time'] = time;
    data['type'] = type;
    data['side'] = side;
    data['durationMinutes'] = durationMinutes;
    data['quantity'] = quantity;
    data['notes'] = notes;
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
