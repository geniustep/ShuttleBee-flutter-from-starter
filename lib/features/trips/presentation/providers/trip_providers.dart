import 'dart:async';
import 'dart:io';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dispatcher/presentation/providers/dispatcher_initial_load_provider.dart';
import '../../../shuttlebee/presentation/providers/shuttlebee_api_providers.dart';
import '../../data/cache/trip_cache_service.dart';
import '../../data/datasources/trip_remote_data_source.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

export '../../domain/repositories/trip_repository.dart'
    show TripDashboardStats, ManagerAnalytics;

/// Key for fetching driver trips (prevents cross-driver cache/state bleed)
class DriverTripsQuery {
  final int driverId;
  final DateTime date; // normalized to yyyy-mm-dd

  DriverTripsQuery({required this.driverId, required DateTime date})
    : date = DateTime(date.year, date.month, date.day);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverTripsQuery &&
          runtimeType == other.runtimeType &&
          driverId == other.driverId &&
          date == other.date;

  @override
  int get hashCode => Object.hash(driverId, date);
}

/// Trip Remote Data Source Provider
final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  final shuttleApi = ref.watch(shuttleBeeApiServiceProvider);
  return TripRemoteDataSource(client, shuttleBeeApi: shuttleApi);
});

/// Trip Repository Provider
final tripRepositoryProvider = Provider<TripRepository?>((ref) {
  final dataSource = ref.watch(tripRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return TripRepositoryImpl(dataSource);
});

/// Driver Daily Trips Provider
final driverDailyTripsProvider = FutureProvider.autoDispose.family<List<Trip>, DriverTripsQuery>((
  ref,
  query,
) async {
  try {
    final date = query.date;
    final driverId = query.driverId;
    print(
      '🚗 [driverDailyTripsProvider] Fetching trips for driverId: $driverId, date: $date',
    );

    final client = ref.watch(bridgecoreClientProvider);
    print(
      '🚗 [driverDailyTripsProvider] BridgecoreClient: ${client != null ? "exists" : "NULL"}',
    );

    // Prefer the new "My Trips" REST endpoint (server computes current driver).
    final shuttleApi = ref.watch(shuttleBeeApiServiceProvider);
    final authUserId = ref.watch(authStateProvider).asData?.value.user?.id;

    if (driverId == 0) {
      print('❌ [driverDailyTripsProvider] userId is 0');
      throw Exception('معلومات السائق غير مكتملة. يرجى التواصل مع الإدارة');
    }

    // Safety: prevent cross-driver bleed.
    if (authUserId != null && authUserId != driverId) {
      print(
        '⚠️ [driverDailyTripsProvider] driverId mismatch (query=$driverId, auth=$authUserId) - returning empty',
      );
      return [];
    }

    try {
      final trips = await shuttleApi.getMyTrips(driverId: driverId);
      final filtered = trips.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return d == date;
      }).toList();
      print(
        '✅ [driverDailyTripsProvider] Got ${filtered.length} trips from search_read',
      );
      return filtered;
    } catch (e) {
      // Fallback to RPC repository for older servers or temporary failures.
      final repository = ref.watch(tripRepositoryProvider);
      print(
        '🚗 [driverDailyTripsProvider] Repository: ${repository != null ? "exists" : "NULL"}',
      );
      if (repository == null) {
        throw Exception('خطأ في الاتصال. يرجى التحقق من الاتصال بالخادم');
      }

      print(
        '🚗 [driverDailyTripsProvider] Fallback to getDriverTrips with driverId (user.id): $driverId',
      );
      final result = await repository.getDriverTrips(driverId, date);
      return result.fold(
        (failure) {
          print('❌ [driverDailyTripsProvider] API Error: ${failure.message}');
          final errorMessage = ErrorTranslator.translateFailure(
            failure.message,
          );
          throw Exception(errorMessage);
        },
        (trips) {
          print(
            '✅ [driverDailyTripsProvider] Got ${trips.length} trips (fallback)',
          );
          return trips;
        },
      );
    }
  } on MissingOdooCredentialsException catch (e) {
    // Token doesn't have tenant info - user needs to re-login
    print('❌ [driverDailyTripsProvider] MissingOdooCredentialsException: $e');
    throw Exception(
      'انتهت صلاحية الجلسة. يرجى تسجيل الخروج وإعادة تسجيل الدخول',
    );
  } catch (e) {
    print('❌ [driverDailyTripsProvider] Exception: $e');
    // Re-throw with better error message
    if (e is Exception) {
      final message = e.toString();
      if (message.startsWith('Exception: ')) {
        throw Exception(message.substring(11));
      }
      if (message == 'Exception') {
        throw Exception('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى');
      }
    }
    rethrow;
  }
});

