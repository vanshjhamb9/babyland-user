// Booking response model.
//
// Maps both:
//   * the legacy `/consultations/upcoming` Mongo-shaped row (`_id`, `date`,
//     `time`, `consultationFee`, …), and
//   * the new canonical row from §13 (`consultationId`, `lifecycleState`,
//     `slotDate`/`slotTime`, `amountPaise`, `meeting{}`, `joinAllowed`, …).
//
// The legacy fields (`sId`, `date`, `time`, `status`, `consultationFee`) stay
// populated for back-compat with screens that already bind to them — they're
// derived from the new canonical fields when only those are present.
//
// Dedup: `source == "pg"` rows are canonical; `source == "booking"` is the
// Mongo mirror. The list parser keeps `pg` and drops any matching mirror
// to avoid showing the same consultation twice (§13).

import 'package:babyland/features/patient_consultation/consultation_models.dart';

class BookingDataModel {
  bool? success;
  List<Booking>? bookings;

  /// Server-reported total (post-filter) when emitted (§13).
  int? total;
  String? state;

  BookingDataModel({this.success, this.bookings, this.total, this.state});

  factory BookingDataModel.fromJson(Map<String, dynamic> json) {
    final nested = json['data'];
    final Map<String, dynamic>? dataMap =
        nested is Map<String, dynamic> ? nested : null;

    dynamic listRaw = json['bookings'] ??
        json['consultations'] ??
        dataMap?['bookings'] ??
        dataMap?['consultations'];

    final List<Booking> list = <Booking>[];
    if (listRaw is List) {
      for (final e in listRaw) {
        if (e is Map<String, dynamic>) {
          list.add(Booking.fromJson(e));
        } else if (e is Map) {
          list.add(Booking.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return BookingDataModel(
      success: json['success'] ?? dataMap?['success'] ?? true,
      bookings: _dedupBySource(list),
      total: _readInt(dataMap?['total']) ?? _readInt(json['total']),
      state: (dataMap?['state'] ?? json['state'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'bookings': bookings?.map((x) => x.toJson()).toList(),
    if (total != null) 'total': total,
    if (state != null) 'state': state,
  };

  /// Keeps `pg` rows when both `pg` and `booking` sources exist for the same
  /// consultation (matched by `consultationId` → `bookingId` → `sId`).
  /// Backend already de-dups per §13; this is a defense-in-depth layer.
  static List<Booking> _dedupBySource(List<Booking> rows) {
    if (rows.length < 2) return rows;
    final byKey = <String, Booking>{};
    final order = <String>[];

    for (final b in rows) {
      final key = b.consultationId ??
          b.bookingId ??
          b.sId ??
          '${rows.indexOf(b)}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = b;
        order.add(key);
        continue;
      }
      // Prefer `pg` over `booking` when there's a clash.
      final isPg = (b.source ?? '').toLowerCase() == 'pg';
      final existingIsPg = (existing.source ?? '').toLowerCase() == 'pg';
      if (isPg && !existingIsPg) {
        byKey[key] = b;
      }
    }
    return order.map((k) => byKey[k]!).toList();
  }
}

class Doctor {
  String? id;
  String? name;
  String? profileImageUrl;
  String? specialization;

  Doctor({this.id, this.name, this.profileImageUrl, this.specialization});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString(),
      profileImageUrl: json['profileImage']?.toString() ??
          json['profileImageUrl']?.toString() ??
          json['image']?.toString() ??
          json['photo']?.toString(),
      specialization: json['specialization']?.toString() ??
          json['speciality']?.toString() ??
          json['specialty']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    if (specialization != null) 'specialization': specialization,
  };
}


class Booking {
  // ─── Legacy fields (still read by existing UI) ─────────────────────────
  String? sId;
  Doctor? doctorId;
  String? patientId;
  DateTime? date;
  String? time;
  String? status;
  String? paymentStatus;
  int? consultationFee;
  String? currency;
  String? paymentMethod;
  List<dynamic>? records;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? iV;
  String? timezoneLabel;

  // ─── Canonical fields (§13) ────────────────────────────────────────────
  /// PG consultation id (UUID). For new bookings this is the authoritative key.
  String? consultationId;

  /// Mongo Booking mirror `_id` (derived from `consultationId`).
  String? bookingId;

  /// `"pg"` for canonical rows, `"booking"` for legacy Mongo-mirror rows.
  String? source;

  /// Canonical lifecycle enum: SLOT_HELD | AWAITING_PAYMENT | SCHEDULED |
  /// READY_TO_JOIN | IN_PROGRESS | COMPLETED | CANCELLED | EXPIRED.
  String? lifecycleState;

  /// IST slot date `YYYY-MM-DD` (§13). When present, drives the date row.
  String? slotDate;

  /// IST slot time label (`"10:30 AM"`).
  String? slotTime;

  /// UTC ISO of the slot start.
  DateTime? scheduledAtUtc;

  /// Final amount the user paid (integer paise) — same value across the funnel.
  int? amountPaise;

  /// Server-computed: `true` only when within `[joinableFrom, joinableUntil]`
  /// AND `paymentStatus==PAID` AND lifecycle ∈ SCHEDULED/READY_TO_JOIN/IN_PROGRESS.
  bool? joinAllowed;

  DateTime? joinableFromUtc;
  DateTime? joinableUntilUtc;

  /// PhonePe merchant txn id for this consultation.
  String? merchantTransactionId;

  /// Agora meeting info. `meeting.channelName` is unique-per-consultation
  /// (format `consultation:<uuid>`) and is the **only** valid channel string
  /// to pass to `/agoras/rtc`. Legacy `"videoCall"` is a hard FAIL (§14).
  MeetingInfo? meeting;

  Booking({
    this.sId,
    this.doctorId,
    this.patientId,
    this.date,
    this.time,
    this.status,
    this.paymentStatus,
    this.consultationFee,
    this.currency,
    this.paymentMethod,
    this.records,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.timezoneLabel,
    this.consultationId,
    this.bookingId,
    this.source,
    this.lifecycleState,
    this.slotDate,
    this.slotTime,
    this.scheduledAtUtc,
    this.amountPaise,
    this.joinAllowed,
    this.joinableFromUtc,
    this.joinableUntilUtc,
    this.merchantTransactionId,
    this.meeting,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    Doctor? doc;
    final d = json['doctorId'];
    if (d is Map<String, dynamic>) {
      doc = Doctor.fromJson(d);
    } else if (d is Map) {
      doc = Doctor.fromJson(Map<String, dynamic>.from(d));
    } else {
      // §13 canonical row carries `doctor:{id,name,specialization,image}`.
      final nestedDoctor = json['doctor'];
      if (nestedDoctor is Map<String, dynamic>) {
        doc = Doctor.fromJson(nestedDoctor);
      } else if (nestedDoctor is Map) {
        doc = Doctor.fromJson(Map<String, dynamic>.from(nestedDoctor));
      }
    }

    DateTime? parsedDate;
    final dateVal = json['date'] ?? json['appointmentDate'] ?? json['slotDate'];
    if (dateVal != null) {
      try {
        parsedDate = DateTime.parse(dateVal.toString());
      } catch (_) {
        parsedDate = null;
      }
    }
    final scheduledRaw = json['scheduledAt'] ?? json['scheduled_at'];
    final scheduled = scheduledRaw != null
        ? DateTime.tryParse(scheduledRaw.toString())?.toUtc()
        : null;
    parsedDate ??= scheduled;

    final timeStr = (json['time'] ?? json['slotTime'])?.toString();

    // Legacy `status` came from `consultations.status`; the new contract has
    // `lifecycleState` at the top level. Prefer the canonical one for new rows.
    final lifecycleState = json['lifecycleState']?.toString();
    final legacyStatus = json['status']?.toString();

    final amountPaiseRaw = json['amountPaise'] ?? json['amount_paise'];
    final amountPaise = _readInt(amountPaiseRaw);

    // Keep `consultationFee` (rupees) populated for legacy code paths, but
    // derive it from `amountPaise` when the new field is present.
    int? consultationFee = _readInt(json['consultationFee']);
    if (consultationFee == null && amountPaise != null && amountPaise > 0) {
      consultationFee = (amountPaise / 100).round();
    }

    final joinableFromRaw = json['joinableFrom'] ?? json['joinable_from'];
    final joinableUntilRaw = json['joinableUntil'] ?? json['joinable_until'];

    return Booking(
      sId: json['_id']?.toString() ??
          json['id']?.toString() ??
          json['bookingId']?.toString() ??
          json['consultationId']?.toString(),
      doctorId: doc,
      patientId: json['patientId']?.toString(),
      date: parsedDate,
      time: timeStr,
      // Prefer canonical lifecycle; fall back to legacy status string.
      status: lifecycleState ?? legacyStatus,
      paymentStatus: json['paymentStatus']?.toString(),
      consultationFee: consultationFee,
      currency: json['currency']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      records:
          json['records'] != null ? List<dynamic>.from(json['records']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      iV: json['__v'] is int
          ? json['__v'] as int
          : (json['__v'] != null
              ? int.tryParse(json['__v'].toString())
              : null),
      timezoneLabel: json['timezone']?.toString() ??
          json['timeZone']?.toString() ??
          json['tz']?.toString(),
      consultationId: json['consultationId']?.toString(),
      bookingId: json['bookingId']?.toString(),
      source: json['source']?.toString(),
      lifecycleState: lifecycleState,
      slotDate: json['slotDate']?.toString(),
      slotTime: timeStr,
      scheduledAtUtc: scheduled,
      amountPaise: amountPaise,
      joinAllowed: _readBool(json['joinAllowed']),
      joinableFromUtc: joinableFromRaw != null
          ? DateTime.tryParse(joinableFromRaw.toString())?.toUtc()
          : null,
      joinableUntilUtc: joinableUntilRaw != null
          ? DateTime.tryParse(joinableUntilRaw.toString())?.toUtc()
          : null,
      merchantTransactionId: json['merchantTransactionId']?.toString(),
      meeting: MeetingInfo.fromJson(json['meeting']),
    );
  }

  /// Effective key for de-dup / lookups: `consultationId` first, then
  /// `bookingId`, then the legacy `sId`. The Agora channel name is keyed
  /// off `consultationId`.
  String? get effectiveId => consultationId ?? bookingId ?? sId;

  /// Display-ready amount line (e.g. `"₹ 500"`). Returns `null` when the
  /// server didn't quote an authoritative amount.
  String? formatAmount() {
    final paise = amountPaise;
    if (paise == null || paise <= 0) return null;
    final rupees = paise / 100.0;
    final symbol = (currency ?? 'INR') == 'INR' ? '₹' : (currency!);
    return '$symbol ${rupees.toStringAsFixed(0)}';
  }

  Map<String, dynamic> toJson() => {
    '_id': sId,
    'doctorId': doctorId?.toJson(),
    'patientId': patientId,
    'date': date?.toIso8601String(),
    'time': time,
    'status': status,
    'paymentStatus': paymentStatus,
    'consultationFee': consultationFee,
    'currency': currency,
    'paymentMethod': paymentMethod,
    'records': records,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    '__v': iV,
    if (consultationId != null) 'consultationId': consultationId,
    if (bookingId != null) 'bookingId': bookingId,
    if (source != null) 'source': source,
    if (lifecycleState != null) 'lifecycleState': lifecycleState,
    if (slotDate != null) 'slotDate': slotDate,
    if (slotTime != null) 'slotTime': slotTime,
    if (scheduledAtUtc != null) 'scheduledAt': scheduledAtUtc!.toIso8601String(),
    if (amountPaise != null) 'amountPaise': amountPaise,
    if (joinAllowed != null) 'joinAllowed': joinAllowed,
    if (joinableFromUtc != null)
      'joinableFrom': joinableFromUtc!.toIso8601String(),
    if (joinableUntilUtc != null)
      'joinableUntil': joinableUntilUtc!.toIso8601String(),
    if (merchantTransactionId != null)
      'merchantTransactionId': merchantTransactionId,
    if (meeting != null)
      'meeting': <String, dynamic>{
        'channelName': meeting!.channelName,
        if (meeting!.sessionId != null) 'sessionId': meeting!.sessionId,
        if (meeting!.agoraEnabled != null)
          'agoraEnabled': meeting!.agoraEnabled,
      },
  };
}

int? _readInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final n = num.tryParse(v.toString());
  return n?.toInt();
}

bool? _readBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase().trim();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return null;
}
