import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/fleet_remote_data_source.dart';
import '../../domain/entities/fleet_brand.dart';
import '../../domain/entities/fleet_vehicle.dart';
import '../../domain/entities/fleet_vehicle_model.dart';

export '../../data/datasources/fleet_remote_data_source.dart' show DriverOption;

/// Fleet Data Source Provider
final fleetDataSourceProvider = Provider<FleetRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return FleetRemoteDataSource(client);
});

// ==================== Brands (المُصنّعين) ====================

/// جميع المُصنّعين
final allBrandsProvider =
    FutureProvider.autoDispose<List<FleetBrand>>((ref) async {
  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getBrands();
});

/// البحث عن مُصنّعين
final brandSearchProvider = FutureProvider.autoDispose
    .family<List<FleetBrand>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(allBrandsProvider).value ?? [];
  }

  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.searchBrands(query);
});

// ==================== Vehicle Models (موديلات السيارات) ====================

/// جميع موديلات السيارات
final allVehicleModelsProvider =
    FutureProvider.autoDispose<List<FleetVehicleModel>>((ref) async {
  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getVehicleModels();
});

/// موديلات السيارات حسب المُصنّع
final vehicleModelsByBrandProvider = FutureProvider.autoDispose
    .family<List<FleetVehicleModel>, int?>((ref, brandId) async {
  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getVehicleModels(brandId: brandId);
});

/// موديل سيارة محدد
final vehicleModelByIdProvider = FutureProvider.autoDispose
    .family<FleetVehicleModel?, int>((ref, modelId) async {
  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return null;

  return await dataSource.getVehicleModelById(modelId);
});

/// البحث عن موديلات سيارات
final vehicleModelSearchProvider = FutureProvider.autoDispose
    .family<List<FleetVehicleModel>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(allVehicleModelsProvider).value ?? [];
  }

  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.searchVehicleModels(query);
});

// ==================== Fleet Vehicles (سيارات الأسطول) ====================

/// جميع سيارات الأسطول
final allFleetVehiclesProvider =
    FutureProvider.autoDispose<List<FleetVehicle>>((ref) async {
  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getFleetVehicles();
});

/// سيارة أسطول محددة
final fleetVehicleByIdProvider = FutureProvider.autoDispose
    .family<FleetVehicle?, int>((ref, vehicleId) async {
  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return null;

  return await dataSource.getFleetVehicleById(vehicleId);
});

/// البحث عن سيارات أسطول
final fleetVehicleSearchProvider = FutureProvider.autoDispose
    .family<List<FleetVehicle>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(allFleetVehiclesProvider).value ?? [];
  }

  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.searchFleetVehicles(query);
});

// ==================== Drivers (السائقين) ====================

/// جميع السائقين المتاحين
final availableDriversProvider =
    FutureProvider.autoDispose<List<DriverOption>>((ref) async {
  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getAvailableDrivers();
});

/// البحث عن سائقين
final driverSearchProvider = FutureProvider.autoDispose
    .family<List<DriverOption>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(availableDriversProvider).value ?? [];
  }

  final dataSource = ref.watch(fleetDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.searchDrivers(query);
});

// ==================== Fleet Actions ====================

/// Fleet Actions Notifier
class FleetActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  FleetRemoteDataSource? get _dataSource => ref.read(fleetDataSourceProvider);

  /// إنشاء مُصنّع جديد
  Future<FleetBrand?> createBrand(String name) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final created = await dataSource.createBrand(name);
      state = const AsyncValue.data(null);
      ref.invalidate(allBrandsProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// إنشاء موديل سيارة جديد
  Future<FleetVehicleModel?> createVehicleModel({
    required String name,
    required int brandId,
    String? vehicleType,
    String? fuelType,
    int seats = 5,
    int doors = 4,
  }) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final created = await dataSource.createVehicleModel(
        name: name,
        brandId: brandId,
        vehicleType: vehicleType,
        fuelType: fuelType,
        seats: seats,
        doors: doors,
      );
      state = const AsyncValue.data(null);
      ref.invalidate(allVehicleModelsProvider);
      ref.invalidate(vehicleModelsByBrandProvider(brandId));
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// إنشاء سيارة أسطول جديدة
  Future<FleetVehicle?> createFleetVehicle({
    required int modelId,
    required String licensePlate,
    int? driverId,
    String? fuelType,
    String? color,
  }) async {
    final dataSource = _dataSource;
    if (dataSource == null) return null;

    state = const AsyncValue.loading();

    try {
      final created = await dataSource.createFleetVehicle(
        modelId: modelId,
        licensePlate: licensePlate,
        driverId: driverId,
        fuelType: fuelType,
        color: color,
      );
      state = const AsyncValue.data(null);
      ref.invalidate(allFleetVehiclesProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Fleet Actions Provider
final fleetActionsProvider =
    NotifierProvider<FleetActionsNotifier, AsyncValue<void>>(() {
  return FleetActionsNotifier();
});
