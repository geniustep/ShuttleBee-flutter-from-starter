import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../domain/entities/passenger_group.dart';

/// Group Data Source Provider
final groupDataSourceProvider = Provider<GroupRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return GroupRemoteDataSource(client);
});

/// جميع المجموعات
final allGroupsProvider =
    FutureProvider.autoDispose<List<PassengerGroup>>((ref) async {
  final dataSource = ref.watch(groupDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getGroups();
});

/// مجموعة محددة مع الجداول والعطلات
final groupByIdProvider = FutureProvider.autoDispose
    .family<PassengerGroup?, int>((ref, groupId) async {
  final dataSource = ref.watch(groupDataSourceProvider);
  if (dataSource == null) return null;

  return await dataSource.getGroupById(groupId);
});

/// جداول مجموعة محددة
final groupSchedulesProvider = FutureProvider.autoDispose
    .family<List<GroupSchedule>, int>((ref, groupId) async {
  final dataSource = ref.watch(groupDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getGroupSchedules(groupId);
});

/// عطلات مجموعة محددة
final groupHolidaysProvider = FutureProvider.autoDispose
    .family<List<GroupHoliday>, int>((ref, groupId) async {
  final dataSource = ref.watch(groupDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getGroupHolidays(groupId);
});

/// البحث عن مجموعات
final groupSearchProvider = FutureProvider.autoDispose
    .family<List<PassengerGroup>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final dataSource = ref.watch(groupDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.searchGroups(query);
});

/// عدد المجموعات
final groupCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dataSource = ref.watch(groupDataSourceProvider);
  if (dataSource == null) return 0;

  return await dataSource.getGroupCount();
});

/// Group Actions Notifier
class GroupActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  GroupRemoteDataSource? get _dataSource => ref.read(groupDataSourceProvider);

  /// إنشاء مجموعة جديدة
  Future<PassengerGroup?> createGroup(PassengerGroup group) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final created = await dataSource.createGroup(group);
      state = const AsyncValue.data(null);
      ref.invalidate(allGroupsProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// تحديث مجموعة
  Future<PassengerGroup?> updateGroup(PassengerGroup group) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final updated = await dataSource.updateGroup(group);
      state = const AsyncValue.data(null);
      ref.invalidate(allGroupsProvider);
      ref.invalidate(groupByIdProvider(group.id));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// حذف مجموعة
  Future<bool> deleteGroup(int groupId) async {
    final dataSource = _dataSource;
    if (dataSource == null) return false;

    state = const AsyncValue.loading();

    try {
      final success = await dataSource.deleteGroup(groupId);
      state = const AsyncValue.data(null);
      if (success) {
        ref.invalidate(allGroupsProvider);
      }
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// إنشاء جدول
  Future<GroupSchedule?> createSchedule({
    required int groupId,
    required Weekday weekday,
    DateTime? pickupTime,
    DateTime? dropoffTime,
    bool createPickup = true,
    bool createDropoff = true,
  }) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    try {
      final schedule = await dataSource.createSchedule(
        groupId: groupId,
        weekday: weekday,
        pickupTime: pickupTime,
        dropoffTime: dropoffTime,
        createPickup: createPickup,
        createDropoff: createDropoff,
      );

      ref.invalidate(groupSchedulesProvider(groupId));
      ref.invalidate(groupByIdProvider(groupId));
      return schedule;
    } catch (e) {
      return null;
    }
  }

  /// حذف جدول
  Future<bool> deleteSchedule(int scheduleId, int groupId) async {
    final dataSource = _dataSource;
    if (dataSource == null) return false;

    try {
      final success = await dataSource.deleteSchedule(scheduleId);
      if (success) {
        ref.invalidate(groupSchedulesProvider(groupId));
        ref.invalidate(groupByIdProvider(groupId));
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// إنشاء عطلة
  Future<GroupHoliday?> createHoliday({
    required int groupId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    try {
      final holiday = await dataSource.createHoliday(
        groupId: groupId,
        name: name,
        startDate: startDate,
        endDate: endDate,
      );

      ref.invalidate(groupHolidaysProvider(groupId));
      ref.invalidate(groupByIdProvider(groupId));
      return holiday;
    } catch (e) {
      return null;
    }
  }

  /// حذف عطلة
  Future<bool> deleteHoliday(int holidayId, int groupId) async {
    final dataSource = _dataSource;
    if (dataSource == null) return false;

    try {
      final success = await dataSource.deleteHoliday(holidayId);
      if (success) {
        ref.invalidate(groupHolidaysProvider(groupId));
        ref.invalidate(groupByIdProvider(groupId));
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// توليد رحلات من الجدول
  Future<int> generateTrips(int groupId, {int weeks = 1}) async {
    final dataSource = _dataSource;
    if (dataSource == null) return 0;

    state = const AsyncValue.loading();

    try {
      final count =
          await dataSource.generateTripsFromSchedule(groupId, weeks: weeks);
      state = const AsyncValue.data(null);
      return count;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }
}

/// Group Actions Provider
final groupActionsProvider =
    NotifierProvider<GroupActionsNotifier, AsyncValue<void>>(() {
  return GroupActionsNotifier();
});

