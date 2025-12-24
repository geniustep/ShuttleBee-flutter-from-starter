import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../entities/dispatcher_holiday.dart';
import '../../repositories/dispatcher_holiday_repository.dart';

/// Parameters for creating a holiday
class CreateHolidayParams {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;

  const CreateHolidayParams({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.notes,
  });
}

/// Use Case: Create Holiday
///
/// Creates a new holiday in the system.
/// Follows Clean Architecture principles by encapsulating business logic.
class CreateHoliday {
  final DispatcherHolidayRepository repository;

  const CreateHoliday(this.repository);

  /// Execute the use case
  ///
  /// [params] - The holiday creation parameters
  /// Returns the created [DispatcherHoliday] or a [Failure]
  Future<Either<Failure, DispatcherHoliday>> call(
    CreateHolidayParams params,
  ) async {
    return await repository.createHoliday(
      name: params.name,
      startDate: params.startDate,
      endDate: params.endDate,
      notes: params.notes,
    );
  }
}