/// Passenger Trips Provider
final passengerTripsProvider = FutureProvider.autoDispose<List<Trip>>((
  ref,
) async {
  final repository = ref.watch(tripRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (repository == null) return [];

  final user = authState.asData?.value.user;
  if (user == null || user.partnerId == null) return [];

  final result = await repository.getPassengerTrips(user.partnerId!);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (trips) => trips,
  );
});

/// Trip Detail Provider
/// محسّن: يستخدم cache محلي أولاً ثم يحدث من السيرفر
/// Note: Removed autoDispose to prevent excessive requests
/// The provider will cache results and only refresh when explicitly invalidated
final tripDetailProvider = FutureProvider.family<Trip?, int>((
  ref,
  tripId,
) async {
  final repository = ref.watch(tripRepositoryProvider);
  if (repository == null) return null;

  // 1. محاولة جلب من cache محلي أولاً (Hive)
  try {
    final cacheService = TripCacheService.instance;
    await cacheService.init();
    final cachedTrip = await cacheService.getCachedTrip(tripId);

    if (cachedTrip != null) {
      // البيانات موجودة في cache - نتحقق من حداثتها
      print(
        '📦 [tripDetailProvider] Found cached trip $tripId: ${cachedTrip.name}',
      );
      print('   └─ Source: Local Cache (Hive)');
      print(
        '   └─ State: ${cachedTrip.state.value} (${cachedTrip.state.arabicLabel})',
      );
      print('   └─ Lines Count: ${cachedTrip.lines.length}');

      // التحقق من وجود الـ lines في الـ cache
      if (cachedTrip.lines.isEmpty) {
        print(
          '⚠️ [tripDetailProvider] Cached trip has no lines, fetching full trip from server...',
        );
        // إذا لم تكن الـ lines موجودة، نجلب الرحلة كاملة من السيرفر
        // نتابع للجلب الكامل من السيرفر
      } else {
        // التحقق من عمر البيانات - إذا كانت قديمة جداً، نجلب من السيرفر
        try {
          final cacheService = TripCacheService.instance;
          await cacheService.init();
          final cacheAge = await cacheService.getTripCacheAge(tripId);
          if (cacheAge != null && cacheAge.inMinutes > 30) {
            print(
              '⚠️ [tripDetailProvider] Cached trip is old (${cacheAge.inMinutes}m), fetching fresh data...',
            );
            // البيانات قديمة جداً، نتابع للجلب من السيرفر
          } else {
            print('   └─ Cache Age: ${cacheAge?.inMinutes ?? 0}m');
            print('   └─ Status: Using cached data (fresh)');
            // البيانات حديثة - نعيدها من الـ cache
            return cachedTrip;
          }
        } catch (_) {
          // في حالة فشل التحقق من العمر، نستخدم البيانات من الـ cache
          print('   └─ Status: Using cached data (age check failed)');
          return cachedTrip;
        }
      }
    } else {
      print('⚠️ [tripDetailProvider] No cached trip found for $tripId');
    }
  } catch (e) {
    // في حالة فشل cache، نتابع للجلب من السيرفر
    print('⚠️ [tripDetailProvider] Cache error: $e');
  }

  // 2. محاولة جلب من dispatcher_initial_trips (إذا كان متوفراً)
  // فقط إذا لم نجد في الـ cache أو كانت الـ cache بدون lines
  if (Platform.isWindows) {
    try {
      final initialLoadState = ref.read(dispatcherInitialLoadProvider);
      if (initialLoadState.isComplete && !initialLoadState.hasError) {
        final preloadedTrips = await ref.read(
          dispatcherPreloadedTripsProvider.future,
        );
        try {
          final trip = preloadedTrips.firstWhere((t) => t.id == tripId);

          print('📦 [tripDetailProvider] ✅ USING PRELOADED DATA');
          print('   └─ Source: Initial Load (Preloaded)');
          print('   └─ Trip ID: $tripId');
          print('   └─ Trip Name: ${trip.name}');
          print(
            '   └─ Trip State: ${trip.state.value} (${trip.state.arabicLabel})',
          );
          print('   └─ Lines Count: ${trip.lines.length}');

          // إذا كانت الرحلة المحملة مسبقاً تحتوي على lines، نستخدمها
          if (trip.lines.isNotEmpty) {
            print('   └─ Status: Using preloaded data (has lines)');
            // حفظ في cache
            try {
              final cacheService = TripCacheService.instance;
              await cacheService.init();
              await cacheService.cacheTrip(trip);
              print('   └─ Saved to Cache: Yes');
            } catch (_) {
              print('   └─ Saved to Cache: Failed');
            }

            return trip;
          } else {
            print(
              '⚠️ [tripDetailProvider] Preloaded trip has no lines, fetching from server...',
            );
            // إذا لم تكن تحتوي على lines، نتابع للجلب من السيرفر
          }
        } catch (_) {
          print(
            '⚠️ [tripDetailProvider] Trip $tripId not found in preloaded trips',
          );
        }
      }
    } catch (e) {
      // لا توجد بيانات محملة مسبقاً، نتابع للجلب من السيرفر
      print('⚠️ [tripDetailProvider] Preloaded trips not available: $e');
    }
  }

  // 3. جلب من السيرفر (آخر خيار)
  print('🌐 [tripDetailProvider] 🔄 FETCHING FROM SERVER');
  print('   └─ Source: Remote API');
  print('   └─ Trip ID: $tripId');
  final result = await repository.getTripById(tripId);
  return result.fold(
    (failure) async {
      print('   └─ Status: ❌ API Error');
      print('   └─ Error: ${failure.message}');
      // في حالة الفشل، نحاول مرة أخرى من cache
      try {
        final cacheService = TripCacheService.instance;
        await cacheService.init();
        final cachedTrip = await cacheService.getCachedTrip(tripId);
        if (cachedTrip != null) {
          print('   └─ Fallback: Using cached trip');
          return cachedTrip;
        }
      } catch (_) {}
      throw Exception(failure.message);
    },
    (trip) async {
      print('   └─ Status: ✅ Success');
      print(
        '   └─ Trip State: ${trip.state.value} (${trip.state.arabicLabel})',
      );
      print('   └─ Trip Name: ${trip.name}');
      // حفظ في cache بعد الجلب الناجح
      print('   └─ Saving to Cache: Yes');
      try {
        final cacheService = TripCacheService.instance;
        await cacheService.init();
        await cacheService.cacheTrip(trip);
        print('   └─ Cache Saved: ✅ Success');
      } catch (e) {
        print('   └─ Cache Saved: ❌ Failed ($e)');
      }

      return trip;
    },
  );
});

