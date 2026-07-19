// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:babyland/app/controller/experts_consultation/booking/booking_controller.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_controller.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_repository.dart';
import 'package:babyland/features/patient_consultation/consultation_models.dart';
import 'package:babyland/features/patient_consultation/consultation_projection_summary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Confirms payment strictly from server projection polling — never from PhonePe UI or return URI.
class ConsultationPaymentVerificationView extends StatefulWidget {
  const ConsultationPaymentVerificationView({super.key});

  @override
  State<ConsultationPaymentVerificationView> createState() =>
      _ConsultationPaymentVerificationViewState();
}

class _ConsultationPaymentVerificationViewState
    extends State<ConsultationPaymentVerificationView>
    with WidgetsBindingObserver {
  Timer? _poll;
  StreamSubscription<Uri>? _paymentReturnLinkSub;
  final AppLinks _appLinks = AppLinks();
  int _ticks = 0;
  static const int _maxTicks = 120; // ~6 min at 3s

  String? _merchantId;
  String? _consultationId;

  String? _projectionError;
  ConsultationProjection? _lastProjection;

  bool _done = false;
  bool _pollInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapProjectionPolling());
      unawaited(_attachPaymentReturnDeepLinks());
    });
  }

  Future<void> _bootstrapProjectionPolling() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _merchantId = args?['merchantTransactionId'] as String?;
    _consultationId = args?['consultationId'] as String?;

    if ((_merchantId == null || _merchantId!.isEmpty) &&
        (_consultationId == null || _consultationId!.isEmpty)) {
      final pending = await context
          .read<ConsultationCheckoutController>()
          .restorePendingConsultation();
      if (!mounted) return;
      _merchantId = pending?.merchantTransactionId;
      _consultationId = pending?.consultationId;
    }

    pt(
      '[PROJECTION_POLL] Verification screen bootstrap '
      'merchantTransactionId=${_merchantId ?? "(none)"} '
      'consultationId=${_consultationId ?? "(none)"}',
    );
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    unawaited(_paymentReturnLinkSub?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// App resume from PhonePe: **only** continue polling — never treat as success.
    if (state == AppLifecycleState.resumed && !_done && mounted) {
      pt('[PROJECTION_POLL] App resumed; refreshing projection immediately');
      refreshProjectionPoll();
    }
  }

  /// `babyland://consultation-payment-return` — **only** triggers GET projection polling.
  /// Never parses query/body for success; never shows success from URI.
  static bool _isConsultationPaymentReturnUri(Uri uri) {
    if (uri.scheme != 'babyland') return false;
    if (uri.host == 'consultation-payment-return') return true;
    return uri.toString().startsWith(
      ConsultationCheckoutController.phonePeReturnScheme,
    );
  }

  Future<void> _attachPaymentReturnDeepLinks() async {
    try {
      _paymentReturnLinkSub = _appLinks.uriLinkStream.listen((Uri uri) {
        if (!_isConsultationPaymentReturnUri(uri) || _done || !mounted) return;
        AppAuditLog.instance.log(
          'payment_return_deep_link',
          component: 'ConsultationPaymentVerification',
          reason: uri.host,
        );
        unawaited(UserPreference.appendDeepLinkHistory(uri.toString()));
        refreshProjectionPoll();
      });
      final initial = await _appLinks.getInitialLink();
      if (initial != null &&
          _isConsultationPaymentReturnUri(initial) &&
          mounted &&
          !_done) {
        unawaited(UserPreference.appendDeepLinkHistory('initial:$initial'));
        refreshProjectionPoll();
      }
    } catch (_) {
      // Platform may not support stream; lifecycle resume still polls.
    }
  }

  /// Single projection refresh (GET projection). Used by timer, resume, and deep link.
  Future<void> refreshProjectionPoll() async {
    await _pollOnce();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _pollOnce());
    unawaited(_pollOnce());
  }

  Future<void> _pollOnce() async {
    if (!mounted || _done || _pollInFlight) return;
    if (_ticks >= _maxTicks) {
      setState(
        () => _projectionError =
            'Confirmation is taking longer than usual. Check My Bookings shortly or contact support.',
      );
      _poll?.cancel();
      return;
    }
    _ticks++;
    _pollInFlight = true;

    final checkout = context.read<ConsultationCheckoutController>();
    try {
      AppAuditLog.instance.log(
        'booking_projection_poll',
        component: 'ConsultationPaymentVerification',
        consultationId: _consultationId,
        merchantTransactionId: _merchantId,
      );
      final proj = await checkout.pollProjectionOnce(
        consultationId: _consultationId,
        merchantTransactionId: _merchantId,
      );
      if (!mounted) return;
      setState(() {
        _lastProjection = proj ?? _lastProjection;
        _projectionError = null;
      });

      if (proj != null && proj.isTerminalPaid) {
        unawaited(_finishSuccess(checkout, proj));
      } else if (proj != null && proj.isTerminalFailed) {
        _finishFailed(checkout, proj);
      }
    } on ConsultationApiException catch (e) {
      if (!mounted) return;
      setState(() => _projectionError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectionError = e.toString());
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _finishSuccess(
    ConsultationCheckoutController checkout,
    ConsultationProjection confirmed,
  ) async {
    if (_done) return;
    _done = true;
    pt(
      '[PAYMENT_SUCCESS] Projection confirmed success '
      'paymentStatus=${confirmed.paymentStatus ?? "(null)"} '
      'consultationStatus=${confirmed.consultationStatus ?? "(null)"} '
      'merchantTransactionId=${_merchantId ?? "(none)"}',
    );
    AppAuditLog.instance.log(
      'consultation_payment_projection_success',
      component: 'ConsultationPaymentVerification',
      consultationId: _consultationId ?? confirmed.consultationId,
      merchantTransactionId: _merchantId,
    );
    _poll?.cancel();
    unawaited(_paymentReturnLinkSub?.cancel());

    await context.read<AppStateReconciliationCoordinator>().reconcile(
          ReconcileTrigger.paymentReturn,
        );
    if (!mounted) return;

    final bookingCtrl = context.read<BookingController>();
    final rawId = confirmed.raw != null
        ? confirmed.raw!['_id']?.toString() ??
            confirmed.raw!['bookingId']?.toString()
        : null;
    final idToMatch =
        confirmed.consultationId ?? _consultationId ?? rawId;
    await bookingCtrl.waitForUpcomingBookingById(
      consultationOrBookingId: idToMatch,
    );

    checkout.markVerificationUiClosed();
    checkout.clearForNewFlow();
    if (!mounted) return;

    final summary = ConsultationProjectionSummary.fromProjection(confirmed);
    final nav = Navigator.of(context);
    nav.pop();
    if (nav.canPop()) nav.pop();
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.consultationPaymentSuccess,
      arguments: summary.toRouteArguments(),
    );
  }

  void _finishFailed(
    ConsultationCheckoutController checkout,
    ConsultationProjection p,
  ) {
    if (_done) return;
    _done = true;
    pt(
      '[PAYMENT_FAILED] Projection confirmed failure '
      'paymentStatus=${p.paymentStatus ?? "(null)"} '
      'merchantTransactionId=${_merchantId ?? "(none)"} '
      'reason=${p.failureReason ?? "(none)"}',
    );
    _poll?.cancel();
    checkout.markVerificationUiClosed();
    unawaited(checkout.clearPendingConsultation());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(p.failureReason ?? 'Payment could not be completed.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final projection = _lastProjection;
    final status =
        (_lastProjection?.paymentStatus ?? _lastProjection?.consultationStatus)
            ?.toUpperCase();
    final paymentUiState = projection == null || projection.isProcessingPayment
        ? 'Processing Payment'
        : projection.isTerminalPaid
        ? 'Consultation Confirmed'
        : projection.isTerminalFailed
        ? 'Retry Payment'
        : 'Processing Payment';

    return Scaffold(
      appBar: CustomAppBar(
        backgroundClr: AppColors.transparent,
        isLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              paymentUiState,
              style: AppFontStyle.text_20_600(
                color: AppColors.textClr,
                fontFamily: AppFontFamily.gilroySemiBold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We only confirm after backend webhook verification. '
              'Do not rely on PhonePe app screens for success.',
              style: AppFontStyle.text_14_400(
                color: AppColors.textLightClr,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: CircularProgressIndicator(color: AppColors.buttonClr1),
            ),
            const SizedBox(height: 24),
            if (status != null)
              Text(
                'Server status: $status',
                textAlign: TextAlign.center,
                style: AppFontStyle.text_14_400(
                  color: AppColors.textClr,
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
              ),
            if (_projectionError != null) ...[
              const SizedBox(height: 16),
              Text(
                _projectionError!,
                textAlign: TextAlign.center,
                style: AppFontStyle.text_13_400(
                  color: AppColors.red,
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: () {
                context
                    .read<ConsultationCheckoutController>()
                    .markVerificationUiClosed();
                pt(
                  '[PROJECTION_POLL] User left verification; pending payment retained',
                );
                Navigator.pop(context);
              },
              child: Text(
                'Leave and check later',
                style: AppFontStyle.text_15_600(
                  color: AppColors.textLightClr,
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
