import 'dart:async';
import 'package:bridgecore_flutter_starter/core/services/event_bus_service.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Event types for BridgeCore events
class BridgeCoreEventTypesDef {
  static const String authLogin = 'auth.login';
  static const String authLogout = 'auth.logout';
  static const String tokenRefreshed = 'auth.token_refreshed';
  static const String syncStarted = 'sync.started';
  static const String syncCompleted = 'sync.completed';
  static const String syncFailed = 'sync.failed';
  static const String syncConflictDetected = 'sync.conflict';
  static const String syncPushCompleted = 'sync.push_completed';
  static const String recordCreated = 'odoo.record_created';
  static const String recordUpdated = 'odoo.record_updated';
  static const String recordDeleted = 'odoo.record_deleted';
}

/// BridgeCore Event
class BridgeCoreEventModel {
  final String type;
  final Map<String, dynamic> data;
  final String? source;
  final DateTime timestamp;
  final String id;

  BridgeCoreEventModel({
    required this.type,
    required this.data,
    this.source,
    DateTime? timestamp,
    String? id,
  })  : timestamp = timestamp ?? DateTime.now(),
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}

/// Event Bus Bridge - Links local EventBusService events
///
/// This bridge provides event forwarding and statistics tracking.
///
/// Usage:
/// ```dart
/// final bridge = EventBusBridge();
/// await bridge.initialize();
///
/// // Listen to sync events
/// bridge.onSyncEvents.listen((event) {
///   print('Sync event: ${event.type}');
/// });
/// ```
class EventBusBridge {
  static final EventBusBridge _instance = EventBusBridge._internal();
  factory EventBusBridge() => _instance;
  EventBusBridge._internal();

  final EventBusService _localEventBus = EventBusService();
  final StreamController<BridgeCoreEventModel> _bridgeCoreController =
      StreamController<BridgeCoreEventModel>.broadcast();

  StreamSubscription<BusEvent>? _localSubscription;

  bool _isInitialized = false;
  bool _forwardLocalToBridgeCore = false;

  /// Event mapping from local EventType to BridgeCore event types
  static final Map<EventType, String> _eventMapping = {
    EventType.userLogin: BridgeCoreEventTypesDef.authLogin,
    EventType.userLogout: BridgeCoreEventTypesDef.authLogout,
    EventType.userUpdated: BridgeCoreEventTypesDef.tokenRefreshed,
    EventType.syncStarted: BridgeCoreEventTypesDef.syncStarted,
    EventType.syncCompleted: BridgeCoreEventTypesDef.syncCompleted,
    EventType.syncFailed: BridgeCoreEventTypesDef.syncFailed,
    EventType.recordCreated: BridgeCoreEventTypesDef.recordCreated,
    EventType.recordUpdated: BridgeCoreEventTypesDef.recordUpdated,
    EventType.recordDeleted: BridgeCoreEventTypesDef.recordDeleted,
  };

  /// Statistics
  final Map<String, int> _eventCounts = {};
  int _totalEventsEmitted = 0;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get local event bus
  EventBusService get localEventBus => _localEventBus;

  /// Get BridgeCore event stream
  Stream<BridgeCoreEventModel> get bridgeCoreStream =>
      _bridgeCoreController.stream;

  /// Initialize the event bus bridge
  Future<void> initialize({
    bool forwardLocalToBridgeCore = false,
  }) async {
    if (_isInitialized) {
      AppLogger.warning('EventBusBridge already initialized');
      return;
    }

    _forwardLocalToBridgeCore = forwardLocalToBridgeCore;

    // Listen to local events and optionally forward
    if (_forwardLocalToBridgeCore) {
      _localSubscription = _localEventBus.events.listen(
        _onLocalEvent,
        onError: (error) {
          AppLogger.error('Local event stream error: $error');
        },
      );
    }

    _isInitialized = true;
    AppLogger.info('EventBusBridge initialized');
  }