/// Prefetch trip data before navigation
/// تحميل بيانات الرحلة مسبقاً قبل التنقل للصفحة
Future<void> prefetchTripDetail(WidgetRef ref, int tripId) async {
  try {
    print('🚀 [prefetchTripDetail] Starting prefetch for trip $tripId');

    // محاولة جلب من cache أولاً
    final cacheService = TripCacheService.instance;
    await cacheService.init();
    final cachedTrip = await cacheService.getCachedTrip(tripId);

    if (cachedTrip != null) {
      print(
        '✅ [prefetchTripDetail] Found cached trip $tripId: ${cachedTrip.name}',
      );
      // البيانات موجودة في cache - لا حاجة لاستدعاء provider
      // سيتم تحميلها تلقائياً عند الوصول للصفحة
      return;
    }

    print('⚠️ [prefetchTripDetail] No cached trip found for $tripId');

    // محاولة جلب من dispatcher_initial_trips على Windows
    if (Platform.isWindows) {
      try {
        final initialLoadState = ref.read(dispatcherInitialLoadProvider);
        if (initialLoadState.isComplete && !initialLoadState.hasError) {
          final preloadedTrips = await ref.read(
            dispatcherPreloadedTripsProvider.future,
          );
          try {
            final trip = preloadedTrips.firstWhere((t) => t.id == tripId);

            print(
              '✅ [prefetchTripDetail] Found preloaded trip $tripId: ${trip.name}',
            );

            // حفظ في cache
            await cacheService.cacheTrip(trip);
            print('💾 [prefetchTripDetail] Cached preloaded trip $tripId');
            // لا حاجة لاستدعاء provider - سيتم تحميلها تلقائياً عند الوصول للصفحة
            return;
          } catch (_) {
            print(
              '⚠️ [prefetchTripDetail] Trip $tripId not found in preloaded trips',
            );
          }
        }
      } catch (e) {
        print('⚠️ [prefetchTripDetail] Preloaded trips error: $e');
      }
    }

    // بدء تحميل من السيرفر في الخلفية (لا ننتظر)
    print('🌐 [prefetchTripDetail] Starting background fetch for trip $tripId');
    final repository = ref.read(tripRepositoryProvider);
    if (repository != null) {
      repository.getTripById(tripId).then((result) {
        result.fold(
          (_) {
            print('❌ [prefetchTripDetail] Failed to fetch trip $tripId');
          },
          (trip) async {
            print('✅ [prefetchTripDetail] Fetched trip $tripId: ${trip.name}');
            await cacheService.cacheTrip(trip);
            print('💾 [prefetchTripDetail] Cached fetched trip $tripId');
            // تحديث الـ provider باستخدام Future.microtask لتجنب dependency cycle
            Future.microtask(() {
              try {
                ref.invalidate(tripDetailProvider(tripId));
              } catch (_) {
                // Provider may be disposed, ignore
              }
            });
          },
        );
      });
    } else {
      print('❌ [prefetchTripDetail] Repository is null');
    }
  } catch (e) {
    print('❌ [prefetchTripDetail] Error: $e');
  }
}

