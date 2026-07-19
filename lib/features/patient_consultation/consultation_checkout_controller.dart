// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/core/time/server_time_service.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_repository.dart';
import 'package:babyland/features/patient_consultation/consultation_models.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Orchestrates slot lock → PhonePe launch → server projection polling.
/// Does **not** treat deeplink return or app resume as payment success.
class ConsultationCheckoutController extends ChangeNotifier {
  ConsultationCheckoutController({
    required ConsultationCheckoutRepository repository,
  }) : _repo = repository {
    unawaited(restorePendingConsultation());
  }

  final ConsultationCheckoutRepository _repo;
  final _uuid = const Uuid();

  SlotHold? _hold;
  PhonePeLaunch? _lastLaunch;
  PendingConsultationPayment? _pendingPayment;

  /// True after intent API succeeds and before projection confirms Paid.
  bool _intentLaunchedAwaitingWebhook = false;

  Timer? _expiryTicker;
  Duration _remaining = Duration.zero;

  bool _busy = false;

  SlotHold? get activeHold => _hold;

  PhonePeLaunch? get lastLaunch => _lastLaunch;

  PendingConsultationPayment? get pendingPayment => _pendingPayment;

  Duration get remainingLockTime => _remaining;

  bool get hasActiveLock =>
      _hold != null &&
      !_hold!.isExpiredAt(ServerTimeService.instance.nowServerUtc()) &&
      !_intentLaunchedAwaitingWebhook &&
      _pendingPayment == null;

  bool get isBusy => _busy;

  bool get isAwaitingServerPaymentTruth => _intentLaunchedAwaitingWebhook;

  String? _lastError;
  String? get lastError => _lastError;

  static const String phonePeReturnScheme =
      'babyland://consultation-payment-return';

  void clearForNewFlow() {
    _cancelExpiryTicker();
    _hold = null;
    _lastLaunch = null;
    _intentLaunchedAwaitingWebhook = false;
    _lastError = null;
    _remaining = Duration.zero;
    _pendingPayment = null;
    unawaited(UserPreference.clearPendingConsultationPayment());
    notifyListeners();
  }

  Future<PendingConsultationPayment?> restorePendingConsultation() async {
    final pending = pendingConsultationPaymentFromJson(
      UserPreference.getPendingConsultationPayment(),
    );
    _pendingPayment = pending;
    if (pending != null) {
      _intentLaunchedAwaitingWebhook = true;
      pt(
        '[PROJECTION_POLL] Restored pending consultation payment '
        'merchantTransactionId=${pending.merchantTransactionId} '
        'consultationId=${pending.consultationId ?? "(none)"}',
      );
      notifyListeners();
    }
    return pending;
  }

  Future<void> clearPendingConsultation() async {
    _pendingPayment = null;
    _intentLaunchedAwaitingWebhook = false;
    await UserPreference.clearPendingConsultationPayment();
    notifyListeners();
  }

  /// Call when user abandons checkout (back navigation) while hold exists and no payment started.
  Future<void> abandonUnpaidHold() async {
    final token = _hold?.lockToken;
    if (token == null || _intentLaunchedAwaitingWebhook) return;
    try {
      await _repo.releaseSlotLock(token);
    } catch (_) {
      // Best-effort; lock will expire server-side.
    } finally {
      clearForNewFlow();
    }
  }

  void _cancelExpiryTicker() {
    _expiryTicker?.cancel();
    _expiryTicker = null;
  }

