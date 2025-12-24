import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/local_storage/domain/local_storage_repository.dart';
import '../../domain/entities/dispatcher_passenger_profile.dart';
import '../../domain/entities/passenger_group_line.dart';

/// Local cache for Passenger data
///
/// Provides offline-first caching for:
/// - Passenger profiles
/// - Passenger groups
/// - Passenger lines
/// - Unassigned passengers
class PassengerLocalCache {
  final LocalStorageRepository _storage;

  // Collection names
  static const String _profilesCollection = 'passenger_profiles';
  static const String _groupsCollection = 'passenger_groups';
  static const String _linesCollection = 'passenger_lines';
  static const String _unassignedCollection = 'unassigned_passengers';

  // Cache TTL
  static const Duration _profilesTTL = Duration(hours: 24);
  static const Duration _groupsTTL = Duration(hours: 12);
  static const Duration _linesTTL = Duration(hours: 6);

  PassengerLocalCache(this._storage);

  // ════════════════════════════════════════════════════════════
  // Passenger Profiles Cache
  // ════════════════════════════════════════════════════════════

  /// Save passenger profiles to cache
  Future<Either<Failure, bool>> cacheProfiles(
    List<DispatcherPassengerProfile> profiles,
  ) async {
    try {
      final profilesJson = profiles.map((p) => p.toJson()).toList();
      return await _storage.saveCollection(
        collectionName: _profilesCollection,
        items: profilesJson,
        ttl: _profilesTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache profiles: $e'));
    }
  }

  /// Load cached passenger profiles
  Future<Either<Failure, List<DispatcherPassengerProfile>>>
  getCachedProfiles() async {
    final result = await _storage.loadCollection(_profilesCollection);

    return result.fold((failure) => Left(failure), (items) {
      try {
        final profiles = items
            .map((json) => DispatcherPassengerProfile.fromJson(json))
            .toList();
        return Right(profiles);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse profiles: $e'));
      }
    });
  }

  /// Get single passenger profile by ID
  Future<Either<Failure, DispatcherPassengerProfile?>> getCachedProfile(
    int passengerId,
  ) async {
    final profilesResult = await getCachedProfiles();
    return profilesResult.fold((failure) => Left(failure), (profiles) {
      try {
        final profile = profiles.firstWhere(
          (p) => p.id == passengerId,
          orElse: () => throw Exception('Profile not found'),
        );
        return Right(profile);
      } catch (_) {
        return const Right(null);
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // Passenger Groups Cache
  // ════════════════════════════════════════════════════════════

  /// Save passenger groups to cache
  Future<Either<Failure, bool>> cacheGroups(
    Map<int, List<PassengerGroupLine>> groups,
  ) async {
    try {
      final groupsJson = groups.entries.map((entry) {
        return {
          'group_id': entry.key,
          'lines': entry.value.map((line) => line.toJson()).toList(),
        };
      }).toList();

      return await _storage.saveCollection(
        collectionName: _groupsCollection,
        items: groupsJson,
        ttl: _groupsTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache groups: $e'));
    }
  }

  /// Load cached passenger groups
  Future<Either<Failure, Map<int, List<PassengerGroupLine>>>>
  getCachedGroups() async {
    final result = await _storage.loadCollection(_groupsCollection);

    return result.fold((failure) => Left(failure), (items) {
      try {
        final groups = <int, List<PassengerGroupLine>>{};
        for (final item in items) {
          final groupId = item['group_id'] as int;
          final linesJson = item['lines'] as List<dynamic>;
          final lines = linesJson
              .map(
                (json) =>
                    PassengerGroupLine.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          groups[groupId] = lines;
        }
        return Right(groups);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse groups: $e'));
      }
    });
  }

  /// Get cached lines for a specific group
  Future<Either<Failure, List<PassengerGroupLine>>> getCachedGroupLines(
    int groupId,
  ) async {
    final groupsResult = await getCachedGroups();
    return groupsResult.fold((failure) => Left(failure), (groups) {
      final lines = groups[groupId] ?? [];
      return Right(lines);
    });
  }

  // ════════════════════════════════════════════════════════════
  // Passenger Lines Cache
  // ════════════════════════════════════════════════════════════

  /// Save all passenger lines to cache
  Future<Either<Failure, bool>> cacheLines(
    List<PassengerGroupLine> lines,
  ) async {
    try {
      final linesJson = lines.map((line) => line.toJson()).toList();
      return await _storage.saveCollection(
        collectionName: _linesCollection,
        items: linesJson,
        ttl: _linesTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache lines: $e'));
    }
  }

  /// Load cached passenger lines
  Future<Either<Failure, List<PassengerGroupLine>>> getCachedLines() async {
    final result = await _storage.loadCollection(_linesCollection);

    return result.fold((failure) => Left(failure), (items) {
      try {
        final lines = items
            .map((json) => PassengerGroupLine.fromJson(json))
            .toList();
        return Right(lines);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse lines: $e'));
      }
    });
  }

  /// Get lines for a specific passenger
  Future<Either<Failure, List<PassengerGroupLine>>> getCachedPassengerLines(
    int passengerId,
  ) async {
    final linesResult = await getCachedLines();
    return linesResult.fold((failure) => Left(failure), (lines) {
      final passengerLines = lines
          .where((line) => line.passengerId == passengerId)
          .toList();
      return Right(passengerLines);
    });
  }

  // ════════════════════════════════════════════════════════════
  // Unassigned Passengers Cache
  // ════════════════════════════════════════════════════════════

  /// Save unassigned passengers to cache
  Future<Either<Failure, bool>> cacheUnassigned(
    List<PassengerGroupLine> unassigned,
  ) async {
    try {
      final unassignedJson = unassigned.map((line) => line.toJson()).toList();
      return await _storage.saveCollection(
        collectionName: _unassignedCollection,
        items: unassignedJson,
        ttl: _linesTTL,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache unassigned: $e'));
    }
  }

  /// Load cached unassigned passengers
  Future<Either<Failure, List<PassengerGroupLine>>>
  getCachedUnassigned() async {
    final result = await _storage.loadCollection(_unassignedCollection);

    return result.fold((failure) => Left(failure), (items) {
      try {
        final unassigned = items
            .map((json) => PassengerGroupLine.fromJson(json))
            .toList();
        return Right(unassigned);
      } catch (e) {
        return Left(CacheFailure(message: 'Failed to parse unassigned: $e'));
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Clear all passenger caches
  Future<Either<Failure, bool>> clearAllCaches() async {
    try {
      await _storage.deleteCollection(_profilesCollection);
      await _storage.deleteCollection(_groupsCollection);
      await _storage.deleteCollection(_linesCollection);
      await _storage.deleteCollection(_unassignedCollection);
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
