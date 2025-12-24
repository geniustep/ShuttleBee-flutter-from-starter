import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';

/// Local cache for Notifications
///
/// Provides offline-first caching for:
/// - Unread notifications
/// - Notification history
/// - Notification preferences
class NotificationLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _unreadCollection = 'unread_notifications';
  static const String _historyCollection = 'notification_history';
  static const String _preferencesKey = 'notification_preferences';

  // Cache TTL
  static const Duration _historyTTL = Duration(days: 90);
  // Unread and preferences are permanent (until read/updated)

  NotificationLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Unread Notifications Cache
  // ════════════════════════════════════════════════════════════

  /// Save unread notifications
  Future<Either<Failure, bool>> cacheUnreadNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    try {
      return await _storage.saveCollection(
        collectionName: _unreadCollection,
        items: notifications,
        ttl: null, // Permanent until read
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache unread: $e'));
    }
  }

  /// Get unread notifications
  Future<Either<Failure, List<Map<String, dynamic>>>> getUnreadNotifications() async {
    return await _storage.loadCollection(_unreadCollection);
  }

  /// Mark notification as read
  Future<Either<Failure, bool>> markAsRead(String notificationId) async {
    try {
      final unreadResult = await getUnreadNotifications();
      return await unreadResult.fold(
        (failure) => Left(failure),
        (unread) async {
          // Remove from unread
          unread.removeWhere((n) => n['id']?.toString() == notificationId);

          // Add to history
          final removed = unread.firstWhere(
            (n) => n['id']?.toString() == notificationId,
            orElse: () => {},
          );
          if (removed.isNotEmpty) {
            await addToHistory(removed);
          }

          return await _storage.saveCollection(
            collectionName: _unreadCollection,
            items: unread,
            ttl: null,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to mark as read: $e'));
    }
  }

  /// Mark all as read
  Future<Either<Failure, bool>> markAllAsRead() async {
    try {
      final unreadResult = await getUnreadNotifications();
      return await unreadResult.fold(
        (failure) => Left(failure),
        (unread) async {
          // Add all to history
          if (unread.isNotEmpty) {
            await addToHistoryBatch(unread);
          }

          // Clear unread
          await _storage.deleteCollection(_unreadCollection);
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to mark all as read: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Notification History Cache
  // ════════════════════════════════════════════════════════════

  /// Add notification to history
  Future<Either<Failure, bool>> addToHistory(
    Map<String, dynamic> notification,
  ) async {
    try {
      final historyResult = await getHistory();
      return await historyResult.fold(
        (failure) => Left(failure),
        (history) async {
          // Remove duplicate if exists
          history.removeWhere((n) => n['id'] == notification['id']);

          // Add to beginning
          history.insert(0, {
            ...notification,
            'read_at': DateTime.now().toIso8601String(),
          });

          // Keep only last 500 notifications
          if (history.length > 500) {
            history = history.sublist(0, 500);
          }

          return await _storage.saveCollection(
            collectionName: _historyCollection,
            items: history,
            ttl: _historyTTL,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add to history: $e'));
    }
  }

  /// Add multiple notifications to history
  Future<Either<Failure, bool>> addToHistoryBatch(
    List<Map<String, dynamic>> notifications,
  ) async {
    try {
      final historyResult = await getHistory();
      return await historyResult.fold(
        (failure) => Left(failure),
        (history) async {
          for (final notification in notifications) {
            history.removeWhere((n) => n['id'] == notification['id']);
            history.insert(0, {
              ...notification,
              'read_at': DateTime.now().toIso8601String(),
            });
          }

          // Keep only last 500
          if (history.length > 500) {
            history = history.sublist(0, 500);
          }

          return await _storage.saveCollection(
            collectionName: _historyCollection,
            items: history,
            ttl: _historyTTL,
          );
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add batch to history: $e'));
    }
  }

  /// Get notification history
  Future<Either<Failure, List<Map<String, dynamic>>>> getHistory() async {
    return await _storage.loadCollection(_historyCollection);
  }

  /// Clear history
  Future<Either<Failure, bool>> clearHistory() async {
    try {
      await _storage.deleteCollection(_historyCollection);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear history: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Notification Preferences Cache
  // ════════════════════════════════════════════════════════════

  /// Save notification preferences
  Future<Either<Failure, bool>> savePreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      return await _storage.save(
        key: _preferencesKey,
        data: {
          ...preferences,
          'updated_at': DateTime.now().toIso8601String(),
        },
        ttl: null, // Permanent
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save preferences: $e'));
    }
  }

  /// Get notification preferences
  Future<Either<Failure, Map<String, dynamic>?>> getPreferences() async {
    final result = await _storage.load(_preferencesKey);
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data),
    );
  }

  /// Update single preference
  Future<Either<Failure, bool>> updatePreference(
    String key,
    dynamic value,
  ) async {
    try {
      final prefsResult = await getPreferences();
      return await prefsResult.fold(
        (failure) => Left(failure),
        (prefs) async {
          final updatedPrefs = {
            ...?prefs,
            key: value,
            'updated_at': DateTime.now().toIso8601String(),
          };
          return await savePreferences(updatedPrefs);
        },
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update preference: $e'));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all notification caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await _storage.deleteCollection(_unreadCollection);
      await _storage.deleteCollection(_historyCollection);
      await _storage.delete(_preferencesKey);
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

