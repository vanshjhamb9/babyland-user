import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register plugins before remote notifications so Firebase Auth/Messaging
    // can receive the APNs device token (required for Phone OTP on TestFlight).
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Keep Firebase Auth / Google Sign-In URL callbacks out of Flutter's router.
  /// FlutterDeepLinkingEnabled=false in Info.plist is required; this is defense
  /// so Auth plugins still receive the URL while Flutter does not navigate.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if isFirebaseAuthCallback(url) {
      // Let FlutterAppDelegate / plugins process Auth; do not treat as Flutter route.
      return super.application(app, open: url, options: options)
    }
    return super.application(app, open: url, options: options)
  }

  private func isFirebaseAuthCallback(_ url: URL) -> Bool {
    let s = url.absoluteString.lowercased()
    return s.contains("deep_link_id=")
      || s.contains("__/auth/")
      || s.contains("recaptchatoken")
      || s.contains("authtype=verifyapp")
      || s.contains("firebaseapp.com")
      || url.path.lowercased().hasPrefix("/link")
  }
}
