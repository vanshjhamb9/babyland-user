import '../error/app_exceptions.dart';

class ParsedAiResponse {
  final String reply;
  final String traceId;
  final List<String> toolsUsed;
  final double evaluationScore;
  final String safetyStatus;
  final int latencyMs;
  final int tokenUsage;
  final Map<String, dynamic> raw;

  const ParsedAiResponse({
    required this.reply,
    required this.traceId,
    this.toolsUsed = const [],
    this.evaluationScore = 0.0,
    this.safetyStatus = 'allowed',
    this.latencyMs = 0,
    this.tokenUsage = 0,
    this.raw = const {},
  });
}

class AiResponseParser {
  ParsedAiResponse parseChatResponse(dynamic response) {
    if (response is! Map) {
      throw const AIServiceException(
        'Invalid AI gateway response format',
      );
    }

    final map = _asStringKeyedMap(response) ?? const <String, dynamic>{};
    if (map['success'] == false) {
      throw AIServiceException(
        _envelopeError(map),
        code: 'AI_GATEWAY_ERROR',
      );
    }

    final dataMap = _asStringKeyedMap(map['data']) ?? const <String, dynamic>{};
    final chatMap = _asStringKeyedMap(map['chat']) ?? const <String, dynamic>{};

    final reply = _firstNonEmpty([
      map['reply'],
      dataMap['reply'],
      dataMap['aiResponse'],
      dataMap['aiMessage'],
      chatMap['aiMessage'],
      chatMap['reply'],
      dataMap['message'],
    ]);

    final tools = (map['tools_used'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return ParsedAiResponse(
      reply: reply,
      traceId: _firstNonEmpty([
        map['trace_id'],
        dataMap['trace_id'],
        map['traceId'],
        chatMap['chatId'],
      ]),
      toolsUsed: tools,
      evaluationScore: _readDouble(map['evaluation_score']),
      safetyStatus: map['safety_status']?.toString() ?? 'allowed',
      latencyMs: _readInt(map['latency_ms']),
      tokenUsage: _readInt(
        map['token_usage'] ?? map['tokens'] ?? map['usage_tokens'],
      ),
      raw: map,
    );
  }

  String _envelopeError(Map<String, dynamic> map) {
    final dataMap = _asStringKeyedMap(map['data']) ?? const <String, dynamic>{};
    final text = _firstNonEmpty([
      map['error'],
      dataMap['error'],
      map['message'],
    ]);
    return text.isEmpty ? 'AI request failed' : text;
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
