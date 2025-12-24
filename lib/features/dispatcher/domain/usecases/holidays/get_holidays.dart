import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../entities/dispatcher_holiday.dart';
import '../../repositories/dispatcher_holiday_repository.dart';

/// Use Case: Get Holidays
///
/// Fetches all holidays from the system with optional filtering.
/// Follows Clean Architecture principles by encapsulating business logic.
class GetHolidays {
  final DispatcherHolidayRepository repository;

  const GetHolidays(this.repository);

  /// Execute the use case
  ///
  /// [activeOnly] - If true, returns only active holidays (default: true)
  /// Returns a list of [DispatcherHoliday] or a [Failure]
  Future<Either<Failure, List<DispatcherHoliday>>> call({
    bool activeOnly = true,
  }) async {
    return await repository.getHolidays(activeOnly: activeOnly);
  }
}
