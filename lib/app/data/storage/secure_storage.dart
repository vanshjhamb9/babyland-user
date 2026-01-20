import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../widgets/print.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'token';
  static const String _userIdKey = 'user_id';
  static const String _trackerId = 'tracker_id';
  static const String _conId = 'con_Id';

  static Future<void> saveToken(String token) async {
    if (token.isNotEmpty) {
      pt('Token saved securely: $token');
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    pt('Token fetched: $token');
    return token;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    pt('Token cleared from storage');
  }

  //-------------------------

  static Future<void> saveUserId(String id) async {
    if (id.isNotEmpty) {
      pt('_userIdKey saved securely: $_userIdKey');
    }
    await _storage.write(key: _userIdKey, value: id);
  }

  static Future<String?> getUserId() async {
    final token = await _storage.read(key: _userIdKey);
    pt('_userIdKey fetched: $token');
    return token;
  }

  static Future<void> clearUserId() async {
    await _storage.delete(key: _userIdKey);
    pt('_userIdKey cleared from storage');
  }

  //-------------------------

  static Future<void> saveTrackerId(String id) async {
      pt('_trackerId saved securely: $id');
    await _storage.write(key: _trackerId, value: id);
  }

  static Future<String?> getTrackerId() async {
    final token = await _storage.read(key: _trackerId);
    pt('_trackerId fetched: $token');
    return token;
  }

  static Future<void> clearTrackerId() async {
    await _storage.delete(key: _trackerId);
    pt('_trackerId cleared from storage');
  }
//-------------------------

  static Future<void> saveConversationId(String id) async {
      pt('_conId saved securely: $id');
    await _storage.write(key: _conId, value: id);
  }

  static Future<String?> getConversationId() async {
    final token = await _storage.read(key: _conId);
    pt('_conId fetched: $token');
    return token;
  }

  static Future<void> clearConversationId() async {
    await _storage.delete(key: _conId);
    pt('_conId cleared from storage');
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _trackerId);
    await _storage.delete(key: _conId);

    pt('🔐 token, user_id & tracker_id cleared from storage');
  }

}
