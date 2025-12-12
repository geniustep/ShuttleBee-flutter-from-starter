import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/shuttle_notification_api_service.dart';
import '../../domain/entities/shuttle_notification.dart';

/// إشعارات رحلة معينة
final tripNotificationsProvider = FutureProvider.autoDispose
    .family<List<ShuttleNotification>, int>((ref, tripId) async {
  final repository = ref.watch(notificationRepositoryProvider);
  
  final result = await repository.getTripNotifications(tripId);
  return result.fold(
    (failure) => [],
    (notifications) => notifications,
  );
});

/// إشعارات الراكب الحالي
final passengerNotificationsProvider =
    FutureProvider.autoDispose<List<ShuttleNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  final user = authState.asData?.value.user;
  if (user == null || user.partnerId == null) return [];

  final result = await repository.getPassengerNotifications(user.partnerId!);
  return result.fold(
    (failure) => [],
    (notifications) => notifications,
  );
});

/// الإشعارات غير المقروءة
final unreadNotificationsProvider =
    FutureProvider.autoDispose<List<ShuttleNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  final user = authState.asData?.value.user;
  if (user == null || user.partnerId == null) return [];

  final result = await repository.getUnreadNotifications(user.partnerId!);
  return result.fold(
    (failure) => [],
    (notifications) => notifications,
  );
});

/// عدد الإشعارات غير المقروءة
final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  final user = authState.asData?.value.user;
  if (user == null || user.partnerId == null) return 0;

  final result = await repository.getUnreadCount(user.partnerId!);
  return result.fold(
    (failure) => 0,
    (count) => count,
  );
});

/// قوالب الرسائل
final messageTemplatesProvider = FutureProvider.autoDispose
    .family<List<MessageTemplate>, MessageTemplateFilter?>((ref, filter) async {
  final repository = ref.watch(notificationRepositoryProvider);

  final result = await repository.getMessageTemplates(
    notificationType: filter?.notificationType,
    language: filter?.language,
    channel: filter?.channel,
  );

  return result.fold(
    (failure) => [],
    (templates) => templates,
  );
});

/// فلتر قوالب الرسائل
class MessageTemplateFilter {
  final String? notificationType;
  final String? language;
  final String? channel;

  const MessageTemplateFilter({
    this.notificationType,
    this.language,
    this.channel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTemplateFilter &&
          runtimeType == other.runtimeType &&
          notificationType == other.notificationType &&
          language == other.language &&
          channel == other.channel;

  @override
  int get hashCode =>
      notificationType.hashCode ^ language.hashCode ^ channel.hashCode;
}

/// إعدادات قناة الإشعار
final notificationChannelSettingsProvider =
    FutureProvider.autoDispose<NotificationChannelSettings?>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);

  final result = await repository.getNotificationChannelSettings();
  return result.fold(
    (failure) => null,
    (settings) => settings,
  );
});

// ============================================================
// 🔔 Notification Actions Notifier
// ============================================================

/// حالة إرسال الإشعار
@immutable
class NotificationSendState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;
  final int? notificationId;

  const NotificationSendState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
    this.notificationId,
  });

  const NotificationSendState.initial()
      : isLoading = false,
        isSuccess = false,
        errorMessage = null,
        successMessage = null,
        notificationId = null;

  const NotificationSendState.loading()
      : isLoading = true,
        isSuccess = false,
        errorMessage = null,
        successMessage = null,
        notificationId = null;

  NotificationSendState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    String? successMessage,
    int? notificationId,
  }) {
    return NotificationSendState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}

