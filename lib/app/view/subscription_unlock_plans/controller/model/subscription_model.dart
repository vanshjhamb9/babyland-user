// ignore_for_file: camel_case_types, unnecessary_new, prefer_collection_literals, unnecessary_this

import 'package:babyland/core/entitlement/subscription_entitlement.dart';

/// Response from GET `/api/v1/subscriptions/me` (canonical; plural `subscriptions`).
class Subscription_Data_Model {
  bool? success;
  String? message;
  dynamic data;

  Subscription_Data_Model({this.success, this.message, this.data});

  Subscription_Data_Model.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> out = <String, dynamic>{};
    out['success'] = success;
    out['message'] = message;
    out['data'] = data;
    return out;
  }

  /// Strict tier from API (prefer over string heuristics for new code).
  SubscriptionEntitlement get resolvedEntitlement =>
      subscriptionEntitlementFromPayload(data);

  bool get hasActiveSubscription {
    final tier = resolvedEntitlement;
    if (tier == SubscriptionEntitlement.active ||
        tier == SubscriptionEntitlement.gracePeriod) {
      return true;
    }
    final value = data;
    if (value is Map) {
      return _isActiveSubscriptionMap(value);
    }
    if (value is List) {
      return value.whereType<Map>().any(_isActiveSubscriptionMap);
    }
    return false;
  }

  static bool _isActiveSubscriptionMap(Map<dynamic, dynamic> map) {
    final status = (map['status'] ??
            map['subscriptionStatus'] ??
            map['paymentStatus'] ??
            map['state'])
        ?.toString()
        .toLowerCase()
        .trim();
    final active = map['isActive'] ?? map['active'] ?? map['subscribed'];
    if (active == true) return true;
    if (status == null) return false;
    return status == 'active' ||
        status == 'paid' ||
        status == 'completed' ||
        status == 'success';
  }
}

class GetAllPlansModel {
  bool? success;
  String? message;
  List<Plans>? plans;

  GetAllPlansModel({this.success, this.message, this.plans});

  GetAllPlansModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    final rawPlans = json['plans'] ??
        (json['data'] is Map ? (json['data'] as Map)['plans'] : null) ??
        (json['data'] is List ? json['data'] : null);
    if (rawPlans != null) {
      plans = <Plans>[];
      rawPlans.forEach((v) {
        if (v is Map<String, dynamic>) {
          plans!.add(Plans.fromJson(v));
        } else if (v is Map) {
          plans!.add(Plans.fromJson(Map<String, dynamic>.from(v)));
        }
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

/// GET `/api/v1/plans/public` | `/plans/get-all` — backend contract (Section A).
class Plans {
  String? sId;
  String? name;
  /// Display-only rupees (whole INR); never derive PhonePe amount from this alone.
  num? price;
  /// Canonical money for checkout UI (integer paise). **Do not** compute `price * 100` client-side.
  int? amountPaise;
  String? currency;
  List<String>? featureNames;
  List<Features>? features;
  int? duration;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Plans({
    this.sId,
    this.name,
    this.price,
    this.amountPaise,
    this.currency,
    this.featureNames,
    this.features,
    this.duration,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  /// Rupees for display — prefer [amountPaise] / 100 per backend contract.
  double get amountRupeesForDisplay {
    if (amountPaise != null && amountPaise! > 0) {
      return amountPaise! / 100.0;
    }
    final p = price;
    if (p != null && p > 0) return p.toDouble();
    return 0;
  }

  Plans.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    final rawPrice = json['price'];
    if (rawPrice is num) {
      price = rawPrice;
    } else {
      price = num.tryParse(rawPrice?.toString() ?? '');
    }
    final rawPaise = json['amountPaise'];
    if (rawPaise is int) {
      amountPaise = rawPaise;
    } else if (rawPaise != null) {
      amountPaise = int.tryParse(rawPaise.toString());
    }
    currency = json['currency']?.toString();
    if (json['featureNames'] is List) {
      featureNames = (json['featureNames'] as List)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(Features.fromJson(v));
      });
    }
    duration = json['duration'] is int
        ? json['duration'] as int
        : int.tryParse(json['duration']?.toString() ?? '');
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
    data['amountPaise'] = this.amountPaise;
    data['currency'] = this.currency;
    data['featureNames'] = this.featureNames;
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
