class Appointment_Data_Model {
  bool? success;
  List<Data>? data;

  Appointment_Data_Model({this.success, this.data});

  Appointment_Data_Model.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
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
  String? sId;

  Data({this.title, this.date, this.time, this.reminder, this.notes, this.sId});

  Data.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    date = json['date'];
    time = json['time'];
    reminder = json['reminder'];
    notes = json['notes'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['date'] = this.date;
    data['time'] = this.time;
    data['reminder'] = this.reminder;
    data['notes'] = this.notes;
    data['_id'] = this.sId;
    return data;
  }
}
