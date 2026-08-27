import 'dart:async';

import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/observability/app_runtime_audit_trail.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:babyland/core/runtime/recovery_coordinator.dart';
import 'package:babyland/core/runtime/token_refresh_reconcile_hook.dart';
import 'package:babyland/core/sync/polling_consultation_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Foreground TTL ticks, long-idle refresh, lifecycle audit logs.
class AppLifecycleHost extends StatefulWidget {
  const AppLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleHost> createState() => _AppLifecycleHostState();
}

class _AppLifecycleHostState extends State<AppLifecycleHost>
    with WidgetsBindingObserver {
  Timer? _ttlTimer;
  final RecoveryCoordinator _recovery = RecoveryCoordinator();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wireTokenRefreshHook();
      _attachRecovery();
      _bootstrapAuthRefresh();
      _ttlTimer = Timer.periodic(const Duration(seconds: 45), (_) {
        if (!mounted) return;
        final sub = context.read<SubscriptionProvider>();
        unawaited(sub.tickForegroundTtlIfNeeded());
      });
    });
  }

  void _wireTokenRefreshHook() {
    TokenRefreshReconcileHook.instance.onAccessTokenRefreshed = () {
      if (!mounted) return;
      unawaited(
        context.read<AppStateReconciliationCoordinator>().reconcile(
              ReconcileTrigger.tokenRefresh,
            ),
      );
    };
  }

  void _attachRecovery() {
    _recovery.attachIfNeeded(
      connectivity: sl.connectivityService,
      onNetworkOnline: () async {
        if (!mounted) return;
        final coord = context.read<AppStateReconciliationCoordinator>();
        coord.noteReconnectReason('connectivity_online');
        await coord.reconcile(ReconcileTrigger.reconnect);
      },
    );
  }

  Future<void> _bootstrapAuthRefresh() async {
    final token = await sl.authService.getToken();
    if (token == null || token.isEmpty) return;
    await _recovery.onAuthenticatedBootstrap(
      reconcileBootstrap: () async {
        if (!mounted) return;
        await context.read<AppStateReconciliationCoordinator>().reconcile(
              ReconcileTrigger.bootstrap,
            );
      },
    );
  }

  @override
  void dispose() {
    TokenRefreshReconcileHook.instance.clear();
    WidgetsBinding.instance.removeObserver(this);
    _ttlTimer?.cancel();
    _recovery.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppAuditLog.instance.log(
      state == AppLifecycleState.resumed
          ? 'app_foreground'
          : state == AppLifecycleState.paused
              ? 'app_background'
              : 'app_lifecycle',
      component: 'AppLifecycleHost',
      reason: state.name,
    );

    if (kDebugMode) {
      unawaited(
        UserPreference.appendLifecycleTransition(
          '${state.name} @ ${DateTime.now().toUtc().toIso8601String()}',
        ),
      );
    }

    if (!mounted) return;

    final sync = context.read<PollingConsultationSyncService>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      sync.setBackgroundPaused(true);
    }

    if (state == AppLifecycleState.resumed) {
      sync.setBackgroundPaused(false);
      AppRuntimeAuditTrail.log(
        AppRuntimeEvent.appResume,
        reason: state.name,
      );

      // Custom Tabs / Safari reCAPTCHA resumes the app — do not storm APIs mid-OTP.
      if (sl.firebasePhoneAuthService.isBusy) {
        AppRuntimeAuditTrail.log(
          AppRuntimeEvent.reconcileDone,
          reason: 'appResume_skipped_phone_auth_busy',
        );
        return;
      }

      final sub = context.read<SubscriptionProvider>();
      sub.onForeground();
      unawaited(sub.refreshAfterLongInactivityIfNeeded());

      final coord = context.read<AppStateReconciliationCoordinator>();

      if (UserPreference.getPendingSilentRefresh()) {
        unawaited(UserPreference.setPendingSilentRefresh(false));
        unawaited(
          coord.reconcile(ReconcileTrigger.silentRefreshPending),
        );
      } else {
        unawaited(coord.reconcile(ReconcileTrigger.appResume));
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
