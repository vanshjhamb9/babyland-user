package com.thebabyland

import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * Phone Auth reCAPTCHA needs [FlutterFragmentActivity] (Custom Tabs / activity results).
 *
 * Flutter's default deep linking (on since 3.27) turns Firebase Auth's
 * `/link?deep_link_id=…` return into a Navigator route ("No route defined for /link…")
 * and can prevent OTP from completing. Manifest `flutter_deeplinking_enabled=false`
 * alone is unreliable (flutter/flutter#177072) — disable engine deep linking here.
 *
 * Intent data is preserved so the Firebase Auth SDK can still consume the callback.
 */
class MainActivity : FlutterFragmentActivity() {
  override fun shouldHandleDeeplinking(): Boolean = false

  override fun getInitialRoute(): String? {
    val data = intent?.dataString
    if (data != null && isFirebaseAuthCallback(data)) {
      Log.i(TAG, "Firebase Auth callback present — not using it as Flutter initial route")
      // null + shouldHandleDeeplinking=false → Flutter uses default route (splash).
      return null
    }
    return super.getInitialRoute()
  }

  override fun onNewIntent(intent: Intent) {
    // Keep Intent for Firebase Auth / Play Integrity. Do not let Flutter navigate.
    setIntent(intent)
    val data = intent.dataString
    if (data != null && isFirebaseAuthCallback(data)) {
      Log.i(TAG, "Firebase Auth callback onNewIntent — blocked Flutter route push")
      return
    }
    super.onNewIntent(intent)
  }

  private fun isFirebaseAuthCallback(data: String): Boolean {
    val lower = data.lowercase()
    if (lower.contains("deep_link_id=") ||
      lower.contains("__/auth/") ||
      lower.contains("recaptchatoken") ||
      lower.contains("authtype=verifyapp") ||
      lower.contains("firebaseapp.com")
    ) {
      return true
    }
    return try {
      val uri = Uri.parse(data)
      val path = uri.path.orEmpty().lowercase()
      path == "/link" ||
        path.startsWith("/link") ||
        path.contains("__/auth") ||
        uri.getQueryParameter("deep_link_id") != null
    } catch (_: Exception) {
      false
    }
  }

  companion object {
    private const val TAG = "BabylandMainActivity"
  }
}
