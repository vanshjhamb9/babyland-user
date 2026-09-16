/// CTO live-backend probe for App Store remediation contracts.
/// Does NOT permanently delete a known account unless --allow-delete-me is passed
/// with a throwaway token; delete is validated via a fresh signup account.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

const baseUrl = 'http://164.52.197.176/api/v1';

final results = <Map<String, dynamic>>[];

void record(String id, {required bool pass, required String detail, int? status}) {
  results.add({
    'id': id,
    'pass': pass,
    'status': status,
    'detail': detail,
  });
  final mark = pass ? 'PASS' : 'FAIL';
  stdout.writeln('[$mark] $id${status != null ? ' HTTP $status' : ''} — $detail');
}

Future<http.Response> req(
  String method,
  String path, {
  Map<String, String>? headers,
  Object? body,
}) async {
  final uri = Uri.parse('$baseUrl$path');
  final h = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...?headers,
  };
  final encoded = body == null ? null : jsonEncode(body);
  switch (method) {
    case 'GET':
      return http.get(uri, headers: h).timeout(const Duration(seconds: 25));
    case 'POST':
      return http
          .post(uri, headers: h, body: encoded)
          .timeout(const Duration(seconds: 25));
    case 'DELETE':
      return http
          .delete(uri, headers: h, body: encoded)
          .timeout(const Duration(seconds: 25));
    case 'PUT':
      return http
          .put(uri, headers: h, body: encoded)
          .timeout(const Duration(seconds: 25));
    default:
      throw UnsupportedError(method);
  }
}

Map<String, dynamic>? asMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

