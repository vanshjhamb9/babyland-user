import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Ring buffer of structured lifecycle / sync logs for production debugging.
class AppAuditLog {
  AppAuditLog._();
  static final AppAuditLog instance = AppAuditLog._();

  static const int maxEntries = 400;

  final Queue<Map<String, Object?>> _entries = Queue();

  void log(
    String event, {
    String? component,
    String? reason,
    String? traceId,
    String? consultationId,
    String? merchantTransactionId,
    String? bookingId,
    int? durationMs,
    String? outcome,
  }) {
    final row = <String, Object?>{
      't': DateTime.now().toUtc().toIso8601String(),
      'event': event,
      if (component != null) 'component': component,
      if (reason != null) 'reason': reason,
      if (traceId != null) 'traceId': traceId,
      if (consultationId != null) 'consultationId': consultationId,
      if (merchantTransactionId != null)
        'merchantTransactionId': merchantTransactionId,
      if (bookingId != null) 'bookingId': bookingId,
      if (durationMs != null) 'durationMs': durationMs,
      if (outcome != null) 'outcome': outcome,
    };
    while (_entries.length >= maxEntries) {
      _entries.removeFirst();
    }
    _entries.addLast(row);
    if (kDebugMode) {
      debugPrint('[AUDIT] $row');
    }
  }

  List<Map<String, Object?>> snapshot() => List.from(_entries);

  String exportAsText() {
    final buf = StringBuffer();
    for (final e in _entries) {
      buf.writeln(e.toString());
    }
    return buf.toString();
  }

  void clear() => _entries.clear();
}
