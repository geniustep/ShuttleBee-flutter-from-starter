import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 🔔 ShuttleBee Notification API Service
/// خدمة API للإشعارات - تتواصل مع endpoints الإشعارات في الخادم
class ShuttleNotificationApiService {
  final Dio _dio;
  final String _baseUrl;

  ShuttleNotificationApiService({
    required Dio dio,
    String? baseUrl,
  })  : _dio = dio,
        // Notifications are sent via ShuttleBee REST endpoints.
        _baseUrl = baseUrl ?? EnvConfig.shuttleBeeApiBaseUrl;

  // ============================================================
  // 📱 إرسال إشعار Approaching (السائق يقترب)
  // ============================================================

  /// إرسال إشعار اقتراب السائق لراكب معين
  /// POST /api/v1/shuttle/trip-line/{trip_line_id}/notify/approaching
  Future<NotificationApiResponse> sendApproachingNotification(
    int tripLineId, {
    int? eta, // الوقت المتوقع للوصول بالدقائق
  }) async {
    try {
      AppLogger.info(
          '📤 Sending approaching notification for trip_line: $tripLineId');

      final response = await _dio.post(
        '$_baseUrl/api/v1/shuttle/trip-line/$tripLineId/notify/approaching',
        data: {
          if (eta != null) 'eta': eta,
        },
      );

      return NotificationApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error(
          '❌ Failed to send approaching notification: ${e.message}');
      return NotificationApiResponse.error(
        e.response?.data?['message'] ?? 'فشل إرسال إشعار الاقتراب',
      );
    } catch (e) {
      AppLogger.error(
          '❌ Unexpected error sending approaching notification: $e');
      return NotificationApiResponse.error('حدث خطأ غير متوقع');
    }
  }

  // ============================================================
  // 📱 إرسال إشعار Arrived (السائق وصل)
  // ============================================================

  /// إرسال إشعار وصول السائق لراكب معين
  /// POST /api/v1/shuttle/trip-line/{trip_line_id}/notify/arrived
  Future<NotificationApiResponse> sendArrivedNotification(
      int tripLineId) async {
    try {
      AppLogger.info(
          '📤 Sending arrived notification for trip_line: $tripLineId');

      final response = await _dio.post(
        '$_baseUrl/api/v1/shuttle/trip-line/$tripLineId/notify/arrived',
      );

      return NotificationApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to send arrived notification: ${e.message}');
      return NotificationApiResponse.error(
        e.response?.data?['message'] ?? 'فشل إرسال إشعار الوصول',
      );
    } catch (e) {
      AppLogger.error('❌ Unexpected error sending arrived notification: $e');
      return NotificationApiResponse.error('حدث خطأ غير متوقع');
    }
  }

  // ============================================================
  // 📱 إرسال إشعار مخصص
  // ============================================================

  /// إرسال إشعار مخصص
  /// POST /api/v1/shuttle/notification/send
  Future<NotificationApiResponse> sendCustomNotification({
    required int passengerId,
    required int tripId,
    required String message,
    String channel = 'whatsapp',
    String notificationType = 'custom',
  }) async {
    try {
      AppLogger.info(
          '📤 Sending custom notification to passenger: $passengerId');

      final response = await _dio.post(
        '$_baseUrl/api/v1/shuttle/notification/send',
        data: {
          'passenger_id': passengerId,
          'trip_id': tripId,
          'notification_type': notificationType,
          'channel': channel,
          'message': message,
        },
      );

      return NotificationApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to send custom notification: ${e.message}');
      return NotificationApiResponse.error(
        e.response?.data?['message'] ?? 'فشل إرسال الإشعار المخصص',
      );
    } catch (e) {
      AppLogger.error('❌ Unexpected error sending custom notification: $e');
      return NotificationApiResponse.error('حدث خطأ غير متوقع');
    }
  }

  // ============================================================
  // 📱 إرسال إشعار لجميع ركاب الرحلة
  // ============================================================

  /// إرسال إشعار لجميع ركاب الرحلة
  /// POST /api/v1/shuttle/trip/{trip_id}/notify/all
  Future<NotificationApiResponse> sendNotificationToAllPassengers({
    required int tripId,
    required String notificationType,
    String? message,
  }) async {
    try {
      AppLogger.info(
          '📤 Sending notification to all passengers in trip: $tripId');

      final response = await _dio.post(
        '$_baseUrl/api/v1/shuttle/trip/$tripId/notify/all',
        data: {
          'notification_type': notificationType,
          if (message != null) 'message': message,
        },
      );

      return NotificationApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to send notification to all: ${e.message}');
      return NotificationApiResponse.error(
        e.response?.data?['message'] ?? 'فشل إرسال الإشعار الجماعي',
      );
    } catch (e) {
      AppLogger.error('❌ Unexpected error sending notification to all: $e');
      return NotificationApiResponse.error('حدث خطأ غير متوقع');
    }
  }

