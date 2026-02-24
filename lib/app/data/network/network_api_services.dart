import 'dart:convert';
import 'dart:io';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import '../../widgets/print.dart';
import 'end_points.dart';

class NetworkApiServices {
  // ---------- SINGLETON IMPLEMENTATION ----------
  static final NetworkApiServices _instance = NetworkApiServices._internal();
  factory NetworkApiServices() => _instance;

  // Private constructor
  NetworkApiServices._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String token = await SecureStorage.getToken() ?? "";
          pt("token...... $token");
          if (token.isNotEmpty) {
            options.headers['auth-token'] = token;
            options.headers['Authorization'] = "Bearer $token";
          }
          options.headers['Accept'] = 'application/json';

          // ✅ GLOBAL ENUM FIX: Intercept any payload containing 'cycleType': 'pregnancy'
          // and reset it to 'regular' before sending to backend.
          if (options.data is Map<String, dynamic>) {
            final data = options.data as Map<String, dynamic>;
            if (data.containsKey('cycleType') && data['cycleType'] == 'pregnancy') {
              pt("Intercepted invalid cycleType 'pregnancy'. Correcting to 'regular'...");
              data['cycleType'] = 'regular';
            }
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) {
          pt("API Error: ${error.message}");
          return handler.next(error);
        },
      ),
    );
  }

  // ---------- VARIABLES ----------
  final String _baseUrl = EndPoints.baseUrl;
  late final Dio _dio;

  // ---------- API METHODS ----------
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: params);
      return _handleResponse(response);
    } catch (e, st) {
      pt("GET error: $e\n$st");
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint,
      {Object? data, Map<String, dynamic>? params, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: params,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } catch (e, st) {
      pt("POST error: $e\n$st");
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return _handleResponse(response);
    } catch (e, st) {
      pt("PUT error: $e\n$st");
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.delete(endpoint, data: data);
      return _handleResponse(response);
    } catch (e, st) {
      pt("DELETE error: $e\n$st");
      rethrow;
    }
  }

  Future<dynamic> postApiMultiPart(
      String url, Map<String, dynamic> fields, Map<String, File> files) async {
    try {
      FormData formData = FormData();

      fields.forEach((key, value) {
        // ✅ Ensure no multipart field sends 'pregnancy' as cycleType
        if (key == 'cycleType' && value == 'pregnancy') {
          formData.fields.add(const MapEntry('cycleType', 'regular'));
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      for (var entry in files.entries) {
        formData.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              entry.value.path,
              filename: entry.value.path.split('/').last,
            ),
          ),
        );
      }

      Response response = await _dio.post(url, data: formData);
      return _handleResponse(response);
    } catch (e, st) {
      pt("Multipart error: $e\n$st");
      rethrow;
    }
  }

  Future<dynamic> putApiMultiPart(
      String url, Map<String, dynamic> fields, Map<String, File> files) async {
    try {
      FormData formData = FormData();

      fields.forEach((key, value) {
        // ✅ Ensure no multipart field sends 'pregnancy' as cycleType
        if (key == 'cycleType' && value == 'pregnancy') {
          formData.fields.add(const MapEntry('cycleType', 'regular'));
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      for (var entry in files.entries) {
        formData.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              entry.value.path,
              filename: entry.value.path.split('/').last,
            ),
          ),
        );
      }

      Response response = await _dio.put(url, data: formData);
      return _handleResponse(response);
    } catch (e, st) {
      pt("Multipart PUT error: $e\n$st");
      rethrow;
    }
  }

  dynamic _handleResponse(Response response) {
    pt('API Response == ${response.statusCode}\n${response.data}');
    if ([200, 201, 202, 204, 400, 401, 403, 404, 409, 422,].contains(response.statusCode)) {
      return response.data;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Unexpected status code: ${response.statusCode}',
      );
    }
  }
}
