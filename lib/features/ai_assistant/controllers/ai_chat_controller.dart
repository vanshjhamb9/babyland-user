import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:babyland/app/data/repository/repository.dart'
    as legacy_repository;
import 'package:babyland/app/services/user_preference/user_preference.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/ai/ai_risk_detector.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/analytics_service.dart';
import '../../../models/user_ai_context.dart';
import '../../../features/trackers/utils/tracker_math.dart';
import '../models/ai_message_model.dart';
import '../repositories/ai_chat_repository.dart';

/// Advanced AI chat controller with:
/// - Streaming responses with typing animation
/// - Voice input (STT)
/// - Voice output (TTS)
/// - Message reactions/feedback
/// - Conversation history
/// - Offline cache support
class AiChatController extends ChangeNotifier {
  final AiChatRepository _repository;
  final AnalyticsService _analytics;
  final Uuid _uuid = const Uuid();

  // ─── UI State ───────────────────────────────────────────
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<AiMessageModel> messages = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _showHistory = false;
  bool get showHistory => _showHistory;

  String? _error;
  String? get error => _error;

  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;
  UserAiContext? _userContext;

  // ─── Voice Input (STT) ─────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool get isListening => _isListening;
  bool _speechInitialized = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isHoldRecording = false;
  bool get isHoldRecording => _isHoldRecording;
  String? _holdTalkPath;

  // ─── Voice Output (TTS) ─────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  // ─── Streaming ──────────────────────────────────────────
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;
  StreamSubscription<String>? _streamSubscription;

  bool _isDisposed = false;

  static const String _iraFallbackReply =
      "I couldn't complete that just now. Please try again in a moment.";

  AiChatController({
    required AiChatRepository repository,
    required AnalyticsService analytics,
  })  : _repository = repository,
        _analytics = analytics;

  void updateUserContext(UserAiContext context) {
    _userContext = context;
    _repository.setUserContext(context);
  }

  // ─── Initialization ─────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create chat room / session
      _currentSessionId = await _repository.startNewSession();
      await _repository.createChatRoom();

      // Load cached messages if available
      if (_currentSessionId != null) {
        final cached = _repository.getCachedMessages(_currentSessionId!);
        if (cached != null && cached.isNotEmpty) {
          messages.addAll(cached);
        }
      }

      // Initialize TTS
      await _initTts();

