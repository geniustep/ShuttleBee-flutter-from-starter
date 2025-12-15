import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Handling background message: ${message.messageId}');
}

/// Notification service for FCM and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  final _messageStreamController = StreamController<RemoteMessage>.broadcast();

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Get message stream
  Stream<RemoteMessage> get onMessage => _messageStreamController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFCM();
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
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.info('User granted FCM permission');
    } else {
      AppLogger.warning('User declined FCM permission');
      return;
    }

    // Get FCM token
    _fcmToken = await _fcm.getToken();
    AppLogger.info('FCM Token: $_fcmToken');

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
      AppLogger.info('FCM Token refreshed: $token');
    });

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.info('Received foreground message: ${message.messageId}');
      _messageStreamController.add(message);
      _showLocalNotification(message);
    });

    // Listen to notification taps (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.info('App opened from notification: ${message.messageId}');
      _messageStreamController.add(message);
    });

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info(
          'App opened from terminated state: ${initialMessage.messageId}');
      _messageStreamController.add(initialMessage);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
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

  /// Show notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannel? channel,
  }) async {
    final defaultChannel = channel ??
        const NotificationChannel(
          id: 'default',
          name: 'Default',
          description: 'Default notification channel',
          importance: Importance.high,
        );

    final androidDetails = AndroidNotificationDetails(
      defaultChannel.id,
      defaultChannel.name,
      channelDescription: defaultChannel.description,
      importance: defaultChannel.importance,
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

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show scheduled notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled',
      'Scheduled Notifications',
      channelDescription: 'Scheduled notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Note: This requires a scheduling plugin like flutter_local_notifications
    // with timezone support. For simplicity, showing immediate notification.
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

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    AppLogger.info('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    AppLogger.info('Unsubscribed from topic: $topic');
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Dispose
  void dispose() {
    _messageStreamController.close();
  }
}

/// Notification channel
class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final Importance importance;

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    this.importance = Importance.defaultImportance,
  });
}
