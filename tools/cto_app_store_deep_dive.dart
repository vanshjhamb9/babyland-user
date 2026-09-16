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

Map<String, dynamic>? map(String body) {
  try {
    final d = jsonDecode(body);
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
  final phoneA = '98${rnd.toString().padLeft(8, '0')}';
  final phoneB = '97${rnd.toString().padLeft(8, '0')}';
  final emailA = 'cto.a.$rnd@mailinator.com';
  final emailB = 'cto.b.$rnd@mailinator.com';
  final emailNoPhone = 'cto.nophone.$rnd@mailinator.com';

  stdout.writeln('=== signup NO phone ===');
  var res = await req('POST', '/auth/signup',
      body: {'email': emailNoPhone, 'password': password});
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== signup A with phone $phoneA ===');
  res = await req('POST', '/auth/signup',
      body: {'email': emailA, 'password': password, 'phone': phoneA});
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== signup B with phone $phoneB ===');
  res = await req('POST', '/auth/signup',
      body: {'email': emailB, 'password': password, 'phone': phoneB});
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== login A ===');
  res = await req('POST', '/auth/login-with-password',
      body: {'email': emailA, 'password': password});
  stdout.writeln('${res.statusCode} ${res.body}\n');
  final tokenA = tokenOf(map(res.body));
  if (tokenA == null) {
    stdout.writeln('FATAL no tokenA');
    exit(2);
  }
  final authA = {'Authorization': 'Bearer $tokenA', 'auth-token': tokenA};

  stdout.writeln('=== login B ===');
  res = await req('POST', '/auth/login-with-password',
      body: {'email': emailB, 'password': password});
  final tokenB = tokenOf(map(res.body));
  stdout.writeln('tokenB=${tokenB != null} ${res.statusCode}\n');
  final authB = {
    'Authorization': 'Bearer $tokenB',
    'auth-token': tokenB ?? '',
  };

  stdout.writeln('=== subscriptions/me ===');
  res = await req('GET', '/subscriptions/me', headers: authA);
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== apple/verify fake ===');
  res = await req('POST', '/subscriptions/apple/verify', headers: authA, body: {
    'platform': 'ios',
    'productId': 'babyland_pro_monthly',
    'transactionId': 'FAKE_$rnd',
    'receiptData': 'fake',
    'source': 'app_store',
  });
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== getUser A/B ===');
  res = await req('GET', '/users/getUser', headers: authA);
  final idA = userIdOf(map(res.body));
  stdout.writeln('A ${res.statusCode} id=$idA');
  res = await req('GET', '/users/getUser', headers: authB);
  final idB = userIdOf(map(res.body));
  stdout.writeln('B ${res.statusCode} id=$idB\n');

  stdout.writeln('=== A blocks B ($idB) ===');
  res = await req('POST', '/users/$idB/block', headers: authA);
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== blocked list ===');
  res = await req('GET', '/users/blocked', headers: authA);
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== B creates post ===');
  res = await req('POST', '/communities/add', headers: authB, body: {
    'message': 'cto probe $rnd',
  });
  stdout.writeln('${res.statusCode} ${res.body}\n');
  final postMap = map(res.body);
  final postId = (postMap?['data'] is Map
          ? (postMap!['data'] as Map)['_id']
          : postMap?['_id'] ??
              (postMap?['data'] is Map
                  ? (postMap!['data'] as Map)['post']
                  : null))
      ?.toString();
  stdout.writeln('postId=$postId');

  stdout.writeln('=== report ===');
  res = await req('POST', '/moderation/reports', headers: authA, body: {
    'targetType': 'post',
    'targetId': postId ?? '000000000000000000000000',
    'reason': 'spam',
  });
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== profile-update omit phone ===');
  res = await req('PUT', '/users/profile-update',
      headers: authA, body: {'name': 'CTO A'});
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== profile-update empty phone ===');
  res = await req('PUT', '/users/profile-update',
      headers: authA, body: {'name': 'CTO A', 'phone': ''});
  stdout.writeln('${res.statusCode} ${res.body}\n');

  stdout.writeln('=== unblock ===');
  res = await req('DELETE', '/users/$idB/block', headers: authA);
  stdout.writeln('${res.statusCode} ${res.body}\n');

  await req('DELETE', '/users/me', headers: authA);
  await req('DELETE', '/users/me', headers: authB);
  stdout.writeln('done');
}
