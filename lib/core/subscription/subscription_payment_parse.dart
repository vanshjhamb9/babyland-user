// ignore_for_file: public_member_api_docs

import 'package:babyland/app/common_model/common_model.dart';

/// Typed view of `POST /api/v1/subscriptions/add` → `data` (Section A §2.3).
///
/// The backend emits this exact shape; legacy fields (`redirect_url`,
/// `paymentUrl`) are preserved for older clients. New code should bind to
/// [redirectUrl] and [amountPaise].
class SubscriptionAddResponse {
  const SubscriptionAddResponse({
    this.paymentType,
    this.merchantTransactionId,
    this.redirectUrl,
    this.redirectUrlSnakeCase,
    this.paymentUrl,
    this.subscriptionId,
    this.amountPaise,
    this.currency,
    this.idempotentReplay = false,
    this.dedupeReason,
  });

  /// Always `"SUBSCRIPTION"` for this endpoint.
  final String? paymentType;

  /// PhonePe-side transaction id (≤48 chars). Echo to status-poll / reconciliation.
  final String? merchantTransactionId;

  /// PhonePe checkout URL — prefer this for new code.
  final String? redirectUrl;

  /// Snake-case alias of [redirectUrl] (identical value); kept for older clients.
  final String? redirectUrlSnakeCase;

  /// Same value as [redirectUrl]; alias used by some legacy callers.
  final String? paymentUrl;

  /// Pending `Subscription` document `_id`. Useful for `/subscription/me` correlation.
  final String? subscriptionId;

  /// Canonical money field, integer paise. Source of truth for the amount line.
  final int? amountPaise;

  /// Currency code (always `"INR"` today).
  final String? currency;

  /// `true` when the server returned an existing PhonePe order (deduped).
  /// Skip "creating order" spinner; reuse [redirectUrl] verbatim.
  final bool idempotentReplay;

  /// Present only on dedupe: e.g. `"in_flight_intent"`. Telemetry only.
  final String? dedupeReason;

  /// Preferred launch URL — picks the first present alias.
  String? get effectiveRedirectUrl =>
      _firstNonEmpty([redirectUrl, redirectUrlSnakeCase, paymentUrl]);

  /// Rupees, computed from [amountPaise] when present.
  /// Returns `null` if no authoritative amount was emitted.
  double? get amountRupees {
    final p = amountPaise;
    if (p == null || p <= 0) return null;
    return p / 100.0;
  }

  /// Display-ready amount line; uses the contract's "₹ N" format for INR.
  String? formatAmount() {
    final rupees = amountRupees;
    if (rupees == null) return null;
    final symbol = (currency ?? 'INR') == 'INR' ? '₹' : currency!;
    return '$symbol ${rupees.toStringAsFixed(0)}';
  }

  factory SubscriptionAddResponse.fromCommonResponse(
    CommonResponseModel value,
  ) {
    final data = value.data;
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    final amountPaise = _readInt(map, const ['amountPaise', 'amount_paise']);
    final merchant = _readMerchantTransactionId(map);
    final redirect = _readString(map, const ['redirectUrl']) ??
        _extractRedirectFromNested(map);
    final redirectSnake = _readString(map, const ['redirect_url']);
    final paymentUrl = _readString(map, const ['paymentUrl', 'payment_url']);

    return SubscriptionAddResponse(
      paymentType: _readString(map, const ['paymentType', 'payment_type']),
      merchantTransactionId: merchant,
      redirectUrl: redirect,
      redirectUrlSnakeCase: redirectSnake,
      paymentUrl: paymentUrl,
      subscriptionId: _readString(map, const ['subscriptionId', 'subscription_id']),
      amountPaise: amountPaise,
      currency: _readString(map, const ['currency']),
      idempotentReplay: map['idempotentReplay'] == true ||
          map['idempotent_replay'] == true,
      dedupeReason: _readString(map, const ['dedupeReason', 'dedupe_reason']),
    );
  }
}

/// Extract merchant / PSP transaction id from add-subscription response.
///
/// Retained for legacy callers; new code should use
/// [SubscriptionAddResponse.fromCommonResponse] and read `merchantTransactionId`.
String? readSubscriptionMerchantTransactionId(CommonResponseModel value) {
  return SubscriptionAddResponse.fromCommonResponse(value).merchantTransactionId;
}

/// Authoritative checkout rupees from `POST /subscriptions/add` → `data.amountPaise` (Section A).
///
/// Retained for legacy callers; new code should use
/// [SubscriptionAddResponse.amountRupees].
double? readSubscriptionCheckoutAmountRupees(CommonResponseModel value) {
  return SubscriptionAddResponse.fromCommonResponse(value).amountRupees;
}

bool readSubscriptionIdempotentReplay(CommonResponseModel value) {
  return SubscriptionAddResponse.fromCommonResponse(value).idempotentReplay;
}

// ───── internal parsing helpers ────────────────────────────────────────────

String? _readString(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return null;
}

int? _readInt(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v == null) continue;
    if (v is int) return v;
    final n = num.tryParse(v.toString());
    if (n != null) return n.toInt();
  }
  return null;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final v in values) {
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

/// Walks the legacy nested places where merchant id may have been emitted
/// (payment.merchantTransactionId, phonepe.transactionId, instrumentResponse.*).
String? _readMerchantTransactionId(Map<String, dynamic> root) {
  const keys = [
    'merchantTransactionId',
    'merchant_transaction_id',
    'transactionId',
    'transaction_id',
  ];
  final direct = _readString(root, keys);
  if (direct != null) return direct;

  for (final parentKey in const ['payment', 'phonePe', 'phonepe', 'instrumentResponse']) {
    final nested = root[parentKey];
    if (nested is Map) {
      final v = _readString(Map<String, dynamic>.from(nested), keys);
      if (v != null) return v;
    }
  }
  return null;
}

/// Fallback redirect URL extraction from the legacy nested PhonePe response
/// (`instrumentResponse.redirectInfo.url`).
String? _extractRedirectFromNested(Map<String, dynamic> root) {
  for (final parentKey in const ['payment', 'phonePe', 'phonepe', 'instrumentResponse']) {
    final nested = root[parentKey];
    if (nested is! Map) continue;
    final map = Map<String, dynamic>.from(nested);

    final direct = _readString(map, const [
      'redirectUrl',
      'redirect_url',
      'paymentUrl',
      'payment_url',
    ]);
    if (direct != null) return direct;

    final redirectInfo = map['redirectInfo'] ?? map['redirect_info'];
    if (redirectInfo is Map) {
      final ri = Map<String, dynamic>.from(redirectInfo);
      final u = _readString(ri, const ['url', 'targetUrl']);
      if (u != null) return u;
    }
  }
  return null;
}
