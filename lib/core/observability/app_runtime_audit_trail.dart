// ignore_for_file: public_member_api_docs

import 'package:babyland/core/observability/app_audit_log.dart';

/// Structured production-audit event tags (searchable in [AppAuditLog] export).
abstract final class AppRuntimeEvent {
  static const String appResume = '[APP_RESUME]';
  static const String paymentPendingRestored = '[PAYMENT_PENDING_RESTORED]';
  static const String paymentReconciled = '[PAYMENT_RECONCILED]';
  static const String entitlementRefreshed = '[ENTITLEMENT_REFRESHED]';
  static const String bookingsSynced = '[BOOKINGS_SYNCED]';
  static const String slotsRefreshed = '[SLOTS_REFRESHED]';
  static const String sessionJoinAttempt = '[SESSION_JOIN_ATTEMPT]';
  static const String notificationDeduped = '[NOTIFICATION_DEDUPED]';
  static const String offlineRecovery = '[OFFLINE_RECOVERY]';
  static const String reconcileStart = '[RECONCILE_START]';
  static const String reconcileDone = '[RECONCILE_DONE]';
}

/// Thin façade over [AppAuditLog] with Phase 9 event constants.
class AppRuntimeAuditTrail {
  AppRuntimeAuditTrail._();

  static void log(
    String event, {
    String? component,
    String? reason,
    String? traceId,
  }) {
    AppAuditLog.instance.log(
      event,
      component: component ?? 'AppRuntimeAuditTrail',
      reason: reason,
      traceId: traceId,
    );
  }
}
