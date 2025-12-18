import 'package:bridgecore_flutter_starter/core/config/app_config.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

/// Log categories for better filtering and organization
enum LogCategory {
  network,
  auth,
  sync,
  database,
  ui,
  navigation,
  notification,
  tracking,
  general,
}

/// Centralized logger wrapper for the app.
class AppLogger {
  AppLogger._();

  /// Enable/disable specific log categories
  static final Set<LogCategory> _enabledCategories = {
    ...LogCategory.values, // All enabled by default
  };

  /// Enable a specific log category
  static void enableCategory(LogCategory category) {
    _enabledCategories.add(category);
  }

  /// Disable a specific log category
  static void disableCategory(LogCategory category) {
    _enabledCategories.remove(category);
  }

  /// Check if a category is enabled
  static bool isCategoryEnabled(LogCategory category) {
    return _enabledCategories.contains(category);
  }

  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0, // keep logs concise (no stack frames for info/debug)
      errorMethodCount: 5, // Reduced from 8 for cleaner error logs
      lineLength: 80, // Reduced from 120 for better readability
      colors: true,
      printEmojis: false, // Disabled for cleaner console output
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      excludeBox: {
        Level.debug: true, // Remove box for debug to reduce noise
        Level.info: true, // Remove box for info to reduce noise
      },
      noBoxingByDefault: false,
    ),
    level: AppConfig.isDebugMode ? Level.debug : Level.warning,
  );

  /// Log debug message
  static void debug(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    LogCategory category = LogCategory.general,
  ]) {
    if (AppConfig.enableLogging && isCategoryEnabled(category)) {
      final formattedMessage = _formatMessage(message, category);
      _logger.d(formattedMessage, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info message
  static void info(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    LogCategory category = LogCategory.general,
  ]) {
    if (AppConfig.enableLogging && isCategoryEnabled(category)) {
      final formattedMessage = _formatMessage(message, category);
      _logger.i(formattedMessage, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning message
  static void warning(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    LogCategory category = LogCategory.general,
  ]) {
    if (AppConfig.enableLogging && isCategoryEnabled(category)) {
      final formattedMessage = _formatMessage(message, category);
      _logger.w(formattedMessage, error: error, stackTrace: stackTrace);
    }
  }

  /// Log error message
  static void error(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    LogCategory category = LogCategory.general,
  ]) {
    // Always log errors regardless of category settings
    final formattedMessage = _formatMessage(message, category);
    _logger.e(formattedMessage, error: error, stackTrace: stackTrace);
  }

  /// Log fatal message
  static void fatal(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    LogCategory category = LogCategory.general,
  ]) {
    // Always log fatal errors regardless of category settings
    final formattedMessage = _formatMessage(message, category);
    _logger.f(formattedMessage, error: error, stackTrace: stackTrace);
  }

  /// Format message with category tag
  static String _formatMessage(dynamic message, LogCategory category) {
    final categoryTag = category.name.toUpperCase().padRight(12);
    return '[$categoryTag] $message';
  }

  /// Log network request
  static void logRequest(String method, String url, {dynamic data}) {
    if (AppConfig.enableLogging && isCategoryEnabled(LogCategory.network)) {
      final StringBuffer logMessage = StringBuffer('→ $method $url');
      if (data != null && AppConfig.isDebugMode) {
        // Only show request body in debug mode
        logMessage.writeln();
        logMessage.write(_prettyPrint(data, maxLength: 200));
      }
      debug(logMessage.toString(), null, null, LogCategory.network);
    }
  }

  /// Log network response
  static void logResponse(
    String method,
    String url,
    int statusCode, {
    dynamic data,
  }) {
    if (AppConfig.enableLogging && isCategoryEnabled(LogCategory.network)) {
      final StringBuffer logMessage = StringBuffer(
        '← $method $url [$statusCode]',
      );
      if (data != null && AppConfig.isDebugMode) {
        // Only show response body in debug mode
        logMessage.writeln();
        logMessage.write(_prettyPrint(data, maxLength: 200));
      }

      if (statusCode >= 200 && statusCode < 300) {
        debug(logMessage.toString(), null, null, LogCategory.network);
      } else {
        error(logMessage.toString(), null, null, LogCategory.network);
      }
    }
  }

  /// Log network error
  static void logNetworkError(String method, String url, dynamic error) {
    AppLogger.error('✗ $method $url', error, null, LogCategory.network);
  }

  /// Helper to pretty print JSON with optional max length
  static String _prettyPrint(dynamic data, {int? maxLength}) {
    try {
      String result;
      if (data is Map || data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        result = encoder.convert(data);
      } else {
        result = data.toString();
      }

      // Truncate if needed
      if (maxLength != null && result.length > maxLength) {
        return '${result.substring(0, maxLength)}... (truncated)';
      }
      return result;
    } catch (e) {
      return data.toString();
    }
  }
}
