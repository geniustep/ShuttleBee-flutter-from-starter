import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';

/// Local cache for Offline Actions Queue
///
/// Provides offline-first caching for:
/// - Pending actions
/// - Failed syncs
/// - Retry metadata
class OfflineActionsCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _pendingActionsCollection = 'pending_actions';
  static const String _failedSyncsCollection = 'failed_syncs';

  // Cache TTL
  // Actions: Until synced (no TTL)
  static const Duration _failedSyncsTTL = Duration(days: 7);

  OfflineActionsCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Pending Actions Cache
  // ════════════════════════════════════════════════════════════

  /// Add action to pending queue
  Future<Either<Failure, bool>> addPendingAction({
    required String actionId,
    required String actionType, // 'create', 'update', 'delete'
    required String entityType, // 'trip', 'passenger', etc.
    required Map<String, dynamic> data,
    int? retryCount,
    DateTime? createdAt,
  }) async {
    try {
      final actionsResult = await getPendingActions();
      return await actionsResult.fold(
        (failure) => Left(failure),
        (actions) async {
          // Remove if exists (update scenario)
          actions.removeWhere((a) => a['action_id'] == actionId);

          // Add to beginning
          actions.insert(0, {
            'action_id': actionId,
            'action_type': actionType,
            'entity_type': entityType,
            'data': data,
            'retry_count': retryCount ?? 0,
            'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
            'status': 'pending',
          });

          return await _storage.saveCollection(
            collectionName: _pendingActionsCollection,
            items: actions,
            ttl: null, // Until synced
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add action: $e'));
    }
  }

  /// Get all pending actions
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingActions() async {
    return await _storage.loadCollection(_pendingActionsCollection);
  }

  /// Get pending actions by type
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingActionsByType(
    String actionType,
  ) async {
    final actionsResult = await getPendingActions();
    return actionsResult.fold(
      (failure) => Left(failure),
      (actions) {
        final filtered = actions
            .where((a) => a['action_type'] == actionType)
            .toList();
        return Right(filtered);
      },
    );
  }

  /// Get pending actions by entity type
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingActionsByEntity(
    String entityType,
  ) async {
    final actionsResult = await getPendingActions();
    return actionsResult.fold(
      (failure) => Left(failure),
      (actions) {
        final filtered = actions
            .where((a) => a['entity_type'] == entityType)
            .toList();
        return Right(filtered);
      },
    );
  }

  /// Mark action as synced (remove from pending)
  Future<Either<Failure, bool>> markActionAsSynced(String actionId) async {
    try {
      final actionsResult = await getPendingActions();
      return await actionsResult.fold(
        (failure) => Left(failure),
        (actions) async {
          actions.removeWhere((a) => a['action_id'] == actionId);
          return await _storage.saveCollection(
            collectionName: _pendingActionsCollection,
            items: actions,
            ttl: null,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to mark as synced: $e'));
    }
  }

  /// Increment retry count for an action
  Future<Either<Failure, bool>> incrementRetryCount(String actionId) async {
    try {
      final actionsResult = await getPendingActions();
      return await actionsResult.fold(
        (failure) => Left(failure),
        (actions) async {
          final actionIndex = actions.indexWhere(
            (a) => a['action_id'] == actionId,
          );
          if (actionIndex >= 0) {
            final currentRetry = actions[actionIndex]['retry_count'] as int? ?? 0;
            actions[actionIndex]['retry_count'] = currentRetry + 1;
            actions[actionIndex]['last_retry_at'] = DateTime.now().toIso8601String();
          }

          return await _storage.saveCollection(
            collectionName: _pendingActionsCollection,
            items: actions,
            ttl: null,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to increment retry: $e'));
    }
  }

  /// Clear all pending actions
  Future<Either<Failure, bool>> clearPendingActions() async {
    try {
      await _storage.deleteCollection(_pendingActionsCollection);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear actions: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Failed Syncs Cache
  // ════════════════════════════════════════════════════════════

  /// Add failed sync to cache
  Future<Either<Failure, bool>> addFailedSync({
    required String actionId,
    required String error,
    Map<String, dynamic>? actionData,
    int? retryCount,
  }) async {
    try {
      final failedResult = await getFailedSyncs();
      return await failedResult.fold(
        (failure) => Left(failure),
        (failed) async {
          // Remove if exists
          failed.removeWhere((f) => f['action_id'] == actionId);

          // Add to beginning
          failed.insert(0, {
            'action_id': actionId,
            'error': error,
            'action_data': actionData,
            'retry_count': retryCount ?? 0,
            'failed_at': DateTime.now().toIso8601String(),
          });

          return await _storage.saveCollection(
            collectionName: _failedSyncsCollection,
            items: failed,
            ttl: _failedSyncsTTL,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add failed sync: $e'));
    }
  }

  /// Get all failed syncs
  Future<Either<Failure, List<Map<String, dynamic>>>> getFailedSyncs() async {
    return await _storage.loadCollection(_failedSyncsCollection);
  }

  /// Remove failed sync (after successful retry)
  Future<Either<Failure, bool>> removeFailedSync(String actionId) async {
    try {
      final failedResult = await getFailedSyncs();
      return await failedResult.fold(
        (failure) => Left(failure),
        (failed) async {
          failed.removeWhere((f) => f['action_id'] == actionId);
          return await _storage.saveCollection(
            collectionName: _failedSyncsCollection,
            items: failed,
            ttl: _failedSyncsTTL,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to remove failed sync: $e'));
    }
  }

  /// Clear all failed syncs
  Future<Either<Failure, bool>> clearFailedSyncs() async {
    try {
      await _storage.deleteCollection(_failedSyncsCollection);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear failed syncs: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all offline action caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await clearPendingActions();
      await clearFailedSyncs();
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear caches: $e'));
    }
  }

  /// Get cache statistics
  Future<Either<Failure, Map<String, dynamic>>> getCacheStats() async {
    return _storage.getStats();
  }

  /// Get sync statistics
  Future<Either<Failure, Map<String, dynamic>>> getSyncStats() async {
    final pendingResult = await getPendingActions();
    final failedResult = await getFailedSyncs();

    return pendingResult.fold(
      (failure) => Left(failure),
      (pending) async {
        return failedResult.fold(
          (failure) => Left(failure),
          (failed) {
            return Right({
              'pending_count': pending.length,
              'failed_count': failed.length,
              'total': pending.length + failed.length,
            });
          },
        );
      },
    );
  }
}

