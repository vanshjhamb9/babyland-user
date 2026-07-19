import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/auth/session_invalidation.dart';
import 'package:babyland/core/runtime/token_refresh_reconcile_hook.dart';
import 'package:babyland/core/time/server_time_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../widgets/print.dart';
import 'end_points.dart';

class NetworkApiServices {
  static final NetworkApiServices _instance = NetworkApiServices._internal();
  factory NetworkApiServices() => _instance;

  NetworkApiServices._internal() {
    _dio = Dio(
      BaseOptions(
        // Note: baseUrl is NOT set here because EndPoints already contain full URLs
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String token = await SecureStorage.getToken() ?? "";
          final isPublic = isAuthPublicEndpoint(options.uri);
          if (kDebugMode) {
            pt('Request with auth: ${token.isNotEmpty}');
            pt('Public auth endpoint: $isPublic');
            pt('Auth token (masked): ${token.isNotEmpty ? _maskSensitive(token) : "(none)"}');
          }
          if (!isPublic && token.isNotEmpty) {
            options.headers['auth-token'] = token;
            options.headers['Authorization'] = "Bearer $token";
          }
          options.headers['Accept'] = 'application/json';

          // ✅ GLOBAL ENUM FIX: Handle Map<String, dynamic> payload
          if (options.data is Map<String, dynamic>) {
            final data = options.data as Map<String, dynamic>;

            // Fix top-level cycleType
            if (data.containsKey('cycleType') && data['cycleType'] == 'pregnancy') {
              pt("⚠️ Intercepted invalid cycleType 'pregnancy' in Map. Correcting to 'regular'...");
              data['cycleType'] = 'regular';
            }

            // Fix nested cycleType in any child map
            data.forEach((key, value) {
              if (value is Map<String, dynamic> &&
                  value.containsKey('cycleType') &&
                  value['cycleType'] == 'pregnancy') {
                pt("⚠️ Intercepted nested invalid cycleType 'pregnancy' in key '$key'. Correcting...");
                value['cycleType'] = 'regular';
              }
            });
          }

          // ✅ GLOBAL ENUM FIX: Handle JSON String payload
          if (options.data is String) {
            try {
              final decoded = jsonDecode(options.data as String);
              if (decoded is Map<String, dynamic>) {
                bool fixed = false;
                if (decoded.containsKey('cycleType') &&
                    decoded['cycleType'] == 'pregnancy') {
                  decoded['cycleType'] = 'regular';
                  fixed = true;
                  pt("⚠️ Intercepted invalid cycleType 'pregnancy' in JSON String. Correcting...");
                }
                if (fixed) {
                  options.data = jsonEncode(decoded);
                }
              }
            } catch (_) {}
          }

          if (kDebugMode) {
            pt("➡️ REQUEST ${options.method}: ${options.uri}");
            pt("➡️ REQUEST HEADERS: ${options.headers}");
            pt("➡️ REQUEST DATA: ${_sanitizeBodyForLogs(options.data)}");
          }

          // Contract: JSON requests must send Content-Type: application/json
          if (options.data is Map || options.data is List) {
            options.headers['Content-Type'] = 'application/json';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) async {
          if (kDebugMode) {
            pt("✅ RESPONSE ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}");
            pt("✅ RESPONSE BODY: ${response.data}");
          }
          if (response.statusCode == 401) {
            final requestOptions = response.requestOptions;
            final uri = requestOptions.uri;
            final alreadyRefreshed =
                requestOptions.extra['didAuthRefresh'] == true;

            if (!isAuthPublicEndpoint(uri) && !alreadyRefreshed) {
              final refreshToken = await SecureStorage.getRefreshToken() ?? '';
              if (refreshToken.isNotEmpty) {
                final refreshed = await _refreshTokens(refreshToken);
                final newAccessToken = refreshed?['authToken'];
                final newRefreshToken = refreshed?['refreshToken'];

                if (newAccessToken != null &&
                    newAccessToken.isNotEmpty &&
                    newRefreshToken != null &&
                    newRefreshToken.isNotEmpty) {
                  await SecureStorage.saveToken(newAccessToken);
                  await SecureStorage.saveRefreshToken(newRefreshToken);
                  await sl.authService.saveToken(newAccessToken);
                  await sl.authService.saveRefreshToken(newRefreshToken);
                  TokenRefreshReconcileHook.instance.notifyAccessTokenRefreshed();

                  requestOptions.extra['didAuthRefresh'] = true;
                  requestOptions.headers['auth-token'] = newAccessToken;
                  requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';

                  final retryResponse = await _dio.fetch(requestOptions);
                  handler.resolve(retryResponse);
                  return;
                }
              }
              unawaited(performUnauthorizedLogout());
            }
          }
          ServerTimeService.instance.recordFromHttpDateHeader(
            response.headers.value('date'),
          );
          _recordServerTimeFromBody(response.data);
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (kDebugMode) {
            pt("❌ DIO ERROR: ${error.type} ${error.requestOptions.method} ${error.requestOptions.uri}");
            pt("❌ DIO MESSAGE: ${error.message}");
            pt("❌ DIO REQUEST DATA: ${_sanitizeBodyForLogs(error.requestOptions.data)}");
            pt("❌ DIO RESPONSE CODE: ${error.response?.statusCode}");
            pt("❌ DIO RESPONSE BODY: ${error.response?.data}");
          }
          if (error.response?.statusCode == 401) {
            final requestOptions = error.requestOptions;
            final uri = requestOptions.uri;
            final alreadyRefreshed =
                requestOptions.extra['didAuthRefresh'] == true;

            if (!isAuthPublicEndpoint(uri) && !alreadyRefreshed) {
              final refreshToken = await SecureStorage.getRefreshToken() ?? '';
              if (refreshToken.isNotEmpty) {
                final refreshed = await _refreshTokens(refreshToken);
                final newAccessToken = refreshed?['authToken'];
                final newRefreshToken = refreshed?['refreshToken'];

                if (newAccessToken != null &&
                    newAccessToken.isNotEmpty &&
                    newRefreshToken != null &&
                    newRefreshToken.isNotEmpty) {
                  await SecureStorage.saveToken(newAccessToken);
                  await SecureStorage.saveRefreshToken(newRefreshToken);
                  await sl.authService.saveToken(newAccessToken);
                  await sl.authService.saveRefreshToken(newRefreshToken);
                  TokenRefreshReconcileHook.instance.notifyAccessTokenRefreshed();

                  requestOptions.extra['didAuthRefresh'] = true;
                  requestOptions.headers['auth-token'] = newAccessToken;
                  requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';

                  final retryResponse = await _dio.fetch(requestOptions);
                  handler.resolve(retryResponse);
                  return;
                }
              }
            }

            if (!isAuthPublicEndpoint(uri)) {
              unawaited(performUnauthorizedLogout());
            }
          }

          if (kDebugMode) {
            pt("API Error: ${error.message}");
          }
          return handler.next(error);
        },
      ),
    );
  }

