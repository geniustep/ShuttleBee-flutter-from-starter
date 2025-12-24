import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../error/failures.dart';
import '../domain/local_storage_repository.dart';
import 'models/cache_entry.dart';
import 'models/cache_metadata.dart';

/// Windows-optimized local storage implementation using Hive
///
/// Optimizations for Windows:
/// - Larger cache size limits
/// - Desktop-optimized write strategies
/// - Better support for larger datasets
/// - File-based persistence optimizations
class WindowsLocalStorageImpl implements LocalStorageRepository {
  // Box names
  static const String _cacheBoxName = 'windows_cache';
  static const String _metadataBoxName = 'windows_metadata';
  static const String _collectionsBoxPrefix = 'windows_collection_';

  // Windows-specific limits (more generous than mobile)
  static const int _maxCacheEntries = 5000;
  static const int _maxCollectionSize = 2000;
  static const Duration _defaultTTL = Duration(hours: 24); // Longer for desktop
  static const int _maxCacheSizeMB = 200; // 200MB max cache

  Box<CacheEntry>? _cacheBox;
  Box<CacheMetadata>? _metadataBox;
  final Map<String, Box<Map<dynamic, dynamic>>> _collectionBoxes = {};

  Duration _defaultTtl = _defaultTTL;
  bool _isInitialized = false;

