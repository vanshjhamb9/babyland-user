import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:babyland/app/data/storage/secure_storage_read.dart';
import '../../widgets/print.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _trackerId = 'tracker_id';
  static const String _conId = 'con_Id';
  static const String _googleIdTokenKey = 'google_id_token';

  static Future<void> saveToken(String token) async {
    if (kDebugMode && token.isNotEmpty) {
      pt('Token saved securely (redacted)');
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    final token = await safeSecureStorageRead(_storage, _tokenKey);
    if (kDebugMode) {
      pt('Token fetched: ${token != null && token.isNotEmpty ? '(present)' : '(none)'}');
    }
    return token;
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    if (kDebugMode && refreshToken.isNotEmpty) {
      pt('Refresh token saved securely (redacted)');
    }
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    final refreshToken = await safeSecureStorageRead(_storage, _refreshTokenKey);
    if (kDebugMode) {
      pt('Refresh token fetched: ${refreshToken != null && refreshToken.isNotEmpty ? '(present)' : '(none)'}');
    }
    return refreshToken;
  }

  static Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
    if (kDebugMode) {
      pt('Refresh token cleared from storage');
    }
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    if (kDebugMode) {
      pt('Token cleared from storage');
    }
  }

  //-------------------------

  static Future<void> saveUserId(String id) async {
    if (kDebugMode && id.isNotEmpty) {
      pt('user id saved securely');
    }
    await _storage.write(key: _userIdKey, value: id);
  }

  static Future<String?> getUserId() async {
    final id = await safeSecureStorageRead(_storage, _userIdKey);
    if (kDebugMode) {
      pt('user id fetched: ${id != null && id.isNotEmpty ? '(present)' : '(none)'}');
    }
    return id;
  }

  static Future<void> clearUserId() async {
    await _storage.delete(key: _userIdKey);
    if (kDebugMode) {
      pt('user id cleared from storage');
    }
  }

  //-------------------------

  static Future<void> saveTrackerId(String id) async {
    if (kDebugMode) {
      pt('tracker id saved');
    }
    await _storage.write(key: _trackerId, value: id);
  }

  static Future<String?> getTrackerId() async {
    final v = await safeSecureStorageRead(_storage, _trackerId);
    if (kDebugMode) {
      pt('tracker id fetched: ${v != null ? '(present)' : '(none)'}');
    }
    return v;
  }

  static Future<void> clearTrackerId() async {
    await _storage.delete(key: _trackerId);
    if (kDebugMode) {
      pt('tracker id cleared');
    }
  }
//-------------------------

  static Future<void> saveConversationId(String id) async {
    if (kDebugMode) {
      pt('conversation id saved');
    }
    await _storage.write(key: _conId, value: id);
  }

  static Future<String?> getConversationId() async {
    final v = await safeSecureStorageRead(_storage, _conId);
    if (kDebugMode) {
      pt('conversation id fetched: ${v != null ? '(present)' : '(none)'}');
    }
    return v;
  }

  static Future<void> clearConversationId() async {
    await _storage.delete(key: _conId);
    if (kDebugMode) {
      pt('conversation id cleared from storage');
    }
  }

  static Future<void> saveGoogleIdToken(String token) async {
    if (kDebugMode) {
      pt('Google idToken saved (redacted)');
    }
    await _storage.write(key: _googleIdTokenKey, value: token);
  }

  static Future<String?> getGoogleIdToken() async {
    final token = await safeSecureStorageRead(_storage, _googleIdTokenKey);
    if (kDebugMode) {
      pt('Google idToken fetched: ${token != null && token.isNotEmpty ? '(present)' : '(none)'}');
    }
    return token;
  }

  static Future<void> clearGoogleIdToken() async {
    await _storage.delete(key: _googleIdTokenKey);
    if (kDebugMode) {
      pt('Google idToken cleared from storage');
    }
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _trackerId);
    await _storage.delete(key: _conId);
    await _storage.delete(key: _googleIdTokenKey);

    if (kDebugMode) {
      pt('🔐 secure storage cleared');
    }
  }

}
