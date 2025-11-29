import 'package:bridgecore_flutter_starter/core/config/app_config.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

/// Centralized logger wrapper for the app.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0, // keep logs concise (no stack frames for info/debug)
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: AppConfig.isDebugMode ? Level.debug : Level.warning,
  );

  /// Log debug message
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConfig.enableLogging) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info message
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConfig.enableLogging) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning message
  static void warning(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (AppConfig.enableLogging) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log error message
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal message
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log network request
  static void logRequest(String method, String url, {dynamic data}) {
    if (AppConfig.enableLogging) {
      final StringBuffer logMessage = StringBuffer('> $method $url');
      if (data != null) {
        logMessage.writeln();
        logMessage.write(_prettyPrint(data));
      }
      debug(logMessage.toString());
    }
  }

  /// Log network response
  static void logResponse(
    String method,
    String url,
    int statusCode, {
    dynamic data,
  }) {
    if (AppConfig.enableLogging) {
      final StringBuffer logMessage = StringBuffer(
        '< $method $url [$statusCode]',
      );
      if (data != null) {
        logMessage.writeln();
        logMessage.write(_prettyPrint(data));
      }

      if (statusCode >= 200 && statusCode < 300) {
        debug(logMessage.toString());
      } else {
        // For error responses, we still might want to see the body, but maybe not as an exception
        // unless it's a critical failure. Using error() here will print stack trace if we pass error obj.
        // Since we formatted data into message, we just pass message.
        error(logMessage.toString());
      }
    }
  }

  /// Log network error
  static void logNetworkError(String method, String url, dynamic error) {
    AppLogger.error('x $method $url', error);
  }

  /// Helper to pretty print JSON
  static String _prettyPrint(dynamic data) {
    try {
      if (data is Map || data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      }
      return data.toString();
    } catch (e) {
      return data.toString();
    }
  }
}
