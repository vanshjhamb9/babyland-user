import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/session_invalidation.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../error/app_exceptions.dart';
import '../error/error_handler.dart';
import '../services/auth_service.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';

/// Production-grade API client with retry logic, token refresh, and interceptors.
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final AuthService _authService;

  ApiClient._({required AuthService authService})
      : _authService = authService {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_authService),
      if (kDebugMode) _LoggingInterceptor(),
      _RetryInterceptor(_dio),
      _AuthRefreshInterceptor(_dio, _authService),
      _UnauthorizedInterceptor(),
    ]);
  }

  factory ApiClient({required AuthService authService}) {
    _instance ??= ApiClient._(authService: authService);
    return _instance!;
  }

  /// Exposes dio for services that need direct access (e.g., streaming).
  Dio get dio => _dio;

  // ─── HTTP Methods ───────────────────────────────────────

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? params,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: params,
        options: timeout != null
            ? Options(receiveTimeout: timeout, sendTimeout: timeout)
            : null,
      );
      return _handleResponse(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st);
      throw ErrorHandler.handle(e);
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
    Duration? timeout,
  }) async {
    try {
      final mergedHeaders = <String, dynamic>{};
      if (headers != null) {
        mergedHeaders.addAll(headers);
      }
      // Contract: JSON requests should specify Content-Type.
      if (data is Map || data is List) {
        mergedHeaders.putIfAbsent('Content-Type', () => 'application/json');
      }
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: params,
        options: Options(
          headers: mergedHeaders,
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );
      return _handleResponse(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st);
      throw ErrorHandler.handle(e);
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: timeout != null
            ? Options(receiveTimeout: timeout, sendTimeout: timeout)
            : null,
      );
      return _handleResponse(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st);
      throw ErrorHandler.handle(e);
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.delete(endpoint, data: data);
      return _handleResponse(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st);
      throw ErrorHandler.handle(e);
    }
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, dynamic> fields,
    required Map<String, File> files,
  }) async {
    try {
      final formData = FormData();

      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      for (final entry in files.entries) {
        formData.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              entry.value.path,
              filename: entry.value.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await _dio.post(endpoint, data: formData);
      return _handleResponse(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st);
      throw ErrorHandler.handle(e);
    }
  }

  Future<dynamic> putMultipart(
    String endpoint, {
    required Map<String, dynamic> fields,
    required Map<String, File> files,
  }) async {
    try {
      final formData = FormData();

      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      for (final entry in files.entries) {
        formData.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              entry.value.path,
              filename: entry.value.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await _dio.put(endpoint, data: formData);
      return _handleResponse(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st);
      throw ErrorHandler.handle(e);
    }
  }

  // ─── Response Handling ──────────────────────────────────

  dynamic _handleResponse(Response response) {
    final statusCode = response.statusCode ?? 0;

    if ([200, 201, 202, 204].contains(statusCode)) {
      final data = response.data;
      if (data == null) {
        return <String, dynamic>{};
      }
      return data;
    }

    if (statusCode == 401) {
      throw const AuthException('Unauthorized', code: 'UNAUTHORIZED');
    }

    // Return data for handled error codes (400, 403, 404, 409, 422)
    if ([400, 403, 404, 409, 422].contains(statusCode)) {
      return response.data ?? <String, dynamic>{};
    }

    throw NetworkException(
      'Server error: $statusCode',
      statusCode: statusCode,
      code: 'HTTP_$statusCode',
    );
  }
}

// ─── Auth Interceptor ─────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final AuthService _authService;

  _AuthInterceptor(this._authService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Public endpoints (login/signup/refresh) must not include auth headers.
    if (!isAuthPublicEndpoint(options.uri)) {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['auth-token'] = token;
        options.headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          log('[API-CLIENT-AUDIT] ${options.method} ${options.path}: token attached (${token.length} chars)');
        }
      } else {
        if (kDebugMode) {
          log('[API-CLIENT-AUDIT] ⚠️ ${options.method} ${options.path}: NO TOKEN! AuthService token is null/empty');
          final secureToken = await SecureStorage.getToken();
          log('[API-CLIENT-AUDIT] SecureStorage token: ${secureToken != null && secureToken.isNotEmpty ? "present (${secureToken.length} chars)" : "NULL/EMPTY"}');
        }
      }
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

/// 401 refresh + retry once.
class _AuthRefreshInterceptor extends Interceptor {
  final Dio _dio;
  final AuthService _authService;

  _AuthRefreshInterceptor(this._dio, this._authService);

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.statusCode != 401) {
      handler.next(response);
      return;
    }

    final requestOptions = response.requestOptions;
    final uri = requestOptions.uri;

    final alreadyTried = requestOptions.extra['authRefreshAttempted'] == true;

    // Public auth endpoints shouldn't be refreshed/retried.
    if (isAuthPublicEndpoint(uri) || alreadyTried) {
      handler.next(response);
      return;
    }

    final refreshToken = await _authService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(response);
      return;
    }

    requestOptions.extra['authRefreshAttempted'] = true;

    try {
      final refreshResponse = await _dio.post(
        ApiEndpoints.authRefresh,
        data: <String, dynamic>{'refreshToken': refreshToken},
      );

      final actualRefreshResponse = refreshResponse.statusCode == 200
          ? refreshResponse
          : await _dio.post(
              ApiEndpoints.authsRefresh,
              data: <String, dynamic>{'refreshToken': refreshToken},
            );

      if (actualRefreshResponse.statusCode != 200) {
        handler.next(response);
        return;
      }

      final body = actualRefreshResponse.data;
      final data = body is Map ? body['data'] : null;
      final newAccessToken = data is Map ? data['authToken']?.toString() : null;
      final newRefreshToken = data is Map ? data['refreshToken']?.toString() : null;

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        handler.next(response);
        return;
      }

      // Keep both architectures in sync.
      await _authService.saveToken(newAccessToken);
      await _authService.saveRefreshToken(newRefreshToken);
      await SecureStorage.saveToken(newAccessToken);
      await SecureStorage.saveRefreshToken(newRefreshToken);

      requestOptions.headers['auth-token'] = newAccessToken;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra['authRefreshApplied'] = true;

      final retryResponse = await _dio.fetch(requestOptions);
      handler.resolve(retryResponse);
      return;
    } catch (_) {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // For this client, 401 is usually handled in onResponse.
    handler.next(err);
  }
}

