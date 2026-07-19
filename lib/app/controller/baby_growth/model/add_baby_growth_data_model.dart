class Add_Baby_Growth_Data_Model {
  bool? success;
  Baby? baby;

  Add_Baby_Growth_Data_Model({this.success, this.baby});

  Add_Baby_Growth_Data_Model.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    baby = json['baby'] != null ? Baby.fromJson(json['baby']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (baby != null) {
      data['baby'] = baby!.toJson();
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
    photo = json['photo'] != null ? Photo.fromJson(json['photo']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (photo != null) {
      data['photo'] = photo!.toJson();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['height'] = height;
    data['weight'] = weight;
    data['headCircumference'] = headCircumference;
    return data;
  }
}
