// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:babyland/app/controller/experts_consultation/model/booking_data_model.dart';
import 'package:babyland/core/consultation/agora_rtc_session_dto.dart';
import 'package:babyland/core/consultation/booking_lifecycle.dart';
import 'package:babyland/core/consultation/patient_consultation_rtc_repository.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_repository.dart';

class PatientJoinNotAllowedException implements Exception {
  PatientJoinNotAllowedException(this.message);
  final String message;

  @override
  String toString() => 'PatientJoinNotAllowedException($message)';
}

/// Single-flight RTC acquisition with backend reconciliation and channel checks.
class PatientSessionJoinGuard {
  PatientSessionJoinGuard._();
  static final PatientSessionJoinGuard instance = PatientSessionJoinGuard._();

  final PatientConsultationRtcRepository _rtcRepo =
      PatientConsultationRtcRepository();

  Future<AgoraRtcSessionDto>? _rtcFlight;
  String? _rtcFlightConsultationId;

  static const Duration acquireTimeout = Duration(seconds: 20);

  static bool lifecycleAllowsJoin(Booking booking) {
    final phase = bookingLifecycleFromBooking(booking);
    if (phase != BookingLifecyclePhase.readyToJoin &&
        phase != BookingLifecyclePhase.inProgress) {
      return false;
    }
    return booking.joinAllowed == true;
  }

  /// Clears a stuck in-flight token request so the next Join tap can proceed.
  void clearRtcFlight() {
    _rtcFlight = null;
    _rtcFlightConsultationId = null;
  }

  Future<AgoraRtcSessionDto> acquireRtcOrThrow({
    required Booking booking,
    ConsultationCheckoutRepository? projectionRepo,
  }) async {
    final consultationId =
        booking.consultationId ?? booking.effectiveId ?? booking.sId;
    if (consultationId == null || consultationId.isEmpty) {
      throw PatientJoinNotAllowedException('Consultation reference missing');
    }

    final pending = _rtcFlight;
    if (pending != null) {
      if (_rtcFlightConsultationId != consultationId) {
        throw PatientJoinNotAllowedException(
          'RTC token issuance already running for another consultation',
        );
      }
      try {
        return await pending.timeout(acquireTimeout);
      } on TimeoutException {
        clearRtcFlight();
        throw PatientJoinNotAllowedException(
          'Video setup timed out. Check your connection and try again.',
        );
      }
    }

    AppAuditLog.instance.log(
      'join_attempt',
      component: 'PatientSessionJoinGuard',
      consultationId: consultationId,
      bookingId: booking.effectiveId,
    );

    _rtcFlightConsultationId = consultationId;
    final fut = () async {
      Booking fresh = booking;
      if (projectionRepo != null) {
        try {
          final projection = await projectionRepo
              .fetchConsultationProjection(consultationId)
              .timeout(const Duration(seconds: 8));
          final updated = _mergeProjectionIntoBooking(booking, projection);
          if (updated != null) fresh = updated;
        } catch (_) {
          // Projection refresh is best-effort; RTC endpoint is authoritative.
        }
      }

      if (!lifecycleAllowsJoin(fresh)) {
        throw PatientJoinNotAllowedException(
          'Consultation is not ready to join. Refresh and try again.',
        );
      }

      final dto = await _rtcRepo.fetchPatientRtcToken(
        consultationId: consultationId,
      );

      if (dto.isExpired || dto.expiresTooSoon) {
        AppAuditLog.instance.log(
          'token_expired',
          component: 'PatientSessionJoinGuard',
          consultationId: consultationId,
        );
        throw PatientJoinNotAllowedException(
          'Video session link expired. Refresh and try again.',
        );
      }

      final expectedChannel = fresh.meeting?.channelName;
      if (expectedChannel != null &&
          expectedChannel.isNotEmpty &&
          expectedChannel != dto.channelName) {
        AppAuditLog.instance.log(
          'channel_mismatch',
          component: 'PatientSessionJoinGuard',
          consultationId: consultationId,
          reason: expectedChannel,
          outcome: dto.channelName,
        );
        throw PatientJoinNotAllowedException(
          'Video session mismatch. Refresh your consultation and try again.',
        );
      }

      AppAuditLog.instance.log(
        'token_fetched',
        component: 'PatientSessionJoinGuard',
        consultationId: consultationId,
        traceId: dto.sessionId,
      );
      return dto;
    }().whenComplete(() {
      _rtcFlight = null;
      _rtcFlightConsultationId = null;
    });

    _rtcFlight = fut;
    try {
      return await fut.timeout(acquireTimeout);
    } on TimeoutException {
      clearRtcFlight();
      throw PatientJoinNotAllowedException(
        'Video setup timed out. Check your connection and try again.',
      );
    }
  }

  Booking? _mergeProjectionIntoBooking(
    Booking booking,
    Map<String, dynamic> projection,
  ) {
    try {
      final merged = Map<String, dynamic>.from(booking.toJson());
      merged.addAll(projection);
      if (projection['data'] is Map) {
        merged.addAll(Map<String, dynamic>.from(projection['data'] as Map));
      }
      return Booking.fromJson(merged);
    } catch (_) {
      return null;
    }
  }
}
