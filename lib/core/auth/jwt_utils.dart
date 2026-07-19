import 'dart:convert';

/// Decodes JWT payload (client-side only; server must enforce auth).
Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    var payload = parts[1];
    switch (payload.length % 4) {
      case 1:
        payload += '===';
        break;
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    final json = utf8.decode(base64Url.decode(payload));
    return jsonDecode(json) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Backend access tokens often embed `{ "user": { "id": "..." } }`.
String? extractUserIdFromAccessJwt(String token) {
  final map = decodeJwtPayload(token);
  if (map == null) return null;
  final u = map['user'];
  if (u is Map && u['id'] != null) return u['id'].toString();
  final id = map['userId'] ?? map['sub'];
  return id?.toString();
}

/// Client-side JWT expiry check (UX only; server must enforce auth).
bool? isJwtExpired(String token) {
  final map = decodeJwtPayload(token);
  if (map == null) return null;
  final exp = map['exp'];
  if (exp is! num) return null;
  final expiry =
      DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  return DateTime.now().toUtc().isAfter(expiry);
}
