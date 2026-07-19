import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../core/services/analytics_service.dart';
import '../../../features/ai_assistant/models/ai_message_model.dart';
import '../models/saved_insight_model.dart';
import '../repositories/conversation_memory_repository.dart';

/// Controller for AI Conversation Memory / History.
class ConversationMemoryController extends ChangeNotifier {
  final ConversationMemoryRepository _repository;
  final AnalyticsService _analytics;

  // ─── State ────────────────────────────────────────────────
  List<AiMessageModel> _history = [];
  List<AiMessageModel> get history => _history;

  List<SavedInsightModel> _bookmarks = [];
  List<SavedInsightModel> get bookmarks => _bookmarks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  ConversationMemoryController({
    required ConversationMemoryRepository repository,
    required AnalyticsService analytics,
  })  : _repository = repository,
        _analytics = analytics;

  void setTab(int tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  // ─── Load History ──────────────────────────────────────
  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _repository.getConversationHistory();
      _analytics.logScreenView('conversation_memory');
    } catch (e) {
      log('Error loading history: $e', name: 'ConvMemoryCtrl');
      _error = 'Failed to load conversation history';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Bookmarks ─────────────────────────────────────────
  Future<void> loadBookmarks() async {
    try {
      _bookmarks = await _repository.getBookmarks();
      notifyListeners();
    } catch (e) {
      log('Error loading bookmarks: $e', name: 'ConvMemoryCtrl');
    }
  }

  Future<void> bookmarkMessage(AiMessageModel message) async {
    final bookmark = SavedInsightModel(
      id: message.id,
      content: message.content,
      traceId: message.traceId,
      savedAt: DateTime.now(),
      category: _categorizeMessage(message.content),
    );

    await _repository.saveBookmark(bookmark);
    _bookmarks.insert(0, bookmark);
    notifyListeners();

    _analytics.logFeatureUsed('ai_message_bookmarked');
  }

  Future<void> removeBookmark(String id) async {
    await _repository.removeBookmark(id);
    _bookmarks.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  bool isBookmarked(String id) {
    return _repository.isBookmarked(id);
  }

  String _categorizeMessage(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('nutrition') || lower.contains('diet') || lower.contains('food')) {
      return 'nutrition';
    }
    if (lower.contains('exercise') || lower.contains('yoga') || lower.contains('walk')) {
      return 'exercise';
    }
    if (lower.contains('doctor') || lower.contains('medical') || lower.contains('checkup')) {
      return 'medical';
    }
    if (lower.contains('baby') || lower.contains('growth') || lower.contains('development')) {
      return 'growth';
    }
    return 'general';
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadHistory(),
      loadBookmarks(),
    ]);
  }
}
