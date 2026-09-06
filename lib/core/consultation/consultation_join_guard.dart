import 'dart:async';

import 'package:babyland/app/agora/video_call_screen.dart';
import 'package:babyland/app/controller/experts_consultation/model/booking_data_model.dart';
import 'package:babyland/app/data/network/network_api_services.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/core/consultation/agora_rtc_session_dto.dart';
import 'package:babyland/core/consultation/booking_lifecycle.dart';
import 'package:babyland/core/consultation/patient_session_join_guard.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/observability/app_runtime_audit_trail.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Only allow Agora entry when server-derived lifecycle is **ready to join**
/// and RTC credentials are acquired from `POST /agoras/rtc` (backend-only).
///
/// This dialog must never await Agora native `initialize()` — that happens on
/// [VideoCallScreen] so a slow/hung SDK cannot trap the user on My Bookings.
class ConsultationJoinGuard {
  ConsultationJoinGuard._();

  static const Duration _prepTimeout = Duration(seconds: 20);

  static Future<void> maybeOpenVideo({
    required BuildContext context,
    required Booking booking,
  }) async {
    final phase = bookingLifecycleFromBooking(booking);
    AppAuditLog.instance.log(
      'join_attempt',
      component: 'ConsultationJoinGuard',
      reason: phase.name,
      bookingId: booking.effectiveId,
      consultationId: booking.consultationId,
    );
    AppRuntimeAuditTrail.log(
      AppRuntimeEvent.sessionJoinAttempt,
      reason: phase.name,
    );

    if (phase != BookingLifecyclePhase.readyToJoin &&
        phase != BookingLifecyclePhase.inProgress) {
      AppPopUp.showToast(
        message: 'Video opens when your consultation is ready to join.',
      );
      return;
    }

    final meeting = booking.meeting;
    if (meeting != null && meeting.agoraEnabled == false) {
      AppPopUp.showToast(
        message: 'Video calling is temporarily unavailable. Please try later.',
      );
      return;
    }

    final consultationId =
        booking.consultationId ?? booking.effectiveId ?? booking.sId;
    if (consultationId == null || consultationId.isEmpty) {
      AppPopUp.showToast(
        message: 'Consultation reference missing. Please refresh.',
      );
      return;
    }

    var userAborted = false;
    var tokenAcquired = false;
    var dialogVisible = false;

    try {
      final projectionRepo = ConsultationCheckoutRepository(
        api: NetworkApiServices(),
      );

      if (!context.mounted) return;
      dialogVisible = true;
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop && !tokenAcquired) userAborted = true;
          },
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Preparing your video session…'),
                    const SizedBox(height: 8),
                    const Text(
                      'Fetching secure call credentials…',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        userAborted = true;
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).whenComplete(() {
        dialogVisible = false;
      });

      final AgoraRtcSessionDto dto;
      try {
        dto = await PatientSessionJoinGuard.instance
            .acquireRtcOrThrow(
              booking: booking,
              projectionRepo: projectionRepo,
            )
            .timeout(_prepTimeout);
        tokenAcquired = true;
      } on TimeoutException {
        PatientSessionJoinGuard.instance.clearRtcFlight();
        throw PatientJoinNotAllowedException(
          'Video setup timed out. Check your connection and try again.',
        );
      } finally {
        if (context.mounted && dialogVisible) {
          Navigator.of(context, rootNavigator: true).pop();
          dialogVisible = false;
        }
      }

      if (userAborted || !context.mounted) {
        if (userAborted) {
          AppPopUp.showToast(message: 'Video join cancelled.');
        }
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoCallScreen(backendSession: dto),
        ),
      );
    } on PatientJoinNotAllowedException catch (e) {
      AppAuditLog.instance.log(
        'join_failure',
        component: 'ConsultationJoinGuard',
        consultationId: consultationId,
        outcome: e.message,
      );
      AppPopUp.showToast(message: e.message);
    } on DioException catch (e) {
      final message = _userFacingRtcError(e);
      AppAuditLog.instance.log(
        'join_failure',
        component: 'ConsultationJoinGuard',
        consultationId: consultationId,
        outcome: message,
      );
      AppPopUp.showToast(message: message);
    } on FormatException catch (e) {
      AppAuditLog.instance.log(
        'join_failure',
        component: 'ConsultationJoinGuard',
        consultationId: consultationId,
        outcome: e.message,
      );
      AppPopUp.showToast(
        message:
            'Video session could not start. Refresh your consultation and try again.',
      );
    } catch (e) {
      AppAuditLog.instance.log(
        'join_failure',
        component: 'ConsultationJoinGuard',
        consultationId: consultationId,
        outcome: e.toString(),
      );
      AppPopUp.showToast(
        message: 'Could not start the video visit. Please try again.',
      );
    }
  }

  static String _userFacingRtcError(DioException e) {
    final code = e.response?.statusCode;
    final body = e.response?.data;
    final errCode = body is Map
        ? (body['error'] is Map
            ? body['error']['code']?.toString()
            : body['code']?.toString())
        : null;

    if (code == 410) {
      return 'This session is no longer available. Refresh your consultation list.';
    }
    if (code == 403 && errCode == 'TOO_EARLY') {
      return 'The join window has not opened yet. Try again shortly before your slot.';
    }
    if (code == 403) {
      return 'You are not authorized to join this consultation.';
    }
    if (code == 409) {
      return 'This visit is not ready to join yet. Make sure payment is complete.';
    }
    if (code == 503) {
      return 'Video service is temporarily unavailable. Please try again.';
    }
    return 'Could not start the video visit. Please try again.';
  }
}
