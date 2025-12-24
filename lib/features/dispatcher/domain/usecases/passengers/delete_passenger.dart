import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_partner_repository.dart';

/// Use Case: Delete Passenger
///
/// Deletes a passenger from the system.
/// Follows Clean Architecture principles by encapsulating business logic.
class DeletePassenger {
  final DispatcherPartnerRepository repository;

  const DeletePassenger(this.repository);

  /// Execute the use case
  ///
  /// [passengerId] - ID of the passenger to delete
  /// Returns void on success or a [Failure]
  Future<Either<Failure, void>> call(int passengerId) async {
    return await repository.deletePassenger(passengerId);
  }
}
