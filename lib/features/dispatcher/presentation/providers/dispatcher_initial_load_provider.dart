import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/local_storage/providers/local_storage_providers.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../data/services/dispatcher_initial_data_service.dart';

// ════════════════════════════════════════════════════════════
// Service Provider
// ════════════════════════════════════════════════════════════

/// Provider للخدمة الأساسية
final dispatcherInitialDataServiceProvider =
    Provider<DispatcherInitialDataService>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  return DispatcherInitialDataService(storage, ref);
});

// ════════════════════════════════════════════════════════════
// Initial Load State
// ════════════════════════════════════════════════════════════

/// حالة التحميل الأولي
class DispatcherInitialLoadState {
  final bool isLoading;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;
  final String currentTask;
  final double progress;
  final InitialLoadResult? result;
  final bool isWindowsPlatform;

  const DispatcherInitialLoadState({
    this.isLoading = false,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
    this.currentTask = '',
    this.progress = 0.0,
    this.result,
    this.isWindowsPlatform = false,
  });

  DispatcherInitialLoadState copyWith({
    bool? isLoading,
    bool? isComplete,
    bool? hasError,
    String? errorMessage,
    String? currentTask,
    double? progress,
    InitialLoadResult? result,
    bool? isWindowsPlatform,
  }) {
    return DispatcherInitialLoadState(
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      currentTask: currentTask ?? this.currentTask,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      isWindowsPlatform: isWindowsPlatform ?? this.isWindowsPlatform,
    );
  }
}

// ════════════════════════════════════════════════════════════
// Initial Load Notifier
// ════════════════════════════════════════════════════════════

/// Notifier لإدارة حالة التحميل الأولي
class DispatcherInitialLoadNotifier
    extends Notifier<DispatcherInitialLoadState> {
  @override
  DispatcherInitialLoadState build() {
    return DispatcherInitialLoadState(
      isWindowsPlatform: Platform.isWindows,
    );
  }

  DispatcherInitialDataService get _service =>
      ref.read(dispatcherInitialDataServiceProvider);

  /// بدء التحميل الأولي
  Future<void> startInitialLoad({bool forceRefresh = false}) async {
    // التحقق من حالة الاتصال
    final isOnline = ref.read(isOnlineStateProvider);
    final isAuthenticated =
        ref.read(authStateProvider).asData?.value.isAuthenticated ?? false;

    if (!isAuthenticated) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'يرجى تسجيل الدخول أولاً',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isComplete: false,
      hasError: false,
      errorMessage: null,
      currentTask: 'جاري التحضير...',
      progress: 0.0,
    );

    try {
      final result = await _service.loadAllInitialData(
        forceRefresh: forceRefresh,
        onProgress: (task, progress) {
          state = state.copyWith(
            currentTask: task,
            progress: progress,
          );
        },
      );

      if (result.isComplete) {
        state = state.copyWith(
          isLoading: false,
          isComplete: true,
          hasError: false,
          result: result,
          currentTask: result.fromCache ? 'تم التحميل من الذاكرة' : 'اكتمل التحميل',
          progress: 1.0,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: result.error ?? 'فشل التحميل',
          result: result,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// تحديث البيانات
  Future<void> refresh() async {
    await startInitialLoad(forceRefresh: true);
  }

  /// مسح البيانات المحفوظة
  Future<void> clearCache() async {
    state = state.copyWith(
      isLoading: true,
      currentTask: 'جاري مسح البيانات...',
    );

    final result = await _service.clearAllCache();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = const DispatcherInitialLoadState(
          isComplete: false,
          currentTask: 'تم مسح البيانات',
        );
      },
    );
  }
}

/// Provider للتحميل الأولي
final dispatcherInitialLoadProvider =
    NotifierProvider<DispatcherInitialLoadNotifier, DispatcherInitialLoadState>(
  () => DispatcherInitialLoadNotifier(),
);

// ════════════════════════════════════════════════════════════
// Cached Data Providers (for use throughout the app)
// ════════════════════════════════════════════════════════════

/// Provider للرحلات المحملة مسبقاً
final dispatcherPreloadedTripsProvider =
    FutureProvider<List<Trip>>((ref) async {
  final service = ref.watch(dispatcherInitialDataServiceProvider);
  return service.getCachedTrips();
});

/// Provider للركاب المحملين مسبقاً
final dispatcherPreloadedPassengersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(dispatcherInitialDataServiceProvider);
  return service.getCachedPassengers();
});

/// 🆕 Provider لملفات تعريف الركاب (الإحداثيات والمحطات الافتراضية)
final dispatcherPreloadedPassengerProfilesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(dispatcherInitialDataServiceProvider);
  return service.getCachedPassengerProfiles();
});

/// Provider للمركبات المحملة مسبقاً
final dispatcherPreloadedVehiclesProvider =
    FutureProvider<List<ShuttleVehicle>>((ref) async {
  final service = ref.watch(dispatcherInitialDataServiceProvider);
  return service.getCachedVehicles();
});

/// Provider للسائقين المحملين مسبقاً
final dispatcherPreloadedDriversProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(dispatcherInitialDataServiceProvider);
  return service.getCachedDrivers();
});

