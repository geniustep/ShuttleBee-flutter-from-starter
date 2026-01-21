import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/data/datasources/local_data_source.dart';
import '../../../../core/error_handling/failures.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../shuttlebee/presentation/providers/shuttlebee_api_providers.dart';
import '../../../shuttlebee/data/services/shuttlebee_api_service.dart';
import 'dispatcher_initial_load_provider.dart';

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

  static String dashboardStats({required int userId, required DateTime date}) =>
      'dispatcher:$userId:dashboard_stats:${_dateKey(date)}';

  static String trips({required int userId, required TripFilters filters}) {
    final from = filters.fromDate == null
        ? 'null'
        : _dateKey(filters.fromDate!);
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

  static String vehicle({required int userId, required int vehicleId}) =>
      'dispatcher:$userId:vehicle:$vehicleId';

  /// All passengers cache key
  static String allPassengers({required int userId}) =>
      'dispatcher:$userId:all_passengers';

  /// Single passenger profile cache key
  static String passengerProfile({
    required int userId,
    required int passengerId,
  }) => 'dispatcher:$userId:passenger:$passengerId';

  /// Passengers by group cache key
  static String groupPassengers({required int userId, required int groupId}) =>
      'dispatcher:$userId:group_passengers:$groupId';

  /// Unassigned passengers cache key
  static String unassignedPassengers({required int userId}) =>
      'dispatcher:$userId:unassigned_passengers';

  /// All passenger profiles cache key (for map view)
  static String allPassengerProfiles({required int userId}) =>
      'dispatcher:$userId:all_passenger_profiles';

  /// Users by role cache key
  static String usersByRole({required int userId, required String role}) =>
      'dispatcher:$userId:users:$role';
}

int _userId(Ref ref) => ref.read(authStateProvider).asData?.value.user?.id ?? 0;

/// Get cache metadata (cached time, expiry time, TTL)
Future<Map<String, String>?> _getCacheMetadata(
  CacheDataSource cache,
  String key,
) async {
  try {
    final metadataBox = await Hive.openBox('metadata_box');
    final expiryKey = '${key}_expiry';
    
    if (!metadataBox.containsKey(expiryKey)) {
      return null;
    }
    
    final expiryTime = metadataBox.get(expiryKey) as int;
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTime);
    final now = DateTime.now();
    
    // Calculate TTL from expiry time
    final ttl = expiryDate.difference(now);
    final ttlStr = ttl.isNegative 
        ? 'Expired (${ttl.abs().inSeconds}s ago)'
        : '${ttl.inMinutes}m ${ttl.inSeconds % 60}s';
    
    // Try to get cached time from a separate metadata entry
    final cachedTimeKey = '${key}_cached_at';
    String cachedAtStr;
    if (metadataBox.containsKey(cachedTimeKey)) {
      final cachedTime = metadataBox.get(cachedTimeKey) as int;
      final cachedDate = DateTime.fromMillisecondsSinceEpoch(cachedTime);
      cachedAtStr = '${cachedDate.hour.toString().padLeft(2, '0')}:${cachedDate.minute.toString().padLeft(2, '0')}:${cachedDate.second.toString().padLeft(2, '0')}';
    } else {
      // If cached time not available, estimate from expiry time
      // Assuming TTL was 1-2 minutes, estimate cached time
      cachedAtStr = 'Unknown';
    }
    
    return {
      'cachedAt': cachedAtStr,
      'expiresAt': '${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}:${expiryDate.second.toString().padLeft(2, '0')}',
      'ttl': ttlStr,
    };
  } catch (e) {
    return null;
  }
}

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

ShuttleVehicle? _decodeVehicle(dynamic cached) {
  if (cached == null) return null;
  final map = Map<String, dynamic>.from(cached as Map);
  return ShuttleVehicle.fromJson(map);
}

