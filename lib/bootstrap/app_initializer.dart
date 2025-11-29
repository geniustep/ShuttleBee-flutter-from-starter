import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:bridgecore_flutter_starter/core/config/app_config.dart';
import 'package:bridgecore_flutter_starter/core/config/env_config.dart';
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/services/services.dart';
import 'package:logger/logger.dart';

import '../core/storage/hive_service.dart';
import '../core/storage/prefs_service.dart';
import '../core/storage/secure_storage_service.dart';

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

      // Initialize BridgeCore client
      await _initializeBridgeCoreClient();

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
