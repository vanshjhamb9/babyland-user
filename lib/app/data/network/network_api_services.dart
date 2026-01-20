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
          }
          options.headers['Accept'] = 'application/json';
          // final curl = _toCurl(options);
          // pt('CURL 👉\n$curl');
          // handler.next(options);
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
        formData.fields.add(MapEntry(key, value.toString()));
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

      pt("Uploading fields: ${formData.fields}");
      pt("Uploading file: ${formData.files.first.key}");

      Response response = await _dio.post(url, data: formData);
      pt("Multipart response: ${response.data}");

      return _handleResponse(response);
    } catch (e, st) {
      pt("Multipart error: $e\n$st");
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

  String _toCurl(RequestOptions options) {
    final buffer = StringBuffer();

    buffer.write('curl -X ${options.method} \\\n');

    options.headers.forEach((key, value) {
      buffer.write('  -H "$key: $value" \\\n');
    });

    if (options.data != null) {
      final data = options.data is String
          ? options.data
          : jsonEncode(options.data);
      buffer.write("  -d '$data' \\\n");
    }

    final uri = options.uri.toString();
    buffer.write('  "$uri"');

    return buffer.toString();
  }

}