/// Provider للمرافقين المحملين مسبقاً
final dispatcherPreloadedCompanionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(dispatcherInitialDataServiceProvider);
  return service.getCachedCompanions();
});

/// Provider للمجموعات المحملة مسبقاً
final dispatcherPreloadedGroupsProvider =
    FutureProvider<List<PassengerGroup>>((ref) async {
  final service = ref.watch(dispatcherInitialDataServiceProvider);
  return service.getCachedGroups();
});

// ════════════════════════════════════════════════════════════
// Combined Data State Provider
// ════════════════════════════════════════════════════════════

/// حالة البيانات المدمجة
class DispatcherDataState {
  final List<Trip> trips;
  final List<Map<String, dynamic>> passengers;
  /// 🆕 ملفات تعريف الركاب (الإحداثيات والمحطات الافتراضية)
  final List<Map<String, dynamic>> passengerProfiles;
  final List<ShuttleVehicle> vehicles;
  final List<Map<String, dynamic>> drivers;
  final List<Map<String, dynamic>> companions;
  final List<PassengerGroup> groups;
  final bool isLoaded;

  const DispatcherDataState({
    this.trips = const [],
    this.passengers = const [],
    this.passengerProfiles = const [],
    this.vehicles = const [],
    this.drivers = const [],
    this.companions = const [],
    this.groups = const [],
    this.isLoaded = false,
  });

  /// عدد الرحلات
  int get tripsCount => trips.length;

  /// عدد الركاب
  int get passengersCount => passengers.length;

  /// عدد ملفات تعريف الركاب
  int get passengerProfilesCount => passengerProfiles.length;

  /// عدد المركبات
  int get vehiclesCount => vehicles.length;

  /// عدد السائقين
  int get driversCount => drivers.length;

  /// عدد المرافقين
  int get companionsCount => companions.length;

  /// عدد المجموعات
  int get groupsCount => groups.length;

  /// هل توجد بيانات
  bool get hasData =>
      trips.isNotEmpty ||
      passengers.isNotEmpty ||
      passengerProfiles.isNotEmpty ||
      vehicles.isNotEmpty ||
      drivers.isNotEmpty ||
      companions.isNotEmpty ||
      groups.isNotEmpty;

  /// إحصائيات البيانات
  Map<String, int> get stats => {
        'trips': tripsCount,
        'passengers': passengersCount,
        'passengerProfiles': passengerProfilesCount,
        'vehicles': vehiclesCount,
        'drivers': driversCount,
        'companions': companionsCount,
        'groups': groupsCount,
      };

  DispatcherDataState copyWith({
    List<Trip>? trips,
    List<Map<String, dynamic>>? passengers,
    List<Map<String, dynamic>>? passengerProfiles,
    List<ShuttleVehicle>? vehicles,
    List<Map<String, dynamic>>? drivers,
    List<Map<String, dynamic>>? companions,
    List<PassengerGroup>? groups,
    bool? isLoaded,
  }) {
    return DispatcherDataState(
      trips: trips ?? this.trips,
      passengers: passengers ?? this.passengers,
      passengerProfiles: passengerProfiles ?? this.passengerProfiles,
      vehicles: vehicles ?? this.vehicles,
      drivers: drivers ?? this.drivers,
      companions: companions ?? this.companions,
      groups: groups ?? this.groups,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Provider للبيانات المدمجة
final dispatcherCombinedDataProvider =
    FutureProvider<DispatcherDataState>((ref) async {
  final loadState = ref.watch(dispatcherInitialLoadProvider);

  if (!loadState.isComplete) {
    return const DispatcherDataState();
  }

  final service = ref.watch(dispatcherInitialDataServiceProvider);

  final trips = await service.getCachedTrips();
  final passengers = await service.getCachedPassengers();
  final passengerProfiles = await service.getCachedPassengerProfiles();
  final vehicles = await service.getCachedVehicles();
  final drivers = await service.getCachedDrivers();
  final companions = await service.getCachedCompanions();
  final groups = await service.getCachedGroups();

  return DispatcherDataState(
    trips: trips,
    passengers: passengers,
    passengerProfiles: passengerProfiles,
    vehicles: vehicles,
    drivers: drivers,
    companions: companions,
    groups: groups,
    isLoaded: true,
  );
});

// ════════════════════════════════════════════════════════════
// Auto-Load on Auth Change
// ════════════════════════════════════════════════════════════

/// Provider لبدء التحميل التلقائي عند تسجيل الدخول
/// 
/// استخدم هذا في main.dart أو App widget:
/// ```dart
/// ref.listen(dispatcherAutoLoadProvider, (_, __) {});
/// ```
final dispatcherAutoLoadProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final isDispatcher = authState.asData?.value.user?.role == 'dispatcher';
  final isAuthenticated = authState.asData?.value.isAuthenticated ?? false;

  if (isAuthenticated && isDispatcher && Platform.isWindows) {
    // بدء التحميل الأولي للـ dispatcher على Windows
    Future.microtask(() {
      final loadState = ref.read(dispatcherInitialLoadProvider);
      if (!loadState.isLoading && !loadState.isComplete) {
        ref.read(dispatcherInitialLoadProvider.notifier).startInitialLoad();
      }
    });
  }
});

