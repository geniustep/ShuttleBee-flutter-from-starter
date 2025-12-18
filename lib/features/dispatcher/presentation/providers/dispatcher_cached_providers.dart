import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/data/datasources/local_data_source.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../shuttlebee/presentation/providers/shuttlebee_api_providers.dart';
import '../../../shuttlebee/data/services/shuttlebee_api_service.dart';

/// A small, explicit cache layer for Dispatcher screens.
///
/// Goals:
/// - Cache-first UX (fast open, works offline)
/// - Per-user keys (avoid cross-user bleed on shared devices)
/// - TTL-based freshness (avoid refetching too frequently)
/// - Manual refresh can delete key + invalidate provider
final dispatcherCacheDataSourceProvider = Provider<CacheDataSource>((ref) {
  return CacheDataSource();
});

class DispatcherCacheKeys {
  DispatcherCacheKeys._();

  static String _dateKey(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];

  static String groups({required int userId}) => 'dispatcher:$userId:groups';

  static String dashboardStats({
    required int userId,
    required DateTime date,
  }) =>
      'dispatcher:$userId:dashboard_stats:${_dateKey(date)}';

  static String trips({
    required int userId,
    required TripFilters filters,
  }) {
    final from =
        filters.fromDate == null ? 'null' : _dateKey(filters.fromDate!);
    final to = filters.toDate == null ? 'null' : _dateKey(filters.toDate!);
    final state = filters.state?.value ?? 'null';
    final type = filters.tripType?.value ?? 'null';
    final driverId = filters.driverId?.toString() ?? 'null';
    final vehicleId = filters.vehicleId?.toString() ?? 'null';
    return 'dispatcher:$userId:trips:from=$from:to=$to:state=$state:type=$type:driver=$driverId:vehicle=$vehicleId:limit=${filters.limit}:offset=${filters.offset}';
  }

  static String ongoingTrips({required int userId}) =>
      'dispatcher:$userId:ongoing_trips';

  static String vehicles({required int userId}) =>
      'dispatcher:$userId:vehicles';

  /// All passengers cache key
  static String allPassengers({required int userId}) =>
      'dispatcher:$userId:all_passengers';

  /// Single passenger profile cache key
  static String passengerProfile({
    required int userId,
    required int passengerId,
  }) =>
      'dispatcher:$userId:passenger:$passengerId';

  /// Passengers by group cache key
  static String groupPassengers({
    required int userId,
    required int groupId,
  }) =>
      'dispatcher:$userId:group_passengers:$groupId';

  /// Unassigned passengers cache key
  static String unassignedPassengers({required int userId}) =>
      'dispatcher:$userId:unassigned_passengers';

  /// Users by role cache key
  static String usersByRole({
    required int userId,
    required String role,
  }) =>
      'dispatcher:$userId:users:$role';
}

int _userId(Ref ref) => ref.read(authStateProvider).asData?.value.user?.id ?? 0;

