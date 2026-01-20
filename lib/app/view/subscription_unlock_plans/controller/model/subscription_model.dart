class GetAllPlansModel {
  bool? success;
  String? message;
  List<Plans>? plans;

  GetAllPlansModel({this.success, this.message, this.plans});

  GetAllPlansModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['plans'] != null) {
      plans = <Plans>[];
      json['plans'].forEach((v) {
        plans!.add(new Plans.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.plans != null) {
      data['plans'] = this.plans!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Plans {
  String? sId;
  String? name;
  int? price;
  List<Features>? features;
  int? duration;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Plans(
      {this.sId,
        this.name,
        this.price,
        this.features,
        this.duration,
        this.isActive,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Plans.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    price = json['price'];
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(new Features.fromJson(v));
      });
    }
    duration = json['duration'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['price'] = this.price;
    if (this.features != null) {
      data['features'] = this.features!.map((v) => v.toJson()).toList();
    }
    data['duration'] = this.duration;
    data['isActive'] = this.isActive;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Features {
  String? sId;
  bool? active;
  String? name;

  Features({this.sId, this.active, this.name});

  Features.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    active = json['active'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['active'] = this.active;
    data['name'] = this.name;
    return data;
  }
}
