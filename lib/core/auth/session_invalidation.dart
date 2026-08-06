import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/core/auth/app_google_sign_in.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/navigation/root_navigator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool _sessionInvalidationInProgress = false;

/// True when the device has an access or refresh token (logged-in / expired session).
Future<bool> hasStoredAuthSession() async {
  final token = await SecureStorage.getToken() ?? '';
  if (token.isNotEmpty) return true;
  final refresh = await SecureStorage.getRefreshToken() ?? '';
  return refresh.isNotEmpty;
}

/// Returns true if this request should not trigger global 401 handling (login/signup).
bool isAuthPublicEndpoint(Uri uri) {
  final path = uri.path.toLowerCase();
  final full = uri.toString().toLowerCase();
  if (path.contains('/auth/login') ||
      path.contains('/auth/signup') ||
      path.contains('/auth/google') ||
      path.contains('/auth/apple') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/request-verification') ||
      path.contains('/auth/verification') ||
      path.contains('/auth/request-forget-password') ||
      path.contains('/auth/verify-otp') ||
      path.contains('/auth/send-otp') ||
      path.contains('/auth/update-phone') ||
      full.contains('/auth/login')) {
    return true;
  }
  return false;
}

/// Clears session storage and navigates to login (401 / forced logout).
///
/// No-ops when there was never a session — otherwise guest flows (signup + Chrome
/// reCAPTCHA) get wiped by resume reconciliation hitting booking APIs with 401.
Future<void> performUnauthorizedLogout() async {
  if (_sessionInvalidationInProgress) {
    if (kDebugMode) {
      pt('[SESSION-AUDIT] performUnauthorizedLogout() SKIPPED — already in progress');
    }
    return;
  }
  if (!await hasStoredAuthSession()) {
    if (kDebugMode) {
      pt('[SESSION-AUDIT] performUnauthorizedLogout() SKIPPED — no stored session');
    }
    return;
  }

  _sessionInvalidationInProgress = true;
  if (kDebugMode) {
    pt('[SESSION-AUDIT] ⚠️ performUnauthorizedLogout() EXECUTING');
    pt('[SESSION-AUDIT] Clearing SecureStorage...');
  }
  try {
    await SecureStorage.clearAll();
    if (kDebugMode) {
      pt('[SESSION-AUDIT] Clearing UserLocalData...');
    }
    await UserLocalData.clearAllLocalData();
    await UserPreference.saveSavedCommunityPostIds([]);
    if (kDebugMode) {
      pt('[SESSION-AUDIT] Clearing AuthService...');
    }
    await sl.authService.logout();
    try {
      await AppGoogleSignIn.signOut();
    } catch (_) {}
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      if (kDebugMode) {
        pt('[SESSION-AUDIT] Navigating to signInView...');
      }
      Navigator.of(ctx).pushNamedAndRemoveUntil(
        AppRoutes.signInView,
        (route) => false,
      );
    } else {
      if (kDebugMode) {
        pt('[SESSION-AUDIT] ⚠️ rootNavigatorKey context is null or not mounted');
      }
    }
  } finally {
    _sessionInvalidationInProgress = false;
    if (kDebugMode) {
      pt('[SESSION-AUDIT] performUnauthorizedLogout() completed');
    }
  }
}
