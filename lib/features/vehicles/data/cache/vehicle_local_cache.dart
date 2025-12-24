import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';
import '../../domain/entities/shuttle_vehicle.dart';

/// Local cache for Vehicle data
///
/// Provides offline-first caching for:
/// - Vehicle list
/// - Driver profiles
/// - Vehicle status
/// - Vehicle location history
class VehicleLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _vehiclesCollection = 'vehicles';
  static const String _driversCollection = 'drivers';
  static const String _statusCollection = 'vehicle_status';
  static const String _locationHistoryCollection = 'vehicle_locations';

  // Cache TTL
  static const Duration _vehiclesTTL = Duration(hours: 12);
  static const Duration _driversTTL = Duration(hours: 24);
  static const Duration _statusTTL = Duration(minutes: 5);
  static const Duration _locationTTL = Duration(hours: 1);

  VehicleLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Vehicles Cache
  // ════════════════════════════════════════════════════════════

  /// Save vehicles list to cache
  Future<Either<Failure, bool>> cacheVehicles(
    List<ShuttleVehicle> vehicles,
  ) async {
    try {
      final vehiclesJson = vehicles.map((v) => v.toJson()).toList();
      return await _storage.saveCollection(
        collectionName: _vehiclesCollection,
        items: vehiclesJson,
        ttl: _vehiclesTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache vehicles: $e'));
    }
  }

  /// Load cached vehicles
  Future<Either<Failure, List<ShuttleVehicle>>> getCachedVehicles() async {
    final result = await _storage.loadCollection(_vehiclesCollection);

    return result.fold((failure) => Left(failure), (items) {
      try {
        final vehicles = items
            .map((json) => ShuttleVehicle.fromJson(json))
            .toList();
        return Right(vehicles);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse vehicles: $e'));
      }
    });
  }

  /// Get single vehicle by ID
  Future<Either<Failure, ShuttleVehicle?>> getCachedVehicle(
    int vehicleId,
  ) async {
    final vehiclesResult = await getCachedVehicles();
    return vehiclesResult.fold((failure) => Left(failure), (vehicles) {
      try {
        final vehicle = vehicles.firstWhere(
          (v) => v.id == vehicleId,
          orElse: () => throw Exception('Vehicle not found'),
        );
        return Right(vehicle);
      } catch (_) {
        return const Right(null);
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // Drivers Cache
  // ════════════════════════════════════════════════════════════

  /// Save drivers list to cache
  Future<Either<Failure, bool>> cacheDrivers(
    List<Map<String, dynamic>> drivers,
  ) async {
    try {
      return await _storage.saveCollection(
        collectionName: _driversCollection,
        items: drivers,
        ttl: _driversTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache drivers: $e'));
    }
  }

  /// Load cached drivers
  Future<Either<Failure, List<Map<String, dynamic>>>> getCachedDrivers() async {
    return await _storage.loadCollection(_driversCollection);
  }

  // ════════════════════════════════════════════════════════════
  // Vehicle Status Cache
  // ════════════════════════════════════════════════════════════

  /// Save vehicle status
  Future<Either<Failure, bool>> cacheVehicleStatus(
    int vehicleId,
    Map<String, dynamic> status,
  ) async {
    try {
      return await _storage.save(
        key: '$_statusCollection$vehicleId',
        data: {
          'vehicle_id': vehicleId,
          ...status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        ttl: _statusTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache status: $e'));
    }
  }

  /// Get cached vehicle status
  Future<Either<Failure, Map<String, dynamic>?>> getCachedVehicleStatus(
    int vehicleId,
  ) async {
    final result = await _storage.load('$_statusCollection$vehicleId');
    return result.fold((failure) => Left(failure), (data) => Right(data));
  }

  // ════════════════════════════════════════════════════════════
  // Location History Cache
  // ════════════════════════════════════════════════════════════

  /// Save vehicle location
  Future<Either<Failure, bool>> cacheVehicleLocation(
    int vehicleId,
    double latitude,
    double longitude, {
    String? address,
    DateTime? timestamp,
  }) async {
    try {
      final locationKey = '$_locationHistoryCollection$vehicleId';
      final result = await _storage.load(locationKey);

      return await result.fold((failure) => Left(failure), (
        existingData,
      ) async {
        final locations = existingData != null
            ? (existingData['locations'] as List<dynamic>?) ?? []
            : <Map<String, dynamic>>[];

        // Add new location
        locations.add({
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        });

        // Keep only last 50 locations
        final finalLocations = locations.length > 50
            ? locations.sublist(locations.length - 50)
            : locations;

        return await _storage.save(
          key: locationKey,
          data: {
            'vehicle_id': vehicleId,
            'locations': finalLocations,
            'last_updated': DateTime.now().toIso8601String(),
          },
          ttl: _locationTTL,
        );
      });
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache location: $e'));
    }
  }

  /// Get cached vehicle location history
  Future<Either<Failure, List<Map<String, dynamic>>>> getCachedVehicleLocations(
    int vehicleId,
  ) async {
    final result = await _storage.load('$_locationHistoryCollection$vehicleId');
    return result.fold((failure) => Left(failure), (data) {
      if (data == null) return const Right([]);
      final locations = (data['locations'] as List<dynamic>?) ?? [];
      return Right(locations.map((l) => l as Map<String, dynamic>).toList());
    });
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all vehicle caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await _storage.deleteCollection(_vehiclesCollection);
      await _storage.deleteCollection(_driversCollection);
      // Status and locations are individual keys, will expire via TTL
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear caches: $e'));
    }
  }

  /// Get cache statistics
  Future<Either<Failure, Map<String, dynamic>>> getCacheStats() async {
    return _storage.getStats();
  }
}
