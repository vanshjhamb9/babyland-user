import 'dart:convert';
import 'dart:developer';

import '../../../core/services/ai_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../features/ai_assistant/models/ai_message_model.dart';
import '../models/saved_insight_model.dart';

/// Repository for AI Conversation Memory and saved insights.
class ConversationMemoryRepository {
  final AIService _aiService;
  final CacheService _cacheService;

  static const _historyCacheKey = 'ai_conversation_history';
  static const _bookmarksCacheKey = 'ai_bookmarked_messages';

  ConversationMemoryRepository({
    required AIService aiService,
    required CacheService cacheService,
  })  : _aiService = aiService,
        _cacheService = cacheService;

  /// Fetches conversation history from AI service or cache.
  Future<List<AiMessageModel>> getConversationHistory() async {
    try {
      // Try to get from AI service (if it has history endpoint)
      // For now, we'll use cached history
      return _getCachedHistory();
    } catch (e) {
      log('Error fetching conversation history: $e', name: 'ConvMemoryRepo');
      return _getCachedHistory();
    }
  }

  /// Saves a message to conversation history.
  Future<void> saveMessage(AiMessageModel message) async {
    try {
      final history = _getCachedHistory();
      history.insert(0, message);

      // Keep only last 100 messages
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }

      await _cacheService.put(
        _historyCacheKey,
        jsonEncode(history.map((m) => _messageToJson(m)).toList()),
        expiry: const Duration(days: 30),
      );

      if (message.role == MessageRole.assistant) {
        final latestUserMessage = history
            .where((m) => m.role == MessageRole.user)
            .cast<AiMessageModel?>()
            .firstWhere((_) => true, orElse: () => null);
        if (latestUserMessage != null && latestUserMessage.content.isNotEmpty) {
          await _aiService.syncMemory(
            userQuestion: latestUserMessage.content,
            aiResponse: message.content,
            topic: _deriveTopic(latestUserMessage.content),
            timestamp: message.timestamp,
          );
        }
      }
    } catch (e) {
      log('Error saving message: $e', name: 'ConvMemoryRepo');
    }
  }

  /// Gets all bookmarked insights.
  Future<List<SavedInsightModel>> getBookmarks() async {
    return _getCachedBookmarks();
  }

  /// Saves a bookmark.
  Future<void> saveBookmark(SavedInsightModel bookmark) async {
    try {
      final bookmarks = _getCachedBookmarks();
      bookmarks.insert(0, bookmark);

      await _cacheService.put(
        _bookmarksCacheKey,
        jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
        expiry: const Duration(days: 365),
      );
    } catch (e) {
      log('Error saving bookmark: $e', name: 'ConvMemoryRepo');
    }
  }

  /// Removes a bookmark.
  Future<void> removeBookmark(String id) async {
    try {
      final bookmarks = _getCachedBookmarks();
      bookmarks.removeWhere((b) => b.id == id);

      await _cacheService.put(
        _bookmarksCacheKey,
        jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
        expiry: const Duration(days: 365),
      );
    } catch (e) {
      log('Error removing bookmark: $e', name: 'ConvMemoryRepo');
    }
  }

  /// Checks if a message is bookmarked.
  bool isBookmarked(String id) {
    return _getCachedBookmarks().any((b) => b.id == id);
  }

  List<AiMessageModel> _getCachedHistory() {
    final cached = _cacheService.get(_historyCacheKey);
    if (cached == null) return [];

    try {
      final data = cached is String ? jsonDecode(cached) : cached;
      return (data as List<dynamic>)
          .map((e) => _messageFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<SavedInsightModel> _getCachedBookmarks() {
    final cached = _cacheService.get(_bookmarksCacheKey);
    if (cached == null) return [];

    try {
      final data = cached is String ? jsonDecode(cached) : cached;
      return (data as List<dynamic>)
          .map((e) => SavedInsightModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _messageToJson(AiMessageModel message) {
    return {
      'id': message.id,
      'content': message.content,
      'role': message.role == MessageRole.assistant ? 'assistant' : 'user',
      'timestamp': message.timestamp.toIso8601String(),
      'traceId': message.traceId,
    };
  }

  AiMessageModel _messageFromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      role: json['role'] == 'assistant'
          ? MessageRole.assistant
          : MessageRole.user,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      traceId: json['traceId']?.toString(),
    );
  }

  String _deriveTopic(String message) {
    final words = message.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'general';
    return words.take(4).join(' ').toLowerCase();
  }
}
