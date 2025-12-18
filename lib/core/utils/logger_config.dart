import 'package:flutter/foundation.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Logger configuration presets for different scenarios
class LoggerConfig {
  LoggerConfig._();

  /// Minimal logging - only errors and critical issues
  static void minimal() {
    AppLogger.disableCategory(LogCategory.network);
    AppLogger.disableCategory(LogCategory.database);
    AppLogger.disableCategory(LogCategory.ui);
    AppLogger.disableCategory(LogCategory.navigation);
    AppLogger.disableCategory(LogCategory.sync);
    AppLogger.disableCategory(LogCategory.general);
  }

  /// Network debugging - focus on network requests
  static void networkOnly() {
    minimal();
    AppLogger.enableCategory(LogCategory.network);
  }

  /// Auth debugging - focus on authentication
  static void authOnly() {
    minimal();
    AppLogger.enableCategory(LogCategory.auth);
  }

  /// Sync debugging - focus on data synchronization
  static void syncOnly() {
    minimal();
    AppLogger.enableCategory(LogCategory.sync);
  }

  /// Tracking debugging - focus on location tracking
  static void trackingOnly() {
    minimal();
    AppLogger.enableCategory(LogCategory.tracking);
  }

  /// Database debugging - focus on database operations
  static void databaseOnly() {
    minimal();
    AppLogger.enableCategory(LogCategory.database);
  }

  /// UI debugging - focus on UI operations
  static void uiOnly() {
    minimal();
    AppLogger.enableCategory(LogCategory.ui);
  }

  /// Enable all logs (default)
  static void all() {
    for (final category in LogCategory.values) {
      AppLogger.enableCategory(category);
    }
  }

  /// Disable all logs except errors
  static void errorsOnly() {
    for (final category in LogCategory.values) {
      AppLogger.disableCategory(category);
    }
  }

  /// Production preset - minimal logging
  static void production() {
    minimal();
    AppLogger.enableCategory(LogCategory.auth);
  }

  /// Development preset - all logs enabled
  static void development() {
    all();
  }

  /// Print current configuration
  static void printConfig() {
    debugPrint('=== Logger Configuration ===');
    for (final category in LogCategory.values) {
      final enabled = AppLogger.isCategoryEnabled(category);
      debugPrint('${category.name.padRight(15)}: ${enabled ? "✓" : "✗"}');
    }
    debugPrint('===========================');
  }
}
