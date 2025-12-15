import 'package:bridgecore_flutter_starter/core/utils/logger.dart';
import 'package:bridgecore_flutter_starter/core/services/event_bus_service.dart';

/// Trigger event types
enum TriggerEventType {
  onCreate,
  onUpdate,
  onDelete,
  onSchedule,
}

/// Trigger action types
enum TriggerActionTypeDef {
  notification,
  email,
  webhook,
  odooMethod,
}

/// Trigger status
enum TriggerStatusDef {
  active,
  inactive,
  error,
}

/// Trigger model
class TriggerModel {
  final String id;
  final String name;
  final String? description;
  final String model;
  final TriggerEventType event;
  final TriggerActionTypeDef actionType;
  final Map<String, dynamic> actionConfig;
  final bool isEnabled;
  final DateTime createdAt;

  TriggerModel({
    required this.id,
    required this.name,
    this.description,
    required this.model,
    required this.event,
    required this.actionType,
    required this.actionConfig,
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'model': model,
        'event': event.name,
        'action_type': actionType.name,
        'action_config': actionConfig,
        'is_enabled': isEnabled,
        'created_at': createdAt.toIso8601String(),
      };
}

/// BridgeCore Trigger Service - Local trigger management
///
/// This service provides trigger functionality locally.
/// Can be extended to sync with BridgeCore backend.
///
/// Usage:
/// ```dart
/// final triggerService = BridgeCoreTriggerService();
/// triggerService.initialize();
///
/// final trigger = await triggerService.createTrigger(
///   name: 'Notify on New Order',
///   model: 'sale.order',
///   event: TriggerEventType.onCreate,
///   actionType: TriggerActionTypeDef.notification,
///   actionConfig: {...},
/// );
/// ```
class BridgeCoreTriggerService {
  static final BridgeCoreTriggerService _instance =
      BridgeCoreTriggerService._internal();
  factory BridgeCoreTriggerService() => _instance;
  BridgeCoreTriggerService._internal();

  final EventBusService _eventBus = EventBusService();
  final Map<String, TriggerModel> _triggers = {};

  bool _isInitialized = false;
  int _idCounter = 0;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Initialize trigger service
  void initialize() {
    if (_isInitialized) {
      AppLogger.warning('BridgeCoreTriggerService already initialized');
      return;
    }

    _isInitialized = true;
    AppLogger.info('BridgeCoreTriggerService initialized');
  }

  // ════════════════════════════════════════════════════════════
  // Create Triggers
  // ════════════════════════════════════════════════════════════

  /// Create a new trigger
  Future<TriggerModel> createTrigger({
    required String name,
    String? description,
    required String model,
    required TriggerEventType event,
    List<dynamic>? condition,
    required TriggerActionTypeDef actionType,
    required Map<String, dynamic> actionConfig,
    bool isEnabled = true,
  }) async {
    _ensureInitialized();

    final id = 'trigger_${++_idCounter}';
    final trigger = TriggerModel(
      id: id,
      name: name,
      description: description,
      model: model,
      event: event,
      actionType: actionType,
      actionConfig: actionConfig,
      isEnabled: isEnabled,
    );

    _triggers[id] = trigger;

    _eventBus.emit(
      BusEvent.custom(
        eventName: 'trigger.created',
        data: {
          'trigger_id': id,
          'name': name,
          'model': model,
        },
      ),
    );

    AppLogger.info('Trigger created: $name ($id)');

    return trigger;
  }

  /// Create notification trigger
  Future<TriggerModel> createNotificationTrigger({
    required String name,
    required String model,
    required TriggerEventType event,
    required String notificationTitle,
    required String notificationMessage,
    required List<int> userIds,
    String? description,
  }) async {
    return await createTrigger(
      name: name,
      description: description,
      model: model,
      event: event,
      actionType: TriggerActionTypeDef.notification,
      actionConfig: {
        'title': notificationTitle,
        'message': notificationMessage,
        'user_ids': userIds,
      },
    );
  }

  /// Create email trigger
  Future<TriggerModel> createEmailTrigger({
    required String name,
    required String model,
    required TriggerEventType event,
    required String subject,
    required String body,
    required List<String> recipients,
    String? description,
  }) async {
    return await createTrigger(
      name: name,
      description: description,
      model: model,
      event: event,
      actionType: TriggerActionTypeDef.email,
      actionConfig: {
        'subject': subject,
        'body': body,
        'recipients': recipients,
      },
    );
  }

