import 'dart:async';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Event types for the Event Bus system
enum EventType {
  // Record events
  recordCreated,
  recordUpdated,
  recordDeleted,
  recordValidated,
  recordApproved,
  recordRejected,

  // User events
  userLogin,
  userLogout,
  userUpdated,

  // Sync events
  syncStarted,
  syncCompleted,
  syncFailed,

  // Network events
  connectionOnline,
  connectionOffline,

  // Notification events
  notificationReceived,
  notificationRead,

  // Company events
  companyChanged,
  companyUpdated,

  // Custom events
  custom,
}

/// Event data class
class BusEvent {
  final EventType type;
  final String? model;
  final int? recordId;
  final List<int>? recordIds;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final String? userId;
  final String? customEventName;

  BusEvent({
    required this.type,
    this.model,
    this.recordId,
    this.recordIds,
    this.data,
    DateTime? timestamp,
    this.userId,
    this.customEventName,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create record created event
  factory BusEvent.recordCreated({
    required String model,
    required int recordId,
    Map<String, dynamic>? data,
  }) {
    return BusEvent(
      type: EventType.recordCreated,
      model: model,
      recordId: recordId,
      data: data,
    );
  }

  /// Create record updated event
  factory BusEvent.recordUpdated({
    required String model,
    required int recordId,
    Map<String, dynamic>? data,
  }) {
    return BusEvent(
      type: EventType.recordUpdated,
      model: model,
      recordId: recordId,
      data: data,
    );
  }

  /// Create record deleted event
  factory BusEvent.recordDeleted({
    required String model,
    required int recordId,
  }) {
    return BusEvent(
      type: EventType.recordDeleted,
      model: model,
      recordId: recordId,
    );
  }

  /// Create custom event
  factory BusEvent.custom({
    required String eventName,
    Map<String, dynamic>? data,
  }) {
    return BusEvent(
      type: EventType.custom,
      customEventName: eventName,
      data: data,
    );
  }

  @override
  String toString() {
    return 'BusEvent(type: $type, model: $model, recordId: $recordId, timestamp: $timestamp)';
  }
}

/// Event Bus Service for application-wide events
class EventBusService {
  static final EventBusService _instance = EventBusService._internal();
  factory EventBusService() => _instance;
  EventBusService._internal();

  final _eventController = StreamController<BusEvent>.broadcast();
  final _specificControllers = <String, StreamController<BusEvent>>{};

  /// Global event stream
  Stream<BusEvent> get events => _eventController.stream;

  /// Emit an event to all listeners
  void emit(BusEvent event) {
    AppLogger.debug('EventBus: Emitting event: ${event.type} for ${event.model}');
    _eventController.add(event);

    // Also emit to specific streams
    final key = _getStreamKey(event.type, event.model);
    if (_specificControllers.containsKey(key)) {
      _specificControllers[key]!.add(event);
    }
  }

  /// Listen to specific event type
  Stream<BusEvent> on(EventType type, {String? model}) {
    final key = _getStreamKey(type, model);

    if (!_specificControllers.containsKey(key)) {
      _specificControllers[key] = StreamController<BusEvent>.broadcast();

      // Forward events from main stream to specific stream
      events.listen((event) {
        if (event.type == type && (model == null || event.model == model)) {
          _specificControllers[key]!.add(event);
        }
      });
    }

    return _specificControllers[key]!.stream;
  }

  /// Listen to all events for a specific model
  Stream<BusEvent> onModel(String model) {
    final key = 'model_$model';

    if (!_specificControllers.containsKey(key)) {
      _specificControllers[key] = StreamController<BusEvent>.broadcast();

      events.listen((event) {
        if (event.model == model) {
          _specificControllers[key]!.add(event);
        }
      });
    }

    return _specificControllers[key]!.stream;
  }

  /// Listen to custom events by name
  Stream<BusEvent> onCustom(String eventName) {
    final key = 'custom_$eventName';

    if (!_specificControllers.containsKey(key)) {
      _specificControllers[key] = StreamController<BusEvent>.broadcast();

      events.listen((event) {
        if (event.type == EventType.custom &&
            event.customEventName == eventName) {
          _specificControllers[key]!.add(event);
        }
      });
    }

    return _specificControllers[key]!.stream;
  }

  /// Create a stream key for caching specific streams
  String _getStreamKey(EventType type, String? model) {
    return model != null ? '${type.name}_$model' : type.name;
  }

  /// Clear all event listeners and streams
  void dispose() {
    _eventController.close();
    for (final controller in _specificControllers.values) {
      controller.close();
    }
    _specificControllers.clear();
  }
}

/// Trigger condition for event-based actions
class TriggerCondition {
  final EventType eventType;
  final String? model;
  final bool Function(BusEvent)? customCondition;

  TriggerCondition({
    required this.eventType,
    this.model,
    this.customCondition,
  });

  /// Check if event matches this condition
  bool matches(BusEvent event) {
    if (event.type != eventType) return false;
    if (model != null && event.model != model) return false;
    if (customCondition != null) return customCondition!(event);
    return true;
  }
}

/// Trigger action to execute when condition is met
typedef TriggerAction = Future<void> Function(BusEvent event);

/// Trigger that executes actions based on conditions
class EventTrigger {
  final String id;
  final TriggerCondition condition;
  final TriggerAction action;
  final bool enabled;

  EventTrigger({
    required this.id,
    required this.condition,
    required this.action,
    this.enabled = true,
  });
}

/// Trigger Service for managing event-based triggers
class TriggerService {
  static final TriggerService _instance = TriggerService._internal();
  factory TriggerService() => _instance;
  TriggerService._internal();

  final EventBusService _eventBus = EventBusService();
  final Map<String, EventTrigger> _triggers = {};
  StreamSubscription<BusEvent>? _subscription;

  /// Initialize trigger service
  void initialize() {
    _subscription = _eventBus.events.listen(_handleEvent);
    AppLogger.info('TriggerService initialized');
  }

  /// Register a new trigger
  void registerTrigger(EventTrigger trigger) {
    _triggers[trigger.id] = trigger;
    AppLogger.debug('Trigger registered: ${trigger.id}');
  }

  /// Unregister a trigger
  void unregisterTrigger(String triggerId) {
    _triggers.remove(triggerId);
    AppLogger.debug('Trigger unregistered: $triggerId');
  }

  /// Handle incoming events and execute matching triggers
  void _handleEvent(BusEvent event) {
    for (final trigger in _triggers.values) {
      if (trigger.enabled && trigger.condition.matches(event)) {
        AppLogger.debug('Executing trigger: ${trigger.id} for event: ${event.type}');
        trigger.action(event).catchError((error) {
          AppLogger.error('Trigger ${trigger.id} failed: $error');
        });
      }
    }
  }

  /// Get all registered triggers
  List<EventTrigger> get triggers => _triggers.values.toList();

  /// Enable/disable a trigger
  void setTriggerEnabled(String triggerId, bool enabled) {
    if (_triggers.containsKey(triggerId)) {
      final trigger = _triggers[triggerId]!;
      _triggers[triggerId] = EventTrigger(
        id: trigger.id,
        condition: trigger.condition,
        action: trigger.action,
        enabled: enabled,
      );
    }
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
    _triggers.clear();
    AppLogger.info('TriggerService disposed');
  }
}
