import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../entities/dispatcher_passenger_profile.dart';

/// Dispatcher Partner Repository Interface
///
/// Defines operations for managing passenger profiles (res.partner) in the dispatcher feature.
/// All operations return Either<Failure, T> for functional error handling.
abstract class DispatcherPartnerRepository {
  /// Create a new passenger in the system
  ///
  /// [name] - Passenger name (required)
  /// [phone] - Passenger phone number (optional)
  /// [mobile] - Passenger mobile number (optional)
  /// [guardianPhone] - Guardian phone number (optional)
  /// [guardianEmail] - Guardian email (optional)
  /// [street] - Street address (optional)
  /// [city] - City (optional)
  /// [notes] - Additional notes (optional)
  /// [latitude] - GPS latitude (optional)
  /// [longitude] - GPS longitude (optional)
  /// [useGpsForPickup] - Use GPS for pickup location (default: true)
  /// [useGpsForDropoff] - Use GPS for dropoff location (default: true)
  /// [tripDirection] - Trip direction: 'both', 'pickup', or 'dropoff' (default: 'both')
  /// [autoNotification] - Enable auto notifications (default: true)
  /// Returns the created passenger ID or a [Failure]
  Future<Either<Failure, int>> createPassenger({
    required String name,
    String? phone,
    String? mobile,
    String? guardianPhone,
    String? guardianEmail,
    String? street,
    String? city,
    String? notes,
    double? latitude,
    double? longitude,
    bool useGpsForPickup = true,
    bool useGpsForDropoff = true,
    String tripDirection = 'both',
    bool autoNotification = true,
  });

  /// Get passenger profile by ID
  ///
  /// [passengerId] - The ID of the passenger to retrieve
  /// Returns the [DispatcherPassengerProfile] or a [Failure]
  /// Returns [ServerFailure] if passenger is not found
  Future<Either<Failure, DispatcherPassengerProfile>> getPassengerById(
    int passengerId,
  );

  /// Update an existing passenger profile
  ///
  /// [passengerId] - ID of the passenger to update
  /// All other parameters are optional updates
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> updatePassenger({
    required int passengerId,
    String? name,
    String? phone,
    String? mobile,
    String? guardianPhone,
    String? guardianEmail,
    String? street,
    String? street2,
    String? city,
    String? zip,
    String? notes,
    double? latitude,
    double? longitude,
    bool? useGpsForPickup,
    bool? useGpsForDropoff,
    String? tripDirection,
    bool? autoNotification,
    bool? active,
  });

  /// Delete a passenger
  ///
  /// [passengerId] - ID of the passenger to delete
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> deletePassenger(int passengerId);

  /// Update passenger temporary location
  ///
  /// [passengerId] - ID of the passenger
  /// [temporaryAddress] - Temporary address text
  /// [temporaryLatitude] - Temporary location latitude
  /// [temporaryLongitude] - Temporary location longitude
  /// [temporaryContactName] - Temporary contact name
  /// [temporaryContactPhone] - Temporary contact phone
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> updateTemporaryLocation({
    required int passengerId,
    String? temporaryAddress,
    double? temporaryLatitude,
    double? temporaryLongitude,
    String? temporaryContactName,
    String? temporaryContactPhone,
  });

  /// Clear passenger temporary location
  ///
  /// [passengerId] - ID of the passenger
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> clearTemporaryLocation(int passengerId);

  /// Update guardian information
  ///
  /// [passengerId] - ID of the passenger
  /// [hasGuardian] - Whether passenger has a guardian
  /// [fatherName] - Father's name
  /// [fatherPhone] - Father's phone number
  /// [motherName] - Mother's name
  /// [motherPhone] - Mother's phone number
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> updateGuardianInfo({
    required int passengerId,
    bool? hasGuardian,
    String? fatherName,
    String? fatherPhone,
    String? motherName,
    String? motherPhone,
  });
}