List<PassengerGroup> _decodeGroups(dynamic cached) {
  final list = (cached as List<dynamic>).cast<dynamic>();
  return list
      .map((e) => PassengerGroup.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

List<Trip> _decodeTrips(dynamic cached) {
  final list = (cached as List<dynamic>).cast<dynamic>();
  return list
      .map((e) => Trip.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

List<ShuttleVehicle> _decodeVehicles(dynamic cached) {
  final list = (cached as List<dynamic>).cast<dynamic>();
  return list
      .map((e) => ShuttleVehicle.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

List<User> _decodeUsers(dynamic cached) {
  final list = (cached as List<dynamic>).cast<dynamic>();
  return list
      .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Cache-first: groups list used in dispatcher.
final dispatcherGroupsProvider =
    FutureProvider.autoDispose<List<PassengerGroup>>((ref) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.groups(userId: userId);

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final groups = _decodeGroups(cached);
    // If offline: fully rely on cache
    if (!isOnline) return groups;
    // Online: rely on TTL for freshness (CacheDataSource drops expired keys)
    return groups;
  }

  // 2) No cache: fetch if possible
  if (!isOnline) return [];
  final dataSource = ref.watch(groupDataSourceProvider);
  if (dataSource == null) return [];

  final groups = await dataSource.getGroups();
  await cache.save(
    key: key,
    data: groups.map((g) => g.toJson()).toList(),
    ttl: const Duration(minutes: 10),
  );
  return groups;
});

/// Cache-first: trips list used in dispatcher (by date/filters).
final dispatcherTripsProvider = FutureProvider.autoDispose
    .family<List<Trip>, TripFilters>((ref, filters) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.trips(userId: userId, filters: filters);

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final trips = _decodeTrips(cached);
    if (!isOnline) return trips;
    return trips;
  }

  // 2) No cache: fetch if possible
  if (!isOnline) return [];
  final repository = ref.watch(tripRepositoryProvider);
  if (repository == null) return [];

  final result = await repository.getTrips(
    state: filters.state,
    tripType: filters.tripType,
    fromDate: filters.fromDate,
    toDate: filters.toDate,
    driverId: filters.driverId,
    vehicleId: filters.vehicleId,
    limit: filters.limit,
    offset: filters.offset,
  );

  return await result.fold(
    (failure) async => throw Exception(failure.message),
    (trips) async {
      await cache.save(
        key: key,
        data: trips.map((t) => t.toJson()).toList(),
        ttl: const Duration(minutes: 2),
      );
      return trips;
    },
  );
});

/// Cache-first: dashboard stats.
final dispatcherDashboardStatsProvider = FutureProvider.autoDispose
    .family<TripDashboardStats, DateTime>((ref, date) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return const TripDashboardStats();

  final key = DispatcherCacheKeys.dashboardStats(userId: userId, date: date);

  final cached = await cache.get<Map<String, dynamic>>(key);
  if (cached != null) {
    final stats =
        TripDashboardStats.fromJson(Map<String, dynamic>.from(cached));
    if (!isOnline) return stats;
    return stats;
  }

  if (!isOnline) return const TripDashboardStats();
  final repository = ref.watch(tripRepositoryProvider);
  if (repository == null) return const TripDashboardStats();

  final result = await repository.getDashboardStats(date);
  return await result.fold(
    (failure) async => const TripDashboardStats(),
    (stats) async {
      await cache.save(
        key: key,
        data: stats.toJson(),
        ttl: const Duration(minutes: 1),
      );
      return stats;
    },
  );
});

/// Live monitoring: always try server when online, but keep last cached value
/// for offline/failure fallback.
final dispatcherOngoingTripsProvider =
    FutureProvider.autoDispose<List<Trip>>((ref) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.ongoingTrips(userId: userId);
  final cached = await cache.get<List<dynamic>>(key);

  // Offline: return cached if available
  if (!isOnline) {
    if (cached == null) return [];
    return _decodeTrips(cached);
  }

  // Online: fetch fresh via ShuttleBee REST live endpoint, fallback to cache on failure.
  final shuttleApi = ref.watch(shuttleBeeApiServiceProvider);
  final repository = ref.watch(tripRepositoryProvider);

  try {
    final trips = await shuttleApi.getLiveOngoingTrips();
    await cache.save(
      key: key,
      data: trips.map((t) => t.toJson()).toList(),
      // Keep a short fallback window for offline.
      ttl: const Duration(minutes: 10),
    );
    return trips;
  } on ShuttleBeeRestNotAvailable catch (_) {
    if (repository != null) {
      final result = await repository.getTrips(
        state: TripState.ongoing,
        limit: 100,
        offset: 0,
      );

      return await result.fold(
        (_) async {
          if (cached != null) return _decodeTrips(cached);
          return const <Trip>[];
        },
        (trips) async {
          await cache.save(
            key: key,
            data: trips.map((t) => t.toJson()).toList(),
            ttl: const Duration(minutes: 10),
          );
          return trips;
        },
      );
    }

    if (cached != null) return _decodeTrips(cached);
    return const <Trip>[];
  } on DioException catch (e) {
    // Some deployments don't expose ShuttleBee REST controllers, so we fallback
    // to BridgeCore/JSON-RPC reads (same data, slower but works everywhere).
    final status = e.response?.statusCode;

    if (status == 404 && repository != null) {
      final result = await repository.getTrips(
        state: TripState.ongoing,
        limit: 100,
        offset: 0,
      );

      final foldResult = await result.fold(
        (_) async {
          if (cached != null) return _decodeTrips(cached);
          return null;
        },
        (trips) async {
          await cache.save(
            key: key,
            data: trips.map((t) => t.toJson()).toList(),
            ttl: const Duration(minutes: 10),
          );
          return trips;
        },
      );

      if (foldResult == null) rethrow;
      return foldResult;
    }

    if (cached != null) return _decodeTrips(cached);
    rethrow;
  } catch (_) {
    if (cached != null) return _decodeTrips(cached);
    rethrow;
  }
});

/// Cache-first: vehicles list used in dispatcher.
final dispatcherVehiclesProvider =
    FutureProvider.autoDispose<List<ShuttleVehicle>>((ref) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.vehicles(userId: userId);

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final vehicles = _decodeVehicles(cached);
    if (!isOnline) return vehicles;
    return vehicles;
  }

  // 2) No cache: fetch if possible
  if (!isOnline) return [];
  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return [];

  final vehicles = await dataSource.getVehicles();
  await cache.save(
    key: key,
    data: vehicles.map((v) => v.toJson()).toList(),
    ttl: const Duration(minutes: 10),
  );
  return vehicles;
});

