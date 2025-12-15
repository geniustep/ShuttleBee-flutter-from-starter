/// ShuttleBee Notification Entity - كيان الإشعار
/// يطابق نموذج shuttle.notification في Odoo
class ShuttleNotification {
  final int id;
  final int? tripId;
  final String? tripName;
  final int? tripLineId;
  final int passengerId;
  final String? passengerName;
  final NotificationType notificationType;
  final NotificationChannel channel;
  final NotificationStatus status;
  final String messageContent;
  final int? templateId;
  final DateTime? sentDate;
  final DateTime? deliveredDate;
  final DateTime? readDate;
  final String? apiResponse;
  final String? errorMessage;
  final String? recipientPhone;
  final String? recipientEmail;
  final String? providerMessageId;
  final int retryCount;
  final DateTime createDate;

  const ShuttleNotification({
    required this.id,
    this.tripId,
    this.tripName,
    this.tripLineId,
    required this.passengerId,
    this.passengerName,
    required this.notificationType,
    required this.channel,
    required this.status,
    required this.messageContent,
    this.templateId,
    this.sentDate,
    this.deliveredDate,
    this.readDate,
    this.apiResponse,
    this.errorMessage,
    this.recipientPhone,
    this.recipientEmail,
    this.providerMessageId,
    this.retryCount = 0,
    required this.createDate,
  });

  factory ShuttleNotification.fromOdoo(Map<String, dynamic> json) {
    return ShuttleNotification(
      id: json['id'] as int? ?? 0,
      tripId: _extractId(json['trip_id']),
      tripName: _extractName(json['trip_id']),
      tripLineId: _extractId(json['trip_line_id']),
      passengerId: _extractId(json['passenger_id']) ?? 0,
      passengerName: _extractName(json['passenger_id']),
      notificationType: NotificationType.fromString(
        _extractString(json['notification_type']) ?? 'custom',
      ),
      channel: NotificationChannel.fromString(
        _extractString(json['channel']) ?? 'push',
      ),
      status: NotificationStatus.fromString(
        _extractString(json['status']) ?? 'pending',
      ),
      messageContent: _extractString(json['message_content']) ?? '',
      templateId: _extractId(json['template_id']),
      sentDate: _parseDateTime(json['sent_date']),
      deliveredDate: _parseDateTime(json['delivered_date']),
      readDate: _parseDateTime(json['read_date']),
      apiResponse: _extractString(json['api_response']),
      errorMessage: _extractString(json['error_message']),
      recipientPhone: _extractString(json['recipient_phone']),
      recipientEmail: _extractString(json['recipient_email']),
      providerMessageId: _extractString(json['provider_message_id']),
      retryCount: json['retry_count'] as int? ?? 0,
      createDate: _parseDateTime(json['create_date']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'trip_line_id': tripLineId,
      'passenger_id': passengerId,
      'notification_type': notificationType.value,
      'channel': channel.value,
      'status': status.value,
      'message_content': messageContent,
      'template_id': templateId,
      'recipient_phone': recipientPhone,
      'recipient_email': recipientEmail,
    };
  }

  static String? _extractString(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int? _extractId(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) return value[0] as int?;
    return null;
  }

  static String? _extractName(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    if (value is List && value.length > 1) return value[1] as String?;
    return null;
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

  ShuttleNotification copyWith({
    int? id,
    int? tripId,
    String? tripName,
    int? tripLineId,
    int? passengerId,
    String? passengerName,
    NotificationType? notificationType,
    NotificationChannel? channel,
    NotificationStatus? status,
    String? messageContent,
    int? templateId,
    DateTime? sentDate,
    DateTime? deliveredDate,
    DateTime? readDate,
    String? apiResponse,
    String? errorMessage,
    String? recipientPhone,
    String? recipientEmail,
    String? providerMessageId,
    int? retryCount,
    DateTime? createDate,
  }) {
    return ShuttleNotification(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      tripName: tripName ?? this.tripName,
      tripLineId: tripLineId ?? this.tripLineId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      notificationType: notificationType ?? this.notificationType,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      messageContent: messageContent ?? this.messageContent,
      templateId: templateId ?? this.templateId,
      sentDate: sentDate ?? this.sentDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      readDate: readDate ?? this.readDate,
      apiResponse: apiResponse ?? this.apiResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      providerMessageId: providerMessageId ?? this.providerMessageId,
      retryCount: retryCount ?? this.retryCount,
      createDate: createDate ?? this.createDate,
    );
  }

  /// هل الإشعار مقروء
  bool get isRead => status == NotificationStatus.read;

  /// هل الإشعار مرسل
  bool get isSent =>
      status == NotificationStatus.sent ||
      status == NotificationStatus.delivered ||
      status == NotificationStatus.read;

  /// هل فشل الإرسال
  bool get isFailed => status == NotificationStatus.failed;

  /// هل يمكن إعادة المحاولة
  bool get canRetry => isFailed && retryCount < 3;

  /// الوقت منذ الإنشاء
  Duration get timeSinceCreation => DateTime.now().difference(createDate);

  @override
  String toString() =>
      'ShuttleNotification(id: $id, type: ${notificationType.value}, status: ${status.value})';
}

/// نوع الإشعار
enum NotificationType {
  approaching('approaching', 'اقتراب'),
  arrived('arrived', 'وصول'),
  tripStarted('trip_started', 'بدء الرحلة'),
  tripEnded('trip_ended', 'انتهاء الرحلة'),
  cancelled('cancelled', 'إلغاء'),
  reminder('reminder', 'تذكير'),
  custom('custom', 'مخصص');

  final String value;
  final String arabicLabel;

  const NotificationType(this.value, this.arabicLabel);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.custom,
    );
  }
}

/// قناة الإشعار
enum NotificationChannel {
  sms('sms', 'SMS', '📱'),
  whatsapp('whatsapp', 'WhatsApp', '💬'),
  push('push', 'إشعار فوري', '🔔'),
  email('email', 'بريد إلكتروني', '📧');

  final String value;
  final String label;
  final String icon;

  const NotificationChannel(this.value, this.label, this.icon);

  static NotificationChannel fromString(String value) {
    return NotificationChannel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationChannel.push,
    );
  }
}

/// حالة الإشعار
enum NotificationStatus {
  pending('pending', 'قيد الانتظار', 0xFFF59E0B),
  sent('sent', 'مرسل', 0xFF3B82F6),
  failed('failed', 'فشل', 0xFFEF4444),
  delivered('delivered', 'تم التسليم', 0xFF10B981),
  read('read', 'مقروء', 0xFF8B5CF6);

  final String value;
  final String arabicLabel;
  final int colorValue;

  const NotificationStatus(this.value, this.arabicLabel, this.colorValue);

  static NotificationStatus fromString(String value) {
    return NotificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationStatus.pending,
    );
  }
}
