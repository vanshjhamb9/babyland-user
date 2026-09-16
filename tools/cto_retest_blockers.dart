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
    'PUT' => http.put(uri, headers: h, body: encoded),
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

String? tokenOf(Map<String, dynamic>? data) {
  final nested = data?['data'] is Map
      ? Map<String, dynamic>.from(data!['data'] as Map)
      : null;
  return (data?['token'] ??
          data?['authToken'] ??
          nested?['authToken'] ??
          nested?['token'])
      ?.toString();
}

String? userIdOf(Map<String, dynamic>? body) {
  final data = body?['data'] is Map
      ? Map<String, dynamic>.from(body!['data'] as Map)
      : body;
  final userWrap = data?['user'] is Map
      ? Map<String, dynamic>.from(data!['user'] as Map)
      : data;
  final user = userWrap?['user'] is Map
      ? Map<String, dynamic>.from(userWrap!['user'] as Map)
      : userWrap;
  return (user?['_id'] ?? user?['id'] ?? data?['_id'])?.toString();
}

Future<void> main() async {
  final rnd = Random().nextInt(89999999) + 10000000;
  final password = 'ProbeTest${rnd}Aa';

  stdout.writeln('=== Multiple phone-less signups ===');
  for (var i = 1; i <= 3; i++) {
    final email = 'cto.nophone.$rnd.$i@mailinator.com';
    final res = await req('POST', '/auth/signup',
        body: {'email': email, 'password': password});
    final data = map(res.body);
    stdout.writeln(
        '[$i] ${res.statusCode} success=${data?['success']} msg=${data?['message']} code=${data?['code']}');
  }

  stdout.writeln('\n=== Block with real users + profile no-phone ===');
  final phoneA = '98${rnd.toString().padLeft(8, '0')}';
  final phoneB = '97${rnd.toString().padLeft(8, '0')}';
  final emailA = 'cto.a2.$rnd@mailinator.com';
  final emailB = 'cto.b2.$rnd@mailinator.com';
  final emailC = 'cto.c2.$rnd@mailinator.com'; // no phone

  await req('POST', '/auth/signup',
      body: {'email': emailA, 'password': password, 'phone': phoneA});
  await req('POST', '/auth/signup',
      body: {'email': emailB, 'password': password, 'phone': phoneB});
  final noPhoneSignup = await req('POST', '/auth/signup',
      body: {'email': emailC, 'password': password});
  stdout.writeln(
      'no-phone signup: ${noPhoneSignup.statusCode} ${noPhoneSignup.body}');

  final loginA = await req('POST', '/auth/login-with-password',
      body: {'email': emailA, 'password': password});
  final loginB = await req('POST', '/auth/login-with-password',
      body: {'email': emailB, 'password': password});
  final loginC = await req('POST', '/auth/login-with-password',
      body: {'email': emailC, 'password': password});
  final tokenA = tokenOf(map(loginA.body));
  final tokenB = tokenOf(map(loginB.body));
  final tokenC = tokenOf(map(loginC.body));
  stdout.writeln(
      'tokens A=${tokenA != null} B=${tokenB != null} C=${tokenC != null}');

  final authA = {'Authorization': 'Bearer $tokenA', 'auth-token': '$tokenA'};
  final authB = {'Authorization': 'Bearer $tokenB', 'auth-token': '$tokenB'};
  final authC = {'Authorization': 'Bearer $tokenC', 'auth-token': '$tokenC'};

  final guA = await req('GET', '/users/getUser', headers: authA);
  final guB = await req('GET', '/users/getUser', headers: authB);
  final idA = userIdOf(map(guA.body));
  final idB = userIdOf(map(guB.body));
  stdout.writeln('idA=$idA idB=$idB');

  final block = await req('POST', '/users/$idB/block', headers: authA);
  stdout.writeln('block: ${block.statusCode} ${block.body}');
  final blocked = await req('GET', '/users/blocked', headers: authA);
  stdout.writeln('blocked: ${blocked.statusCode} ${blocked.body}');
  final unblock = await req('DELETE', '/users/$idB/block', headers: authA);
  stdout.writeln('unblock: ${unblock.statusCode} ${unblock.body}');

  if (tokenC != null) {
    final prof = await req('PUT', '/users/profile-update',
        headers: authC, body: {'name': 'No Phone CTO'});
    stdout.writeln('profile no-phone user: ${prof.statusCode} ${prof.body}');
  }

  // cleanup
  if (tokenA != null) await req('DELETE', '/users/me', headers: authA);
  if (tokenB != null) await req('DELETE', '/users/me', headers: authB);
  if (tokenC != null) await req('DELETE', '/users/me', headers: authC);
  stdout.writeln('done');
}
