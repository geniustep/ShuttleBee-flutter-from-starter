import 'package:dartz/dartz.dart';

import '../../error/failures.dart';
import '../domain/local_storage_repository.dart';

/// Local cache for Search History & Filters
///
/// Provides offline-first caching for:
/// - Recent searches
/// - Saved filters
/// - Favorite searches
class SearchLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _searchHistoryCollection = 'search_history';
  static const String _savedFiltersCollection = 'saved_filters';
  static const String _favoritesCollection = 'favorite_searches';

  // Cache TTL
  static const Duration _searchHistoryTTL = Duration(days: 30);
  // Filters and favorites are permanent (no TTL)

  SearchLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Search History Cache
  // ════════════════════════════════════════════════════════════

  /// Save search query to history
  Future<Either<Failure, bool>> saveSearchHistory({
    required String query,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final historyResult = await getSearchHistory();
      return await historyResult.fold(
        (failure) => Left(failure),
        (history) async {
          // Remove duplicate if exists
          history.removeWhere((item) => item['query'] == query);

          // Add to beginning
          history.insert(0, {
            'query': query,
            'category': category,
            'metadata': metadata,
            'searched_at': DateTime.now().toIso8601String(),
          });

          // Keep only last 50 searches
          if (history.length > 50) {
            history = history.sublist(0, 50);
          }

          final historyJson = history;
          return await _storage.saveCollection(
            collectionName: _searchHistoryCollection,
            items: historyJson,
            ttl: _searchHistoryTTL,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save search: $e'));
    }
  }

  /// Get search history
  Future<Either<Failure, List<Map<String, dynamic>>>> getSearchHistory() async {
    final result = await _storage.loadCollection(_searchHistoryCollection);
    return result.fold(
      (failure) => Left(failure),
      (items) => Right(items),
    );
  }

  /// Clear search history
  Future<Either<Failure, bool>> clearSearchHistory() async {
    try {
      await _storage.deleteCollection(_searchHistoryCollection);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear history: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Saved Filters Cache
  // ════════════════════════════════════════════════════════════

  /// Save a filter
  Future<Either<Failure, bool>> saveFilter({
    required String name,
    required Map<String, dynamic> filter,
    String? category,
  }) async {
    try {
      final filtersResult = await getSavedFilters();
      return await filtersResult.fold(
        (failure) => Left(failure),
        (filters) async {
          // Update or add filter
          final index = filters.indexWhere((f) => f['name'] == name);
          if (index >= 0) {
            filters[index] = {
              'name': name,
              'filter': filter,
              'category': category,
              'saved_at': DateTime.now().toIso8601String(),
            };
          } else {
            filters.add({
              'name': name,
              'filter': filter,
              'category': category,
              'saved_at': DateTime.now().toIso8601String(),
            });
          }

          return await _storage.saveCollection(
            collectionName: _savedFiltersCollection,
            items: filters,
            ttl: null, // Permanent
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save filter: $e'));
    }
  }

  /// Get saved filters
  Future<Either<Failure, List<Map<String, dynamic>>>> getSavedFilters() async {
    final result = await _storage.loadCollection(_savedFiltersCollection);
    return result.fold(
      (failure) => Left(failure),
      (items) => Right(items),
    );
  }

  /// Delete a saved filter
  Future<Either<Failure, bool>> deleteFilter(String filterName) async {
    try {
      final filtersResult = await getSavedFilters();
      return await filtersResult.fold(
        (failure) => Left(failure),
        (filters) async {
          filters.removeWhere((f) => f['name'] == filterName);
          return await _storage.saveCollection(
            collectionName: _savedFiltersCollection,
            items: filters,
            ttl: null,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete filter: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Favorite Searches Cache
  // ════════════════════════════════════════════════════════════

  /// Add to favorites
  Future<Either<Failure, bool>> addFavorite({
    required String query,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final favoritesResult = await getFavorites();
      return await favoritesResult.fold(
        (failure) => Left(failure),
        (favorites) async {
          // Remove if exists
          favorites.removeWhere((item) => item['query'] == query);

          // Add to beginning
          favorites.insert(0, {
            'query': query,
            'category': category,
            'metadata': metadata,
            'favorited_at': DateTime.now().toIso8601String(),
          });

          return await _storage.saveCollection(
            collectionName: _favoritesCollection,
            items: favorites,
            ttl: null, // Permanent
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add favorite: $e'));
    }
  }

  /// Get favorite searches
  Future<Either<Failure, List<Map<String, dynamic>>>> getFavorites() async {
    final result = await _storage.loadCollection(_favoritesCollection);
    return result.fold(
      (failure) => Left(failure),
      (items) => Right(items),
    );
  }

  /// Remove from favorites
  Future<Either<Failure, bool>> removeFavorite(String query) async {
    try {
      final favoritesResult = await getFavorites();
      return await favoritesResult.fold(
        (failure) => Left(failure),
        (favorites) async {
          favorites.removeWhere((item) => item['query'] == query);
          return await _storage.saveCollection(
            collectionName: _favoritesCollection,
            items: favorites,
            ttl: null,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to remove favorite: $e'));
    }
  }

  /// Check if query is favorited
  Future<Either<Failure, bool>> isFavorite(String query) async {
    final favoritesResult = await getFavorites();
    return favoritesResult.fold(
      (failure) => Left(failure),
      (favorites) {
        final isFav = favorites.any((item) => item['query'] == query);
        return Right(isFav);
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all search caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await _storage.deleteCollection(_searchHistoryCollection);
      await _storage.deleteCollection(_savedFiltersCollection);
      await _storage.deleteCollection(_favoritesCollection);
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

