import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/user_ai_context.dart';
import '../ai/ai_context_builder.dart';
import '../ai/ai_gateway_service.dart';
import '../ai/ai_observability_service.dart';
import '../ai/ai_response_parser.dart';
import '../ai/ai_risk_detector.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../error/app_exceptions.dart';
import '../error/error_handler.dart';
import '../network/api_client.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

/// Response model for AI chat interactions.
class AIChatResponse {
  final String reply;
  final String traceId;
  final List<String> toolsUsed;
  final double evaluationScore;
  final String safetyStatus;
  final int latencyMs;

  const AIChatResponse({
    required this.reply,
    required this.traceId,
    this.toolsUsed = const [],
    this.evaluationScore = 0.0,
    this.safetyStatus = 'allowed',
    this.latencyMs = 0,
  });

  factory AIChatResponse.fromJson(Map<String, dynamic> json) {
    return AIChatResponse(
      reply: json['reply']?.toString() ?? '',
      traceId: json['trace_id']?.toString() ?? '',
      toolsUsed: (json['tools_used'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      evaluationScore: (json['evaluation_score'] as num?)?.toDouble() ?? 0.0,
      safetyStatus: json['safety_status']?.toString() ?? 'allowed',
      latencyMs: (json['latency_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

/// AI health check response.
class AIHealthResponse {
  final bool healthy;
  final String status;
  final int activeModules;

  const AIHealthResponse({
    required this.healthy,
    this.status = 'unknown',
    this.activeModules = 0,
  });

  factory AIHealthResponse.fromJson(Map<String, dynamic> json) {
    return AIHealthResponse(
      healthy: json['healthy'] == true,
      status: json['status']?.toString() ?? 'unknown',
      activeModules: (json['active_modules'] as num?)?.toInt() ?? 0,
    );
  }
}

/// AI insights response.
class AIInsightsResponse {
  final List<Map<String, dynamic>> insights;
  final String generatedAt;

  const AIInsightsResponse({
    this.insights = const [],
    this.generatedAt = '',
  });

  factory AIInsightsResponse.fromJson(Map<String, dynamic> json) {
    return AIInsightsResponse(
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      generatedAt: json['generated_at']?.toString() ?? '',
    );
  }
}

/// Production-grade AI Service that integrates with the next-generation AI backend.
///
/// Responsibilities:
/// - Send chat messages to the AI gateway
/// - Receive and parse AI responses with trace IDs
/// - Send user feedback to the AI learning engine
/// - Retrieve AI insights and health status
/// - Manage session and trace IDs
/// - Support streaming responses
class AIService {
  static AIService? _instance;
  final ApiClient _apiClient;
  final AuthService _authService;
  final Uuid _uuid = const Uuid();
  final AiGatewayService _gatewayService;
  final AiContextBuilder _contextBuilder;
  final AiResponseParser _responseParser;
  final AiRiskDetector _riskDetector;
  final AiObservabilityService _observability;

  String? _currentSessionId;
  String? _lastTraceId;
  UserAiContext? _userContext;
  final List<String> _recentQuestions = <String>[];

  AIService._({
    required ApiClient apiClient,
    required AuthService authService,
    required AiGatewayService gatewayService,
    required AiContextBuilder contextBuilder,
    required AiResponseParser responseParser,
    required AiRiskDetector riskDetector,
    required AiObservabilityService observability,
  })  : _apiClient = apiClient,
        _authService = authService,
        _gatewayService = gatewayService,
        _contextBuilder = contextBuilder,
        _responseParser = responseParser,
        _riskDetector = riskDetector,
        _observability = observability;

  factory AIService({
    required ApiClient apiClient,
    required AuthService authService,
    AnalyticsService? analyticsService,
    AiGatewayService? gatewayService,
    AiContextBuilder? contextBuilder,
    AiResponseParser? responseParser,
    AiRiskDetector? riskDetector,
    AiObservabilityService? observabilityService,
  }) {
    _instance ??= AIService._(
      apiClient: apiClient,
      authService: authService,
      gatewayService: gatewayService ?? AiGatewayService(apiClient: apiClient),
      contextBuilder: contextBuilder ?? AiContextBuilder(),
      responseParser: responseParser ?? AiResponseParser(),
      riskDetector: riskDetector ?? AiRiskDetector(),
      observability: observabilityService ??
          AiObservabilityService(
            analyticsService: analyticsService ?? AnalyticsService(),
            apiClient: apiClient,
          ),
    );
    return _instance!;
  }

  String? get lastTraceId => _lastTraceId;
  String? get currentSessionId => _currentSessionId;
  UserAiContext? get userContext => _userContext;

  void setUserContext(UserAiContext context) {
    _userContext = context;
  }

  // ─── Session Management ─────────────────────────────────

  /// Ensures a session ID exists. Creates one if not present.
  Future<String> ensureSessionId() async {
    if (_currentSessionId != null) return _currentSessionId!;

    _currentSessionId = await _authService.getSessionId();
    if (_currentSessionId == null || _currentSessionId!.isEmpty) {
      _currentSessionId = _uuid.v4();
      await _authService.saveSessionId(_currentSessionId!);
    }
    return _currentSessionId!;
  }

  /// Starts a new AI session.
  Future<String> startNewSession() async {
    _currentSessionId = _uuid.v4();
    await _authService.saveSessionId(_currentSessionId!);
    return _currentSessionId!;
  }

  // ─── Chat ───────────────────────────────────────────────

  /// Sends a chat message to the AI gateway.
  ///
  /// Uses: `POST /api/v1/ai/chat`
  Future<AIChatResponse> sendMessage(
    String message, {
    UserAiContext? context,
    Map<String, dynamic>? extra,
  }) async {
    final startedAt = DateTime.now();
    try {
      final userId = await _authService.getUserId();
      final sessionId = await ensureSessionId();
      final effectiveContext = _buildContext(
        explicitContext: context,
        userId: userId ?? '',
        message: message,
        extra: extra,
      );

      final conversationId = await _authService.getConversationId();
      final response = await _gatewayService.sendChatMessage(
        message: message,
        context: effectiveContext,
        userId: userId,
        conversationId: conversationId,
      );

      if (kDebugMode) {
        debugPrint(
          '[IRA-AUDIT] POST ${ApiEndpoints.aiChat} success=${response['success']}',
        );
      }

      final parsed = _responseParser.parseChatResponse(response);
      if (parsed.reply.isEmpty) {
        throw const AIServiceException('AI gateway returned an empty response');
      }

      final risk = _riskDetector.detect(text: message, additionalText: parsed.reply);
      final latencyMs = DateTime.now().difference(startedAt).inMilliseconds;
      final aiResponse = AIChatResponse(
        reply: parsed.reply,
        traceId: parsed.traceId.isEmpty ? _uuid.v4() : parsed.traceId,
        toolsUsed: parsed.toolsUsed,
        evaluationScore: parsed.evaluationScore,
        safetyStatus:
            risk.requiresUrgentCare ? risk.tag : parsed.safetyStatus,
        latencyMs: latencyMs > 0 ? latencyMs : parsed.latencyMs,
      );

      _lastTraceId = aiResponse.traceId;
      _trackRecentQuestion(message);
      await _gatewayService.storeMemory(
        userQuestion: message,
        aiResponse: aiResponse.reply,
        topic: _deriveTopicFromMessage(message),
        timestamp: DateTime.now(),
      );

      await _observability.logEvent({
        'type': 'ai_request',
        'trace_id': aiResponse.traceId,
        'latency': aiResponse.latencyMs,
        'tokens': parsed.tokenUsage,
        'status': 'success',
        'safety_violation': risk.requiresUrgentCare,
        'risk_level': risk.tag,
      });

      return aiResponse;
    } catch (e) {
      ErrorHandler.logError(e, StackTrace.current);
      await _observability.logEvent({
        'type': 'ai_request',
        'status': 'error',
        'error': e.toString(),
        'latency': DateTime.now().difference(startedAt).inMilliseconds,
      });

      if (kDebugMode) {
        debugPrint('[IRA-AUDIT] gateway error type=${e.runtimeType}');
      }

      if (e is AIServiceException && e.code == 'RATE_LIMIT_EXCEEDED') {
        rethrow;
      }

      // `/api/v1/ai/chat` often returns a structured error envelope even for
      // "hello". Fall through to production `/aichats/send-message`.
      return _sendMessageLegacy(message);
    }
  }

  /// Fallback: production `POST /aichats/send-message` (`chatInput` contract).
  Future<AIChatResponse> _sendMessageLegacy(String message) async {
    try {
      var conversationId = await _authService.getConversationId();
      if (conversationId == null || conversationId.isEmpty) {
        conversationId = await createChatRoom();
      }

      if (kDebugMode) {
        debugPrint(
          '[IRA-AUDIT] POST ${ApiEndpoints.legacyAiSendMessage} hasConversation=${conversationId != null && conversationId.isNotEmpty}',
        );
      }

      final response = await _apiClient.post(
        ApiEndpoints.legacyAiSendMessage,
        data: {
          if (conversationId != null && conversationId.isNotEmpty)
            'conversationId': conversationId,
          'chatInput': message,
          'message': message,
        },
        timeout: AppConstants.aiApiTimeout,
      );

      if (response is Map) {
        final map = Map<String, dynamic>.from(response);
        if (map['success'] == false) {
          throw AIServiceException(
            map['message']?.toString() ?? 'Legacy AI error',
            code: 'AI_GATEWAY_ERROR',
          );
        }
        final parsed = _responseParser.parseChatResponse(map);
        if (parsed.reply.isNotEmpty) {
          return AIChatResponse(
            reply: parsed.reply,
            traceId: parsed.traceId.isEmpty ? _uuid.v4() : parsed.traceId,
          );
        }
      }

      throw const AIServiceException('Legacy AI returned an empty response');
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to send message: $e');
    }
  }

  /// Creates a chat room via legacy endpoint (fallback).
  Future<String?> createChatRoom() async {
    try {
      final response = await _apiClient.post(ApiEndpoints.legacyAiCreateRoom);

      if (response is Map) {
        final map = Map<String, dynamic>.from(response);
        if (map['success'] == true) {
          final data = map['data'] is Map
              ? Map<String, dynamic>.from(map['data'] as Map)
              : const <String, dynamic>{};
          final chat = map['chat'] is Map
              ? Map<String, dynamic>.from(map['chat'] as Map)
              : const <String, dynamic>{};
          final chatId = chat['_id']?.toString() ??
              data['_id']?.toString() ??
              data['conversationId']?.toString() ??
              map['conversationId']?.toString();
          if (chatId != null && chatId.isNotEmpty) {
            await _authService.saveConversationId(chatId);
            return chatId;
          }
        }
      }
      return null;
    } catch (e) {
      ErrorHandler.logError(e);
      return null;
    }
  }

  /// Retrieves all AI chat messages (legacy).
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.legacyAiAllMessages);

      if (response is Map<String, dynamic> && response['success'] == true) {
        final chats = response['chats'] as List<dynamic>?;
        return chats?.map((c) => c as Map<String, dynamic>).toList() ?? [];
      }
      return [];
    } catch (e) {
      ErrorHandler.logError(e);
      return [];
    }
  }

  // ─── Feedback ───────────────────────────────────────────

  /// Sends user feedback for an AI response.
  ///
  /// Uses: `POST /api/v1/ai/feedback`
  Future<bool> sendFeedback({
    required String traceId,
    required String feedback,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.aiFeedback,
        data: {
          'trace_id': traceId,
          'feedback': feedback,
        },
      );

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      return false;
    }
  }

  // ─── Health Check ───────────────────────────────────────

  /// Checks AI system health.
  ///
  /// Uses: `GET /api/v1/ai/health`
  Future<AIHealthResponse> checkHealth() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.aiHealth);

      if (response is Map<String, dynamic>) {
        return AIHealthResponse.fromJson(response);
      }
      return const AIHealthResponse(healthy: false);
    } catch (e) {
      ErrorHandler.logError(e);
      return const AIHealthResponse(healthy: false);
    }
  }

