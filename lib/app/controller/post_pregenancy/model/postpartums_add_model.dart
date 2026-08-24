class PostpartumsAddModel {
  bool? success;
  String? message;
  Task? task;

  PostpartumsAddModel({this.success, this.message, this.task});

  /// Parses add/start responses that may wrap the profile in `data` or `task`.
  /// Never throws on unexpected shapes — that previously stuck onboarding.
  factory PostpartumsAddModel.fromResponse(dynamic response) {
    final map = _asStringKeyedMap(response);
    if (map == null) {
      return PostpartumsAddModel(
        success: false,
        message: response?.toString() ?? 'Invalid postpartum response',
      );
    }
    return PostpartumsAddModel.fromJson(map);
  }

  PostpartumsAddModel.fromJson(Map<String, dynamic> json) {
    success = json['success'] == true;
    message = json['message']?.toString();
    task = _parseTask(json['task']) ?? _parseTask(json['data']);
  }

  static bool isAlreadyExists(String? message) {
    final m = (message ?? '').toLowerCase();
    return m.contains('already exists') ||
        m.contains('already exist') ||
        m.contains('already created') ||
        m.contains('already have') ||
        m.contains('duplicate') ||
        m.contains('e11000');
  }

  static Task? _parseTask(dynamic raw) {
    final map = _asStringKeyedMap(raw);
    if (map == null) return null;
    return Task.fromJson(map);
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
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
    completed = json['completed'] == true;
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
