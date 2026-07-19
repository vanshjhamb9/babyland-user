import 'dart:io';

import 'package:babyland/core/ai/ai_risk_detector.dart';
import 'package:babyland/core/services/ai_service.dart';
import 'package:babyland/core/services/cache_service.dart';
import 'package:babyland/features/ai_assistant/models/ai_message_model.dart';
import 'package:babyland/models/user_ai_context.dart';

/// Repository layer for AI chat operations.
/// Manages data flow between AI service, cache, and UI.
class AiChatRepository {
  final AIService _aiService;
  final CacheService _cacheService;
  final AiRiskDetector _riskDetector = AiRiskDetector();

  AiChatRepository({
    required AIService aiService,
    required CacheService cacheService,
  })  : _aiService = aiService,
        _cacheService = cacheService;

  /// Sends a message and returns the AI response.
  Future<AIChatResponse> sendMessage(
    String message, {
    UserAiContext? context,
    Map<String, dynamic>? extra,
  }) async {
    return await _aiService.sendMessage(
      message,
      context: context,
      extra: extra,
    );
  }

  /// Sends a message with streaming response.
  Stream<String> sendMessageStream(
    String message, {
    UserAiContext? context,
  }) {
    return _aiService.sendMessageStream(message, context: context);
  }

  Future<AIChatResponse> sendVoiceMessage(
    File audioFile, {
    UserAiContext? context,
  }) async {
    return _aiService.sendVoiceMessage(audioFile, context: context);
  }

  void setUserContext(UserAiContext context) {
    _aiService.setUserContext(context);
  }

  AiRiskAssessment detectRisk({
    required String userText,
    String? aiText,
  }) {
    return _riskDetector.detect(text: userText, additionalText: aiText);
  }

  /// Submits feedback for an AI response.
  Future<bool> submitFeedback({
    required String traceId,
    required MessageFeedback feedback,
  }) async {
    final feedbackStr = feedback == MessageFeedback.positive ? 'positive' : 'negative';
    return await _aiService.sendFeedback(
      traceId: traceId,
      feedback: feedbackStr,
    );
  }

  /// Creates a new chat room (legacy support).
  Future<String?> createChatRoom() async {
    return await _aiService.createChatRoom();
  }

  /// Starts a new AI session.
  Future<String> startNewSession() async {
    return await _aiService.startNewSession();
  }

  /// Fetches conversation history.
  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    return await _aiService.getAllMessages();
  }

  /// Caches messages locally for offline access.
  Future<void> cacheMessages(String sessionId, List<AiMessageModel> messages) async {
    final jsonMessages = messages.map((m) => m.toJson()).toList();
    await _cacheService.cacheAiChats(sessionId, jsonMessages);
  }

  /// Retrieves cached messages.
  List<AiMessageModel>? getCachedMessages(String sessionId) {
    final cached = _cacheService.getCachedAiChats(sessionId);
    if (cached == null) return null;
    return cached.map((json) => AiMessageModel.fromJson(json)).toList();
  }

  /// Gets AI system insights.
  Future<AIInsightsResponse> getInsights({Map<String, dynamic>? params}) async {
    return await _aiService.getInsights(params: params);
  }

  /// Checks AI system health.
  Future<AIHealthResponse> checkHealth() async {
    return await _aiService.checkHealth();
  }
}
