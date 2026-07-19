import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/core/auth/app_google_sign_in.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/navigation/root_navigator.dart';
import 'package:flutter/material.dart';

bool _sessionInvalidationInProgress = false;

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
      full.contains('/auth/login')) {
    return true;
  }
  return false;
}

/// Clears session storage and navigates to login (401 / forced logout).
Future<void> performUnauthorizedLogout() async {
  if (_sessionInvalidationInProgress) return;
  _sessionInvalidationInProgress = true;
  try {
    await SecureStorage.clearAll();
    await UserLocalData.clearAllLocalData();
    await UserPreference.saveSavedCommunityPostIds([]);
    await sl.authService.logout();
    try {
      await AppGoogleSignIn.signOut();
    } catch (_) {}
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      Navigator.of(ctx).pushNamedAndRemoveUntil(
        AppRoutes.signInView,
        (route) => false,
      );
    }
  } finally {
    _sessionInvalidationInProgress = false;
  }
}
