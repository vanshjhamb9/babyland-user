import 'dart:convert';

/// Debug-session NDJSON (session 64f774). On device, lines appear in logcat as `AGENT_DEBUG {...}`.
void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
  String runId = 'pre-fix',
}) {
  final line = jsonEncode({
    'sessionId': '64f774',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // ignore: avoid_print
  print('AGENT_DEBUG $line');
}
