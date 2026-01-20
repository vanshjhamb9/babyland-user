  import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
  import 'package:babyland/app/widgets/print.dart';
  import 'package:babyland/main.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'package:google_sign_in/google_sign_in.dart';

  class SocialLoginService{
    SocialLoginService._internal();
    static final SocialLoginService _instance = SocialLoginService._internal();
    factory SocialLoginService() => _instance;

    final FirebaseAuth _auth = FirebaseAuth.instance;
    // Use the singleton instance (v7+)
    final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

    User? _user;
    User? get currentUser => _user;

    Future<User?> signInWithGoogle() async {
      final serverClientId = dotenv.env['SERVERClientID'] ?? "";
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId:  serverClientId,
        );

        // Interactive sign-in. scopeHint is a list of scope strings (e.g. 'email', 'profile')
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);

        // if (googleUser == null) return null; // user cancelled

        // Get authentication tokens (note: in v7 GoogleSignInAuthentication currently has idToken only)
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // Create Firebase credential using idToken (accessToken may be null in v7)
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          // accessToken: googleAuth.accessToken, // often null in v7
        );
        final UserCredential userCredential = await _auth.signInWithCredential(credential);

        _user = userCredential.user;
        pt("user ----------- $_user");
        if(_user != null){
          Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.stagesView);
        }
        return _user;
      } catch (e) {
        pt('Google sign-in error: $e');
        AppPopUp.showToast(
          message: e.toString().contains('GoogleSignInExceptionCode.canceled')
              ? "Google sign-in Failed."
              : e.toString(),
          duration: const Duration(seconds: 5),
        );
        rethrow;
      }
    }

    Future<void> signOut() async {
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
        _user = null;
      } catch (e) {
        pt('Sign out error: $e');
      }
    }
  }
