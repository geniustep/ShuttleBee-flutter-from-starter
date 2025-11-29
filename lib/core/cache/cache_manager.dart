import 'dart:async';
import 'dart:collection';
import 'package:bridgecore_flutter_starter/core/data/datasources/local_data_source.dart';

/// Multi-layer cache manager with memory and disk caching
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final CacheDataSource _diskCache = CacheDataSource();
  final _memoryCache = <String, _CacheEntry>{};
  final _lruQueue = Queue<String>();
  static const int _maxMemoryItems = 100;

  /// Get from cache (checks memory first, then disk)
  Future<T?> get<T>(
    String key, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      await invalidate(key);
      return null;
    }

    // Try memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired) {
        _updateLRU(key);
        return entry.data as T?;
      } else {
        _memoryCache.remove(key);
      }
    }

    // Try disk cache
    final diskData = await _diskCache.get<T>(key);
    if (diskData != null) {
      // Store in memory cache for faster access
      _setMemory(key, diskData, const Duration(minutes: 5));
    }

    return diskData;
  }

  /// Save to both memory and disk cache
  Future<void> set(
    String key,
    dynamic data, {
    Duration? memoryTTL,
    Duration? diskTTL,
  }) async {
    // Save to memory cache
    _setMemory(key, data, memoryTTL ?? const Duration(minutes: 5));

    // Save to disk cache
    await _diskCache.save(
      key: key,
      data: data,
      ttl: diskTTL ?? const Duration(hours: 1),
    );
  }

  /// Set only in memory cache
  void _setMemory(String key, dynamic data, Duration ttl) {
    if (_memoryCache.length >= _maxMemoryItems) {
      _evictLRU();
    }

    _memoryCache[key] = _CacheEntry(
      data: data,
      expiryTime: DateTime.now().add(ttl),
    );
    _updateLRU(key);
  }

  /// Update LRU queue
  void _updateLRU(String key) {
    _lruQueue.remove(key);
    _lruQueue.addLast(key);
  }

  /// Evict least recently used item
  void _evictLRU() {
    if (_lruQueue.isNotEmpty) {
      final key = _lruQueue.removeFirst();
      _memoryCache.remove(key);
    }
  }

  /// Invalidate cache for a key
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    _lruQueue.remove(key);
    await _diskCache.delete(key);
  }

  /// Invalidate cache by pattern
  Future<void> invalidatePattern(String pattern) async {
    final regex = RegExp(pattern);

    // Clear from memory
    _memoryCache.removeWhere((key, _) => regex.hasMatch(key));
    _lruQueue.removeWhere((key) => regex.hasMatch(key));

    // Note: For disk, you'd need to list all keys and match
    // This is a simplified implementation
  }

  /// Clear all caches
  Future<void> clearAll() async {
    _memoryCache.clear();
    _lruQueue.clear();
    await _diskCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'memory_items': _memoryCache.length,
      'max_memory_items': _maxMemoryItems,
      'memory_usage_percent':
          (_memoryCache.length / _maxMemoryItems * 100).toStringAsFixed(2),
    };
  }

  /// Prefetch data and cache it
  Future<T?> prefetch<T>(
    String key,
    Future<T> Function() fetchFunction, {
    Duration? memoryTTL,
    Duration? diskTTL,
    bool force = false,
  }) async {
    if (!force) {
      final cached = await get<T>(key);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final data = await fetchFunction();
      await set(key, data, memoryTTL: memoryTTL, diskTTL: diskTTL);
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Smart prefetch multiple items
  Future<void> prefetchBatch(
    Map<String, Future<dynamic> Function()> items, {
    Duration? ttl,
  }) async {
    await Future.wait(
      items.entries.map((entry) => prefetch(
            entry.key,
            entry.value,
            memoryTTL: ttl,
            diskTTL: ttl,
          )),
    );
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  _CacheEntry({
    required this.data,
    required this.expiryTime,
  });

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
