import 'package:babyland/core/navigation/root_navigator.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:provider/provider.dart';

/// FCM must only **hint** refresh — never unlock premium from payload text.
class Phase8NotificationBridge {
  Phase8NotificationBridge._();

  static Future<void> reconcile(ReconcileTrigger trigger) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    await ctx.read<AppStateReconciliationCoordinator>().reconcile(trigger);
  }
}
