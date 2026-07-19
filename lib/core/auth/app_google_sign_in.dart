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
      serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
    );
    return _instance!;
  }

  static Future<void> signOut() => instance.signOut();
}
