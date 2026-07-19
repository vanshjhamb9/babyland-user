class AddMildStones {
  String? message;
  bool? success;
  String? date;
  String? title;
  String? photo;
  String? note;

  AddMildStones(
      {this.message,
        this.success,
        this.date,
        this.title,
        this.photo,
        this.note});

  AddMildStones.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    success = json['success'];
    date = json['date'];
    title = json['title'];
    photo = json['photo'];
    note = json['note'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['success'] = success;
    data['date'] = date;
    data['title'] = title;
    data['photo'] = photo;
    data['note'] = note;
    return data;
  }
}
