import 'dart:convert';
import 'dart:io';

const baseUrl = "https://baby-land-node-servers.onrender.com/api";

void main() async {
  final client = HttpClient();

  // 1. Login
  print('Logging in...');
  final loginUrl = Uri.parse('$baseUrl/auths/login-with-password');
  final loginRequest = await client.postUrl(loginUrl);
  loginRequest.headers.contentType = ContentType.json;
  loginRequest.write(jsonEncode({
    "email": "nim@nim.com",
    "password": "12345678"
  }));
  final loginResponse = await loginRequest.close();
  final loginBody = await loginResponse.transform(utf8.decoder).join();
  
  if (loginResponse.statusCode != 200 && loginResponse.statusCode != 201) {
    print('Login failed: ${loginResponse.statusCode}');
    print(loginBody);
    return;
  }

  print('Login response: $loginBody');

  final loginData = jsonDecode(loginBody);
  final token = loginData['data']?['authToken'];
  
  if (token == null) {
    print('Token is null. Check response structure.');
    return;
  }
  
  // Regex to match a standard JWT token structure (3 parts separated by dots)
  final tokenRegex = RegExp(r'eyJ[a-zA-Z0-9\-_]*\.[a-zA-Z0-9\-_]*\.[a-zA-Z0-9\-_]*');
  final match = tokenRegex.firstMatch(token.toString());
  
  if (match == null) {
    print('Could not find valid JWT token in response.');
    return;
  }
  
  final cleanToken = match.group(0)!;
  print('Token cleaned. Length: ${cleanToken.length}');

  // 2. GET API Test
  print('\nTesting GET /pregnancys/dashboard/predict...');
  final getUrl = Uri.parse('$baseUrl/pregnancys/dashboard/predict');
  final getRequest = await client.getUrl(getUrl);
  getRequest.headers.add('Authorization', 'Bearer $cleanToken');
  final getResponse = await getRequest.close();
  final getBody = await getResponse.transform(utf8.decoder).join();
  print('GET Status: ${getResponse.statusCode}');
  print('GET Response: $getBody');

  // 3. POST API Test
  print('\nTesting POST /pregnancys/dashboard/predict...');
  final postUrl = Uri.parse('$baseUrl/pregnancys/dashboard/predict');
  final postRequest = await client.postUrl(postUrl);
  postRequest.headers.add('Authorization', 'Bearer $token');
  // postRequest.headers.contentType = ContentType.json; // sending empty body or whatever
  final postResponse = await postRequest.close();
  final postBody = await postResponse.transform(utf8.decoder).join();
  print('POST Status: ${postResponse.statusCode}');
  print('POST Response: $postBody');
  
  client.close();
}
