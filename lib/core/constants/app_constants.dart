/// Central application constants for the Babyland platform.
class AppConstants {
  AppConstants._();

  // ─── App Info ───────────────────────────────────────────
  static const String appName = 'Babyland';
  static const String appVersion = '2.0.0';

  // ─── API ────────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration aiApiTimeout = Duration(seconds: 120);
  static const int maxRetryAttempts = 3;
  static const Duration retryBaseDelay = Duration(seconds: 1);

  // ─── AI ─────────────────────────────────────────────────
  /// Display name for the in-app conversational assistant (chat bot).
  static const String aiAssistantDisplayName = 'IRA';

  static const int maxChatHistoryDisplay = 100;
  static const int chatPaginationLimit = 20;
  static const Duration typingAnimationDuration = Duration(milliseconds: 30);
  static const Duration voiceListenTimeout = Duration(seconds: 30);
  static const Duration voicePauseTimeout = Duration(seconds: 3);

  // ─── Cache ──────────────────────────────────────────────
  static const String hiveCacheBox = 'babyland_cache';
  static const String hiveAiChatBox = 'ai_chat_cache';
  static const String hivePregnancyBox = 'pregnancy_cache';
  static const String hiveDashboardBox = 'dashboard_cache';
  static const Duration cacheExpiry = Duration(hours: 1);

  // ─── Notification Channels ──────────────────────────────
  static const String notifChannelGeneral = 'BABYLAND_GENERAL';
  static const String notifChannelAI = 'BABYLAND_AI';
  static const String notifChannelAppointment = 'BABYLAND_APPOINTMENT';
  static const String notifChannelCommunity = 'BABYLAND_COMMUNITY';
  static const String notifChannelVideoCall = 'BABYLAND_VIDEO_CALL';

  // ─── Secure Storage Keys ────────────────────────────────
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keySessionId = 'ai_session_id';
  static const String keyConversationId = 'conversation_id';
  static const String keyTrackerId = 'tracker_id';
  static const String keyFcmToken = 'fcm_token';
}
