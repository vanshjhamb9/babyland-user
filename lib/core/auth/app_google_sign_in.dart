import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Single [GoogleSignIn] instance for sign-in and sign-out.
class AppGoogleSignIn {
  AppGoogleSignIn._();

  static GoogleSignIn? _instance;

  static GoogleSignIn get instance {
    if (_instance != null) return _instance!;
    final serverClientId = dotenv.env['SERVERClientID'] ?? '';
    _instance = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
      serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
    );
    return _instance!;
  }

  /// Signs out and disconnects (clears cached credentials).
  static Future<void> signOut() async {
    try {
      await instance.disconnect();
    } catch (e) {
      if (kDebugMode) {
        print('[AppGoogleSignIn] disconnect failed, trying signOut: $e');
      }
      try {
        await instance.signOut();
      } catch (_) {}
    }
  }
}
