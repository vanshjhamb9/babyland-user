/// Base exception for all app-specific errors.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

/// Thrown when a network request fails.
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });
}

/// Thrown when authentication fails or token is invalid.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Thrown when the AI service returns an error.
class AIServiceException extends AppException {
  final String? traceId;

  const AIServiceException(
    super.message, {
    this.traceId,
    super.code,
    super.originalError,
  });
}

/// Thrown when cached data is stale or not found.
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Thrown when validation fails.
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
  });
}

/// Thrown when health tracker operations fail.
class HealthTrackerException extends AppException {
  const HealthTrackerException(super.message, {super.code, super.originalError});
}

/// Thrown when subscription is required but not purchased.
class SubscriptionException extends AppException {
  const SubscriptionException(
    super.message, {
    super.code,
    super.originalError,
  });
}