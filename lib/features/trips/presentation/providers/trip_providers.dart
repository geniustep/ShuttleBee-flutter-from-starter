import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shuttlebee/presentation/providers/shuttlebee_api_providers.dart';
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

  DriverTripsQuery({
    required this.driverId,
    required DateTime date,
  }) : date = DateTime(date.year, date.month, date.day);

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
final driverDailyTripsProvider = FutureProvider.autoDispose
    .family<List<Trip>, DriverTripsQuery>((ref, query) async {
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
      final trips = await shuttleApi.getMyTrips();
      final filtered = trips.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return d == date;
      }).toList();
      print(
          '✅ [driverDailyTripsProvider] Got ${filtered.length} trips from /trips/my');
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
          final errorMessage =
              ErrorTranslator.translateFailure(failure.message);
          throw Exception(errorMessage);
        },
        (trips) {
          print(
              '✅ [driverDailyTripsProvider] Got ${trips.length} trips (fallback)');
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
final passengerTripsProvider =
    FutureProvider.autoDispose<List<Trip>>((ref) async {
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
final tripDetailProvider =
    FutureProvider.autoDispose.family<Trip?, int>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  if (repository == null) return null;

  final result = await repository.getTripById(tripId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (trip) => trip,
  );
});

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
final allTripsProvider = FutureProvider.autoDispose
    .family<List<Trip>, TripFilters>((ref, filters) async {
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
final ongoingTripsProvider =
    allTripsProvider(const TripFilters(state: TripState.ongoing, limit: 200));

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
}

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

    return result.fold(
      (failure) => false,
      (trip) {
        state = AsyncValue.data(trip);
        _invalidateDriverTripsList();
        return true;
      },
    );
  }

  Future<bool> completeTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return false;

    final result = await repository.completeTrip(tripId);

    // Check if still mounted after async operation
    if (!_isMounted) return false;

    return result.fold(
      (failure) => false,
      (trip) {
        state = AsyncValue.data(trip);
        _invalidateDriverTripsList();
        return true;
      },
    );
  }

  Future<bool> cancelTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return false;

    final result = await repository.cancelTrip(tripId);

    // Check if still mounted after async operation
    if (!_isMounted) return false;

    return result.fold(
      (failure) => false,
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
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

      final updatedTrip = currentTrip.copyWith(
        lines: updatedLines,
      );

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
}

/// Active Trip Provider
final activeTripProvider =
    NotifierProvider.autoDispose<ActiveTripNotifier, AsyncValue<Trip?>>(() {
  return ActiveTripNotifier();
});

/// Manager Analytics Provider
final managerAnalyticsProvider =
    FutureProvider.autoDispose<ManagerAnalytics>((ref) async {
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
