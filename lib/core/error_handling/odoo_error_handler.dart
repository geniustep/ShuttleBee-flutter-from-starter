import 'package:bridgecore_flutter_starter/core/utils/logger.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Odoo 18 Error Handler
class OdooErrorHandler {
  /// Parse and handle BridgeCore exceptions
  static Failure handleBridgeCoreException(dynamic exception) {
    AppLogger.error('BridgeCore exception: $exception');

    final message = exception.toString();
    final exceptionString = message.toLowerCase();

    // Authentication errors
    if (exceptionString.contains('authentication') ||
        exceptionString.contains('unauthorized') ||
        exceptionString.contains('token') ||
        exceptionString.contains('session') ||
        exceptionString.contains('401')) {
      return const AuthFailure(
        message: 'Authentication failed. Please login again.',
        code: 'ODOO_AUTH_ERROR',
      );
    }

    // Validation errors
    if (exceptionString.contains('validation') ||
        exceptionString.contains('constraint') ||
        exceptionString.contains('invalid') ||
        exceptionString.contains('required')) {
      return const ValidationFailure(
        message: 'Validation error. Please check your input.',
        code: 'ODOO_VALIDATION_ERROR',
      );
    }

    // Access/Permission errors
    if (exceptionString.contains('access') ||
        exceptionString.contains('permission') ||
        exceptionString.contains('forbidden') ||
        exceptionString.contains('403')) {
      return const AuthFailure(
        message: 'Access denied. You don\'t have permission.',
        code: 'ODOO_ACCESS_DENIED',
      );
    }

    // Not found errors
    if (exceptionString.contains('not found') ||
        exceptionString.contains('missing') ||
        exceptionString.contains('does not exist') ||
        exceptionString.contains('404')) {
      return const ServerFailure(
        message: 'Resource not found',
        code: 'ODOO_NOT_FOUND',
      );
    }

    // Warning (UserError)
    if (exceptionString.contains('usererror') ||
        exceptionString.contains('warning')) {
      // Extract message if possible
      return ServerFailure(
        message: _extractErrorMessage(message) ?? 'Operation cannot be completed',
        code: 'ODOO_USER_ERROR',
      );
    }

    // Default Odoo error
    return ServerFailure(
      message: _extractErrorMessage(message) ?? 'Odoo server error occurred',
      code: 'ODOO_ERROR',
    );
  }

  /// Extract error message from exception string
  static String? _extractErrorMessage(String exceptionString) {
    // Try to extract meaningful error message
    // BridgeCore exceptions often have format: "BridgeCoreException: message"
    if (exceptionString.contains(':')) {
      final parts = exceptionString.split(':');
      if (parts.length > 1) {
        return parts.skip(1).join(':').trim();
      }
    }
    return null;
  }

  /// Create Odoo-specific exception from error data
  static OdooException createOdooException({
    required String message,
    String? errorType,
    String? code,
    Map<String, dynamic>? context,
  }) {
    final lowerErrorType = errorType?.toLowerCase() ?? '';

    if (lowerErrorType.contains('validation')) {
      return OdooValidationException(
        message: message,
        code: code,
        context: context,
      );
    }

    if (lowerErrorType.contains('access')) {
      return OdooAccessException(
        message: message,
        code: code,
        context: context,
      );
    }

    if (lowerErrorType.contains('user')) {
      return OdooUserException(
        message: message,
        code: code,
        context: context,
      );
    }

    if (lowerErrorType.contains('warning')) {
      return OdooWarningException(
        message: message,
        code: code,
        context: context,
      );
    }

    if (lowerErrorType.contains('missing')) {
      return OdooMissingException(
        message: message,
        code: code,
        context: context,
      );
    }

    return OdooException(
      message: message,
      code: code,
      odooErrorType: errorType,
      context: context,
    );
  }
}
