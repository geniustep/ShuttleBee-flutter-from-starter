import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_partner_repository.dart';

/// Parameters for updating temporary location
class UpdateTemporaryLocationParams {
  final int passengerId;
  final String? temporaryAddress;
  final double? temporaryLatitude;
  final double? temporaryLongitude;
  final String? temporaryContactName;
  final String? temporaryContactPhone;

  const UpdateTemporaryLocationParams({
    required this.passengerId,
    this.temporaryAddress,
    this.temporaryLatitude,
    this.temporaryLongitude,
    this.temporaryContactName,
    this.temporaryContactPhone,
  });
}

/// Use Case: Update Temporary Location
///
/// Sets a temporary address/location for a passenger.
/// This is useful when a passenger needs to be picked up or dropped off
/// at a different location temporarily.
/// Follows Clean Architecture principles by encapsulating business logic.
class UpdateTemporaryLocation {
  final DispatcherPartnerRepository repository;

  const UpdateTemporaryLocation(this.repository);

  /// Execute the use case
  ///
  /// [params] - The temporary location parameters
  /// Returns void on success or a [Failure]
  Future<Either<Failure, void>> call(
    UpdateTemporaryLocationParams params,
  ) async {
    return await repository.updateTemporaryLocation(
      passengerId: params.passengerId,
      temporaryAddress: params.temporaryAddress,
      temporaryLatitude: params.temporaryLatitude,
      temporaryLongitude: params.temporaryLongitude,
      temporaryContactName: params.temporaryContactName,
      temporaryContactPhone: params.temporaryContactPhone,
    );
  }
}
