import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/common_profile_header/get_user_model.dart';
import 'package:babyland/app/data/network/end_points.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/main.dart';
import 'package:babyland/core/auth/app_google_sign_in.dart';
import 'package:babyland/core/auth/jwt_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/debug/release_logger.dart';

/// Social login: obtain provider tokens, exchange for **backend JWT** via API.
/// [AuthService] + stored JWT are the source of truth.
class SocialLoginService {
  SocialLoginService._internal();
  static final SocialLoginService _instance = SocialLoginService._internal();
  factory SocialLoginService() => _instance;

  final Repository _repo = Repository();

  /// Google: get `idToken` → backend → returns JWT + user payload in [CommonResponseModel.data].
  Future<CommonResponseModel?> signInWithGoogle() async {
    await ReleaseLogger.log('GOOGLE-FILE', '>>> signInWithGoogle called');
    print('Starting Google Sign-In');

    try {
      final googleSignIn = AppGoogleSignIn.instance;

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (authError) {
        print('Google Sign-In failed: $authError.');
        AppPopUp.showToast(
          message:
              'Google Sign-In was canceled or no account exists on device.',
        );
        return null;
      }

      if (googleUser == null) {
        print('Google Sign In was cancelled by the user.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('Google Auth success. ID Token received: ${googleAuth.idToken != null}');

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        print('Google Sign-In: idToken is null or empty');
        AppPopUp.showToast(
          message: 'Google Sign-In failed to obtain credentials. Please try again.',
        );
        return null;
      }

      final serverClientId = dotenv.env['SERVERClientID'] ?? '';
      print('=== GOOGLE SIGN-IN DEBUG START ===');
      print('idToken length: ${googleAuth.idToken?.length}');
      print('idToken first50chars: ${googleAuth.idToken?.substring(0, googleAuth.idToken!.length > 50 ? 50 : googleAuth.idToken!.length)}');
      print('serverClientId from .env: "$serverClientId"');
      print('serverClientId isEmpty: ${serverClientId.isEmpty}');
      final payload = decodeJwtPayload(googleAuth.idToken!);
      print('JWT aud: ${payload?['aud']}');
      print('JWT iss: ${payload?['iss']}');
      print('JWT sub: ${payload?['sub']}');
      print('JWT email: ${payload?['email']}');
      print('Backend URL: ${EndPoints.googleLogin}');
      print('=== GOOGLE SIGN-IN DEBUG END ===');

      final response = await _repo.googleLogin({
        'idToken': googleAuth.idToken,
        'serverClientId': serverClientId,
      });

      await ReleaseLogger.log('GOOGLE-FILE', '=== BACKEND RESPONSE START ===');
      await ReleaseLogger.log('GOOGLE-FILE', 'success: ${response.success}');
      await ReleaseLogger.log('GOOGLE-FILE', 'message: ${response.message}');
      await ReleaseLogger.log('GOOGLE-FILE', 'token: ${response.token != null ? "present (${response.token!.length} chars)" : "NULL"}');
      await ReleaseLogger.log('GOOGLE-FILE', 'refreshToken: ${response.refreshToken != null ? "present (${response.refreshToken!.length} chars)" : "NULL"}');
      await ReleaseLogger.log('GOOGLE-FILE', 'data type: ${response.data.runtimeType}');
      await ReleaseLogger.log('GOOGLE-FILE', 'data: ${response.data}');
      await ReleaseLogger.log('GOOGLE-FILE', '=== BACKEND RESPONSE END ===');

      if (response.success == true) {
        await ReleaseLogger.log('GOOGLE-FILE', 'success=true, calling _persistSessionAndNavigate');
        await _persistSessionAndNavigate(response);
        return response;
      }

      await ReleaseLogger.log('GOOGLE-FILE', 'success=false, checking requirePhone and phone validation...');

      // Handle requirePhone: backend says user exists but needs phone verification
      final responseData = response.data;
      await ReleaseLogger.log('GOOGLE-FILE', 'responseData type: ${responseData.runtimeType}');
      await ReleaseLogger.log('GOOGLE-FILE', 'responseData is Map: ${responseData is Map}');
      if (responseData is Map) {
        await ReleaseLogger.log('GOOGLE-FILE', 'responseData requirePhone: ${responseData['requirePhone']}');
      }

      if (_requiresPhone(response)) {
        await ReleaseLogger.log(
          'GOOGLE-FILE',
          'requirePhone=true. Token present=${response.token != null && response.token!.isNotEmpty}',
        );
        await SecureStorage.saveGoogleIdToken(googleAuth.idToken!);
        final routedExisting = await _tryRouteExistingGoogleUser(response);
        if (routedExisting) {
          return response;
        }
        if (navigatorKey.currentContext != null) {
          Navigator.pushReplacementNamed(
            navigatorKey.currentContext!,
            AppRoutes.addPhoneView,
          );
        }
        return response;
      }

      // Backend may return Mongoose validation error instead of requirePhone
      // when the user record exists but phone is missing.
      // e.g. "User validation failed: phone: Path 'phone' is required."
      final msg = (response.message ?? '').toLowerCase();
      await ReleaseLogger.log('GOOGLE-FILE', 'msg (lowercase): "$msg"');
      await ReleaseLogger.log('GOOGLE-FILE', 'contains validation failed: ${msg.contains('validation failed')}');
      await ReleaseLogger.log('GOOGLE-FILE', 'contains phone: ${msg.contains('phone')}');

      if (msg.contains('validation failed') && msg.contains('phone')) {
        await ReleaseLogger.log('GOOGLE-FILE', 'Phone validation error detected!');

        // Check if the response data already contains a user with a phone
        // (backend may return the existing user alongside the validation error
        //  when the user already completed signup previously).
        if (responseData is Map && responseData['user'] is Map) {
          final userMap = Map<String, dynamic>.from(responseData['user'] as Map);
          final existingPhone = userMap['phone']?.toString();
          await ReleaseLogger.log('GOOGLE-FILE', 'Existing user in error response: phone=$existingPhone');

          if (existingPhone != null && existingPhone.isNotEmpty) {
            // User already has a phone — this is a returning user.
            // The backend validation error is transient; persist the session
            // using the user data we received.
            await ReleaseLogger.log('GOOGLE-FILE', 'Returning user with phone found in error response. Persisting session...');
            await _persistSessionAndNavigate(response);
            return response;
          }
        }

        // New user (no existing phone) — redirect to AddPhoneView
        await ReleaseLogger.log('GOOGLE-FILE', 'No existing user/phone found. Navigating to AddPhoneView...');
        await SecureStorage.saveGoogleIdToken(googleAuth.idToken!);
        if (navigatorKey.currentContext != null) {
          await ReleaseLogger.log('GOOGLE-FILE', 'Navigator context available, pushing AddPhoneView');
          Navigator.pushReplacementNamed(
            navigatorKey.currentContext!,
            AppRoutes.addPhoneView,
          );
        } else {
          await ReleaseLogger.log('GOOGLE-FILE', 'Navigator context is NULL! Cannot navigate');
        }
        return response;
      }

      await ReleaseLogger.log('GOOGLE-FILE', 'No matching error handler. Showing toast: ${response.message}');
      AppPopUp.showToast(
        message: response.message ?? 'Google login failed on backend.',
      );
      return response;
    } catch (e) {
      await ReleaseLogger.log('GOOGLE-FILE', 'EXCEPTION: $e');
      print('Detailed Google Sign-In error: $e');

      String errorMsg = 'Google Sign-In failed.';
      final errorStr = e.toString();
      if (errorStr.contains('ApiException: 10') ||
          errorStr.contains('DEVELOPER_ERROR')) {
        errorMsg =
            'Configuration error. Please ensure:\n'
            '1. SHA-1 & SHA-256 are added in Firebase Console\n'
            '2. Web Client ID matches your Firebase project\n'
            '3. Google Sign-In is enabled in Firebase Console';
      } else if (errorStr.contains('sign_in_canceled') ||
          errorStr.contains('cancelled')) {
        errorMsg = 'Sign-in cancelled.';
      } else if (errorStr.contains('network_error') ||
          errorStr.contains('SocketException')) {
        errorMsg = 'Network error. Check your connection and try again.';
      } else if (errorStr.contains('sign_in_failed')) {
        errorMsg = 'Sign-in failed. Please check your Google account and try again.';
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

  bool _requiresPhone(CommonResponseModel response) {
    final data = response.data;
    if (data is Map && data['requirePhone'] == true) return true;
    final msg = (response.message ?? '').toLowerCase();
    return msg.contains('phone number required') || msg.contains('requirephone');
  }

  Future<void> _saveAuthTokens(String token, String? refreshToken) async {
    await SecureStorage.saveToken(token);
    await sl.authService.saveToken(token);
    final uid = extractUserIdFromAccessJwt(token);
    if (uid != null && uid.isNotEmpty) {
      await SecureStorage.saveUserId(uid);
      await sl.authService.saveUserId(uid);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(refreshToken);
      await sl.authService.saveRefreshToken(refreshToken);
    }
  }

  /// If Google returned a JWT for an account that already has a phone (and
  /// possibly a completed stage), skip Add Phone and reuse existing data.
  Future<bool> _tryRouteExistingGoogleUser(CommonResponseModel response) async {
    final token = response.token ?? '';
    if (token.isEmpty) return false;
    await _saveAuthTokens(token, response.refreshToken);
    try {
      final existing = await _repo.getUser();
      final phone = existing.user?.user?.phone?.trim();
      if (existing.success == true && phone != null && phone.isNotEmpty) {
        print(
          '[GOOGLE-AUDIT] requirePhone but getUser already has phone=$phone — routing existing account',
        );
        await _routeFromValidatedUser(existing);
        return true;
      }
    } catch (e) {
      print('[GOOGLE-AUDIT] requirePhone getUser failed: $e');
    }
    return false;
  }

  /// After tokens are already saved (OTP / social), fetch getUser and route
  /// returning users to splash/dashboard instead of repeating onboarding.
  Future<void> routeAfterAuthSession() async {
    GetUserModel? validatedUser;
    try {
      validatedUser = await _repo.getUser();
      print(
        '[AUTH-ROUTE] getUser success=${validatedUser.success} '
        'stage=${validatedUser.user?.user?.stage} '
        'completion=${validatedUser.user?.profileCompletion} '
        'phone=${validatedUser.user?.user?.phone}',
      );
      if (validatedUser.success != true) {
        print('[AUTH-ROUTE] getUser failed — falling through to basic profile');
      }
    } catch (e) {
      print('[AUTH-ROUTE] getUser exception: $e');
    }
    await _routeFromValidatedUser(validatedUser);
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
    await ReleaseLogger.log('GOOGLE-FILE', '_persistSessionAndNavigate called');
    await ReleaseLogger.log('GOOGLE-FILE', 'Token empty: ${token.isEmpty}');
    await ReleaseLogger.log('GOOGLE-FILE', 'Response data type: ${response.data.runtimeType}');
    print('[GOOGLE-AUDIT] _persistSessionAndNavigate called');
    print('[GOOGLE-AUDIT] Token empty: ${token.isEmpty}');
    print('[GOOGLE-AUDIT] Response data type: ${response.data.runtimeType}');
    print('[GOOGLE-AUDIT] Response data: ${response.data}');

    if (token.isEmpty) {
      print('[GOOGLE-AUDIT] ⚠️ Token is EMPTY — showing error toast');
      AppPopUp.showToast(message: 'No auth token received. Please try again.');
      return;
    }

    // 1. Persist tokens to both storage backends.
    await SecureStorage.saveToken(token);
    if (refreshToken.isNotEmpty) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await sl.authService.saveToken(token);
    if (refreshToken.isNotEmpty) {
      await sl.authService.saveRefreshToken(refreshToken);
    }
    print('[GOOGLE-AUDIT] ✅ Tokens saved to SecureStorage + AuthService');

    // Verify tokens were actually saved
    final verifySecure = await SecureStorage.getToken();
    final verifyAuth = await sl.authService.getToken();
    print('[GOOGLE-AUDIT] Verify SecureStorage token: ${verifySecure != null && verifySecure.isNotEmpty ? "present (${verifySecure.length} chars)" : "NULL/EMPTY"}');
    print('[GOOGLE-AUDIT] Verify AuthService token: ${verifyAuth != null && verifyAuth.isNotEmpty ? "present (${verifyAuth.length} chars)" : "NULL/EMPTY"}');
    print('[GOOGLE-AUDIT] Tokens match: ${verifySecure == verifyAuth}');

    // 2. Validate the token by calling getUser(). If the backend rejects it
    //    (e.g. token format mismatch, account issue), redirect to login
    //    instead of proceeding with a broken session.
    print('[GOOGLE-AUDIT] Validating token via getUser()...');
    GetUserModel? validatedUser;
    try {
      final validateResponse = await _repo.getUser();
      validatedUser = validateResponse;
      print('[GOOGLE-AUDIT] Token validation result: success=${validateResponse.success}, message=${validateResponse.message}');
      print('[GOOGLE-AUDIT] User from validation: ${validateResponse.user?.user?.sId}');
      if (validateResponse.success != true) {
        if (kDebugMode) {
          pt('[GOOGLE-AUDIT] ⚠️ Token validation FAILED: ${validateResponse.message}');
        }
        // Clear the invalid session
        await SecureStorage.clearAll();
        await sl.authService.logout();
        AppPopUp.showToast(
          message: 'Session creation failed. Please try signing in again.',
          duration: const Duration(seconds: 4),
        );
        if (navigatorKey.currentContext != null) {
          print('[GOOGLE-AUDIT] → signInView (token validation failed)');
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            AppRoutes.signInView,
            (route) => false,
          );
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        pt('Token validation exception after social login: $e');
      }
      // Network error or similar — proceed optimistically; splash will
      // handle any stale-token scenario on next cold start.
    }

    // 3. Extract user data from the original response (not the validate call).
    if (response.data != null && response.data is Map) {
      final dataMap = Map<String, dynamic>.from(response.data as Map);
      final user = dataMap['user'];
      print('[GOOGLE-AUDIT] User from response: $user');
      final email = _emailFromUser(user);
      print('[GOOGLE-AUDIT] Email: $email');
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

    await _routeFromValidatedUser(validatedUser);
  }

  Future<void> _routeFromValidatedUser(GetUserModel? validatedUser) async {
    final userData = validatedUser?.user?.user;
    final phone = userData?.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final backendStage = userData?.stage;
    final hasCompletedOnboarding = ExistingAccount.isReturning(
      userData,
      profileCompletion: validatedUser?.user?.profileCompletion,
    );

    if (!hasPhone) {
      await UserLocalData.setNeedsPhoneProfile(true);
    } else {
      await UserLocalData.clearNeedsPhoneProfile();
    }

    print(
      '[AUTH-ROUTE] hasPhone=$hasPhone hasCompletedOnboarding=$hasCompletedOnboarding '
      'stage=$backendStage completion=${validatedUser?.user?.profileCompletion}',
    );

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    if (!hasPhone) {
      await UserLocalData.setNeedsBasicProfile(true);
      print('[AUTH-ROUTE] → addPhoneView (no phone)');
      Navigator.pushReplacementNamed(ctx, AppRoutes.addPhoneView);
      return;
    }

    if (hasCompletedOnboarding) {
      await UserLocalData.setNeedsBasicProfile(false);
      print('[AUTH-ROUTE] → splashView (existing account, stage=$backendStage)');
      Navigator.pushNamedAndRemoveUntil(
        ctx,
        AppRoutes.splashView,
        (route) => false,
      );
      return;
    }

    await UserLocalData.setNeedsBasicProfile(true);
    print('[AUTH-ROUTE] → basicProfileView (new / incomplete profile)');
    Navigator.pushNamedAndRemoveUntil(
      ctx,
      AppRoutes.basicProfileView,
      (route) => false,
    );
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