/// Dashboard Stats Provider
final dashboardStatsProvider = FutureProvider.autoDispose
    .family<TripDashboardStats, DateTime>((ref, date) async {
      final repository = ref.watch(tripRepositoryProvider);
      if (repository == null) {
        return const TripDashboardStats();
      }

      final result = await repository.getDashboardStats(date);
      return result.fold(
        (failure) => const TripDashboardStats(),
        (stats) => stats,
      );
    });

/// All Trips Provider (with filters)
/// على Windows: يستخدم البيانات المحفوظة من التحميل الأولي
final allTripsProvider = FutureProvider.autoDispose
    .family<List<Trip>, TripFilters>((ref, filters) async {
      // على Windows: استخدم البيانات المحفوظة للرحلات العامة
      if (Platform.isWindows && filters.isDefault) {
        final loadState = ref.watch(dispatcherInitialLoadProvider);
        if (loadState.isComplete && !loadState.hasError) {
          final preloadedTrips = await ref.watch(
            dispatcherPreloadedTripsProvider.future,
          );
          if (preloadedTrips.isNotEmpty) {
            // تطبيق الفلاتر على البيانات المحفوظة
            var result = preloadedTrips.toList();
            if (filters.state != null) {
              result = result.where((t) => t.state == filters.state).toList();
            }
            if (filters.tripType != null) {
              result = result
                  .where((t) => t.tripType == filters.tripType)
                  .toList();
            }
            if (filters.fromDate != null) {
              result = result
                  .where(
                    (t) =>
                        t.date.isAfter(filters.fromDate!) ||
                        t.date.isAtSameMomentAs(filters.fromDate!),
                  )
                  .toList();
            }
            if (filters.toDate != null) {
              result = result
                  .where(
                    (t) =>
                        t.date.isBefore(filters.toDate!) ||
                        t.date.isAtSameMomentAs(filters.toDate!),
                  )
                  .toList();
            }
            if (filters.driverId != null) {
              result = result
                  .where((t) => t.driverId == filters.driverId)
                  .toList();
            }
            if (filters.vehicleId != null) {
              result = result
                  .where((t) => t.vehicleId == filters.vehicleId)
                  .toList();
            }
            // تطبيق الـ limit و offset
            if (filters.offset > 0 && filters.offset < result.length) {
              result = result.sublist(filters.offset);
            }
            if (filters.limit > 0 && result.length > filters.limit) {
              result = result.sublist(0, filters.limit);
            }
            return result;
          }
        }
      }

      final repository = ref.watch(tripRepositoryProvider);
      if (repository == null) return [];

      final result = await repository.getTrips(
        state: filters.state,
        tripType: filters.tripType,
        fromDate: filters.fromDate,
        toDate: filters.toDate,
        driverId: filters.driverId,
        vehicleId: filters.vehicleId,
        limit: filters.limit,
        offset: filters.offset,
      );

      return result.fold(
        (failure) => throw Exception(failure.message),
        (trips) => trips,
      );
    });

/// Ongoing Trips Provider (for live monitoring screens)
///
/// Uses the generic [allTripsProvider] with a fixed filter (ongoing only).
final ongoingTripsProvider = allTripsProvider(
  const TripFilters(state: TripState.ongoing, limit: 200),
);

