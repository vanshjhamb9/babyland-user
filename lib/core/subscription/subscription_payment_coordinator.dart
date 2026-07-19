// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/observability/app_runtime_audit_trail.dart';
import 'package:flutter/foundation.dart';

/// Canonical subscription checkout states — UI observes this, not loose booleans.
enum SubscriptionPaymentState {
  idle,
  initiating,
  redirecting,
  pendingVerification,
  active,
  failed,
  cancelled,
  expired,
}

/// Persists only merchant id + timestamps — never ACTIVE without server GET /subscriptions/me.
class SubscriptionPaymentCoordinator extends ChangeNotifier {
  SubscriptionPaymentState _state = SubscriptionPaymentState.idle;
  String? _merchantTransactionId;
  DateTime? _pendingCreatedAtUtc;
  Timer? _pollTimer;
  int _pollTicks = 0;
  static const int _maxPollTicks = 90;

  SubscriptionPaymentState get state => _state;
  String? get merchantTransactionId => _merchantTransactionId;

  SubscriptionPaymentCoordinator() {
    unawaited(_restoreFromDisk());
  }

  Future<void> _restoreFromDisk() async {
    final raw = UserPreference.getPendingSubscriptionPayment();
    if (raw == null) return;
    final merchant = raw['merchantTransactionId']?.toString();
    if (merchant == null || merchant.isEmpty) {
      await UserPreference.clearPendingSubscriptionPayment();
      return;
    }
    _merchantTransactionId = merchant;
    final created = raw['createdAtUtc']?.toString();
    _pendingCreatedAtUtc =
        created != null ? DateTime.tryParse(created)?.toUtc() : null;
    _state = SubscriptionPaymentState.pendingVerification;
    AppAuditLog.instance.log(
      'subscription_payment_restored',
      component: 'SubscriptionPaymentCoordinator',
      merchantTransactionId: merchant,
    );
    AppRuntimeAuditTrail.log(
      AppRuntimeEvent.paymentPendingRestored,
      component: 'SubscriptionPaymentCoordinator',
      reason: merchant,
    );
    notifyListeners();
  }

  void beginCheckout() {
    _state = SubscriptionPaymentState.initiating;
    notifyListeners();
  }

  void markRedirecting({String? merchantId, String? planId}) {
    _state = SubscriptionPaymentState.redirecting;
    _merchantTransactionId = merchantId;
    notifyListeners();
  }

  Future<void> markPendingAfterPhonePeLaunched({
    required String merchantTransactionId,
    String? planId,
  }) async {
    _merchantTransactionId = merchantTransactionId;
    _pendingCreatedAtUtc = DateTime.now().toUtc();
    _state = SubscriptionPaymentState.pendingVerification;
    await UserPreference.savePendingSubscriptionPayment({
      'merchantTransactionId': merchantTransactionId,
      if (planId != null && planId.isNotEmpty) 'planId': planId,
      'createdAtUtc': _pendingCreatedAtUtc!.toIso8601String(),
      'pendingVerification': true,
    });
    AppAuditLog.instance.log(
      'subscription_payment_pending',
      component: 'SubscriptionPaymentCoordinator',
      merchantTransactionId: merchantTransactionId,
    );
    notifyListeners();
  }

  /// Poll until [canUsePremiumFeature] or max ticks (caller supplies gate logic).
  void startVerificationPolling({
    required Future<void> Function() refreshEntitlements,
    required bool Function() canUsePremiumFeature,
  }) {
    _pollTimer?.cancel();
    _pollTicks = 0;
    unawaited(() async {
      await refreshEntitlements();
      await syncAfterRefresh(canUsePremiumFeature: canUsePremiumFeature);
    }());
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_state != SubscriptionPaymentState.pendingVerification) {
        _pollTimer?.cancel();
        return;
      }
      _pollTicks++;
      if (_pollTicks > _maxPollTicks) {
        _pollTimer?.cancel();
        AppAuditLog.instance.log(
          'subscription_payment_poll_exhausted',
          component: 'SubscriptionPaymentCoordinator',
          merchantTransactionId: _merchantTransactionId,
        );
        notifyListeners();
        return;
      }
      await refreshEntitlements();
      await syncAfterRefresh(canUsePremiumFeature: canUsePremiumFeature);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> syncAfterRefresh({
    required bool Function() canUsePremiumFeature,
  }) async {
    if (_state != SubscriptionPaymentState.pendingVerification) return;
    if (canUsePremiumFeature()) {
      await _clearPendingSuccess();
      _state = SubscriptionPaymentState.active;
      stopPolling();
      notifyListeners();
    }
  }

  Future<void> _clearPendingSuccess() async {
    await UserPreference.clearPendingSubscriptionPayment();
    _merchantTransactionId = null;
    _pendingCreatedAtUtc = null;
  }

  Future<void> markFailed() async {
    _state = SubscriptionPaymentState.failed;
    await UserPreference.clearPendingSubscriptionPayment();
    stopPolling();
    notifyListeners();
  }

  Future<void> resetToIdle() async {
    _state = SubscriptionPaymentState.idle;
    await UserPreference.clearPendingSubscriptionPayment();
    stopPolling();
    notifyListeners();
  }

  /// Resume polling after app restart / login if Hive still has pending row.
  void resumePollingIfNeeded({
    required Future<void> Function() refreshEntitlements,
    required bool Function() canUsePremiumFeature,
  }) {
    if (_state != SubscriptionPaymentState.pendingVerification) return;
    startVerificationPolling(
      refreshEntitlements: refreshEntitlements,
      canUsePremiumFeature: canUsePremiumFeature,
    );
    unawaited(refreshEntitlements());
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
