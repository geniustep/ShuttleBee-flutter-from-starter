import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/local_data_source.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/remote_data_source.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';
import 'package:uuid/uuid.dart';

/// Sync manager for offline-first architecture
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final OfflineQueueDataSource _queueDataSource = OfflineQueueDataSource();
  final OdooRemoteDataSource _remoteDataSource = OdooRemoteDataSource();
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize sync manager
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final hasConnection = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet
        );

        if (hasConnection && !_isSyncing) {
          syncPendingOperations();
        }
      },
    );
  }

  /// Add operation to offline queue
  Future<String> addOperation({
    required String type,
    required String model,
    required Map<String, dynamic> data,
  }) async {
    final operationId = const Uuid().v4();
    final operation = {
      'id': operationId,
      'type': type,
      'model': model,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
    };

    await _queueDataSource.enqueue(operation);
    AppLogger.info('Operation $operationId added to queue');

    // Try to sync immediately if online
    final connectivityResults = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResults.any((result) =>
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );

    if (hasConnection) {
      syncPendingOperations();
    }

    return operationId;
  }

  /// Sync all pending operations
  Future<void> syncPendingOperations() async {
    if (_isSyncing) {
      AppLogger.warning('Sync already in progress');
      return;
    }

    _isSyncing = true;
    AppLogger.info('Starting sync...');

    try {
      final operations = await _queueDataSource.getPendingOperations();
      AppLogger.info('Found ${operations.length} pending operations');

      for (final operation in operations) {
        try {
          await _executeOperation(operation);
          await _queueDataSource.dequeue(operation['id']);
          AppLogger.info('Operation ${operation['id']} synced successfully');
        } catch (e) {
          AppLogger.error('Failed to sync operation ${operation['id']}: $e');
          // Update retry count
          operation['retry_count'] = (operation['retry_count'] ?? 0) + 1;

          if (operation['retry_count'] >= 3) {
            AppLogger.error(
              'Operation ${operation['id']} failed after 3 retries',
            );
            operation['status'] = 'failed';
          }
        }
      }

      _lastSyncTime = DateTime.now();
      AppLogger.info('Sync completed successfully');
    } catch (e) {
      AppLogger.error('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a single operation
  Future<void> _executeOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final model = operation['model'] as String;
    final data = operation['data'] as Map<String, dynamic>;

    switch (type) {
      case 'create':
        await _remoteDataSource.create(
          model: model,
          values: data,
        );
        break;

      case 'update':
        final ids = data['ids'] as List<int>;
        final values = data['values'] as Map<String, dynamic>;
        await _remoteDataSource.update(
          model: model,
          ids: ids,
          values: values,
        );
        break;

      case 'delete':
        final ids = data['ids'] as List<int>;
        await _remoteDataSource.delete(
          model: model,
          ids: ids,
        );
        break;

      default:
        throw UnsupportedError('Operation type $type not supported');
    }
  }

  /// Get pending operations count
  Future<int> getPendingCount() async {
    return await _queueDataSource.getQueueSize();
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if syncing
  bool get isSyncing => _isSyncing;

  /// Clear all pending operations
  Future<void> clearQueue() async {
    await _queueDataSource.clearQueue();
    AppLogger.info('Queue cleared');
  }

  /// Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Conflict resolution strategy
enum ConflictResolution {
  serverWins,
  clientWins,
  merge,
  manual,
}

/// Conflict resolver
class ConflictResolver {
  /// Resolve conflict between local and remote data
  Map<String, dynamic> resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required ConflictResolution strategy,
  }) {
    switch (strategy) {
      case ConflictResolution.serverWins:
        return remoteData;

      case ConflictResolution.clientWins:
        return localData;

      case ConflictResolution.merge:
        return _merge(localData, remoteData);

      case ConflictResolution.manual:
        // This would typically show a UI for user to resolve
        throw UnimplementedError('Manual resolution not implemented');
    }
  }

  /// Merge local and remote data
  Map<String, dynamic> _merge(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = <String, dynamic>{...remote};

    // Merge strategy: prefer newer values based on timestamp
    local.forEach((key, value) {
      if (!merged.containsKey(key)) {
        merged[key] = value;
      } else {
        // Custom merge logic can be added here
        // For now, prefer remote values
      }
    });

    return merged;
  }

  /// Detect conflicts
  List<String> detectConflicts(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final conflicts = <String>[];

    local.forEach((key, value) {
      if (remote.containsKey(key) && remote[key] != value) {
        conflicts.add(key);
      }
    });

    return conflicts;
  }
}
