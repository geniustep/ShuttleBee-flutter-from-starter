import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../entities/passenger_group_line.dart';
import '../../repositories/dispatcher_passenger_repository.dart';

/// Use Case: Get Unassigned Passengers
///
/// Fetches all passengers not assigned to any group.
/// Optionally syncs with backend to ensure all shuttle passengers
/// have corresponding unassigned line records.
/// Follows Clean Architecture principles by encapsulating business logic.
class GetUnassignedPassengers {
  final DispatcherPassengerRepository repository;

  const GetUnassignedPassengers(this.repository);

  /// Execute the use case
  ///
  /// [syncFirst] - If true, syncs unassigned passengers with backend first
  /// Returns a list of [PassengerGroupLine] with groupId = null or a [Failure]
  Future<Either<Failure, List<PassengerGroupLine>>> call({
    bool syncFirst = false,
  }) async {
    // Optionally sync first to ensure backend has unassigned lines
    if (syncFirst) {
      final syncResult = await repository.syncUnassignedPassengers();
      // Continue even if sync fails (best-effort operation)
      syncResult.fold(
        (failure) {
          // Log or handle sync failure if needed, but continue to fetch
        },
        (_) {},
      );
    }

    return await repository.getUnassignedPassengers();
  }
}
