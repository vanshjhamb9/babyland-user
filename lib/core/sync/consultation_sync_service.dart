import 'dart:async';

/// Invalidation reasons — REST refetch is always authoritative.
enum ConsultationSyncReason {
  pollTick,
  socketHint,
  reconnect,
  manual,
  paymentReturned,
  fcmHint,
}

/// Abstraction: polling today, WebSocket acceleration later.
/// UI subscribes here instead of owning raw [Timer]s.
abstract class ConsultationSyncService {
  Stream<ConsultationSyncReason> get invalidations;

  /// Start low-frequency polling while a sync consumer is active (e.g. slot screen).
  void startSlotPolling({Duration interval = const Duration(seconds: 15)});

  void stopSlotPolling();

  /// Booking list refresh cadence while My Bookings is visible.
  void startBookingPolling({Duration interval = const Duration(seconds: 20)});

  void stopBookingPolling();

  void dispose();
}
