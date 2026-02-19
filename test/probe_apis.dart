import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const baseUrl = 'https://baby-land-node-servers.onrender.com/api';
// Known doctor ID from original hardcoded endpoint
const doctorId = '68e0177aca35a4f118eed184';

String trunc(String s, [int n = 400]) =>
    s.length <= n ? s : '${s.substring(0, n)}…';

void main() async {
  // 1. Login
  print('→ Logging in…');
  final loginResp = await http.post(
    Uri.parse('$baseUrl/auths/login-with-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'nim@nim.com', 'password': '12345678'}),
  );
  final loginJson = jsonDecode(loginResp.body) as Map<String, dynamic>;
  if (loginJson['success'] != true) {
    print('❌ Login failed: ${loginResp.body}');
    exit(1);
  }
  final token = loginJson['data']['authToken'] as String;
  print('✅ JWT obtained (${token.length} chars)\n');
  // Write token for test file
  File('${Directory.systemTemp.path}/babyland_token.txt').writeAsStringSync(token);

  // 2. Test slot endpoint
  print('→ GET /bookings/doctor/$doctorId/available-slots?date=2026-02-20');
  final slotResp = await http.get(
    Uri.parse('$baseUrl/bookings/doctor/$doctorId/available-slots?date=2026-02-20'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('  Status: ${slotResp.statusCode}');
  print('  Body:   ${trunc(slotResp.body)}');

  // 3. Test medical records list
  print('\n→ GET /medical-record/gettall');
  final mrResp = await http.get(
    Uri.parse('$baseUrl/medical-record/gettall'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('  Status: ${mrResp.statusCode}');
  print('  Body:   ${trunc(mrResp.body)}');

  // 4. Test medical record upload (no file → expect 4xx not 500)
  print('\n→ POST /medical-record/upload (empty)');
  final uploadReq = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/medical-record/upload'),
  )..headers['Authorization'] = 'Bearer $token';
  final uploadStream = await uploadReq.send();
  final uploadResp = await http.Response.fromStream(uploadStream);
  print('  Status: ${uploadResp.statusCode}');
  print('  Body:   ${trunc(uploadResp.body)}');

  print('\nDone. Token written to ${Directory.systemTemp.path}/babyland_token.txt');
}
