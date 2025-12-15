import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../../../core/enums/enums.dart';
import '../../domain/entities/trip.dart';

/// 🚌 ShuttleBee Trip Cache Service
/// خدمة تخزين الرحلات محلياً للعمل بدون إنترنت
///
/// Features:
/// ✅ تخزين الرحلات محلياً باستخدام Hive
/// ✅ تحديثات متفائلة (Optimistic Updates)
/// ✅ دعم العمل بدون إنترنت
/// ✅ مزامنة تلقائية عند الاتصال
/// ✅ TTL للكاش مع تحديث ذكي
class TripCacheService {
  static final Logger _logger = Logger();

  // Box names
  static const String _tripsBoxName = 'trips_cache';
  static const String _tripLinesBoxName = 'trip_lines_cache';
  static const String _metadataBoxName = 'trips_metadata';
  static const String _pendingActionsBoxName = 'pending_actions';

  // Singleton
  static TripCacheService? _instance;
  static TripCacheService get instance {
    _instance ??= TripCacheService._();
    return _instance!;
  }

  TripCacheService._();

  // Boxes
  Box<String>? _tripsBox;
  Box<String>? _tripLinesBox;
  Box<dynamic>? _metadataBox;
  Box<Map>? _pendingActionsBox;

  bool _isInitialized = false;

  /// Initialize cache service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _tripsBox = await Hive.openBox<String>(_tripsBoxName);
      _tripLinesBox = await Hive.openBox<String>(_tripLinesBoxName);
      _metadataBox = await Hive.openBox<dynamic>(_metadataBoxName);
      _pendingActionsBox = await Hive.openBox<Map>(_pendingActionsBoxName);

