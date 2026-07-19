import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../widgets/print.dart';

/// Reads from [FlutterSecureStorage], recovering from corrupted ciphertext
/// (e.g. after reinstall, keystore reset, or debug/release switch).
Future<String?> safeSecureStorageRead(
  FlutterSecureStorage storage,
  String key,
) async {
  try {
    return await storage.read(key: key);
  } on PlatformException catch (e) {
    pt('Secure storage read failed ($key): ${e.message}');
    await _deleteOrIgnore(storage, key);
    return null;
  } catch (e) {
    pt('Secure storage read error ($key): $e');
    await _deleteOrIgnore(storage, key);
    return null;
  }
}

Future<void> _deleteOrIgnore(FlutterSecureStorage storage, String key) async {
  try {
    await storage.delete(key: key);
  } catch (_) {}
}
