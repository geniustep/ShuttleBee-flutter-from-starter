import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';
import 'package:bridgecore_flutter_starter/core/services/event_bus_service.dart';

/// Notification type
enum NotificationTypeDef {
  info,
  success,
  warning,
  error,
  system,
}

/// App notification model
/// Updated to use extraData instead of data for compatibility with BridgeCore
class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationTypeDef type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? extraData; // Renamed from data to extraData to match BridgeCore

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationTypeDef.info,
    this.isRead = false,
    DateTime? createdAt,
    Map<String, dynamic>? extraData,
    // Backward compatibility: support both data and extraData
    @Deprecated('Use extraData instead') Map<String, dynamic>? data,
  }) : createdAt = createdAt ?? DateTime.now(),
       extraData = extraData ?? data;

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationTypeDef? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? extraData,
    // Backward compatibility
    @Deprecated('Use extraData instead') Map<String, dynamic>? data,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      extraData: extraData ?? data ?? this.extraData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
        'extra_data': extraData, // Backend expects extra_data
        // Backward compatibility: also include as data for old clients
        if (extraData != null) 'data': extraData,
      };

  /// Factory constructor from JSON with backward compatibility
  /// Supports both extra_data (new) and data/metadata (old)
  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationTypeDef.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationTypeDef.info,
      ),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      // Support both extra_data (new) and data/metadata (old) for backward compatibility
      extraData: json['extra_data'] ?? json['data'] ?? json['metadata'],
    );
  }
}

/// Notification stats
class NotificationStatsModel {
  final int total;
  final int unreadCount;

  NotificationStatsModel({
    required this.total,
    required this.unreadCount,
  });
}

/// BridgeCore Notification Service
///
/// Combines Firebase Cloud Messaging (FCM) with local notification management.
///
/// Usage:
/// ```dart
/// final notificationService = BridgeCoreNotificationService();
/// await notificationService.initialize();
///
/// // Show notification
/// await notificationService.showNotification(
///   id: 1,
///   title: 'Hello',
///   body: 'World',
/// );
/// ```
class BridgeCoreNotificationService {
  static final BridgeCoreNotificationService _instance =
      BridgeCoreNotificationService._internal();
  factory BridgeCoreNotificationService() => _instance;
  BridgeCoreNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final EventBusService _eventBus = EventBusService();

  bool _isInitialized = false;
  String? _fcmToken;
  String? _deviceId;

  final Map<String, AppNotificationModel> _notifications = {};
  int _idCounter = 0;

  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Get device ID
  String? get deviceId => _deviceId;

  /// Get message stream
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  /// Initialize notification service
  Future<void> initialize({String? deviceId}) async {
    if (_isInitialized) {
      AppLogger.warning('BridgeCoreNotificationService already initialized');
      return;
    }

    _deviceId = deviceId;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize FCM
    await _initializeFCM();

    _isInitialized = true;
    AppLogger.info('BridgeCoreNotificationService initialized');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    AppLogger.info('Local notifications initialized');
  }

  /// Initialize FCM
  Future<void> _initializeFCM() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      AppLogger.warning('User declined FCM permission');
      return;
    }

    AppLogger.info('User granted FCM permission');

    _fcmToken = await _fcm.getToken();
    AppLogger.info('FCM Token obtained');

    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
      AppLogger.info('FCM Token refreshed');
    });

    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.info('Received foreground message: ${message.messageId}');
      _messageController.add(message);
      _showLocalNotificationFromRemote(message);

      _eventBus.emit(BusEvent(
        type: EventType.notificationReceived,
        data: {
          'message_id': message.messageId,
          'title': message.notification?.title,
          'body': message.notification?.body,
        },
      ));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.info('App opened from notification: ${message.messageId}');
      _messageController.add(message);
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App opened from terminated state');
      _messageController.add(initialMessage);
    }
  }

  /// Show local notification from remote message
  Future<void> _showLocalNotificationFromRemote(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await showNotification(
        id: message.hashCode,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
    _eventBus.emit(BusEvent(
      type: EventType.custom,
      customEventName: 'notification.tapped',
      data: {'payload': response.payload},
    ));
  }

  // ════════════════════════════════════════════════════════════
  // Notification Management
  // ════════════════════════════════════════════════════════════

  /// Get all notifications
  Future<List<AppNotificationModel>> getNotifications({
    bool? isRead,
    NotificationTypeDef? type,
    int limit = 50,
  }) async {
    _ensureInitialized();

    var notifications = _notifications.values.toList();

    if (isRead != null) {
      notifications = notifications.where((n) => n.isRead == isRead).toList();
    }
    if (type != null) {
      notifications = notifications.where((n) => n.type == type).toList();
    }

    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications.take(limit).toList();
  }

  /// Get unread notifications
  Future<List<AppNotificationModel>> getUnreadNotifications({
    int limit = 50,
  }) async {
    return await getNotifications(isRead: false, limit: limit);
  }

  /// Get notification by ID
  Future<AppNotificationModel?> getNotification(String notificationId) async {
    _ensureInitialized();
    return _notifications[notificationId];
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    _ensureInitialized();

    final notification = _notifications[notificationId];
    if (notification == null) return false;

    _notifications[notificationId] = notification.copyWith(isRead: true);

    _eventBus.emit(BusEvent(
      type: EventType.notificationRead,
      data: {'notification_id': notificationId},
    ));

    return true;
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    _ensureInitialized();

    int count = 0;
    for (final id in _notifications.keys) {
      final notification = _notifications[id]!;
      if (!notification.isRead) {
        _notifications[id] = notification.copyWith(isRead: true);
        count++;
      }
    }

    _eventBus.emit(BusEvent(
      type: EventType.custom,
      customEventName: 'notifications.all_read',
      data: {'count': count},
    ));

    return count;
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    _ensureInitialized();
    return _notifications.remove(notificationId) != null;
  }

  /// Get notification statistics
  Future<NotificationStatsModel> getStats() async {
    _ensureInitialized();

    final unread = _notifications.values.where((n) => !n.isRead).length;

    return NotificationStatsModel(
      total: _notifications.length,
      unreadCount: unread,
    );
  }

  /// Add notification to local store
  Future<AppNotificationModel> addNotification({
    required String title,
    required String body,
    NotificationTypeDef type = NotificationTypeDef.info,
    Map<String, dynamic>? extraData,
    // Backward compatibility
    @Deprecated('Use extraData instead') Map<String, dynamic>? data,
  }) async {
    _ensureInitialized();

    final id = 'notification_${++_idCounter}';
    final notification = AppNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      extraData: extraData ?? data,
    );

    _notifications[id] = notification;
    return notification;
  }

  // ════════════════════════════════════════════════════════════
  // Local Notifications
  // ════════════════════════════════════════════════════════════

  /// Show local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default',
    String channelName = 'Default',
    String channelDescription = 'Default notification channel',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // ════════════════════════════════════════════════════════════
  // FCM Topics
  // ════════════════════════════════════════════════════════════

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    AppLogger.info('Subscribed to topic: $topic');
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    AppLogger.info('Unsubscribed from topic: $topic');
  }

  // ════════════════════════════════════════════════════════════
  // Utility
  // ════════════════════════════════════════════════════════════

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'BridgeCoreNotificationService not initialized. Call initialize() first.',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _messageController.close();
    _isInitialized = false;
    AppLogger.info('BridgeCoreNotificationService disposed');
  }
}