  void _startExpiryTicker() {
    _cancelExpiryTicker();
    _expiryTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final h = _hold;
      if (h == null) return;
      final now = ServerTimeService.instance.nowServerUtc();
      if (h.isExpiredAt(now)) {
        _remaining = Duration.zero;
        _lastError = 'Your slot hold expired. Choose a time again to continue.';
        _cancelExpiryTicker();
        notifyListeners();
        return;
      }
      _remaining = h.expiresAtUtc.difference(now);
      notifyListeners();
    });
  }

  /// Client idempotency key: one per checkout attempt (lock + matching intent uses same key).
  Future<({bool ok, String? message})> requestSlotLock({
    required String doctorId,
    required String slotDate,
    required String slotTime,
  }) async {
    _busy = true;
    _lastError = null;
    notifyListeners();

    final clientRequestId = _uuid.v4();
    try {
      final body = <String, dynamic>{
        'doctorId': doctorId,
        'slotDate': slotDate,
        'slotTime': slotTime,
        'clientRequestId': clientRequestId,
      };

      pt('[CONSULTATION_LOCK] Requesting slot lock $body');
      final res = await _repo.requestSlotLock(body);
      pt('[CONSULTATION_LOCK] Slot lock response $res');
      final success = res['success'] == true;
      if (!success) {
        final msg = res['message']?.toString() ?? 'Slot could not be held.';
        _lastError = msg;
        return (ok: false, message: msg);
      }

      final hold = slotHoldFromLockResponse(
        res,
        doctorId: doctorId,
        slotDate: slotDate,
        slotTime: slotTime,
        clientRequestId: clientRequestId,
      );
      if (hold == null) {
        const msg = 'Invalid lock response from server.';
        _lastError = msg;
        return (ok: false, message: msg);
      }

      _hold = hold;
      pt(
        '[CONSULTATION_LOCK] Slot locked token=${hold.lockToken} '
        'consultationId=${hold.consultationDraftId ?? "(none)"} '
        'expiresAt=${hold.expiresAtUtc.toIso8601String()} '
        'clientRequestId=${hold.clientRequestId} '
        'amountPaise=${hold.amountPaise ?? "(none)"} '
        'currency=${hold.currency ?? "(none)"}',
      );
      _startExpiryTicker();
      final now = ServerTimeService.instance.nowServerUtc();
      _remaining = hold.expiresAtUtc.difference(now);
      return (ok: true, message: null);
    } on ConsultationApiException catch (e) {
      _lastError = e.message;
      return (ok: false, message: e.message);
    } catch (e) {
      final msg = e.toString();
      _lastError = msg;
      return (ok: false, message: msg);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Creates PhonePe intent and opens PSP. Does not mark payment success.
  /// Caller must open [AppRoutes.consultationPaymentVerification] when [ok] is true.
  Future<({bool ok, String? message, PhonePeLaunch? launch})>
  launchPhonePeCheckout() async {
    final hold = _hold;
    if (_pendingPayment != null) {
      const msg =
          'A consultation payment is already awaiting server confirmation.';
      _lastError = msg;
      return (ok: false, message: msg, launch: null);
    }
    if (hold == null ||
        hold.isExpiredAt(ServerTimeService.instance.nowServerUtc())) {
      const msg = 'No active slot hold. Go back and select a slot again.';
      _lastError = msg;
      return (ok: false, message: msg, launch: null);
    }

    _busy = true;
    _lastError = null;
    notifyListeners();

    // Per contract §11: this MUST be a different UUID from the one used at
    // /slot-lock — re-using `hold.clientRequestId` returns
    // `409 clientRequestId does not match this lock`.
    final intentClientRequestId = _uuid.v4();
    try {
      final body = <String, dynamic>{
        'lockToken': hold.lockToken,
        'clientRequestId': intentClientRequestId,
        'redirectUrl': phonePeReturnScheme,
      };

      pt('[PHONEPE_INTENT] Creating PhonePe intent $body');
      final res = await _repo.createPhonePeIntent(body);
      pt('[PHONEPE_INTENT] PhonePe intent response $res');
      if (res['success'] != true) {
        final msg = res['message']?.toString() ?? 'Could not start payment.';
        _lastError = msg;
        return (ok: false, message: msg, launch: null);
      }

      final launch = phonePeLaunchFromIntentResponse(res);
      if (launch == null) {
        const msg = 'Payment could not start (invalid PSP response).';
        _lastError = msg;
        return (ok: false, message: msg, launch: null);
      }

      _lastLaunch = launch;
      notifyListeners();

      final uri = Uri.tryParse(launch.paymentLaunchUrl);
      if (uri == null) {
        const msg = 'Invalid payment URL.';
        _lastError = msg;
        return (ok: false, message: msg, launch: null);
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        const msg = 'Could not open PhonePe. Install or update PhonePe.';
        _lastError = msg;
        return (ok: false, message: msg, launch: null);
      }

      _intentLaunchedAwaitingWebhook = true;
      _cancelExpiryTicker();
      _pendingPayment = PendingConsultationPayment(
        lockToken: hold.lockToken,
        // Persist the slot-lock's clientRequestId, since that's what identifies
        // the hold; the intent-side id is single-use and not needed for resume.
        clientRequestId: hold.clientRequestId,
        merchantTransactionId: launch.merchantTransactionId,
        consultationId: launch.consultationId ?? hold.consultationDraftId,
      );
      await UserPreference.savePendingConsultationPayment(
        _pendingPayment!.toJson(),
      );
      pt(
        '[PHONEPE_INTENT] Launched externally and saved pending payment '
        'lockToken=${hold.lockToken} '
        'merchantTransactionId=${launch.merchantTransactionId} '
        'consultationId=${_pendingPayment!.consultationId ?? "(none)"} '
        'lockClientRequestId=${hold.clientRequestId} '
        'intentClientRequestId=$intentClientRequestId '
        'amountPaise=${launch.amountPaise ?? "(none)"}',
      );

      return (ok: true, message: null, launch: launch);
    } on ConsultationApiException catch (e) {
      _lastError = e.message;
      return (ok: false, message: e.message, launch: null);
    } catch (e) {
      final msg = e.toString();
      _lastError = msg;
      return (ok: false, message: msg, launch: null);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Single projection read (caller implements backoff / max duration).
  Future<ConsultationProjection?> pollProjectionOnce({
    String? consultationId,
    String? merchantTransactionId,
  }) async {
    try {
      Map<String, dynamic> raw;
      if (consultationId != null && consultationId.isNotEmpty) {
        pt(
          '[PROJECTION_POLL] Fetching consultation projection $consultationId',
        );
        raw = await _repo.fetchConsultationProjection(consultationId);
      } else if (merchantTransactionId != null &&
          merchantTransactionId.isNotEmpty) {
        pt(
          '[PROJECTION_POLL] Fetching payment projection $merchantTransactionId',
        );
        raw = await _repo.fetchPaymentProjection(merchantTransactionId);
      } else {
        return null;
      }
      final projection = consultationProjectionFromJson(raw);
      pt(
        '[PROJECTION_POLL] paymentStatus=${projection.paymentStatus ?? "(null)"} '
        'lifecycleState=${projection.lifecycleState ?? "(null)"} '
        'consultationStatus=${projection.consultationStatus ?? "(null)"} eff=${projection.effectiveLifecycle} '
        'terminalPaid=${projection.isTerminalPaid} '
        'merchantTransactionId=${projection.merchantTransactionId ?? merchantTransactionId ?? "(none)"} '
        'consultationId=${projection.consultationId ?? consultationId ?? "(none)"}',
      );
      return projection;
    } on ConsultationApiException {
      rethrow;
    }
  }

  void markVerificationUiClosed() {
    _intentLaunchedAwaitingWebhook = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelExpiryTicker();
    super.dispose();
  }
}
