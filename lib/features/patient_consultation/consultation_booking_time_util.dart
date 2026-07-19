// ignore_for_file: public_member_api_docs

import 'package:babyland/app/controller/experts_consultation/model/booking_data_model.dart';
import 'package:intl/intl.dart';

/// Best-effort parse of wall-clock start for countdowns (local device calendar date + time label).
///
/// Prefers the canonical `scheduledAt` (UTC ISO from §13) — that's the
/// server's source-of-truth slot start, already aligned to the doctor's IST
/// grid. Falls back to the legacy `date + time` split when only those are
/// available.
DateTime? parseConsultationStartLocal(Booking b) {
  final scheduled = b.scheduledAtUtc;
  if (scheduled != null) return scheduled.toLocal();

  if (b.date == null) return null;
  final day = DateTime(b.date!.year, b.date!.month, b.date!.day);
  final t = b.time?.trim();
  if (t == null || t.isEmpty) return day;

  final patterns = ['hh:mm a', 'h:mm a', 'HH:mm', 'H:mm', 'jm'];
  for (final pattern in patterns) {
    try {
      final parsed = DateFormat(pattern, 'en_IN').parseLoose(t);
      return DateTime(
        day.year,
        day.month,
        day.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {}
  }
  return day;
}
