import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/trip_remote_data_source.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

export '../../domain/repositories/trip_repository.dart'
    show TripDashboardStats, ManagerAnalytics;

/// Trip Remote Data Source Provider
final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return TripRemoteDataSource(client);
});

/// Trip Repository Provider
final tripRepositoryProvider = Provider<TripRepository?>((ref) {
  final dataSource = ref.watch(tripRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return TripRepositoryImpl(dataSource);
});

/// Driver Daily Trips Provider
final driverDailyTripsProvider =
    FutureProvider.autoDispose.family<List<Trip>, DateTime>((ref, date) async {
  final repository = ref.watch(tripRepositoryProvider);
  if (repository == null) {
    throw Exception(ErrorTranslator.translate('خطأ في الاتصال. يرجى المحاولة لاحقاً'));
  }

  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value.user;

  if (user == null) {
    throw Exception('يجب تسجيل الدخول أولاً');
  }

  if (user.partnerId == null) {
    throw Exception('معلومات السائق غير مكتملة. يرجى التواصل مع الإدارة');
  }

  final result = await repository.getDriverTrips(user.partnerId!, date);
  return result.fold(
    (failure) => throw Exception(ErrorTranslator.translateFailure(failure.message)),
    (trips) => trips,
  );
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

  Future<void> loadTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return;

    state = const AsyncValue.loading();

    final result = await repository.getTripById(tripId);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (trip) => AsyncValue.data(trip),
    );
  }

  Future<bool> startTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return false;

    final result = await repository.startTrip(tripId);
    return result.fold(
      (failure) => false,
      (trip) {
        state = AsyncValue.data(trip);
        return true;
      },
    );
  }

  Future<bool> completeTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return false;

    final result = await repository.completeTrip(tripId);
    return result.fold(
      (failure) => false,
      (trip) {
        state = AsyncValue.data(trip);
        return true;
      },
    );
  }

  Future<bool> cancelTrip(int tripId) async {
    final repository = _repository;
    if (repository == null) return false;

    final result = await repository.cancelTrip(tripId);
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
    return result.fold(
      (failure) {
        // Revert on failure
        if (currentTrip != null) {
          state = AsyncValue.data(currentTrip);
        }
        return false;
      },
      (line) {
        // Confirm with server data
        if (currentTrip != null) {
          loadTrip(currentTrip.id);
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
    return result.fold(
      (failure) {
        if (currentTrip != null) {
          state = AsyncValue.data(currentTrip);
        }
        return false;
      },
      (line) {
        if (currentTrip != null) {
          loadTrip(currentTrip.id);
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
    return result.fold(
      (failure) {
        if (currentTrip != null) {
          state = AsyncValue.data(currentTrip);
        }
        return false;
      },
      (line) {
        if (currentTrip != null) {
          loadTrip(currentTrip.id);
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
