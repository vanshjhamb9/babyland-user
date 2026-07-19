/// Represents a single message in the AI chat conversation.
class AiMessageModel {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final String? traceId;
  final List<String> toolsUsed;
  final double? evaluationScore;
  final String? safetyStatus;
  final int? latencyMs;
  final MessageFeedback? feedback;
  final bool isStreaming;

  const AiMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.traceId,
    this.toolsUsed = const [],
    this.evaluationScore,
    this.safetyStatus,
    this.latencyMs,
    this.feedback,
    this.isStreaming = false,
  });

  AiMessageModel copyWith({
    String? content,
    MessageFeedback? feedback,
    bool? isStreaming,
  }) {
    return AiMessageModel(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      traceId: traceId,
      toolsUsed: toolsUsed,
      evaluationScore: evaluationScore,
      safetyStatus: safetyStatus,
      latencyMs: latencyMs,
      feedback: feedback ?? this.feedback,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
        'traceId': traceId,
        'toolsUsed': toolsUsed,
        'evaluationScore': evaluationScore,
        'safetyStatus': safetyStatus,
        'latencyMs': latencyMs,
        'feedback': feedback?.name,
      };

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      role: json['role'] == 'assistant' ? MessageRole.assistant : MessageRole.user,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      traceId: json['traceId']?.toString(),
      toolsUsed: (json['toolsUsed'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      evaluationScore: (json['evaluationScore'] as num?)?.toDouble(),
      safetyStatus: json['safetyStatus']?.toString(),
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
      feedback: json['feedback'] != null
          ? MessageFeedback.values.firstWhere(
              (e) => e.name == json['feedback'],
              orElse: () => MessageFeedback.none,
            )
          : null,
    );
  }
}

enum MessageRole { user, assistant }

enum MessageFeedback { positive, negative, none }
