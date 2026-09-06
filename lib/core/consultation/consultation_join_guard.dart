import 'package:babyland/app/agora/video_call_controller.dart';
import 'package:babyland/app/agora/video_call_screen.dart';
import 'package:babyland/app/controller/experts_consultation/model/booking_data_model.dart';
import 'package:babyland/app/data/network/network_api_services.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/core/consultation/agora_rtc_session_dto.dart';
import 'package:babyland/core/consultation/booking_lifecycle.dart';
import 'package:babyland/core/consultation/patient_session_join_guard.dart';
import 'package:babyland/core/environment/app_environment.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/observability/app_runtime_audit_trail.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Only allow Agora entry when server-derived lifecycle is **ready to join**
/// and RTC credentials are acquired from `POST /agoras/rtc` (backend-only).
class ConsultationJoinGuard {
  ConsultationJoinGuard._();

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

    try {
      final projectionRepo = ConsultationCheckoutRepository(
        api: NetworkApiServices(),
      );

      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparing your video session…'),
                    SizedBox(height: 8),
                    Text(
                      'First connection on iPhone can take a minute.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      AgoraRtcSessionDto dto;
      try {
        dto = await PatientSessionJoinGuard.instance.acquireRtcOrThrow(
          booking: booking,
          projectionRepo: projectionRepo,
        );

        // Pre-warm Agora on iOS during this dialog — first initialize() can
        // take 45–60s; doing it here avoids the connect-screen false timeout.
        final appId = dto.appId?.trim().isNotEmpty == true
            ? dto.appId!.trim()
            : AppEnvironment.agoraAppIdFromEnv;
        if (appId != null && appId.isNotEmpty && context.mounted) {
          try {
            await context.read<VideoCallProvider>().ensureEngineReady(
                  agoraAppId: appId,
                );
          } catch (e) {
            // Still open the call screen — join/retry will re-attempt init.
            AppAuditLog.instance.log(
              'join_failure',
              component: 'ConsultationJoinGuard',
              consultationId: consultationId,
              outcome: 'prewarm_failed:$e',
            );
          }
        }
      } finally {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }

      if (!context.mounted) return;
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
