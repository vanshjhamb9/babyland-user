// ignore_for_file: public_member_api_docs

/// Canonical RTC credentials from `POST /api/v1/agoras/rtc`.
///
/// Patient: `{ consultationId, role: "patient" }`
/// Doctor:  `{ consultationId, role: "doctor" }`
///
/// The backend is the only source of channelName, uid, token, sessionId, appId,
/// and expiry. Flutter must not invent or hardcode any of these.
class AgoraRtcSessionDto {
  const AgoraRtcSessionDto({
    required this.token,
    required this.channelName,
    required this.uid,
    required this.consultationId,
    required this.sessionId,
    required this.expiresAt,
    this.appId,
  });

  final String token;
  final String channelName;
  final int uid;
  final String consultationId;
  final String sessionId;
  final DateTime? expiresAt;

  /// Agora App ID echoed by backend — required to initialize the RTC engine.
  final String? appId;

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return !exp.isAfter(DateTime.now().toUtc());
  }

  bool get expiresTooSoon =>
      expiresAt != null &&
      !expiresAt!.isAfter(DateTime.now().toUtc().add(const Duration(seconds: 15)));

  static AgoraRtcSessionDto parse(dynamic decoded) {
    if (decoded is! Map) {
      throw FormatException('Agora RTC payload must be a JSON object');
    }
    final root = Map<String, dynamic>.from(decoded);
    final data = root['data'];
    final merged = Map<String, dynamic>.from(root);
    if (data is Map) {
      merged.addAll(Map<String, dynamic>.from(data));
    }

    final rawToken = merged['token'];
    String? tokenStr;
    int? expireInSec;
    if (rawToken is String) {
      tokenStr = rawToken;
    } else if (rawToken is Map) {
      final inner =
          rawToken['token'] ?? rawToken['rtcToken'] ?? rawToken['value'];
      tokenStr = inner?.toString();
      expireInSec = _readInt(rawToken['expireIn'] ?? rawToken['expire_in']);
    }

    expireInSec ??=
        _readInt(merged['expireIn'] ?? merged['expire_in'] ?? merged['expireTime']);

    final channelName =
        merged['channelName']?.toString() ?? merged['channel']?.toString();
    final uidRaw = merged['uid'];
    final consultationId =
        merged['consultationId']?.toString() ??
        merged['consultation_id']?.toString();
    final sessionId =
        merged['sessionId']?.toString() ??
        merged['session_id']?.toString() ??
        consultationId ??
        '';

    if (tokenStr == null ||
        tokenStr.isEmpty ||
        channelName == null ||
        channelName.isEmpty ||
        consultationId == null ||
        consultationId.isEmpty) {
      throw FormatException(
        'RTC response missing token, channelName, or consultationId',
      );
    }

    final uid = switch (uidRaw) {
      int v => v,
      num v => v.toInt(),
      String v when v.isNotEmpty => int.tryParse(v) ?? 0,
      _ => 0,
    };
    if (uid <= 0) {
      throw FormatException('RTC response missing valid numeric uid');
    }

    DateTime? exp;
    final expRaw =
        merged['expiresAt'] ?? merged['expireAt'] ?? merged['expire_at'];
    if (expRaw != null) {
      exp = DateTime.tryParse(expRaw.toString())?.toUtc();
    }
    if (exp == null && expireInSec != null && expireInSec > 0) {
      exp = DateTime.now().toUtc().add(Duration(seconds: expireInSec));
    }

    return AgoraRtcSessionDto(
      token: tokenStr.trim().replaceAll('"', ''),
      channelName: channelName,
      uid: uid,
      consultationId: consultationId,
      sessionId: sessionId,
      expiresAt: exp,
      appId: merged['appId']?.toString(),
    );
  }

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
