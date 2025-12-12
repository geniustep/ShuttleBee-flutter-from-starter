import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/shuttle_notification.dart';
import '../services/shuttle_notification_api_service.dart';

/// Notification Remote Data Source - مصدر بيانات الإشعارات
/// يستخدم Odoo ORM للإشعارات
class NotificationRemoteDataSource {
  final BridgecoreClient _client;
  // ignore: unused_field - محفوظ للاستخدام المستقبلي
  final ShuttleNotificationApiService? _apiService;

  static const String _notificationModel = 'shuttle.notification';
  static const String _tripLineModel = 'shuttle.trip.line';

  NotificationRemoteDataSource(
    this._client, {
    ShuttleNotificationApiService? apiService,
  }) : _apiService = apiService;

  /// الحصول على إشعارات رحلة معينة
  Future<List<ShuttleNotification>> getTripNotifications(int tripId) async {
    final result = await _client.searchRead(
      model: _notificationModel,
      domain: [
        ['trip_id', '=', tripId],
      ],
      fields: _notificationFields,
      order: 'create_date desc',
    );

    return result.map((json) => ShuttleNotification.fromOdoo(json)).toList();
  }

  /// الحصول على إشعارات راكب معين
  Future<List<ShuttleNotification>> getPassengerNotifications(
    int passengerId, {
    int limit = 50,
  }) async {
    final result = await _client.searchRead(
      model: _notificationModel,
      domain: [
        ['passenger_id', '=', passengerId],
      ],
      fields: _notificationFields,
      order: 'create_date desc',
      limit: limit,
    );

    return result.map((json) => ShuttleNotification.fromOdoo(json)).toList();
  }

