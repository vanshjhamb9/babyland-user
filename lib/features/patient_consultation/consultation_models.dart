// DTOs for patient consultation checkout.
//
// Backend contract (Section B): the consultation amount is computed server-side
// at slot-lock time and frozen on `consultations.amount_paise` for the row's
// lifetime. Every downstream endpoint quotes that same `amountPaise` integer.
// The Flutter app MUST NOT recompute amounts from `doctorDetails.consultationFee`
// — admin fee + tax are env-driven and only the server knows the total.
//
// ignore_for_file: public_member_api_docs
class SlotHold {
  SlotHold({
    required this.lockToken,
    required this.expiresAtUtc,
    required this.clientRequestId,
    this.consultationDraftId,
    required this.doctorId,
    required this.slotDate,
    required this.slotTime,
    this.amountPaise,
    this.currency,
    this.pricing,
  });

  final String lockToken;
  final DateTime expiresAtUtc;

  /// Idempotency key for the **slot-lock** call only.
  ///
  /// IMPORTANT: per §11, the PhonePe-intent call must use a **different** UUID
  /// (mixing them returns `409 clientRequestId does not match this lock`).
  final String clientRequestId;
  final String? consultationDraftId;
  final String doctorId;

  /// `yyyy-MM-dd` as understood by consultation slot APIs.
  final String slotDate;

  /// Human-readable time label (must match availability API semantics).
  final String slotTime;

  /// Canonical final amount the patient will pay (integer paise) — same value
  /// echoed by `/phonepe/intent` and the projection. Section B §9.
  final int? amountPaise;

  /// Currency code (always `"INR"` today).
  final String? currency;

  /// Server-computed invoice breakdown (doctor fee + admin fee + tax).
  /// On idempotent replays the breakdown may degrade to `{totalPaise, currency}`
  /// only — the locked-in amount still wins.
  final ConsultationPricing? pricing;

  bool isExpiredAt(DateTime nowUtc) =>
      nowUtc.isAfter(expiresAtUtc) || nowUtc.isAtSameMomentAs(expiresAtUtc);

  /// Display-ready amount line (e.g. `"₹ 500"`) sourced from [amountPaise].
  /// Returns `null` if the server didn't quote a final amount.
  String? formatAmount() => _formatPaise(amountPaise, currency);
}

/// Server-computed invoice breakdown returned by `/slot-lock` (§9).
///
/// Breakdown fields may be absent on idempotent replays — only [totalPaise]
/// and [currency] are guaranteed. UIs that show a line-by-line invoice
/// should fall back to hiding individual rows when the components are null.
class ConsultationPricing {
  const ConsultationPricing({
    this.doctorFeePaise,
    this.adminFeePaise,
    this.taxablePaise,
    this.taxPercent,
    this.taxPaise,
    required this.totalPaise,
    this.currency,
  });

  final int? doctorFeePaise;
  final int? adminFeePaise;
  final int? taxablePaise;
  final num? taxPercent;
  final int? taxPaise;

  /// Always quoted (mirrors `SlotHold.amountPaise`).
  final int totalPaise;
  final String? currency;

  bool get hasBreakdown =>
      doctorFeePaise != null ||
      adminFeePaise != null ||
      taxablePaise != null ||
      taxPaise != null;

  static ConsultationPricing? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final total = _readInt(m, const ['totalPaise', 'total_paise']);
    if (total == null) return null;
    return ConsultationPricing(
      doctorFeePaise: _readInt(m, const ['doctorFeePaise', 'doctor_fee_paise']),
      adminFeePaise: _readInt(m, const ['adminFeePaise', 'admin_fee_paise']),
      taxablePaise: _readInt(m, const ['taxablePaise', 'taxable_paise']),
      taxPercent: _readNum(m, const ['taxPercent', 'tax_percent']),
      taxPaise: _readInt(m, const ['taxPaise', 'tax_paise']),
      totalPaise: total,
      currency: _readString(m, const ['currency']),
    );
  }
}

