import 'dart:io';
import 'dart:math';

/// Tracks estimated UTC offset between device clock and server time.
///
/// Used for slot expiry and join windows — do not rely on [DateTime.now] alone
/// for healthcare-grade scheduling (skewed devices, rooted clocks).
class ServerTimeService {
  ServerTimeService._();
  static final ServerTimeService instance = ServerTimeService._();

  /// `serverUtc - deviceUtc` when last recorded (smoothed).
  Duration _offset = Duration.zero;
  int _samples = 0;

  Duration get offset => _offset;

  /// Monotonic wall reference for logging (not used for business rules).
  DateTime? _lastUpdateUtc;

  DateTime? get lastUpdateUtc => _lastUpdateUtc;

  /// Best-effort "now" in server-UTC space using smoothed offset.
  DateTime nowServerUtc() => DateTime.now().toUtc().add(_offset);

  /// Record offset from HTTP `Date` header (RFC 7231).
  void recordFromHttpDateHeader(String? dateHeader) {
    if (dateHeader == null || dateHeader.isEmpty) return;
    final serverUtc = _parseRfc1123Date(dateHeader);
    if (serverUtc == null) return;
    _recordOffset(serverUtc, DateTime.now().toUtc());
  }

  /// If API embeds `serverTime` / `server_time` ISO string in JSON body.
  void recordFromServerTimeIso(String? iso) {
    if (iso == null || iso.isEmpty) return;
    final serverUtc = DateTime.tryParse(iso);
    if (serverUtc == null) return;
    _recordOffset(serverUtc.toUtc(), DateTime.now().toUtc());
  }

  void _recordOffset(DateTime serverUtc, DateTime deviceUtc) {
    final sample = serverUtc.difference(deviceUtc);
    // Exponential moving average to reduce jitter.
    if (_samples == 0) {
      _offset = sample;
    } else {
      const alpha = 0.35;
      _offset = Duration(
        milliseconds: (alpha * sample.inMilliseconds +
                (1 - alpha) * _offset.inMilliseconds)
            .round(),
      );
    }
    _samples = min(_samples + 1, 100);
    _lastUpdateUtc = DateTime.now().toUtc();
  }

  /// Parse e.g. "Sun, 06 Nov 1994 08:49:37 GMT"
  DateTime? _parseRfc1123Date(String raw) {
    try {
      return HttpDate.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }
}
