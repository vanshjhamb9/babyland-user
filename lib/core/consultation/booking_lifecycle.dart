// ignore_for_file: public_member_api_docs

import 'package:babyland/app/controller/experts_consultation/model/booking_data_model.dart';

/// Canonical consultation lifecycle for UI (maps loose backend strings).
enum BookingLifecyclePhase {
  slotHeld,
  awaitingPayment,
  scheduled,
  readyToJoin,
  inProgress,
  completed,
  cancelled,
  expired,
  unknown,
}

BookingLifecyclePhase bookingLifecycleFromBooking(Booking b) {
  // Prefer the canonical top-level `lifecycleState` (§13) when present;
  // fall back to the legacy `status` + `paymentStatus` string heuristic.
  final canonical = b.lifecycleState?.trim().toUpperCase();
  if (canonical != null && canonical.isNotEmpty) {
    switch (canonical) {
      case 'SLOT_HELD':
        return BookingLifecyclePhase.slotHeld;
      case 'AWAITING_PAYMENT':
        return BookingLifecyclePhase.awaitingPayment;
      case 'SCHEDULED':
        // Backend may flip to READY_TO_JOIN at T-10m via cron; the
        // `joinAllowed` flag is the server-authoritative gate.
        return b.joinAllowed == true
            ? BookingLifecyclePhase.readyToJoin
            : BookingLifecyclePhase.scheduled;
      case 'READY_TO_JOIN':
        return BookingLifecyclePhase.readyToJoin;
      case 'IN_PROGRESS':
        return BookingLifecyclePhase.inProgress;
      case 'COMPLETED':
        return BookingLifecyclePhase.completed;
      case 'CANCELLED':
        return BookingLifecyclePhase.cancelled;
      case 'EXPIRED':
        return BookingLifecyclePhase.expired;
    }
  }

  final s = '${b.status ?? ''} ${b.paymentStatus ?? ''}'.toUpperCase();

  if (s.contains('CANCELLED') || s.contains('CANCELED')) {
    return BookingLifecyclePhase.cancelled;
  }
  if (s.contains('EXPIRED')) return BookingLifecyclePhase.expired;
  if (s.contains('COMPLETED') || s.contains('DONE')) {
    return BookingLifecyclePhase.completed;
  }
  if (s.contains('IN_PROGRESS') ||
      s.contains('IN PROGRESS') ||
      s.contains('ONGOING')) {
    return BookingLifecyclePhase.inProgress;
  }
  if (s.contains('READY_TO_JOIN') ||
      s.contains('READY TO JOIN') ||
      (s.contains('READY') && s.contains('JOIN'))) {
    return BookingLifecyclePhase.readyToJoin;
  }
  if (s.contains('SCHEDULED') || s.contains('CONFIRMED')) {
    return b.joinAllowed == true
        ? BookingLifecyclePhase.readyToJoin
        : BookingLifecyclePhase.scheduled;
  }
  if (s.contains('AWAITING_PAYMENT') ||
      s.contains('PENDING_PAYMENT') ||
      (b.paymentStatus?.toUpperCase().contains('PENDING') ?? false)) {
    return BookingLifecyclePhase.awaitingPayment;
  }
  if (s.contains('HELD') || s.contains('SLOT_HELD')) {
    return BookingLifecyclePhase.slotHeld;
  }
  return BookingLifecyclePhase.unknown;
}

String bookingLifecycleLabel(BookingLifecyclePhase p) {
  switch (p) {
    case BookingLifecyclePhase.slotHeld:
      return 'Slot held';
    case BookingLifecyclePhase.awaitingPayment:
      return 'Awaiting payment';
    case BookingLifecyclePhase.scheduled:
      return 'Scheduled';
    case BookingLifecyclePhase.readyToJoin:
      return 'Ready to join';
    case BookingLifecyclePhase.inProgress:
      return 'In progress';
    case BookingLifecyclePhase.completed:
      return 'Completed';
    case BookingLifecyclePhase.cancelled:
      return 'Cancelled';
    case BookingLifecyclePhase.expired:
      return 'Expired';
    case BookingLifecyclePhase.unknown:
      return 'Status updating';
  }
}
