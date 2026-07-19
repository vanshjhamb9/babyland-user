import 'package:hive_flutter/adapters.dart';

class UserPreference {
  UserPreference._();

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox("userBox");
  }

  static Future<void> saveIsFirstTime(bool isFirstTime) async =>
      _box.put("isFirstTime", isFirstTime);
  static bool? getIsFirstTime() => _box.get("isFirstTime");

  /// Community post IDs saved locally (backend has no saved-posts endpoint yet).
  static Future<void> saveSavedCommunityPostIds(List<String> ids) async {
    await _box.put('savedCommunityPostIds', ids);
  }

  static List<String> getSavedCommunityPostIds() {
    final raw = _box.get('savedCommunityPostIds');
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Post-pregnancy mental health logs are charted locally because the legacy
  /// codebase doesn't expose a "GET logs" endpoint for postpartum mood.
  static const String _postMentalHealthLogsKey = 'postMentalHealthLogs';

  static Future<void> savePostMentalHealthLog({
    required DateTime date,
    required int score,
    required String mood,
  }) async {
    final iso = date.toIso8601String();
    final entry = <String, dynamic>{'date': iso, 'score': score, 'mood': mood};

    final existingRaw = _box.get(_postMentalHealthLogsKey);
    final existing = existingRaw is List ? existingRaw : <dynamic>[];

    // Upsert by date (guarantee only one entry per day).
    final withoutThisDay = existing.where((e) {
      if (e is Map) return e['date']?.toString() != iso;
      return true;
    }).toList();

    withoutThisDay.add(entry);

    await _box.put(_postMentalHealthLogsKey, withoutThisDay);
  }

  static List<Map<String, dynamic>> getPostMentalHealthLogs() {
    final raw = _box.get(_postMentalHealthLogsKey);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return [];
  }

  static const String _pendingConsultationPaymentKey =
      'pendingConsultationPayment';

  static Future<void> savePendingConsultationPayment(
    Map<String, dynamic> data,
  ) async {
    await _box.put(_pendingConsultationPaymentKey, data);
  }

  static Map<String, dynamic>? getPendingConsultationPayment() {
    final raw = _box.get(_pendingConsultationPaymentKey);
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static Future<void> clearPendingConsultationPayment() async {
    await _box.delete(_pendingConsultationPaymentKey);
  }

  static const String _pendingSubscriptionPaymentKey =
      'pendingSubscriptionPayment';

  /// Persisted pending PhonePe subscription payment (merchant id + timestamps only).
  static Future<void> savePendingSubscriptionPayment(
    Map<String, dynamic> data,
  ) async {
    await _box.put(_pendingSubscriptionPaymentKey, data);
  }

  static Map<String, dynamic>? getPendingSubscriptionPayment() {
    final raw = _box.get(_pendingSubscriptionPaymentKey);
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static Future<void> clearPendingSubscriptionPayment() async {
    await _box.delete(_pendingSubscriptionPaymentKey);
  }

  // ─── Phase 9: notification dedupe + silent refresh + deep links ───

  static const String _notificationDedupeKeys = 'notificationDedupeKeys';
  static const String _pendingSilentFcmRefresh = 'pendingSilentFcmRefresh';
  static const String _deepLinkHistory = 'deepLinkHistory';
  static const String _lifecycleTransitions = 'lifecycleTransitionsDebug';

  /// Returns true if this key is new (caller should process); false if duplicate.
  static Future<bool> tryAddNotificationDedupe(String key) async {
    if (key.isEmpty) return true;
    final list = getNotificationDedupeKeys();
    if (list.contains(key)) return false;
    final next = [...list, key];
    while (next.length > 80) {
      next.removeAt(0);
    }
    await _box.put(_notificationDedupeKeys, next);
    return true;
  }

  static List<String> getNotificationDedupeKeys() {
    final raw = _box.get(_notificationDedupeKeys);
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  static Future<void> setPendingSilentRefresh(bool value) async {
    await _box.put(_pendingSilentFcmRefresh, value);
  }

  static bool getPendingSilentRefresh() {
    return _box.get(_pendingSilentFcmRefresh) == true;
  }

  static Future<void> appendDeepLinkHistory(String line) async {
    final raw = _box.get(_deepLinkHistory);
    final list = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    list.add(line);
    while (list.length > 20) {
      list.removeAt(0);
    }
    await _box.put(_deepLinkHistory, list);
  }

  static List<String> getDeepLinkHistory() {
    final raw = _box.get(_deepLinkHistory);
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Debug-only ring buffer for Phase 9 diagnostics (resume/pause/focus).
  static Future<void> appendLifecycleTransition(String line) async {
    final raw = _box.get(_lifecycleTransitions);
    final list = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    list.add(line);
    while (list.length > 40) {
      list.removeAt(0);
    }
    await _box.put(_lifecycleTransitions, list);
  }

  static List<String> getLifecycleTransitions() {
    final raw = _box.get(_lifecycleTransitions);
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }
}
