// Stub implementation for platforms that don't support firebase_messaging
// This file is used when firebase_messaging is not available (e.g., Windows)

/// Stub class for RemoteMessage
class RemoteMessage {
  final String? messageId;
  final Notification? notification;
  final Map<String, dynamic> data;

  RemoteMessage({
    this.messageId,
    this.notification,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  @override
  int get hashCode => messageId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteMessage &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId;
}

/// Stub class for Notification
class Notification {
  final String? title;
  final String? body;

  Notification({this.title, this.body});
}

/// Stub class for FirebaseMessaging
class FirebaseMessaging {
  static FirebaseMessaging get instance => FirebaseMessaging._();
  FirebaseMessaging._();

  Future<String?> getToken() async => null;
  Stream<String> get onTokenRefresh => const Stream.empty();
  Future<RemoteMessage?> getInitialMessage() async => null;
  Future<void> subscribeToTopic(String topic) async {}
  Future<void> unsubscribeFromTopic(String topic) async {}
  Future<NotificationSettings> requestPermission({
    bool alert = false,
    bool badge = false,
    bool sound = false,
    bool provisional = false,
  }) async {
    return NotificationSettings(
      authorizationStatus: AuthorizationStatus.denied,
    );
  }

  // Static streams for compatibility with firebase_messaging API
  static Stream<RemoteMessage> get onMessage => const Stream.empty();
  static Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();
}

/// Stub class for NotificationSettings
class NotificationSettings {
  final AuthorizationStatus authorizationStatus;

  NotificationSettings({required this.authorizationStatus});
}

/// Stub enum for AuthorizationStatus
enum AuthorizationStatus {
  notDetermined,
  denied,
  authorized,
  provisional,
}
