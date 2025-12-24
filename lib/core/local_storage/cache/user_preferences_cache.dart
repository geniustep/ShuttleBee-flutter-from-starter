import 'package:dartz/dartz.dart';

import '../../error/failures.dart';
import '../domain/local_storage_repository.dart';

/// Local cache for User Preferences & Settings
///
/// Provides permanent storage for:
/// - Theme preferences
/// - Language settings
/// - Display preferences
/// - Notification settings
class UserPreferencesCache {
  final LocalStorageRepository _storage;

  // Keys
  static const String _themeKey = 'user_theme';
  static const String _languageKey = 'user_language';
  static const String _displayKey = 'user_display';
  static const String _notificationsKey = 'user_notifications';
  static const String _allPreferencesKey = 'user_all_preferences';

  // All preferences are permanent (no TTL)

  UserPreferencesCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Theme Preferences
  // ════════════════════════════════════════════════════════════

  /// Save theme preference
  Future<Either<Failure, bool>> saveTheme({
    required String themeMode, // 'light', 'dark', 'system'
    int? primaryColor,
    bool? useMaterial3,
  }) async {
    try {
      return await _storage.save(
        key: _themeKey,
        data: {
          'theme_mode': themeMode,
          'primary_color': primaryColor,
          'use_material3': useMaterial3,
          'updated_at': DateTime.now().toIso8601String(),
        },
        ttl: null, // Permanent
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save theme: $e'));
    }
  }

  /// Get theme preference
  Future<Either<Failure, Map<String, dynamic>?>> getTheme() async {
    final result = await _storage.load(_themeKey);
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Language Settings
  // ════════════════════════════════════════════════════════════

  /// Save language preference
  Future<Either<Failure, bool>> saveLanguage({
    required String languageCode,
    String? countryCode,
  }) async {
    try {
      return await _storage.save(
        key: _languageKey,
        data: {
          'language_code': languageCode,
          'country_code': countryCode,
          'updated_at': DateTime.now().toIso8601String(),
        },
        ttl: null, // Permanent
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save language: $e'));
    }
  }

  /// Get language preference
  Future<Either<Failure, Map<String, dynamic>?>> getLanguage() async {
    final result = await _storage.load(_languageKey);
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Display Preferences
  // ════════════════════════════════════════════════════════════

  /// Save display preferences
  Future<Either<Failure, bool>> saveDisplayPreferences({
    double? textScale,
    bool? showAnimations,
    bool? reduceMotion,
    String? fontSize, // 'small', 'medium', 'large'
  }) async {
    try {
      return await _storage.save(
        key: _displayKey,
        data: {
          'text_scale': textScale,
          'show_animations': showAnimations,
          'reduce_motion': reduceMotion,
          'font_size': fontSize,
          'updated_at': DateTime.now().toIso8601String(),
        },
        ttl: null, // Permanent
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save display: $e'));
    }
  }

  /// Get display preferences
  Future<Either<Failure, Map<String, dynamic>?>> getDisplayPreferences() async {
    final result = await _storage.load(_displayKey);
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Notification Settings
  // ════════════════════════════════════════════════════════════

  /// Save notification preferences
  Future<Either<Failure, bool>> saveNotificationPreferences({
    bool? enabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    List<String>? enabledCategories,
  }) async {
    try {
      return await _storage.save(
        key: _notificationsKey,
        data: {
          'enabled': enabled,
          'sound_enabled': soundEnabled,
          'vibration_enabled': vibrationEnabled,
          'enabled_categories': enabledCategories,
          'updated_at': DateTime.now().toIso8601String(),
        },
        ttl: null, // Permanent
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save notifications: $e'));
    }
  }

  /// Get notification preferences
  Future<Either<Failure, Map<String, dynamic>?>> getNotificationPreferences() async {
    final result = await _storage.load(_notificationsKey);
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data),
    );
  }

  // ════════════════════════════════════════════════════════════
  // All Preferences (Combined)
  // ════════════════════════════════════════════════════════════

  /// Save all preferences at once
  Future<Either<Failure, bool>> saveAllPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      return await _storage.save(
        key: _allPreferencesKey,
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

  /// Get all preferences
  Future<Either<Failure, Map<String, dynamic>?>> getAllPreferences() async {
    final result = await _storage.load(_allPreferencesKey);
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all preferences (logout scenario)
  Future<Either<Failure, bool>> clearAllPreferences() async {
    try {
      await _storage.delete(_themeKey);
      await _storage.delete(_languageKey);
      await _storage.delete(_displayKey);
      await _storage.delete(_notificationsKey);
      await _storage.delete(_allPreferencesKey);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear preferences: $e'));
    }
  }

  /// Get cache statistics
  Future<Either<Failure, Map<String, dynamic>>> getCacheStats() async {
    return _storage.getStats();
  }
}

