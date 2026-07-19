// ignore_for_file: public_member_api_docs

import 'dart:convert';

import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/core/constants/app_constants.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/environment/app_environment.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:babyland/core/subscription/subscription_payment_coordinator.dart';
import 'package:babyland/core/sync/polling_consultation_sync.dart';
import 'package:babyland/core/time/server_time_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Hidden diagnostics for Phase 8/9 production readiness (not user-facing marketing).
class Phase8DebugScreen extends StatelessWidget {
  const Phase8DebugScreen({super.key});

  Future<void> _copy(BuildContext context, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Unavailable')),
      );
    }

    final sub = context.watch<SubscriptionProvider>();
    final pay = context.watch<SubscriptionPaymentCoordinator>();
    final coord = context.watch<AppStateReconciliationCoordinator>();
    final sync =
        Provider.of<PollingConsultationSyncService>(context, listen: false);

    final snapshot = <String, dynamic>{
      'appVersion': AppConstants.appVersion,
      'apiBaseUrl': AppEnvironment.baseUrl,
      'apiEnvironment': AppEnvironment.current.name,
      'serverOffsetMs': ServerTimeService.instance.offset.inMilliseconds,
      'lastHttpDateUtc':
          ServerTimeService.instance.lastUpdateUtc?.toIso8601String(),
      'entitlementLastVerifiedUtc':
          sub.lastEntitlementVerifiedAtUtc?.toIso8601String(),
      'canUsePremiumFeature': sub.canUsePremiumFeature,
      'isEntitlementStale': sub.isEntitlementSnapshotStale,
      'subscriptionPaymentState': pay.state.name,
      'pendingConsultationPayment': UserPreference.getPendingConsultationPayment(),
      'pendingSubscriptionPayment': UserPreference.getPendingSubscriptionPayment(),
      'pendingSilentFcmRefresh': UserPreference.getPendingSilentRefresh(),
      'fcmToken': sl.notificationService.fcmToken,
      'reconcileBusy': coord.isReconciling,
      'lastBookingSyncUtc': coord.lastBookingSyncUtc?.toIso8601String(),
      'lastEntitlementSyncUtc': coord.lastEntitlementSyncUtc?.toIso8601String(),
      'lastReconnectReason': coord.lastReconnectReason,
      'slotBookingPollingPaused': sync.isBackgroundPaused,
      'connectivityOnline': sl.connectivityService.isOnline,
      'syncTransport': 'polling_invalidation_bus',
      'deepLinkHistory': UserPreference.getDeepLinkHistory(),
      'lifecycleTransitions': UserPreference.getLifecycleTransitions(),
      'notificationDedupeKeysSample':
          UserPreference.getNotificationDedupeKeys().length,
    };

    final snapshotJson =
        const JsonEncoder.withIndent('  ').convert(snapshot);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Runtime diagnostics (Phase 8–9)'),
        actions: [
          IconButton(
            tooltip: 'Copy snapshot JSON',
            icon: const Icon(Icons.copy),
            onPressed: () => _copy(context, snapshotJson, 'Snapshot'),
          ),
          IconButton(
            tooltip: 'Copy audit log',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => _copy(
              context,
              AppAuditLog.instance.exportAsText(),
              'Audit log',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            snapshotJson,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ),
    );
  }
}
