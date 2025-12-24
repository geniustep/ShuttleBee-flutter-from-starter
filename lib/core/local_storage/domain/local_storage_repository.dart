import 'package:dartz/dartz.dart';
import '../../error/failures.dart';

/// Local Storage Repository Interface
///
/// Defines the contract for platform-specific local storage implementations.
/// Supports offline-first architecture with automatic fallback to cached data.
abstract class LocalStorageRepository {
  // ════════════════════════════════════════════════════════════
  // Initialization & Configuration
  // ════════════════════════════════════════════════════════════

  /// Initialize storage system
  ///
  /// Must be called before any other operation.
  /// Platform-specific implementations may set up:
  /// - Database connections
  /// - File system access
  /// - Cache directories
  Future<Either<Failure, bool>> initialize();

  /// Close storage connections
  ///
  /// Clean up resources when app is closed.
  Future<Either<Failure, bool>> close();

  /// Clear all cached data
  ///
  /// Useful for logout or data reset scenarios.
  Future<Either<Failure, bool>> clearAll();

  /// Get storage statistics
  ///
  /// Returns information about cached data size, count, etc.
  Future<Either<Failure, Map<String, dynamic>>> getStats();

  // ════════════════════════════════════════════════════════════
  // Generic Cache Operations
  // ════════════════════════════════════════════════════════════

  /// Save data to cache
  ///
  /// [key] - Unique identifier for the data
  /// [data] - Data to cache (must be JSON-serializable)
  /// [ttl] - Time to live (optional, null = never expires)
  Future<Either<Failure, bool>> save({
    required String key,
    required Map<String, dynamic> data,
    Duration? ttl,
  });

  /// Load data from cache
  ///
  /// Returns null if key doesn't exist or data expired.
  Future<Either<Failure, Map<String, dynamic>?>> load(String key);

  /// Delete specific cached item
  Future<Either<Failure, bool>> delete(String key);

  /// Check if key exists and is valid (not expired)
  Future<Either<Failure, bool>> has(String key);

  // ════════════════════════════════════════════════════════════
  // Batch Operations
  // ════════════════════════════════════════════════════════════

  /// Save multiple items at once
  ///
  /// More efficient than individual saves for bulk data.
  Future<Either<Failure, bool>> saveBatch({
    required Map<String, Map<String, dynamic>> items,
    Duration? ttl,
  });

  /// Load multiple items at once
  Future<Either<Failure, Map<String, Map<String, dynamic>>>> loadBatch(
    List<String> keys,
  );

  /// Delete multiple items at once
  Future<Either<Failure, bool>> deleteBatch(List<String> keys);

  // ════════════════════════════════════════════════════════════
  // Collection Operations (for lists of entities)
  // ════════════════════════════════════════════════════════════

  /// Save a collection of items
  ///
  /// [collectionName] - Name of the collection (e.g., 'trips', 'passengers')
  /// [items] - List of items to save
  /// [ttl] - Time to live for the entire collection
  Future<Either<Failure, bool>> saveCollection({
    required String collectionName,
    required List<Map<String, dynamic>> items,
    Duration? ttl,
  });

  /// Load a collection of items
  ///
  /// Returns empty list if collection doesn't exist or expired.
  Future<Either<Failure, List<Map<String, dynamic>>>> loadCollection(
    String collectionName,
  );

  /// Delete entire collection
  Future<Either<Failure, bool>> deleteCollection(String collectionName);

  /// Update single item in collection
  ///
  /// [collectionName] - Name of the collection
  /// [itemId] - ID of the item to update
  /// [data] - New data for the item
  Future<Either<Failure, bool>> updateCollectionItem({
    required String collectionName,
    required String itemId,
    required Map<String, dynamic> data,
  });

  /// Delete single item from collection
  Future<Either<Failure, bool>> deleteCollectionItem({
    required String collectionName,
    required String itemId,
  });

  // ════════════════════════════════════════════════════════════
  // Query Operations
  // ════════════════════════════════════════════════════════════

  /// Query collection with filters
  ///
  /// Simple filtering for cached data.
  /// For complex queries, use domain-specific repositories.
  Future<Either<Failure, List<Map<String, dynamic>>>> queryCollection({
    required String collectionName,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool ascending = true,
    int? limit,
    int? offset,
  });

  // ════════════════════════════════════════════════════════════
  // Platform-Specific Metadata
  // ════════════════════════════════════════════════════════════

  /// Get platform-specific storage info
  ///
  /// Returns details about the underlying storage:
  /// - Platform name (mobile/windows)
  /// - Storage type (hive/sqlite/etc)
  /// - Available space
  /// - Cache directory path
  Future<Either<Failure, Map<String, dynamic>>> getPlatformInfo();

  /// Check if storage is available and healthy
  Future<Either<Failure, bool>> healthCheck();

  // ════════════════════════════════════════════════════════════
  // Cache Expiry Management
  // ════════════════════════════════════════════════════════════

  /// Clear all expired entries
  ///
  /// Should be called periodically (e.g., on app startup).
  Future<Either<Failure, int>> clearExpired();

  /// Set default TTL for cached items
  void setDefaultTTL(Duration ttl);

  /// Get default TTL
  Duration getDefaultTTL();
}
