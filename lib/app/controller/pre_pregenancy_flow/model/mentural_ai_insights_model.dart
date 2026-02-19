class MenturalAiInsightsModel {
  bool? success;
  String? source;
  DataExit? dataexit;

  MenturalAiInsightsModel({this.success, this.source, this.dataexit});

  MenturalAiInsightsModel.fromJson(Map<String, dynamic> json) {
    // The top-level 'data' field in the API response contains the actual model data
    // So if 'data' exists and is a Map, we parse THAT.
    // Otherwise fallback to parsing the root (incase the structure varies or is already unwrapped)
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
       final dataObj = json['data'];
       success = dataObj['success'];
       source = dataObj['source'];
       dataexit = dataObj['dataexit'] != null ? DataExit.fromJson(dataObj['dataexit']) : null;
    } else {
       // Fallback or direct mapping
       success = json['success'];
       source = json['source'];
       dataexit = json['dataexit'] != null ? DataExit.fromJson(json['dataexit']) : null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['source'] = source;
    if (dataexit != null) {
      data['dataexit'] = dataexit!.toJson();
    }
    return data;
  }
}

class DataExit {
  String? sId;
  String? userId;
  int? week;
  String? category;
  List<InsightItem>? items;
  QuickTip? quickTip;
  String? createdAt;
  String? updatedAt;
  int? iV;

  DataExit(
      {this.sId,
      this.userId,
      this.week,
      this.category,
      this.items,
      this.quickTip,
      this.createdAt,
      this.updatedAt,
      this.iV});

  DataExit.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    week = json['week'];
    category = json['category'];
    if (json['items'] != null) {
      items = <InsightItem>[];
      json['items'].forEach((v) {
        items!.add(InsightItem.fromJson(v));
      });
    }
    quickTip = json['quick_tip'] != null
        ? QuickTip.fromJson(json['quick_tip'])
        : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['userId'] = userId;
    data['week'] = week;
    data['category'] = category;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (quickTip != null) {
      data['quick_tip'] = quickTip!.toJson();
    }
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class InsightItem {
  String? title;
  String? emoji;
  String? description;
  String? sId;

  InsightItem({this.title, this.emoji, this.description, this.sId});

  InsightItem.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    emoji = json['emoji'];
    description = json['description'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['emoji'] = emoji;
    data['description'] = description;
    data['_id'] = sId;
    return data;
  }
}

class QuickTip {
  String? emoji;
  String? text;
  String? sId;

  QuickTip({this.emoji, this.text, this.sId});

  QuickTip.fromJson(Map<String, dynamic> json) {
    emoji = json['emoji'];
    text = json['text'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['emoji'] = emoji;
    data['text'] = text;
    data['_id'] = sId;
    return data;
  }
}
