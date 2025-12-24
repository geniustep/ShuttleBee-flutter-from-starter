import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';
import '../../domain/entities/trip.dart';

/// Local cache for Trip History & Analytics
///
/// Provides offline-first caching for:
/// - Completed trips
/// - Trip statistics
/// - Monthly summaries
class TripHistoryCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _completedTripsCollection = 'completed_trips';
  static const String _statisticsKey = 'trip_statistics';
  static const String _monthlySummariesCollection = 'monthly_summaries';

  // Cache TTL
  static const Duration _completedTripsTTL = Duration(days: 90);
  static const Duration _statisticsTTL = Duration(days: 365);
  // Monthly summaries are permanent

  TripHistoryCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Completed Trips Cache
  // ════════════════════════════════════════════════════════════

  /// Save completed trip to cache
  Future<Either<Failure, bool>> cacheCompletedTrip(Trip trip) async {
    try {
      final tripsResult = await getCompletedTrips();
      return await tripsResult.fold((failure) => Left(failure), (trips) async {
        // Remove if exists (update scenario)
        trips.removeWhere((t) => t['id'] == trip.id);

        // Add to beginning
        trips.insert(0, {
          ...trip.toJson(),
          'completed_at': DateTime.now().toIso8601String(),
        });

        // Keep only last 500 trips
        if (trips.length > 500) {
          trips = trips.sublist(0, 500);
        }

        return await _storage.saveCollection(
          collectionName: _completedTripsCollection,
          items: trips,
          ttl: _completedTripsTTL,
        );
      });
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache trip: $e'));
    }
  }

  /// Save multiple completed trips
  Future<Either<Failure, bool>> cacheCompletedTrips(List<Trip> trips) async {
    try {
      final tripsJson = trips
          .map(
            (t) => {
              ...t.toJson(),
              'completed_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      return await _storage.saveCollection(
        collectionName: _completedTripsCollection,
        items: tripsJson,
        ttl: _completedTripsTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache trips: $e'));
    }
  }

  /// Get completed trips
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getCompletedTrips() async {
    return await _storage.loadCollection(_completedTripsCollection);
  }

  /// Get completed trips by date range
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getCompletedTripsByDateRange(DateTime startDate, DateTime endDate) async {
    final tripsResult = await getCompletedTrips();
    return tripsResult.fold((failure) => Left(failure), (trips) {
      final filtered = trips.where((t) {
        final tripDate = DateTime.tryParse(t['date'] as String? ?? '');
        if (tripDate == null) return false;
        return tripDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            tripDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      return Right(filtered);
    });
  }

  // ════════════════════════════════════════════════════════════
  // Trip Statistics Cache
  // ════════════════════════════════════════════════════════════

  /// Save trip statistics
  Future<Either<Failure, bool>> cacheStatistics(
    Map<String, dynamic> statistics,
  ) async {
    try {
      return await _storage.save(
        key: _statisticsKey,
        data: {...statistics, 'updated_at': DateTime.now().toIso8601String()},
        ttl: _statisticsTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache statistics: $e'));
    }
  }

  /// Get trip statistics
  Future<Either<Failure, Map<String, dynamic>?>> getStatistics() async {
    final result = await _storage.load(_statisticsKey);
    return result.fold((failure) => Left(failure), (data) => Right(data));
  }

  // ════════════════════════════════════════════════════════════
  // Monthly Summaries Cache
  // ════════════════════════════════════════════════════════════

  /// Save monthly summary
  Future<Either<Failure, bool>> cacheMonthlySummary({
    required int year,
    required int month,
    required Map<String, dynamic> summary,
  }) async {
    try {
      final summariesResult = await getMonthlySummaries();
      return await summariesResult.fold((failure) => Left(failure), (
        summaries,
      ) async {
        // Remove if exists
        summaries.removeWhere((s) => s['year'] == year && s['month'] == month);

        // Add
        summaries.add({
          'year': year,
          'month': month,
          ...summary,
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Sort by year and month
        summaries.sort((a, b) {
          final yearCompare = (b['year'] as int).compareTo(a['year'] as int);
          if (yearCompare != 0) return yearCompare;
          return (b['month'] as int).compareTo(a['month'] as int);
        });

        return await _storage.saveCollection(
          collectionName: _monthlySummariesCollection,
          items: summaries,
          ttl: null, // Permanent
        );
      });
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache summary: $e'));
    }
  }

  /// Get monthly summaries
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getMonthlySummaries() async {
    return await _storage.loadCollection(_monthlySummariesCollection);
  }

  /// Get monthly summary for specific month
  Future<Either<Failure, Map<String, dynamic>?>> getMonthlySummary(
    int year,
    int month,
  ) async {
    final summariesResult = await getMonthlySummaries();
    return summariesResult.fold((failure) => Left(failure), (summaries) {
      try {
        final summary = summaries.firstWhere(
          (s) => s['year'] == year && s['month'] == month,
          orElse: () => throw Exception('Summary not found'),
        );
        return Right(summary);
      } catch (_) {
        return const Right(null);
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all trip history caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await _storage.deleteCollection(_completedTripsCollection);
      await _storage.delete(_statisticsKey);
      await _storage.deleteCollection(_monthlySummariesCollection);
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
