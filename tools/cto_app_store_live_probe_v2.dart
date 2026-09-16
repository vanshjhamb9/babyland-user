/// CTO live probe v2 — creates throwaway user, probes all remediation routes.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

const candidates = <String>[
  'http://164.52.197.176/api/v1',
  'https://api-babyland.duckdns.org/api/v1',
  'https://api-babyland.duckdns.org/api',
];

final results = <Map<String, dynamic>>[];

void record(String id, {required bool pass, required String detail, int? status}) {
  results.add({'id': id, 'pass': pass, 'status': status, 'detail': detail});
  stdout.writeln(
      '[${pass ? 'PASS' : 'FAIL'}] $id${status != null ? ' HTTP $status' : ''} — $detail');
}

Future<http.Response> req(
  String base,
  String method,
  String path, {
  Map<String, String>? headers,
  Object? body,
}) {
  final uri = Uri.parse('$base$path');
  final h = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...?headers,
  };
  final encoded = body == null ? null : jsonEncode(body);
  final future = switch (method) {
    'GET' => http.get(uri, headers: h),
    'POST' => http.post(uri, headers: h, body: encoded),
    'DELETE' => http.delete(uri, headers: h, body: encoded),
    'PUT' => http.put(uri, headers: h, body: encoded),
    _ => throw UnsupportedError(method),
  };
  return future.timeout(const Duration(seconds: 30));
}

Map<String, dynamic>? asMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.isNotEmpty) {
    try {
      final d = jsonDecode(raw);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
  }
  return null;
}

String? extractToken(Map<String, dynamic>? data) {
  if (data == null) return null;
  final nested = asMap(data['data']);
  final t = data['token'] ??
      data['authToken'] ??
      nested?['authToken'] ??
      nested?['token'];
  final s = t?.toString();
  return (s != null && s.isNotEmpty) ? s : null;
}

