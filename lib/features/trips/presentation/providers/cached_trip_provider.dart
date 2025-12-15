import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shuttlebee/presentation/providers/shuttlebee_api_providers.dart';
import '../../data/cache/trip_cache_service.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import 'trip_providers.dart';

/// 🚌 ShuttleBee Cached Trip Provider
/// نظام إدارة الرحلات مع التخزين المؤقت والتحديثات المتفائلة
///
/// المميزات:
/// ✅ تخزين الرحلات محلياً للعمل بدون إنترنت
/// ✅ تحديثات متفائلة فورية (Optimistic Updates)
/// ✅ مزامنة تلقائية عند الاتصال
/// ✅ إعادة محاولة تلقائية للعمليات الفاشلة
/// ✅ تجربة مستخدم سلسة كأنها لعبة

final _logger = Logger();

String _dateKey(DateTime date) =>
    DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];

int _driverIdFromAuth(Ref ref) {
  final auth = ref.read(authStateProvider);
  return auth.asData?.value.user?.id ?? 0;
}

String _driverTripsCacheKey({
  required int driverId,
  required DateTime date,
}) =>
    'driver_trips_${driverId}_${_dateKey(date)}';

/// Cache service provider
final tripCacheServiceProvider = Provider<TripCacheService>((ref) {
  return TripCacheService.instance;
});

/// Connectivity provider
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Is online provider
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (results) => !results.contains(ConnectivityResult.none),
    orElse: () => true,
  );
});

/// 🎮 Smart Trip State - حالة الرحلة الذكية
/// تدعم التحديثات المتفائلة والعمل بدون إنترنت
class SmartTripState {
  final Trip? trip;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final bool isFromCache;
  final DateTime? lastUpdated;
  final int pendingActionsCount;

  const SmartTripState({
    this.trip,
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.isFromCache = false,
    this.lastUpdated,
    this.pendingActionsCount = 0,
  });

  SmartTripState copyWith({
    Trip? trip,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    bool? isFromCache,
    DateTime? lastUpdated,
    int? pendingActionsCount,
  }) {
    return SmartTripState(
      trip: trip ?? this.trip,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      isFromCache: isFromCache ?? this.isFromCache,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      pendingActionsCount: pendingActionsCount ?? this.pendingActionsCount,
    );
  }

  /// هل البيانات جاهزة للعرض
  bool get hasData => trip != null;

  /// هل يوجد خطأ
  bool get hasError => error != null;

  /// هل يوجد عمليات معلقة
  bool get hasPendingActions => pendingActionsCount > 0;
}

/// 🎮 Smart Trip Notifier - مدير الرحلة الذكي
/// يوفر تجربة مستخدم سلسة مع تحديثات فورية
class SmartTripNotifier extends Notifier<SmartTripState> {
  TripRepository? get _repository => ref.read(tripRepositoryProvider);
  TripCacheService get _cache => ref.read(tripCacheServiceProvider);
  bool get _isOnline => ref.read(isOnlineProvider);

  int? _currentTripId;

