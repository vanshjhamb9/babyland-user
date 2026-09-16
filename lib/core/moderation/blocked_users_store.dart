import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/main.dart';
import 'package:flutter/foundation.dart';

/// Local + server blocked-user ids for instant community feed filtering.
class BlockedUsersStore {
  BlockedUsersStore._();

  static Set<String> _memory = {};

  static Set<String> get ids => Set<String>.unmodifiable(_memory);

  static bool isBlocked(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return _memory.contains(userId);
  }

  static Future<void> loadLocal() async {
    final raw = UserPreference.getBlockedUserIds();
    _memory = raw.toSet();
  }

  static Future<void> addLocal(String userId) async {
    if (userId.isEmpty) return;
    _memory.add(userId);
    await UserPreference.saveBlockedUserIds(_memory.toList());
  }

  static Future<void> removeLocal(String userId) async {
    _memory.remove(userId);
    await UserPreference.saveBlockedUserIds(_memory.toList());
  }

  static Future<void> replaceAll(Iterable<String> ids) async {
    _memory = ids.where((e) => e.isNotEmpty).toSet();
    await UserPreference.saveBlockedUserIds(_memory.toList());
  }

  /// Best-effort sync from API; keeps local ids on failure.
  static Future<void> syncFromServer() async {
    try {
      final remote = await repository.getBlockedUserIds();
      if (remote.isNotEmpty) {
        await replaceAll({..._memory, ...remote});
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BLOCKED_USERS] sync failed: $e');
      }
    }
  }
}