  String _maskSensitive(String value) {
    if (value.isEmpty) return value;
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  dynamic _sanitizeBodyForLogs(dynamic body) {
    if (body is Map) {
      final sanitized = Map<String, dynamic>.from(body);
      const sensitiveKeys = <String>{
        'password',
        'confirmPassword',
        'authToken',
        'refreshToken',
        'token',
        'idToken',
      };
      for (final key in sensitiveKeys) {
        if (sanitized[key] != null) {
          sanitized[key] = _maskSensitive(sanitized[key].toString());
        }
      }
      return sanitized;
    }
    return body;
  }

  Future<Map<String, String>?>? _refreshInFlight;

  Future<Map<String, String>?> _refreshTokens(String refreshToken) async {
    if (_refreshInFlight != null) return _refreshInFlight;

    _refreshInFlight = () async {
      // Uses unified /api/v1/auth/refresh endpoint only.
      final refreshResponse = await _dio.post(
        EndPoints.authRefresh,
        data: <String, dynamic>{'refreshToken': refreshToken},
      );

      if (refreshResponse.statusCode != 200) {
        final fallbackResponse = await _dio.post(
          EndPoints.authsRefresh,
          data: <String, dynamic>{'refreshToken': refreshToken},
        );

        if (fallbackResponse.statusCode != 200) return null;

        final body = fallbackResponse.data;
        final data = body is Map ? body['data'] : null;
        final newAccessToken =
            data is Map ? data['authToken']?.toString() : null;
        final newRefreshToken =
            data is Map ? data['refreshToken']?.toString() : null;
        if (newAccessToken == null || newAccessToken.isEmpty) return null;
        if (newRefreshToken == null || newRefreshToken.isEmpty) return null;
        return <String, String>{
          'authToken': newAccessToken,
          'refreshToken': newRefreshToken,
        };
      }

      final body = refreshResponse.data;
      final data = body is Map ? body['data'] : null;
      final newAccessToken =
          data is Map ? data['authToken']?.toString() : null;
      final newRefreshToken =
          data is Map ? data['refreshToken']?.toString() : null;
      if (newAccessToken == null || newAccessToken.isEmpty) return null;
      if (newRefreshToken == null || newRefreshToken.isEmpty) return null;

      return <String, String>{
        'authToken': newAccessToken,
        'refreshToken': newRefreshToken,
      };
    }();

    try {
      return await _refreshInFlight;
    } finally {
      _refreshInFlight = null;
    }
  }

  late final Dio _dio;

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
      {Object? data,
        Map<String, dynamic>? params,
        Map<String, dynamic>? headers}) async {
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
        // ✅ Block invalid cycleType in multipart
        if (key == 'cycleType' && value == 'pregnancy') {
          pt("⚠️ Intercepted invalid cycleType 'pregnancy' in multipart POST. Correcting...");
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
      pt("Multipart POST error: $e\n$st");
      rethrow;
    }
  }

  Future<dynamic> putApiMultiPart(
      String url, Map<String, dynamic> fields, Map<String, File> files) async {
    try {
      FormData formData = FormData();

      fields.forEach((key, value) {
        // ✅ Block invalid cycleType in multipart
        if (key == 'cycleType' && value == 'pregnancy') {
          pt("⚠️ Intercepted invalid cycleType 'pregnancy' in multipart PUT. Correcting...");
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
    if (kDebugMode) {
      pt('API Response == ${response.statusCode}');
    }
    if ([200, 201, 202, 204, 400, 401, 403, 404, 409, 422]
        .contains(response.statusCode)) {
      final data = response.data;
      if (data == null) {
        return <String, dynamic>{};
      }
      return data;
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

void _recordServerTimeFromBody(dynamic data) {
  void pick(Map<dynamic, dynamic> m) {
    final st = m['serverTime'] ?? m['server_time'];
    if (st is String) {
      ServerTimeService.instance.recordFromServerTimeIso(st);
    }
    final nested = m['data'];
    if (nested is Map<dynamic, dynamic>) {
      pick(nested);
    }
  }

  if (data is Map<dynamic, dynamic>) pick(data);
}