// Typed response for `GET /api/v1/doctors/{doctorId}/live-slots` (§8).
//
// This is the richer slot grid that the new backend contract emits: each slot
// carries an explicit `status` enum (AVAILABLE | HELD | BOOKED | PAST) plus
// an optional `until` countdown for HELD slots and a UTC `slotStart` for
// sorting / "starts in" labels.
//
// Per the contract the per-slot price is **deliberately not** included — the
// authoritative consultation amount is computed at slot-lock time and quoted
// by `/slot-lock` (§7).

/// Top-level live-slots response envelope.
class LiveSlotsResponse {
  const LiveSlotsResponse({
    required this.success,
    required this.doctorId,
    this.doctorName,
    required this.date,
    required this.timezone,
    required this.intervalMinutes,
    required this.slots,
    this.generatedAtUtc,
  });

  final bool success;
  final String doctorId;
  final String? doctorName;

  /// IST date in `YYYY-MM-DD`.
  final String date;

  /// Always `"Asia/Kolkata"` for the slot grid (§8).
  final String timezone;

  /// Grid granularity in minutes (currently `30`).
  final int intervalMinutes;

  final List<LiveSlot> slots;

  /// When the projection was assembled — used for staleness checks.
  final DateTime? generatedAtUtc;

  factory LiveSlotsResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    final data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : <String, dynamic>{};

    final rawSlots = data['slots'];
    final slots = <LiveSlot>[];
    if (rawSlots is List) {
      for (final s in rawSlots) {
        if (s is Map) {
          slots.add(LiveSlot.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    return LiveSlotsResponse(
      success: json['success'] == true,
      doctorId: data['doctorId']?.toString() ?? '',
      doctorName: data['doctorName']?.toString(),
      date: data['date']?.toString() ?? '',
      timezone: data['timezone']?.toString() ?? 'Asia/Kolkata',
      intervalMinutes: _readInt(data['intervalMinutes']) ?? 30,
      slots: slots,
      generatedAtUtc: _readDateTime(data['generatedAt']),
    );
  }

  /// Slots that are bookable right now (status == AVAILABLE).
  List<LiveSlot> get availableSlots =>
      slots.where((s) => s.isAvailable).toList(growable: false);
}

/// Status of a single live slot. Backend always emits exactly one of these.
enum LiveSlotStatus { available, held, booked, past, unknown }

LiveSlotStatus _statusFromString(String? s) {
  switch ((s ?? '').toUpperCase().trim()) {
    case 'AVAILABLE':
      return LiveSlotStatus.available;
    case 'HELD':
      return LiveSlotStatus.held;
    case 'BOOKED':
      return LiveSlotStatus.booked;
    case 'PAST':
      return LiveSlotStatus.past;
  }
  return LiveSlotStatus.unknown;
}

/// Single slot in the live grid (§8).
class LiveSlot {
  const LiveSlot({
    required this.time,
    required this.status,
    this.untilUtc,
    this.slotStartUtc,
  });

  /// IST display label (e.g. `"10:30 AM"`). Pass verbatim as `slotTime` to
  /// `/slot-lock` (the contract specifies byte-for-byte match).
  final String time;

  final LiveSlotStatus status;

  /// For `HELD` slots: when the other patient's lock expires (UTC).
  /// `null` for any other status.
  final DateTime? untilUtc;

  /// UTC ISO of the slot's IST start. Use for sort / "starts in X" labels.
  final DateTime? slotStartUtc;

  bool get isAvailable => status == LiveSlotStatus.available;
  bool get isHeld => status == LiveSlotStatus.held;
  bool get isBooked => status == LiveSlotStatus.booked;
  bool get isPast => status == LiveSlotStatus.past;
  bool get isBookable => isAvailable;

  factory LiveSlot.fromJson(Map<String, dynamic> json) {
    return LiveSlot(
      time: json['time']?.toString() ?? '',
      status: _statusFromString(json['status']?.toString()),
      untilUtc: _readDateTime(json['until']),
      slotStartUtc: _readDateTime(json['slotStart']),
    );
  }
}

int? _readInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final n = num.tryParse(v.toString());
  return n?.toInt();
}

DateTime? _readDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toUtc();
}
