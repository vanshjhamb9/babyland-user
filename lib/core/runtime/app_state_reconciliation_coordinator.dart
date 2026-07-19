import 'dart:async';

// Context is always taken fresh from [rootNavigatorKey] after each await.
// ignore_for_file: use_build_context_synchronously

import 'package:babyland/app/controller/experts_consultation/booking/booking_controller.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/core/navigation/root_navigator.dart';
import 'package:babyland/core/observability/app_runtime_audit_trail.dart';
import 'package:babyland/core/subscription/subscription_payment_coordinator.dart';
import 'package:babyland/core/sync/consultation_sync_service.dart';
import 'package:babyland/core/sync/polling_consultation_sync.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Single orchestrator for app-store-grade state reconciliation.
/// REST is authoritative; sync service emits invalidation only.
enum ReconcileTrigger {
  appResume,
  reconnect,
  login,
  tokenRefresh,
  notificationTap,
  deepLink,
  paymentReturn,
  foregroundTransition,
  bootstrap,
  silentRefreshPending,
}

class AppStateReconciliationCoordinator extends ChangeNotifier {
  bool _busy = false;
  bool get isReconciling => _busy;

  DateTime? _lastBookingSyncUtc;
  DateTime? _lastEntitlementSyncUtc;
  String? _lastReconnectReason;

  DateTime? get lastBookingSyncUtc => _lastBookingSyncUtc;
  DateTime? get lastEntitlementSyncUtc => _lastEntitlementSyncUtc;
  String? get lastReconnectReason => _lastReconnectReason;

  Future<void> reconcile(
    ReconcileTrigger trigger, {
    bool emitSlotInvalidate = true,
  }) async {
    if (_busy) {
      AppRuntimeAuditTrail.log(
        AppRuntimeEvent.reconcileStart,
        reason: '${trigger.name}_skipped_already_busy',
      );
      return;
    }
    _busy = true;
    notifyListeners();

    AppRuntimeAuditTrail.log(
      AppRuntimeEvent.reconcileStart,
      reason: trigger.name,
    );

    final ctxEnt = rootNavigatorKey.currentContext;
    if (ctxEnt == null) {
      _busy = false;
      notifyListeners();
      return;
    }

    try {
      final sub = Provider.of<SubscriptionProvider>(ctxEnt, listen: false);

      await sub.refreshEntitlements(reason: trigger.name, silent: true);
      _lastEntitlementSyncUtc = DateTime.now().toUtc();
      AppRuntimeAuditTrail.log(
        AppRuntimeEvent.entitlementRefreshed,
        reason: trigger.name,
      );

      final ctxBook = rootNavigatorKey.currentContext;
      if (ctxBook == null) return;
      await Provider.of<BookingController>(ctxBook, listen: false).getBookingApi();
      _lastBookingSyncUtc = DateTime.now().toUtc();
      AppRuntimeAuditTrail.log(
        AppRuntimeEvent.bookingsSynced,
        reason: trigger.name,
      );

      final ctxPay = rootNavigatorKey.currentContext;
      if (ctxPay == null) return;
      final freshSub = Provider.of<SubscriptionProvider>(ctxPay, listen: false);
      final pay =
          Provider.of<SubscriptionPaymentCoordinator>(ctxPay, listen: false);
      await pay.syncAfterRefresh(
        canUsePremiumFeature: () => freshSub.canUsePremiumFeature,
      );
      AppRuntimeAuditTrail.log(
        AppRuntimeEvent.paymentReconciled,
        reason: trigger.name,
      );

      final ctxSync = rootNavigatorKey.currentContext;
      if (ctxSync == null) return;
      if (emitSlotInvalidate) {
        Provider.of<PollingConsultationSyncService>(ctxSync, listen: false).emit(
          ConsultationSyncReason.manual,
        );
        AppRuntimeAuditTrail.log(
          AppRuntimeEvent.slotsRefreshed,
          reason: trigger.name,
        );
      }

      AppRuntimeAuditTrail.log(
        AppRuntimeEvent.reconcileDone,
        reason: trigger.name,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void noteReconnectReason(String reason) {
    _lastReconnectReason = reason;
    notifyListeners();
  }
}