  /// فحص إذا كان الـ provider لا يزال موجوداً
  bool get _isMounted {
    try {
      // محاولة الوصول للـ ref - إذا فشلت فهذا يعني أنه تم التخلص منه
      ref.read(tripCacheServiceProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  // شرط المنتج: حفظ الرحلات والركاب محلياً لليوم فقط
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _shouldCacheTrip(Trip trip) {
    final tripDate = DateTime(trip.date.year, trip.date.month, trip.date.day);
    return tripDate.isAtSameMomentAs(_today);
  }

  @override
  SmartTripState build() {
    // Reset state on user change to prevent cross-user data bleed on shared devices
    ref.listen<int?>(
      authStateProvider.select((s) => s.asData?.value.user?.id),
      (previous, next) {
        if (previous != next) {
          _currentTripId = null;
          state = const SmartTripState();
          _logger.d(
              '🧹 SmartTripNotifier reset due to user change: $previous -> $next');
        }
      },
    );

    // Initialize cache on first build
    _initCache();
    return const SmartTripState();
  }

  Future<void> _initCache() async {
    try {
      await _cache.init();
    } catch (e) {
      _logger.e('Failed to initialize cache', error: e);
    }
  }

  /// تحميل الرحلة - يستخدم الكاش أولاً ثم يحدث من الخادم
  Future<void> loadTrip(int tripId) async {
    _currentTripId = tripId;
    _logger.d('📍 loadTrip: Set _currentTripId = $tripId');

    // 1. أظهر البيانات المخزنة مباشرة (إن وجدت)
    final cachedTrip = await _cache.getCachedTrip(tripId);

    if (!_isMounted) return; // تحقق قبل تحديث الحالة

    if (cachedTrip != null) {
      // البيانات موجودة في الكاش - استخدمها مباشرة بدون جلب من السيرفر
      state = SmartTripState(
        trip: cachedTrip,
        isFromCache: true,
        lastUpdated: DateTime.now(),
        isSyncing: false, // لا نحتاج جلب من السيرفر
      );
      _logger.d(
          '📦 Loaded trip $tripId from cache (${cachedTrip.lines.length} passengers)');
    } else {
      // البيانات غير موجودة في الكاش - نجلب من السيرفر
      state = state.copyWith(isLoading: true);

      if (_isOnline) {
        await _refreshFromServer(tripId);
      } else {
        if (!_isMounted) return;
        state = state.copyWith(
          isLoading: false,
          error: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات مخزنة',
        );
      }
    }

    // 2. تحديث عدد العمليات المعلقة
    final pendingCount = await _cache.getPendingActionsCount();
    if (!_isMounted) return;
    state = state.copyWith(pendingActionsCount: pendingCount);
  }

  /// تحديث من الخادم
  Future<void> _refreshFromServer(int tripId) async {
    final repository = _repository;
    if (repository == null) return;

    try {
      final result = await repository.getTripById(tripId);

      if (!_isMounted) return; // تحقق قبل تحديث الحالة

      result.fold(
        (failure) {
          if (!_isMounted) return;
          // فشل التحديث - نبقي على البيانات المخزنة
          if (state.trip == null) {
            state = state.copyWith(
              isLoading: false,
              isSyncing: false,
              error: failure.message,
            );
          } else {
            // لدينا بيانات مخزنة، نبقي عليها
            state = state.copyWith(
              isSyncing: false,
            );
          }
          _logger.w('Failed to refresh trip $tripId: ${failure.message}');
        },
        (trip) async {
          // نجح التحديث - نخزن ونعرض
          if (_shouldCacheTrip(trip)) {
            await _cache.cacheTrip(trip);
          }
          if (!_isMounted) return;
          state = SmartTripState(
            trip: trip,
            isFromCache: false,
            lastUpdated: DateTime.now(),
          );
          _logger.d('✅ Refreshed trip $tripId from server');
        },
      );
    } catch (e) {
      _logger.e('Error refreshing trip $tripId', error: e);
      if (!_isMounted) return;
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
      );
    }
  }

  /// تحديث يدوي من الخادم
  Future<void> refresh() async {
    if (_currentTripId == null) return;

    state = state.copyWith(isSyncing: true);
    await _refreshFromServer(_currentTripId!);
  }

  // ============================================================
  // 🎮 OPTIMISTIC ACTIONS - تحديثات متفائلة فورية
  // ============================================================

  /// تسجيل صعود راكب - تحديث فوري
  Future<bool> markPassengerBoarded(int lineId) async {
    return _executeOptimisticAction(
      actionType: 'mark_boarded',
      lineId: lineId,
      newStatus: 'boarded',
      apiCall: () async => _repository?.markPassengerBoarded(lineId),
    );
  }

  /// تسجيل نزول راكب - تحديث فوري
  Future<bool> markPassengerDropped(int lineId) async {
    return _executeOptimisticAction(
      actionType: 'mark_dropped',
      lineId: lineId,
      newStatus: 'dropped',
      apiCall: () async => _repository?.markPassengerDropped(lineId),
    );
  }

  /// تسجيل غياب راكب - تحديث فوري
  Future<bool> markPassengerAbsent(int lineId) async {
    return _executeOptimisticAction(
      actionType: 'mark_absent',
      lineId: lineId,
      newStatus: 'absent',
      apiCall: () async => _repository?.markPassengerAbsent(lineId),
    );
  }

  /// إعادة حالة راكب - تحديث فوري
  Future<bool> resetPassengerToPlanned(int lineId) async {
    return _executeOptimisticAction(
      actionType: 'reset_to_planned',
      lineId: lineId,
      newStatus: 'not_started',
      apiCall: () async => _repository?.resetPassengerToPlanned(lineId),
    );
  }

  /// تنفيذ عملية متفائلة
  Future<bool> _executeOptimisticAction({
    required String actionType,
    required int lineId,
    required String newStatus,
    required Future<dynamic> Function() apiCall,
  }) async {
    final tripId = _currentTripId;
    if (tripId == null) return false;

    final previousTrip = state.trip;
    if (previousTrip == null) return false;

    // 1. 🎮 تحديث فوري (Optimistic Update)
    final optimisticTrip = await _cache.applyOptimisticLineUpdate(
      tripId: tripId,
      lineId: lineId,
      newStatus: newStatus,
    );

    if (optimisticTrip != null) {
      state = state.copyWith(
        trip: optimisticTrip,
        lastUpdated: DateTime.now(),
      );
      _logger.d('🎮 Applied optimistic update: line $lineId -> $newStatus');
    }

    // 2. إذا لم نكن متصلين، نخزن العملية للمزامنة لاحقاً
    if (!_isOnline) {
      await _cache.addPendingAction(
        actionType: actionType,
        tripId: tripId,
        lineId: lineId,
        data: {'status': newStatus},
      );
      final pendingCount = await _cache.getPendingActionsCount();
      state = state.copyWith(pendingActionsCount: pendingCount);
      _logger.d('📤 Queued action for offline sync: $actionType');
      return true;
    }

    // 3. تنفيذ على الخادم
    try {
      final result = await apiCall();

      if (result == null) {
        // Repository غير متوفر
        await _cache.addPendingAction(
          actionType: actionType,
          tripId: tripId,
          lineId: lineId,
          data: {'status': newStatus},
        );
        return true;
      }

      return result.fold(
        (failure) async {
          // فشل - نتراجع عن التحديث المتفائل
          _logger.w('❌ Action failed, reverting: ${failure.message}');
          // previousTrip is guaranteed non-null here
          if (_shouldCacheTrip(previousTrip)) {
            await _cache.cacheTrip(previousTrip);
          }
          state = state.copyWith(trip: previousTrip);
          return false;
        },
        (line) async {
          // نجح - نحدث من الخادم للتأكد
          _logger.d('✅ Action succeeded on server');
          // Refresh to get latest data
          await _refreshFromServer(tripId);
          // Invalidate driver trips list
          _invalidateDriverTripsList();
          return true;
        },
      );
    } catch (e) {
      _logger.e('Error executing action', error: e);
      // نبقي على التحديث المتفائل ونخزن للمزامنة
      await _cache.addPendingAction(
        actionType: actionType,
        tripId: tripId,
        lineId: lineId,
        data: {'status': newStatus},
      );
      final pendingCount = await _cache.getPendingActionsCount();
      state = state.copyWith(pendingActionsCount: pendingCount);
      return true;
    }
  }

  // ============================================================
  // 🚌 TRIP STATE ACTIONS
  // ============================================================

  /// بدء الرحلة
  Future<bool> startTrip() async {
    final tripId = _currentTripId;
    if (tripId == null) {
      _logger.w('❌ startTrip: _currentTripId is null');
      return false;
    }

    _logger.d('🔄 startTrip: Starting for trip $tripId');

    // تحديث متفائل
    final optimisticTrip = await _cache.applyOptimisticTripStateUpdate(
      tripId: tripId,
      newState: 'ongoing',
    );
    if (optimisticTrip != null) {
      _logger.d(
          '✅ startTrip: Optimistic update applied, new state: ${optimisticTrip.state.value}');
      state = state.copyWith(trip: optimisticTrip);
    } else {
      _logger.w('⚠️ startTrip: Optimistic update returned null');
    }

    if (!_isOnline) {
      await _cache.addPendingAction(
        actionType: 'start_trip',
        tripId: tripId,
      );
      _logger.d('📤 startTrip: Offline - action queued');
      return true;
    }

    try {
      final result = await _repository?.startTrip(tripId);
      if (result == null) {
        _logger.w('❌ startTrip: Repository returned null');
        return false;
      }

      return result.fold(
        (failure) async {
          _logger.w('❌ startTrip: API failed: ${failure.message}');
          await loadTrip(tripId);
          return false;
        },
        (trip) async {
          _logger.d('✅ startTrip: API success! New state: ${trip.state.value}');

          // Merge with cached lines (API returns minimal data to avoid rate limiting)
          final cachedTrip = state.trip;
          final mergedTrip = trip.copyWith(
            lines: cachedTrip?.lines ?? trip.lines,
            companyLatitude:
                trip.companyLatitude ?? cachedTrip?.companyLatitude,
            companyLongitude:
                trip.companyLongitude ?? cachedTrip?.companyLongitude,
          );

          if (_shouldCacheTrip(mergedTrip)) {
            await _cache.cacheTrip(mergedTrip);
          }
          if (!_isMounted) {
            _logger.w('⚠️ startTrip: Provider disposed after API call');
            return true;
          }
          state = state.copyWith(trip: mergedTrip);
          _logger.d('✅ startTrip: State updated');
          _invalidateDriverTripsList();
          return true;
        },
      );
    } catch (e) {
      _logger.e('Error starting trip', error: e);
      return false;
    }
  }

  /// إنهاء الرحلة
  Future<bool> completeTrip() async {
    final tripId = _currentTripId;
    if (tripId == null) {
      _logger.w('❌ completeTrip: _currentTripId is null');
      return false;
    }

    _logger.d('🔄 completeTrip: Starting for trip $tripId');

    // تحديث متفائل
    final optimisticTrip = await _cache.applyOptimisticTripStateUpdate(
      tripId: tripId,
      newState: 'done',
    );
    if (optimisticTrip != null) {
      _logger.d(
          '✅ completeTrip: Optimistic update applied, new state: ${optimisticTrip.state.value}');
      state = state.copyWith(trip: optimisticTrip);
    } else {
      _logger.w('⚠️ completeTrip: Optimistic update returned null');
    }

    if (!_isOnline) {
      await _cache.addPendingAction(
        actionType: 'complete_trip',
        tripId: tripId,
      );
      _logger.d('📤 completeTrip: Offline - action queued');
      return true;
    }

    try {
      final result = await _repository?.completeTrip(tripId);
      if (result == null) {
        _logger.w('❌ completeTrip: Repository returned null');
        return false;
      }

      return result.fold(
        (failure) async {
          _logger.w('❌ completeTrip: API failed: ${failure.message}');
          await loadTrip(tripId);
          return false;
        },
        (trip) async {
          _logger
              .d('✅ completeTrip: API success! New state: ${trip.state.value}');

          // Merge with cached lines (API returns minimal data to avoid rate limiting)
          final cachedTrip = state.trip;
          final mergedTrip = trip.copyWith(
            lines: cachedTrip?.lines ?? trip.lines,
            companyLatitude:
                trip.companyLatitude ?? cachedTrip?.companyLatitude,
            companyLongitude:
                trip.companyLongitude ?? cachedTrip?.companyLongitude,
          );

          if (_shouldCacheTrip(mergedTrip)) {
            await _cache.cacheTrip(mergedTrip);
          }
          if (!_isMounted) {
            _logger.w('⚠️ completeTrip: Provider disposed after API call');
            return true;
          }
          state = state.copyWith(trip: mergedTrip);
          _logger.d('✅ completeTrip: State updated');
          _invalidateDriverTripsList();
          return true;
        },
      );
    } catch (e) {
      _logger.e('Error completing trip', error: e);
      return false;
    }
  }

  /// تأكيد الرحلة
  Future<bool> confirmTrip({
    double? latitude,
    double? longitude,
    int? stopId,
    String? note,
  }) async {
    final tripId = _currentTripId;
    if (tripId == null) {
      _logger.w('❌ confirmTrip: _currentTripId is null');
      return false;
    }

    _logger.d('🔄 confirmTrip: Starting for trip $tripId');

    // تحديث متفائل
    final optimisticTrip = await _cache.applyOptimisticTripStateUpdate(
      tripId: tripId,
      newState: 'planned',
    );
    if (optimisticTrip != null) {
      _logger.d(
          '✅ confirmTrip: Optimistic update applied, new state: ${optimisticTrip.state.value}');
      state = state.copyWith(trip: optimisticTrip);
    } else {
      _logger.w(
          '⚠️ confirmTrip: Optimistic update returned null (trip not in cache?)');
    }

    if (!_isOnline) {
      await _cache.addPendingAction(
        actionType: 'confirm_trip',
        tripId: tripId,
        data: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (stopId != null) 'stopId': stopId,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );
      _logger.d('📤 confirmTrip: Offline - action queued');
      return true;
    }

    try {
      final result = await _repository?.confirmTrip(
        tripId,
        latitude: latitude,
        longitude: longitude,
        stopId: stopId,
        note: note,
      );
      if (result == null) {
        _logger.w('❌ confirmTrip: Repository returned null');
        return false;
      }

      return result.fold(
        (failure) async {
          _logger.w('❌ confirmTrip: API failed: ${failure.message}');
          await loadTrip(tripId);
          return false;
        },
        (trip) async {
          _logger
              .d('✅ confirmTrip: API success! New state: ${trip.state.value}');

          // Merge with cached lines (API returns minimal data to avoid rate limiting)
          final cachedTrip = state.trip;
          final mergedTrip = trip.copyWith(
            lines: cachedTrip?.lines ?? trip.lines,
            companyLatitude:
                trip.companyLatitude ?? cachedTrip?.companyLatitude,
            companyLongitude:
                trip.companyLongitude ?? cachedTrip?.companyLongitude,
          );

          if (_shouldCacheTrip(mergedTrip)) {
            await _cache.cacheTrip(mergedTrip);
          }
          if (!_isMounted) {
            _logger.w('⚠️ confirmTrip: Provider disposed after API call');
            return true;
          }
          state = state.copyWith(trip: mergedTrip);
          _logger.d('✅ confirmTrip: State updated');
          _invalidateDriverTripsList();
          return true;
        },
      );
    } catch (e) {
      _logger.e('Error confirming trip', error: e);
      return false;
    }
  }

  // ============================================================
  // 🔄 SYNC
  // ============================================================

  /// مزامنة العمليات المعلقة
  Future<void> syncPendingActions() async {
    if (!_isOnline) return;

    final pendingActions = await _cache.getPendingActions();
    if (pendingActions.isEmpty) return;

    _logger.d('🔄 Syncing ${pendingActions.length} pending actions...');

    for (final action in pendingActions) {
      final actionId = action['id'] as String;
      final actionType = action['type'] as String;
      final tripId = action['tripId'] as int;
      final lineId = action['lineId'] as int?;

      try {
        bool success = false;

        switch (actionType) {
          case 'mark_boarded':
            if (lineId != null) {
              final result = await _repository?.markPassengerBoarded(lineId);
              success = result?.isRight() ?? false;
            }
            break;
          case 'mark_dropped':
            if (lineId != null) {
              final result = await _repository?.markPassengerDropped(lineId);
              success = result?.isRight() ?? false;
            }
            break;
          case 'mark_absent':
            if (lineId != null) {
              final result = await _repository?.markPassengerAbsent(lineId);
              success = result?.isRight() ?? false;
            }
            break;
          case 'reset_to_planned':
            if (lineId != null) {
              final result = await _repository?.resetPassengerToPlanned(lineId);
              success = result?.isRight() ?? false;
            }
            break;
          case 'start_trip':
            final result = await _repository?.startTrip(tripId);
            success = result?.isRight() ?? false;
            break;
          case 'complete_trip':
            final result = await _repository?.completeTrip(tripId);
            success = result?.isRight() ?? false;
            break;
          case 'confirm_trip':
            final data = action['data'];
            final map = data is Map ? Map<String, dynamic>.from(data) : null;

            final result = await _repository?.confirmTrip(
              tripId,
              latitude: (map?['latitude'] as num?)?.toDouble(),
              longitude: (map?['longitude'] as num?)?.toDouble(),
              stopId: map?['stopId'] as int?,
              note: map?['note'] as String?,
            );
            success = result?.isRight() ?? false;
            break;
        }

        if (success) {
          await _cache.removePendingAction(actionId);
          _logger.d('✅ Synced action: $actionType');
        } else {
          await _cache.incrementRetryCount(actionId);
          _logger.w('❌ Failed to sync action: $actionType');
        }
      } catch (e) {
        _logger.e('Error syncing action: $actionType', error: e);
        await _cache.incrementRetryCount(actionId);
      }
    }

    // تحديث عدد العمليات المعلقة
    final pendingCount = await _cache.getPendingActionsCount();
    state = state.copyWith(pendingActionsCount: pendingCount);

    // تحديث البيانات من الخادم
    if (_currentTripId != null) {
      await _refreshFromServer(_currentTripId!);
    }
  }

  void _invalidateDriverTripsList() {
    try {
      final currentTrip = state.trip;
      if (currentTrip == null) return;

      // تحديث فوري في smartDriverTripsProvider فقط
      // لا نستخدم invalidate لـ driverDailyTripsProvider لتجنب race condition
      // حيث قد يجلب البيانات القديمة من الخادم قبل اكتمال التحديث
      ref.read(smartDriverTripsProvider.notifier).updateTripInList(currentTrip);

      _logger.d(
          '🔄 Updated trip ${currentTrip.id} in driver trips list (state: ${currentTrip.state.value})');
    } catch (e) {
      _logger.w('Failed to update driver trips list: $e');
    }
  }
}

/// Smart Trip Provider - بدون autoDispose للحفاظ على الحالة
final smartTripProvider =
    NotifierProvider<SmartTripNotifier, SmartTripState>(() {
  return SmartTripNotifier();
});

/// Provider for a specific trip with caching
final cachedTripProvider =
    FutureProvider.autoDispose.family<Trip?, int>((ref, tripId) async {
  final cache = ref.watch(tripCacheServiceProvider);
  await cache.init();

  // Try cache first
  final cachedTrip = await cache.getCachedTrip(tripId);

  // If online, fetch from server
  final isOnline = ref.watch(isOnlineProvider);
  if (isOnline) {
    final repository = ref.watch(tripRepositoryProvider);
    if (repository != null) {
      final result = await repository.getTripById(tripId);
      return result.fold(
        (failure) => cachedTrip, // Return cached on failure
        (trip) async {
          // شرط المنتج: حفظ الرحلات والركاب محلياً لليوم فقط
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tripDate =
              DateTime(trip.date.year, trip.date.month, trip.date.day);
          if (tripDate.isAtSameMomentAs(today)) {
            await cache.cacheTrip(trip);
          }
          return trip;
        },
      );
    }
  }

  return cachedTrip;
});

/// Provider for cached driver daily trips
final cachedDriverTripsProvider =
    FutureProvider.autoDispose.family<List<Trip>, DateTime>((ref, date) async {
  final cache = ref.watch(tripCacheServiceProvider);
  await cache.init();

  final driverId = _driverIdFromAuth(ref);
  if (driverId == 0) {
    // Not logged in / user not ready yet
    return [];
  }
  final cacheKey = _driverTripsCacheKey(driverId: driverId, date: date);

  // Check if cache is valid (30 minutes)
  final isCacheValid = await cache.isCacheValid(
    cacheKey,
    maxAge: const Duration(minutes: 30),
  );

  // If cache is valid and offline, return cached
  final isOnline = ref.watch(isOnlineProvider);
  if (isCacheValid && !isOnline) {
    final cachedTrips = await cache.getCachedTrips(cacheKey);
    if (cachedTrips.isNotEmpty) {
      return cachedTrips;
    }
  }

  // Fetch from server
  if (isOnline) {
    try {
      final trips = await ref.watch(
        driverDailyTripsProvider(
          DriverTripsQuery(driverId: driverId, date: date),
        ).future,
      );
      // Cache the trips
      await cache.cacheTrips(trips, cacheKey: cacheKey);
      return trips;
    } catch (e) {
      // On error, return cached if available
      final cachedTrips = await cache.getCachedTrips(cacheKey);
      if (cachedTrips.isNotEmpty) {
        return cachedTrips;
      }
      rethrow;
    }
  }

  // Offline - return cached
  return cache.getCachedTrips(cacheKey);
});

// ============================================================
// 🚌 SMART DRIVER TRIPS - تحديثات فورية لقائمة الرحلات
// ============================================================

/// حالة قائمة رحلات السائق
class SmartDriverTripsState {
  final List<Trip> trips;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final DateTime? selectedDate;
  final DateTime? lastUpdated;
  final bool isFromCache;

  const SmartDriverTripsState({
    this.trips = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.selectedDate,
    this.lastUpdated,
    this.isFromCache = false,
  });

  SmartDriverTripsState copyWith({
    List<Trip>? trips,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    DateTime? selectedDate,
    DateTime? lastUpdated,
    bool? isFromCache,
  }) {
    return SmartDriverTripsState(
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  bool get hasData => trips.isNotEmpty;
  bool get hasError => error != null;
}

/// مدير قائمة رحلات السائق الذكي
class SmartDriverTripsNotifier extends Notifier<SmartDriverTripsState> {
  TripCacheService get _cache => ref.read(tripCacheServiceProvider);
  bool get _isOnline => ref.read(isOnlineProvider);
  final PrefsService _prefs = PrefsService();

  int get _driverId => _driverIdFromAuth(ref);
  TripRepository? get _repository => ref.read(tripRepositoryProvider);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isToday(DateTime date) => date.isAtSameMomentAs(_today);

  @override
  SmartDriverTripsState build() {
    // Reset state on user change to prevent cross-user data bleed on shared devices
    ref.listen<int?>(
      authStateProvider.select((s) => s.asData?.value.user?.id),
      (previous, next) {
        if (previous != next) {
          state = const SmartDriverTripsState();
          _logger.d(
              '🧹 SmartDriverTripsNotifier reset due to user change: $previous -> $next');
        }
      },
    );
    return const SmartDriverTripsState();
  }

  /// تحميل رحلات اليوم
  Future<void> loadTrips(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_driverId == 0) {
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        selectedDate: normalizedDate,
        error: 'يجب تسجيل الدخول أولاً',
        isFromCache: false,
      );
      return;
    }

    // شرط المنتج:
    // - اليوم فقط: يتم الحفظ والقراءة من الكاش (التحميل من السيرفر يكون عند الدخول أو يدوياً فقط).
    // - الأمس/الغد/غيره: يتم الجلب من السيرفر مباشرة (بدون تخزين محلي).
    if (_isToday(normalizedDate)) {
      state = state.copyWith(
        isLoading: state.trips.isEmpty,
        isSyncing: false,
        selectedDate: normalizedDate,
        error: null,
        isFromCache: true,
      );

      // 1) جلب من الكاش أولاً
      final cacheKey =
          _driverTripsCacheKey(driverId: _driverId, date: normalizedDate);
      final cachedTrips = await _cache.getCachedTrips(cacheKey);

      if (cachedTrips.isNotEmpty) {
        state = state.copyWith(
          trips: cachedTrips,
          isLoading: false,
          isSyncing: false,
          lastUpdated: DateTime.now(),
          isFromCache: true,
        );
        _logger.d('📦 Loaded ${cachedTrips.length} trips from cache (today)');
        return;
      }

      // No cached data for today: show error only if offline.
      state =
          state.copyWith(isLoading: false, isSyncing: false, isFromCache: true);
      if (!_isOnline) {
        state = state.copyWith(
          error: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات مخزنة لليوم',
        );
      }
      return;
    }

    // Non-today: fetch from server
    if (!_isOnline) {
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        selectedDate: normalizedDate,
        error: 'لا يوجد اتصال بالإنترنت. لا يمكن تحميل رحلات هذا التاريخ',
        isFromCache: false,
      );
      return;
    }

    final repository = _repository;
    if (repository == null) {
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        selectedDate: normalizedDate,
        error: 'خطأ في الاتصال. يرجى التحقق من الاتصال بالخادم',
        isFromCache: false,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isSyncing: false,
      selectedDate: normalizedDate,
      error: null,
      isFromCache: false,
    );

    try {
      // Prefer REST `/trips/my` then filter by date.
      try {
        final shuttleApi = ref.read(shuttleBeeApiServiceProvider);
        final trips = await shuttleApi.getMyTrips();
        final filtered = trips.where((t) {
          final d = DateTime(t.date.year, t.date.month, t.date.day);
          return d == normalizedDate;
        }).toList();
        state = state.copyWith(
          trips: filtered,
          isLoading: false,
          isSyncing: false,
          lastUpdated: DateTime.now(),
          isFromCache: false,
        );
      } catch (_) {
        // Fallback to RPC repository.
        final tripsResult =
            await repository.getDriverTrips(_driverId, normalizedDate);
        tripsResult.fold(
          (failure) {
            state = state.copyWith(
              isLoading: false,
              isSyncing: false,
              error: failure.message,
              isFromCache: false,
            );
          },
          (trips) {
            state = state.copyWith(
              trips: trips,
              isLoading: false,
              isSyncing: false,
              lastUpdated: DateTime.now(),
              isFromCache: false,
            );
          },
        );
      }
    } catch (e) {
      _logger.e('Failed to fetch non-today trips', error: e);
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        error: e.toString(),
        isFromCache: false,
      );
    }
  }

