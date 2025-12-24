import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_passenger_repository.dart';

/// Parameters for assigning a passenger to a group
class AssignPassengerToGroupParams {
  final int lineId;
  final int groupId;

  const AssignPassengerToGroupParams({
    required this.lineId,
    required this.groupId,
  });
}

/// Use Case: Assign Passenger To Group
///
/// Assigns a passenger line to a specific group.
/// This updates the group assignment for an existing passenger line.
/// Follows Clean Architecture principles by encapsulating business logic.
class AssignPassengerToGroup {
  final DispatcherPassengerRepository repository;

  const AssignPassengerToGroup(this.repository);

  /// Execute the use case
  ///
  /// [params] - The assignment parameters
  /// Returns void on success or a [Failure]
  Future<Either<Failure, void>> call(
    AssignPassengerToGroupParams params,
  ) async {
    return await repository.assignLineToGroup(
      lineId: params.lineId,
      groupId: params.groupId,
    );
  }
}