      _isInitialized = true;
      _logger.d('✅ TripCacheService initialized');
    } catch (e) {
      _logger.e('❌ Failed to initialize TripCacheService', error: e);
      rethrow;
    }
  }

  /// Ensure initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await init();
  }

  // ============================================================
  // 📦 TRIP CACHING
  // ============================================================

  /// Cache a single trip
  Future<void> cacheTrip(Trip trip) async {
    await _ensureInitialized();
    try {
      final tripJson = jsonEncode(trip.toJson());
      await _tripsBox!.put('trip_${trip.id}', tripJson);

      // Update metadata
      await _metadataBox!.put(
        'trip_${trip.id}_cached_at',
        DateTime.now().millisecondsSinceEpoch,
      );

      _logger.d('📦 Cached trip ${trip.id}: ${trip.name}');
    } catch (e) {
      _logger.e('❌ Failed to cache trip ${trip.id}', error: e);
    }
  }

  /// Cache multiple trips
  Future<void> cacheTrips(List<Trip> trips, {String? cacheKey}) async {
    await _ensureInitialized();
    try {
      // Cache individual trips
      for (final trip in trips) {
        await cacheTrip(trip);
      }

      // If a cache key is provided, store the list of trip IDs
      if (cacheKey != null) {
        final tripIds = trips.map((t) => t.id).toList();
        await _metadataBox!.put(cacheKey, tripIds);
        await _metadataBox!.put(
          '${cacheKey}_cached_at',
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      _logger.d(
          '📦 Cached ${trips.length} trips${cacheKey != null ? ' with key: $cacheKey' : ''}');
    } catch (e) {
      _logger.e('❌ Failed to cache trips', error: e);
    }
  }

  /// Get cached trip by ID
  Future<Trip?> getCachedTrip(int tripId) async {
    await _ensureInitialized();
    try {
      final tripJson = _tripsBox!.get('trip_$tripId');
      if (tripJson == null) return null;

      final tripMap = jsonDecode(tripJson) as Map<String, dynamic>;
      return Trip.fromJson(tripMap);
    } catch (e) {
      _logger.e('❌ Failed to get cached trip $tripId', error: e);
      return null;
    }
  }

  /// Get cached trips by cache key
  Future<List<Trip>> getCachedTrips(String cacheKey) async {
    await _ensureInitialized();
    try {
      final tripIds = _metadataBox!.get(cacheKey) as List<dynamic>?;
      if (tripIds == null) return [];

      final trips = <Trip>[];
      for (final id in tripIds) {
        final trip = await getCachedTrip(id as int);
        if (trip != null) {
          trips.add(trip);
        }
      }

      _logger.d('📦 Retrieved ${trips.length} cached trips for key: $cacheKey');
      return trips;
    } catch (e) {
      _logger.e('❌ Failed to get cached trips for key: $cacheKey', error: e);
      return [];
    }
  }

  /// Check if cache is valid (not expired)
  Future<bool> isCacheValid(String cacheKey,
      {Duration maxAge = const Duration(minutes: 30)}) async {
    await _ensureInitialized();
    try {
      final cachedAt = _metadataBox!.get('${cacheKey}_cached_at') as int?;
      if (cachedAt == null) return false;

      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      return age < maxAge.inMilliseconds;
    } catch (e) {
      return false;
    }
  }

  /// Get cache age
  Future<Duration?> getCacheAge(String cacheKey) async {
    await _ensureInitialized();
    try {
      final cachedAt = _metadataBox!.get('${cacheKey}_cached_at') as int?;
      if (cachedAt == null) return null;

      return Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - cachedAt,
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // 🔄 OPTIMISTIC UPDATES
  // ============================================================

  /// Apply optimistic update to a trip line
  Future<Trip?> applyOptimisticLineUpdate({
    required int tripId,
    required int lineId,
    required String newStatus,
  }) async {
    await _ensureInitialized();
    try {
      final trip = await getCachedTrip(tripId);
      if (trip == null) return null;

      // Find and update the line
      final updatedLines = trip.lines.map((line) {
        if (line.id == lineId) {
          return line.copyWithStatus(newStatus);
        }
        return line;
      }).toList();

      // Calculate new counts
      int boardedCount = 0;
      int droppedCount = 0;
      int absentCount = 0;

      for (final line in updatedLines) {
        switch (line.status.value) {
          case 'boarded':
            boardedCount++;
            break;
          case 'dropped':
            droppedCount++;
            break;
          case 'absent':
            absentCount++;
            break;
        }
      }

      // Create updated trip
      final updatedTrip = trip.copyWith(
        lines: updatedLines,
        boardedCount: boardedCount,
        droppedCount: droppedCount,
        absentCount: absentCount,
      );

      // Save to cache
      await cacheTrip(updatedTrip);

      _logger.d(
          '🔄 Applied optimistic update: trip $tripId, line $lineId -> $newStatus');
      return updatedTrip;
    } catch (e) {
      _logger.e('❌ Failed to apply optimistic update', error: e);
      return null;
    }
  }

  /// Apply optimistic trip state update
  Future<Trip?> applyOptimisticTripStateUpdate({
    required int tripId,
    required String newState,
  }) async {
    await _ensureInitialized();
    try {
      final trip = await getCachedTrip(tripId);
      if (trip == null) return null;

      final updatedTrip = trip.copyWithState(newState);
      await cacheTrip(updatedTrip);

      _logger.d(
          '🔄 Applied optimistic trip state update: trip $tripId -> $newState');
      return updatedTrip;
    } catch (e) {
      _logger.e('❌ Failed to apply optimistic trip state update', error: e);
      return null;
    }
  }

  // ============================================================
  // 📤 PENDING ACTIONS (Offline Support)
  // ============================================================

  /// Add pending action for offline sync
  Future<void> addPendingAction({
    required String actionType,
    required int tripId,
    int? lineId,
    Map<String, dynamic>? data,
  }) async {
    await _ensureInitialized();
    try {
      final actionId =
          '${DateTime.now().millisecondsSinceEpoch}_${tripId}_$lineId';
      final action = {
        'id': actionId,
        'type': actionType,
        'tripId': tripId,
        'lineId': lineId,
        'data': data,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'retryCount': 0,
      };

      await _pendingActionsBox!.put(actionId, action);
      _logger.d('📤 Added pending action: $actionType for trip $tripId');
    } catch (e) {
      _logger.e('❌ Failed to add pending action', error: e);
    }
  }

  /// Get all pending actions
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    await _ensureInitialized();
    try {
      final actions = _pendingActionsBox!.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Sort by creation time
      actions.sort(
        (a, b) => (a['createdAt'] as int).compareTo(b['createdAt'] as int),
      );

      return actions;
    } catch (e) {
      _logger.e('❌ Failed to get pending actions', error: e);
      return [];
    }
  }

  /// Remove pending action
  Future<void> removePendingAction(String actionId) async {
    await _ensureInitialized();
    try {
      await _pendingActionsBox!.delete(actionId);
      _logger.d('✅ Removed pending action: $actionId');
    } catch (e) {
      _logger.e('❌ Failed to remove pending action', error: e);
    }
  }

  /// Update pending action retry count
  Future<void> incrementRetryCount(String actionId) async {
    await _ensureInitialized();
    try {
      final action = _pendingActionsBox!.get(actionId);
      if (action != null) {
        action['retryCount'] = (action['retryCount'] as int) + 1;
        await _pendingActionsBox!.put(actionId, action);
      }
    } catch (e) {
      _logger.e('❌ Failed to increment retry count', error: e);
    }
  }

  /// Check if there are pending actions
  Future<bool> hasPendingActions() async {
    await _ensureInitialized();
    return _pendingActionsBox!.isNotEmpty;
  }

  /// Get pending actions count
  Future<int> getPendingActionsCount() async {
    await _ensureInitialized();
    return _pendingActionsBox!.length;
  }

  // ============================================================
  // 🧹 CLEANUP
  // ============================================================

  /// Clear trip cache
  Future<void> clearTripCache(int tripId) async {
    await _ensureInitialized();
    try {
      await _tripsBox!.delete('trip_$tripId');
      await _metadataBox!.delete('trip_${tripId}_cached_at');
      _logger.d('🧹 Cleared cache for trip $tripId');
    } catch (e) {
      _logger.e('❌ Failed to clear trip cache', error: e);
    }
  }

  /// Clear all trip caches
  Future<void> clearAllCaches() async {
    await _ensureInitialized();
    try {
      await _tripsBox!.clear();
      await _tripLinesBox!.clear();
      await _metadataBox!.clear();
      _logger.d('🧹 Cleared all trip caches');
    } catch (e) {
      _logger.e('❌ Failed to clear all caches', error: e);
    }
  }

  /// Clear pending actions
  Future<void> clearPendingActions() async {
    await _ensureInitialized();
    try {
      await _pendingActionsBox!.clear();
      _logger.d('🧹 Cleared all pending actions');
    } catch (e) {
      _logger.e('❌ Failed to clear pending actions', error: e);
    }
  }

  /// Close all boxes
  Future<void> close() async {
    try {
      await _tripsBox?.close();
      await _tripLinesBox?.close();
      await _metadataBox?.close();
      await _pendingActionsBox?.close();
      _isInitialized = false;
      _logger.d('✅ TripCacheService closed');
    } catch (e) {
      _logger.e('❌ Failed to close TripCacheService', error: e);
    }
  }
}

/// Extension to add copyWithStatus to TripLine
extension TripLineCacheExtension on TripLine {
  TripLine copyWithStatus(String newStatus) {
    return copyWith(
      status: TripLineStatus.fromString(newStatus),
    );
  }
}

/// Extension to add copyWithState to Trip
extension TripCacheExtension on Trip {
  Trip copyWithState(String newState) {
    return copyWith(
      state: TripState.fromString(newState),
    );
  }
}
