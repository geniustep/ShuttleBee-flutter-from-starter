import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../domain/entities/dispatcher_holiday.dart';
import '../../domain/repositories/dispatcher_holiday_repository.dart';
import '../datasources/dispatcher_holiday_remote_data_source.dart';

/// Implementation of [DispatcherHolidayRepository]
///
/// Uses [DispatcherHolidayRemoteDataSource] to communicate with the backend.
/// Wraps all data source calls with try-catch and returns Either<Failure, T>
/// for functional error handling.
class DispatcherHolidayRepositoryImpl implements DispatcherHolidayRepository {
  final DispatcherHolidayRemoteDataSource _dataSource;

  const DispatcherHolidayRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<DispatcherHoliday>>> getHolidays({
    bool activeOnly = true,
  }) async {
    try {
      final result = await _dataSource.getHolidays(activeOnly: activeOnly);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DispatcherHoliday>> getHolidayById(
    int holidayId,
  ) async {
    try {
      final result = await _dataSource.getHolidayById(holidayId);
      if (result == null) {
        return Left(
          ServerFailure(
            message: 'Holiday with ID $holidayId not found',
            code: 'NOT_FOUND',
          ),
        );
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DispatcherHoliday>> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    try {
      final result = await _dataSource.createHoliday(
        name: name,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
      );
      if (result == null) {
        return Left(
          ServerFailure(
            message: 'Failed to create holiday',
            code: 'CREATE_FAILED',
          ),
        );
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateHoliday({
    required int holidayId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    bool? active,
  }) async {
    try {
      final result = await _dataSource.updateHoliday(
        holidayId: holidayId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        active: active,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteHoliday(int holidayId) async {
    try {
      final result = await _dataSource.deleteHoliday(holidayId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