/// Created after PSP intent API; payment truth still unknown until webhook → projection query.
class PhonePeLaunch {
  PhonePeLaunch({
    required this.merchantTransactionId,
    required this.paymentLaunchUrl,
    this.consultationId,
    this.amountPaise,
    this.currency,
    this.rawResponseHash,
  });

  final String merchantTransactionId;
  final String paymentLaunchUrl;

  /// When server creates draft consultation before redirect.
  final String? consultationId;

  /// Authoritative final amount echoed by `/phonepe/intent` — same value as
  /// `/slot-lock`. Section B §11. Bind the "Pay now" sheet to this.
  final int? amountPaise;
  final String? currency;

  /// Optional fingerprint to detect accidental duplicate intents (analytics / support).
  final String? rawResponseHash;

  String? formatAmount() => _formatPaise(amountPaise, currency);
}

class PendingConsultationPayment {
  PendingConsultationPayment({
    required this.lockToken,
    required this.clientRequestId,
    required this.merchantTransactionId,
    this.consultationId,
    this.savedAtUtc,
  });

  final String lockToken;

  /// Slot-lock's idempotency key. The PhonePe-intent call uses a separate id.
  final String clientRequestId;
  final String merchantTransactionId;
  final String? consultationId;
  final DateTime? savedAtUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'lockToken': lockToken,
    'clientRequestId': clientRequestId,
    'merchantTransactionId': merchantTransactionId,
    if (consultationId != null && consultationId!.isNotEmpty)
      'consultationId': consultationId,
    'savedAtUtc': (savedAtUtc ?? DateTime.now().toUtc()).toIso8601String(),
  };

  Map<String, dynamic> toRouteArguments() => <String, dynamic>{
    'merchantTransactionId': merchantTransactionId,
    if (consultationId != null && consultationId!.isNotEmpty)
      'consultationId': consultationId,
  };
}

PendingConsultationPayment? pendingConsultationPaymentFromJson(
  Map<String, dynamic>? json,
) {
  if (json == null) return null;
  final lockToken = _readString(json, const ['lockToken']);
  final clientRequestId = _readString(json, const ['clientRequestId']);
  final merchantTransactionId = _readString(json, const [
    'merchantTransactionId',
  ]);
  if (lockToken == null ||
      lockToken.isEmpty ||
      clientRequestId == null ||
      clientRequestId.isEmpty ||
      merchantTransactionId == null ||
      merchantTransactionId.isEmpty) {
    return null;
  }
  return PendingConsultationPayment(
    lockToken: lockToken,
    clientRequestId: clientRequestId,
    merchantTransactionId: merchantTransactionId,
    consultationId: _readString(json, const ['consultationId']),
    savedAtUtc: _readDateTime(json, const ['savedAtUtc']),
  );
}

/// Doctor reference embedded in the projection (`projection.doctor.*`, §12).
class DoctorRef {
  const DoctorRef({this.id, this.name, this.specialization, this.image});

  final String? id;
  final String? name;
  final String? specialization;
  final String? image;

  static DoctorRef? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = _readString(m, const ['id', '_id', 'doctorId']);
    final name = _readString(m, const ['name', 'fullName', 'doctorName']);
    final spec = _readString(m, const [
      'specialization',
      'speciality',
      'specialty',
    ]);
    final image = _readString(m, const [
      'image',
      'profileImage',
      'profileImageUrl',
      'photo',
    ]);
    if (id == null && name == null && spec == null && image == null) {
      return null;
    }
    return DoctorRef(id: id, name: name, specialization: spec, image: image);
  }
}

/// Agora meeting info embedded in the projection (`projection.meeting.*`, §12).
///
/// [channelName] is unique-per-consultation (format `consultation:<uuid>`) and
/// is the **only** valid channel string to pass to `/agoras/rtc`. The legacy
/// constant `"videoCall"` is a hard FAIL on the backend (§14).
class MeetingInfo {
  const MeetingInfo({
    required this.channelName,
    this.sessionId,
    this.agoraEnabled,
  });

