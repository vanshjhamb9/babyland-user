class GetBabyPhotosModel {
  bool? success;
  List<Photos>? photos;

  GetBabyPhotosModel({this.success, this.photos});

  GetBabyPhotosModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['photos'] != null) {
      photos = <Photos>[];
      json['photos'].forEach((v) {
        photos!.add(Photos.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (photos != null) {
      data['photos'] = photos!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Photos {
  String? date;
  String? caption;
  String? photoUrl;
  String? sId;
  String? createdAt;
  String? updatedAt;

  Photos({this.date, this.caption, this.sId, this.createdAt, this.updatedAt});

  Photos.fromJson(Map<String, dynamic> json) {
    date = json['date']?.toString();
    caption = json['caption']?.toString();
    photoUrl = json['photoUrl']?.toString();
    sId = json['_id']?.toString();
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['photoUrl'] = photoUrl;
    data['caption'] = caption;
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
