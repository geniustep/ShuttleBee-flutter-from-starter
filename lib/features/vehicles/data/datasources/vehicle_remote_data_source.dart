import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/shuttle_vehicle.dart';
import 'fleet_remote_data_source.dart';

/// معلومات إنشاء المركبة الكاملة
class CreateVehicleData {
  // === بيانات الموديل (إذا كان موديل جديد) ===
  final int? existingModelId;
  final String? newModelName;
  final int? brandId;
  final String? vehicleType;
  final String? fuelType;

  // === بيانات fleet.vehicle ===
  final String licensePlate;
  final int? driverId;
  final int seats;

  // === بيانات shuttle.vehicle ===
  final String name;
  final String? homeAddress;
  final double? homeLatitude;
  final double? homeLongitude;
  final String? note;
  final bool active;

  const CreateVehicleData({
    // موديل موجود أو جديد
    this.existingModelId,
    this.newModelName,
    this.brandId,
    this.vehicleType,
    this.fuelType,
    // fleet.vehicle
    required this.licensePlate,
    this.driverId,
    required this.seats,
    // shuttle.vehicle
    required this.name,
    this.homeAddress,
    this.homeLatitude,
    this.homeLongitude,
    this.note,
    this.active = true,
  });

  /// هل يحتاج إنشاء موديل جديد؟
  bool get needsNewModel =>
      existingModelId == null && newModelName != null && brandId != null;
}

/// Vehicle Remote Data Source - مصدر بيانات المركبات
class VehicleRemoteDataSource {
  final BridgecoreClient _client;
  late final FleetRemoteDataSource _fleetDataSource;

  static const String _vehicleModel = 'shuttle.vehicle';

  VehicleRemoteDataSource(this._client) {
    _fleetDataSource = FleetRemoteDataSource(_client);
  }

  /// الحصول على جميع المركبات
  Future<List<ShuttleVehicle>> getVehicles({
    bool activeOnly = true,
    int? limit,
    int? offset,
  }) async {
    final domain = <List<dynamic>>[];

    if (activeOnly) {
      domain.add(['active', '=', true]);
    }

    final result = await _client.searchRead(
      model: _vehicleModel,
      domain: domain,
      fields: _vehicleFields,
      order: 'name asc',
      limit: limit,
      offset: offset,
    );

    return result.map((json) => ShuttleVehicle.fromOdoo(json)).toList();
  }

