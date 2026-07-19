// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:babyland/app/controller/experts_consultation/model/booking_data_model.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/core/consultation/booking_lifecycle.dart';
import 'package:babyland/core/time/server_time_service.dart';
import 'package:babyland/features/patient_consultation/consultation_booking_time_util.dart';
import 'package:flutter/material.dart';

class ConsultationCountdownRow extends StatefulWidget {
  const ConsultationCountdownRow({super.key, required this.booking});

  final Booking booking;

  @override
  State<ConsultationCountdownRow> createState() =>
      _ConsultationCountdownRowState();
}

class _ConsultationCountdownRowState extends State<ConsultationCountdownRow> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = bookingLifecycleFromBooking(widget.booking);
    if (phase == BookingLifecyclePhase.readyToJoin) {
      return Text(
        'You can join now — tap Join consultation.',
        style: AppFontStyle.text_13_600(
          fontFamily: AppFontFamily.gilroyMedium,
          color: AppColors.primary,
        ),
      );
    }
    if (phase == BookingLifecyclePhase.completed ||
        phase == BookingLifecyclePhase.cancelled) {
      return const SizedBox.shrink();
    }

    final start = parseConsultationStartLocal(widget.booking);
    if (start == null) return const SizedBox.shrink();

    final now = ServerTimeService.instance.nowServerUtc().toLocal();
    if (!start.isAfter(now)) {
      return Text(
        'Consultation time reached — waiting for host to open join.',
        style: AppFontStyle.text_12_400(
          fontFamily: AppFontFamily.gilroyRegular,
          color: AppColors.textLightClr,
        ),
      );
    }

    final diff = start.difference(now);
    final d = diff.inDays;
    final h = diff.inHours.remainder(24);
    final m = diff.inMinutes.remainder(60);
    String label;
    if (d > 0) {
      label = 'Starts in ${d}d ${h}h';
    } else if (h > 0) {
      label = 'Starts in ${h}h ${m}m';
    } else {
      label = 'Starts in ${m}m';
    }

    return Text(
      label,
      style: AppFontStyle.text_13_600(
        fontFamily: AppFontFamily.gilroyMedium,
        color: AppColors.textClr,
      ),
    );
  }
}