/// Trip GPS path points provider (REST `/api/v1/shuttle/trips/<id>/gps`).
// Note: incremental GPS path polling is implemented in
// `trip_gps_path_provider.dart` (autoDispose notifier with `since`).

/// Trip Filters
class TripFilters {
  final TripState? state;
  final TripType? tripType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? driverId;
  final int? vehicleId;
  final int limit;
  final int offset;

  const TripFilters({
    this.state,
    this.tripType,
    this.fromDate,
    this.toDate,
    this.driverId,
    this.vehicleId,
    this.limit = 50,
    this.offset = 0,
  });

  TripFilters copyWith({
    TripState? state,
    TripType? tripType,
    DateTime? fromDate,
    DateTime? toDate,
    int? driverId,
    int? vehicleId,
    int? limit,
    int? offset,
  }) {
    return TripFilters(
      state: state ?? this.state,
      tripType: tripType ?? this.tripType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripFilters &&
          state == other.state &&
          tripType == other.tripType &&
          fromDate == other.fromDate &&
          toDate == other.toDate &&
          driverId == other.driverId &&
          vehicleId == other.vehicleId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(
    state,
    tripType,
    fromDate,
    toDate,
    driverId,
    vehicleId,
    limit,
    offset,
  );

  /// هل الفلاتر افتراضية (بدون تحديد فلاتر خاصة)
  bool get isDefault =>
      state == null &&
      tripType == null &&
      driverId == null &&
      vehicleId == null;
}

/// Available passengers for a trip (from the trip's group, not already in trip)
final availablePassengersForTripProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, tripId) async {
      final repository = ref.watch(tripRepositoryProvider);
      if (repository == null) return [];

      final result = await repository.getAvailablePassengersForTrip(tripId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (passengers) => passengers,
      );
    });

/// Active Trip Notifier for managing trip actions
class ActiveTripNotifier extends Notifier<AsyncValue<Trip?>> {
  @override
  AsyncValue<Trip?> build() => const AsyncValue.data(null);

  TripRepository? get _repository => ref.read(tripRepositoryProvider);

  /// Check if provider is still mounted (safe to update state)
  /// Note: For autoDispose providers, this check might fail after async operations
  bool get _isMounted {
    try {
      // Accessing ref will throw if disposed
      ref.read(tripRepositoryProvider);
      return true;
    } catch (e) {
      print('⚠️ [_isMounted] Provider check failed: $e');
      return false;
    }
  }

  /// Invalidate driver daily trips provider to refresh the list
  /// This ensures state synchronization across all screens
  void _invalidateDriverTripsList() {
    if (!_isMounted) return;

    try {
      // Get the current trip to find its date
      final currentTrip = state.asData?.value;
      if (currentTrip?.plannedStartTime != null) {
        final tripDate = DateTime(
          currentTrip!.plannedStartTime!.year,
          currentTrip.plannedStartTime!.month,
          currentTrip.plannedStartTime!.day,
        );
        // Invalidate the provider for that specific (driverId + date)
        final authUserId = ref.read(authStateProvider).asData?.value.user?.id;
        final driverId = currentTrip.driverId ?? authUserId ?? 0;
        if (driverId != 0) {
          ref.invalidate(
            driverDailyTripsProvider(
              DriverTripsQuery(driverId: driverId, date: tripDate),
            ),
          );
        }
        print(
          '🔄 [State Sync] Invalidated driverDailyTripsProvider for date: $tripDate',
        );
      } else {
        // If we don't have the trip date, try to invalidate today's date as fallback
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final authUserId = ref.read(authStateProvider).asData?.value.user?.id;
        final driverId = authUserId ?? 0;
        if (driverId != 0) {
          ref.invalidate(
            driverDailyTripsProvider(
              DriverTripsQuery(driverId: driverId, date: todayDate),
            ),
          );
        }
        print(
          '🔄 [State Sync] Invalidated driverDailyTripsProvider for today: $todayDate',
        );
      }
    } catch (e) {
      print(
        '⚠️ [State Sync] Failed to invalidate driverDailyTripsProvider: $e',
      );
    }
  }

  Future<void> loadTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return;

    state = const AsyncValue.loading();

    final result = await repository.getTripById(tripId);

