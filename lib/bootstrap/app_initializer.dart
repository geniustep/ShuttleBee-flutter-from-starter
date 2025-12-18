import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:bridgecore_flutter_starter/core/config/app_config.dart';
import 'package:bridgecore_flutter_starter/core/config/env_config.dart';
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/services/services.dart';
import 'package:logger/logger.dart';

import '../core/storage/hive_service.dart';
import '../core/storage/prefs_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/services/vehicle_heartbeat_background_service.dart';
import '../core/utils/formatters.dart';
import '../core/constants/storage_keys.dart';

/// Handles all app initialization tasks
class AppInitializer {
  static final Logger _logger = Logger();

  /// Initialize all app services
  static Future<void> initialize() async {
    _logger.i('Starting app initialization...');

    try {
      // Initialize storage services
      await _initializeStorage();

      // Register Hive adapters
      await _registerHiveAdapters();

      // Initialize format preferences
      await _initializeFormatPreferences();

      // Initialize BridgeCore client
      await _initializeBridgeCoreClient();

      // Initialize Android foreground-task service (vehicle heartbeat)
      await VehicleHeartbeatBackgroundService.initialize();

      _logger.i('App initialization completed successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'App initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize storage services
  static Future<void> _initializeStorage() async {
    _logger.d('Initializing storage services...');

    await Future.wait([
      PrefsService.init(),
      SecureStorageService.init(),
      HiveService.init(),
    ]);

    _logger.d('Storage services initialized');
  }

  /// Register Hive type adapters
  static Future<void> _registerHiveAdapters() async {
    _logger.d('Registering Hive adapters...');

    // Register adapters here as needed
    // Example: Hive.registerAdapter(UserAdapter());

    _logger.d('Hive adapters registered');
  }

  /// Initialize format preferences for numbers and dates
  static Future<void> _initializeFormatPreferences() async {
    _logger.d('Initializing format preferences...');

    final prefs = PrefsService();

    // Load locale preference
    final locale = prefs.getString(StorageKeys.languageCode) ?? 'en';
    Formatters.setLocale(locale);

    // Load Arabic numerals preference (only valid for Arabic locale)
    var useArabicNumerals =
        prefs.getBool(StorageKeys.useArabicNumerals) ?? false;

    // Force disable Arabic numerals if not using Arabic language
    if (locale != 'ar' && useArabicNumerals) {
      useArabicNumerals = false;
      await prefs.setBool(StorageKeys.useArabicNumerals, false);
      _logger.d('Arabic numerals disabled (non-Arabic locale)');
    }

    Formatters.setNumeralPreference(useArabicNumerals);

    // Load date format preference
    final dateFormatStr = prefs.getString(StorageKeys.dateFormat);
    final dateFormat = _stringToDateFormat(dateFormatStr);
    Formatters.setDateFormatPreference(dateFormat);

    _logger.d(
      'Format preferences initialized (Locale: $locale, Arabic numerals: $useArabicNumerals, Date format: $dateFormatStr)',
    );
  }

  /// Convert string to DateFormatType
  static DateFormatType _stringToDateFormat(String? value) {
    switch (value) {
      case 'short':
        return DateFormatType.short;
      case 'medium':
        return DateFormatType.medium;
      case 'long':
        return DateFormatType.long;
      case 'full':
        return DateFormatType.full;
      default:
        return DateFormatType.medium;
    }
  }

  /// Initialize BridgeCore client
  static Future<void> _initializeBridgeCoreClient() async {
    _logger.d('Initializing BridgeCore client...');

    // Initialize BridgeCore SDK
    BridgeCore.initialize(
      baseUrl: EnvConfig.odooUrl,
      debugMode: AppConfig.isDebugMode,
      enableCache: true,
      enableLogging: AppConfig.enableLogging,
      logLevel: AppConfig.isDebugMode ? LogLevel.debug : LogLevel.info,
    );

    _logger.d('BridgeCore client initialized');
  }

  /// Initialize BridgeCore services after user login
  ///
  /// This should be called after successful login to enable:
  /// - Smart sync
  /// - Server-side triggers
  /// - Push notifications
  /// - Event bus bridging
  ///
  /// Example:
  /// ```dart
  /// // After successful login
  /// final session = await BridgeCore.instance.auth.login(...);
  /// await AppInitializer.initializeBridgeCoreServices(
  ///   userId: session.user.odooUserId!,
  ///   deviceId: await getDeviceId(),
  /// );
  /// ```
  static Future<void> initializeBridgeCoreServices({
    required int userId,
    required String deviceId,
    String? appType,
    bool startPeriodicSync = true,
    Duration periodicSyncInterval = const Duration(minutes: 5),
  }) async {
    _logger.d('Initializing BridgeCore services for user: $userId');

    try {
      await BridgeCoreServices.initialize(
        userId: userId,
        deviceId: deviceId,
        appType: appType,
        startPeriodicSync: startPeriodicSync,
        periodicSyncInterval: periodicSyncInterval,
        enableLocalToBridgeCoreForwarding: AppConfig.isDebugMode,
      );

      _logger.i('BridgeCore services initialized successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize BridgeCore services',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - services are optional
    }
  }

  /// Dispose BridgeCore services on logout
  static void disposeBridgeCoreServices() {
    _logger.d('Disposing BridgeCore services...');
    BridgeCoreServices.dispose();
    _logger.d('BridgeCore services disposed');
  }
}
