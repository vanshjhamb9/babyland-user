class Add_Baby_Growth_Data_Model {
  bool? success;
  Baby? baby;

  Add_Baby_Growth_Data_Model({this.success, this.baby});

  Add_Baby_Growth_Data_Model.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    baby = json['baby'] != null ? new Baby.fromJson(json['baby']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.baby != null) {
      data['baby'] = this.baby!.toJson();
    }
    return data;
  }
}

class Baby {
  String? message;
  Photo? photo;

  Baby({this.message, this.photo});

  Baby.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    photo = json['photo'] != null ? new Photo.fromJson(json['photo']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.photo != null) {
      data['photo'] = this.photo!.toJson();
    }
    return data;
  }
}

class Photo {
  String? date;
  String? height;
  String? weight;
  String? headCircumference;

  Photo({this.date, this.height, this.weight, this.headCircumference});

  Photo.fromJson(Map<String, dynamic> json) {
    date = json['date']?.toString();
    height = json['height']?.toString();
    weight = json['weight']?.toString();
    headCircumference = json['headCircumference']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['height'] = this.height;
    data['weight'] = this.weight;
    data['headCircumference'] = this.headCircumference;
    return data;
  }
}
