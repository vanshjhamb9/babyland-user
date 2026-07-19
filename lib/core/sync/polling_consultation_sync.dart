import 'dart:async';

import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/sync/consultation_sync_service.dart';

/// Timer-driven invalidation; handlers refetch from REST.
class PollingConsultationSyncService implements ConsultationSyncService {
  final _controller = StreamController<ConsultationSyncReason>.broadcast(
    sync: true,
  );

  Timer? _slotPoll;
  Timer? _bookingPoll;

  /// While true, timers still fire but **do not** enqueue invalidations (saves battery in background).
  bool _backgroundPaused = false;

  void setBackgroundPaused(bool paused) {
    _backgroundPaused = paused;
  }

  bool get isBackgroundPaused => _backgroundPaused;

  @override
  Stream<ConsultationSyncReason> get invalidations => _controller.stream;

  @override
  void startSlotPolling({Duration interval = const Duration(seconds: 15)}) {
    _slotPoll?.cancel();
    _slotPoll = Timer.periodic(interval, (_) {
      if (_backgroundPaused) return;
      AppAuditLog.instance.log(
        'sync_invalidate',
        component: 'PollingConsultationSync',
        reason: 'slot_poll_tick',
      );
      if (!_controller.isClosed) {
        _controller.add(ConsultationSyncReason.pollTick);
      }
    });
  }

  @override
  void stopSlotPolling() {
    _slotPoll?.cancel();
    _slotPoll = null;
  }

  @override
  void startBookingPolling({Duration interval = const Duration(seconds: 20)}) {
    _bookingPoll?.cancel();
    _bookingPoll = Timer.periodic(interval, (_) {
      if (_backgroundPaused) return;
      AppAuditLog.instance.log(
        'sync_invalidate',
        component: 'PollingConsultationSync',
        reason: 'booking_poll_tick',
      );
      if (!_controller.isClosed) {
        _controller.add(ConsultationSyncReason.pollTick);
      }
    });
  }

  @override
  void stopBookingPolling() {
    _bookingPoll?.cancel();
    _bookingPoll = null;
  }

  void emit(ConsultationSyncReason reason) {
    if (!_controller.isClosed) _controller.add(reason);
  }

  @override
  void dispose() {
    stopSlotPolling();
    stopBookingPolling();
    unawaited(_controller.close());
  }
}
