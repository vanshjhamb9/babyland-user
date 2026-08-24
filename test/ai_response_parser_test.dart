import 'package:babyland/core/ai/ai_response_parser.dart';
import 'package:babyland/core/error/app_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = AiResponseParser();

  test('parses reply without using envelope message', () {
    final parsed = parser.parseChatResponse({
      'success': true,
      'reply': 'Hello, I am IRA.',
      'message': 'ok',
      'trace_id': 't1',
    });
    expect(parsed.reply, 'Hello, I am IRA.');
    expect(parsed.traceId, 't1');
  });

  test('throws on success false instead of using error message as reply', () {
    expect(
      () => parser.parseChatResponse({
        'success': false,
        'message':
            'I encountered an error processing your message. Please try again.',
      }),
      throwsA(
        isA<AIServiceException>().having(
          (e) => e.code,
          'code',
          'AI_GATEWAY_ERROR',
        ),
      ),
    );
  });

  test('does not treat envelope message as chat reply', () {
    final parsed = parser.parseChatResponse({
      'message':
          'I encountered an error processing your message. Please try again.',
    });
    expect(parsed.reply, isEmpty);
  });

  test('parses production aichats data.aiResponse', () {
    final parsed = parser.parseChatResponse({
      'success': true,
      'data': {
        'conversationId': 'c1',
        'userMessage': 'hello',
        'aiResponse': 'Hi, I am IRA. How can I help?',
      },
    });
    expect(parsed.reply, 'Hi, I am IRA. How can I help?');
  });
}
