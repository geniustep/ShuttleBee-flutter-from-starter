import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';

/// Local cache for Stops & Locations
///
/// Provides offline-first caching for:
/// - Stop list
/// - Location coordinates
/// - Stop metadata
class StopLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _stopsCollection = 'stops';
  static const String _coordinatesCollection = 'stop_coordinates';

  // Cache TTL
  static const Duration _stopsTTL = Duration(hours: 24);
  static const Duration _coordinatesTTL = Duration(days: 7);

  StopLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Stops Cache
  // ════════════════════════════════════════════════════════════

  /// Save stops list to cache
  Future<Either<Failure, bool>> cacheStops(
    List<Map<String, dynamic>> stops,
  ) async {
    try {
      return await _storage.saveCollection(
        collectionName: _stopsCollection,
        items: stops,
        ttl: _stopsTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache stops: $e'));
    }
  }

  /// Load cached stops
  Future<Either<Failure, List<Map<String, dynamic>>>> getCachedStops() async {
    return await _storage.loadCollection(_stopsCollection);
  }

  /// Get single stop by ID
  Future<Either<Failure, Map<String, dynamic>?>> getCachedStop(
    int stopId,
  ) async {
    final stopsResult = await getCachedStops();
    return stopsResult.fold((failure) => Left(failure), (stops) {
      try {
        final stop = stops.firstWhere(
          (s) => (s['id'] as int?) == stopId,
          orElse: () => throw Exception('Stop not found'),
        );
        return Right(stop);
      } catch (_) {
        return const Right(null);
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // Coordinates Cache
  // ════════════════════════════════════════════════════════════

  /// Save stop coordinates
  Future<Either<Failure, bool>> cacheStopCoordinates(
    int stopId,
    double latitude,
    double longitude, {
    String? address,
  }) async {
    try {
      return await _storage.save(
        key: '$_coordinatesCollection$stopId',
        data: {
          'stop_id': stopId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'cached_at': DateTime.now().toIso8601String(),
        },
        ttl: _coordinatesTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache coordinates: $e'));
    }
  }

  /// Get cached stop coordinates
  Future<Either<Failure, Map<String, dynamic>?>> getCachedStopCoordinates(
    int stopId,
  ) async {
    final result = await _storage.load('$_coordinatesCollection$stopId');
    return result.fold((failure) => Left(failure), (data) => Right(data));
  }

  /// Save multiple stop coordinates
  Future<Either<Failure, bool>> cacheStopCoordinatesBatch(
    Map<int, Map<String, dynamic>> coordinates,
  ) async {
    try {
      final items = <String, Map<String, dynamic>>{};
      for (final entry in coordinates.entries) {
        items['$_coordinatesCollection${entry.key}'] = {
          'stop_id': entry.key,
          ...entry.value,
          'cached_at': DateTime.now().toIso8601String(),
        };
      }

      return await _storage.saveBatch(items: items, ttl: _coordinatesTTL);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to cache coordinates batch: $e'),
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all stop caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await _storage.deleteCollection(_stopsCollection);
      // Coordinates are individual keys, will expire via TTL
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
