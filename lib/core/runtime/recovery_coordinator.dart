import 'dart:async';

import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/runtime/offline_recovery_engine.dart';
import 'package:babyland/core/services/connectivity_service.dart';

/// Orchestrates reconnect + refresh (GET-only). Payment POSTs are never queued here.
class RecoveryCoordinator {
  RecoveryCoordinator();

  StreamSubscription<bool>? _netSub;
  bool _attached = false;

  void attachIfNeeded({
    required ConnectivityService connectivity,
    required Future<void> Function() onNetworkOnline,
  }) {
    if (_attached) return;
    _attached = true;
    _netSub = connectivity.onConnectivityChanged.listen((online) async {
      if (!online) return;
      AppAuditLog.instance.log(
        'network_online',
        component: 'RecoveryCoordinator',
        reason: 'reconnect',
      );
      OfflineRecoveryEngine.logRecoveryStarted();
      await onNetworkOnline();
    });
  }

  Future<void> onAuthenticatedBootstrap({
    required Future<void> Function() reconcileBootstrap,
  }) async {
    AppAuditLog.instance.log(
      'recovery_bootstrap',
      component: 'RecoveryCoordinator',
    );
    await reconcileBootstrap();
  }

  void dispose() {
    _netSub?.cancel();
    _netSub = null;
    _attached = false;
  }
}
