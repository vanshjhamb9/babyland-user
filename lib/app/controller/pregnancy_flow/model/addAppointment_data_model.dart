class AddAppointment_Data_Model {
  bool? success;
  String? message;
  Data? data;

  AddAppointment_Data_Model({this.success, this.message, this.data});

  AddAppointment_Data_Model.fromJson(Map<String, dynamic> json) {
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
  String? title;
  String? date;
  String? time;
  bool? reminder;
  String? notes;

  Data({this.title, this.date, this.time, this.reminder, this.notes});

  Data.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    date = json['date'];
    time = json['time'];
    reminder = json['reminder'];
    notes = json['notes'];
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