  /// الحصول على الإشعارات الأخيرة
  Future<List<ShuttleNotification>> getRecentNotifications({
    int? passengerId,
    int? tripId,
    int limit = 50,
  }) async {
    // استخدام الطريقة المخصصة في Odoo
    try {
      final result = await _client.callKw(
        model: _notificationModel,
        method: 'get_recent_notifications',
        kwargs: {
          if (passengerId != null) 'passenger_id': passengerId,
          if (tripId != null) 'trip_id': tripId,
          'limit': limit,
        },
      );

      if (result is List) {
        return result
            .map((json) =>
                ShuttleNotification.fromOdoo(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Fallback to searchRead
    }

    final domain = <List<dynamic>>[];
    if (passengerId != null) {
      domain.add(['passenger_id', '=', passengerId]);
    }
    if (tripId != null) {
      domain.add(['trip_id', '=', tripId]);
    }

    final result = await _client.searchRead(
      model: _notificationModel,
      domain: domain,
      fields: _notificationFields,
      order: 'create_date desc',
      limit: limit,
    );

    return result.map((json) => ShuttleNotification.fromOdoo(json)).toList();
  }

  /// الحصول على الإشعارات غير المقروءة
  Future<List<ShuttleNotification>> getUnreadNotifications(
      int passengerId) async {
    final result = await _client.searchRead(
      model: _notificationModel,
      domain: [
        ['passenger_id', '=', passengerId],
        ['status', 'not in', ['read']],
      ],
      fields: _notificationFields,
      order: 'create_date desc',
    );

    return result.map((json) => ShuttleNotification.fromOdoo(json)).toList();
  }

  /// تحديث حالة الإشعار كمقروء
  Future<bool> markAsRead(int notificationId) async {
    try {
      await _client.callKw(
        model: _notificationModel,
        method: 'action_mark_read',
        args: [
          [notificationId]
        ],
      );
      return true;
    } catch (e) {
      // Fallback to direct write
      return await _client.write(
        model: _notificationModel,
        ids: [notificationId],
        values: {
          'status': 'read',
          'read_date': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// تحديث حالة الإشعار كمستلم
  Future<bool> markAsDelivered(int notificationId) async {
    try {
      await _client.callKw(
        model: _notificationModel,
        method: 'action_mark_delivered',
        args: [
          [notificationId]
        ],
      );
      return true;
    } catch (e) {
      return await _client.write(
        model: _notificationModel,
        ids: [notificationId],
        values: {
          'status': 'delivered',
          'delivered_date': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// إعادة محاولة إرسال إشعار فاشل
  Future<bool> retryNotification(int notificationId) async {
    try {
      await _client.callKw(
        model: _notificationModel,
        method: 'action_retry',
        args: [
          [notificationId]
        ],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount(int passengerId) async {
    return await _client.searchCount(
      model: _notificationModel,
      domain: [
        ['passenger_id', '=', passengerId],
        ['status', 'not in', ['read']],
      ],
    );
  }

  /// الحقول المطلوبة
  static const List<String> _notificationFields = [
    'id',
    'trip_id',
    'trip_line_id',
    'passenger_id',
    'notification_type',
    'channel',
    'status',
    'message_content',
    'template_id',
    'sent_date',
    'delivered_date',
    'read_date',
    'api_response',
    'error_message',
    'recipient_phone',
    'recipient_email',
    'provider_message_id',
    'retry_count',
    'create_date',
  ];

  // ============================================================
  // 📱 إرسال إشعارات عبر REST API
  // ============================================================

  /// إرسال إشعار اقتراب السائق
  /// يستخدم Odoo ORM مباشرة (REST API غير مدعوم حالياً)
  Future<NotificationSendResult> sendApproachingNotification(
    int tripLineId, {
    int? eta,
  }) async {
    // استخدام Odoo ORM مباشرة
    try {
      final result = await _client.callKw(
        model: _tripLineModel,
        method: 'action_send_approaching_notification',
        args: [
          [tripLineId]
        ],
      );

      return NotificationSendResult(
        success: result != false && result != null,
        message: 'تم إرسال إشعار الاقتراب',
      );
    } catch (e) {
      return NotificationSendResult(
        success: false,
        message: 'فشل إرسال إشعار الاقتراب: $e',
      );
    }
  }

  /// إرسال إشعار وصول السائق
  /// يستخدم Odoo ORM مباشرة (REST API غير مدعوم حالياً)
  Future<NotificationSendResult> sendArrivedNotification(int tripLineId) async {
    // استخدام Odoo ORM مباشرة
    try {
      final result = await _client.callKw(
        model: _tripLineModel,
        method: 'action_send_arrived_notification',
        args: [
          [tripLineId]
        ],
      );

      return NotificationSendResult(
        success: result != false && result != null,
        message: 'تم إرسال إشعار الوصول',
      );
    } catch (e) {
      return NotificationSendResult(
        success: false,
        message: 'فشل إرسال إشعار الوصول: $e',
      );
    }
  }

  /// إرسال إشعار مخصص
  /// يستخدم Odoo ORM مباشرة
  Future<NotificationSendResult> sendCustomNotification({
    required int passengerId,
    required int tripId,
    required String message,
    String channel = 'whatsapp',
  }) async {
    // استخدام Odoo ORM مباشرة - إنشاء إشعار
    try {
      final notificationId = await _client.create(
        model: _notificationModel,
        values: {
          'passenger_id': passengerId,
          'trip_id': tripId,
          'notification_type': 'custom',
          'channel': channel,
          'message_content': message,
          'status': 'pending',
        },
      );

      // محاولة إرسال الإشعار
      await _client.callKw(
        model: _notificationModel,
        method: 'action_send',
        args: [
          [notificationId]
        ],
      );

      return NotificationSendResult(
        success: true,
        notificationId: notificationId,
        message: 'تم إرسال الإشعار المخصص',
        channel: channel,
      );
    } catch (e) {
      return NotificationSendResult(
        success: false,
        message: 'فشل إرسال الإشعار المخصص: $e',
      );
    }
  }

  /// إرسال إشعار لجميع ركاب الرحلة
  /// يستخدم Odoo ORM مباشرة
  Future<NotificationSendResult> sendNotificationToAllPassengers({
    required int tripId,
    required String notificationType,
    String? message,
  }) async {
    // استخدام Odoo ORM مباشرة
    try {
      final result = await _client.callKw(
        model: 'shuttle.trip',
        method: 'action_notify_all_passengers',
        args: [
          [tripId]
        ],
        kwargs: {
          'notification_type': notificationType,
          if (message != null) 'message': message,
        },
      );

      return NotificationSendResult(
        success: result != false && result != null,
        message: 'تم إرسال الإشعارات لجميع الركاب',
      );
    } catch (e) {
      return NotificationSendResult(
        success: false,
        message: 'فشل إرسال الإشعارات الجماعية: $e',
      );
    }
  }

  /// الحصول على قوالب الرسائل
  /// يستخدم Odoo ORM مباشرة
  Future<List<MessageTemplate>> getMessageTemplates({
    String? notificationType,
    String? language,
    String? channel,
  }) async {
    // استخدام Odoo ORM مباشرة
    try {
      final domain = <List<dynamic>>[];
      if (notificationType != null) {
        domain.add(['notification_type', '=', notificationType]);
      }
      if (language != null) {
        domain.add(['language', '=', language]);
      }
      if (channel != null && channel != 'all') {
        domain.add(['channel', 'in', [channel, 'all']]);
      }

      final result = await _client.searchRead(
        model: 'shuttle.message.template',
        domain: domain,
        fields: [
          'id',
          'name',
          'notification_type',
          'language',
          'channel',
          'body',
          'is_default',
        ],
      );

      return result.map((json) => MessageTemplate.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// معاينة الرسالة
  /// يستخدم Odoo ORM مباشرة
  Future<String?> previewMessage({
    required int templateId,
    required Map<String, String> variables,
  }) async {
    // استخدام Odoo ORM مباشرة
    try {
      final result = await _client.callKw(
        model: 'shuttle.message.template',
        method: 'preview_message',
        args: [
          [templateId]
        ],
        kwargs: variables,
      );

      return result as String?;
    } catch (e) {
      return null;
    }
  }

  /// الحصول على إعدادات قناة الإشعار الافتراضية
  Future<NotificationChannelSettings?> getNotificationChannelSettings() async {
    // Default settings - يمكن جلبها من Odoo لاحقاً
    return const NotificationChannelSettings(
      defaultChannel: 'whatsapp',
      availableChannels: ['whatsapp', 'sms', 'push', 'email'],
    );
  }
}

/// نتيجة إرسال الإشعار
class NotificationSendResult {
  final bool success;
  final int? notificationId;
  final String? message;
  final String? channel;

  const NotificationSendResult({
    required this.success,
    this.notificationId,
    this.message,
    this.channel,
  });

  bool get isSuccess => success;
  bool get isError => !success;
}

