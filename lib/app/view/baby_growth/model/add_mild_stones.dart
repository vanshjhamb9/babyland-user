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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    data['success'] = this.success;
    data['date'] = this.date;
    data['title'] = this.title;
    data['photo'] = this.photo;
    data['note'] = this.note;
    return data;
  }
}
