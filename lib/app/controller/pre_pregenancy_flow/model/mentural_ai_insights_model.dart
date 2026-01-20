class MenturalAiInsightsModel {
  bool? success;
  String? message;
  List<Data>? data;

  MenturalAiInsightsModel({this.success, this.message, this.data});

  MenturalAiInsightsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? type;
  String? message;
  String? createdAt;

  Data({this.type, this.message, this.createdAt});

  Data.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    message = json['message']?.toString();
    createdAt = json['createdAt']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['message'] = message;
    data['createdAt'] = createdAt;
    return data;
  }
}