  // ════════════════════════════════════════════════════════════
  // Initialization
  // ════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, bool>> initialize() async {
    try {
      if (_isInitialized) {
        return const Right(true);
      }

      // Get app data directory (Windows-specific)
      final dir = await getApplicationDocumentsDirectory();
      final hivePath = '${dir.path}\\ShuttleBee\\hive_windows';

      // Create directory if it doesn't exist
      final hiveDir = Directory(hivePath);
      if (!hiveDir.existsSync()) {
        hiveDir.createSync(recursive: true);
      }

      // Initialize Hive
      Hive.init(hivePath);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CacheEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CacheMetadataAdapter());
      }

      // Open boxes with compaction strategy
      _cacheBox = await Hive.openBox<CacheEntry>(
        _cacheBoxName,
        compactionStrategy: (entries, deletedEntries) {
          return deletedEntries > 50; // Compact when 50+ deleted
        },
      );
      _metadataBox = await Hive.openBox<CacheMetadata>(
        _metadataBoxName,
        compactionStrategy: (entries, deletedEntries) {
          return deletedEntries > 10;
        },
      );

      _isInitialized = true;

      // Clear expired entries on startup
      await clearExpired();

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to initialize Windows storage: $e'));
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized || _cacheBox == null || _metadataBox == null) {
      throw CacheException('Storage not initialized. Call initialize() first.');
    }
  }

  // ════════════════════════════════════════════════════════════
  // Generic Cache Operations
  // ════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, bool>> save({
    required String key,
    required Map<String, dynamic> data,
    Duration? ttl,
  }) async {
    try {
      _ensureInitialized();

      // Check cache size limit
      if (_cacheBox!.length >= _maxCacheEntries) {
        await _evictLRU();
      }

      final entry = CacheEntry.withTTL(
        key: key,
        data: data,
        ttl: ttl ?? _defaultTtl,
      );

      await _cacheBox!.put(key, entry);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> load(String key) async {
    try {
      _ensureInitialized();

      final entry = _cacheBox!.get(key);
      if (entry == null) return const Right(null);

      if (entry.isExpired) {
        await _cacheBox!.delete(key);
        return const Right(null);
      }

      // Update access metadata
      entry.markAccessed();

      return Right(entry.data);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> delete(String key) async {
    try {
      _ensureInitialized();
      await _cacheBox!.delete(key);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> has(String key) async {
    try {
      _ensureInitialized();

      final entry = _cacheBox!.get(key);
      if (entry == null) return const Right(false);

      if (entry.isExpired) {
        await _cacheBox!.delete(key);
        return const Right(false);
      }

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to check key: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Batch Operations
  // ════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, bool>> saveBatch({
    required Map<String, Map<String, dynamic>> items,
    Duration? ttl,
  }) async {
    try {
      _ensureInitialized();

      final entries = <String, CacheEntry>{};
      for (final entry in items.entries) {
        entries[entry.key] = CacheEntry.withTTL(
          key: entry.key,
          data: entry.value,
          ttl: ttl ?? _defaultTtl,
        );
      }

      await _cacheBox!.putAll(entries);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save batch: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, Map<String, dynamic>>>> loadBatch(
    List<String> keys,
  ) async {
    try {
      _ensureInitialized();

      final result = <String, Map<String, dynamic>>{};
      for (final key in keys) {
        final entry = _cacheBox!.get(key);
        if (entry != null && !entry.isExpired) {
          entry.markAccessed();
          result[key] = entry.data;
        }
      }

      return Right(result);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load batch: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteBatch(List<String> keys) async {
    try {
      _ensureInitialized();
      await _cacheBox!.deleteAll(keys);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete batch: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Collection Operations
  // ════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, bool>> saveCollection({
    required String collectionName,
    required List<Map<String, dynamic>> items,
    Duration? ttl,
  }) async {
    try {
      _ensureInitialized();

      // Windows can handle larger collections
      if (items.length > _maxCollectionSize) {
        return Left(
          CacheFailure(
            message: 'Collection too large: ${items.length} items '
                '(max: $_maxCollectionSize)',
          ),
        );
      }

      // Open/create collection box
      final box = await _getCollectionBox(collectionName);

      // Clear existing data
      await box.clear();

      // Save items in batches for better performance
      const batchSize = 100;
      for (var i = 0; i < items.length; i += batchSize) {
        final end = (i + batchSize < items.length) ? i + batchSize : items.length;
        final batch = <int, Map<dynamic, dynamic>>{};

        for (var j = i; j < end; j++) {
          batch[j] = items[j];
        }

        await box.putAll(batch);
      }

      // Update metadata
      final metadata = CacheMetadata(
        collectionName: collectionName,
        itemCount: items.length,
        lastUpdated: DateTime.now(),
        expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
        sizeBytes: _estimateSize(items),
      );
      await _metadataBox!.put(collectionName, metadata);

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save collection: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> loadCollection(
    String collectionName,
  ) async {
    try {
      _ensureInitialized();

      // Check metadata
      final metadata = _metadataBox!.get(collectionName);
      if (metadata == null) return const Right([]);

      if (metadata.isExpired) {
        await deleteCollection(collectionName);
        return const Right([]);
      }

      // Load collection
      final box = await _getCollectionBox(collectionName);
      final items = <Map<String, dynamic>>[];

      for (var i = 0; i < box.length; i++) {
        final item = box.get(i);
        if (item != null) {
          items.add(Map<String, dynamic>.from(item));
        }
      }

      metadata.markUpdated();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load collection: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCollection(String collectionName) async {
    try {
      _ensureInitialized();

      final boxName = '$_collectionsBoxPrefix$collectionName';
      if (_collectionBoxes.containsKey(collectionName)) {
        await _collectionBoxes[collectionName]!.clear();
        await _collectionBoxes[collectionName]!.close();
        _collectionBoxes.remove(collectionName);
      }

      await Hive.deleteBoxFromDisk(boxName);
      await _metadataBox!.delete(collectionName);

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete collection: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateCollectionItem({
    required String collectionName,
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    try {
      _ensureInitialized();

      final box = await _getCollectionBox(collectionName);

      // Find item by id
      for (var i = 0; i < box.length; i++) {
        final item = box.get(i);
        if (item != null && item['id']?.toString() == itemId) {
          await box.put(i, data);
          return const Right(true);
        }
      }

      return Left(CacheFailure(message: 'Item not found: $itemId'));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update item: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCollectionItem({
    required String collectionName,
    required String itemId,
  }) async {
    try {
      _ensureInitialized();

      final box = await _getCollectionBox(collectionName);

      // Find and delete item
      for (var i = 0; i < box.length; i++) {
        final item = box.get(i);
        if (item != null && item['id']?.toString() == itemId) {
          await box.delete(i);
          return const Right(true);
        }
      }

      return Left(CacheFailure(message: 'Item not found: $itemId'));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete item: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Query Operations
  // ════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> queryCollection({
    required String collectionName,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      final loadResult = await loadCollection(collectionName);
      return loadResult.fold(
        (failure) => Left(failure),
        (items) {
          var result = items;

          // Apply filters
          if (filters != null && filters.isNotEmpty) {
            result = result.where((item) {
              for (final filter in filters.entries) {
                if (item[filter.key] != filter.value) return false;
              }
              return true;
            }).toList();
          }

          // Apply sorting
          if (sortBy != null) {
            result.sort((a, b) {
              final aVal = a[sortBy];
              final bVal = b[sortBy];
              if (aVal == null && bVal == null) return 0;
              if (aVal == null) return ascending ? -1 : 1;
              if (bVal == null) return ascending ? 1 : -1;

              final comparison = Comparable.compare(
                aVal as Comparable,
                bVal as Comparable,
              );
              return ascending ? comparison : -comparison;
            });
          }

          // Apply offset
          if (offset != null && offset > 0) {
            result = result.skip(offset).toList();
          }

          // Apply limit
          if (limit != null && limit > 0) {
            result = result.take(limit).toList();
          }

          return Right(result);
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to query collection: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Management & Statistics
  // ════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, bool>> close() async {
    try {
      await _cacheBox?.close();
      await _metadataBox?.close();

      for (final box in _collectionBoxes.values) {
        await box.close();
      }
      _collectionBoxes.clear();

      _isInitialized = false;
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to close storage: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> clearAll() async {
    try {
      _ensureInitialized();

      await _cacheBox!.clear();
      await _metadataBox!.clear();

      for (final box in _collectionBoxes.values) {
        await box.clear();
      }

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear all: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStats() async {
    try {
      _ensureInitialized();

      final totalEntries = _cacheBox!.length;
      final totalCollections = _metadataBox!.length;

      var totalSize = 0;
      for (final metadata in _metadataBox!.values) {
        totalSize += metadata.sizeBytes;
      }

      return Right({
        'platform': 'windows',
        'storage_type': 'hive',
        'cache_entries': totalEntries,
        'collections': totalCollections,
        'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'max_entries': _maxCacheEntries,
        'max_collection_size': _maxCollectionSize,
        'max_cache_mb': _maxCacheSizeMB,
        'is_initialized': _isInitialized,
      });
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get stats: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPlatformInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      return Right({
        'platform': 'windows',
        'platform_os': Platform.operatingSystem,
        'storage_type': 'hive',
        'storage_path': '${dir.path}\\ShuttleBee\\hive_windows',
        'max_cache_size_mb': _maxCacheSizeMB,
        'default_ttl_hours': _defaultTtl.inHours,
      });
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get platform info: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    try {
      _ensureInitialized();

      // Check if boxes are open and accessible
      final cacheOk = _cacheBox!.isOpen;
      final metadataOk = _metadataBox!.isOpen;

      return Right(cacheOk && metadataOk);
    } catch (e) {
      return Left(CacheFailure(message: 'Health check failed: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> clearExpired() async {
    try {
      _ensureInitialized();

      var count = 0;

      // Clear expired cache entries
      final expiredKeys = <String>[];
      for (final entry in _cacheBox!.values) {
        if (entry.isExpired) {
          expiredKeys.add(entry.key);
        }
      }
      await _cacheBox!.deleteAll(expiredKeys);
      count += expiredKeys.length;

      // Clear expired collections
      for (final metadata in _metadataBox!.values) {
        if (metadata.isExpired) {
          await deleteCollection(metadata.collectionName);
          count++;
        }
      }

      return Right(count);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear expired: $e'));
    }
  }

  @override
  void setDefaultTTL(Duration ttl) {
    _defaultTtl = ttl;
  }

  @override
  Duration getDefaultTTL() {
    return _defaultTtl;
  }

  // ════════════════════════════════════════════════════════════
  // Helper Methods
  // ════════════════════════════════════════════════════════════

  Future<Box<Map<dynamic, dynamic>>> _getCollectionBox(
    String collectionName,
  ) async {
    if (_collectionBoxes.containsKey(collectionName)) {
      return _collectionBoxes[collectionName]!;
    }

    final boxName = '$_collectionsBoxPrefix$collectionName';
    final box = await Hive.openBox<Map>(
      boxName,
      compactionStrategy: (entries, deletedEntries) {
        return deletedEntries > 20;
      },
    );
    _collectionBoxes[collectionName] = box;
    return box;
  }

  int _estimateSize(List<Map<String, dynamic>> items) {
    try {
      final json = jsonEncode(items);
      return json.length;
    } catch (_) {
      return items.length * 1024; // Rough estimate: 1KB per item
    }
  }

  /// Evict least recently used entries when cache is full
  Future<void> _evictLRU() async {
    final entries = _cacheBox!.values.toList();
    entries.sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

    // Remove oldest 10%
    final toRemove = (entries.length * 0.1).ceil();
    final keysToRemove = entries.take(toRemove).map((e) => e.key).toList();

    await _cacheBox!.deleteAll(keysToRemove);
  }
}