/// Notification Actions Notifier - إدارة إجراءات الإشعارات
class NotificationActionsNotifier extends StateNotifier<NotificationSendState> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationActionsNotifier(this._repository, this._ref)
      : super(const NotificationSendState.initial());

  /// إعادة تعيين الحالة
  void reset() {
    state = const NotificationSendState.initial();
  }

  /// إرسال إشعار اقتراب السائق
  Future<bool> sendApproachingNotification(
    int tripLineId, {
    int? eta,
  }) async {
    state = const NotificationSendState.loading();
    AppLogger.info('📤 Sending approaching notification for trip_line: $tripLineId');

    final result = await _repository.sendApproachingNotification(
      tripLineId,
      eta: eta,
    );

    return result.fold(
      (failure) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: false,
          errorMessage: failure.message,
        );
        AppLogger.error('❌ Failed: ${failure.message}');
        return false;
      },
      (sendResult) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: true,
          successMessage: sendResult.message ?? 'تم إرسال إشعار الاقتراب',
          notificationId: sendResult.notificationId,
        );
        AppLogger.info('✅ Success: ${sendResult.message}');
        _invalidateNotifications();
        return true;
      },
    );
  }

  /// إرسال إشعار وصول السائق
  Future<bool> sendArrivedNotification(int tripLineId) async {
    state = const NotificationSendState.loading();
    AppLogger.info('📤 Sending arrived notification for trip_line: $tripLineId');

    final result = await _repository.sendArrivedNotification(tripLineId);

    return result.fold(
      (failure) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: false,
          errorMessage: failure.message,
        );
        AppLogger.error('❌ Failed: ${failure.message}');
        return false;
      },
      (sendResult) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: true,
          successMessage: sendResult.message ?? 'تم إرسال إشعار الوصول',
          notificationId: sendResult.notificationId,
        );
        AppLogger.info('✅ Success: ${sendResult.message}');
        _invalidateNotifications();
        return true;
      },
    );
  }

  /// إرسال إشعار مخصص
  Future<bool> sendCustomNotification({
    required int passengerId,
    required int tripId,
    required String message,
    String channel = 'whatsapp',
  }) async {
    state = const NotificationSendState.loading();
    AppLogger.info('📤 Sending custom notification to passenger: $passengerId');

    final result = await _repository.sendCustomNotification(
      passengerId: passengerId,
      tripId: tripId,
      message: message,
      channel: channel,
    );

    return result.fold(
      (failure) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: false,
          errorMessage: failure.message,
        );
        AppLogger.error('❌ Failed: ${failure.message}');
        return false;
      },
      (sendResult) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: true,
          successMessage: sendResult.message ?? 'تم إرسال الإشعار المخصص',
          notificationId: sendResult.notificationId,
        );
        AppLogger.info('✅ Success: ${sendResult.message}');
        _invalidateNotifications();
        return true;
      },
    );
  }

  /// إرسال إشعار لجميع ركاب الرحلة
  Future<bool> sendNotificationToAllPassengers({
    required int tripId,
    required String notificationType,
    String? message,
  }) async {
    state = const NotificationSendState.loading();
    AppLogger.info('📤 Sending notification to all passengers in trip: $tripId');

    final result = await _repository.sendNotificationToAllPassengers(
      tripId: tripId,
      notificationType: notificationType,
      message: message,
    );

    return result.fold(
      (failure) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: false,
          errorMessage: failure.message,
        );
        AppLogger.error('❌ Failed: ${failure.message}');
        return false;
      },
      (sendResult) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: true,
          successMessage: sendResult.message ?? 'تم إرسال الإشعارات لجميع الركاب',
        );
        AppLogger.info('✅ Success: ${sendResult.message}');
        _invalidateNotifications();
        return true;
      },
    );
  }

  /// تحديث إشعار كمقروء
  Future<bool> markAsRead(int notificationId) async {
    final result = await _repository.markAsRead(notificationId);

    return result.fold(
      (failure) => false,
      (success) {
        if (success) {
          _invalidateNotifications();
        }
        return success;
      },
    );
  }

  /// تحديث جميع الإشعارات كمقروءة
  Future<void> markAllAsRead(List<int> notificationIds) async {
    for (final id in notificationIds) {
      await _repository.markAsRead(id);
    }
    _invalidateNotifications();
  }

  /// إعادة محاولة إرسال إشعار
  Future<bool> retryNotification(int notificationId) async {
    state = const NotificationSendState.loading();

    final result = await _repository.retryNotification(notificationId);

    return result.fold(
      (failure) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (success) {
        state = NotificationSendState(
          isLoading: false,
          isSuccess: success,
          successMessage: success ? 'تمت إعادة المحاولة بنجاح' : null,
        );
        if (success) {
          _invalidateNotifications();
        }
        return success;
      },
    );
  }

  /// تحديث قوائم الإشعارات
  void _invalidateNotifications() {
    _ref.invalidate(passengerNotificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
    _ref.invalidate(unreadNotificationsProvider);
  }
}

