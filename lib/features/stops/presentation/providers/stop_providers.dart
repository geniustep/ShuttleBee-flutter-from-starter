import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/stop_remote_data_source.dart';
import '../../domain/entities/shuttle_stop.dart';

/// Stop Data Source Provider
final stopDataSourceProvider = Provider<StopRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return StopRemoteDataSource(client);
});

/// جميع نقاط التوقف
final allStopsProvider =
    FutureProvider.autoDispose<List<ShuttleStop>>((ref) async {
  final dataSource = ref.watch(stopDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getStops();
});

/// نقاط توقف الصعود
final pickupStopsProvider =
    FutureProvider.autoDispose<List<ShuttleStop>>((ref) async {
  final dataSource = ref.watch(stopDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getStops(stopType: StopType.pickup);
});

/// نقاط توقف النزول
final dropoffStopsProvider =
    FutureProvider.autoDispose<List<ShuttleStop>>((ref) async {
  final dataSource = ref.watch(stopDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getStops(stopType: StopType.dropoff);
});

/// نقطة توقف محددة
final stopByIdProvider =
    FutureProvider.autoDispose.family<ShuttleStop?, int>((ref, stopId) async {
  final dataSource = ref.watch(stopDataSourceProvider);
  if (dataSource == null) return null;

  return await dataSource.getStopById(stopId);
});

/// البحث عن نقاط التوقف
final stopSearchProvider = FutureProvider.autoDispose
    .family<List<ShuttleStop>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final dataSource = ref.watch(stopDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.searchStops(query);
});

/// اقتراحات نقاط التوقف القريبة
final nearestStopsProvider = FutureProvider.autoDispose
    .family<List<StopSuggestion>, ({double lat, double lng, StopType? type})>(
        (ref, params) async {
  final dataSource = ref.watch(stopDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.suggestNearestStops(
    latitude: params.lat,
    longitude: params.lng,
    stopType: params.type,
  );
});

/// عدد نقاط التوقف
final stopCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dataSource = ref.watch(stopDataSourceProvider);
  if (dataSource == null) return 0;

  return await dataSource.getStopCount();
});

/// Stop Actions Notifier
class StopActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  StopRemoteDataSource? get _dataSource => ref.read(stopDataSourceProvider);

  /// إنشاء نقطة توقف جديدة
  Future<ShuttleStop?> createStop(ShuttleStop stop) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final created = await dataSource.createStop(stop);
      state = const AsyncValue.data(null);
      ref.invalidate(allStopsProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// تحديث نقطة توقف
  Future<ShuttleStop?> updateStop(ShuttleStop stop) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final updated = await dataSource.updateStop(stop);
      state = const AsyncValue.data(null);
      ref.invalidate(allStopsProvider);
      ref.invalidate(stopByIdProvider(stop.id));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// حذف نقطة توقف
  Future<bool> deleteStop(int stopId) async {
    final dataSource = _dataSource;
    if (dataSource == null) return false;

    state = const AsyncValue.loading();

    try {
      final success = await dataSource.deleteStop(stopId);
      state = const AsyncValue.data(null);
      if (success) {
        ref.invalidate(allStopsProvider);
      }
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Stop Actions Provider
final stopActionsProvider =
    NotifierProvider<StopActionsNotifier, AsyncValue<void>>(() {
  return StopActionsNotifier();
});