  // ─── Insights ───────────────────────────────────────────

  /// Retrieves AI-generated insights.
  ///
  /// Uses: `GET /api/ai/insights`
  Future<AIInsightsResponse> getInsights({Map<String, dynamic>? params}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.aiInsightsCategory,
        params: params,
      );

      if (response is Map<String, dynamic>) {
        return AIInsightsResponse.fromJson(response);
      }
      return const AIInsightsResponse();
    } catch (e) {
      ErrorHandler.logError(e);
      return const AIInsightsResponse();
    }
  }

  // ─── Streaming ──────────────────────────────────────────

  /// Sends a chat message and returns a stream for real-time response.
  /// Uses the new `/api/v1/chat/stream` endpoint with Server-Sent Events (SSE).
  Stream<String> sendMessageStream(
    String message, {
    UserAiContext? context,
  }) async* {
    try {
      final userId = await _authService.getUserId();
      final sessionId = await ensureSessionId();
      final effectiveContext = _buildContext(
        explicitContext: context,
        userId: userId ?? '',
        message: message,
      );

      // Use the new streaming endpoint
      final response = await _apiClient.dio.post(
        ApiEndpoints.chatStream,
        data: {
          'message': message,
          'sessionId': sessionId,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
          'context': effectiveContext,
        },
        options: Options(
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
          responseType: ResponseType.stream,
        ),
      );

      if (response.data != null) {
        final stream = response.data as Stream<List<int>>;
        final buffer = StringBuffer();
        
        await for (final chunk in stream.transform(utf8.decoder)) {
          buffer.write(chunk);
          final content = buffer.toString();
          final lines = content.split('\n');
          buffer.clear();
          
          // Keep the last incomplete line in buffer
          if (lines.length > 1 && !content.endsWith('\n')) {
            buffer.write(lines.removeLast());
          }
          
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            
            if (line.startsWith('data: ')) {
              try {
                final jsonData = jsonDecode(line.substring(6));
                if (jsonData is Map<String, dynamic>) {
                  final token = jsonData['token']?.toString() ?? 
                               jsonData['content']?.toString() ?? '';
                  if (token.isNotEmpty) {
                    yield token;
                  }
                  
                  // Check if stream is complete
                  if (jsonData['done'] == true || jsonData['finished'] == true) {
                    return;
                  }
                }
              } catch (e) {
                // Skip invalid JSON lines
                continue;
              }
            }
          }
        }
      }
    } catch (e) {
      ErrorHandler.logError(e);
      // Fallback to non-streaming
      try {
        final response = await sendMessage(message, context: context);
        yield response.reply;
      } catch (fallbackError) {
        yield 'Error: Unable to get AI response. Please try again.';
      }
    }
  }

  /// Send message using the new `/api/v1/chat` endpoint (standard, non-streaming)
  Future<AIChatResponse> sendMessageNew(
    String message, {
    UserAiContext? context,
    String? sessionId,
  }) async {
    final startedAt = DateTime.now();
    try {
      final userId = await _authService.getUserId();
      final effectiveSessionId = sessionId ?? await ensureSessionId();
      final effectiveContext = _buildContext(
        explicitContext: context,
        userId: userId ?? '',
        message: message,
      );

      final response = await _apiClient.post(
        ApiEndpoints.chat,
        data: {
          'message': message,
          'sessionId': effectiveSessionId,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
          'context': effectiveContext,
        },
        timeout: AppConstants.aiApiTimeout,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final data = response['data'] ?? response;
        final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
        
        final aiResponse = AIChatResponse(
          reply: data['message']?.toString() ?? '',
          traceId: response['requestId']?.toString() ?? 
                   metadata['trace_id']?.toString() ?? 
                   _uuid.v4(),
          toolsUsed: (metadata['tools_used'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          evaluationScore: (metadata['evaluation_score'] as num?)?.toDouble() ?? 0.0,
          safetyStatus: metadata['safety_status']?.toString() ?? 'passed',
          latencyMs: (metadata['latency_ms'] as num?)?.toInt() ?? 
                     DateTime.now().difference(startedAt).inMilliseconds,
        );

        _lastTraceId = aiResponse.traceId;
        _trackRecentQuestion(message);
        
        await _gatewayService.storeMemory(
          userQuestion: message,
          aiResponse: aiResponse.reply,
          topic: _deriveTopicFromMessage(message),
          timestamp: DateTime.now(),
        );

        return aiResponse;
      }
      
      throw const AIServiceException('AI service returned invalid response');
    } catch (e) {
      ErrorHandler.logError(e, StackTrace.current);
      // Fallback to existing gateway service
      return sendMessage(message, context: context);
    }
  }

  /// Uploads recorded audio to `/api/v1/ai/chat/voice`.
  Future<AIChatResponse> sendVoiceMessage(
    File audioFile, {
    UserAiContext? context,
  }) async {
    final startedAt = DateTime.now();
    try {
      final userId = await _authService.getUserId();
      final sessionId = await ensureSessionId();
      final effectiveContext = _buildContext(
        explicitContext: context,
        userId: userId ?? '',
        message: '',
      );

      final formData = FormData.fromMap({
        'sessionId': sessionId,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        'context': jsonEncode(effectiveContext),
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.uri.pathSegments.isNotEmpty
              ? audioFile.uri.pathSegments.last
              : 'voice.m4a',
        ),
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.aiChatVoice,
        data: formData,
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const AIServiceException('Invalid voice response format');
      }

      final data = (body['data'] is Map<String, dynamic>)
          ? body['data'] as Map<String, dynamic>
          : body;

      final metadata = (data['metadata'] is Map<String, dynamic>)
          ? data['metadata'] as Map<String, dynamic>
          : <String, dynamic>{};

      final reply = data['reply']?.toString() ??
          data['message']?.toString() ??
          data['response']?.toString() ??
          '';

      if (reply.isEmpty) {
        throw const AIServiceException('Voice AI returned empty reply');
      }

      return AIChatResponse(
        reply: reply,
        traceId: data['trace_id']?.toString() ??
            metadata['trace_id']?.toString() ??
            _uuid.v4(),
        toolsUsed: (metadata['tools_used'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        evaluationScore: (metadata['evaluation_score'] as num?)?.toDouble() ?? 0.0,
        safetyStatus: metadata['safety_status']?.toString() ?? 'allowed',
        latencyMs: (metadata['latency_ms'] as num?)?.toInt() ??
            DateTime.now().difference(startedAt).inMilliseconds,
      );
    } catch (e) {
      ErrorHandler.logError(e, StackTrace.current);
      throw AIServiceException('Failed to upload voice message: $e');
    }
  }

  Future<void> syncMemory({
    required String userQuestion,
    required String aiResponse,
    required String topic,
    DateTime? timestamp,
  }) async {
    await _gatewayService.storeMemory(
      userQuestion: userQuestion,
      aiResponse: aiResponse,
      topic: topic,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _buildContext({
    required UserAiContext? explicitContext,
    required String userId,
    required String message,
    Map<String, dynamic>? extra,
  }) {
    final base = explicitContext ??
        _userContext ??
        UserAiContext(
          userId: userId,
          previousQuestions: _recentQuestions,
        );
    return _contextBuilder.buildContext(
      userContext: base.copyWith(previousQuestions: _recentQuestions),
      currentMessage: message,
      extra: extra,
    );
  }

  void _trackRecentQuestion(String message) {
    _recentQuestions.insert(0, message);
    if (_recentQuestions.length > 10) {
      _recentQuestions.removeRange(10, _recentQuestions.length);
    }
  }

  String _deriveTopicFromMessage(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) return 'general';
    final words = normalized.split(RegExp(r'\s+'));
    return words.take(4).join(' ').toLowerCase();
  }
}

