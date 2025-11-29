import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Centralized error handler
class ErrorHandler {
  static final Logger _logger = Logger();

  /// Handle exception and return appropriate failure
  static Failure handleException(dynamic exception) {
    _logger.e('Handling exception', error: exception);

    if (exception is AppException) {
      return _handleAppException(exception);
    }

    if (exception is DioException) {
      return _handleDioException(exception);
    }

    if (exception is FormatException) {
      return const ServerFailure(
        message: 'Invalid response format',
        code: 'FORMAT_ERROR',
      );
    }

    return UnknownFailure(
      message: exception.toString(),
    );
  }

  /// Handle app-specific exceptions
  static Failure _handleAppException(AppException exception) {
    if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        code: exception.code,
      );
    }

    if (exception is NoConnectionException) {
      return const NoConnectionFailure();
    }

    if (exception is AuthException) {
      return AuthFailure(
        message: exception.message,
        code: exception.code,
      );
    }

    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        fieldErrors: exception.errors,
      );
    }

    if (exception is CacheException) {
      return CacheFailure(
        message: exception.message,
        code: exception.code,
      );
    }

    if (exception is SyncException) {
      return SyncFailure(
        message: exception.message,
        code: exception.code,
      );
    }

    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        code: exception.code,
        statusCode: exception.statusCode,
      );
    }

    return UnknownFailure(message: exception.message);
  }

  /// Handle Dio exceptions
  static Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          message: 'Connection timed out. Please try again.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.connectionError:
        return const NoConnectionFailure();

      case DioExceptionType.badResponse:
        return _handleBadResponse(exception.response);

      case DioExceptionType.cancel:
        return const NetworkFailure(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
      default:
        return NetworkFailure(
          message: exception.message ?? 'Network error occurred',
          code: 'NETWORK_ERROR',
        );
    }
  }

  /// Handle bad HTTP response
  static Failure _handleBadResponse(Response? response) {
    if (response == null) {
      return const ServerFailure(
        message: 'No response from server',
        code: 'NO_RESPONSE',
      );
    }

    final statusCode = response.statusCode;
    final data = response.data;

    String message = 'Server error';
    if (data is Map && data.containsKey('error')) {
      final error = data['error'];
      if (error is Map && error.containsKey('message')) {
        message = error['message'].toString();
      } else if (error is String) {
        message = error;
      }
    }

    switch (statusCode) {
      case 400:
        return ServerFailure(
          message: message,
          code: 'BAD_REQUEST',
          statusCode: statusCode,
        );

      case 401:
        return const AuthFailure(
          message: 'Authentication required',
          code: 'UNAUTHORIZED',
        );

      case 403:
        return const AuthFailure(
          message: 'Access denied',
          code: 'FORBIDDEN',
        );

      case 404:
        return ServerFailure(
          message: 'Resource not found',
          code: 'NOT_FOUND',
          statusCode: statusCode,
        );

      case 422:
        return ValidationFailure(
          message: message,
          code: 'VALIDATION_ERROR',
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerFailure(
          message: 'Server error. Please try again later.',
          code: 'SERVER_ERROR',
          statusCode: statusCode,
        );

      default:
        return ServerFailure(
          message: message,
          code: 'HTTP_$statusCode',
          statusCode: statusCode,
        );
    }
  }

  /// Get user-friendly message from failure
  static String getUserMessage(Failure failure) {
    return failure.message;
  }
}
