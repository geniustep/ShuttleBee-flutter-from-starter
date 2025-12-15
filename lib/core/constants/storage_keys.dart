/// Storage keys for SharedPreferences and SecureStorage
class StorageKeys {
  StorageKeys._();

  // === Secure Storage Keys ===
  /// Access token
  static const String accessToken = 'access_token';

  /// Session ID
  static const String sessionId = 'session_id';

  /// ShuttleBee REST Session ID (when REST base URL differs from main ODOO_URL).
  static const String shuttleBeeSessionId = 'shuttlebee_session_id';

  /// User credentials (encrypted)
  static const String userCredentials = 'user_credentials';

  // === Shared Preferences Keys ===
  /// User ID
  static const String userId = 'user_id';

  /// Username
  static const String username = 'username';

  /// User display name
  static const String userDisplayName = 'user_display_name';

  /// Company ID
  static const String companyId = 'company_id';

  /// Company name
  static const String companyName = 'company_name';

  /// Selected database
  static const String database = 'database';

  /// Server URL
  static const String serverUrl = 'server_url';

  /// Theme mode (light/dark/system)
  static const String themeMode = 'theme_mode';

  /// Language code
  static const String languageCode = 'language_code';

  /// First launch flag
  static const String isFirstLaunch = 'is_first_launch';

  /// Onboarding completed flag
  static const String onboardingCompleted = 'onboarding_completed';

  /// Remember me flag
  static const String rememberMe = 'remember_me';

  /// Biometric enabled
  static const String biometricEnabled = 'biometric_enabled';

  /// Last sync timestamp
  static const String lastSyncTimestamp = 'last_sync_timestamp';

  /// Partner ID (Odoo res.partner)
  static const String partnerId = 'partner_id';

  /// User Role (driver, dispatcher, passenger, manager)
  static const String userRole = 'user_role';

  /// Last known vehicle ID for the current driver (for background heartbeat).
  static const String lastVehicleId = 'last_vehicle_id';

  /// Offline mode enabled
  static const String offlineModeEnabled = 'offline_mode_enabled';

  /// Auto sync enabled
  static const String autoSyncEnabled = 'auto_sync_enabled';

  // === Hive Box Names ===
  /// User box
  static const String userBox = 'user_box';

  /// Settings box
  static const String settingsBox = 'settings_box';

  /// Cache box
  static const String cacheBox = 'cache_box';

  /// Sync queue box
  static const String syncQueueBox = 'sync_queue_box';

  /// Offline data box prefix
  static const String offlineDataPrefix = 'offline_';
}
