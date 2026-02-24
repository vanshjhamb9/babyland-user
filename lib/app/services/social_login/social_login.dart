import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialLoginService {
  SocialLoginService._internal();
  static final SocialLoginService _instance = SocialLoginService._internal();
  factory SocialLoginService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  User? get currentUser => _user;

  Future<User?> signInWithGoogle() async {
    // This ID MUST be the 'Web client ID' from your Google Cloud Console
    final serverClientId = dotenv.env['SERVERClientID'] ?? "";
    pt("Starting Google Sign-In. Server Client ID present: ${serverClientId.isNotEmpty}");
    
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
      );

      // Sign out first to ensure the account picker is shown every time (essential for debugging)
      await googleSignIn.signOut().catchError((_) => null);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        pt("Google Sign-In aborted by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      pt("Google Auth success. ID Token received: ${googleAuth.idToken != null}");

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      pt("Firebase Sign-In successful for: ${_user?.email}");

      if (_user != null && navigatorKey.currentContext != null) {
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          AppRoutes.stagesView,
          (route) => false,
          arguments: {"fromLoginScreen": true},
        );
      }
      return _user;
    } catch (e) {
      pt('Detailed Google Sign-In error: $e');
      
      String errorMsg = "Google Sign-In failed.";
      if (e.toString().contains('ApiException: 10')) {
        errorMsg = "Configuration Error (10): Please verify your SHA-1 and Web Client ID in Firebase.";
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMsg = "Sign-in cancelled.";
      }

      AppPopUp.showToast(message: errorMsg, duration: const Duration(seconds: 5));
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
      _user = null;
    } catch (e) {
      pt('Sign out error: $e');
    }
  }
}
