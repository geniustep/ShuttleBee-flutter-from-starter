/// BridgeCore Integration Services
///
/// This module provides full integration services for the app,
/// including sync, triggers, notifications, and event bus bridging.
///
/// Usage:
/// ```dart
/// import 'package:bridgecore_flutter_starter/core/bridgecore_integration/services/services.dart';
///
/// // Initialize all services
/// await BridgeCoreServices.initialize(
///   userId: 123,
///   deviceId: 'device-uuid',
/// );
///
/// // Access individual services
/// final syncService = BridgeCoreSyncService();
/// final triggerService = BridgeCoreTriggerService();
/// final notificationService = BridgeCoreNotificationService();
/// final eventBridge = EventBusBridge();
/// ```

export 'bridgecore_sync_service.dart';
export 'bridgecore_trigger_service.dart';
export 'bridgecore_notification_service.dart';
export 'event_bus_bridge.dart';

import 'package:bridgecore_flutter_starter/core/utils/logger.dart';
import 'bridgecore_sync_service.dart';
import 'bridgecore_trigger_service.dart';
import 'bridgecore_notification_service.dart';
import 'event_bus_bridge.dart';

/// BridgeCore Services - Unified initialization and access
class BridgeCoreServices {
  BridgeCoreServices._();

  static bool _isInitialized = false;

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Get sync service
  static BridgeCoreSyncService get sync => BridgeCoreSyncService();

  /// Get trigger service
  static BridgeCoreTriggerService get triggers => BridgeCoreTriggerService();

  /// Get notification service
  static BridgeCoreNotificationService get notifications =>
      BridgeCoreNotificationService();

  /// Get event bus bridge
  static EventBusBridge get eventBridge => EventBusBridge();

  /// Initialize all BridgeCore services
  ///
  /// This should be called after BridgeCore.initialize() and user login.
  ///
  /// Example:
  /// ```dart
  /// await BridgeCoreServices.initialize(
  ///   userId: session.user.odooUserId,
  ///   deviceId: await getDeviceId(),
  ///   appType: 'sales_app',
  /// );
  /// ```
  static Future<void> initialize({
    required int userId,
    required String deviceId,
    String? appType,
    bool startPeriodicSync = true,
    Duration periodicSyncInterval = const Duration(minutes: 5),
    bool enableLocalToBridgeCoreForwarding = false,
  }) async {
    if (_isInitialized) {
      AppLogger.warning('BridgeCoreServices already initialized');
      return;
    }

    AppLogger.info('Initializing BridgeCore services...');

    // Initialize Event Bus Bridge first (to capture all events)
    await eventBridge.initialize(
      forwardLocalToBridgeCore: enableLocalToBridgeCoreForwarding,
    );

    // Initialize Sync Service
    await sync.initialize(
      userId: userId,
      deviceId: deviceId,
      appType: appType,
      startPeriodicSync: startPeriodicSync,
      periodicSyncInterval: periodicSyncInterval,
    );

    // Initialize Trigger Service
    triggers.initialize();

    // Initialize Notification Service
    await notifications.initialize(deviceId: deviceId);

    _isInitialized = true;
    AppLogger.info('BridgeCore services initialized successfully');
  }

  /// Initialize only sync-related services
  static Future<void> initializeSync({
    required int userId,
    required String deviceId,
    String? appType,
    bool startPeriodicSync = true,
    Duration periodicSyncInterval = const Duration(minutes: 5),
  }) async {
    await sync.initialize(
      userId: userId,
      deviceId: deviceId,
      appType: appType,
      startPeriodicSync: startPeriodicSync,
      periodicSyncInterval: periodicSyncInterval,
    );
  }

  /// Initialize only notification service
  static Future<void> initializeNotifications({
    required String deviceId,
  }) async {
    await notifications.initialize(deviceId: deviceId);
  }

  /// Dispose all services
  static void dispose() {
    sync.dispose();
    notifications.dispose();
    eventBridge.dispose();
    _isInitialized = false;
    AppLogger.info('BridgeCore services disposed');
  }

  /// Get status of all services
  static Map<String, bool> getServicesStatus() {
    return {
      'sync': sync.isInitialized,
      'triggers': triggers.isInitialized,
      'notifications': notifications.isInitialized,
      'event_bridge': eventBridge.isInitialized,
    };
  }
}
