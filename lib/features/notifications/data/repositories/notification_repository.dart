import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error_handling/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/shuttle_notification.dart';
import '../datasources/notification_remote_data_source.dart';
import '../services/shuttle_notification_api_service.dart';

/// 🔔 Notification Repository
/// Repository للتعامل مع الإشعارات
class NotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepository(this._dataSource);

  // ============================================================
  // 📤 إرسال الإشعارات
  // ============================================================

  /// إرسال إشعار اقتراب السائق
  Future<Either<Failure, NotificationSendResult>> sendApproachingNotification(
    int tripLineId, {
    int? eta,
  }) async {
    try {
      final result = await _dataSource.sendApproachingNotification(
        tripLineId,
        eta: eta,
      );

      if (result.success) {
        return Right(result);
      } else {
        return Left(ServerFailure(message: result.message ?? 'فشل إرسال إشعار الاقتراب'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في إرسال إشعار الاقتراب: $e'));
    }
  }

  /// إرسال إشعار وصول السائق
  Future<Either<Failure, NotificationSendResult>> sendArrivedNotification(
    int tripLineId,
  ) async {
    try {
      final result = await _dataSource.sendArrivedNotification(tripLineId);

      if (result.success) {
        return Right(result);
      } else {
        return Left(ServerFailure(message: result.message ?? 'فشل إرسال إشعار الوصول'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في إرسال إشعار الوصول: $e'));
    }
  }

  /// إرسال إشعار مخصص
  Future<Either<Failure, NotificationSendResult>> sendCustomNotification({
    required int passengerId,
    required int tripId,
    required String message,
    String channel = 'whatsapp',
  }) async {
    try {
      final result = await _dataSource.sendCustomNotification(
        passengerId: passengerId,
        tripId: tripId,
        message: message,
        channel: channel,
      );

      if (result.success) {
        return Right(result);
      } else {
        return Left(ServerFailure(message: result.message ?? 'فشل إرسال الإشعار المخصص'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في إرسال الإشعار المخصص: $e'));
    }
  }

  /// إرسال إشعار لجميع ركاب الرحلة
  Future<Either<Failure, NotificationSendResult>> sendNotificationToAllPassengers({
    required int tripId,
    required String notificationType,
    String? message,
  }) async {
    try {
      final result = await _dataSource.sendNotificationToAllPassengers(
        tripId: tripId,
        notificationType: notificationType,
        message: message,
      );

      if (result.success) {
        return Right(result);
      } else {
        return Left(ServerFailure(message: result.message ?? 'فشل إرسال الإشعارات الجماعية'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في إرسال الإشعارات الجماعية: $e'));
    }
  }

  // ============================================================
  // 📥 استرجاع الإشعارات
  // ============================================================

  /// الحصول على إشعارات رحلة معينة
  Future<Either<Failure, List<ShuttleNotification>>> getTripNotifications(
    int tripId,
  ) async {
    try {
      final notifications = await _dataSource.getTripNotifications(tripId);
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في جلب إشعارات الرحلة: $e'));
    }
  }

  /// الحصول على إشعارات راكب معين
  Future<Either<Failure, List<ShuttleNotification>>> getPassengerNotifications(
    int passengerId, {
    int limit = 50,
  }) async {
    try {
      final notifications = await _dataSource.getPassengerNotifications(
        passengerId,
        limit: limit,
      );
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في جلب إشعارات الراكب: $e'));
    }
  }

  /// الحصول على الإشعارات الأخيرة
  Future<Either<Failure, List<ShuttleNotification>>> getRecentNotifications({
    int? passengerId,
    int? tripId,
    int limit = 50,
  }) async {
    try {
      final notifications = await _dataSource.getRecentNotifications(
        passengerId: passengerId,
        tripId: tripId,
        limit: limit,
      );
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في جلب الإشعارات الأخيرة: $e'));
    }
  }

  /// الحصول على الإشعارات غير المقروءة
  Future<Either<Failure, List<ShuttleNotification>>> getUnreadNotifications(
    int passengerId,
  ) async {
    try {
      final notifications = await _dataSource.getUnreadNotifications(passengerId);
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في جلب الإشعارات غير المقروءة: $e'));
    }
  }

  /// عدد الإشعارات غير المقروءة
  Future<Either<Failure, int>> getUnreadCount(int passengerId) async {
    try {
      final count = await _dataSource.getUnreadCount(passengerId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في جلب عدد الإشعارات: $e'));
    }
  }

  // ============================================================
  // 🔄 تحديث حالة الإشعار
  // ============================================================

  /// تحديث حالة الإشعار كمقروء
  Future<Either<Failure, bool>> markAsRead(int notificationId) async {
    try {
      final success = await _dataSource.markAsRead(notificationId);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في تحديث حالة الإشعار: $e'));
    }
  }

  /// تحديث حالة الإشعار كمستلم
  Future<Either<Failure, bool>> markAsDelivered(int notificationId) async {
    try {
      final success = await _dataSource.markAsDelivered(notificationId);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في تحديث حالة الإشعار: $e'));
    }
  }

  /// إعادة محاولة إرسال إشعار فاشل
  Future<Either<Failure, bool>> retryNotification(int notificationId) async {
    try {
      final success = await _dataSource.retryNotification(notificationId);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في إعادة محاولة الإرسال: $e'));
    }
  }

  // ============================================================
  // 📋 قوالب الرسائل
  // ============================================================

  /// الحصول على قوالب الرسائل
  Future<Either<Failure, List<MessageTemplate>>> getMessageTemplates({
    String? notificationType,
    String? language,
    String? channel,
  }) async {
    try {
      final templates = await _dataSource.getMessageTemplates(
        notificationType: notificationType,
        language: language,
        channel: channel,
      );
      return Right(templates);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في جلب قوالب الرسائل: $e'));
    }
  }

  /// معاينة الرسالة
  Future<Either<Failure, String>> previewMessage({
    required int templateId,
    required Map<String, String> variables,
  }) async {
    try {
      final preview = await _dataSource.previewMessage(
        templateId: templateId,
        variables: variables,
      );

      if (preview != null) {
        return Right(preview);
      } else {
        return Left(ServerFailure(message: 'فشل معاينة الرسالة'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في معاينة الرسالة: $e'));
    }
  }

  // ============================================================
  // ⚙️ الإعدادات
  // ============================================================

  /// الحصول على إعدادات قناة الإشعار الافتراضية
  Future<Either<Failure, NotificationChannelSettings>> getNotificationChannelSettings() async {
    try {
      final settings = await _dataSource.getNotificationChannelSettings();

      if (settings != null) {
        return Right(settings);
      } else {
        return Right(const NotificationChannelSettings(
          defaultChannel: 'whatsapp',
          availableChannels: ['whatsapp', 'sms', 'push', 'email'],
        ));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ في جلب إعدادات الإشعارات: $e'));
    }
  }
}

// ============================================================
// 🔌 Providers
// ============================================================

/// Provider لمصدر بيانات الإشعارات
final notificationDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  final apiService = ref.watch(shuttleNotificationApiServiceProvider);

  if (client == null) {
    throw StateError('BridgeCore client is not initialized');
  }

  return NotificationRemoteDataSource(
    client,
    apiService: apiService,
  );
});

/// Provider لـ Repository الإشعارات
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dataSource = ref.watch(notificationDataSourceProvider);
  return NotificationRepository(dataSource);
});