  // ============================================================
  // 📋 الحصول على قوالب الرسائل
  // ============================================================

  /// الحصول على قوالب الرسائل
  /// GET /api/v1/shuttle/message-templates
  Future<List<MessageTemplate>> getMessageTemplates({
    String? notificationType,
    String? language,
    String? channel,
  }) async {
    try {
      AppLogger.info('📥 Fetching message templates');

      final response = await _dio.get(
        '$_baseUrl/api/v1/shuttle/message-templates',
        queryParameters: {
          if (notificationType != null) 'notification_type': notificationType,
          if (language != null) 'language': language,
          if (channel != null) 'channel': channel,
        },
      );

      final templates = (response.data['templates'] as List?)
              ?.map((t) => MessageTemplate.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];

      AppLogger.info('✅ Fetched ${templates.length} message templates');
      return templates;
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to fetch message templates: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.error('❌ Unexpected error fetching message templates: $e');
      return [];
    }
  }

  // ============================================================
  // 📝 معاينة الرسالة
  // ============================================================

  /// معاينة الرسالة قبل الإرسال
  /// POST /api/v1/shuttle/message-templates/{template_id}/preview
  Future<String?> previewMessage({
    required int templateId,
    required Map<String, String> variables,
  }) async {
    try {
      AppLogger.info('📝 Previewing message template: $templateId');

      final response = await _dio.post(
        '$_baseUrl/api/v1/shuttle/message-templates/$templateId/preview',
        data: variables,
      );

      return response.data['preview'] as String?;
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to preview message: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.error('❌ Unexpected error previewing message: $e');
      return null;
    }
  }

  // ============================================================
  // 📊 حالة الإشعار
  // ============================================================

  /// الحصول على حالة إشعار معين
  /// GET /api/v1/shuttle/notification/{notification_id}/status
  Future<NotificationStatusResponse?> getNotificationStatus(
    int notificationId,
  ) async {
    try {
      AppLogger.info('📊 Fetching notification status: $notificationId');

      final response = await _dio.get(
        '$_baseUrl/api/v1/shuttle/notification/$notificationId/status',
      );

      return NotificationStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to get notification status: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.error('❌ Unexpected error getting notification status: $e');
      return null;
    }
  }

  // ============================================================
  // 🔄 إعادة محاولة إرسال الإشعار
  // ============================================================

  /// إعادة محاولة إرسال إشعار فاشل
  /// POST /api/v1/shuttle/notification/{notification_id}/retry
  Future<NotificationApiResponse> retryNotification(int notificationId) async {
    try {
      AppLogger.info('🔄 Retrying notification: $notificationId');

      final response = await _dio.post(
        '$_baseUrl/api/v1/shuttle/notification/$notificationId/retry',
      );

      return NotificationApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to retry notification: ${e.message}');
      return NotificationApiResponse.error(
        e.response?.data?['message'] ?? 'فشل إعادة محاولة الإرسال',
      );
    } catch (e) {
      AppLogger.error('❌ Unexpected error retrying notification: $e');
      return NotificationApiResponse.error('حدث خطأ غير متوقع');
    }
  }

  // ============================================================
  // 📜 سجل الإشعارات
  // ============================================================

  /// الحصول على سجل إشعارات راكب معين
  /// GET /api/v1/shuttle/passenger/{passenger_id}/notifications
  Future<List<NotificationHistoryItem>> getPassengerNotifications(
    int passengerId, {
    int limit = 50,
    int? tripId,
  }) async {
    try {
      AppLogger.info('📜 Fetching notifications for passenger: $passengerId');

      final response = await _dio.get(
        '$_baseUrl/api/v1/shuttle/passenger/$passengerId/notifications',
        queryParameters: {
          'limit': limit,
          if (tripId != null) 'trip_id': tripId,
        },
      );

      final notifications = (response.data['notifications'] as List?)
              ?.map((n) =>
                  NotificationHistoryItem.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [];

      AppLogger.info('✅ Fetched ${notifications.length} notifications');
      return notifications;
    } on DioException catch (e) {
      AppLogger.error(
          '❌ Failed to fetch passenger notifications: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.error(
          '❌ Unexpected error fetching passenger notifications: $e');
      return [];
    }
  }

  // ============================================================
  // ⚙️ إعدادات القناة الافتراضية
  // ============================================================

  /// الحصول على إعدادات قناة الإشعار الافتراضية
  /// GET /api/v1/shuttle/settings/notification-channel
  Future<NotificationChannelSettings?> getNotificationChannelSettings() async {
    try {
      AppLogger.info('⚙️ Fetching notification channel settings');

      final response = await _dio.get(
        '$_baseUrl/api/v1/shuttle/settings/notification-channel',
      );

      return NotificationChannelSettings.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error(
          '❌ Failed to get notification channel settings: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.error(
          '❌ Unexpected error getting notification channel settings: $e');
      return null;
    }
  }
}

// ============================================================
// 📦 Response Models
// ============================================================

/// استجابة API الإشعارات
class NotificationApiResponse {
  final bool success;
  final int? notificationId;
  final String? channel;
  final String? status;
  final String? message;
  final String? errorMessage;

