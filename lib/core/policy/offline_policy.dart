/// Product rules for offline / stale entitlement (Phase 8).
///
/// - Premium content: locked when entitlement snapshot is stale or device offline.
/// - Active Agora session: reconnect allowed; refresh entitlement when online.
/// - Cached bookings: visible read-only; prompt to connect if cache is stale.
/// - New bookings / slot lock / PhonePe: blocked offline (caller must check connectivity).
abstract final class OfflinePolicy {
  static String blockedPaymentMessage() =>
      'Connect to the internet to complete or retry payment.';

  static String blockedBookingMessage() =>
      'Connect to the internet to book a consultation.';

  static String staleBookingsMessage() =>
      'Showing saved details. Connect for the latest status.';
}
