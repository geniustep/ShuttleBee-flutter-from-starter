import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../entities/dispatcher_holiday.dart';
import '../../repositories/dispatcher_holiday_repository.dart';

/// Use Case: Get Holiday By ID
///
/// Fetches a specific holiday by its ID.
/// Follows Clean Architecture principles by encapsulating business logic.
class GetHolidayById {
  final DispatcherHolidayRepository repository;

  const GetHolidayById(this.repository);

  /// Execute the use case
  ///
  /// [holidayId] - The ID of the holiday to retrieve
  /// Returns the [DispatcherHoliday] or a [Failure]
  /// Returns [ServerFailure] if holiday is not found
  Future<Either<Failure, DispatcherHoliday>> call(int holidayId) async {
    return await repository.getHolidayById(holidayId);
  }
}
