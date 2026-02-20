import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  const baseUrl = "https://api-babyland.duckdns.org/api";

  print("--- Logging in as nom@nom.com ---");
  final loginRes = await dio.post("$baseUrl/auths/login-with-password", data: {
    "email": "nom@nom.com",
    "password": "12345678"
  });
  final authToken = loginRes.data['data']?['authToken'];
  final userId = loginRes.data['data']?['user']?['_id'];
  print("UserId: $userId\n");

  final options = Options(headers: {"auth-token": authToken, "Content-Type": "application/json"});

  try {
      final res = await dio.post("$baseUrl/menstruals/add-cycle", 
        data: {
          "startDate": "2026-02-10",
          "endDate": "2026-02-15",
          "notes": "Added from App"
        },
        options: options,
      );
    print("AI Insights Response: ${jsonEncode(res.data)}\n");
  } catch (e) {
    if (e is DioException) {
      print("AI Insights ERROR ${e.response?.statusCode}: ${e.response?.data}\n");
    } else {
      print("AI Insights ERROR: $e");
    }
  }
}