/// Cache-first: groups list used in dispatcher.
/// على Windows: يستخدم البيانات المحفوظة من التحميل الأولي
final dispatcherGroupsProvider =
    FutureProvider.autoDispose<List<PassengerGroup>>((ref) async {
      final cache = ref.watch(dispatcherCacheDataSourceProvider);
      final isOnline = ref.watch(isOnlineStateProvider);
      final userId = _userId(ref);
      if (userId == 0) return [];

      // على Windows: استخدم البيانات المحفوظة من التحميل الأولي
      if (Platform.isWindows) {
        final loadState = ref.watch(dispatcherInitialLoadProvider);
        if (loadState.isComplete && !loadState.hasError) {
          final preloadedGroups = await ref.watch(
            dispatcherPreloadedGroupsProvider.future,
          );
          if (preloadedGroups.isNotEmpty) {
            return preloadedGroups;
          }
        }
      }

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
/// على Windows: يستخدم البيانات المحفوظة من التحميل الأولي للرحلات بدون فلاتر خاصة
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
        final cacheMetadata = await _getCacheMetadata(cache, key);
        print('📦 [dispatcherTripsProvider] ✅ USING CACHE');
        print('   └─ Source: Local Storage (Cache)');
        print('   └─ Key: $key');
        print('   └─ Trips Count: ${trips.length}');
        if (cacheMetadata != null) {
          print('   └─ Cached At: ${cacheMetadata['cachedAt']}');
          print('   └─ Expires At: ${cacheMetadata['expiresAt']}');
          print('   └─ TTL: ${cacheMetadata['ttl']}');
        }
        if (!isOnline) {
          print('   └─ Status: Offline mode - using cached data');
          return trips;
        }
        print('   └─ Status: Online - using cached data (fresh)');
        // البيانات موجودة في الـ cache - نعيدها مباشرة بدون جلب من السيرفر
        return trips;
      }

      // 2) على Windows: استخدم البيانات المحملة مسبقاً قبل محاولة الجلب من السيرفر
      if (Platform.isWindows) {
        try {
          final loadState = ref.read(dispatcherInitialLoadProvider);
          if (loadState.isComplete && !loadState.hasError) {
            final preloadedTrips = await ref.read(
              dispatcherPreloadedTripsProvider.future,
            );
            if (preloadedTrips.isNotEmpty) {
              print('📦 [dispatcherTripsProvider] ✅ USING PRELOADED DATA');
              print('   └─ Source: Initial Load (Preloaded)');
              print('   └─ Key: $key');
              print('   └─ Preloaded Trips Count: ${preloadedTrips.length}');
              // تطبيق الفلاتر على البيانات المحفوظة
              var result = preloadedTrips.toList();
              if (filters.state != null) {
                result = result.where((t) => t.state == filters.state).toList();
              }
              if (filters.tripType != null) {
                result = result
                    .where((t) => t.tripType == filters.tripType)
                    .toList();
              }
              if (filters.fromDate != null) {
                result = result
                    .where(
                      (t) =>
                          t.date.isAfter(filters.fromDate!) ||
                          t.date.isAtSameMomentAs(filters.fromDate!),
                    )
                    .toList();
              }
              if (filters.toDate != null) {
                result = result
                    .where(
                      (t) =>
                          t.date.isBefore(filters.toDate!) ||
                          t.date.isAtSameMomentAs(filters.toDate!),
                    )
                    .toList();
              }
              if (filters.driverId != null) {
                result = result
                    .where((t) => t.driverId == filters.driverId)
                    .toList();
              }
              if (filters.vehicleId != null) {
                result = result
                    .where((t) => t.vehicleId == filters.vehicleId)
                    .toList();
              }
              // تطبيق الـ limit و offset
              if (filters.offset > 0 && filters.offset < result.length) {
                result = result.sublist(filters.offset);
              }
              if (filters.limit > 0 && result.length > filters.limit) {
                result = result.sublist(0, filters.limit);
              }
              
              // حفظ في الـ cache للاستخدام المستقبلي
              final filteredCount = result.length;
              await cache.save(
                key: key,
                data: result.map((t) => t.toJson()).toList(),
                ttl: const Duration(minutes: 2),
              );
              print('   └─ Filtered Trips Count: $filteredCount');
              print('   └─ Saved to Cache: Yes (TTL: 2 minutes)');
              print('   └─ Status: Using preloaded data');
              // على Windows: نعيد البيانات المحملة مسبقاً مباشرة بدون محاولة الجلب من السيرفر
              return result;
            }
          }
        } catch (e) {
          print('⚠️ [dispatcherTripsProvider] Preloaded trips error: $e');
        }
      }

      print('⚠️ [dispatcherTripsProvider] ❌ NO CACHE FOUND');
      print('   └─ Key: $key');
      print('   └─ Status: Cache miss - will fetch from API');

      // 3) No cache: fetch if possible
      if (!isOnline) {
        print('   └─ Status: Offline - cannot fetch from API');
        return [];
      }
      final repository = ref.watch(tripRepositoryProvider);
      if (repository == null) {
        print('   └─ Status: Repository not available');
        return [];
      }

      try {
        print('🌐 [dispatcherTripsProvider] 🔄 FETCHING FROM API');
        print('   └─ Source: Remote API');
        print('   └─ Key: $key');
        final stopwatch = Stopwatch()..start();
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
          (failure) async {
            stopwatch.stop();
            print('   └─ API Response Time: ${stopwatch.elapsedMilliseconds}ms');
            print('   └─ Status: ❌ API Error');
            print('   └─ Error: ${failure.message}');
            // في حالة فشل الجلب من السيرفر، نحاول استخدام البيانات المحملة مسبقاً على Windows
            if (Platform.isWindows) {
              try {
                final loadState = ref.read(dispatcherInitialLoadProvider);
                if (loadState.isComplete && !loadState.hasError) {
                  final preloadedTrips = await ref.read(
                    dispatcherPreloadedTripsProvider.future,
                  );
                  if (preloadedTrips.isNotEmpty) {
                    print('📦 [dispatcherTripsProvider] ✅ USING PRELOADED DATA (FALLBACK)');
                    print('   └─ Source: Initial Load (Preloaded) - Fallback after API error');
                    print('   └─ Key: $key');
                    print('   └─ Preloaded Trips Count: ${preloadedTrips.length}');
                    // تطبيق الفلاتر
                    var result = preloadedTrips.toList();
                    if (filters.state != null) {
                      result = result.where((t) => t.state == filters.state).toList();
                    }
                    if (filters.tripType != null) {
                      result = result.where((t) => t.tripType == filters.tripType).toList();
                    }
                    if (filters.fromDate != null) {
                      result = result.where(
                        (t) => t.date.isAfter(filters.fromDate!) || t.date.isAtSameMomentAs(filters.fromDate!),
                      ).toList();
                    }
                    if (filters.toDate != null) {
                      result = result.where(
                        (t) => t.date.isBefore(filters.toDate!) || t.date.isAtSameMomentAs(filters.toDate!),
                      ).toList();
                    }
                    if (filters.driverId != null) {
                      result = result.where((t) => t.driverId == filters.driverId).toList();
                    }
                    if (filters.vehicleId != null) {
                      result = result.where((t) => t.vehicleId == filters.vehicleId).toList();
                    }
                    if (filters.offset > 0 && filters.offset < result.length) {
                      result = result.sublist(filters.offset);
                    }
                    if (filters.limit > 0 && result.length > filters.limit) {
                      result = result.sublist(0, filters.limit);
                    }
                    return result;
                  }
                }
              } catch (_) {}
            }
            throw Exception(failure.message);
          },
          (trips) async {
            stopwatch.stop();
            print('   └─ API Response Time: ${stopwatch.elapsedMilliseconds}ms');
            print('   └─ Trips Count: ${trips.length}');
            await cache.save(
              key: key,
              data: trips.map((t) => t.toJson()).toList(),
              ttl: const Duration(minutes: 2),
            );
            print('   └─ Saved to Cache: Yes (TTL: 2 minutes)');
            print('   └─ Status: ✅ Successfully fetched and cached');
            return trips;
          },
        );
      } catch (e) {
        print('   └─ Status: ❌ Connection Error');
        print('   └─ Error: $e');
        // في حالة خطأ في الاتصال، نحاول استخدام البيانات المحملة مسبقاً على Windows
        if (Platform.isWindows) {
          try {
            final loadState = ref.read(dispatcherInitialLoadProvider);
            if (loadState.isComplete && !loadState.hasError) {
              final preloadedTrips = await ref.read(
                dispatcherPreloadedTripsProvider.future,
              );
              if (preloadedTrips.isNotEmpty) {
                print('📦 [dispatcherTripsProvider] ✅ USING PRELOADED DATA (FALLBACK)');
                print('   └─ Source: Initial Load (Preloaded) - Fallback after connection error');
                print('   └─ Key: $key');
                print('   └─ Preloaded Trips Count: ${preloadedTrips.length}');
                // تطبيق الفلاتر البسيطة
                var result = preloadedTrips.toList();
                if (filters.state != null) {
                  result = result.where((t) => t.state == filters.state).toList();
                }
                if (filters.tripType != null) {
                  result = result.where((t) => t.tripType == filters.tripType).toList();
                }
                return result;
              }
            }
          } catch (_) {}
        }
        rethrow;
      }
    });