/// Notification Actions Provider
final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, NotificationSendState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationActionsNotifier(repository, ref);
});

// ============================================================
// 🔔 Trip Line Notification State
// ============================================================

/// حالة إشعار سطر الرحلة (الراكب)
@immutable
class TripLineNotificationState {
  final int tripLineId;
  final bool approachingNotified;
  final bool arrivedNotified;
  final bool isApproachingLoading;
  final bool isArrivedLoading;
  final String? lastError;

  const TripLineNotificationState({
    required this.tripLineId,
    this.approachingNotified = false,
    this.arrivedNotified = false,
    this.isApproachingLoading = false,
    this.isArrivedLoading = false,
    this.lastError,
  });

  TripLineNotificationState copyWith({
    bool? approachingNotified,
    bool? arrivedNotified,
    bool? isApproachingLoading,
    bool? isArrivedLoading,
    String? lastError,
  }) {
    return TripLineNotificationState(
      tripLineId: tripLineId,
      approachingNotified: approachingNotified ?? this.approachingNotified,
      arrivedNotified: arrivedNotified ?? this.arrivedNotified,
      isApproachingLoading: isApproachingLoading ?? this.isApproachingLoading,
      isArrivedLoading: isArrivedLoading ?? this.isArrivedLoading,
      lastError: lastError,
    );
  }
}

/// Notifier لحالة إشعارات سطر الرحلة
class TripLineNotificationNotifier extends StateNotifier<TripLineNotificationState> {
  final NotificationRepository _repository;

  TripLineNotificationNotifier(
    int tripLineId,
    this._repository, {
    bool initialApproachingNotified = false,
    bool initialArrivedNotified = false,
  }) : super(TripLineNotificationState(
          tripLineId: tripLineId,
          approachingNotified: initialApproachingNotified,
          arrivedNotified: initialArrivedNotified,
        ));

  /// إرسال إشعار اقتراب
  Future<bool> sendApproaching({int? eta}) async {
    if (state.approachingNotified || state.isApproachingLoading) {
      return false;
    }

    state = state.copyWith(isApproachingLoading: true, lastError: null);

    final result = await _repository.sendApproachingNotification(
      state.tripLineId,
      eta: eta,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isApproachingLoading: false,
          lastError: failure.message,
        );
        return false;
      },
      (sendResult) {
        state = state.copyWith(
          isApproachingLoading: false,
          approachingNotified: sendResult.success,
        );
        return sendResult.success;
      },
    );
  }

  /// إرسال إشعار وصول
  Future<bool> sendArrived() async {
    if (state.arrivedNotified || state.isArrivedLoading) {
      return false;
    }

    state = state.copyWith(isArrivedLoading: true, lastError: null);

    final result = await _repository.sendArrivedNotification(state.tripLineId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isArrivedLoading: false,
          lastError: failure.message,
        );
        return false;
      },
      (sendResult) {
        state = state.copyWith(
          isArrivedLoading: false,
          arrivedNotified: sendResult.success,
        );
        return sendResult.success;
      },
    );
  }

  /// تحديث حالة الإشعارات من البيانات الخارجية
  void updateFromExternal({
    bool? approachingNotified,
    bool? arrivedNotified,
  }) {
    state = state.copyWith(
      approachingNotified: approachingNotified,
      arrivedNotified: arrivedNotified,
    );
  }
}

/// Provider لحالة إشعارات سطر رحلة معين
final tripLineNotificationProvider = StateNotifierProvider.autoDispose
    .family<TripLineNotificationNotifier, TripLineNotificationState, TripLineNotificationParams>(
  (ref, params) {
    final repository = ref.watch(notificationRepositoryProvider);
    return TripLineNotificationNotifier(
      params.tripLineId,
      repository,
      initialApproachingNotified: params.approachingNotified,
      initialArrivedNotified: params.arrivedNotified,
    );
  },
);

/// معاملات Provider إشعارات سطر الرحلة
class TripLineNotificationParams {
  final int tripLineId;
  final bool approachingNotified;
  final bool arrivedNotified;

  const TripLineNotificationParams({
    required this.tripLineId,
    this.approachingNotified = false,
    this.arrivedNotified = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripLineNotificationParams &&
          runtimeType == other.runtimeType &&
          tripLineId == other.tripLineId;

  @override
  int get hashCode => tripLineId.hashCode;
}
