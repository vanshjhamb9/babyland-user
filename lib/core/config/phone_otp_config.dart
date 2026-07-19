import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase Phone OTP / Auth Emulator settings (from `assets/.env`).
class PhoneOtpConfig {
  PhoneOtpConfig._();

  /// When set (e.g. `192.168.1.16` on device, `10.0.2.2` on Android emulator),
  /// debug builds use the Firebase Auth Emulator — no Play Integrity / SMS needed.
  static String? get authEmulatorHost {
    final host = dotenv.env['FIREBASE_AUTH_EMULATOR_HOST']?.trim();
    if (host == null || host.isEmpty) return null;
    return host;
  }

  static int get authEmulatorPort {
    return int.tryParse(dotenv.env['FIREBASE_AUTH_EMULATOR_PORT'] ?? '') ?? 9099;
  }
}