  /// Unique per consultation. Pass verbatim to Agora SDK + token endpoint.
  final String channelName;

  /// Equals the `consultationId`; used by the canonical Agora endpoint.
  final String? sessionId;

  /// `false` when `AGORA_APP_ID` isn't configured server-side — disable Join UI.
  final bool? agoraEnabled;

  bool get isAgoraEnabled => agoraEnabled != false;

  /// Channel names emitted by the backend look like `consultation:<uuid>`.
  /// Reject the legacy `"videoCall"` constant defensively at the boundary.
  bool get isCanonical =>
      channelName.isNotEmpty &&
      channelName != 'videoCall' &&
      channelName.startsWith('consultation:');

  static MeetingInfo? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final channel = _readString(m, const ['channelName', 'channel_name']);
    if (channel == null || channel.isEmpty) return null;
    return MeetingInfo(
      channelName: channel,
      sessionId: _readString(m, const ['sessionId', 'session_id']),
      agoraEnabled: _readBool(m, const ['agoraEnabled', 'agora_enabled']),
    );
  }
}

/// Read model from PostgreSQL-backed projection endpoint (polling only — never inferred client-side).
///
/// Per the contract (§12), responses carry two layers:
///   1. top-level canonical (new code) — `consultationId`, `lifecycleState`,
///      `paymentStatus`, `doctor`, `meeting`, `amountPaise`, `joinAllowed`, etc.
///   2. `data` envelope (legacy) — duplicates the same fields under different names.
///
/// This parser unwraps the legacy `data` wrapper when present and prefers
/// top-level fields when both exist.
class ConsultationProjection {
  ConsultationProjection({
    this.consultationId,
    this.bookingId,
    this.paymentStatus,
    this.consultationStatus,
    this.lifecycleState,
    this.merchantTransactionId,
    this.failureReason,
    this.lifecycleStage,
    this.doctor,
    this.meeting,
    this.scheduledAtUtc,
    this.timezone,
    this.joinAllowed,
    this.joinableFromUtc,
    this.joinableUntilUtc,
    this.amountPaise,
    this.currency,
    this.slotDate,
    this.slotTime,
    this.raw,
  });

  final String? consultationId;

  /// Mongo Booking mirror `_id` (derived from `consultationId`). Older "My
  /// Bookings" screens key on this.
  final String? bookingId;

  /// e.g. `PENDING_PROCESSING | PAID | FAILED` (uppercase/lowercase tolerated).
  final String? paymentStatus;

  /// Raw PG `consultations.status`: `SLOT_HELD | AWAITING_PAYMENT | SCHEDULED |
  /// CANCELLED_*`. Legacy field — new code should bind to [lifecycleState].
  final String? consultationStatus;

  /// Canonical top-level field (§12): drives the booking-card UI state.
  /// Values: `SLOT_HELD | AWAITING_PAYMENT | SCHEDULED | READY_TO_JOIN |
  /// IN_PROGRESS | COMPLETED | CANCELLED | EXPIRED`.
  final String? lifecycleState;

  final String? merchantTransactionId;
  final String? failureReason;

  /// Legacy `data.lifecycleStage` enum: `PENDING_INTENT | REDIRECTED_TO_GATEWAY |
  /// FAILED | CONSULTATION_ACTIVATED`. Kept for older clients.
  final String? lifecycleStage;

  final DoctorRef? doctor;
  final MeetingInfo? meeting;

  final DateTime? scheduledAtUtc;
  final String? timezone;

  /// Server-computed: only `true` when within `[joinableFrom, joinableUntil]`
  /// AND payment is PAID AND lifecycle is SCHEDULED/READY_TO_JOIN/IN_PROGRESS.
  /// Drives the Join button enabled state.
  final bool? joinAllowed;

