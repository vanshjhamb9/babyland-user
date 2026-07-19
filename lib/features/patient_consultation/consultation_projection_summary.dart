// ignore_for_file: public_member_api_docs

import 'package:babyland/features/patient_consultation/consultation_models.dart';

/// Display fields extracted from a [ConsultationProjection].
///
/// Prefers the new top-level canonical fields (§12) — `doctor`, `meeting`,
/// `scheduledAt`, `amountPaise` — and falls back to the legacy `raw.*` map
/// only when the typed accessors are absent (older backend responses).
class ConsultationProjectionSummary {
  const ConsultationProjectionSummary({
    required this.consultationId,
    required this.merchantTransactionId,
    required this.meetingStatusLabel,
    required this.doctorName,
    required this.specialization,
    required this.consultationDate,
    required this.consultationTime,
    required this.paymentStatus,
    required this.consultationStatus,
    this.amountLine,
    this.amountPaise,
    this.currency,
    this.channelName,
    this.sessionId,
    this.agoraEnabled,
  });

  final String? consultationId;
  final String? merchantTransactionId;
  final String meetingStatusLabel;
  final String doctorName;
  final String specialization;
  final String consultationDate;
  final String consultationTime;
  final String? paymentStatus;
  final String? consultationStatus;

  /// Pre-formatted amount line for the invoice/total (e.g. `"₹ 500"`).
  /// Comes from the projection's `amountPaise` + `currency` — never recomputed
  /// from doctor fee. `null` when the projection didn't quote one.
  final String? amountLine;

  /// Raw paise from the projection (Section B §15).
  final int? amountPaise;
  final String? currency;

  /// Unique-per-consultation Agora channel name (`consultation:<uuid>`) sourced
  /// from `projection.meeting.channelName`. **Never** the legacy `"videoCall"`.
  final String? channelName;

  /// Equals `consultationId` for canonical responses.
  final String? sessionId;

  /// `false` when the server-side Agora app id isn't configured — UI should
  /// hide / disable the Join CTA.
  final bool? agoraEnabled;

  factory ConsultationProjectionSummary.fromProjection(
    ConsultationProjection p,
  ) {
    final m = p.raw ?? <String, dynamic>{};

    String readLegacy(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      final doc = m['doctor'];
      if (doc is Map) {
        final dm = Map<String, dynamic>.from(doc);
        for (final k in ['name', 'fullName', 'doctorName']) {
          final v = dm[k];
          if (v != null && v.toString().isNotEmpty) return v.toString();
        }
      }
      return '';
    }

    final doctorName = (p.doctor?.name?.isNotEmpty ?? false)
        ? p.doctor!.name!
        : readLegacy(const ['doctorName', 'doctor_name', 'providerName']);

    final specialization = (p.doctor?.specialization?.isNotEmpty ?? false)
        ? p.doctor!.specialization!
        : readLegacy(const [
            'specialization',
            'speciality',
            'specialty',
            'doctorSpecialization',
          ]);

    final date = (p.slotDate?.isNotEmpty ?? false)
        ? p.slotDate!
        : readLegacy(const [
            'slotDate',
            'appointmentDate',
            'consultationDate',
            'date',
          ]);

    final time = (p.slotTime?.isNotEmpty ?? false)
        ? p.slotTime!
        : readLegacy(const [
            'slotTime',
            'appointmentTime',
            'consultationTime',
            'time',
          ]);

    final lifecycle = (p.lifecycleState ??
            p.lifecycleStage ??
            p.consultationStatus ??
            '')
        .trim();
    final meeting = lifecycle.isEmpty
        ? (p.consultationStatus ?? p.paymentStatus ?? 'Confirmed')
        : lifecycle;

    return ConsultationProjectionSummary(
      consultationId: p.consultationId,
      merchantTransactionId: p.merchantTransactionId,
      meetingStatusLabel: meeting,
      doctorName: doctorName.isEmpty ? 'Your doctor' : doctorName,
      specialization:
          specialization.isEmpty ? 'Consultation' : specialization,
      consultationDate: date.isEmpty ? '—' : date,
      consultationTime: time.isEmpty ? '—' : time,
      paymentStatus: p.paymentStatus,
      consultationStatus: p.consultationStatus,
      amountLine: p.formatAmount(),
      amountPaise: p.amountPaise,
      currency: p.currency,
      channelName: p.meeting?.channelName,
      sessionId: p.meeting?.sessionId,
      agoraEnabled: p.meeting?.agoraEnabled,
    );
  }

  Map<String, dynamic> toRouteArguments() => <String, dynamic>{
        'consultationId': consultationId,
        'merchantTransactionId': merchantTransactionId,
        'meetingStatusLabel': meetingStatusLabel,
        'doctorName': doctorName,
        'specialization': specialization,
        'consultationDate': consultationDate,
        'consultationTime': consultationTime,
        'paymentStatus': paymentStatus,
        'consultationStatus': consultationStatus,
        if (amountLine != null) 'amountLine': amountLine,
        if (amountPaise != null) 'amountPaise': amountPaise,
        if (currency != null) 'currency': currency,
        if (channelName != null) 'channelName': channelName,
        if (sessionId != null) 'sessionId': sessionId,
        if (agoraEnabled != null) 'agoraEnabled': agoraEnabled,
      };

  static ConsultationProjectionSummary? fromRouteArguments(
    Map<String, dynamic>? args,
  ) {
    if (args == null || args.isEmpty) return null;
    final amountPaiseRaw = args['amountPaise'];
    final amountPaise = amountPaiseRaw is int
        ? amountPaiseRaw
        : (amountPaiseRaw != null
            ? int.tryParse(amountPaiseRaw.toString())
            : null);
    return ConsultationProjectionSummary(
      consultationId: args['consultationId'] as String?,
      merchantTransactionId: args['merchantTransactionId'] as String?,
      meetingStatusLabel: '${args['meetingStatusLabel'] ?? 'Confirmed'}',
      doctorName: '${args['doctorName'] ?? 'Your doctor'}',
      specialization: '${args['specialization'] ?? 'Consultation'}',
      consultationDate: '${args['consultationDate'] ?? '—'}',
      consultationTime: '${args['consultationTime'] ?? '—'}',
      paymentStatus: args['paymentStatus'] as String?,
      consultationStatus: args['consultationStatus'] as String?,
      amountLine: args['amountLine'] as String?,
      amountPaise: amountPaise,
      currency: args['currency'] as String?,
      channelName: args['channelName'] as String?,
      sessionId: args['sessionId'] as String?,
      agoraEnabled: args['agoraEnabled'] as bool?,
    );
  }
}