      _isInitialized = true;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      log('AiChatController init error: $e', name: 'AiChat');
      _isLoading = false;
      _error = 'Failed to initialize ${AppConstants.aiAssistantDisplayName}';
      notifyListeners();
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (!_isDisposed) notifyListeners();
    });
  }

  // ─── Send Message ───────────────────────────────────────

  Future<void> sendMessage({bool useStreaming = true}) async {
    final text = messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    messageController.clear();

    // Add user message
    final userMsg = AiMessageModel(
      id: _uuid.v4(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);
    _isLoading = true;
    _error = null;
    notifyListeners();

    _scrollToBottom();

    // Log analytics
    _analytics.logAiChatSent(
      sessionId: _currentSessionId ?? '',
      messageLength: text.length,
    );

    // ─── AI user-data context (logs) ───────────────────────────────
    final hydrationLogs = await getHydrationLogs();
    final mentalLogs = await getMentalLogs();
    final menstrualLogs = await getMenstrualLogs();
    final pregnancyData = await getPregnancyData();

    final extraContext = <String, dynamic>{
      'hydration_logs': hydrationLogs.take(5).toList(),
      'mental_logs': mentalLogs.take(5).toList(),
      'menstrual_logs': menstrualLogs.take(5).toList(),
      'pregnancy_data': pregnancyData,
    };

    print("AI Context: $extraContext");

    if (useStreaming) {
      await _sendWithStreaming(
        text,
        extraContext: extraContext,
      );
    } else {
      await _sendDirect(
        text,
        extraContext: extraContext,
      );
    }
  }

  // ─── Step 1: Fetch logs (before sending message) ──────────────────

  Future<List<Map<String, dynamic>>> getHydrationLogs() async {
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 7));
      final to = now;

      final resp = await sl.healthTrackerService.getHydrationLogs(
        from: from,
        to: to,
        page: 1,
        limit: 200,
      );

      final logs = resp.data.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return logs.map((e) => e.toJson()).toList();
    } catch (e, st) {
      log('getHydrationLogs error: $e\n$st', name: 'AiChat');
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getMenstrualLogs() async {
    try {
      final repo = legacy_repository.Repository();
      final now = DateTime.now();
      final days = TrackerMath.lastNDays(now, count: 5).reversed;

      final result = <Map<String, dynamic>>[];
      for (final d in days) {
        final apiDate = DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));
        final res = await repo.getMenstrualLogs(params: {'date': apiDate});

        if (res.success == true && res.data != null && res.data!.isNotEmpty) {
          result.addAll(res.data!.map((e) => e.toJson()));
        }
      }

      result.sort((a, b) {
        final da = DateTime.tryParse(a['date']?.toString() ?? '');
        final db = DateTime.tryParse(b['date']?.toString() ?? '');
        if (da != null && db != null) return db.compareTo(da);
        return (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? '');
      });
      return result;
    } catch (e, st) {
      log('getMenstrualLogs error: $e\n$st', name: 'AiChat');
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getMentalLogs() async {
    // Postpartum: backend first, Hive only as fallback.
    try {
      final repo = legacy_repository.Repository();
      final now = DateTime.now();
      final days = TrackerMath.lastNDays(now, count: 5).reversed;

      final results = <Map<String, dynamic>>[];

      for (final d in days) {
        final apiDate =
            DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));
        try {
          final res = await repo.getPostpartumLogs(params: {'date': apiDate});
          if (res.success == true && res.data != null && res.data!.isNotEmpty) {
            final log = res.data!.first;
            final mood = log.mood;
            if (mood == null || mood.trim().isEmpty) continue;

            results.add({
              'date': log.date,
              'mood': mood,
              'score': TrackerMath.moodToScore(mood),
              'stressLevel': log.stressLevel,
              'anxietyLevel': log.anxietyLevel,
              'symptoms': log.symptoms,
              'notes': log.notes,
              'sleepQuality': log.sleepQuality,
              'mentalHealth': log.mentalHealth?.toJson(),
              'hydration': log.hydration?.toJson(),
            });
          }
        } catch (_) {
          // Ignore per-day failures; we'll fall back below.
        }
      }

      if (results.isNotEmpty) {
        results.sort((a, b) {
          final da = DateTime.tryParse(a['date']?.toString() ?? '');
          final db = DateTime.tryParse(b['date']?.toString() ?? '');
          if (da != null && db != null) return db.compareTo(da);
          return (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? '');
        });
        return results;
      }
    } catch (e, st) {
      log('getMentalLogs postpartum fetch error: $e\n$st', name: 'AiChat');
    }

    // Hive fallback (postpartum only).
    try {
      final hiveRaw = UserPreference.getPostMentalHealthLogs();
      if (hiveRaw.isNotEmpty) {
        final mapped = hiveRaw.map((e) {
          return <String, dynamic>{
            'date': e['date']?.toString(),
            'mood': e['mood']?.toString(),
            'score': (e['score'] is num)
                ? (e['score'] as num).toInt()
                : int.tryParse(e['score']?.toString() ?? '') ?? 0,
          };
        }).toList();

        mapped.sort((a, b) {
          final da = DateTime.tryParse(a['date']?.toString() ?? '');
          final db = DateTime.tryParse(b['date']?.toString() ?? '');
          if (da != null && db != null) return db.compareTo(da);
          return (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? '');
        });

        return mapped;
      }
    } catch (_) {}

    // Final fallback: treat menstrual mood logs as mental logs.
    final menstrualLogs = await getMenstrualLogs();
    return menstrualLogs
        .map((e) => <String, dynamic>{
                'date': e['date'],
                'mood': e['mood'],
                'score': TrackerMath.moodToScore(e['mood']?.toString()),
                'stressLevel': e['stressLevel'],
                'anxietyLevel': e['anxietyLevel'],
                'symptoms': e['symptoms'],
                'notes': e['notes'],
              })
        .toList();
  }

  Future<Map<String, dynamic>> getPregnancyData() async {
    try {
      final repo = legacy_repository.Repository();
      final now = DateTime.now();
      final days = TrackerMath.lastNDays(now, count: 5).reversed;
      final results = <Map<String, dynamic>>[];

      for (final d in days) {
        final apiDate =
            DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));
        final res = await repo.getPregnancyLogs(params: {'date': apiDate});
        if (res.success == true && res.data != null && res.data!.isNotEmpty) {
          for (final log in res.data!) {
            final mood = log.mood;
            if (mood == null || mood.trim().isEmpty) continue;
            results.add({
              'date': log.date,
              'mood': mood,
              'score': TrackerMath.moodToScore(mood),
              'stressLevel': log.stressLevel,
              'anxietyLevel': log.anxietyLevel,
              'symptoms': log.symptoms,
              'notes': log.notes,
              'sleepQuality': log.sleepQuality,
              'mentalHealth': log.mentalHealth?.toJson(),
              'hydration': log.hydration?.toJson(),
            });
          }
        }
      }

      results.sort((a, b) {
        final da = DateTime.tryParse(a['date']?.toString() ?? '');
        final db = DateTime.tryParse(b['date']?.toString() ?? '');
        if (da != null && db != null) return db.compareTo(da);
        return (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? '');
      });

      return {'logs': results};
    } catch (e, st) {
      log('getPregnancyData error: $e\n$st', name: 'AiChat');
      return <String, dynamic>{};
    }
  }

  Future<void> _sendDirect(
    String text, {
    required Map<String, dynamic> extraContext,
  }) async {
    try {
      final response = await _repository.sendMessage(
        text,
        context: _userContext,
        extra: extraContext,
      );

      final safeReply = _safeAssistantReply(response.reply);
      log(
        '[IRA-AUDIT] send ok=${!_isSystemErrorReply(response.reply)} replyLen=${response.reply.length}',
        name: 'IRA',
      );

      final aiMsg = AiMessageModel(
        id: _uuid.v4(),
        content: safeReply,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        traceId: response.traceId,
        toolsUsed: response.toolsUsed,
        evaluationScore: response.evaluationScore,
        safetyStatus: response.safetyStatus,
        latencyMs: response.latencyMs,
      );

      messages.add(aiMsg);

      final riskAssessment = _repository.detectRisk(
        userText: text,
        aiText: safeReply,
      );
      if (riskAssessment.requiresUrgentCare) {
        messages.add(
          AiMessageModel(
            id: _uuid.v4(),
            content: AiRiskDetector.medicalAlertMessage,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            safetyStatus: riskAssessment.tag,
          ),
        );
      }

      _isLoading = false;
      notifyListeners();
      _scrollToBottom();

      // Log analytics
      _analytics.logAiChatReceived(
        traceId: response.traceId,
        latencyMs: response.latencyMs,
        evaluationScore: response.evaluationScore,
        safetyStatus: response.safetyStatus,
      );

      // Cache messages
      _cacheCurrentMessages();
    } catch (e) {
      log('[IRA-AUDIT] send failed: ${e.runtimeType}', name: 'IRA');
      _isLoading = false;
      _error = null;
      _presentIraFallback();
      notifyListeners();
    }
  }

  Future<void> _sendWithStreaming(
    String text, {
    required Map<String, dynamic> extraContext,
  }) async {
    try {
      // Add placeholder AI message for streaming
      final aiMsgId = _uuid.v4();
      final aiMsg = AiMessageModel(
        id: aiMsgId,
        content: '',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      messages.add(aiMsg);
      _isStreaming = true;
      _isLoading = false;
      notifyListeners();

      // Get the full response first, then stream it
      final response = await _repository.sendMessage(
        text,
        context: _userContext,
        extra: extraContext,
      );

      final safeReply = _safeAssistantReply(response.reply);
      log(
        '[IRA-AUDIT] send ok=${!_isSystemErrorReply(response.reply)} replyLen=${response.reply.length}',
        name: 'IRA',
      );

      // Simulate streaming (character-by-character typing animation)
      String displayedText = '';
      final fullText = safeReply;

      for (int i = 0; i < fullText.length && !_isDisposed; i++) {
        displayedText += fullText[i];

        final index = messages.indexWhere((m) => m.id == aiMsgId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(content: displayedText);
          notifyListeners();
        }

        // Faster animation for longer messages
        final delay = fullText.length > 500
            ? const Duration(milliseconds: 5)
            : const Duration(milliseconds: 20);
        await Future.delayed(delay);

        // Scroll periodically during streaming
        if (i % 50 == 0) _scrollToBottom();
      }

      // Finalize the message with full metadata
      final index = messages.indexWhere((m) => m.id == aiMsgId);
      if (index != -1) {
        messages[index] = AiMessageModel(
          id: aiMsgId,
          content: fullText,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          traceId: response.traceId,
          toolsUsed: response.toolsUsed,
          evaluationScore: response.evaluationScore,
          safetyStatus: response.safetyStatus,
          latencyMs: response.latencyMs,
          isStreaming: false,
        );
      }

      final riskAssessment = _repository.detectRisk(
        userText: text,
        aiText: safeReply,
      );
      if (riskAssessment.requiresUrgentCare) {
        messages.add(
          AiMessageModel(
            id: _uuid.v4(),
            content: AiRiskDetector.medicalAlertMessage,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            safetyStatus: riskAssessment.tag,
          ),
        );
      }

      _isStreaming = false;
      notifyListeners();
      _scrollToBottom();

      // Log analytics
      _analytics.logAiChatReceived(
        traceId: response.traceId,
        latencyMs: response.latencyMs,
        evaluationScore: response.evaluationScore,
        safetyStatus: response.safetyStatus,
      );

      _cacheCurrentMessages();
    } catch (e) {
      log('[IRA-AUDIT] send failed: ${e.runtimeType}', name: 'IRA');
      _isStreaming = false;
      _isLoading = false;
      _error = null;
      _presentIraFallback();
      notifyListeners();
    }
  }

  String _safeAssistantReply(String reply) {
    if (_isSystemErrorReply(reply)) return _iraFallbackReply;
    return reply;
  }

  bool _isSystemErrorReply(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return true;
    return t.contains('encountered an error') ||
        t.contains('error processing your message') ||
        t.contains('failed to get ai') ||
        t.contains('unable to get ai') ||
        t.contains('ai gateway');
  }

  void _presentIraFallback() {
    final streamingIndex = messages.lastIndexWhere(
      (m) =>
          m.role == MessageRole.assistant &&
          (m.isStreaming || m.content.trim().isEmpty),
    );
    if (streamingIndex != -1) {
      messages[streamingIndex] = messages[streamingIndex].copyWith(
        content: _iraFallbackReply,
        isStreaming: false,
      );
      return;
    }
    messages.add(
      AiMessageModel(
        id: _uuid.v4(),
        content: _iraFallbackReply,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ─── Quick Actions ──────────────────────────────────────

  Future<void> sendQuickMessage(String message) async {
    messageController.text = message;
    await sendMessage();
  }

  // ─── Feedback (Step 5) ──────────────────────────────────

  Future<void> submitFeedback(String messageId, MessageFeedback feedback) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final msg = messages[index];
    if (msg.traceId == null) return;

    messages[index] = msg.copyWith(feedback: feedback);
    notifyListeners();

    final success = await _repository.submitFeedback(
      traceId: msg.traceId!,
      feedback: feedback,
    );

    if (success) {
      _analytics.logAiFeedback(
        traceId: msg.traceId!,
        feedback: feedback == MessageFeedback.positive ? 'positive' : 'negative',
      );
    }
  }

  // ─── Voice Input (STT) ─────────────────────────────────

  Future<void> toggleVoiceInput() async {
    if (_isDisposed) return;

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isDisposed) return;

    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onError: (error) {
          log('STT Error: ${error.errorMsg}', name: 'AiChat');
          _isListening = false;
          if (!_isDisposed) notifyListeners();
        },
      );

      if (!_speechInitialized) {
        _error = 'Speech recognition not available';
        notifyListeners();
        return;
      }
    }

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isListening = true;
    notifyListeners();

    _analytics.logAiVoiceInput();

    await _speech.listen(
      onResult: (result) {
        if (_isDisposed) return;

        messageController.text = result.recognizedWords;
        notifyListeners();

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          Future.microtask(() async {
            await _stopListening();
            await Future.delayed(const Duration(milliseconds: 300));
            sendMessage();
          });
        }
      },
      listenFor: const Duration(minutes: 3),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
      listenOptions: stt.SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> _stopListening() async {
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
    _isListening = false;
    if (!_isDisposed) notifyListeners();
  }

  // ─── Voice Recording (Hold-to-talk) ─────────────────────

  Future<void> startHoldToTalk() async {
    if (_isDisposed || _isLoading || _isStreaming || _isHoldRecording) return;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _error = 'Microphone permission is required';
        notifyListeners();
        return;
      }

      _holdTalkPath =
          '${Directory.systemTemp.path}/babyland_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: _holdTalkPath!,
      );
      _isHoldRecording = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Unable to start recording';
      notifyListeners();
    }
  }

  Future<void> stopHoldToTalkAndSend() async {
    if (_isDisposed || !_isHoldRecording) return;

    try {
      final path = await _audioRecorder.stop();
      _isHoldRecording = false;
      final effectivePath = (path != null && path.isNotEmpty) ? path : _holdTalkPath;
      _holdTalkPath = null;
      notifyListeners();

      if (effectivePath == null || effectivePath.isEmpty) return;
      final audioFile = File(effectivePath);
      if (!await audioFile.exists()) return;

      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _repository.sendVoiceMessage(
        audioFile,
        context: _userContext,
      );

      final transcript = messageController.text.trim();
      if (transcript.isNotEmpty) {
        messages.add(
          AiMessageModel(
            id: _uuid.v4(),
            content: transcript,
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        messages.add(
          AiMessageModel(
            id: _uuid.v4(),
            content: '[Voice message]',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
        );
      }

      messages.add(
        AiMessageModel(
          id: _uuid.v4(),
          content: _safeAssistantReply(response.reply),
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          traceId: response.traceId,
          toolsUsed: response.toolsUsed,
          evaluationScore: response.evaluationScore,
          safetyStatus: response.safetyStatus,
          latencyMs: response.latencyMs,
        ),
      );

      _isLoading = false;
      notifyListeners();
      _scrollToBottom();
      _cacheCurrentMessages();

      try {
        await audioFile.delete();
      } catch (_) {}
    } catch (e) {
      _isHoldRecording = false;
      _isLoading = false;
      _error = 'Failed to send voice message. Please try again.';
      notifyListeners();
    }
  }

  Future<void> cancelHoldToTalk() async {
    if (!_isHoldRecording) return;
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    _isHoldRecording = false;
    _holdTalkPath = null;
    notifyListeners();
  }

  /// Clears the last error so retry / UI does not feel "stuck".
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Voice Output (TTS) ─────────────────────────────────

  Future<void> speakMessage(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
      notifyListeners();
      return;
    }

    // Strip markdown for TTS
    final cleanText = text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll('---', '')
        .replaceAll(RegExp(r'\n+'), '. ');

    _isSpeaking = true;
    notifyListeners();

    await _tts.speak(cleanText);
  }

  // ─── History ────────────────────────────────────────────

  Future<void> loadHistory() async {
    _showHistory = true;
    _isLoading = true;
    notifyListeners();

    try {
      final history = await _repository.getConversationHistory();
      messages.clear();

      for (final chat in history) {
        final role = chat['role'] == 'assistant'
            ? MessageRole.assistant
            : MessageRole.user;
        messages.add(AiMessageModel(
          id: chat['_id']?.toString() ?? _uuid.v4(),
          content: chat['content']?.toString() ?? '',
          role: role,
          timestamp: chat['createdAt'] != null
              ? DateTime.parse(chat['createdAt'])
              : DateTime.now(),
        ));
      }

      _isLoading = false;
      notifyListeners();
      _scrollToBottom(immediate: true);
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load chat history';
      notifyListeners();
    }
  }

  void startNewChat() {
    _showHistory = false;
    messages.clear();
    _error = null;
    notifyListeners();
  }

  // ─── Scroll ─────────────────────────────────────────────

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      try {
        final maxExtent = scrollController.position.maxScrollExtent;
        if (immediate) {
          scrollController.jumpTo(maxExtent);
        } else {
          scrollController.animateTo(
            maxExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        // Ignore scroll errors
      }
    });
  }

  // ─── Cache ──────────────────────────────────────────────

  void _cacheCurrentMessages() {
    if (_currentSessionId != null && messages.isNotEmpty) {
      _repository.cacheMessages(_currentSessionId!, messages);
    }
  }

  // ─── Cleanup ────────────────────────────────────────────

  @override
  void dispose() {
    _isDisposed = true;
    _streamSubscription?.cancel();
    _stopListening();
    _speech.cancel();
    _audioRecorder.dispose();
    _tts.stop();
    scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