    // Check if still mounted after async operation
    if (!_isMounted) return;

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (trip) => AsyncValue.data(trip),
    );
  }

  Future<bool> confirmTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) {
      print('❌ [confirmTrip] Repository is null');
      return false;
    }

    print('🔄 [confirmTrip] Calling repository.confirmTrip($tripId)');
    final result = await repository.confirmTrip(tripId);

    // Check if still mounted after async operation
    if (!_isMounted) {
      print('⚠️ [confirmTrip] Provider disposed after async operation');
      // Still return true if the operation succeeded on the server
      return result.isRight();
    }

    return result.fold(
      (failure) {
        print('❌ [confirmTrip] Failed: ${failure.message}');
        return false;
      },
      (trip) {
        print('✅ [confirmTrip] Success! Trip state: ${trip.state.value}');
        state = AsyncValue.data(trip);
        _invalidateDriverTripsList();
        return true;
      },
    );
  }

  Future<bool> startTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return false;

    final result = await repository.startTrip(tripId);

    // Check if still mounted after async operation
    if (!_isMounted) return false;

    return result.fold((failure) => false, (trip) {
      state = AsyncValue.data(trip);
      _invalidateDriverTripsList();
      return true;
    });
  }

  Future<bool> completeTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return false;

    final result = await repository.completeTrip(tripId);

    // Check if still mounted after async operation
    if (!_isMounted) return false;

    return result.fold((failure) => false, (trip) {
      state = AsyncValue.data(trip);
      _invalidateDriverTripsList();
      return true;
    });
  }

  Future<bool> cancelTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return false;

    final result = await repository.cancelTrip(tripId);

    // Check if still mounted after async operation
    if (!_isMounted) return false;

    return result.fold((failure) => false, (_) {
      state = const AsyncValue.data(null);
      return true;
    });
  }

  Future<bool> markPassengerBoarded(int tripLineId) async {
    final repository = _repository;
    if (repository == null) return false;

    // Optimistic update
    final currentTrip = state.asData?.value;
    if (currentTrip != null) {
      final updatedLines = currentTrip.lines.map((line) {
        if (line.id == tripLineId) {
          return line.copyWith(status: TripLineStatus.boarded);
        }
        return line;
      }).toList();

      // Update counts optimistically
      final updatedTrip = currentTrip.copyWith(
        lines: updatedLines,
        boardedCount: currentTrip.boardedCount + 1,
      );

      state = AsyncValue.data(updatedTrip);
    }

    // Make API call
    final result = await repository.markPassengerBoarded(tripLineId);

    // Check if still mounted after async operation
    if (!_isMounted) {
      // Still return true if the operation succeeded on the server
      return result.isRight();
    }

    return result.fold(
      (failure) {
        // Revert on failure
        if (currentTrip != null && _isMounted) {
          state = AsyncValue.data(currentTrip);
        }
        return false;
      },
      (line) {
        // Confirm with server data
        if (currentTrip != null && _isMounted) {
          loadTrip(currentTrip.id);
          _invalidateDriverTripsList();
        }
        return true;
      },
    );
  }

  Future<bool> markPassengerAbsent(int tripLineId) async {
    final repository = _repository;
    if (repository == null) return false;

    // Optimistic update
    final currentTrip = state.asData?.value;
    if (currentTrip != null) {
      final updatedLines = currentTrip.lines.map((line) {
        if (line.id == tripLineId) {
          return line.copyWith(status: TripLineStatus.absent);
        }
        return line;
      }).toList();

      final updatedTrip = currentTrip.copyWith(
        lines: updatedLines,
        absentCount: currentTrip.absentCount + 1,
      );

      state = AsyncValue.data(updatedTrip);
    }

    final result = await repository.markPassengerAbsent(tripLineId);

    // Check if still mounted after async operation
    if (!_isMounted) {
      // Still return true if the operation succeeded on the server
      return result.isRight();
    }

    return result.fold(
      (failure) {
        if (currentTrip != null && _isMounted) {
          state = AsyncValue.data(currentTrip);
        }
        return false;
      },
      (line) {
        if (currentTrip != null && _isMounted) {
          loadTrip(currentTrip.id);
          _invalidateDriverTripsList();
        }
        return true;
      },
    );
  }

  Future<bool> markPassengerDropped(int tripLineId) async {
    final repository = _repository;
    if (repository == null) return false;

    // Optimistic update
    final currentTrip = state.asData?.value;
    if (currentTrip != null) {
      final updatedLines = currentTrip.lines.map((line) {
        if (line.id == tripLineId) {
          return line.copyWith(status: TripLineStatus.dropped);
        }
        return line;
      }).toList();

      final updatedTrip = currentTrip.copyWith(
        lines: updatedLines,
        droppedCount: currentTrip.droppedCount + 1,
      );

      state = AsyncValue.data(updatedTrip);
    }

    final result = await repository.markPassengerDropped(tripLineId);

    // Check if still mounted after async operation
    if (!_isMounted) {
      // Still return true if the operation succeeded on the server
      return result.isRight();
    }

    return result.fold(
      (failure) {
        if (currentTrip != null && _isMounted) {
          state = AsyncValue.data(currentTrip);
        }
        return false;
      },
      (line) {
        if (currentTrip != null && _isMounted) {
          loadTrip(currentTrip.id);
          _invalidateDriverTripsList();
        }
        return true;
      },
    );
  }

  Future<bool> resetPassengerToPlanned(int tripLineId) async {
    final repository = _repository;
    if (repository == null) return false;

    // Optimistic update
    final currentTrip = state.asData?.value;
    if (currentTrip != null) {
      final updatedLines = currentTrip.lines.map((line) {
        if (line.id == tripLineId) {
          return line.copyWith(status: TripLineStatus.notStarted);
        }
        return line;
      }).toList();

      final updatedTrip = currentTrip.copyWith(lines: updatedLines);

      state = AsyncValue.data(updatedTrip);
    }

    final result = await repository.resetPassengerToPlanned(tripLineId);

    // Check if still mounted after async operation
    if (!_isMounted) {
      // Still return true if the operation succeeded on the server
      return result.isRight();
    }

    return result.fold(
      (failure) {
        if (currentTrip != null && _isMounted) {
          state = AsyncValue.data(currentTrip);
        }
        return false;
      },
      (line) {
        if (currentTrip != null && _isMounted) {
          loadTrip(currentTrip.id);
          _invalidateDriverTripsList();
        }
        return true;
      },
    );
  }

  /// Add a passenger to the trip
  Future<bool> addPassengerToTrip({
    required int tripId,
    required int passengerId,
    int seatCount = 1,
    String? notes,
  }) async {
    final repository = _repository;
    if (repository == null) return false;

    state = const AsyncValue.loading();

    final result = await repository.addPassengerToTrip(
      tripId: tripId,
      passengerId: passengerId,
      seatCount: seatCount,
      notes: notes,
    );

    if (!_isMounted) {
      return result.isRight();
    }

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (line) {
        // Refresh the trip to get updated data
        ref.invalidate(tripDetailProvider(tripId));
        ref.invalidate(availablePassengersForTripProvider(tripId));
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  /// Remove a passenger from the trip
  Future<bool> removePassengerFromTrip({
    required int tripId,
    required int tripLineId,
  }) async {
    final repository = _repository;
    if (repository == null) return false;

    state = const AsyncValue.loading();

    final result = await repository.removePassengerFromTrip(tripLineId);

    if (!_isMounted) {
      return result.isRight();
    }

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        // Refresh the trip to get updated data
        ref.invalidate(tripDetailProvider(tripId));
        ref.invalidate(availablePassengersForTripProvider(tripId));
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  /// Update a trip line (passenger in trip)
  Future<bool> updateTripLine({
    required int tripId,
    required int tripLineId,
    int? seatCount,
    String? notes,
  }) async {
    final repository = _repository;
    if (repository == null) return false;

    state = const AsyncValue.loading();

    final result = await repository.updateTripLine(
      tripLineId: tripLineId,
      seatCount: seatCount,
      notes: notes,
    );

    if (!_isMounted) {
      return result.isRight();
    }

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (line) {
        // Refresh the trip to get updated data
        ref.invalidate(tripDetailProvider(tripId));
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}

/// Active Trip Provider
final activeTripProvider =
    NotifierProvider.autoDispose<ActiveTripNotifier, AsyncValue<Trip?>>(() {
      return ActiveTripNotifier();
    });

/// Manager Analytics Provider
final managerAnalyticsProvider = FutureProvider.autoDispose<ManagerAnalytics>((
  ref,
) async {
  final repository = ref.watch(tripRepositoryProvider);
  if (repository == null) {
    return const ManagerAnalytics();
  }

  final result = await repository.getManagerAnalytics();
  return result.fold(
    (failure) => const ManagerAnalytics(),
    (analytics) => analytics,
  );
});
