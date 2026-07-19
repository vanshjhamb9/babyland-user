import 'package:babyland/core/observability/app_runtime_audit_trail.dart';

/// Policy holder for offline / long-reconnect behavior (GET retries only; no payment POST replay).
class OfflineRecoveryEngine {
  OfflineRecoveryEngine._();

  static void logRecoveryStarted({String? detail}) {
    AppRuntimeAuditTrail.log(
      AppRuntimeEvent.offlineRecovery,
      reason: detail ?? 'connectivity_restored',
    );
  }
}