  const NotificationApiResponse({
    required this.success,
    this.notificationId,
    this.channel,
    this.status,
    this.message,
    this.errorMessage,
  });

  factory NotificationApiResponse.fromJson(Map<String, dynamic> json) {
    return NotificationApiResponse(
      success: json['success'] as bool? ?? false,
      notificationId: json['notification_id'] as int?,
      channel: json['channel'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String?,
    );
  }

  factory NotificationApiResponse.error(String message) {
    return NotificationApiResponse(
      success: false,
      errorMessage: message,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}

/// قالب الرسالة
class MessageTemplate {
  final int id;
  final String name;
  final String notificationType;
  final String language;
  final String channel;
  final String body;
  final bool isDefault;

  const MessageTemplate({
    required this.id,
    required this.name,
    required this.notificationType,
    required this.language,
    required this.channel,
    required this.body,
    this.isDefault = false,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? '',
      language: json['language'] as String? ?? 'ar',
      channel: json['channel'] as String? ?? 'all',
      body: json['body'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notification_type': notificationType,
      'language': language,
      'channel': channel,
      'body': body,
      'is_default': isDefault,
    };
  }
}

/// حالة الإشعار
class NotificationStatusResponse {
  final int id;
  final String status;
  final String channel;
  final DateTime? sentDate;
  final DateTime? deliveredDate;
  final DateTime? readDate;
  final String? providerMessageId;

  const NotificationStatusResponse({
    required this.id,
    required this.status,
    required this.channel,
    this.sentDate,
    this.deliveredDate,
    this.readDate,
    this.providerMessageId,
  });

  factory NotificationStatusResponse.fromJson(Map<String, dynamic> json) {
    return NotificationStatusResponse(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      channel: json['channel'] as String? ?? '',
      sentDate: _parseDateTime(json['sent_date']),
      deliveredDate: _parseDateTime(json['delivered_date']),
      readDate: _parseDateTime(json['read_date']),
      providerMessageId: json['provider_message_id'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null || value == false) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// هل تم التسليم
  bool get isDelivered => status == 'delivered' || status == 'read';

  /// هل تمت القراءة
  bool get isRead => status == 'read';

  /// هل فشل الإرسال
  bool get isFailed => status == 'failed';

  /// هل في الانتظار
  bool get isPending => status == 'pending';
}

/// عنصر سجل الإشعارات
class NotificationHistoryItem {
  final int id;
  final String notificationType;
  final String channel;
  final String status;
  final String messageContent;
  final DateTime createDate;
  final DateTime? sentDate;
  final DateTime? deliveredDate;
  final DateTime? readDate;

  const NotificationHistoryItem({
    required this.id,
    required this.notificationType,
    required this.channel,
    required this.status,
    required this.messageContent,
    required this.createDate,
    this.sentDate,
    this.deliveredDate,
    this.readDate,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id'] as int? ?? 0,
      notificationType: json['notification_type'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      messageContent: json['message_content'] as String? ?? '',
      createDate:
          NotificationStatusResponse._parseDateTime(json['create_date']) ??
              DateTime.now(),
      sentDate: NotificationStatusResponse._parseDateTime(json['sent_date']),
      deliveredDate:
          NotificationStatusResponse._parseDateTime(json['delivered_date']),
      readDate: NotificationStatusResponse._parseDateTime(json['read_date']),
    );
  }
}

/// إعدادات قناة الإشعار
class NotificationChannelSettings {
  final String defaultChannel;
  final List<String> availableChannels;

  const NotificationChannelSettings({
    required this.defaultChannel,
    required this.availableChannels,
  });

  factory NotificationChannelSettings.fromJson(Map<String, dynamic> json) {
    return NotificationChannelSettings(
      defaultChannel: json['default_channel'] as String? ?? 'whatsapp',
      availableChannels: (json['available_channels'] as List?)
              ?.map((c) => c as String)
              .toList() ??
          ['whatsapp', 'sms', 'push', 'email'],
    );
  }
}

// ============================================================
// 🔌 Provider
// ============================================================

/// Provider للحصول على خدمة API الإشعارات
final shuttleNotificationApiServiceProvider =
    Provider<ShuttleNotificationApiService>((ref) {
  // Notifications are sent via ShuttleBee REST endpoints and may live on a different base URL.
  final dioClient = DioClient(
    baseUrl: EnvConfig.shuttleBeeApiBaseUrl,
    sessionStorageKey: StorageKeys.shuttleBeeSessionId,
  );

  // إضافة interceptor للمصادقة
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value.user;

  // استخدام session_id المخزن للمصادقة
  if (user != null) {
    // يمكن إضافة headers إضافية هنا إذا لزم الأمر
  }

  return ShuttleNotificationApiService(dio: dioClient.dio);
});
