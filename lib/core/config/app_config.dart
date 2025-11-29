import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration constants
class AppConfig {
  AppConfig._();

  /// App name
  static const String appName = 'BridgeCore Starter';

  /// App version
  static const String appVersion = '1.0.0';

  /// Build number
  static const int buildNumber = 1;

  /// Minimum supported API version
  static const int minApiVersion = 14;

  /// Default pagination limit
  static const int defaultPageSize = 20;

  /// Maximum retry attempts for network requests
  static const int maxRetryAttempts = 3;

  /// Connection timeout in milliseconds
  static const int connectionTimeout = 30000;

  /// Receive timeout in milliseconds
  static const int receiveTimeout = 30000;

  /// Cache duration in minutes
  static const int cacheDurationMinutes = 60;

  /// Sync interval in seconds
  static const int syncIntervalSeconds = 300;

  /// Session timeout in minutes
  static const int sessionTimeoutMinutes = 30;

  /// Animation durations
  static const Duration transitionDuration = Duration(milliseconds: 250);
  static const Duration microDuration = Duration(milliseconds: 150);
  static const Duration shimmerDuration = Duration(milliseconds: 1500);

  // Debug Mode
  static bool get isDebugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  static bool get enableLogging =>
      dotenv.env['ENABLE_LOGGING']?.toLowerCase() == 'true';
}
