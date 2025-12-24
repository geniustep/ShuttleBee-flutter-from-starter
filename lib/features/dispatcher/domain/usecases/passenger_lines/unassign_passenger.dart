import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_passenger_repository.dart';

/// Use Case: Unassign Passenger
///
/// Removes a passenger line from its current group assignment.
/// This sets the group to null, making the passenger unassigned.
/// Follows Clean Architecture principles by encapsulating business logic.
class UnassignPassenger {
  final DispatcherPassengerRepository repository;

  const UnassignPassenger(this.repository);

  /// Execute the use case
  ///
  /// [lineId] - ID of the passenger line to unassign
  /// Returns void on success or a [Failure]
  Future<Either<Failure, void>> call(int lineId) async {
    return await repository.unassignLine(lineId: lineId);
  }
}
