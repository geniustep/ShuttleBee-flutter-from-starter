import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Passengers of a group.
final dispatcherGroupPassengersProvider = FutureProvider.autoDispose
    .family<List<PassengerGroupLine>, int>((ref, groupId) async {
  final ds = ref.watch(dispatcherPassengerDataSourceProvider);
  if (ds == null) return [];
  return ds.getGroupPassengers(groupId);
});

/// All group line records for a passenger (assigned + unassigned).
final dispatcherPassengerLinesProvider = FutureProvider.autoDispose
    .family<List<PassengerGroupLine>, int>((ref, passengerId) async {
  final ds = ref.watch(dispatcherPassengerDataSourceProvider);
  if (ds == null) return [];
  return ds.getPassengerLines(passengerId);
});

/// Unassigned passengers (backend uses group_id = false).
final dispatcherUnassignedPassengersProvider =
    FutureProvider.autoDispose<List<PassengerGroupLine>>((ref) async {
  final ds = ref.watch(dispatcherPassengerDataSourceProvider);
  if (ds == null) return [];
  return ds.getUnassignedPassengers();
});

class DispatcherPassengerActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  DispatcherPassengerRemoteDataSource? get _ds =>
      ref.read(dispatcherPassengerDataSourceProvider);

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

      // Refresh group passengers + unassigned list.
      ref.invalidate(dispatcherGroupPassengersProvider(groupId));
      if (fromGroupId != null && fromGroupId != groupId) {
        ref.invalidate(dispatcherGroupPassengersProvider(fromGroupId));
      }
      ref.invalidate(dispatcherUnassignedPassengersProvider);

      // Refresh group counts on lists.
      final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
      if (userId != 0) {
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        await cache.delete(DispatcherCacheKeys.groups(userId: userId));
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

      ref.invalidate(dispatcherGroupPassengersProvider(groupId));
      ref.invalidate(dispatcherUnassignedPassengersProvider);

      final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
      if (userId != 0) {
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        await cache.delete(DispatcherCacheKeys.groups(userId: userId));
      }
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

      ref.invalidate(dispatcherGroupPassengersProvider(groupId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dispatcherPassengerActionsProvider =
    NotifierProvider<DispatcherPassengerActionsNotifier, AsyncValue<void>>(() {
  return DispatcherPassengerActionsNotifier();
});
