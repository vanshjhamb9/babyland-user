// ignore_for_file: public_member_api_docs

import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/features/patient_consultation/consultation_projection_summary.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown only after [ConsultationProjection.isTerminalPaid] (server booking + lifecycle).
class ConsultationPaymentSuccessView extends StatelessWidget {
  const ConsultationPaymentSuccessView({super.key});

  static const String supportMail = 'mailto:support@babyland.health';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final summary = args is Map<String, dynamic>
        ? ConsultationProjectionSummary.fromRouteArguments(args)
        : null;

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('Missing confirmation data.')),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundClr,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Payment successful',
            style: AppFontStyle.text_18_600(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textClr,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 72),
                const SizedBox(height: 16),
                Text(
                  'Your consultation is confirmed',
                  textAlign: TextAlign.center,
                  style: AppFontStyle.text_20_600(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We verified this with our servers — not from the payment app alone.',
                  textAlign: TextAlign.center,
                  style: AppFontStyle.text_13_400(
                    fontFamily: AppFontFamily.gilroyRegular,
                    color: AppColors.textLightClr,
                  ),
                ),
                const SizedBox(height: 28),
                _tile('Doctor', summary.doctorName),
                _tile('Specialization', summary.specialization),
                _tile('Booking ID', summary.consultationId ?? '—'),
                _tile('Date', summary.consultationDate),
                _tile('Time', summary.consultationTime),
                _tile('Meeting status', summary.meetingStatusLabel),
                if (summary.paymentStatus != null)
                  _tile('Payment', summary.paymentStatus!),
                if (summary.amountLine != null)
                  _tile('Amount paid', summary.amountLine!),
                const Spacer(),
                Button(
                  borderRadius: 12,
                  height: 48,
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.myBookingsView,
                      arguments: <String, dynamic>{'forceRefresh': true},
                    );
                  },
                  child: Center(
                    child: Text(
                      'View booking',
                      style: AppFontStyle.text_16_500(
                        fontFamily: AppFontFamily.gilroySemiBold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.myBookingsView,
                      arguments: <String, dynamic>{'forceRefresh': true},
                    );
                  },
                  child: Text(
                    'Join when available',
                    style: AppFontStyle.text_15_600(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final uri = Uri.parse(supportMail);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Text(
                    'Contact support',
                    style: AppFontStyle.text_14_600(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.textLightClr,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppFontStyle.text_13_400(
                fontFamily: AppFontFamily.gilroyRegular,
                color: AppColors.textLightClr,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFontStyle.text_14_600(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.textClr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
