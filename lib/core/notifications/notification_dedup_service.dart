import 'package:babyland/app/services/user_preference/user_preference.dart';

/// Persists dedupe keys so foreground / background / tap storms don't amplify refreshes.
class NotificationDedupService {
  NotificationDedupService._();
  static final NotificationDedupService instance = NotificationDedupService._();

  /// Returns true if this key should be processed (first time); false if duplicate.
  Future<bool> tryProcess({required String dedupeKey}) async {
    if (dedupeKey.isEmpty) return true;
    return UserPreference.tryAddNotificationDedupe(dedupeKey);
  }

  /// Extract dedupe key from FCM payload.
  static String dedupeKeyFrom(Map<String, dynamic> data, {String? messageId}) {
    final k = data['dedupeKey'] ??
        data['eventId'] ??
        data['traceId'] ??
        messageId ??
        '';
    return k.toString();
  }
}
