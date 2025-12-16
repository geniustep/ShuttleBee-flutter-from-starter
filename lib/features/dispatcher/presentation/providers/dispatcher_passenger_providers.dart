import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/dispatcher_passenger_remote_data_source.dart';
import '../../domain/entities/passenger_group_line.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import 'dispatcher_cached_providers.dart';

/// Passenger data source for dispatcher.
final dispatcherPassengerDataSourceProvider =
    Provider<DispatcherPassengerRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return DispatcherPassengerRemoteDataSource(client);
});

int _userId(Ref ref) => ref.read(authStateProvider).asData?.value.user?.id ?? 0;

List<PassengerGroupLine> _decodePassengerLines(dynamic cached) {
  final list = (cached as List<dynamic>).cast<dynamic>();
  return list
      .map((e) =>
          PassengerGroupLine.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Cache-first: Passengers of a group.
final dispatcherGroupPassengersProvider = FutureProvider.autoDispose
    .family<List<PassengerGroupLine>, int>((ref, groupId) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.groupPassengers(
    userId: userId,
    groupId: groupId,
  );

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final passengers = _decodePassengerLines(cached);
    if (!isOnline) return passengers;
    return passengers;
  }

  // 2) No cache: fetch if possible
  if (!isOnline) return [];
  final ds = ref.watch(dispatcherPassengerDataSourceProvider);
  if (ds == null) return [];

  final passengers = await ds.getGroupPassengers(groupId);
  await cache.save(
    key: key,
    data: passengers.map((p) => p.toJson()).toList(),
    ttl: const Duration(minutes: 5),
  );
  return passengers;
});

/// All group line records for a passenger (assigned + unassigned).
final dispatcherPassengerLinesProvider = FutureProvider.autoDispose
    .family<List<PassengerGroupLine>, int>((ref, passengerId) async {
  final ds = ref.watch(dispatcherPassengerDataSourceProvider);
  if (ds == null) return [];
  return ds.getPassengerLines(passengerId);
});

/// Cache-first: Unassigned passengers (backend uses group_id = false).
final dispatcherUnassignedPassengersProvider =
    FutureProvider.autoDispose<List<PassengerGroupLine>>((ref) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.unassignedPassengers(userId: userId);

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final passengers = _decodePassengerLines(cached);
    if (!isOnline) return passengers;
    return passengers;
  }

  // 2) No cache: fetch if possible
  if (!isOnline) return [];
  final ds = ref.watch(dispatcherPassengerDataSourceProvider);
  if (ds == null) return [];

  final passengers = await ds.getUnassignedPassengers();
  await cache.save(
    key: key,
    data: passengers.map((p) => p.toJson()).toList(),
    ttl: const Duration(minutes: 5),
  );
  return passengers;
});

/// Passengers that belong to groups other than [groupId].
final dispatcherPassengersInOtherGroupsProvider = FutureProvider.autoDispose
    .family<List<PassengerGroupLine>, int>((ref, groupId) async {
  final ds = ref.watch(dispatcherPassengerDataSourceProvider);
  if (ds == null) return [];
  return ds.getPassengersInOtherGroups(groupId);
});

/// Cache-first: All passengers (unassigned + from all groups).
final dispatcherAllPassengersProvider =
    FutureProvider.autoDispose<List<PassengerGroupLine>>((ref) async {
  final cache = ref.watch(dispatcherCacheDataSourceProvider);
  final isOnline = ref.watch(isOnlineStateProvider);
  final userId = _userId(ref);
  if (userId == 0) return [];

  final key = DispatcherCacheKeys.allPassengers(userId: userId);

  // 1) Cache-first
  final cached = await cache.get<List<dynamic>>(key);
  if (cached != null) {
    final passengers = _decodePassengerLines(cached);
    if (!isOnline) return passengers;
    return passengers;
  }

  // 2) No cache: fetch if possible
  if (!isOnline) return [];
  final ds = ref.watch(dispatcherPassengerDataSourceProvider);
  if (ds == null) return [];

  // Get unassigned passengers
  final unassigned = await ds.getUnassignedPassengers();

  // Get passengers from all groups (groupId = 0 means all groups)
  final assigned = await ds.getPassengersInOtherGroups(0);

  // Combine and deduplicate by passenger_id
  final Map<int, PassengerGroupLine> uniquePassengers = {};
  for (final line in unassigned) {
    if (!uniquePassengers.containsKey(line.passengerId)) {
      uniquePassengers[line.passengerId] = line;
    }
  }
  for (final line in assigned) {
    if (!uniquePassengers.containsKey(line.passengerId)) {
      uniquePassengers[line.passengerId] = line;
    }
  }

  final passengers = uniquePassengers.values.toList()
    ..sort((a, b) => a.passengerName.compareTo(b.passengerName));

  // Save to cache
  await cache.save(
    key: key,
    data: passengers.map((p) => p.toJson()).toList(),
    ttl: const Duration(minutes: 5),
  );

  return passengers;
});

class DispatcherPassengerActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  DispatcherPassengerRemoteDataSource? get _ds =>
      ref.read(dispatcherPassengerDataSourceProvider);

  /// Helper to clear passenger-related caches
  Future<void> _clearPassengerCaches({int? groupId, int? fromGroupId}) async {
    final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
    if (userId == 0) return;

    final cache = ref.read(dispatcherCacheDataSourceProvider);

    // Clear all passengers cache
    await cache.delete(DispatcherCacheKeys.allPassengers(userId: userId));

    // Clear unassigned passengers cache
    await cache
        .delete(DispatcherCacheKeys.unassignedPassengers(userId: userId));

    // Clear specific group caches
    if (groupId != null) {
      await cache.delete(DispatcherCacheKeys.groupPassengers(
        userId: userId,
        groupId: groupId,
      ));
    }
    if (fromGroupId != null && fromGroupId != groupId) {
      await cache.delete(DispatcherCacheKeys.groupPassengers(
        userId: userId,
        groupId: fromGroupId,
      ));
    }

    // Clear groups cache (for passenger counts)
    await cache.delete(DispatcherCacheKeys.groups(userId: userId));
  }

  Future<void> assignToGroup({
    required int lineId,
    required int groupId,
    int? fromGroupId,
  }) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.assignLineToGroup(lineId: lineId, groupId: groupId);
      state = const AsyncValue.data(null);

      // Clear caches
      await _clearPassengerCaches(groupId: groupId, fromGroupId: fromGroupId);

      // Refresh providers
      ref.invalidate(dispatcherGroupPassengersProvider(groupId));
      if (fromGroupId != null && fromGroupId != groupId) {
        ref.invalidate(dispatcherGroupPassengersProvider(fromGroupId));
      }
      ref.invalidate(dispatcherUnassignedPassengersProvider);
      ref.invalidate(dispatcherAllPassengersProvider);
      ref.invalidate(dispatcherPassengersInOtherGroupsProvider(groupId));
      if (fromGroupId != null && fromGroupId != groupId) {
        ref.invalidate(dispatcherPassengersInOtherGroupsProvider(fromGroupId));
      }
      ref.invalidate(dispatcherGroupsProvider);
      ref.invalidate(allGroupsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unassignFromGroup({
    required int lineId,
    required int groupId,
  }) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.unassignLine(lineId: lineId);
      state = const AsyncValue.data(null);

      // Clear caches
      await _clearPassengerCaches(groupId: groupId);

      // Refresh providers
      ref.invalidate(dispatcherGroupPassengersProvider(groupId));
      ref.invalidate(dispatcherUnassignedPassengersProvider);
      ref.invalidate(dispatcherAllPassengersProvider);
      ref.invalidate(dispatcherPassengersInOtherGroupsProvider(groupId));
      ref.invalidate(dispatcherGroupsProvider);
      ref.invalidate(allGroupsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLine({
    required int lineId,
    required int groupId,
    int? seatCount,
    int? sequence,
    String? notes,
  }) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.updateLine(
        lineId: lineId,
        seatCount: seatCount,
        sequence: sequence,
        notes: notes,
      );
      state = const AsyncValue.data(null);

      // Clear caches
      await _clearPassengerCaches(groupId: groupId);

      // Refresh providers
      ref.invalidate(dispatcherGroupPassengersProvider(groupId));
      ref.invalidate(dispatcherAllPassengersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLine({
    required int lineId,
    required int? groupId,
  }) async {
    final ds = _ds;
    if (ds == null) return;

    state = const AsyncValue.loading();
    try {
      await ds.deleteLine(lineId: lineId);
      state = const AsyncValue.data(null);

      // Clear caches
      await _clearPassengerCaches(groupId: groupId);

      // Refresh providers
      if (groupId != null) {
        ref.invalidate(dispatcherGroupPassengersProvider(groupId));
      }
      ref.invalidate(dispatcherUnassignedPassengersProvider);
      ref.invalidate(dispatcherAllPassengersProvider);
      ref.invalidate(dispatcherGroupsProvider);
      ref.invalidate(allGroupsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dispatcherPassengerActionsProvider =
    NotifierProvider<DispatcherPassengerActionsNotifier, AsyncValue<void>>(() {
  return DispatcherPassengerActionsNotifier();
});