/// Simple User model for user selection
class SimpleUser {
  final int id;
  final String name;
  final String? email;
  final String? role;

  const SimpleUser({
    required this.id,
    required this.name,
    this.email,
    this.role,
  });

  factory SimpleUser.fromOdoo(Map<String, dynamic> json) {
    return SimpleUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? json['login'] as String?,
      role: json['shuttle_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}

/// Cache-first: users by role (driver, companion, dispatcher)
final usersByRoleProvider = FutureProvider.autoDispose
    .family<List<SimpleUser>, String>((ref, role) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.usersByRole(userId: userId, role: role);

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final users = (cached as List<dynamic>)
        .map((e) => SimpleUser.fromOdoo(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (!isOnline) return users;
    return users;
  }

  // 2) No cache: fetch if possible using bridgecore
  if (!isOnline) return [];

  try {
    final client = ref.watch(bridgecoreClientProvider);
    if (client == null) return [];

    // Build domain based on role
    List<dynamic> domain = [];
    if (role == 'driver' || role == 'companion') {
      // Get users who are drivers or companions
      domain = [
        [
          'shuttle_role',
          'in',
          ['driver', 'companion']
        ]
      ];
    } else if (role == 'dispatcher') {
      // Get users who are dispatchers
      domain = [
        ['shuttle_role', '=', 'dispatcher']
      ];
    }

    final users = await client.searchRead(
      model: 'res.users',
      domain: domain,
      fields: ['id', 'name', 'email', 'login', 'shuttle_role'],
      limit: 200,
    );

    final simpleUsers = users.map((u) => SimpleUser.fromOdoo(u)).toList();

    await cache.save(
      key: key,
      data: users,
      ttl: const Duration(minutes: 30),
    );

    return simpleUsers;
  } catch (e) {
    // Fallback to empty list on error
    return [];
  }
});

/// Provider for drivers and companions combined
final driversAndCompanionsProvider =
    FutureProvider.autoDispose<List<SimpleUser>>((ref) async {
  final users = await ref.watch(usersByRoleProvider('driver').future);
  return users;
});

/// Provider for dispatchers only
final dispatchersProvider =
    FutureProvider.autoDispose<List<SimpleUser>>((ref) async {
  final users = await ref.watch(usersByRoleProvider('dispatcher').future);
  return users;
});
