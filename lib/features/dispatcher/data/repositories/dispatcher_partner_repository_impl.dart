import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../domain/entities/dispatcher_passenger_profile.dart';
import '../../domain/repositories/dispatcher_partner_repository.dart';
import '../datasources/dispatcher_partner_remote_data_source.dart';

/// Implementation of [DispatcherPartnerRepository]
///
/// Uses [DispatcherPartnerRemoteDataSource] to communicate with the backend.
/// Wraps all data source calls with try-catch and returns Either<Failure, T>
/// for functional error handling.
class DispatcherPartnerRepositoryImpl implements DispatcherPartnerRepository {
  final DispatcherPartnerRemoteDataSource _dataSource;

  const DispatcherPartnerRepositoryImpl(this._dataSource);

  @override
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
  }) async {
    try {
      final result = await _dataSource.createPassenger(
        name: name,
        phone: phone,
        mobile: mobile,
        guardianPhone: guardianPhone,
        guardianEmail: guardianEmail,
        street: street,
        city: city,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
        useGpsForPickup: useGpsForPickup,
        useGpsForDropoff: useGpsForDropoff,
        tripDirection: tripDirection,
        autoNotification: autoNotification,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DispatcherPassengerProfile>> getPassengerById(
    int passengerId,
  ) async {
    try {
      final result = await _dataSource.getPassengerById(passengerId);
      if (result == null) {
        return Left(
          ServerFailure(
            message: 'Passenger with ID $passengerId not found',
            code: 'NOT_FOUND',
          ),
        );
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      await _dataSource.updatePassenger(
        passengerId: passengerId,
        name: name,
        phone: phone,
        mobile: mobile,
        guardianPhone: guardianPhone,
        guardianEmail: guardianEmail,
        street: street,
        street2: street2,
        city: city,
        zip: zip,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
        useGpsForPickup: useGpsForPickup,
        useGpsForDropoff: useGpsForDropoff,
        tripDirection: tripDirection,
        autoNotification: autoNotification,
        active: active,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePassenger(int passengerId) async {
    try {
      await _dataSource.deletePassenger(passengerId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTemporaryLocation({
    required int passengerId,
    String? temporaryAddress,
    double? temporaryLatitude,
    double? temporaryLongitude,
    String? temporaryContactName,
    String? temporaryContactPhone,
  }) async {
    try {
      await _dataSource.updateTemporaryLocation(
        passengerId: passengerId,
        temporaryAddress: temporaryAddress,
        temporaryLatitude: temporaryLatitude,
        temporaryLongitude: temporaryLongitude,
        temporaryContactName: temporaryContactName,
        temporaryContactPhone: temporaryContactPhone,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearTemporaryLocation(int passengerId) async {
    try {
      await _dataSource.clearTemporaryLocation(passengerId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGuardianInfo({
    required int passengerId,
    bool? hasGuardian,
    String? fatherName,
    String? fatherPhone,
    String? motherName,
    String? motherPhone,
  }) async {
    try {
      await _dataSource.updateGuardianInfo(
        passengerId: passengerId,
        hasGuardian: hasGuardian,
        fatherName: fatherName,
        fatherPhone: fatherPhone,
        motherName: motherName,
        motherPhone: motherPhone,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
