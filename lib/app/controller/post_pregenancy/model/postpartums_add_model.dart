class PostpartumsAddModel {
  bool? success;
  String? message;
  Task? task;

  PostpartumsAddModel({this.success, this.message, this.task});

  PostpartumsAddModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    task = json['task'] != null ? Task.fromJson(json['task']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (task != null) {
      data['task'] = task!.toJson();
    }
    return data;
  }
}

class Task {
  String? task;
  String? dateAssigned;
  String? dueDate;
  bool? completed;
  String? dateCompleted;
  String? sId;

  Task(
      {this.task,
        this.dateAssigned,
        this.dueDate,
        this.completed,
        this.dateCompleted,
        this.sId});

  Task.fromJson(Map<String, dynamic> json) {
    task = json['task']?.toString();
    dateAssigned = json['dateAssigned']?.toString();
    dueDate = json['dueDate']?.toString();
    completed = json['completed'];
    dateCompleted = json['dateCompleted']?.toString();
    sId = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['task'] = task;
    data['dateAssigned'] = dateAssigned;
    data['dueDate'] = dueDate;
    data['completed'] = completed;
    data['dateCompleted'] = dateCompleted;
    data['_id'] = sId;
    return data;
  }
}
