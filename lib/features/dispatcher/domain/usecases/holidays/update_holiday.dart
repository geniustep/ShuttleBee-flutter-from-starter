import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_holiday_repository.dart';

/// Parameters for updating a holiday
class UpdateHolidayParams {
  final int holidayId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final bool? active;

  const UpdateHolidayParams({
    required this.holidayId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.active,
  });
}

/// Use Case: Update Holiday
///
/// Updates an existing holiday in the system.
/// Follows Clean Architecture principles by encapsulating business logic.
class UpdateHoliday {
  final DispatcherHolidayRepository repository;

  const UpdateHoliday(this.repository);

  /// Execute the use case
  ///
  /// [params] - The holiday update parameters
  /// Returns true if successful, or a [Failure]
  Future<Either<Failure, bool>> call(UpdateHolidayParams params) async {
    return await repository.updateHoliday(
      holidayId: params.holidayId,
      name: params.name,
      startDate: params.startDate,
      endDate: params.endDate,
      notes: params.notes,
      active: params.active,
    );
  }
}
