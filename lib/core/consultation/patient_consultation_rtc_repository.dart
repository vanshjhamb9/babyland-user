// ignore_for_file: public_member_api_docs

import 'package:babyland/app/data/network/end_points.dart';
import 'package:babyland/app/data/network/network_api_services.dart';
import 'package:babyland/core/consultation/agora_rtc_session_dto.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:dio/dio.dart';

/// Fetches authoritative Agora RTC credentials from the backend.
class PatientConsultationRtcRepository {
  PatientConsultationRtcRepository({NetworkApiServices? api})
      : _api = api ?? NetworkApiServices();

  final NetworkApiServices _api;

  static const int _maxAttempts = 3;

  Future<AgoraRtcSessionDto> fetchPatientRtcToken({
    required String consultationId,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _api.post(
          EndPoints.agoraRtcTokenApi,
          data: {
            'consultationId': consultationId,
            'role': 'patient',
          },
        );

        if (_isTransientServerFailure(response)) {
          lastError = StateError(_serverMessage(response));
          AppAuditLog.instance.log(
            'join_failure',
            component: 'PatientRtcRepository',
            consultationId: consultationId,
            reason: 'transient_server_failure',
            outcome: 'attempt_$attempt',
          );
          if (attempt < _maxAttempts) {
            await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
            continue;
          }
          throw StateError(
            'The server could not load this consultation right now. '
            'Please try again in a moment.',
          );
        }

        return AgoraRtcSessionDto.parse(response);
      } catch (e) {
        if (attempt < _maxAttempts && _isTransientTransport(e)) {
          lastError = e;
          await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
          continue;
        }
        AppAuditLog.instance.log(
          'join_failure',
          component: 'PatientRtcRepository',
          consultationId: consultationId,
          outcome: e.toString(),
        );
        rethrow;
      }
    }
    throw lastError ??
        StateError('Failed to acquire RTC token for $consultationId');
  }

  bool _isTransientServerFailure(dynamic response) {
    if (response is! Map) return false;
    if (response['success'] != false) return false;
    final error = response['error'];
    final code = (error is Map ? error['code'] : null)?.toString() ?? '';
    final message =
        ((error is Map ? error['message'] : null) ?? response['message'] ?? '')
            .toString()
            .toLowerCase();
    return code == 'REQUEST_FAILED' ||
        message.contains('failed to load consultation');
  }

  String _serverMessage(dynamic response) {
    if (response is Map) {
      final error = response['error'];
      final m = (error is Map ? error['message'] : null) ?? response['message'];
      if (m != null) return m.toString();
    }
    return 'RTC token request failed';
  }

  bool _isTransientTransport(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode ?? 0;
          return code >= 500 && code < 600;
        default:
          return false;
      }
    }
    return false;
  }
}