/// Cache-first: dashboard stats.
/// يستخدم FutureProvider عادي (بدون autoDispose) لتجنب إعادة البناء المتكررة
final dispatcherDashboardStatsProvider = FutureProvider
    .family<TripDashboardStats, DateTime>((ref, date) async {
      // استخدام read بدلاً من watch لتجنب إعادة البناء عند تغيير هذه القيم
      final cache = ref.read(dispatcherCacheDataSourceProvider);
      final isOnline = ref.read(isOnlineStateProvider);
      final userId = _userId(ref);
      if (userId == 0) return const TripDashboardStats();

      final key = DispatcherCacheKeys.dashboardStats(
        userId: userId,
        date: date,
      );

      // التحقق من الكاش أولاً - CacheDataSource يتحقق من TTL تلقائياً
      final cached = await cache.get<Map<String, dynamic>>(key);
      if (cached != null) {
        final stats = TripDashboardStats.fromJson(
          Map<String, dynamic>.from(cached),
        );
        final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
        final cacheMetadata = await _getCacheMetadata(cache, key);
        print('📦 [dispatcherDashboardStatsProvider] ✅ USING CACHE');
        print('   └─ Source: Local Storage (Cache)');
        print('   └─ Key: $key');
        print('   └─ Date: $dateStr');
        print('   └─ Stats: TotalTrips=${stats.totalTripsToday}, Ongoing=${stats.ongoingTrips}, Completed=${stats.completedTrips}');
        if (cacheMetadata != null) {
          print('   └─ Cached At: ${cacheMetadata['cachedAt']}');
          print('   └─ Expires At: ${cacheMetadata['expiresAt']}');
          print('   └─ TTL: ${cacheMetadata['ttl']}');
        }
        // إذا كان غير متصل، نعيد البيانات المحفوظة مباشرة
        if (!isOnline) {
          print('   └─ Status: Offline mode - using cached data');
          return stats;
        }

        // إذا كان متصل والبيانات موجودة في الكاش (لم تنته صلاحيتها)،
        // نعيدها مباشرة لتجنب الاستدعاءات المتكررة
        // الـ TTL = 1 دقيقة، لذا البيانات حديثة بما فيه الكفاية
        print('   └─ Status: Online - using cached data (fresh)');
        return stats;
      }

      final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
      print('⚠️ [dispatcherDashboardStatsProvider] ❌ NO CACHE FOUND');
      print('   └─ Key: $key');
      print('   └─ Date: $dateStr');
      print('   └─ Status: Cache miss - will fetch from API');

      // لا توجد بيانات في الكاش أو انتهت صلاحيتها
      if (!isOnline) {
        return const TripDashboardStats();
      }

      final repository = ref.read(tripRepositoryProvider);
      if (repository == null) {
        return const TripDashboardStats();
      }

      // جلب البيانات من الـ API
      print('🌐 [dispatcherDashboardStatsProvider] 🔄 FETCHING FROM API');
      print('   └─ Source: Remote API');
      print('   └─ Key: $key');
      print('   └─ Date: $dateStr');
      final stopwatch = Stopwatch()..start();
      final result = await repository.getDashboardStats(date);
      return await result.fold(
        (failure) async {
          stopwatch.stop();
          print('   └─ API Response Time: ${stopwatch.elapsedMilliseconds}ms');
          print('   └─ Status: ❌ API Error');
          print('   └─ Error: ${failure.message}');
          // If it's an authentication error, throw it to trigger error handling in UI
          final errorMsg = failure.message.toLowerCase();
          if (failure is AuthFailure ||
              errorMsg.contains('not authenticated') ||
              errorMsg.contains('403') ||
              errorMsg.contains('400') ||
              errorMsg.contains('authentication required') ||
              errorMsg.contains('access denied') ||
              errorMsg.contains('forbidden') ||
              errorMsg.contains('missing odoo credentials') ||
              errorMsg.contains('no tokens found') ||
              errorMsg.contains('انتهت صلاحية الجلسة')) {
            throw Exception(failure.message);
          }

          // في حالة أخطاء الاتصال (502, 503, 504)، نحاول استخدام البيانات المحفوظة حتى لو انتهت صلاحيتها
          if (errorMsg.contains('502') ||
              errorMsg.contains('503') ||
              errorMsg.contains('504') ||
              errorMsg.contains('bad gateway') ||
              errorMsg.contains('service unavailable') ||
              errorMsg.contains('gateway timeout') ||
              errorMsg.contains('connection error') ||
              errorMsg.contains('network error') ||
              errorMsg.contains('timeout') ||
              errorMsg.contains('unexpected response format')) {
            // محاولة جلب البيانات من الكاش حتى لو انتهت صلاحيتها
            try {
              final expiredData = await cache
                  .getEvenIfExpired<Map<String, dynamic>>(key);
              if (expiredData != null) {
                // إعادة البيانات المحفوظة وتجنب إعادة المحاولة
                return TripDashboardStats.fromJson(expiredData);
              }
            } catch (_) {
              // في حالة فشل جلب البيانات من الكاش، نعيد بيانات فارغة
            }
            // عند حدوث خطأ 502، نعيد بيانات فارغة بدلاً من إعادة المحاولة
            // هذا يمنع المحاولات المتكررة التي تسبب استهلاك الموارد
            return const TripDashboardStats();
          }

          // في حالة الخطأ، نعيد بيانات فارغة
          return const TripDashboardStats();
        },
        (stats) async {
          // التأكد من أن جميع الحقول موجودة
          final statsToSave = TripDashboardStats(
            totalTripsToday: stats.totalTripsToday,
            ongoingTrips: stats.ongoingTrips,
            completedTrips: stats.completedTrips,
            cancelledTrips: stats.cancelledTrips,
            plannedTrips: stats.plannedTrips,
            totalPassengers: stats.totalPassengers,
            boardedPassengers: stats.boardedPassengers,
            absentPassengers: stats.absentPassengers,
            totalVehicles: stats.totalVehicles,
            activeVehicles: stats.activeVehicles,
            totalDrivers: stats.totalDrivers,
            activeDrivers: stats.activeDrivers,
          );
          stopwatch.stop();
          print('   └─ API Response Time: ${stopwatch.elapsedMilliseconds}ms');
          print('   └─ Stats: TotalTrips=${statsToSave.totalTripsToday}, Ongoing=${statsToSave.ongoingTrips}, Completed=${statsToSave.completedTrips}');
          // حفظ البيانات في الكاش مع TTL = 1 دقيقة
          await cache.save(
            key: key,
            data: statsToSave.toJson(),
            ttl: const Duration(minutes: 1),
          );
          print('   └─ Saved to Cache: Yes (TTL: 1 minute)');
          print('   └─ Status: ✅ Successfully fetched and cached');
          return statsToSave;
        },
      );
    });

