class GroupDataModel {
  bool? success;
  String? message;
  List<GroupModel>? data;

  GroupDataModel({this.success, this.message, this.data});

  GroupDataModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <GroupModel>[];
      json['data'].forEach((v) {
        data!.add(GroupModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};
    dataMap['success'] = success;
    dataMap['message'] = message;
    if (data != null) {
      dataMap['data'] = data!.map((v) => v.toJson()).toList();
    }
    return dataMap;
  }
}

class GroupModel {
  String? sId;
  String? name;
  String? description;
  String? image;
  int? membersCount;

  GroupModel({
    this.sId,
    this.name,
    this.description,
    this.image,
    this.membersCount,
  });

  GroupModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    image = json['image'];
    // In some APIs count comes as a distinct field or length of array
    membersCount = json['membersCount'] ?? (json['members'] as List?)?.length;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};
    dataMap['_id'] = sId;
    dataMap['name'] = name;
    dataMap['description'] = description;
    dataMap['image'] = image;
    dataMap['membersCount'] = membersCount;
    return dataMap;
  }
}