  final DateTime? joinableFromUtc;
  final DateTime? joinableUntilUtc;

  /// Immutable for the row's lifetime — same value the user paid.
  final int? amountPaise;
  final String? currency;

  /// IST slot date `YYYY-MM-DD` and human-readable IST time (`"10:30 AM"`).
  final String? slotDate;
  final String? slotTime;

  final Map<String, dynamic>? raw;

  /// Display-ready amount line (e.g. `"₹ 500"`); `null` when no `amountPaise`.
  String? formatAmount() => _formatPaise(amountPaise, currency);

  /// Effective lifecycle for UI — prefers the new top-level enum, falls
  /// back to the legacy `consultations.status` string.
  String get effectiveLifecycle =>
      (lifecycleState ?? consultationStatus ?? '').trim();

  /// Terminal paid — backend projection only. Aligns with §12:
  /// `paymentStatus == PAID` and `lifecycleState` in
  /// `{SCHEDULED, READY_TO_JOIN, IN_PROGRESS, COMPLETED}`.
  ///
  /// Note: `COMPLETED` is included because the session auto-close cron can
  /// flip the row after payment while the user is still on the verification
  /// screen — without this, the UI would spin forever.
  bool get isTerminalPaid {
    final p = (paymentStatus ?? '').toUpperCase().trim();
    final ls = effectiveLifecycle.toUpperCase();
    if (p == 'FAILED' || ls.contains('CANCELLED') || ls.contains('CANCELED')) {
      return false;
    }
    final paymentOk = p == 'PAID' ||
        p == 'SUCCESS' ||
        p == 'COMPLETED' ||
        p == 'CAPTURED' ||
        p == 'PAYMENT_COMPLETED' ||
        p == 'SUCCEEDED';
    final bookingReady = ls == 'SCHEDULED' ||
        ls == 'COMPLETED' ||
        ls == 'READY_TO_JOIN' ||
        ls == 'IN_PROGRESS' ||
        ls.contains('CONFIRMED') ||
        ls.contains('READY_TO_JOIN') ||
        ls.contains('READY TO JOIN') ||
        ls.contains('IN_PROGRESS') ||
        ls.contains('IN PROGRESS') ||
        (lifecycleStage ?? '').toUpperCase().contains('SCHEDULED') ||
        (lifecycleStage ?? '').toUpperCase().contains('CONFIRMED') ||
        (lifecycleStage ?? '').toUpperCase().contains('READY_TO_JOIN') ||
        (lifecycleStage ?? '').toUpperCase().contains('CONSULTATION_ACTIVATED');
    if (paymentOk && bookingReady) return true;

    // Booking-shaped lifecycle without relying on payment row (legacy mirrors).
    if (ls == 'SCHEDULED' ||
        ls == 'COMPLETED' ||
        ls == 'READY_TO_JOIN' ||
        ls == 'IN_PROGRESS' ||
        ls.contains('CONFIRMED') ||
        ls.contains('READY_TO_JOIN')) {
      return true;
    }
    return false;
  }

  bool get isTerminalFailed {
    final p = (paymentStatus ?? '').toUpperCase().trim();
    return p == 'FAILED';
  }

  bool get isProcessingPayment {
    if (isTerminalPaid || isTerminalFailed) return false;
    final lifecycle = (lifecycleStage ?? '').toLowerCase().trim();
    if (lifecycle.contains('pending') ||
        lifecycle.contains('initiated') ||
        lifecycle.contains('redirected') ||
        lifecycle.contains('webhook')) {
      return true;
    }
    final p = (paymentStatus ?? '').toLowerCase().trim();
    return p.isEmpty || p.contains('pending');
  }
}

