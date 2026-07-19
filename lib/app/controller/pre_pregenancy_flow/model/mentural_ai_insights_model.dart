class MenturalAiInsightsModel {
  bool? success;
  String? source;
  DataExit? dataexit;
  String? message;
  String? errorCode;

  MenturalAiInsightsModel({
    this.success,
    this.source,
    this.dataexit,
    this.message,
    this.errorCode,
  });

  /// User-facing text for toasts when [success] is not true.
  String get displayMessage {
    if (message != null && message!.trim().isNotEmpty) return message!.trim();
    switch (errorCode) {
      case 'NO_SUBSCRIPTION':
        return 'This feature requires an active subscription.';
      case 'FEATURE_NOT_INCLUDED':
        return 'Your plan does not include this feature.';
      default:
        return 'Something went wrong!';
    }
  }

  bool get isSubscriptionError =>
      errorCode == 'NO_SUBSCRIPTION' ||
      errorCode == 'FEATURE_NOT_INCLUDED' ||
      rootRequiresSubscription == true ||
      rootRequiresUpgrade == true;

  bool? rootRequiresSubscription;
  bool? rootRequiresUpgrade;

  MenturalAiInsightsModel.fromJson(Map<String, dynamic> json) {
    final root = _asMap(json);
    if (root == null) return;

    message = root['message']?.toString();
    final err = _asMap(root['error']);
    if (err != null) {
      errorCode = err['code']?.toString();
      message ??= err['message']?.toString();
    }
    rootRequiresSubscription = root['requiresSubscription'] == true;
    rootRequiresUpgrade = root['requiresUpgrade'] == true;

    final nested = _asMap(root['data']);
    if (nested != null) {
      success = nested['success'] ?? root['success'];
      source = nested['source']?.toString() ?? root['source']?.toString();
      dataexit = _parseDataExit(nested['dataexit'] ?? root['dataexit']);
    } else {
      success = root['success'];
      source = root['source']?.toString();
      dataexit = _parseDataExit(root['dataexit']);
    }
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static DataExit? _parseDataExit(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return DataExit.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['source'] = source;
    data['message'] = message;
    if (errorCode != null) {
      data['error'] = {'code': errorCode};
    }
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
    if (json['items'] is List) {
      items = <InsightItem>[];
      for (final v in json['items'] as List) {
        final map = MenturalAiInsightsModel._asMap(v);
        if (map != null) items!.add(InsightItem.fromJson(map));
      }
    }
    final tipMap = MenturalAiInsightsModel._asMap(json['quick_tip']);
    quickTip = tipMap != null ? QuickTip.fromJson(tipMap) : null;
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
