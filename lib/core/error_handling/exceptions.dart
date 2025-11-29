/// Base exception for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// No internet connection exception
class NoConnectionException extends NetworkException {
  const NoConnectionException({
    super.message = 'No internet connection',
    super.code = 'NO_CONNECTION',
  });
}

/// Server unreachable exception
class ServerUnreachableException extends NetworkException {
  const ServerUnreachableException({
    super.message = 'Server is unreachable',
    super.code = 'SERVER_UNREACHABLE',
  });
}

/// Request timeout exception
class TimeoutException extends NetworkException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.code = 'TIMEOUT',
  });
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Invalid credentials exception
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException({
    super.message = 'Invalid username or password',
    super.code = 'INVALID_CREDENTIALS',
  });
}

/// Session expired exception
class SessionExpiredException extends AuthException {
  const SessionExpiredException({
    super.message = 'Your session has expired',
    super.code = 'SESSION_EXPIRED',
  });
}

/// Unauthorized exception
class UnauthorizedException extends AuthException {
  const UnauthorizedException({
    super.message = 'You are not authorized to perform this action',
    super.code = 'UNAUTHORIZED',
  });
}

/// Server/API exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });
}

/// Validation exception
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.errors,
  });
}

/// Cache exception
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// Storage exception
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.originalError,
  });
}

/// Sync exception
class SyncException extends AppException {
  const SyncException({
    required super.message,
    super.code = 'SYNC_ERROR',
    super.originalError,
  });
}

/// Conflict exception for sync conflicts
class ConflictException extends SyncException {
  final Map<String, dynamic>? localData;
  final Map<String, dynamic>? remoteData;

  const ConflictException({
    super.message = 'Data conflict detected',
    super.code = 'CONFLICT',
    this.localData,
    this.remoteData,
  });
}

/// Odoo-specific exceptions (Odoo 18 support)
class OdooException extends ServerException {
  final String? odooErrorType;
  final Map<String, dynamic>? context;

  const OdooException({
    required super.message,
    super.code,
    super.statusCode,
    super.originalError,
    this.odooErrorType,
    this.context,
  });
}

/// Odoo validation error
class OdooValidationException extends OdooException {
  final Map<String, String>? fieldErrors;

  const OdooValidationException({
    required super.message,
    super.code = 'ODOO_VALIDATION_ERROR',
    super.odooErrorType = 'ValidationError',
    this.fieldErrors,
    super.context,
  });
}

/// Odoo access rights error
class OdooAccessException extends OdooException {
  final String? model;
  final String? operation;

  const OdooAccessException({
    required super.message,
    super.code = 'ODOO_ACCESS_ERROR',
    super.odooErrorType = 'AccessError',
    this.model,
    this.operation,
    super.context,
  });
}

/// Odoo user error (business logic error)
class OdooUserException extends OdooException {
  const OdooUserException({
    required super.message,
    super.code = 'ODOO_USER_ERROR',
    super.odooErrorType = 'UserError',
    super.context,
  });
}

/// Odoo warning
class OdooWarningException extends OdooException {
  final String? warningTitle;

  const OdooWarningException({
    required super.message,
    super.code = 'ODOO_WARNING',
    super.odooErrorType = 'Warning',
    this.warningTitle,
    super.context,
  });
}

/// Odoo missing error (record not found)
class OdooMissingException extends OdooException {
  final String? model;
  final int? recordId;

  const OdooMissingException({
    required super.message,
    super.code = 'ODOO_MISSING_ERROR',
    super.odooErrorType = 'MissingError',
    this.model,
    this.recordId,
    super.context,
  });
}
