import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_partner_repository.dart';

/// Parameters for creating a passenger
class CreatePassengerParams {
  final String name;
  final String? phone;
  final String? mobile;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? street;
  final String? city;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final bool useGpsForPickup;
  final bool useGpsForDropoff;
  final String tripDirection;
  final bool autoNotification;

  const CreatePassengerParams({
    required this.name,
    this.phone,
    this.mobile,
    this.guardianPhone,
    this.guardianEmail,
    this.street,
    this.city,
    this.notes,
    this.latitude,
    this.longitude,
    this.useGpsForPickup = true,
    this.useGpsForDropoff = true,
    this.tripDirection = 'both',
    this.autoNotification = true,
  });
}

/// Use Case: Create Passenger
///
/// Creates a new passenger profile in the system.
/// Follows Clean Architecture principles by encapsulating business logic.
class CreatePassenger {
  final DispatcherPartnerRepository repository;

  const CreatePassenger(this.repository);

  /// Execute the use case
  ///
  /// [params] - The passenger creation parameters
  /// Returns the created passenger ID or a [Failure]
  Future<Either<Failure, int>> call(CreatePassengerParams params) async {
    return await repository.createPassenger(
      name: params.name,
      phone: params.phone,
      mobile: params.mobile,
      guardianPhone: params.guardianPhone,
      guardianEmail: params.guardianEmail,
      street: params.street,
      city: params.city,
      notes: params.notes,
      latitude: params.latitude,
      longitude: params.longitude,
      useGpsForPickup: params.useGpsForPickup,
      useGpsForDropoff: params.useGpsForDropoff,
      tripDirection: params.tripDirection,
      autoNotification: params.autoNotification,
    );
  }
}