  /// الحصول على مركبة بالمعرف
  Future<ShuttleVehicle?> getVehicleById(int vehicleId) async {
    final result = await _client.searchRead(
      model: _vehicleModel,
      domain: [
        ['id', '=', vehicleId],
      ],
      fields: _vehicleFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ShuttleVehicle.fromOdoo(result.first);
  }

  /// البحث عن مركبات
  Future<List<ShuttleVehicle>> searchVehicles(String query) async {
    final result = await _client.searchRead(
      model: _vehicleModel,
      domain: [
        '|',
        '|',
        ['name', 'ilike', query],
        ['license_plate', 'ilike', query],
        ['driver_id.name', 'ilike', query],
      ],
      fields: _vehicleFields,
      order: 'name asc',
      limit: 20,
    );

    return result.map((json) => ShuttleVehicle.fromOdoo(json)).toList();
  }

  /// الحصول على المركبات المتاحة
  Future<List<ShuttleVehicle>> getAvailableVehicles() async {
    // المركبات النشطة التي ليس لديها رحلة جارية
    final result = await _client.searchRead(
      model: _vehicleModel,
      domain: [
        ['active', '=', true],
      ],
      fields: _vehicleFields,
      order: 'name asc',
    );

    return result.map((json) => ShuttleVehicle.fromOdoo(json)).toList();
  }

  /// الحصول على مركبات سائق معين
  Future<List<ShuttleVehicle>> getDriverVehicles(int driverId) async {
    final result = await _client.searchRead(
      model: _vehicleModel,
      domain: [
        ['driver_id', '=', driverId],
        ['active', '=', true],
      ],
      fields: _vehicleFields,
      order: 'name asc',
    );

    return result.map((json) => ShuttleVehicle.fromOdoo(json)).toList();
  }

  /// إنشاء مركبة جديدة (الطريقة القديمة - تتطلب fleet_vehicle_id موجود)
  Future<ShuttleVehicle> createVehicle(ShuttleVehicle vehicle) async {
    final id = await _client.create(
      model: _vehicleModel,
      values: vehicle.toOdoo(),
    );

    final created = await getVehicleById(id);
    if (created == null) throw Exception('Failed to create vehicle');
    return created;
  }

  /// إنشاء مركبة كاملة - تُنشئ fleet.vehicle.model (إذا لزم) + fleet.vehicle + shuttle.vehicle
  /// هذه الطريقة تقوم بكل العمل في خطوة واحدة من وجهة نظر المستخدم
  Future<ShuttleVehicle> createFullVehicle(CreateVehicleData data) async {
    int modelId;

    // الخطوة 1: إنشاء موديل جديد إذا لزم الأمر
    if (data.needsNewModel) {
      final newModel = await _fleetDataSource.createVehicleModel(
        name: data.newModelName!,
        brandId: data.brandId!,
        vehicleType: data.vehicleType,
        fuelType: data.fuelType,
        seats: data.seats,
      );
      modelId = newModel.id;
    } else if (data.existingModelId != null) {
      modelId = data.existingModelId!;
    } else {
      throw Exception('يجب تحديد موديل موجود أو إنشاء موديل جديد');
    }

    // الخطوة 2: إنشاء fleet.vehicle
    final fleetVehicle = await _fleetDataSource.createFleetVehicle(
      modelId: modelId,
      licensePlate: data.licensePlate,
      driverId: data.driverId,
      fuelType: data.fuelType,
    );

    // الخطوة 3: إنشاء shuttle.vehicle مع ربطه بـ fleet.vehicle
    final shuttleVehicle = ShuttleVehicle(
      id: 0,
      name: data.name,
      fleetVehicleId: fleetVehicle.id,
      licensePlate: data.licensePlate,
      seatCapacity: data.seats,
      driverId: data.driverId,
      active: data.active,
      note: data.note,
      homeAddress: data.homeAddress,
      homeLatitude: data.homeLatitude,
      homeLongitude: data.homeLongitude,
    );

    return await createVehicle(shuttleVehicle);
  }

  /// الحصول على FleetRemoteDataSource للوصول إلى بيانات Fleet
  FleetRemoteDataSource get fleetDataSource => _fleetDataSource;

  /// تحديث مركبة
  Future<ShuttleVehicle> updateVehicle(ShuttleVehicle vehicle) async {
    await _client.write(
      model: _vehicleModel,
      ids: [vehicle.id],
      values: vehicle.toOdoo(),
    );

    final updated = await getVehicleById(vehicle.id);
    if (updated == null) throw Exception('Failed to update vehicle');
    return updated;
  }

  /// حذف مركبة
  Future<bool> deleteVehicle(int vehicleId) async {
    return await _client.unlink(
      model: _vehicleModel,
      ids: [vehicleId],
    );
  }

  /// عدد المركبات
  Future<int> getVehicleCount({bool activeOnly = true}) async {
    final domain = <List<dynamic>>[];
    if (activeOnly) {
      domain.add(['active', '=', true]);
    }

    return await _client.searchCount(
      model: _vehicleModel,
      domain: domain,
    );
  }

  /// إحصائيات المركبات
  Future<VehicleStats> getVehicleStats() async {
    try {
      final result = await _client.callKw(
        model: _vehicleModel,
        method: 'get_vehicle_stats',
        args: [],
      );

      if (result is Map<String, dynamic>) {
        return VehicleStats.fromJson(result);
      }
    } catch (e) {
      // Fallback: حساب الإحصائيات محلياً
    }

    final vehicles = await getVehicles();
    final activeVehicles = vehicles.where((v) => v.active).toList();
    final totalCapacity =
        activeVehicles.fold<int>(0, (sum, v) => sum + v.seatCapacity);

    return VehicleStats(
      totalVehicles: vehicles.length,
      activeVehicles: activeVehicles.length,
      totalCapacity: totalCapacity,
      vehiclesWithDriver: activeVehicles.where((v) => v.hasDriver).length,
    );
  }

  /// الحقول المطلوبة
  static const List<String> _vehicleFields = [
    'id',
    'name',
    'fleet_vehicle_id',
    'license_plate',
    'seat_capacity',
    'driver_id',
    'color',
    'active',
    'note',
    'company_id',
    'trip_ids',
    'home_latitude',
    'home_longitude',
    'home_address',
  ];
}

/// إحصائيات المركبات
class VehicleStats {
  final int totalVehicles;
  final int activeVehicles;
  final int totalCapacity;
  final int vehiclesWithDriver;
  final int vehiclesOnTrip;

  const VehicleStats({
    this.totalVehicles = 0,
    this.activeVehicles = 0,
    this.totalCapacity = 0,
    this.vehiclesWithDriver = 0,
    this.vehiclesOnTrip = 0,
  });

  factory VehicleStats.fromJson(Map<String, dynamic> json) {
    return VehicleStats(
      totalVehicles: json['total_vehicles'] as int? ?? 0,
      activeVehicles: json['active_vehicles'] as int? ?? 0,
      totalCapacity: json['total_capacity'] as int? ?? 0,
      vehiclesWithDriver: json['vehicles_with_driver'] as int? ?? 0,
      vehiclesOnTrip: json['vehicles_on_trip'] as int? ?? 0,
    );
  }
}
