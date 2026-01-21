import 'dart:io';
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';
import '../../../domain/entities/dispatcher_holiday.dart';
import '../../../../trips/domain/entities/trip.dart';

/// Local cache for Dispatcher feature
///
/// Provides offline-first caching for dispatcher data using
/// platform-specific storage (Mobile vs Windows).
class DispatcherLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _tripsCollection = 'dispatcher_trips';
  static const String _holidaysCollection = 'dispatcher_holidays';
  static const String _passengersCollection = 'dispatcher_passengers';

  // Cache TTL - محسّن حسب المنصة
  static Duration get _tripsCacheTTL => 
      Platform.isWindows ? const Duration(hours: 3) : const Duration(hours: 2);
  
  static Duration get _holidaysCacheTTL => 
      Platform.isWindows ? const Duration(days: 14) : const Duration(days: 7);
  
  static Duration get _passengersCacheTTL => 
      Platform.isWindows ? const Duration(hours: 18) : const Duration(hours: 12);

  DispatcherLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Trips Cache
  // ════════════════════════════════════════════════════════════

  /// Save trips to cache
  Future<Either<Failure, bool>> cacheTrips(List<Trip> trips) async {
    try {
      final tripsJson = trips.map((t) => t.toJson()).toList();
      return await _storage.saveCollection(
        collectionName: _tripsCollection,
        items: tripsJson,
        ttl: _tripsCacheTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache trips: $e'));
    }
  }

  /// Load cached trips
  Future<Either<Failure, List<Trip>>> getCachedTrips() async {
    final result = await _storage.loadCollection(_tripsCollection);

    return result.fold((failure) => Left(failure), (items) {
      try {
        final trips = items.map((json) => Trip.fromJson(json)).toList();
        return Right(trips);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse trips: $e'));
      }
    });
  }

  /// Update single trip in cache
  Future<Either<Failure, bool>> updateCachedTrip(Trip trip) async {
    return _storage.updateCollectionItem(
      collectionName: _tripsCollection,
      itemId: trip.id.toString(),
      data: trip.toJson(),
    );
  }

  /// Delete trip from cache
  Future<Either<Failure, bool>> deleteCachedTrip(int tripId) async {
    return _storage.deleteCollectionItem(
      collectionName: _tripsCollection,
      itemId: tripId.toString(),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Holidays Cache
  // ════════════════════════════════════════════════════════════

  /// Save holidays to cache
  Future<Either<Failure, bool>> cacheHolidays(
    List<DispatcherHoliday> holidays,
  ) async {
    final holidaysJson = holidays.map((h) => h.toJson()).toList();
    return _storage.saveCollection(
      collectionName: _holidaysCollection,
      items: holidaysJson,
      ttl: _holidaysCacheTTL,
    );
  }

  /// Load cached holidays
  Future<Either<Failure, List<DispatcherHoliday>>> getCachedHolidays() async {
    final result = await _storage.loadCollection(_holidaysCollection);

    return result.fold((failure) => Left(failure), (items) {
      try {
        final holidays = items
            .map((json) => DispatcherHoliday.fromJson(json))
            .toList();
        return Right(holidays);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse holidays: $e'));
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // Passengers Cache
  // ════════════════════════════════════════════════════════════

  /// Save passengers to cache
  Future<Either<Failure, bool>> cachePassengers(
    List<Map<String, dynamic>> passengers,
  ) async {
    return _storage.saveCollection(
      collectionName: _passengersCollection,
      items: passengers,
      ttl: _passengersCacheTTL,
    );
  }

  /// Load cached passengers
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getCachedPassengers() async {
    return _storage.loadCollection(_passengersCollection);
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all dispatcher caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      // تنظيف البيانات المنتهية الصلاحية أولاً
      await _storage.clearExpired();
      
      await _storage.deleteCollection(_tripsCollection);
      await _storage.deleteCollection(_holidaysCollection);
      await _storage.deleteCollection(_passengersCollection);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear caches: $e'));
    }
  }

  /// تنظيف البيانات المنتهية الصلاحية فقط
  Future<Either<Failure, int>> cleanupExpired() async {
    try {
      final result = await _storage.clearExpired();
      return result.fold(
        (failure) => Left(failure),
        (count) => Right(count),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cleanup expired: $e'));
    }
  }

  /// Get cache statistics
  Future<Either<Failure, Map<String, dynamic>>> getCacheStats() async {
    return _storage.getStats();
  }
}
