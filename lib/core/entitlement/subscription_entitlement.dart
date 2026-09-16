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

SubscriptionEntitlement _tierFromStatusMap(Map<String, dynamic> map) {
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
  if (map['subscriptionActive'] == true) {
    return SubscriptionEntitlement.active;
  }

  return SubscriptionEntitlement.unknown;
}

/// Live API often returns `{ subscriptions: [ {...} ] }` (top-level or under data).
SubscriptionEntitlement subscriptionEntitlementFromPayload(dynamic data) {
  Map<String, dynamic>? map = _unwrapDataMap(data);
  if (map != null && map.containsKey('data') && map['data'] is Map) {
    map = _unwrapDataMap(map['data']);
  }
  if (map == null) {
    if (data is List) {
      for (final item in data) {
        final tier = subscriptionEntitlementFromPayload(item);
        if (tier == SubscriptionEntitlement.active ||
            tier == SubscriptionEntitlement.gracePeriod) {
          return tier;
        }
      }
    }
    return SubscriptionEntitlement.unknown;
  }

  final list = map['subscriptions'];
  if (list is List && list.isNotEmpty) {
    SubscriptionEntitlement best = SubscriptionEntitlement.unknown;
    for (final item in list) {
      final tier = subscriptionEntitlementFromPayload(item);
      if (tier == SubscriptionEntitlement.active) return tier;
      if (tier == SubscriptionEntitlement.gracePeriod) {
        best = tier;
      } else if (best == SubscriptionEntitlement.unknown) {
        best = tier;
      }
    }
    return best;
  }

  return _tierFromStatusMap(map);
}

/// Active / grace subscription map for expiry display, if present.
Map<String, dynamic>? activeSubscriptionMapFromPayload(dynamic data) {
  final map = _unwrapDataMap(data);
  if (map == null) {
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return null;
  }
  final nested = map['data'] is Map ? _unwrapDataMap(map['data']) : map;
  if (nested == null) return null;

  final list = nested['subscriptions'];
  if (list is List) {
    for (final item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final tier = _tierFromStatusMap(m);
      if (tier == SubscriptionEntitlement.active ||
          tier == SubscriptionEntitlement.gracePeriod) {
        return m;
      }
    }
    if (list.isNotEmpty && list.first is Map) {
      return Map<String, dynamic>.from(list.first as Map);
    }
  }

  final tier = _tierFromStatusMap(nested);
  if (tier == SubscriptionEntitlement.active ||
      tier == SubscriptionEntitlement.gracePeriod ||
      nested.containsKey('status') ||
      nested.containsKey('endDate') ||
      nested.containsKey('expiresAt')) {
    return nested;
  }
  return null;
}
