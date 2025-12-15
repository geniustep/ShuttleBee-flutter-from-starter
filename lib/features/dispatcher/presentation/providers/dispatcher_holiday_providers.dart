import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/dispatcher_holiday_remote_data_source.dart';
import '../../domain/entities/dispatcher_holiday.dart';

/// Holiday data source for dispatcher (global holidays).
final dispatcherHolidayDataSourceProvider =
    Provider<DispatcherHolidayRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return DispatcherHolidayRemoteDataSource(client);
});

/// Global holidays list.
final dispatcherHolidaysProvider = FutureProvider.autoDispose
    .family<List<DispatcherHoliday>, bool>((ref, activeOnly) async {
  final ds = ref.watch(dispatcherHolidayDataSourceProvider);
  if (ds == null) return [];
  return ds.getHolidays(activeOnly: activeOnly);
});

/// Single global holiday by id.
final dispatcherHolidayByIdProvider = FutureProvider.autoDispose
    .family<DispatcherHoliday?, int>((ref, holidayId) async {
  final ds = ref.watch(dispatcherHolidayDataSourceProvider);
  if (ds == null) return null;
  return ds.getHolidayById(holidayId);
});

class DispatcherHolidayActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  DispatcherHolidayRemoteDataSource? get _ds =>
      ref.read(dispatcherHolidayDataSourceProvider);

  Future<DispatcherHoliday?> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final ds = _ds;
    if (ds == null) return null;

    state = const AsyncValue.loading();
    try {
      final holiday = await ds.createHoliday(
        name: name,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      ref.invalidate(dispatcherHolidaysProvider(true));
      ref.invalidate(dispatcherHolidaysProvider(false));
      return holiday;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteHoliday(int holidayId) async {
    final ds = _ds;
    if (ds == null) return false;

    state = const AsyncValue.loading();
    try {
      final ok = await ds.deleteHoliday(holidayId);
      state = const AsyncValue.data(null);
      if (ok) {
        ref.invalidate(dispatcherHolidaysProvider(true));
        ref.invalidate(dispatcherHolidaysProvider(false));
      }
      return ok;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateHoliday({
    required int holidayId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    bool? active,
  }) async {
    final ds = _ds;
    if (ds == null) return false;

    state = const AsyncValue.loading();
    try {
      final ok = await ds.updateHoliday(
        holidayId: holidayId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        active: active,
      );
      state = const AsyncValue.data(null);
      if (ok) {
        ref.invalidate(dispatcherHolidaysProvider(true));
        ref.invalidate(dispatcherHolidaysProvider(false));
        ref.invalidate(dispatcherHolidayByIdProvider(holidayId));
      }
      return ok;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final dispatcherHolidayActionsProvider =
    NotifierProvider<DispatcherHolidayActionsNotifier, AsyncValue<void>>(() {
  return DispatcherHolidayActionsNotifier();
});