  /// مزامنة رحلات هذا التاريخ من الخادم وتخزينها (مع الركاب)
  /// تُستخدم عند الدخول إلى صفحة السائق أو عند التحديث اليدوي فقط.
  Future<void> syncTripsWithPassengers(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    try {
      if (_driverId == 0) {
        state = state.copyWith(
          isLoading: false,
          isSyncing: false,
          error: 'يجب تسجيل الدخول أولاً',
          isFromCache: false,
        );
        return;
      }

      // شرط المنتج: الكاش (الرحلات + الركاب) لليوم فقط
      if (!_isToday(normalizedDate)) {
        await loadTrips(normalizedDate);
        return;
      }

      // Offline: rely on cache only
      if (!_isOnline) {
        await loadTrips(normalizedDate);
        return;
      }

      final repository = _repository;
      if (repository == null) {
        state = state.copyWith(
          isLoading: false,
          isSyncing: false,
          error: 'خطأ في الاتصال. يرجى التحقق من الاتصال بالخادم',
        );
        return;
      }

      state = state.copyWith(
        isLoading: state.trips.isEmpty,
        isSyncing: true,
        selectedDate: normalizedDate,
        error: null,
        isFromCache: false,
      );

      // Prefer REST `/trips/my` then filter by date.
      Either<Failure, List<Trip>> tripsResult;
      try {
        final shuttleApi = ref.read(shuttleBeeApiServiceProvider);
        final trips = await shuttleApi.getMyTrips();
        final filtered = trips.where((t) {
          final d = DateTime(t.date.year, t.date.month, t.date.day);
          return d == normalizedDate;
        }).toList();
        tripsResult = Right(filtered);
      } catch (_) {
        tripsResult =
            await repository.getDriverTrips(_driverId, normalizedDate);
      }

      await tripsResult.fold(
        (failure) async {
          state = state.copyWith(
            isLoading: false,
            isSyncing: false,
            error: failure.message,
          );
        },
        (trips) async {
          // Persist last known vehicleId for background heartbeat.
          try {
            final vehicleId =
                trips.firstWhere((t) => t.vehicleId != null).vehicleId;
            if (vehicleId != null) {
              await _prefs.setInt(StorageKeys.lastVehicleId, vehicleId);
            }
          } catch (_) {}

          // تخزين IDs القائمة في الكاش
          final cacheKey =
              _driverTripsCacheKey(driverId: _driverId, date: normalizedDate);
          await _cache.cacheTrips(trips, cacheKey: cacheKey);

          // جلب تفاصيل كل رحلة مع الركاب وتخزينها
          final fullTrips = <Trip>[];
          for (final trip in trips) {
            try {
              final fullTripResult = await repository.getTripById(trip.id);
              await fullTripResult.fold(
                (failure) async {
                  await _cache.cacheTrip(trip);
                  fullTrips.add(trip);
                  _logger.w(
                    '⚠️ Cached trip ${trip.id} without passengers: ${failure.message}',
                  );
                },
                (fullTrip) async {
                  await _cache.cacheTrip(fullTrip);
                  fullTrips.add(fullTrip);
                  _logger.d(
                    '✅ Cached trip ${fullTrip.id} with ${fullTrip.lines.length} passengers',
                  );
                },
              );
            } catch (e) {
              await _cache.cacheTrip(trip);
              fullTrips.add(trip);
              _logger.w('⚠️ Failed to fetch full trip ${trip.id}: $e');
            }
          }

          state = state.copyWith(
            trips: fullTrips,
            isLoading: false,
            isSyncing: false,
            lastUpdated: DateTime.now(),
            isFromCache: false,
          );
          _logger.d(
            '✅ Synced ${fullTrips.length} trips with passengers from server',
          );
        },
      );
    } catch (e) {
      _logger.e('Failed to refresh trips', error: e);
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        error: state.trips.isEmpty ? e.toString() : null,
      );
    }
  }

  /// تحديث رحلة واحدة في القائمة (Optimistic Update)
  void updateTripInList(Trip updatedTrip) {
    final currentTrips = List<Trip>.from(state.trips);
    final index = currentTrips.indexWhere((t) => t.id == updatedTrip.id);

    if (index != -1) {
      currentTrips[index] = updatedTrip;
      state = state.copyWith(
        trips: currentTrips,
        lastUpdated: DateTime.now(),
      );
      _logger.d(
          '🔄 Updated trip ${updatedTrip.id} in list: ${updatedTrip.state.value}');

      // تحديث الكاش أيضاً
      if (state.selectedDate != null && _isToday(state.selectedDate!)) {
        final cacheKey = _driverTripsCacheKey(
            driverId: _driverId, date: state.selectedDate!);
        _cache.cacheTrips(currentTrips, cacheKey: cacheKey);
      }
    }
  }

  /// تحديث يدوي
  Future<void> refresh() async {
    final selected = state.selectedDate;
    if (selected == null) return;
    if (_isToday(selected)) {
      await syncTripsWithPassengers(selected);
    } else {
      await loadTrips(selected);
    }
  }
}

/// Smart Driver Trips Provider
final smartDriverTripsProvider =
    NotifierProvider<SmartDriverTripsNotifier, SmartDriverTripsState>(() {
  return SmartDriverTripsNotifier();
});
