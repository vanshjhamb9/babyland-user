import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/app/utils/currency_formatter.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/font_family.dart';
import '../../../theme/font_style.dart';
import '../../../widgets/general_exception.dart';
import '../../../widgets/print.dart';

/// Checkout screen: requires an active server slot lock before PhonePe.
/// Payment success is **never** inferred here — only from projection polling.
class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  String? time;
  String? date;
  String? doctorId;

  /// Finds taxable base `B` (in paise) such that `B + round(B * rate/100) == total`,
  /// matching typical invoice rounding when GST applies on the subtotal.
  static int? _taxableBaseMatchingTotal(int totalPaise, num ratePercent) {
    for (var b = 0; b <= totalPaise; b++) {
      final tax = ((b * ratePercent) / 100.0).round();
      if (b + tax == totalPaise) return b;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      date = args?['appointmentDate'];
      time = args?['appointmentTime'];
      doctorId = args?['doctorId'];

      final provider = context.read<ExpertConsultationProvider>();
      provider.doctorDetailApiData(doctorId: doctorId ?? "");

      pt(
        "appointmentTime: $time >>> appointmentDate: $date >>> doctorId: $doctorId",
      );
    });
  }

  Future<void> _onPay(BuildContext context) async {
    final checkout = context.read<ConsultationCheckoutController>();
    if (!checkout.hasActiveLock) {
      AppPopUp.showToast(
        message:
            checkout.lastError ??
            'Slot hold is invalid. Go back and pick a slot again.',
        lineColor: AppColors.red,
      );
      return;
    }

    final out = await checkout.launchPhonePeCheckout();
    if (!context.mounted) return;

    if (!out.ok) {
      AppPopUp.showToast(
        message: out.message ?? 'Could not start payment.',
        lineColor: AppColors.red,
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.consultationPaymentVerification,
      arguments: <String, dynamic>{
        if (out.launch?.merchantTransactionId != null)
          'merchantTransactionId': out.launch!.merchantTransactionId,
        if (out.launch?.consultationId != null)
          'consultationId': out.launch!.consultationId,
      },
    );
  }

  String _fmtRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).abs();
    final s = d.inSeconds.remainder(60).abs();
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        await context
            .read<ConsultationCheckoutController>()
            .abandonUnpaidHold();
      },
      child: Scaffold(
        appBar: appbar(),
        body:
            Consumer2<
              ExpertConsultationProvider,
              ConsultationCheckoutController
            >(
              builder: (context, provider, checkout, _) {
                return switch (provider.doctorApiData?.status) {
                  ApiStatus.LOADING => _buildLoadingShimmer(),
                  ApiStatus.COMPLETED => _buildSuccessUI(
                    context,
                    provider,
                    checkout,
                  ),
                  ApiStatus.ERROR => GeneralExceptionWidget(
                    onPress: () =>
                        provider.doctorDetailApiData(doctorId: doctorId ?? ""),
                  ),
                  _ => _buildLoadingShimmer(),
                };
              },
            ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return AppContainer(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      gradient: AppColors.backGroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 120,
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.buttonClr,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 20),
          ...List.generate(
            4,
            (i) => Container(
              height: 20,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  /// Invoice lines for the checkout sheet — total always matches
  /// [SlotHold.amountPaise] when an active hold exists (same as PhonePe).
  (double doctor, double platform, double gst, double total, num gstPercent)
  _resolveCheckoutAmounts({
    required ExpertConsultationProvider provider,
    required ConsultationCheckoutController checkout,
  }) {
    final data = provider.doctorApiData?.data?.data?.first;
    final feeRupees = (data?.doctorDetails?.consultationFee ?? 0).toDouble();

    final hold = checkout.activeHold;
    final pricing = hold?.pricing;
    final totalPaise = hold?.amountPaise ?? pricing?.totalPaise;

    final gstPercent = pricing?.taxPercent ?? 18;

    if (totalPaise != null && totalPaise > 0) {
      final totalRupees = totalPaise / 100.0;

      final platPaise = pricing?.adminFeePaise ?? 1000;
      var docPaise = pricing?.doctorFeePaise ?? (feeRupees * 100).round();
      int taxPaise;

      final serverTax = pricing?.taxPaise;
      final linesMatchTotal =
          serverTax != null && docPaise + platPaise + serverTax == totalPaise;

      if (linesMatchTotal) {
        taxPaise = serverTax;
      } else if (serverTax != null) {
        taxPaise = totalPaise - docPaise - platPaise;
        if (taxPaise < 0) {
          final taxable = _taxableBaseMatchingTotal(totalPaise, gstPercent);
          if (taxable != null) {
            docPaise = (taxable - platPaise).clamp(0, taxable);
            taxPaise = totalPaise - taxable;
          } else {
            taxPaise = ((docPaise + platPaise) * gstPercent / 100.0).round();
            docPaise = totalPaise - platPaise - taxPaise;
            if (docPaise < 0) {
              docPaise = 0;
              taxPaise = totalPaise - platPaise;
            }
          }
        }
      } else {
        taxPaise = totalPaise - docPaise - platPaise;
        if (taxPaise < 0) {
          final taxable = _taxableBaseMatchingTotal(totalPaise, gstPercent);
          if (taxable != null) {
            docPaise = (taxable - platPaise).clamp(0, taxable);
            taxPaise = totalPaise - taxable;
          } else {
            taxPaise = ((docPaise + platPaise) * gstPercent / 100.0).round();
            docPaise = totalPaise - platPaise - taxPaise;
            if (docPaise < 0) {
              docPaise = 0;
              taxPaise = totalPaise - platPaise;
            }
          }
        }
      }

      return (
        docPaise / 100.0,
        platPaise / 100.0,
        taxPaise / 100.0,
        totalRupees,
        gstPercent,
      );
    }

    // No server quote yet (should be rare on this screen): show estimate from 18% GST.
    final platform = 10.0;
    final taxable = feeRupees + platform;
    final gst = (taxable * 0.18 * 100).round() / 100.0;
    final total = taxable + gst;
    return (feeRupees, platform, gst, total, gstPercent);
  }

  Widget _buildSuccessUI(
    BuildContext context,
    ExpertConsultationProvider provider,
    ConsultationCheckoutController checkout,
  ) {
    final data = provider.doctorApiData?.data?.data?.first;

    final amounts = _resolveCheckoutAmounts(
      provider: provider,
      checkout: checkout,
    );
    final doctorRupees = amounts.$1;
    final platformRupees = amounts.$2;
    final gstRupees = amounts.$3;
    final totalRupees = amounts.$4;
    final gstPercent = amounts.$5;
    final gstLabelPct = gstPercent == gstPercent.roundToDouble()
        ? gstPercent.round().toString()
        : gstPercent.toString();

    final hasLock = checkout.hasActiveLock;
    final holdExpired =
        checkout.lastError?.contains('expired') == true ||
        (checkout.activeHold != null &&
            checkout.activeHold!.isExpiredAt(DateTime.now().toUtc()));

    return AppContainer(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      gradient: AppColors.backGroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppContainer(
            radius: 12,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            gradient: AppColors.buttonClr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImage(
                  path: ImageConstants.networkImageDemo,
                  h: 88,
                  w: 88,
                  borderRadius: BorderRadius.circular(8),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data?.name?.toString() ?? "Doctor Name",
                        style: AppFontStyle.text_16_600(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Specialty",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.white,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.star,
                            color: AppColors.orangeClr,
                            size: 18,
                          ),
                          SizedBox(width: 2),
                          Text(
                            data?.doctorDetails?.totalReviewCount?.toString() ??
                                "0",
                            style: AppFontStyle.text_14_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "1 hour consultation",
                            style: AppFontStyle.text_16_500(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          _buildSafetyBanner(
            hasLock: hasLock,
            holdExpired: holdExpired,
            checkout: checkout,
          ),

          SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Appointment Cost",
                style: AppFontStyle.text_16_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
              Text(
                formatCurrency(doctorRupees),
                style: AppFontStyle.text_18_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
          Text(
            "Consultation fee for 1 hour",
            style: AppFontStyle.text_12_400(
              fontFamily: AppFontFamily.gilroyRegular,
              color: AppColors.textLightClr,
            ),
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Platform fee",
                style: AppFontStyle.text_16_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
              Text(
                formatCurrency(platformRupees),
                style: AppFontStyle.text_18_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "GST ($gstLabelPct%)",
                style: AppFontStyle.text_16_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
              Text(
                formatCurrency(gstRupees),
                style: AppFontStyle.text_18_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
          Text(
            "On consultation + platform fee",
            style: AppFontStyle.text_12_400(
              fontFamily: AppFontFamily.gilroyRegular,
              color: AppColors.textLightClr,
            ),
          ),
          SizedBox(height: 8),
          CustomTextFormField(
            height: 60,
            borderColor: AppColors.borderColor,
            labelText: "Enter Coupon",
            suffix: Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: AppContainer(
                gradient: AppColors.buttonClr,
                radius: 8,
                width: 120,
                child: Center(
                  child: Text(
                    "Apply",
                    style: AppFontStyle.text_16_500(
                      fontFamily: AppFontFamily.gilroyBold,
                      color: AppColors.textClr,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: AppFontStyle.text_16_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
              Text(
                formatCurrency(totalRupees),
                style: AppFontStyle.text_18_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
          if (checkout.activeHold?.amountPaise != null &&
              checkout.activeHold!.amountPaise! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'This total is the same amount you will see in PhonePe.',
                style: AppFontStyle.text_12_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color: AppColors.textLightClr,
                ),
              ),
            ),
          SizedBox(height: 18),
          Text(
            "PhonePe (UPI)",
            style: AppFontStyle.text_14_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textLightClr,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "We only confirm payment after the server verifies PhonePe. "
            "Returning from PhonePe does not guarantee success.",
            style: AppFontStyle.text_12_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textLightClr,
            ),
          ),
          SizedBox(height: 10),
          AppContainer(
            radius: 8,
            color: AppColors.white,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.buttonClr1,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  "Pay securely with PhonePe",
                  style: AppFontStyle.text_16_500(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.textClr,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Button(
            onTap:
                checkout.isBusy ||
                    !hasLock ||
                    holdExpired ||
                    checkout.isAwaitingServerPaymentTruth
                ? null
                : () => _onPay(context),
            borderRadius: 8,
            gradient: checkout.isBusy || !hasLock || holdExpired
                ? LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                  )
                : null,
            child: checkout.isBusy
                ? customLoading()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, color: AppColors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        checkout.isAwaitingServerPaymentTruth
                            ? "Awaiting server confirmation..."
                            : "Pay with PhonePe",
                        style: AppFontStyle.text_18_500(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: 12),
          if (!hasLock || holdExpired)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                holdExpired ? "Pick another slot" : "Back to slots",
                style: AppFontStyle.text_15_600(
                  color: AppColors.buttonClr1,
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner({
    required bool hasLock,
    required bool holdExpired,
    required ConsultationCheckoutController checkout,
  }) {
    if (holdExpired) {
      return AppContainer(
        radius: 8,
        color: AppColors.red.withValues(alpha: 0.08),
        padding: EdgeInsets.all(12),
        child: Text(
          checkout.lastError ??
              'Slot hold expired. Go back and select availability again.',
          style: AppFontStyle.text_14_400(
            fontFamily: AppFontFamily.gilroyMedium,
            color: AppColors.red,
          ),
        ),
      );
    }
    if (!hasLock) {
      return AppContainer(
        radius: 8,
        color: Colors.orange.withValues(alpha: 0.1),
        padding: EdgeInsets.all(12),
        child: Text(
          'No active server slot hold. Payment is disabled until a slot lock succeeds.',
          style: AppFontStyle.text_14_400(
            fontFamily: AppFontFamily.gilroyMedium,
            color: AppColors.textClr,
          ),
        ),
      );
    }
    return AppContainer(
      radius: 8,
      color: Colors.green.withValues(alpha: 0.12),
      padding: EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_clock, color: AppColors.green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Slot secured on server',
                  style: AppFontStyle.text_15_600(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.textClr,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Completing payment before this timer ends: ${_fmtRemaining(checkout.remainingLockTime)}',
                  style: AppFontStyle.text_13_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textLightClr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  CustomAppBar appbar() {
    return CustomAppBar(
      backgroundClr: AppColors.transparent,
      isIosBackBtn: true,
      title: Text(
        "My Booking",
        style: AppFontStyle.text_18_600(
          color: AppColors.textClr,
          fontFamily: AppFontFamily.gilroyMedium,
        ),
      ),
    );
  }
}