SlotHold? slotHoldFromLockResponse(
  Map<String, dynamic> json, {
  required String doctorId,
  required String slotDate,
  required String slotTime,
  required String clientRequestId,
}) {
  final data = _unwrapData(json);
  final token = _readString(data, const ['lockToken', 'lock_token', 'token']);
  if (token == null || token.isEmpty) return null;

  final exp = _readDateTime(data, const [
    'expiresAt',
    'expires_at',
    'lockExpiresAt',
  ]);
  if (exp == null) return null;

  final draft = _readString(data, const [
    'consultationId',
    'consultationDraftId',
    'consultation_id',
    'draftId',
  ]);

  return SlotHold(
    lockToken: token,
    expiresAtUtc: exp.toUtc(),
    clientRequestId: clientRequestId,
    consultationDraftId: draft,
    doctorId: doctorId,
    slotDate: slotDate,
    slotTime: slotTime,
    amountPaise: _readInt(data, const ['amountPaise', 'amount_paise']),
    currency: _readString(data, const ['currency']),
    pricing: ConsultationPricing.fromJson(data['pricing']),
  );
}

PhonePeLaunch? phonePeLaunchFromIntentResponse(
  Map<String, dynamic> json, {
  String? expectedClientRequestId,
}) {
  final data = _unwrapData(json);
  final mt = _readString(data, const [
    'merchantTransactionId',
    'merchant_transaction_id',
  ]);
  if (mt == null || mt.isEmpty) return null;

  final url = _extractPhonePeRedirectUrl(data);
  if (url == null || url.isEmpty) return null;

  final cid = _readString(data, const ['consultationId', 'consultation_id']);

  return PhonePeLaunch(
    merchantTransactionId: mt,
    paymentLaunchUrl: url,
    consultationId: cid,
    amountPaise: _readInt(data, const ['amountPaise', 'amount_paise']),
    currency: _readString(data, const ['currency']),
  );
}

ConsultationProjection consultationProjectionFromJson(
  Map<String, dynamic> json,
) {
  // Per §12 the canonical fields live at the **top level**; the `data` envelope
  // is the legacy mirror. Prefer top-level for real domain fields.
  //
  // Many envelopes use `status: "success"` at the **root** for the HTTP/API
  // outcome. That must not be read as `consultationStatus` — combined with a
  // top-first `read()` it steals before `data.consultationStatus`, so
  // `effectiveLifecycle` becomes `"success"`, `isTerminalPaid` never becomes
  // true, and payment verification spins forever despite `data.paymentStatus`
  // being `PAID`.
  final top = json;
  final legacy = (json['data'] is Map<String, dynamic>)
      ? json['data'] as Map<String, dynamic>
      : (json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : <String, dynamic>{});

  String? readFlat(List<String> keys) =>
      _readString(top, keys) ?? _readString(legacy, keys);

  String? readConsultationRowStatus() =>
      _readString(top, const ['consultationStatus', 'consultation_status']) ??
      _readString(legacy, const [
        'consultationStatus',
        'consultation_status',
        'status',
      ]) ??
      _readNestedString(legacy, const ['consultation'], const [
        'status',
        'consultationStatus',
        'consultation_status',
      ]);

  String? readPaymentStatus() {
    final flat = _readString(top, const ['paymentStatus', 'payment_status']) ??
        _readString(legacy, const ['paymentStatus', 'payment_status']);
    if (flat != null) return flat;
    for (final root in [legacy, top]) {
      final pay = root['payment'];
      if (pay is Map) {
        final m = Map<String, dynamic>.from(pay);
        final v = _readString(m, const [
          'paymentStatus',
          'payment_status',
          'status',
          'state',
        ]);
        if (v != null) return v;
      }
    }
    return null;
  }

  int? readInt(List<String> keys) =>
      _readInt(top, keys) ?? _readInt(legacy, keys);
  bool? readBool(List<String> keys) =>
      _readBool(top, keys) ?? _readBool(legacy, keys);
  DateTime? readDt(List<String> keys) =>
      _readDateTime(top, keys) ?? _readDateTime(legacy, keys);

  final lifecycleState =
      readFlat(const ['lifecycleState', 'lifecycle_state']);

  return ConsultationProjection(
    consultationId:
        readFlat(const ['consultationId', 'id', 'consultation_id']),
    bookingId: readFlat(const ['bookingId', 'booking_id']),
    paymentStatus: readPaymentStatus(),
    consultationStatus: readConsultationRowStatus(),
    lifecycleState: lifecycleState,
    merchantTransactionId: readFlat(const [
      'merchantTransactionId',
      'merchant_transaction_id',
    ]),
    failureReason: readFlat(const ['failureReason', 'failure_reason']) ??
        _readString(legacy, const [
          'failureReason',
          'failure_reason',
          'message',
        ]),
    lifecycleStage: readFlat(const ['lifecycleStage', 'lifecycle_stage']),
    doctor: DoctorRef.fromJson(top['doctor'] ?? legacy['doctor']),
    meeting: MeetingInfo.fromJson(top['meeting'] ?? legacy['meeting']),
    scheduledAtUtc: readDt(const ['scheduledAt', 'scheduled_at'])?.toUtc(),
    timezone: readFlat(const ['timezone', 'timeZone', 'tz']),
    joinAllowed: readBool(const ['joinAllowed', 'join_allowed']),
    joinableFromUtc: readDt(const ['joinableFrom', 'joinable_from'])?.toUtc(),
    joinableUntilUtc:
        readDt(const ['joinableUntil', 'joinable_until'])?.toUtc(),
    amountPaise: readInt(const ['amountPaise', 'amount_paise']),
    currency: readFlat(const ['currency']),
    slotDate: readFlat(const ['slotDate', 'slot_date']),
    slotTime: readFlat(const ['slotTime', 'slot_time']),
    raw: legacy.isNotEmpty
        ? Map<String, dynamic>.from(legacy)
        : Map<String, dynamic>.from(top),
  );
}

