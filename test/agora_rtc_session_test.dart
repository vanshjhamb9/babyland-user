import 'package:babyland/core/consultation/agora_rtc_session_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgoraRtcSessionDto.parse', () {
    test('parses flat token + appId from backend payload', () {
      final dto = AgoraRtcSessionDto.parse({
        'success': true,
        'data': {
          'token': '006abc123',
          'channelName': 'consultation:test-id',
          'uid': 42,
          'consultationId': 'test-id',
          'sessionId': 'sess-1',
          'appId': '5575848aafdd4f32928274f4b71d84c0',
          'expireIn': 3600,
        },
      });

      expect(dto.token, '006abc123');
      expect(dto.channelName, 'consultation:test-id');
      expect(dto.uid, 42);
      expect(dto.consultationId, 'test-id');
      expect(dto.appId, '5575848aafdd4f32928274f4b71d84c0');
      expect(dto.isExpired, isFalse);
      expect(dto.expiresTooSoon, isFalse);
    });

    test('parses nested token object', () {
      final dto = AgoraRtcSessionDto.parse({
        'token': {'token': 'nested-token', 'expireIn': 7200},
        'channelName': 'consultation:abc',
        'uid': '99',
        'consultationId': 'abc',
      });

      expect(dto.token, 'nested-token');
      expect(dto.uid, 99);
      expect(dto.sessionId, 'abc');
    });

    test('rejects missing uid', () {
      expect(
        () => AgoraRtcSessionDto.parse({
          'token': 't',
          'channelName': 'c',
          'consultationId': 'id',
          'uid': 0,
        }),
        throwsFormatException,
      );
    });

    test('expiresTooSoon when expiry is within 15 seconds', () {
      final dto = AgoraRtcSessionDto(
        token: 't',
        channelName: 'c',
        uid: 1,
        consultationId: 'id',
        sessionId: 's',
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 5)),
      );
      expect(dto.expiresTooSoon, isTrue);
    });
  });
}
