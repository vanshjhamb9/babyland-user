class FeedingModel {
  bool? success;
  List<Feedings>? feedings;

  FeedingModel({this.success, this.feedings});

  FeedingModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['feedings'] != null) {
      feedings = <Feedings>[];
      json['feedings'].forEach((v) {
        feedings!.add(Feedings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (feedings != null) {
      data['feedings'] = feedings!.map((v) => v.toJson()).toList();
    }
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
    type = json['type'];
    side = json['side'];
    durationMinutes = json['durationMinutes'];
    quantity = json['quantity'];
    notes = json['notes'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
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
