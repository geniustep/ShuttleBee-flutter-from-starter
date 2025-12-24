import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../domain/entities/passenger_group_line.dart';
import '../../domain/repositories/dispatcher_passenger_repository.dart';
import '../datasources/dispatcher_passenger_remote_data_source.dart';

/// Implementation of [DispatcherPassengerRepository]
///
/// Uses [DispatcherPassengerRemoteDataSource] to communicate with the backend.
/// Wraps all data source calls with try-catch and returns Either<Failure, T>
/// for functional error handling.
class DispatcherPassengerRepositoryImpl
    implements DispatcherPassengerRepository {
  final DispatcherPassengerRemoteDataSource _dataSource;

  const DispatcherPassengerRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<PassengerGroupLine>>> getGroupPassengers(
    int groupId,
  ) async {
    try {
      final result = await _dataSource.getGroupPassengers(groupId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PassengerGroupLine>>> getPassengerLines(
    int passengerId,
  ) async {
    try {
      final result = await _dataSource.getPassengerLines(passengerId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncUnassignedPassengers() async {
    try {
      await _dataSource.syncUnassignedPassengers();
      return const Right(null);
    } catch (e) {
      // Sync is best-effort, so we still return success but could log the error
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, List<PassengerGroupLine>>>
      getUnassignedPassengers() async {
    try {
      final result = await _dataSource.getUnassignedPassengers();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PassengerGroupLine>>> getPassengersInOtherGroups(
    int groupId,
  ) async {
    try {
      final result = await _dataSource.getPassengersInOtherGroups(groupId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignLineToGroup({
    required int lineId,
    required int groupId,
  }) async {
    try {
      await _dataSource.assignLineToGroup(
        lineId: lineId,
        groupId: groupId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unassignLine({required int lineId}) async {
    try {
      await _dataSource.unassignLine(lineId: lineId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLine({
    required int lineId,
    int? seatCount,
    int? sequence,
    String? notes,
    int? pickupStopId,
    int? dropoffStopId,
  }) async {
    try {
      await _dataSource.updateLine(
        lineId: lineId,
        seatCount: seatCount,
        sequence: sequence,
        notes: notes,
        pickupStopId: pickupStopId,
        dropoffStopId: dropoffStopId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLine({required int lineId}) async {
    try {
      await _dataSource.deleteLine(lineId: lineId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
