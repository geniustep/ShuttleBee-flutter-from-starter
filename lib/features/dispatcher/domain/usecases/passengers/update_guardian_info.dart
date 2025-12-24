import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_partner_repository.dart';

/// Parameters for updating guardian information
class UpdateGuardianInfoParams {
  final int passengerId;
  final bool? hasGuardian;
  final String? fatherName;
  final String? fatherPhone;
  final String? motherName;
  final String? motherPhone;

  const UpdateGuardianInfoParams({
    required this.passengerId,
    this.hasGuardian,
    this.fatherName,
    this.fatherPhone,
    this.motherName,
    this.motherPhone,
  });
}

/// Use Case: Update Guardian Info
///
/// Updates guardian information for a passenger.
/// Supports the new guardian structure with separate father/mother fields.
/// Follows Clean Architecture principles by encapsulating business logic.
class UpdateGuardianInfo {
  final DispatcherPartnerRepository repository;

  const UpdateGuardianInfo(this.repository);

  /// Execute the use case
  ///
  /// [params] - The guardian information parameters
  /// Returns void on success or a [Failure]
  Future<Either<Failure, void>> call(UpdateGuardianInfoParams params) async {
    return await repository.updateGuardianInfo(
      passengerId: params.passengerId,
      hasGuardian: params.hasGuardian,
      fatherName: params.fatherName,
      fatherPhone: params.fatherPhone,
      motherName: params.motherName,
      motherPhone: params.motherPhone,
    );
  }
}
