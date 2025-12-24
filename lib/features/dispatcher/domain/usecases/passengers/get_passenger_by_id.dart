import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../entities/dispatcher_passenger_profile.dart';
import '../../repositories/dispatcher_partner_repository.dart';

/// Use Case: Get Passenger By ID
///
/// Fetches a specific passenger profile by ID.
/// Follows Clean Architecture principles by encapsulating business logic.
class GetPassengerById {
  final DispatcherPartnerRepository repository;

  const GetPassengerById(this.repository);

  /// Execute the use case
  ///
  /// [passengerId] - The ID of the passenger to retrieve
  /// Returns the [DispatcherPassengerProfile] or a [Failure]
  /// Returns [ServerFailure] if passenger is not found
  Future<Either<Failure, DispatcherPassengerProfile>> call(
    int passengerId,
  ) async {
    return await repository.getPassengerById(passengerId);
  }
}
