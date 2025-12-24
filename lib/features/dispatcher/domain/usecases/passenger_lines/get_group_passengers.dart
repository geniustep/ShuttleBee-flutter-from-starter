import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../entities/passenger_group_line.dart';
import '../../repositories/dispatcher_passenger_repository.dart';

/// Use Case: Get Group Passengers
///
/// Fetches all passengers assigned to a specific group.
/// Returns passenger group line records for a given group ID.
/// Follows Clean Architecture principles by encapsulating business logic.
class GetGroupPassengers {
  final DispatcherPassengerRepository repository;

  const GetGroupPassengers(this.repository);

  /// Execute the use case
  ///
  /// [groupId] - The ID of the group
  /// Returns a list of [PassengerGroupLine] or a [Failure]
  Future<Either<Failure, List<PassengerGroupLine>>> call(int groupId) async {
    return await repository.getGroupPassengers(groupId);
  }
}
