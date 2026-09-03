// ignore_for_file: public_member_api_docs

import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/experts_consultation/model/booking_data_model.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/core/consultation/booking_lifecycle.dart';
import 'package:babyland/core/consultation/consultation_join_guard.dart';
import 'package:babyland/features/patient_consultation/widgets/consultation_countdown_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultationBookingDetailView extends StatelessWidget {
  const ConsultationBookingDetailView({super.key, required this.booking});

  final Booking booking;

  static const String supportMail = 'mailto:support@babyland.health';

  String _dateStr() {
    final d = booking.date;
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final phase = bookingLifecycleFromBooking(booking);
    final url = booking.doctorId?.profileImageUrl;
    final spec = booking.doctorId?.specialization?.trim().isNotEmpty == true
        ? booking.doctorId!.specialization!
        : 'Specialty';

    return Scaffold(
      backgroundColor: AppColors.backgroundClr,
      appBar: CustomAppBar(
        leadingOnTap: () => Navigator.pop(context),
        isIosBackBtn: true,
        title: Text(
          'Consultation details',
          style: AppFontStyle.text_18_600(
            fontFamily: AppFontFamily.gilroyMedium,
            color: AppColors.textClr,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url != null && url.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: url,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => CustomImage(
                            path: ImageConstants.networkImageDemo,
                            h: 72,
                            w: 72,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        )
                      : CustomImage(
                          path: ImageConstants.networkImageDemo,
                          h: 72,
                          w: 72,
                          borderRadius: BorderRadius.circular(12),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.doctorId?.name ?? 'Doctor',
                        style: AppFontStyle.text_18_600(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textClr,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spec,
                        style: AppFontStyle.text_14_400(
                          fontFamily: AppFontFamily.gilroyRegular,
                          color: AppColors.textLightClr,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _row('Booking ID', booking.sId ?? '—'),
            _row('Date', _dateStr()),
            _row('Time', booking.time ?? '—'),
            _row(
              'Timezone',
              booking.timezoneLabel ??
                  'Device local (${DateTime.now().timeZoneName})',
            ),
            _row('Consultation status', bookingLifecycleLabel(phase)),
            _row('Payment status', booking.paymentStatus ?? '—'),
            _row('Session status', booking.status ?? '—'),
            if (booking.formatAmount() != null)
              _row('Amount', booking.formatAmount()!),
            const SizedBox(height: 16),
            ConsultationCountdownRow(booking: booking),
            const SizedBox(height: 28),
            if (phase == BookingLifecyclePhase.readyToJoin)
              Button(
                borderRadius: 12,
                height: 50,
                onTap: () => ConsultationJoinGuard.maybeOpenVideo(
                  context: context,
                  booking: booking,
                ),
                child: Center(
                  child: Text(
                    'Join consultation',
                    style: AppFontStyle.text_16_500(
                      fontFamily: AppFontFamily.gilroySemiBold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              )
            else
              Text(
                phase == BookingLifecyclePhase.scheduled
                    ? 'Join unlocks when the session is ready to join (server state).'
                    : 'This booking is not in a joinable state yet.',
                style: AppFontStyle.text_13_400(
                  fontFamily: AppFontFamily.gilroyRegular,
                  color: AppColors.textLightClr,
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(supportMail);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              child: Text(
                'Contact support',
                style: AppFontStyle.text_14_600(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              k,
              style: AppFontStyle.text_13_400(
                fontFamily: AppFontFamily.gilroyRegular,
                color: AppColors.textLightClr,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
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
