import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_partner_repository.dart';

/// Parameters for updating a passenger
class UpdatePassengerParams {
  final int passengerId;
  final String? name;
  final String? phone;
  final String? mobile;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? street;
  final String? street2;
  final String? city;
  final String? zip;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final bool? useGpsForPickup;
  final bool? useGpsForDropoff;
  final String? tripDirection;
  final bool? autoNotification;
  final bool? active;

  const UpdatePassengerParams({
    required this.passengerId,
    this.name,
    this.phone,
    this.mobile,
    this.guardianPhone,
    this.guardianEmail,
    this.street,
    this.street2,
    this.city,
    this.zip,
    this.notes,
    this.latitude,
    this.longitude,
    this.useGpsForPickup,
    this.useGpsForDropoff,
    this.tripDirection,
    this.autoNotification,
    this.active,
  });
}

/// Use Case: Update Passenger
///
/// Updates an existing passenger profile in the system.
/// Follows Clean Architecture principles by encapsulating business logic.
class UpdatePassenger {
  final DispatcherPartnerRepository repository;

  const UpdatePassenger(this.repository);

  /// Execute the use case
  ///
  /// [params] - The passenger update parameters
  /// Returns void on success or a [Failure]
  Future<Either<Failure, void>> call(UpdatePassengerParams params) async {
    return await repository.updatePassenger(
      passengerId: params.passengerId,
      name: params.name,
      phone: params.phone,
      mobile: params.mobile,
      guardianPhone: params.guardianPhone,
      guardianEmail: params.guardianEmail,
      street: params.street,
      street2: params.street2,
      city: params.city,
      zip: params.zip,
      notes: params.notes,
      latitude: params.latitude,
      longitude: params.longitude,
      useGpsForPickup: params.useGpsForPickup,
      useGpsForDropoff: params.useGpsForDropoff,
      tripDirection: params.tripDirection,
      autoNotification: params.autoNotification,
      active: params.active,
    );
  }
}
