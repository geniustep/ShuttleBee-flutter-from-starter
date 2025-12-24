import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../entities/dispatcher_holiday.dart';

/// Dispatcher Holiday Repository Interface
///
/// Defines operations for managing global holidays in the dispatcher feature.
/// All operations return Either<Failure, T> for functional error handling.
abstract class DispatcherHolidayRepository {
  /// Get all holidays from the system
  ///
  /// [activeOnly] - If true, returns only active holidays (default: true)
  /// Returns a list of [DispatcherHoliday] or a [Failure]
  Future<Either<Failure, List<DispatcherHoliday>>> getHolidays({
    bool activeOnly = true,
  });

  /// Get a specific holiday by ID
  ///
  /// [holidayId] - The ID of the holiday to retrieve
  /// Returns the [DispatcherHoliday] or a [Failure]
  /// Returns [ServerFailure] if holiday is not found
  Future<Either<Failure, DispatcherHoliday>> getHolidayById(int holidayId);

  /// Create a new holiday
  ///
  /// [name] - Name of the holiday
  /// [startDate] - Start date of the holiday
  /// [endDate] - End date of the holiday
  /// [notes] - Optional notes about the holiday
  /// Returns the created [DispatcherHoliday] or a [Failure]
  Future<Either<Failure, DispatcherHoliday>> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  });

  /// Update an existing holiday
  ///
  /// [holidayId] - ID of the holiday to update
  /// [name] - Updated name
  /// [startDate] - Updated start date
  /// [endDate] - Updated end date
  /// [notes] - Updated notes (optional)
  /// [active] - Updated active status (optional)
  /// Returns true if successful, false otherwise, or a [Failure]
  Future<Either<Failure, bool>> updateHoliday({
    required int holidayId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    bool? active,
  });

  /// Delete a holiday
  ///
  /// [holidayId] - ID of the holiday to delete
  /// Returns true if successful, false otherwise, or a [Failure]
  Future<Either<Failure, bool>> deleteHoliday(int holidayId);
}