/// Live monitoring: always try server when online, but keep last cached value
/// for offline/failure fallback.
final dispatcherOngoingTripsProvider = FutureProvider.autoDispose<List<Trip>>((
  ref,
) async {
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
/// على Windows: يستخدم البيانات المحفوظة من التحميل الأولي
final dispatcherVehiclesProvider =
    FutureProvider.autoDispose<List<ShuttleVehicle>>((ref) async {
      final cache = ref.watch(dispatcherCacheDataSourceProvider);
      final isOnline = ref.watch(isOnlineStateProvider);
      final userId = _userId(ref);
      if (userId == 0) return [];

      // على Windows: استخدم البيانات المحفوظة من التحميل الأولي
      if (Platform.isWindows) {
        final loadState = ref.watch(dispatcherInitialLoadProvider);
        if (loadState.isComplete && !loadState.hasError) {
          final preloadedVehicles = await ref.watch(
            dispatcherPreloadedVehiclesProvider.future,
          );
          if (preloadedVehicles.isNotEmpty) {
            return preloadedVehicles;
          }
        }
      }

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

      print('📦 [dispatcherVehiclesProvider] 🌐 FETCHING FROM SERVER');
      final vehicles = await dataSource.getVehicles();
      print('   └─ Fetched ${vehicles.length} vehicles');
      await cache.save(
        key: key,
        data: vehicles.map((v) => v.toJson()).toList(),
        ttl: const Duration(minutes: 10),
      );
      print('   └─ Saved to Cache: Yes (TTL: 10 minutes)');
      print('   └─ Status: ✅ Successfully fetched and cached');
      return vehicles;
    });

/// Cache-first: single vehicle by ID used in dispatcher.
/// يستخدم الكاش والبيانات المحفوظة من التحميل الأولي
final dispatcherVehicleByIdProvider = FutureProvider.autoDispose
    .family<ShuttleVehicle?, int>((ref, vehicleId) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return null;

  final key = DispatcherCacheKeys.vehicle(userId: userId, vehicleId: vehicleId);

  print('📦 [dispatcherVehicleByIdProvider] 🔍 SEARCHING FOR VEHICLE');
  print('   └─ Vehicle ID: $vehicleId');
  print('   └─ User ID: $userId');
  print('   └─ Cache Key: $key');

  // 1) Cache-first: تحقق من الكاش المباشر للمركبة
  final cached = await cache.get<Map<String, dynamic>>(key);
  if (cached != null) {
    final vehicle = _decodeVehicle(cached);
    if (vehicle != null) {
      print('📦 [dispatcherVehicleByIdProvider] ✅ USING DIRECT CACHE');
      print('   └─ Source: Local Storage (Direct Cache)');
      print('   └─ Vehicle Name: ${vehicle.name}');
      if (!isOnline) {
        print('   └─ Status: Offline mode - using cached data');
        return vehicle;
      }
      print('   └─ Status: Online - using cached data (fresh)');
      return vehicle;
    }
  }
  print('   └─ ❌ Direct cache not found');

  // 2) ابحث في قائمة المركبات المحفوظة في الكاش أولاً (أسرع)
  final vehiclesKey = DispatcherCacheKeys.vehicles(userId: userId);
  print('   └─ 🔍 Checking vehicles list cache...');
  final cachedVehicles = await cache.get<List<dynamic>>(vehiclesKey);
  if (cachedVehicles != null) {
    try {
      final vehicles = _decodeVehicles(cachedVehicles);
      print('   └─ Found ${vehicles.length} vehicles in cache');
      final foundVehicle = vehicles.firstWhere(
        (v) => v.id == vehicleId,
      );
      print('📦 [dispatcherVehicleByIdProvider] ✅ USING VEHICLES LIST CACHE');
      print('   └─ Source: Vehicles List Cache');
      print('   └─ Vehicle Name: ${foundVehicle.name}');
      // حفظ في الكاش المباشر للمركبة للاستخدام المستقبلي
      await cache.save(
        key: key,
        data: foundVehicle.toJson(),
        ttl: const Duration(minutes: 10),
      );
      print('   └─ Saved to direct cache for future use');
      return foundVehicle;
    } catch (e) {
      print('   └─ ❌ Vehicle not found in vehicles list cache');
    }
  } else {
    print('   └─ ❌ Vehicles list cache not found');
  }

  // 3) على Windows: ابحث في البيانات المحفوظة من التحميل الأولي
  if (Platform.isWindows) {
    print('   └─ 🔍 Checking preloaded data (Windows)...');
    final loadState = ref.watch(dispatcherInitialLoadProvider);
    if (loadState.isComplete && !loadState.hasError) {
      try {
        final preloadedVehicles = await ref.watch(
          dispatcherPreloadedVehiclesProvider.future,
        );
        print('   └─ Found ${preloadedVehicles.length} preloaded vehicles');
        final foundVehicle = preloadedVehicles.firstWhere(
          (v) => v.id == vehicleId,
        );
        print('📦 [dispatcherVehicleByIdProvider] ✅ USING PRELOADED DATA');
        print('   └─ Source: Initial Load (Preloaded)');
        print('   └─ Vehicle Name: ${foundVehicle.name}');
        // حفظ في الكاش للاستخدام المستقبلي
        await cache.save(
          key: key,
          data: foundVehicle.toJson(),
          ttl: const Duration(minutes: 10),
        );
        print('   └─ Saved to cache for future use');
        return foundVehicle;
      } catch (e) {
        print('   └─ ❌ Vehicle not found in preloaded data');
      }
    } else {
      print('   └─ ❌ Initial load not complete or has error');
    }
  }

  // 4) No cache: fetch if possible
  if (!isOnline) return null;
  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return null;

  print('📦 [dispatcherVehicleByIdProvider] 🌐 FETCHING FROM SERVER');
  print('   └─ Vehicle ID: $vehicleId');
  
  final vehicle = await dataSource.getVehicleById(vehicleId);
  if (vehicle != null) {
    print('   └─ Vehicle Name: ${vehicle.name}');
    print('   └─ Saved to Cache: Yes (TTL: 10 minutes)');
    print('   └─ Status: ✅ Successfully fetched and cached');
    // حفظ في الكاش
    await cache.save(
      key: key,
      data: vehicle.toJson(),
      ttl: const Duration(minutes: 10),
    );
  } else {
    print('   └─ Status: ❌ Vehicle not found');
  }
  return vehicle;
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
    // Handle shuttle_role which can be String or bool
    String? role;
    final shuttleRole = json['shuttle_role'];
    if (shuttleRole != null) {
      if (shuttleRole is String) {
        role = shuttleRole;
      } else if (shuttleRole is bool && shuttleRole) {
        // If it's true, we might want to set a default role
        // But for now, we'll leave it null since we don't know what role it represents
        role = null;
      }
    }

    // Handle email which can be String or bool
    String? email;
    final emailValue = json['email'];
    if (emailValue != null && emailValue is String) {
      email = emailValue;
    } else {
      // Try login as fallback
      final loginValue = json['login'];
      if (loginValue != null && loginValue is String) {
        email = loginValue;
      }
    }

    return SimpleUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: email,
      role: role,
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
/// على Windows: يستخدم البيانات المحفوظة من التحميل الأولي
final usersByRoleProvider = FutureProvider.autoDispose
    .family<List<SimpleUser>, String>((ref, role) async {
      final cache = ref.watch(dispatcherCacheDataSourceProvider);
      final isOnline = ref.watch(isOnlineStateProvider);
      final userId = _userId(ref);
      if (userId == 0) return [];

      // على Windows: استخدم البيانات المحفوظة للسائقين والمرافقين
      if (Platform.isWindows && (role == 'driver' || role == 'companion')) {
        final loadState = ref.watch(dispatcherInitialLoadProvider);
        if (loadState.isComplete && !loadState.hasError) {
          final service = ref.watch(dispatcherInitialDataServiceProvider);
          if (role == 'driver') {
            final drivers = await service.getCachedDrivers();
            if (drivers.isNotEmpty) {
              return drivers.map((d) => SimpleUser.fromOdoo(d)).toList();
            }
          } else if (role == 'companion') {
            final companions = await service.getCachedCompanions();
            if (companions.isNotEmpty) {
              return companions.map((c) => SimpleUser.fromOdoo(c)).toList();
            }
          }
        }
      }

      final key = DispatcherCacheKeys.usersByRole(userId: userId, role: role);

      // 1) Cache-first
      final cached = await cache.get<List<dynamic>>(key);
      if (cached != null) {
        final users = (cached)
            .map(
              (e) => SimpleUser.fromOdoo(Map<String, dynamic>.from(e as Map)),
            )
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
              ['driver', 'companion'],
            ],
          ];
        } else if (role == 'dispatcher') {
          // Get users who are dispatchers
          domain = [
            ['shuttle_role', '=', 'dispatcher'],
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
      final drivers = await ref.watch(usersByRoleProvider('driver').future);
      final companions = await ref.watch(
        usersByRoleProvider('companion').future,
      );
      // دمج القائمتين وإزالة التكرارات
      final allUsers = <int, SimpleUser>{};
      for (final user in drivers) {
        allUsers[user.id] = user;
      }
      for (final user in companions) {
        allUsers[user.id] = user;
      }
      return allUsers.values.toList();
    });

/// Provider for drivers only - يجلب المستخدمين الذين لديهم shuttle_role == 'driver'
/// على Windows: يستخدم البيانات المحفوظة من التحميل الأولي
final driversProvider = FutureProvider.autoDispose<List<SimpleUser>>((
  ref,
) async {
  // على Windows: استخدم البيانات المحفوظة من التحميل الأولي
  if (Platform.isWindows) {
    final loadState = ref.watch(dispatcherInitialLoadProvider);
    if (loadState.isComplete && !loadState.hasError) {
      final service = ref.watch(dispatcherInitialDataServiceProvider);
      final drivers = await service.getCachedDrivers();
      if (drivers.isNotEmpty) {
        return drivers.map((d) => SimpleUser.fromOdoo(d)).toList();
      }
    }
  }

  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.usersByRole(
    userId: userId,
    role: 'driver_only',
  );

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final users = (cached)
        .map((e) => SimpleUser.fromOdoo(Map<String, dynamic>.from(e as Map)))
        .toList();
    // تصفية للحصول على السائقين فقط
    final drivers = users.where((user) => user.role == 'driver').toList();
    if (!isOnline) return drivers;
  }

  // 2) No cache or online: fetch if possible using bridgecore
  if (!isOnline && cached != null) {
    final users = (cached)
        .map((e) => SimpleUser.fromOdoo(Map<String, dynamic>.from(e as Map)))
        .toList();
    return users.where((user) => user.role == 'driver').toList();
  }

  if (!isOnline) return [];

  try {
    final client = ref.watch(bridgecoreClientProvider);
    if (client == null) return [];

    // جلب المستخدمين الذين لديهم shuttle_role == 'driver' فقط
    final users = await client.searchRead(
      model: 'res.users',
      domain: [
        ['shuttle_role', '=', 'driver'],
      ],
      fields: ['id', 'name', 'email', 'login', 'shuttle_role'],
      limit: 200,
    );

    final simpleUsers = users.map((u) => SimpleUser.fromOdoo(u)).toList();

    // حفظ في الـ cache
    await cache.save(key: key, data: users, ttl: const Duration(minutes: 30));

    return simpleUsers;
  } catch (e) {
    // في حالة الخطأ، نعيد الـ cache إذا كان موجوداً
    if (cached != null) {
      final users = (cached)
          .map((e) => SimpleUser.fromOdoo(Map<String, dynamic>.from(e as Map)))
          .toList();
      return users.where((user) => user.role == 'driver').toList();
    }
    // Fallback to empty list on error
    return [];
  }
});

/// Provider for companions only - يجلب المستخدمين الذين لديهم shuttle_role == 'companion'
/// على Windows: يستخدم البيانات المحفوظة من التحميل الأولي
final companionsProvider = FutureProvider.autoDispose<List<SimpleUser>>((
  ref,
) async {
  // على Windows: استخدم البيانات المحفوظة من التحميل الأولي
  if (Platform.isWindows) {
    final loadState = ref.watch(dispatcherInitialLoadProvider);
    if (loadState.isComplete && !loadState.hasError) {
      final preloadedCompanions = await ref.watch(
        dispatcherPreloadedCompanionsProvider.future,
      );
      if (preloadedCompanions.isNotEmpty) {
        return preloadedCompanions.map((c) => SimpleUser.fromOdoo(c)).toList();
      }
    }
  }

  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.usersByRole(
    userId: userId,
    role: 'companion_only',
  );

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final users = (cached)
        .map((e) => SimpleUser.fromOdoo(Map<String, dynamic>.from(e as Map)))
        .toList();
    // تصفية للحصول على المرافقين فقط
    final companions = users.where((user) => user.role == 'companion').toList();
    if (!isOnline) return companions;
    // إذا كان متصل، نتحقق من البيانات الجديدة
  }

  // 2) No cache or online: fetch if possible using bridgecore
  if (!isOnline && cached != null) {
    // إذا كان غير متصل ولدينا cache، نعيد الـ cache
    final users = (cached)
        .map((e) => SimpleUser.fromOdoo(Map<String, dynamic>.from(e as Map)))
        .toList();
    return users.where((user) => user.role == 'companion').toList();
  }

  if (!isOnline) return [];

  try {
    final client = ref.watch(bridgecoreClientProvider);
    if (client == null) return [];

    // جلب المستخدمين الذين لديهم shuttle_role == 'companion' فقط
    final users = await client.searchRead(
      model: 'res.users',
      domain: [
        ['shuttle_role', '=', 'companion'],
      ],
      fields: ['id', 'name', 'email', 'login', 'shuttle_role'],
      limit: 200,
    );

    final simpleUsers = users.map((u) => SimpleUser.fromOdoo(u)).toList();

    // حفظ في الـ cache
    await cache.save(key: key, data: users, ttl: const Duration(minutes: 30));

    return simpleUsers;
  } catch (e) {
    // في حالة الخطأ، نعيد الـ cache إذا كان موجوداً
    if (cached != null) {
      final users = (cached)
          .map((e) => SimpleUser.fromOdoo(Map<String, dynamic>.from(e as Map)))
          .toList();
      return users.where((user) => user.role == 'companion').toList();
    }
    // Fallback to empty list on error
    return [];
  }
});

/// Provider for dispatchers only
final dispatchersProvider = FutureProvider.autoDispose<List<SimpleUser>>((
  ref,
) async {
  final users = await ref.watch(usersByRoleProvider('dispatcher').future);
  return users;
});