Map<String, dynamic> _unwrapData(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return json;
}

String? _readNestedString(
  Map<String, dynamic> map,
  List<String> parentKeys,
  List<String> childKeys,
) {
  for (final parentKey in parentKeys) {
    final nested = map[parentKey];
    if (nested is Map<String, dynamic>) {
      final v = _readString(nested, childKeys);
      if (v != null) return v;
    } else if (nested is Map) {
      final v = _readString(Map<String, dynamic>.from(nested), childKeys);
      if (v != null) return v;
    }
  }
  return null;
}

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

num? _readNum(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v == null) continue;
    if (v is num) return v;
    final n = num.tryParse(v.toString());
    if (n != null) return n;
  }
  return null;
}

bool? _readBool(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v == null) continue;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  return null;
}

DateTime? _readDateTime(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v == null) continue;
    if (v is DateTime) return v;
    final s = v.toString();
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
  }
  return null;
}

String? _extractPhonePeRedirectUrl(Map<String, dynamic> data) {
  final direct = _readString(data, const [
    'redirectUrl',
    'redirect_url',
    'paymentUrl',
  ]);
  if (direct != null) return direct;

  final inst = data['instrumentResponse'] ?? data['instrument_response'];
  if (inst is Map<String, dynamic>) {
    final ri = inst['redirectInfo'] ?? inst['redirect_info'];
    if (ri is Map<String, dynamic>) {
      final u = ri['url'] ?? ri['targetUrl'];
      if (u != null) return u.toString();
    }
  }
  return null;
}

/// Formats `(paise, currency)` into the contract-recommended display line
/// (`"₹ 500"` for INR). Returns `null` when no authoritative amount was emitted.
String? _formatPaise(int? paise, String? currency) {
  if (paise == null || paise <= 0) return null;
  final rupees = paise / 100.0;
  final symbol = (currency ?? 'INR') == 'INR' ? '₹' : currency!;
  return '$symbol ${rupees.toStringAsFixed(0)}';
}