/// 401 → clear session and send user to login (public auth routes skipped).
class _UnauthorizedInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 401) {
      final uri = response.requestOptions.uri;
      if (!isAuthPublicEndpoint(uri)) {
        if (kDebugMode) {
          log('[API-CLIENT-UNAUTH] ⚠️ 401 on ${uri.path} — performing logout');
        }
        unawaited(performUnauthorizedLogout());
      } else {
        if (kDebugMode) {
          log('[API-CLIENT-UNAUTH] 401 on public endpoint ${uri.path} — skipping logout');
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final uri = err.requestOptions.uri;
      if (!isAuthPublicEndpoint(uri)) {
        if (kDebugMode) {
          log('[API-CLIENT-UNAUTH] ⚠️ onError 401 on ${uri.path} — performing logout');
        }
        unawaited(performUnauthorizedLogout());
      }
    }
    handler.next(err);
  }
}

// ─── Retry Interceptor (exponential backoff) ──────────────

class _RetryInterceptor extends Interceptor {
  final Dio _dio;

  _RetryInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry = _isRetryable(err);
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (shouldRetry && retryCount < AppConstants.maxRetryAttempts) {
      final delay = AppConstants.retryBaseDelay * (1 << retryCount);
      await Future.delayed(delay);

      err.requestOptions.extra['retryCount'] = retryCount + 1;

      if (kDebugMode) {
        log('Retrying request (${retryCount + 1}/${AppConstants.maxRetryAttempts}): '
            '${err.requestOptions.path}');
      }

      try {
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Fall through to handler.next
      }
    }

    handler.next(err);
  }

  bool _isRetryable(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

// ─── Debug Logging Interceptor ────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('→ ${options.method} ${options.baseUrl}${options.path}',
        name: 'API');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('← ${response.statusCode} ${response.requestOptions.path}',
        name: 'API');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('✗ ${err.type} ${err.requestOptions.path}: ${err.message}',
        name: 'API');
    handler.next(err);
  }
}
