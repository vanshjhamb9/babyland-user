import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io';

void main() async {
  final dio = Dio();
  const baseUrl = "https://api-babyland.duckdns.org/api";

  print("--- Logging in as nim@nim.com ---");
  final loginRes = await dio.post("$baseUrl/auths/login-with-password", data: {
    "email": "nim@nim.com",
    "password": "12345678"
  });
  final authToken = loginRes.data['data']?['authToken'];
  final userId = loginRes.data['data']?['user']?['_id'];
  print("UserId: $userId\n");

  final options = Options(headers: {"auth-token": authToken, "Content-Type": "application/json"});

  // Use real image file from artifacts
  final dummyFile = File(r'C:\Users\telig\.gemini\antigravity\brain\94a05eae-4459-431f-9fa3-d0ea0eee7fc8\media__1771565023229.png');

  print("--- Submitting profile update with image ---");
  try {
    FormData formData = FormData.fromMap({
      "name": "Nim User",
      "phone": "1234567890",
      "photo": await MultipartFile.fromFile(dummyFile.path, filename: "dummy_image.jpg")
    });

    final res = await dio.put("$baseUrl/users/profile-update", 
      data: formData,
      options: Options(headers: {"auth-token": authToken}),
    );
    print("profileUpdate response: ${jsonEncode(res.data)}\n");
  } catch (e) {
    if (e is DioException) {
      print("profileUpdate ERROR ${e.response?.statusCode}: ${e.response?.data}\n");
    } else {
      print("profileUpdate ERROR: $e");
    }
  }

  // clean up
  if (await dummyFile.exists()) await dummyFile.delete();
}
