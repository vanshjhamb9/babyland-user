import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Offline caching service powered by Hive.
/// Supports automatic cache expiry and typed data storage.
class CacheService {
  static CacheService? _instance;
  late Box _cacheBox;
  late Box _aiChatBox;
  late Box _dashboardBox;

  CacheService._();

  factory CacheService() {
    _instance ??= CacheService._();
    return _instance!;
  }

  Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox(AppConstants.hiveCacheBox);
    _aiChatBox = await Hive.openBox(AppConstants.hiveAiChatBox);
    _dashboardBox = await Hive.openBox(AppConstants.hiveDashboardBox);
  }

  // ─── Generic Cache ──────────────────────────────────────

  Future<void> put(String key, dynamic value, {Duration? expiry}) async {
    final expiryDuration = expiry ?? AppConstants.cacheExpiry;
    final entry = {
      'data': value is String ? value : jsonEncode(value),
      'expiresAt': DateTime.now().add(expiryDuration).toIso8601String(),
    };
    await _cacheBox.put(key, entry);
  }

  dynamic get(String key) {
    final entry = _cacheBox.get(key);
    if (entry == null) return null;

    final expiresAt = DateTime.parse(entry['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      _cacheBox.delete(key);
      return null;
    }

    final data = entry['data'];
    try {
      return jsonDecode(data);
    } catch (_) {
      return data;
    }
  }

  // ─── AI Chat Cache ──────────────────────────────────────

  Future<void> cacheAiChats(String conversationId, List<Map<String, dynamic>> messages) async {
    await _aiChatBox.put(conversationId, {
      'messages': jsonEncode(messages),
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  List<Map<String, dynamic>>? getCachedAiChats(String conversationId) {
    final entry = _aiChatBox.get(conversationId);
    if (entry == null) return null;

    try {
      final decoded = jsonDecode(entry['messages']);
      return (decoded as List).cast<Map<String, dynamic>>();
    } catch (e) {
      log('Cache decode error: $e', name: 'CacheService');
      return null;
    }
  }

  // ─── Dashboard Cache ────────────────────────────────────

  Future<void> cacheDashboard(String key, Map<String, dynamic> data) async {
    await _dashboardBox.put(key, {
      'data': jsonEncode(data),
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic>? getCachedDashboard(String key) {
    final entry = _dashboardBox.get(key);
    if (entry == null) return null;

    final cachedAt = DateTime.parse(entry['cachedAt']);
    if (DateTime.now().difference(cachedAt) > AppConstants.cacheExpiry) {
      _dashboardBox.delete(key);
      return null;
    }

    try {
      return jsonDecode(entry['data']);
    } catch (_) {
      return null;
    }
  }

  // ─── Clear ──────────────────────────────────────────────

  Future<void> clearAll() async {
    await _cacheBox.clear();
    await _aiChatBox.clear();
    await _dashboardBox.clear();
  }

  Future<void> clearAiCache() async {
    await _aiChatBox.clear();
  }
}