  /// Create webhook trigger
  Future<TriggerModel> createWebhookTrigger({
    required String name,
    required String model,
    required TriggerEventType event,
    required String webhookUrl,
    Map<String, String>? headers,
    String? description,
  }) async {
    return await createTrigger(
      name: name,
      description: description,
      model: model,
      event: event,
      actionType: TriggerActionTypeDef.webhook,
      actionConfig: {
        'url': webhookUrl,
        if (headers != null) 'headers': headers,
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // List & Get Triggers
  // ════════════════════════════════════════════════════════════

  /// List all triggers
  Future<List<TriggerModel>> listTriggers({
    String? model,
    TriggerEventType? event,
    bool? isEnabled,
  }) async {
    _ensureInitialized();

    var triggers = _triggers.values.toList();

    if (model != null) {
      triggers = triggers.where((t) => t.model == model).toList();
    }
    if (event != null) {
      triggers = triggers.where((t) => t.event == event).toList();
    }
    if (isEnabled != null) {
      triggers = triggers.where((t) => t.isEnabled == isEnabled).toList();
    }

    return triggers;
  }

  /// Get trigger by ID
  Future<TriggerModel?> getTrigger(String triggerId) async {
    _ensureInitialized();
    return _triggers[triggerId];
  }

  // ════════════════════════════════════════════════════════════
  // Update & Delete Triggers
  // ════════════════════════════════════════════════════════════

  /// Enable trigger
  Future<TriggerModel?> enableTrigger(String triggerId) async {
    return await toggleTrigger(triggerId, true);
  }

  /// Disable trigger
  Future<TriggerModel?> disableTrigger(String triggerId) async {
    return await toggleTrigger(triggerId, false);
  }

  /// Toggle trigger
  Future<TriggerModel?> toggleTrigger(String triggerId, bool isEnabled) async {
    _ensureInitialized();

    final existing = _triggers[triggerId];
    if (existing == null) return null;

    final updated = TriggerModel(
      id: existing.id,
      name: existing.name,
      description: existing.description,
      model: existing.model,
      event: existing.event,
      actionType: existing.actionType,
      actionConfig: existing.actionConfig,
      isEnabled: isEnabled,
      createdAt: existing.createdAt,
    );

    _triggers[triggerId] = updated;

    _eventBus.emit(
      BusEvent.custom(
        eventName: isEnabled ? 'trigger.enabled' : 'trigger.disabled',
        data: {'trigger_id': triggerId, 'name': updated.name},
      ),
    );

    AppLogger.info(
      'Trigger ${isEnabled ? 'enabled' : 'disabled'}: ${updated.name} ($triggerId)',
    );

    return updated;
  }

  /// Delete trigger
  Future<bool> deleteTrigger(String triggerId) async {
    _ensureInitialized();

    final removed = _triggers.remove(triggerId);

    if (removed != null) {
      _eventBus.emit(
        BusEvent.custom(
          eventName: 'trigger.deleted',
          data: {'trigger_id': triggerId},
        ),
      );

      AppLogger.info('Trigger deleted: $triggerId');
      return true;
    }

    return false;
  }

  // ════════════════════════════════════════════════════════════
  // Execute Triggers
  // ════════════════════════════════════════════════════════════

  /// Execute trigger manually
  Future<Map<String, dynamic>> executeTrigger(
    String triggerId, {
    List<int>? recordIds,
    bool testMode = false,
  }) async {
    _ensureInitialized();

    final trigger = _triggers[triggerId];
    if (trigger == null) {
      return {'success': false, 'error': 'Trigger not found'};
    }

    _eventBus.emit(
      BusEvent.custom(
        eventName: 'trigger.executed',
        data: {
          'trigger_id': triggerId,
          'success': true,
          'records_affected': recordIds?.length ?? 0,
          'test_mode': testMode,
        },
      ),
    );

    AppLogger.info('Trigger executed: $triggerId');

    return {
      'success': true,
      'records_affected': recordIds?.length ?? 0,
    };
  }

  // ════════════════════════════════════════════════════════════
  // Common Trigger Templates
  // ════════════════════════════════════════════════════════════

  /// Create trigger for new sale orders
  Future<TriggerModel> createNewSaleOrderTrigger({
    required String name,
    required String notificationTitle,
    required String notificationMessage,
    required List<int> userIds,
  }) async {
    return await createNotificationTrigger(
      name: name,
      model: 'sale.order',
      event: TriggerEventType.onCreate,
      notificationTitle: notificationTitle,
      notificationMessage: notificationMessage,
      userIds: userIds,
    );
  }

  /// Create trigger for new customers
  Future<TriggerModel> createNewCustomerTrigger({
    required String name,
    required String notificationTitle,
    required String notificationMessage,
    required List<int> userIds,
  }) async {
    return await createNotificationTrigger(
      name: name,
      model: 'res.partner',
      event: TriggerEventType.onCreate,
      notificationTitle: notificationTitle,
      notificationMessage: notificationMessage,
      userIds: userIds,
    );
  }

  // ════════════════════════════════════════════════════════════
  // Private Methods
  // ════════════════════════════════════════════════════════════

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'BridgeCoreTriggerService not initialized. Call initialize() first.',
      );
    }
  }
}
