import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env file
class EnvConfig {
  EnvConfig._();

  /// Odoo server URL
  static String get odooUrl =>
      dotenv.env['ODOO_URL'] ?? 'https://bridgecore.geniura.com';

  /// Odoo database name
  static String get odooDatabase => dotenv.env['ODOO_DATABASE'] ?? '';

  /// Application name
  static String get appName => dotenv.env['APP_NAME'] ?? 'BridgeCore Starter';

  /// Environment (development, staging, production)
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  /// Cache duration in minutes
  static int get cacheDuration =>
      int.tryParse(dotenv.env['CACHE_DURATION'] ?? '60') ?? 60;

  /// Sync interval in seconds
  static int get syncInterval =>
      int.tryParse(dotenv.env['SYNC_INTERVAL'] ?? '300') ?? 300;

  /// Debug mode enabled
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  /// Check if running in production
  static bool get isProduction => appEnv == 'production';

  /// Check if running in development
  static bool get isDevelopment => appEnv == 'development';
}