Future<void> main(List<String> args) async {
  stdout.writeln('=== Babyland CTO live API probe ===');
  stdout.writeln('Base: $baseUrl\n');

  // ── 1) Login ──────────────────────────────────────────────
  String? token;
  String? userId;
  for (final cred in [
    {'email': 'nim@nim.com', 'password': '12345678'},
  ]) {
    final res = await req('POST', '/auth/login-with-password', body: cred);
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final nested = asMap(data?['data']);
    final t = (data?['token'] ??
            data?['authToken'] ??
            nested?['authToken'] ??
            nested?['token'])
        ?.toString();
    if (res.statusCode == 200 && t != null && t.isNotEmpty) {
      token = t;
      userId = (nested?['user'] is Map
              ? (nested!['user'] as Map)['_id'] ?? (nested['user'] as Map)['id']
              : nested?['userId'])
          ?.toString();
      record('auth.login',
          pass: true,
          status: res.statusCode,
          detail: 'Logged in as ${cred['email']}');
      break;
    }
    record('auth.login',
        pass: false,
        status: res.statusCode,
        detail: 'body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
  }

  if (token == null) {
    // Try alternate path used in older scripts
    final dio = Dio(BaseOptions(validateStatus: (s) => s != null && s < 600));
    final alt = await dio.post(
      'http://164.52.197.176/api/auths/login-with-password',
      data: {'email': 'nim@nim.com', 'password': '12345678'},
    );
    final data = asMap(alt.data);
    final nested = asMap(data?['data']);
    final t = (nested?['authToken'] ?? data?['authToken'])?.toString();
    if (t != null && t.isNotEmpty) {
      token = t;
      record('auth.login.alt',
          pass: true,
          status: alt.statusCode,
          detail: 'Logged in via /api/auths/login-with-password');
    } else {
      record('auth.login.alt',
          pass: false,
          status: alt.statusCode,
          detail: '${alt.data}');
    }
  }

  if (token == null) {
    stdout.writeln('\nFATAL: cannot authenticate — aborting authenticated probes.');
    _printSummary();
    exit(2);
  }

  final auth = {
    'Authorization': 'Bearer $token',
    'auth-token': token!,
  };

  // ── 2) GET /subscriptions/me ──────────────────────────────
  {
    final res = await req('GET', '/subscriptions/me', headers: auth);
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final ok = res.statusCode == 200;
    final payload = data?['data'] ?? data;
    final payloadMap = asMap(payload);
    final status = payloadMap?['status'] ??
        payloadMap?['subscriptionStatus'] ??
        payloadMap?['paymentStatus'];
    final expires = payloadMap?['expiresAt'] ??
        payloadMap?['endDate'] ??
        payloadMap?['validUntil'];
    record('subscriptions.me',
        pass: ok,
        status: res.statusCode,
        detail:
            'success=${data?['success']} status=$status expiresAt=$expires keys=${payloadMap?.keys.take(12).toList()}');
  }

  // ── 3) POST /subscriptions/apple/verify (expect route exists) ─
  {
    final res = await req('POST', '/subscriptions/apple/verify', headers: auth, body: {
      'platform': 'ios',
      'productId': 'babyland_pro_monthly',
      'transactionId': 'CTO_PROBE_FAKE_${DateTime.now().millisecondsSinceEpoch}',
      'receiptData': 'fake-receipt-for-route-probe',
      'source': 'app_store',
    });
    final body = res.body;
    final data = asMap(jsonDecode(body.isEmpty ? '{}' : body));
    // Route exists if NOT 404. Valid verify of fake receipt should fail 4xx with message.
    final exists = res.statusCode != 404;
    final sensible = res.statusCode == 400 ||
        res.statusCode == 401 ||
        res.statusCode == 403 ||
        res.statusCode == 422 ||
        (res.statusCode == 200 && data?['success'] == false) ||
        (res.statusCode == 200 && data?['success'] == true);
    record('subscriptions.apple.verify.route',
        pass: exists,
        status: res.statusCode,
        detail: exists
            ? 'Route present. success=${data?['success']} msg=${data?['message'] ?? body.substring(0, body.length.clamp(0, 160))}'
            : 'Endpoint missing (404)');
    record('subscriptions.apple.verify.reject_fake',
        pass: exists &&
            !(res.statusCode == 200 && data?['success'] == true),
        status: res.statusCode,
        detail: (res.statusCode == 200 && data?['success'] == true)
            ? 'CRITICAL: accepted fake receipt — must verify with Apple'
            : 'Fake receipt not activated (expected). sensible=$sensible msg=${data?['message']}');
  }

  // ── 4) Plans ──────────────────────────────────────────────
  {
    final res = await req('GET', '/plans/get-all', headers: auth);
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final plans = data?['plans'] ??
        (data?['data'] is Map ? (data!['data'] as Map)['plans'] : data?['data']);
    final count = plans is List ? plans.length : 0;
    record('plans.get-all',
        pass: res.statusCode == 200,
        status: res.statusCode,
        detail: 'planCount=$count');
  }

  // ── 5) Moderation report ──────────────────────────────────
  String? samplePostId;
  {
    final res = await req('GET', '/communities/all', headers: auth);
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final nested = asMap(data?['data']);
    final posts = nested?['posts'] ?? data?['posts'];
    if (posts is List && posts.isNotEmpty && posts.first is Map) {
      samplePostId = (posts.first as Map)['_id']?.toString();
    }
    record('communities.all',
        pass: res.statusCode == 200,
        status: res.statusCode,
        detail: 'samplePostId=$samplePostId');
  }

  {
    final res = await req('POST', '/moderation/reports', headers: auth, body: {
      'targetType': 'post',
      'targetId': samplePostId ?? '000000000000000000000000',
      'reason': 'spam',
      'notes': 'CTO live probe — ignore',
    });
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final exists = res.statusCode != 404;
    final ok = exists &&
        (res.statusCode == 200 ||
            res.statusCode == 201 ||
            res.statusCode == 400 ||
            res.statusCode == 422);
    record('moderation.reports',
        pass: ok,
        status: res.statusCode,
        detail: exists
            ? 'success=${data?['success']} msg=${data?['message']}'
            : 'Endpoint missing (404)');
  }

  // ── 6) Block / blocked list ───────────────────────────────
  final blockTarget = '000000000000000000000001';
  {
    final res =
        await req('POST', '/users/$blockTarget/block', headers: auth);
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final exists = res.statusCode != 404;
    record('users.block',
        pass: exists && res.statusCode != 500,
        status: res.statusCode,
        detail: exists
            ? 'success=${data?['success']} msg=${data?['message']}'
            : 'Endpoint missing (404)');
  }
  {
    final res = await req('GET', '/users/blocked', headers: auth);
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final exists = res.statusCode != 404;
    record('users.blocked.list',
        pass: exists && res.statusCode == 200,
        status: res.statusCode,
        detail: exists
            ? 'success=${data?['success']} bodyKeys=${data?.keys.toList()} rawLen=${res.body.length}'
            : 'Endpoint missing (404)');
  }
  {
    final res =
        await req('DELETE', '/users/$blockTarget/block', headers: auth);
    final exists = res.statusCode != 404;
    record('users.unblock',
        pass: exists && res.statusCode != 500,
        status: res.statusCode,
        detail: exists ? 'ok' : 'Endpoint missing (404)');
  }

  // ── 7) Phone optional signup ──────────────────────────────
  final rnd = Random().nextInt(999999);
  final email = 'cto.probe.$rnd@example.com';
  final password = 'ProbeTest1!$rnd';
  {
    final res = await req('POST', '/auth/signup', body: {
      'email': email,
      'password': password,
      // intentionally no phone
    });
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final msg = (data?['message'] ?? '').toString().toLowerCase();
    final phoneRequired = msg.contains('phone') &&
        (msg.contains('required') || msg.contains('validation'));
    final ok = res.statusCode == 200 ||
        res.statusCode == 201 ||
        (data?['success'] == true);
    record('auth.signup.phone_optional',
        pass: ok && !phoneRequired,
        status: res.statusCode,
        detail: phoneRequired
            ? 'REJECTED: phone still required — $msg'
            : 'success=${data?['success']} msg=${data?['message']}');
  }

  // Login throwaway if created
  String? throwawayToken;
  {
    final res = await req('POST', '/auth/login-with-password', body: {
      'email': email,
      'password': password,
    });
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final nested = asMap(data?['data']);
    throwawayToken = (data?['token'] ??
            data?['authToken'] ??
            nested?['authToken'] ??
            nested?['token'])
        ?.toString();
    record('auth.login.throwaway',
        pass: throwawayToken != null && throwawayToken!.isNotEmpty,
        status: res.statusCode,
        detail: 'throwaway login after phone-less signup');
  }

  // ── 8) DELETE /users/me on throwaway only ─────────────────
  if (throwawayToken != null && throwawayToken!.isNotEmpty) {
    final res = await req('DELETE', '/users/me', headers: {
      'Authorization': 'Bearer $throwawayToken',
      'auth-token': throwawayToken!,
    });
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final exists = res.statusCode != 404;
    final ok = exists &&
        (res.statusCode == 200 ||
            res.statusCode == 204 ||
            data?['success'] == true);
    record('users.me.delete',
        pass: ok,
        status: res.statusCode,
        detail: exists
            ? 'success=${data?['success']} msg=${data?['message']}'
            : 'Endpoint missing (404)');
  } else {
    record('users.me.delete',
        pass: false,
        detail: 'Skipped — throwaway account not available to safely delete');
  }

  // ── 9) Profile update without phone (soft) ────────────────
  {
    final res = await req('PUT', '/users/profile-update', headers: auth, body: {
      'name': 'CTO Probe',
    });
    final data = asMap(jsonDecode(res.body.isEmpty ? '{}' : res.body));
    final msg = (data?['message'] ?? '').toString().toLowerCase();
    final phoneRequired = msg.contains('phone') && msg.contains('required');
    record('users.profile_update.phone_optional',
        pass: res.statusCode != 404 && !phoneRequired && res.statusCode != 500,
        status: res.statusCode,
        detail: 'success=${data?['success']} msg=${data?['message']}');
  }

  stdout.writeln('\nuserId=$userId');
  _printSummary();
  final failed = results.where((r) => r['pass'] != true).length;
  exit(failed == 0 ? 0 : 1);
}

void _printSummary() {
  stdout.writeln('\n=== SUMMARY ===');
  final pass = results.where((r) => r['pass'] == true).length;
  final fail = results.where((r) => r['pass'] != true).length;
  stdout.writeln('PASS $pass / FAIL $fail / TOTAL ${results.length}');
  for (final r in results.where((r) => r['pass'] != true)) {
    stdout.writeln('  - ${r['id']}: ${r['detail']}');
  }
}