Future<void> main() async {
  stdout.writeln('=== Babyland CTO live probe v2 ===\n');

  String? workingBase;
  for (final base in candidates) {
    try {
      final res = await req(base, 'GET', '/plans/public');
      final ok = res.statusCode > 0 && res.statusCode < 500;
      record('reachability.$base',
          pass: ok,
          status: res.statusCode,
          detail: 'len=${res.body.length}');
      if (ok && workingBase == null) workingBase = base;
    } catch (e) {
      record('reachability.$base', pass: false, detail: '$e');
    }
  }

  if (workingBase == null) {
    // try plans/get-all without auth
    for (final base in candidates) {
      try {
        final res = await req(base, 'GET', '/plans/get-all');
        if (res.statusCode > 0 && res.statusCode != 502) {
          workingBase = base;
          record('reachability.fallback.$base',
              pass: true, status: res.statusCode, detail: 'using this base');
          break;
        }
      } catch (_) {}
    }
  }

  if (workingBase == null) {
    stdout.writeln('No reachable API base.');
    _summary();
    exit(2);
  }

  final base = workingBase!;
  stdout.writeln('\nUsing base: $base\n');

  final rnd = Random().nextInt(9999999);
  final email = 'cto.probe.$rnd@babyland.test';
  final password = 'ProbeTest1!$rnd';
  // Indian-looking optional phone for backends that still validate format when present
  final phone = '98${(10000000 + rnd % 89999999).toString().padLeft(8, '0')}';

  // Probe unauthenticated route existence first (404 = missing)
  for (final entry in [
    ['POST', '/subscriptions/apple/verify'],
    ['POST', '/moderation/reports'],
    ['GET', '/users/blocked'],
    ['DELETE', '/users/me'],
    ['POST', '/users/000000000000000000000001/block'],
  ]) {
    final method = entry[0];
    final path = entry[1];
    final res = await req(base, method, path, body: method == 'GET' ? null : {});
    final exists = res.statusCode != 404;
    record('route.exists $method $path',
        pass: exists,
        status: res.statusCode,
        detail: exists
            ? 'present (auth may be required)'
            : 'MISSING 404 — backend contract not deployed');
  }

  // Signup WITHOUT phone
  {
    final res = await req(base, 'POST', '/auth/signup', body: {
      'email': email,
      'password': password,
    });
    final data = asMap(res.body);
    final msg = (data?['message'] ?? '').toString().toLowerCase();
    final phoneRequired = msg.contains('phone') &&
        (msg.contains('required') ||
            msg.contains('validation') ||
            msg.contains('must'));
    record('signup.no_phone',
        pass: (res.statusCode == 200 || res.statusCode == 201) &&
            data?['success'] != false &&
            !phoneRequired,
        status: res.statusCode,
        detail: 'msg=${data?['message']} success=${data?['success']} body=${res.body.length > 240 ? res.body.substring(0, 240) : res.body}');
  }

  // Signup WITH phone (fallback account for auth tests)
  final email2 = 'cto.probe.phone.$rnd@babyland.test';
  String? token;
  {
    final res = await req(base, 'POST', '/auth/signup', body: {
      'email': email2,
      'password': password,
      'phone': phone,
    });
    final data = asMap(res.body);
    record('signup.with_phone',
        pass: res.statusCode == 200 ||
            res.statusCode == 201 ||
            data?['success'] == true ||
            (data?['message']?.toString().toLowerCase().contains('exist') ??
                false),
        status: res.statusCode,
        detail: 'msg=${data?['message']}');
  }

  // Try login both accounts + optional OTP path leftover
  for (final e in [email, email2]) {
    final res = await req(base, 'POST', '/auth/login-with-password', body: {
      'email': e,
      'password': password,
    });
    final data = asMap(res.body);
    final t = extractToken(data);
    record('login.$e',
        pass: t != null,
        status: res.statusCode,
        detail: 'msg=${data?['message']} token=${t != null}');
    token ??= t;
  }

  // Also try verify-otp style won't work without firebase — skip

  if (token == null) {
    // Some backends return token on signup
    stdout.writeln(
        '\nNo login token — authenticated probes limited. Checking if signup returned token already.');
  }

  if (token != null) {
    final auth = {
      'Authorization': 'Bearer $token',
      'auth-token': token!,
    };

    // subscriptions/me
    {
      final res = await req(base, 'GET', '/subscriptions/me', headers: auth);
      final data = asMap(res.body);
      final payload = asMap(data?['data']) ?? data;
      record('subscriptions.me',
          pass: res.statusCode == 200,
          status: res.statusCode,
          detail:
              'success=${data?['success']} status=${payload?['status']} expiresAt=${payload?['expiresAt'] ?? payload?['endDate']} keys=${payload?.keys.take(15).toList()}');
    }

    // apple verify fake
    {
      final res = await req(base, 'POST', '/subscriptions/apple/verify',
          headers: auth,
          body: {
            'platform': 'ios',
            'productId': 'babyland_pro_monthly',
            'transactionId': 'CTO_FAKE_$rnd',
            'receiptData': 'fake-receipt',
            'source': 'app_store',
          });
      final data = asMap(res.body);
      final exists = res.statusCode != 404;
      final acceptedFake =
          res.statusCode == 200 && data?['success'] == true;
      record('apple.verify.route',
          pass: exists,
          status: res.statusCode,
          detail: 'msg=${data?['message']}');
      record('apple.verify.rejects_fake',
          pass: exists && !acceptedFake,
          status: res.statusCode,
          detail: acceptedFake
              ? 'CRITICAL: fake receipt activated Pro'
              : 'fake not activated (good)');
    }

    // plans
    {
      final res = await req(base, 'GET', '/plans/get-all', headers: auth);
      final data = asMap(res.body);
      record('plans.get-all',
          pass: res.statusCode == 200,
          status: res.statusCode,
          detail: 'success=${data?['success']}');
    }

    // communities + report
    String? postId;
    String? otherUserId;
    {
      final res = await req(base, 'GET', '/communities/all', headers: auth);
      final data = asMap(res.body);
      final nested = asMap(data?['data']);
      final posts = nested?['posts'] ?? data?['posts'];
      if (posts is List && posts.isNotEmpty && posts.first is Map) {
        final p = Map<String, dynamic>.from(posts.first as Map);
        postId = p['_id']?.toString();
        final u = p['userId'];
        if (u is Map) otherUserId = (u['_id'] ?? u['id'])?.toString();
        if (u is String) otherUserId = u;
      }
      record('communities.all',
          pass: res.statusCode == 200,
          status: res.statusCode,
          detail: 'postId=$postId otherUserId=$otherUserId');
    }

    {
      final res = await req(base, 'POST', '/moderation/reports',
          headers: auth,
          body: {
            'targetType': 'post',
            'targetId': postId ?? '000000000000000000000000',
            'reason': 'spam',
            'notes': 'CTO probe',
          });
      final data = asMap(res.body);
      record('moderation.reports',
          pass: res.statusCode != 404 && res.statusCode < 500,
          status: res.statusCode,
          detail: 'success=${data?['success']} msg=${data?['message']}');
    }

    final blockId = otherUserId ?? '000000000000000000000001';
    {
      final res =
          await req(base, 'POST', '/users/$blockId/block', headers: auth);
      final data = asMap(res.body);
      record('users.block',
          pass: res.statusCode != 404 && res.statusCode < 500,
          status: res.statusCode,
          detail: 'success=${data?['success']} msg=${data?['message']}');
    }
    {
      final res = await req(base, 'GET', '/users/blocked', headers: auth);
      final data = asMap(res.body);
      record('users.blocked',
          pass: res.statusCode == 200,
          status: res.statusCode,
          detail: 'success=${data?['success']} body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
    }
    {
      final res =
          await req(base, 'DELETE', '/users/$blockId/block', headers: auth);
      record('users.unblock',
          pass: res.statusCode != 404 && res.statusCode < 500,
          status: res.statusCode,
          detail: 'ok');
    }

    // profile update without phone field
    {
      final res = await req(base, 'PUT', '/users/profile-update',
          headers: auth, body: {'name': 'CTO Probe User'});
      final data = asMap(res.body);
      final msg = (data?['message'] ?? '').toString().toLowerCase();
      final phoneReq = msg.contains('phone') && msg.contains('required');
      record('profile.update.no_phone_field',
          pass: !phoneReq && res.statusCode != 404 && res.statusCode < 500,
          status: res.statusCode,
          detail: 'msg=${data?['message']}');
    }

    // delete throwaway account
    {
      final res = await req(base, 'DELETE', '/users/me', headers: auth);
      final data = asMap(res.body);
      final ok = res.statusCode == 200 ||
          res.statusCode == 204 ||
          data?['success'] == true;
      record('users.me.delete',
          pass: ok,
          status: res.statusCode,
          detail: 'success=${data?['success']} msg=${data?['message']}');
    }
  }

  _summary();
  exit(results.any((r) => r['pass'] != true) ? 1 : 0);
}

void _summary() {
  stdout.writeln('\n=== SUMMARY ===');
  final pass = results.where((r) => r['pass'] == true).length;
  final fail = results.where((r) => r['pass'] != true).length;
  stdout.writeln('PASS $pass / FAIL $fail / TOTAL ${results.length}');
  for (final r in results.where((r) => r['pass'] != true)) {
    stdout.writeln('  - ${r['id']}: HTTP ${r['status']} — ${r['detail']}');
  }
}
