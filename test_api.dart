import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  const baseUrl = "https://api-babyland.duckdns.org/api";

  // 1. Fresh login
  print("--- Logging in as nim@nim.com ---");
  final loginRes = await dio.post("$baseUrl/auths/login-with-password", data: {
    "email": "nim@nim.com",
    "password": "12345678"
  });
  final authToken = loginRes.data['data']?['authToken'];
  final userId = loginRes.data['data']?['user']?['_id'];
  print("Token: ${authToken?.toString().substring(0, 20)}...");
  print("UserId: $userId\n");

  final options = Options(headers: {"auth-token": authToken, "Content-Type": "application/json"});

  // 2. Submit pregnancy info
  print("--- Submitting pregnancy info ---");
  try {
    final res = await dio.post("$baseUrl/pregnancys/info", 
      data: {
        "userId": userId,
        "pregnancyStartDate": "2025-12-05",
      },
      options: options,
    );
    print("pregnancyInfo response: ${jsonEncode(res.data)}\n");
  } catch (e) {
    if (e is DioException) {
      print("pregnancyInfo ERROR ${e.response?.statusCode}: ${e.response?.data}\n");
    }
  }

  // 3. Get pregnancy dashboard
  print("--- Getting pregnancy dashboard ---");
  try {
    final res = await dio.get("$baseUrl/pregnancys/dashboard/predict", options: options);
    print("dashboard response: ${jsonEncode(res.data)}\n");
  } catch (e) {
    if (e is DioException) {
      print("dashboard ERROR ${e.response?.statusCode}: ${e.response?.data}\n");
    }
  }
}
