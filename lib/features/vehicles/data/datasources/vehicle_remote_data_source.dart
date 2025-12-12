import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/shuttle_vehicle.dart';

/// Vehicle Remote Data Source - مصدر بيانات المركبات
class VehicleRemoteDataSource {
  final BridgecoreClient _client;

  static const String _vehicleModel = 'shuttle.vehicle';

  VehicleRemoteDataSource(this._client);

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
        ['id', '=', vehicleId]
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

  /// إنشاء مركبة جديدة
  Future<ShuttleVehicle> createVehicle(ShuttleVehicle vehicle) async {
    final id = await _client.create(
      model: _vehicleModel,
      values: vehicle.toOdoo(),
    );

    final created = await getVehicleById(id);
    if (created == null) throw Exception('Failed to create vehicle');
    return created;
  }

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

