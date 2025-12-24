import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_holiday_repository.dart';

/// Use Case: Delete Holiday
///
/// Deletes a holiday from the system.
/// Follows Clean Architecture principles by encapsulating business logic.
class DeleteHoliday {
  final DispatcherHolidayRepository repository;

  const DeleteHoliday(this.repository);

  /// Execute the use case
  ///
  /// [holidayId] - ID of the holiday to delete
  /// Returns true if successful, or a [Failure]
  Future<Either<Failure, bool>> call(int holidayId) async {
    return await repository.deleteHoliday(holidayId);
  }
}
