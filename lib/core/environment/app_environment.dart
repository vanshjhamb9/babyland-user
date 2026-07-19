import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application environment configuration.
enum Environment { development, staging, production }

class AppEnvironment {
  AppEnvironment._();

  static Environment _current = Environment.production;
  static Environment get current => _current;

  static Future<void> init({Environment env = Environment.production}) async {
    _current = env;
    try {
      await dotenv.load(fileName: 'assets/.env');
    } catch (_) {
      // Silently ignore if .env file is not found
    }
  }

  static const String _productionBaseUrl = 'http://164.52.197.176/api/v1';

  static String get baseUrl {
    switch (_current) {
      case Environment.development:
        return dotenv.env['DEV_BASE_URL'] ?? _productionBaseUrl;
      case Environment.staging:
        return dotenv.env['STAGING_BASE_URL'] ?? _productionBaseUrl;
      case Environment.production:
        return dotenv.env['PROD_BASE_URL'] ?? _productionBaseUrl;
    }
  }

  /// Host + `/api` without the `/v1` suffix (e.g. category AI insights).
  static String get apiRoot {
    final url = baseUrl.trim();
    if (url.endsWith('/api/v1')) {
      return url.substring(0, url.length - 3);
    }
    if (url.endsWith('/api/v1/')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }

  /// Agora App ID — must match the App ID the backend signs RTC tokens with.
  ///
  /// Prefer the value echoed by `POST /agoras/rtc` (`appId`). When absent, use
  /// build-time `--dart-define=AGORA_APP_ID` or `assets/.env` `AGORA_APP_ID`.
  /// No hardcoded fallback is permitted in production builds.
  static String? get agoraAppIdFromEnv =>
      dotenv.env['AGORA_APP_ID']?.trim().isNotEmpty == true
          ? dotenv.env['AGORA_APP_ID']!.trim()
          : (const String.fromEnvironment('AGORA_APP_ID').trim().isNotEmpty
              ? const String.fromEnvironment('AGORA_APP_ID').trim()
              : null);

  static bool get isDebug => _current != Environment.production;
}
