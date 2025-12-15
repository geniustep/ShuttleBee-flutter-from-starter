import 'package:hive_flutter/hive_flutter.dart';
import 'package:bridgecore_flutter_starter/core/error/failures.dart';

/// Base local data source
abstract class LocalDataSource {
  /// Execute a local call with error handling
  Future<T> execute<T>(
    Future<T> Function() call, {
    String? errorMessage,
  }) async {
    try {
      return await call();
    } catch (e) {
      throw CacheException(errorMessage ?? e.toString());
    }
  }

  T executeSync<T>(
    T Function() call, {
    String? errorMessage,
  }) {
    try {
      return call();
    } catch (e) {
      throw CacheException(errorMessage ?? e.toString());
    }
  }
}

/// Cache data source using Hive
class CacheDataSource extends LocalDataSource {
  static const String _cacheBox = 'cache_box';
  static const String _metadataBox = 'metadata_box';

  Future<Box> _getCacheBox() async {
    return await Hive.openBox(_cacheBox);
  }

  Future<Box> _getMetadataBox() async {
    return await Hive.openBox(_metadataBox);
  }

  /// Save data to cache with TTL
  Future<void> save({
    required String key,
    required dynamic data,
    Duration? ttl,
  }) async {
    return execute(
      () async {
        final box = await _getCacheBox();
        final metadataBox = await _getMetadataBox();

        await box.put(key, data);

        if (ttl != null) {
          final expiryTime = DateTime.now().add(ttl).millisecondsSinceEpoch;
          await metadataBox.put('${key}_expiry', expiryTime);
        }
      },
      errorMessage: 'Failed to save data to cache',
    );
  }

  /// Get data from cache
  Future<T?> get<T>(String key) async {
    return execute(
      () async {
        final box = await _getCacheBox();
        final metadataBox = await _getMetadataBox();

        // Check if data exists
        if (!box.containsKey(key)) {
          return null;
        }

        // Check if data has expired
        final expiryKey = '${key}_expiry';
        if (metadataBox.containsKey(expiryKey)) {
          final expiryTime = metadataBox.get(expiryKey) as int;
          if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
            await box.delete(key);
            await metadataBox.delete(expiryKey);
            return null;
          }
        }

        return box.get(key) as T?;
      },
      errorMessage: 'Failed to get data from cache',
    );
  }

  /// Delete data from cache
  Future<void> delete(String key) async {
    return execute(
      () async {
        final box = await _getCacheBox();
        final metadataBox = await _getMetadataBox();

        await box.delete(key);
        await metadataBox.delete('${key}_expiry');
      },
      errorMessage: 'Failed to delete data from cache',
    );
  }

  /// Clear all cache
  Future<void> clear() async {
    return execute(
      () async {
        final box = await _getCacheBox();
        final metadataBox = await _getMetadataBox();

        await box.clear();
        await metadataBox.clear();
      },
      errorMessage: 'Failed to clear cache',
    );
  }

  /// Check if key exists and is not expired
  Future<bool> exists(String key) async {
    return execute(
      () async {
        final data = await get<dynamic>(key);
        return data != null;
      },
      errorMessage: 'Failed to check if key exists',
    );
  }
}

/// Offline queue data source
class OfflineQueueDataSource extends LocalDataSource {
  static const String _queueBox = 'offline_queue_box';

  Future<Box> _getQueueBox() async {
    return await Hive.openBox(_queueBox);
  }

  /// Add operation to offline queue
  Future<void> enqueue(Map<String, dynamic> operation) async {
    return execute(
      () async {
        final box = await _getQueueBox();
        final queue = box.get('queue', defaultValue: <Map<String, dynamic>>[])
            as List<dynamic>;
        queue.add(operation);
        await box.put('queue', queue);
      },
      errorMessage: 'Failed to enqueue operation',
    );
  }

  /// Get all pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    return execute(
      () async {
        final box = await _getQueueBox();
        final queue = box.get('queue', defaultValue: <Map<String, dynamic>>[])
            as List<dynamic>;
        return queue.cast<Map<String, dynamic>>();
      },
      errorMessage: 'Failed to get pending operations',
    );
  }

  /// Remove operation from queue
  Future<void> dequeue(String operationId) async {
    return execute(
      () async {
        final box = await _getQueueBox();
        final queue = box.get('queue', defaultValue: <Map<String, dynamic>>[])
            as List<dynamic>;
        queue.removeWhere((op) => op['id'] == operationId);
        await box.put('queue', queue);
      },
      errorMessage: 'Failed to dequeue operation',
    );
  }

  /// Clear all pending operations
  Future<void> clearQueue() async {
    return execute(
      () async {
        final box = await _getQueueBox();
        await box.delete('queue');
      },
      errorMessage: 'Failed to clear queue',
    );
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    return execute(
      () async {
        final operations = await getPendingOperations();
        return operations.length;
      },
      errorMessage: 'Failed to get queue size',
    );
  }
}
