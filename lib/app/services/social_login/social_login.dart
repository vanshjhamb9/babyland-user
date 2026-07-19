import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/main.dart';
import 'package:babyland/core/auth/app_google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/core/di/service_locator.dart';

/// Social login: obtain provider tokens, exchange for **backend JWT** via API.
/// [AuthService] + stored JWT are the source of truth.
class SocialLoginService {
  SocialLoginService._internal();
  static final SocialLoginService _instance = SocialLoginService._internal();
  factory SocialLoginService() => _instance;

  final Repository _repo = Repository();

  /// Google: get `idToken` → backend → returns JWT + user payload in [CommonResponseModel.data].
  Future<CommonResponseModel?> signInWithGoogle() async {
    if (kDebugMode) {
      pt('Starting Google Sign-In');
    }

    try {
      final googleSignIn = AppGoogleSignIn.instance;

      await googleSignIn.signOut().catchError((_) => null);

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (authError) {
        if (kDebugMode) {
          pt('Google Sign-In failed: $authError.');
        }
        AppPopUp.showToast(
          message:
              'Google Sign-In was canceled or no account exists on device.',
        );
        return null;
      }

      if (googleUser == null) {
        if (kDebugMode) {
          pt('Google Sign In was cancelled by the user.');
        }
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (kDebugMode) {
        pt(
          'Google Auth success. ID Token received: ${googleAuth.idToken != null}',
        );
      }

      final response = await _repo.googleLogin({
        'idToken': googleAuth.idToken,
      });

      if (kDebugMode) {
        debugPrint('User logged in');
      }

      if (kDebugMode) {
        pt('Backend Google response: ${response.message}');
      }

      if (response.success == true) {
        await _persistSessionAndNavigate(response);
        return response;
      }

      AppPopUp.showToast(
        message: response.message ?? 'Google login failed on backend.',
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        pt('Detailed Google Sign-In error: $e');
      }

      String errorMsg = 'Google Sign-In failed.';
      if (e.toString().contains('ApiException: 10')) {
        errorMsg =
            'Configuration Error (10): Please verify your SHA-1 and Web Client ID in Firebase.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMsg = 'Sign-in cancelled.';
      }

      AppPopUp.showToast(
        message: errorMsg,
        duration: const Duration(seconds: 5),
      );
      return null;
    }
  }

  /// Apple: get identity token → backend → JWT + user in response.
  Future<CommonResponseModel?> signInWithApple() async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        AppPopUp.showToast(
          message: 'Apple Sign-In is not available on this device.',
        );
        return null;
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await _repo.appleLogin({
        'identityToken': appleCredential.identityToken,
      });

      if (kDebugMode) {
        debugPrint('User logged in');
      }

      if (kDebugMode) {
        pt('Backend Apple response: ${response.message}');
      }

      if (response.success == true) {
        await _persistSessionAndNavigate(response);
        return response;
      }

      AppPopUp.showToast(
        message: response.message ?? 'Apple login failed on backend.',
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        pt('Apple Sign-In error: $e');
      }
      AppPopUp.showToast(
        message: 'Apple Sign-In failed. Please try again.',
        duration: const Duration(seconds: 4),
      );
      return null;
    }
  }

  String? _emailFromUser(dynamic user) {
    if (user is! Map) return null;
    final m = Map<String, dynamic>.from(user);
    final e = m['email'];
    if (e == null) return null;
    final s = e.toString().trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _persistSessionAndNavigate(CommonResponseModel response) async {
    final token = response.token ?? '';
    final refreshToken = response.refreshToken ?? '';
    if (token.isNotEmpty) {
      await SecureStorage.saveToken(token);
      if (refreshToken.isNotEmpty) {
        await SecureStorage.saveRefreshToken(refreshToken);
      }
      await sl.authService.saveToken(token);
      if (refreshToken.isNotEmpty) {
        await sl.authService.saveRefreshToken(refreshToken);
      }
    }

    if (response.data != null && response.data is Map) {
      final dataMap = Map<String, dynamic>.from(response.data as Map);
      final user = dataMap['user'];
      final email = _emailFromUser(user);
      if (email == null || email.isEmpty) {
        await UserLocalData.setNeedsPhoneProfile(true);
        if (navigatorKey.currentContext != null) {
          Navigator.pushReplacementNamed(
            navigatorKey.currentContext!,
            AppRoutes.addAppleEmailView,
          );
        }
        return;
      }
    }

    bool hasPhone = true;
    if (response.data != null && response.data is Map) {
      final Map<String, dynamic> dataMap =
          Map<String, dynamic>.from(response.data as Map);
      if (dataMap.containsKey('user') && dataMap['user'] != null) {
        final userPhone = dataMap['user']['phone'];
        if (userPhone == null || userPhone.toString().isEmpty) {
          hasPhone = false;
        }
      }
    }

    await UserLocalData.setNeedsPhoneProfile(true);

    if (navigatorKey.currentContext != null) {
      if (!hasPhone) {
        Navigator.pushReplacementNamed(
          navigatorKey.currentContext!,
          AppRoutes.addPhoneView,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          AppRoutes.stagesView,
          (route) => false,
          arguments: {'fromLoginScreen': true},
        );
      }
    }
  }

  /// Clears Google session on device. Apple has no client sign-out API.
  Future<void> signOut() async {
    try {
      await AppGoogleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        pt('Social sign out error: $e');
      }
    }
  }
}
