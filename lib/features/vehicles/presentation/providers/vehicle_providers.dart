import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/vehicle_remote_data_source.dart';
import '../../domain/entities/shuttle_vehicle.dart';

export '../../data/datasources/vehicle_remote_data_source.dart'
    show CreateVehicleData;

/// Vehicle Data Source Provider
final vehicleDataSourceProvider = Provider<VehicleRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return VehicleRemoteDataSource(client);
});

/// جميع المركبات
final allVehiclesProvider =
    FutureProvider.autoDispose<List<ShuttleVehicle>>((ref) async {
  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getVehicles();
});

/// المركبات المتاحة
final availableVehiclesProvider =
    FutureProvider.autoDispose<List<ShuttleVehicle>>((ref) async {
  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getAvailableVehicles();
});

/// مركبة محددة
final vehicleByIdProvider = FutureProvider.autoDispose
    .family<ShuttleVehicle?, int>((ref, vehicleId) async {
  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return null;

  return await dataSource.getVehicleById(vehicleId);
});

/// مركبات سائق محدد
final driverVehiclesProvider = FutureProvider.autoDispose
    .family<List<ShuttleVehicle>, int>((ref, driverId) async {
  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getDriverVehicles(driverId);
});

/// البحث عن مركبات
final vehicleSearchProvider = FutureProvider.autoDispose
    .family<List<ShuttleVehicle>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.searchVehicles(query);
});

/// إحصائيات المركبات
final vehicleStatsProvider =
    FutureProvider.autoDispose<VehicleStats>((ref) async {
  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return const VehicleStats();

  return await dataSource.getVehicleStats();
});

/// عدد المركبات
final vehicleCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dataSource = ref.watch(vehicleDataSourceProvider);
  if (dataSource == null) return 0;

  return await dataSource.getVehicleCount();
});

/// Vehicle Actions Notifier
class VehicleActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  VehicleRemoteDataSource? get _dataSource =>
      ref.read(vehicleDataSourceProvider);

  /// إنشاء مركبة جديدة (الطريقة القديمة - تتطلب fleet_vehicle_id)
  Future<ShuttleVehicle?> createVehicle(ShuttleVehicle vehicle) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final created = await dataSource.createVehicle(vehicle);
      state = const AsyncValue.data(null);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(vehicleStatsProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// إنشاء مركبة كاملة - تُنشئ fleet.vehicle.model + fleet.vehicle + shuttle.vehicle
  Future<ShuttleVehicle?> createFullVehicle(CreateVehicleData data) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final created = await dataSource.createFullVehicle(data);
      state = const AsyncValue.data(null);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(vehicleStatsProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// تحديث مركبة
  Future<ShuttleVehicle?> updateVehicle(ShuttleVehicle vehicle) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final updated = await dataSource.updateVehicle(vehicle);
      state = const AsyncValue.data(null);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(vehicleByIdProvider(vehicle.id));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// حذف مركبة
  Future<bool> deleteVehicle(int vehicleId) async {
    final dataSource = _dataSource;
    if (dataSource == null) return false;

    state = const AsyncValue.loading();

    try {
      final success = await dataSource.deleteVehicle(vehicleId);
      state = const AsyncValue.data(null);
      if (success) {
        ref.invalidate(allVehiclesProvider);
        ref.invalidate(vehicleStatsProvider);
      }
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Vehicle Actions Provider
final vehicleActionsProvider =
    NotifierProvider<VehicleActionsNotifier, AsyncValue<void>>(() {
  return VehicleActionsNotifier();
});
