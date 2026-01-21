import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/dispatcher_partner_remote_data_source.dart';
import '../../domain/entities/dispatcher_passenger_profile.dart';
import 'dispatcher_cached_providers.dart';
import 'dispatcher_passenger_providers.dart';

final dispatcherPartnerDataSourceProvider =
    Provider<DispatcherPartnerRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return DispatcherPartnerRemoteDataSource(client);
});

/// Cache-first passenger profile provider
final dispatcherPassengerProfileProvider = FutureProvider.autoDispose
    .family<DispatcherPassengerProfile?, int>((ref, passengerId) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;

  if (userId == 0) return null;

  final key = DispatcherCacheKeys.passengerProfile(
    userId: userId,
    passengerId: passengerId,
  );

  // 1) Cache-first
  final cached = await cache.get<Map<String, dynamic>>(key);
  if (cached != null) {
    final profile = DispatcherPassengerProfile.fromJson(
      Map<String, dynamic>.from(cached),
    );
    if (!isOnline) return profile;
    return profile;
  }

  // 2) No cache: fetch if possible
  if (!isOnline) return null;
  final ds = ref.watch(dispatcherPartnerDataSourceProvider);
  if (ds == null) return null;

  final profile = await ds.getPassengerById(passengerId);
  if (profile != null) {
    await cache.save(
      key: key,
      data: profile.toJson(),
      ttl: const Duration(minutes: 5),
    );
  }
  return profile;
});

/// Provider to fetch multiple passenger profiles at once (batch fetch)
/// This avoids the dispose issue when fetching profiles in a loop
final dispatcherPassengerProfilesBatchProvider = FutureProvider.autoDispose
    .family<Map<int, DispatcherPassengerProfile>, List<int>>((
  ref,
  passengerIds,
) async {
  if (passengerIds.isEmpty) return {};

  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
  final ds = ref.watch(dispatcherPartnerDataSourceProvider);

  if (userId == 0) return {};

  final profiles = <int, DispatcherPassengerProfile>{};
  final missingIds = <int>[];

  // 1) Check cache for each passenger
  for (final passengerId in passengerIds) {
    final key = DispatcherCacheKeys.passengerProfile(
      userId: userId,
      passengerId: passengerId,
    );
    final cached = await cache.get<Map<String, dynamic>>(key);
    if (cached != null) {
      profiles[passengerId] = DispatcherPassengerProfile.fromJson(
        Map<String, dynamic>.from(cached),
      );
    } else {
      missingIds.add(passengerId);
    }
  }

  // 2) Fetch missing profiles from server in batch
  if (missingIds.isNotEmpty && isOnline && ds != null) {
    try {
      final fetchedProfiles = await ds.getPassengersByIds(missingIds);

      // Cache the fetched profiles
      for (final entry in fetchedProfiles.entries) {
        final key = DispatcherCacheKeys.passengerProfile(
          userId: userId,
          passengerId: entry.key,
        );
        await cache.save(
          key: key,
          data: entry.value.toJson(),
          ttl: const Duration(minutes: 5),
        );
        profiles[entry.key] = entry.value;
      }
    } catch (e) {
      // Ignore errors and return what we have from cache
    }
  }

  return profiles;
});

/// Provider to pre-load ALL passenger profiles for offline map usage
/// This fetches all passengers and caches them locally for future use
final dispatcherAllPassengerProfilesProvider = FutureProvider.autoDispose<
    Map<int, DispatcherPassengerProfile>>((ref) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
  final ds = ref.watch(dispatcherPartnerDataSourceProvider);

  if (userId == 0) return {};

  final cacheKey = DispatcherCacheKeys.allPassengerProfiles(userId: userId);

  // 1) Check cache first
  final cached = await cache.get<List<dynamic>>(cacheKey);
  if (cached != null) {
    final profiles = <int, DispatcherPassengerProfile>{};
    for (final item in cached) {
      final profile = DispatcherPassengerProfile.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      profiles[profile.id] = profile;
    }
    // If offline, return cached data
    if (!isOnline) return profiles;
    // If online, return cached but also refresh in background
    return profiles;
  }

  // 2) No cache and offline: return empty
  if (!isOnline || ds == null) return {};

  // 3) Fetch all passengers from server
  try {
    final allProfiles = await ds.getAllPassengersWithCoordinates();

    // Save to cache
    final profilesList = allProfiles.map((p) => p.toJson()).toList();
    await cache.save(
      key: cacheKey,
      data: profilesList,
      ttl: const Duration(hours: 24), // Cache for 24 hours
    );

    // Also cache individual profiles
    for (final profile in allProfiles) {
      final key = DispatcherCacheKeys.passengerProfile(
        userId: userId,
        passengerId: profile.id,
      );
      await cache.save(
        key: key,
        data: profile.toJson(),
        ttl: const Duration(hours: 24),
      );
    }

    final profiles = <int, DispatcherPassengerProfile>{};
    for (final profile in allProfiles) {
      profiles[profile.id] = profile;
    }
    return profiles;
  } catch (e) {
    return {};
  }
});

class DispatcherPartnerActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  DispatcherPartnerRemoteDataSource? get _ds =>
      ref.read(dispatcherPartnerDataSourceProvider);

  Future<int?> createPassenger({
    required String name,
    String? phone,
    String? mobile,
    String? guardianPhone,
    String? guardianEmail,
    String? street,
    String? city,
    String? notes,
    double? latitude,
    double? longitude,
    bool useGpsForPickup = true,
    bool useGpsForDropoff = true,
    String tripDirection = 'both',
    bool autoNotification = true,
  }) async {
    final ds = _ds;
    if (ds == null) return null;

    state = const AsyncValue.loading();
    try {
      final id = await ds.createPassenger(
        name: name,
        phone: phone,
        mobile: mobile,
        guardianPhone: guardianPhone,
        guardianEmail: guardianEmail,
        street: street,
        city: city,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
        useGpsForPickup: useGpsForPickup,
        useGpsForDropoff: useGpsForDropoff,
        tripDirection: tripDirection,
        autoNotification: autoNotification,
      );

      // Ensure the backend created an unassigned line for the passenger.
      final passengerDs = ref.read(dispatcherPassengerDataSourceProvider);
      await passengerDs?.syncUnassignedPassengers();

      // Clear caches
      await _clearAllPassengerCaches();

      ref.invalidate(dispatcherUnassignedPassengersProvider);
      ref.invalidate(dispatcherAllPassengersProvider);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updatePassenger({
    required int passengerId,
    String? name,
    String? phone,
    String? mobile,
    String? guardianPhone,
    String? guardianEmail,
    String? street,
    String? street2,
    String? city,
    String? zip,
    String? notes,
    double? latitude,
    double? longitude,
    bool? useGpsForPickup,
    bool? useGpsForDropoff,
    String? tripDirection,
    bool? autoNotification,
    bool? active,
  }) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.updatePassenger(
        passengerId: passengerId,
        name: name,
        phone: phone,
        mobile: mobile,
        guardianPhone: guardianPhone,
        guardianEmail: guardianEmail,
        street: street,
        street2: street2,
        city: city,
        zip: zip,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
        useGpsForPickup: useGpsForPickup,
        useGpsForDropoff: useGpsForDropoff,
        tripDirection: tripDirection,
        autoNotification: autoNotification,
        active: active,
      );

      // Clear caches
      await _clearPassengerCache(passengerId);

      ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
      ref.invalidate(dispatcherUnassignedPassengersProvider);
      ref.invalidate(dispatcherAllPassengersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePassenger(int passengerId) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.deletePassenger(passengerId);

      // Clear all caches (including profile and lists)
      await _clearPassengerCache(passengerId);

      ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
      ref.invalidate(dispatcherUnassignedPassengersProvider);
      ref.invalidate(dispatcherAllPassengersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update temporary location for a passenger (quick action)
  Future<void> updateTemporaryLocation({
    required int passengerId,
    String? temporaryAddress,
    double? temporaryLatitude,
    double? temporaryLongitude,
    String? temporaryContactName,
    String? temporaryContactPhone,
  }) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.updateTemporaryLocation(
        passengerId: passengerId,
        temporaryAddress: temporaryAddress,
        temporaryLatitude: temporaryLatitude,
        temporaryLongitude: temporaryLongitude,
        temporaryContactName: temporaryContactName,
        temporaryContactPhone: temporaryContactPhone,
      );

      await _clearPassengerCache(passengerId);
      ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clear temporary location for a passenger
  Future<void> clearTemporaryLocation(int passengerId) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.clearTemporaryLocation(passengerId);

      await _clearPassengerCache(passengerId);
      ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update guardian information
  Future<void> updateGuardianInfo({
    required int passengerId,
    bool? hasGuardian,
    String? fatherName,
    String? fatherPhone,
    String? motherName,
    String? motherPhone,
  }) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.updateGuardianInfo(
        passengerId: passengerId,
        hasGuardian: hasGuardian,
        fatherName: fatherName,
        fatherPhone: fatherPhone,
        motherName: motherName,
        motherPhone: motherPhone,
      );

      await _clearPassengerCache(passengerId);
      ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Helper to clear passenger cache
  Future<void> _clearPassengerCache(int passengerId) async {
    final cache = ref.read(dispatcherCacheDataSourceProvider);
    final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
    if (userId != 0) {
      // Clear specific passenger profile
      await cache.delete(
        DispatcherCacheKeys.passengerProfile(
          userId: userId,
          passengerId: passengerId,
        ),
      );
      // Clear all passengers list
      await cache.delete(
        DispatcherCacheKeys.allPassengers(userId: userId),
      );
      // Clear unassigned passengers list
      await cache.delete(
        DispatcherCacheKeys.unassignedPassengers(userId: userId),
      );
    }
  }

  /// Helper to clear all passenger-related caches (for create/delete)
  Future<void> _clearAllPassengerCaches() async {
    final cache = ref.read(dispatcherCacheDataSourceProvider);
    final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
    if (userId != 0) {
      await cache.delete(DispatcherCacheKeys.allPassengers(userId: userId));
      await cache
          .delete(DispatcherCacheKeys.unassignedPassengers(userId: userId));
    }
  }
}

final dispatcherPartnerActionsProvider =
    NotifierProvider<DispatcherPartnerActionsNotifier, AsyncValue<void>>(() {
  return DispatcherPartnerActionsNotifier();
});
