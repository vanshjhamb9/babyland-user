// ignore_for_file: public_member_api_docs

import 'package:babyland/app/data/network/end_points.dart';
import 'package:babyland/app/data/network/network_api_services.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:dio/dio.dart';

/// Thin API layer for Phase 1/2 checkout. Responses are authoritative only after projection reads.
class ConsultationCheckoutRepository {
  ConsultationCheckoutRepository({required NetworkApiServices api})
    : _api = api;

  final NetworkApiServices _api;

  Future<Map<String, dynamic>> requestSlotLock(
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await _api.post(
        EndPoints.patientConsultationSlotLock,
        data: body,
      );
      return _asMap(r);
    } on DioException catch (e) {
      throw ConsultationApiException(
        _messageFromDio(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> releaseSlotLock(String lockToken) async {
    try {
      pt('[CONSULTATION_LOCK] Releasing slot lock $lockToken');
      final r = await _api.delete(
        EndPoints.patientConsultationSlotLockByToken(lockToken),
      );
      return _asMap(r);
    } on DioException catch (e) {
      throw ConsultationApiException(
        _messageFromDio(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> createPhonePeIntent(
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await _api.post(
        EndPoints.patientConsultationPhonePeIntent,
        data: body,
      );
      return _asMap(r);
    } on DioException catch (e) {
      throw ConsultationApiException(
        _messageFromDio(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Poll [`consultationId`] projection (webhook → DB → read model).
  Future<Map<String, dynamic>> fetchConsultationProjection(
    String consultationId,
  ) async {
    try {
      final r = await _api.get(
        EndPoints.patientConsultationProjection(consultationId),
      );
      return _asMap(r);
    } on DioException catch (e) {
      throw ConsultationApiException(
        _messageFromDio(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Alternate poll when server keys state by PSP transaction id.
  Future<Map<String, dynamic>> fetchPaymentProjection(
    String merchantTransactionId,
  ) async {
    try {
      final r = await _api.get(
        EndPoints.patientConsultationPaymentProjection(merchantTransactionId),
      );
      return _asMap(r);
    } on DioException catch (e) {
      throw ConsultationApiException(
        _messageFromDio(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic r) {
    if (r is Map<String, dynamic>) return r;
    if (r is Map) return Map<String, dynamic>.from(r);
    return <String, dynamic>{};
  }

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    String raw;
    if (data is Map && data['message'] != null) {
      raw = data['message'].toString();
    } else if (data is Map && data['error'] != null) {
      raw = data['error'].toString();
    } else {
      raw = e.message ?? 'Network request failed';
    }
    if (e.response?.statusCode == 503) {
      pt('[CONSULTATION_API] 503: $raw');
    }
    return _userFacingConsultationMessage(raw);
  }

  /// Maps known server-side Postgres / checkout-unavailable errors to clearer copy.
  String _userFacingConsultationMessage(String serverMessage) {
    final lower = serverMessage.toLowerCase();
    if (lower.contains('postgresql schema validation') ||
        lower.contains('consultation checkout is unavailable') ||
        lower.contains('consultation_database_url') ||
        lower.contains('econnrefused') && lower.contains('5432')) {
      return 'Consultation booking is temporarily unavailable because the '
          'server database is not ready. Please try again later or contact support.';
    }
    return serverMessage;
  }
}

class ConsultationApiException implements Exception {
  ConsultationApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
