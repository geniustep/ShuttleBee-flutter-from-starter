import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env file
class EnvConfig {
  EnvConfig._();

  /// Main Odoo/BridgeCore server URL (used for login + JSON-RPC via BridgeCore).
  static String get odooUrl =>
      dotenv.env['ODOO_URL'] ?? 'https://bridgecore.geniura.com';

  /// ShuttleBee REST API base URL (used ONLY for `/api/v1/shuttle/*` endpoints).
  ///
  /// If not set, it falls back to [odooUrl].
  static String get shuttleBeeApiUrl =>
      (dotenv.env['SHUTTLEBEE_API_URL'] ?? '').trim();

  /// Database for ShuttleBee REST API authentication (`/web/session/authenticate`).
  /// If not set, it falls back to [odooDatabase].
  static String get shuttleBeeApiDatabase =>
      (dotenv.env['SHUTTLEBEE_API_DATABASE'] ?? '').trim();

  /// Effective base URL for ShuttleBee REST calls.
  static String get shuttleBeeApiBaseUrl =>
      shuttleBeeApiUrl.isNotEmpty ? shuttleBeeApiUrl : odooUrl;

  /// Effective database for ShuttleBee REST calls.
  static String get shuttleBeeApiDb =>
      shuttleBeeApiDatabase.isNotEmpty ? shuttleBeeApiDatabase : odooDatabase;

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
