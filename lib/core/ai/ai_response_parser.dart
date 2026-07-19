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
    if (response is! Map<String, dynamic>) {
      return const ParsedAiResponse(reply: '', traceId: '');
    }

    final dataObj = response['data'];
    final dataMap = dataObj is Map<String, dynamic> ? dataObj : const {};

    final tokenUsage = _readInt(
      response['token_usage'] ?? response['tokens'] ?? response['usage_tokens'],
    );
    final tools = (response['tools_used'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return ParsedAiResponse(
      reply: response['reply']?.toString() ??
          dataMap['reply']?.toString() ??
          response['message']?.toString() ??
          response['response']?.toString() ??
          '',
      traceId: response['trace_id']?.toString() ??
          dataMap['trace_id']?.toString() ??
          response['traceId']?.toString() ??
          '',
      toolsUsed: tools,
      evaluationScore: _readDouble(response['evaluation_score']),
      safetyStatus: response['safety_status']?.toString() ?? 'allowed',
      latencyMs: _readInt(response['latency_ms']),
      tokenUsage: tokenUsage,
      raw: response,
    );
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
