// ignore_for_file: public_member_api_docs

/// Parsed from GET `/api/v1/subscriptions/me` payload (authoritative tiers).
enum SubscriptionEntitlement {
  active,
  expired,
  gracePeriod,
  pending,
  unknown,
}

Map<String, dynamic>? _unwrapDataMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

SubscriptionEntitlement subscriptionEntitlementFromPayload(dynamic data) {
  Map<String, dynamic>? map = _unwrapDataMap(data);
  if (map != null && map.containsKey('data') && map['data'] is Map) {
    map = _unwrapDataMap(map['data']);
  }
  if (map == null) return SubscriptionEntitlement.unknown;

  final status = (map['status'] ??
          map['subscriptionStatus'] ??
          map['paymentStatus'] ??
          map['state'])
      ?.toString()
      .toLowerCase()
      .trim();

  if (status != null) {
    if (status.contains('grace')) return SubscriptionEntitlement.gracePeriod;
    if (status.contains('pending') || status.contains('processing')) {
      return SubscriptionEntitlement.pending;
    }
    if (status.contains('expired') || status.contains('lapsed')) {
      return SubscriptionEntitlement.expired;
    }
    if (status == 'active' ||
        status == 'paid' ||
        status == 'completed' ||
        status == 'success') {
      return SubscriptionEntitlement.active;
    }
  }

  final active = map['isActive'] ?? map['active'] ?? map['subscribed'];
  if (active == true) return SubscriptionEntitlement.active;

  return SubscriptionEntitlement.unknown;
}
