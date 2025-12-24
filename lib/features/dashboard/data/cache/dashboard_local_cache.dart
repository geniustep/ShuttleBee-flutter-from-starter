import 'package:bridgecore_flutter_starter/features/dashboard/domain/entities/chart_data.dart';
import 'package:bridgecore_flutter_starter/features/dashboard/domain/entities/kpi.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';

/// Local cache for Dashboard data
///
/// Provides offline-first caching for:
/// - KPI values
/// - Chart data
/// - Last update timestamp
class DashboardLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _kpisKey = 'dashboard_kpis';
  static const String _chartsKey = 'dashboard_charts';
  static const String _lastUpdateKey = 'dashboard_last_update';

  // Cache TTL
  static const Duration _kpisTTL = Duration(minutes: 15);
  static const Duration _chartsTTL = Duration(minutes: 30);

  DashboardLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // KPIs Cache
  // ════════════════════════════════════════════════════════════

  /// Save KPIs to cache
  Future<Either<Failure, bool>> cacheKPIs(List<KPI> kpis) async {
    try {
      final kpisJson = kpis.map((k) => k.toJson()).toList();
      return await _storage.save(
        key: _kpisKey,
        data: {'kpis': kpisJson, 'cached_at': DateTime.now().toIso8601String()},
        ttl: _kpisTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache KPIs: $e'));
    }
  }

  /// Get cached KPIs
  Future<Either<Failure, List<KPI>>> getCachedKPIs() async {
    final result = await _storage.load(_kpisKey);

    return result.fold((failure) => Left(failure), (data) {
      if (data == null) return const Right([]);
      try {
        final kpisJson = data['kpis'] as List<dynamic>? ?? [];
        final kpis = kpisJson
            .map((json) => KPI.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(kpis);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse KPIs: $e'));
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // Charts Cache
  // ════════════════════════════════════════════════════════════

  /// Save chart data to cache
  Future<Either<Failure, bool>> cacheCharts(
    Map<String, ChartData> charts,
  ) async {
    try {
      final chartsJson = charts.map(
        (key, value) => MapEntry(key, value.toJson()),
      );

      return await _storage.save(
        key: _chartsKey,
        data: {
          'charts': chartsJson,
          'cached_at': DateTime.now().toIso8601String(),
        },
        ttl: _chartsTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache charts: $e'));
    }
  }

  /// Get cached chart data
  Future<Either<Failure, Map<String, ChartData>>> getCachedCharts() async {
    final result = await _storage.load(_chartsKey);

    return result.fold((failure) => Left(failure), (data) {
      if (data == null) return const Right({});
      try {
        final chartsJson = data['charts'] as Map<String, dynamic>? ?? {};
        final charts = chartsJson.map(
          (key, value) =>
              MapEntry(key, ChartData.fromJson(value as Map<String, dynamic>)),
        );
        return Right(charts);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse charts: $e'));
      }
    });
  }

  /// Get single chart by key
  Future<Either<Failure, ChartData?>> getCachedChart(String chartKey) async {
    final chartsResult = await getCachedCharts();
    return chartsResult.fold(
      (failure) => Left(failure),
      (charts) => Right(charts[chartKey]),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Last Update Timestamp
  // ════════════════════════════════════════════════════════════

  /// Save last update timestamp
  Future<Either<Failure, bool>> saveLastUpdate(DateTime timestamp) async {
    try {
      return await _storage.save(
        key: _lastUpdateKey,
        data: {'timestamp': timestamp.toIso8601String()},
        ttl: null, // Permanent
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save timestamp: $e'));
    }
  }

  /// Get last update timestamp
  Future<Either<Failure, DateTime?>> getLastUpdate() async {
    final result = await _storage.load(_lastUpdateKey);
    return result.fold((failure) => Left(failure), (data) {
      if (data == null) return const Right(null);
      try {
        final timestampStr = data['timestamp'] as String?;
        if (timestampStr == null) return const Right(null);
        return Right(DateTime.parse(timestampStr));
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse timestamp: $e'));
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all dashboard caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await _storage.delete(_kpisKey);
      await _storage.delete(_chartsKey);
      await _storage.delete(_lastUpdateKey);
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
