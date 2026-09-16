import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

const base = 'http://164.52.197.176/api/v1';

Future<http.Response> req(String method, String path,
    {Map<String, String>? headers, Object? body}) {
  final uri = Uri.parse('$base$path');
  final h = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...?headers,
  };
  final encoded = body == null ? null : jsonEncode(body);
  return switch (method) {
    'GET' => http.get(uri, headers: h),
    'POST' => http.post(uri, headers: h, body: encoded),
    'DELETE' => http.delete(uri, headers: h, body: encoded),
    _ => throw UnsupportedError(method),
  }.timeout(const Duration(seconds: 30));
}

Map<String, dynamic>? map(String b) {
  try {
    final d = jsonDecode(b);
    if (d is Map) return Map<String, dynamic>.from(d);
  } catch (_) {}
  return null;
}

Future<void> main() async {
  final rnd = Random().nextInt(89999999) + 10000000;
  final password = 'ProbeTest${rnd}Aa';
  final phone = '96${rnd.toString().padLeft(8, '0')}';
  final email = 'cto.sub.$rnd@mailinator.com';

  await req('POST', '/auth/signup',
      body: {'email': email, 'password': password, 'phone': phone});
  final login = await req('POST', '/auth/login-with-password',
      body: {'email': email, 'password': password});
  final data = map(login.body);
  final nested = data?['data'] is Map
      ? Map<String, dynamic>.from(data!['data'] as Map)
      : null;
  final token = (nested?['authToken'] ?? data?['authToken'])?.toString();
  final auth = {'Authorization': 'Bearer $token', 'auth-token': token!};

  stdout.writeln('1) me BEFORE verify');
  var res = await req('GET', '/subscriptions/me', headers: auth);
  stdout.writeln('${res.body}\n');

  stdout.writeln('2) getUser BEFORE verify');
  res = await req('GET', '/users/getUser', headers: auth);
  final u = map(res.body);
  // print subscription fields only
  stdout.writeln('${res.body.contains('subscription')}\n');
  final raw = res.body;
  final idx = raw.indexOf('subscription');
  if (idx >= 0) {
    stdout.writeln(raw.substring(idx, (idx + 200).clamp(0, raw.length)));
  }

  stdout.writeln('\n3) apple verify fake');
  res = await req('POST', '/subscriptions/apple/verify', headers: auth, body: {
    'platform': 'ios',
    'productId': 'babyland_pro_monthly',
    'transactionId': 'FAKE_$rnd',
    'receiptData': 'definitely-fake',
    'source': 'app_store',
  });
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('4) me AFTER verify');
  res = await req('GET', '/subscriptions/me', headers: auth);
  stdout.writeln('${res.body}\n');

  stdout.writeln('5) getUser AFTER verify (subscription fields)');
  res = await req('GET', '/users/getUser', headers: auth);
  final raw2 = res.body;
  for (final key in [
    'subscriptionActive',
    'subscriptionEndsAt',
    'subscriptionPlanId'
  ]) {
    final i = raw2.indexOf(key);
    if (i >= 0) {
      stdout.writeln(raw2.substring(i, (i + 80).clamp(0, raw2.length)));
    }
  }

  await req('DELETE', '/users/me', headers: auth);
}
