import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../error/failures.dart';
import '../domain/local_storage_repository.dart';
import 'models/cache_entry.dart';
import 'models/cache_metadata.dart';

/// Mobile-optimized local storage implementation using Hive
///
/// Optimizations for mobile:
/// - Smaller cache size limits
/// - Aggressive expired entry cleanup
/// - Battery-friendly write strategies
/// - Memory-efficient data structures
class MobileLocalStorageImpl implements LocalStorageRepository {
  // Box names
  static const String _cacheBoxName = 'mobile_cache';
  static const String _metadataBoxName = 'mobile_metadata';
  static const String _collectionsBoxPrefix = 'mobile_collection_';

  // Mobile-specific limits
  static const int _maxCacheEntries = 1000;
  static const int _maxCollectionSize = 500;
  static const Duration _defaultTTL = Duration(hours: 6); // Shorter for mobile
  static const int _maxCacheSizeMB = 50; // 50MB max cache

  Box<Map<dynamic, dynamic>>? _cacheBox;
  Box<Map<dynamic, dynamic>>? _metadataBox;
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

      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final hivePath = '${dir.path}/hive_mobile';

      // Create directory if it doesn't exist
      final hiveDir = Directory(hivePath);
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
      }

      // Initialize Hive
      Hive.init(hivePath);

      // Open boxes (using dynamic maps instead of TypeAdapters)
      _cacheBox = await Hive.openBox<Map>(_cacheBoxName);
      _metadataBox = await Hive.openBox<Map>(_metadataBoxName);

      _isInitialized = true;

      // Clear expired entries on startup
      await clearExpired();

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to initialize mobile storage: $e'));
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
        // Remove oldest entries
        await _evictLRU();
      }

      final entry = CacheEntry.withTTL(
        key: key,
        data: data,
        ttl: ttl ?? _defaultTtl,
      );

      await _cacheBox!.put(key, entry.toJson());
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> load(String key) async {
    try {
      _ensureInitialized();

      final entryMap = _cacheBox!.get(key);
      if (entryMap == null) return const Right(null);

      // Convert Map to CacheEntry
      final entry = CacheEntry.fromJson(
        Map<String, dynamic>.from(entryMap),
      );

      if (entry.isExpired) {
        await _cacheBox!.delete(key);
        return const Right(null);
      }

      // Update access metadata
      entry.markAccessed();
      await _cacheBox!.put(key, entry.toJson());

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

      final entryMap = _cacheBox!.get(key);
      if (entryMap == null) return const Right(false);

      // Convert Map to CacheEntry
      final entry = CacheEntry.fromJson(
        Map<String, dynamic>.from(entryMap),
      );

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

      final entries = <String, Map<dynamic, dynamic>>{};
      for (final entry in items.entries) {
        final cacheEntry = CacheEntry.withTTL(
          key: entry.key,
          data: entry.value,
          ttl: ttl ?? _defaultTtl,
        );
        entries[entry.key] = cacheEntry.toJson();
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
        final entryMap = _cacheBox!.get(key);
        if (entryMap != null) {
          final entry = CacheEntry.fromJson(
            Map<String, dynamic>.from(entryMap),
          );
          if (!entry.isExpired) {
            entry.markAccessed();
            await _cacheBox!.put(key, entry.toJson());
            result[key] = entry.data;
          }
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

      // Limit collection size for mobile
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

      // Save items
      final data = <int, Map<dynamic, dynamic>>{};
      for (var i = 0; i < items.length; i++) {
        data[i] = items[i];
      }
      await box.putAll(data);

      // Update metadata
      final metadata = CacheMetadata(
        collectionName: collectionName,
        itemCount: items.length,
        lastUpdated: DateTime.now(),
        expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
        sizeBytes: _estimateSize(items),
      );
      await _metadataBox!.put(collectionName, metadata.toJson());

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
      final metadataMap = _metadataBox!.get(collectionName);
      if (metadataMap == null) return const Right([]);

      final metadata = CacheMetadata.fromJson(
        Map<String, dynamic>.from(metadataMap),
      );

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
      await _metadataBox!.put(collectionName, metadata.toJson());
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
      for (final metadataMap in _metadataBox!.values) {
        final metadata = CacheMetadata.fromJson(
          Map<String, dynamic>.from(metadataMap),
        );
        totalSize += metadata.sizeBytes;
      }

      return Right({
        'platform': 'mobile',
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
        'platform': 'mobile',
        'platform_os': Platform.operatingSystem,
        'storage_type': 'hive',
        'storage_path': '${dir.path}/hive_mobile',
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
      for (final key in _cacheBox!.keys) {
        final entryMap = _cacheBox!.get(key);
        if (entryMap != null) {
          final entry = CacheEntry.fromJson(
            Map<String, dynamic>.from(entryMap),
          );
          if (entry.isExpired) {
            expiredKeys.add(key.toString());
          }
        }
      }
      await _cacheBox!.deleteAll(expiredKeys);
      count += expiredKeys.length;

      // Clear expired collections
      for (final key in _metadataBox!.keys) {
        final metadataMap = _metadataBox!.get(key);
        if (metadataMap != null) {
          final metadata = CacheMetadata.fromJson(
            Map<String, dynamic>.from(metadataMap),
          );
          if (metadata.isExpired) {
            await deleteCollection(metadata.collectionName);
            count++;
          }
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
    final box = await Hive.openBox<Map>(boxName);
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
    final entries = <CacheEntry>[];

    // Convert all maps to CacheEntry objects
    for (final entryMap in _cacheBox!.values) {
      try {
        final entry = CacheEntry.fromJson(
          Map<String, dynamic>.from(entryMap),
        );
        entries.add(entry);
      } catch (_) {
        // Skip invalid entries
      }
    }

    // Sort by last accessed time
    entries.sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

    // Remove oldest 10%
    final toRemove = (entries.length * 0.1).ceil();
    final keysToRemove = entries.take(toRemove).map((e) => e.key).toList();

    await _cacheBox!.deleteAll(keysToRemove);
  }
}