  /// Handle local events
  void _onLocalEvent(BusEvent event) {
    try {
      // Skip events that originated from BridgeCore (prevent loops)
      if (event.customEventName?.startsWith('bridgecore.') ?? false) {
        return;
      }

      final bridgeCoreType = _eventMapping[event.type];
      if (bridgeCoreType != null) {
        final bridgeCoreEvent = BridgeCoreEventModel(
          type: bridgeCoreType,
          data: {
            if (event.model != null) 'model': event.model,
            if (event.recordId != null) 'record_id': event.recordId,
            if (event.recordIds != null) 'record_ids': event.recordIds,
            ...?event.data,
          },
          source: 'local_app',
        );

        _bridgeCoreController.add(bridgeCoreEvent);

        // Update statistics
        _totalEventsEmitted++;
        _eventCounts[bridgeCoreType] = (_eventCounts[bridgeCoreType] ?? 0) + 1;

        AppLogger.debug(
          'Local event forwarded: ${event.type.name} -> $bridgeCoreType',
        );
      }
    } catch (e) {
      AppLogger.error('Error forwarding local event: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // Event Listening
  // ════════════════════════════════════════════════════════════

  /// Listen to all sync events
  Stream<BusEvent> get onSyncEvents {
    return _localEventBus.events.where((event) =>
        event.type == EventType.syncStarted ||
        event.type == EventType.syncCompleted ||
        event.type == EventType.syncFailed);
  }

  /// Listen to all auth events
  Stream<BusEvent> get onAuthEvents {
    return _localEventBus.events.where((event) =>
        event.type == EventType.userLogin ||
        event.type == EventType.userLogout ||
        event.type == EventType.userUpdated);
  }

  /// Listen to all Odoo record events
  Stream<BusEvent> get onRecordEvents {
    return _localEventBus.events.where((event) =>
        event.type == EventType.recordCreated ||
        event.type == EventType.recordUpdated ||
        event.type == EventType.recordDeleted ||
        event.type == EventType.recordValidated ||
        event.type == EventType.recordApproved ||
        event.type == EventType.recordRejected);
  }

  /// Listen to Odoo record events for a specific model
  Stream<BusEvent> onModelEvents(String model) {
    return onRecordEvents.where((event) => event.model == model);
  }

  /// Listen to custom events by name
  Stream<BusEvent> onCustomEvent(String eventName) {
    return _localEventBus.onCustom(eventName);
  }

  // ════════════════════════════════════════════════════════════
  // Event Emission
  // ════════════════════════════════════════════════════════════

  /// Emit local event
  void emitLocal(BusEvent event) {
    _localEventBus.emit(event);
  }

  /// Emit BridgeCore event
  void emitBridgeCore(String type, Map<String, dynamic> data,
      {String? source}) {
    final event = BridgeCoreEventModel(
      type: type,
      data: data,
      source: source,
    );
    _bridgeCoreController.add(event);

    // Update statistics
    _totalEventsEmitted++;
    _eventCounts[type] = (_eventCounts[type] ?? 0) + 1;
  }

  /// Emit to both event buses
  void emitBoth({
    required EventType localType,
    required String bridgeCoreType,
    String? model,
    int? recordId,
    Map<String, dynamic>? data,
  }) {
    // Emit to local
    _localEventBus.emit(BusEvent(
      type: localType,
      model: model,
      recordId: recordId,
      data: data,
    ));

    // Emit to BridgeCore
    emitBridgeCore(
      bridgeCoreType,
      {
        if (model != null) 'model': model,
        if (recordId != null) 'record_id': recordId,
        ...?data,
      },
      source: 'local_app',
    );
  }

  // ════════════════════════════════════════════════════════════
  // Statistics
  // ════════════════════════════════════════════════════════════

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'is_initialized': _isInitialized,
      'forward_local_to_bridgecore': _forwardLocalToBridgeCore,
      'total_events': _totalEventsEmitted,
      'event_counts': Map<String, int>.from(_eventCounts),
      'event_mapping_count': _eventMapping.length,
    };
  }

  /// Get count for specific event type
  int getEventCount(String eventType) {
    return _eventCounts[eventType] ?? 0;
  }

  /// Clear statistics
  void clearStatistics() {
    _eventCounts.clear();
    _totalEventsEmitted = 0;
    AppLogger.debug('Event statistics cleared');
  }

  // ════════════════════════════════════════════════════════════
  // Configuration
  // ════════════════════════════════════════════════════════════

  /// Enable forwarding local events
  void enableForwardingToBridgeCore() {
    if (_forwardLocalToBridgeCore) return;

    _forwardLocalToBridgeCore = true;
    _localSubscription?.cancel();
    _localSubscription = _localEventBus.events.listen(
      _onLocalEvent,
      onError: (error) {
        AppLogger.error('Local event stream error: $error');
      },
    );

    AppLogger.info('Local to BridgeCore forwarding enabled');
  }

  /// Disable forwarding
  void disableForwardingToBridgeCore() {
    _forwardLocalToBridgeCore = false;
    _localSubscription?.cancel();
    _localSubscription = null;

    AppLogger.info('Local to BridgeCore forwarding disabled');
  }

  // ════════════════════════════════════════════════════════════
  // Lifecycle
  // ════════════════════════════════════════════════════════════

  /// Dispose resources
  void dispose() {
    _localSubscription?.cancel();
    _bridgeCoreController.close();
    _isInitialized = false;
    AppLogger.info('EventBusBridge disposed');
  }
}
