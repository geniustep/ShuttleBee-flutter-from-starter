import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_data_source.dart';

/// Trip Repository Implementation - ShuttleBee
class TripRepositoryImpl extends BaseRepository implements TripRepository {
  final TripRemoteDataSource _remoteDataSource;

  TripRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Trip>>> getTripsByDate(DateTime date) async {
    return execute(() => _remoteDataSource.getTripsByDate(date));
  }

  @override
  Future<Either<Failure, List<Trip>>> getDriverTrips(
    int driverId,
    DateTime date, {
    List<TripState>? states,
  }) async {
    return execute(
      () => _remoteDataSource.getDriverTrips(
        driverId,
        date,
        states: states,
      ),
    );
  }

  @override
  Future<Either<Failure, List<Trip>>> getPassengerTrips(int passengerId) async {
    return execute(() => _remoteDataSource.getPassengerTrips(passengerId));
  }

  @override
  Future<Either<Failure, Trip>> getTripById(int tripId) async {
    return execute(() => _remoteDataSource.getTripById(tripId));
  }

  @override
  Future<Either<Failure, List<Trip>>> getTrips({
    TripState? state,
    TripType? tripType,
    DateTime? fromDate,
    DateTime? toDate,
    int? driverId,
    int? vehicleId,
    int limit = 50,
    int offset = 0,
  }) async {
    return execute(
      () => _remoteDataSource.getTrips(
        state: state,
        tripType: tripType,
        fromDate: fromDate,
        toDate: toDate,
        driverId: driverId,
        vehicleId: vehicleId,
        limit: limit,
        offset: offset,
      ),
    );
  }

  @override
  Future<Either<Failure, Trip>> createTrip(Trip trip) async {
    return execute(() => _remoteDataSource.createTrip(trip));
  }

  @override
  Future<Either<Failure, Trip>> updateTrip(Trip trip) async {
    return execute(() => _remoteDataSource.updateTrip(trip));
  }

  @override
  Future<Either<Failure, Trip>> confirmTrip(
    int tripId, {
    double? latitude,
    double? longitude,
    int? stopId,
    String? note,
  }) async {
    return execute(
      () => _remoteDataSource.confirmTrip(
        tripId,
        latitude: latitude,
        longitude: longitude,
        stopId: stopId,
        note: note,
      ),
    );
  }

  @override
  Future<Either<Failure, Trip>> startTrip(int tripId) async {
    return execute(() => _remoteDataSource.startTrip(tripId));
  }

  @override
  Future<Either<Failure, Trip>> completeTrip(int tripId) async {
    return execute(() => _remoteDataSource.completeTrip(tripId));
  }

  @override
  Future<Either<Failure, void>> cancelTrip(int tripId) async {
    return execute(() => _remoteDataSource.cancelTrip(tripId));
  }

  @override
  Future<Either<Failure, TripLine>> updatePassengerStatus(
    int tripLineId,
    TripLineStatus status,
  ) async {
    return execute(
      () => _remoteDataSource.updatePassengerStatus(tripLineId, status),
    );
  }

  @override
  Future<Either<Failure, TripLine>> markPassengerBoarded(int tripLineId) async {
    return execute(() => _remoteDataSource.markPassengerBoarded(tripLineId));
  }

  @override
  Future<Either<Failure, TripLine>> markPassengerAbsent(int tripLineId) async {
    return execute(() => _remoteDataSource.markPassengerAbsent(tripLineId));
  }

  @override
  Future<Either<Failure, TripLine>> markPassengerDropped(int tripLineId) async {
    return execute(() => _remoteDataSource.markPassengerDropped(tripLineId));
  }

  @override
  Future<Either<Failure, TripLine>> resetPassengerToPlanned(
    int tripLineId,
  ) async {
    return execute(() => _remoteDataSource.resetPassengerToPlanned(tripLineId));
  }

  @override
  Future<Either<Failure, TripDashboardStats>> getDashboardStats(
    DateTime date,
  ) async {
    return execute(() => _remoteDataSource.getDashboardStats(date));
  }

  @override
  Future<Either<Failure, ManagerAnalytics>> getManagerAnalytics() async {
    return const Right(
      ManagerAnalytics(
        totalTripsThisMonth: 100,
      ),
    );
    // return execute(() => _remoteDataSource.getManagerAnalytics());
  }
}
