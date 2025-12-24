import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../entities/passenger_group_line.dart';
import '../../repositories/dispatcher_passenger_repository.dart';

/// Use Case: Get Passenger Lines
///
/// Fetches all group assignments for a specific passenger.
/// Returns all passenger group line records for a given passenger ID.
/// Follows Clean Architecture principles by encapsulating business logic.
class GetPassengerLines {
  final DispatcherPassengerRepository repository;

  const GetPassengerLines(this.repository);

  /// Execute the use case
  ///
  /// [passengerId] - The ID of the passenger
  /// Returns a list of [PassengerGroupLine] or a [Failure]
  Future<Either<Failure, List<PassengerGroupLine>>> call(
    int passengerId,
  ) async {
    return await repository.getPassengerLines(passengerId);
  }
}
