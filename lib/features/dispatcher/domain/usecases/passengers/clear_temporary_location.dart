import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_partner_repository.dart';

/// Use Case: Clear Temporary Location
///
/// Clears the temporary address/location for a passenger,
/// reverting back to using their primary address.
/// Follows Clean Architecture principles by encapsulating business logic.
class ClearTemporaryLocation {
  final DispatcherPartnerRepository repository;

  const ClearTemporaryLocation(this.repository);

  /// Execute the use case
  ///
  /// [passengerId] - ID of the passenger
  /// Returns void on success or a [Failure]
  Future<Either<Failure, void>> call(int passengerId) async {
    return await repository.clearTemporaryLocation(passengerId);
  }
}
