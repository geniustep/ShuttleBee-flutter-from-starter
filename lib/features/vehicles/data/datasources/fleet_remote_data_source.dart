import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/fleet_brand.dart';
import '../../domain/entities/fleet_vehicle.dart';
import '../../domain/entities/fleet_vehicle_model.dart';

/// خيار السائق للاختيار في القوائم
class DriverOption {
  final int id;
  final String name;
  final String? login;
  final int? partnerId;

  const DriverOption({
    required this.id,
    required this.name,
    this.login,
    this.partnerId,
  });

  factory DriverOption.fromOdoo(Map<String, dynamic> json) {
    return DriverOption(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      login: _extractString(json['login']),
      partnerId: _extractId(json['partner_id']),
    );
  }

  static String? _extractString(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int? _extractId(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) return value[0] as int?;
    return null;
  }

  @override
  String toString() => 'DriverOption(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Fleet Remote Data Source - مصدر بيانات الأسطول
/// للتعامل مع موديلات fleet.vehicle و fleet.vehicle.model و fleet.vehicle.model.brand
class FleetRemoteDataSource {
  final BridgecoreClient _client;

  static const String _brandModel = 'fleet.vehicle.model.brand';
  static const String _vehicleModelModel = 'fleet.vehicle.model';
  static const String _fleetVehicleModel = 'fleet.vehicle';

  FleetRemoteDataSource(this._client);

  // ==================== Brands (المُصنّعين) ====================

  /// الحصول على جميع المُصنّعين
  Future<List<FleetBrand>> getBrands({int? limit}) async {
    final result = await _client.searchRead(
      model: _brandModel,
      domain: [],
      fields: _brandFields,
      order: 'name asc',
      limit: limit,
    );

    return result.map((json) => FleetBrand.fromOdoo(json)).toList();
  }

  /// البحث عن مُصنّع بالاسم
  Future<List<FleetBrand>> searchBrands(String query) async {
    final result = await _client.searchRead(
      model: _brandModel,
      domain: [
        ['name', 'ilike', query],
      ],
      fields: _brandFields,
      order: 'name asc',
      limit: 20,
    );

    return result.map((json) => FleetBrand.fromOdoo(json)).toList();
  }

  /// إنشاء مُصنّع جديد
  Future<FleetBrand> createBrand(String name) async {
    final id = await _client.create(
      model: _brandModel,
      values: {'name': name},
    );

    final result = await _client.searchRead(
      model: _brandModel,
      domain: [
        ['id', '=', id]
      ],
      fields: _brandFields,
      limit: 1,
    );

    if (result.isEmpty) throw Exception('Failed to create brand');
    return FleetBrand.fromOdoo(result.first);
  }

  // ==================== Vehicle Models (موديلات السيارات) ====================

  /// الحصول على جميع موديلات السيارات
  Future<List<FleetVehicleModel>> getVehicleModels({
    int? brandId,
    int? limit,
  }) async {
    final domain = <List<dynamic>>[];

    if (brandId != null) {
      domain.add(['brand_id', '=', brandId]);
    }

    final result = await _client.searchRead(
      model: _vehicleModelModel,
      domain: domain,
      fields: _vehicleModelFields,
      order: 'brand_id, name asc',
      limit: limit,
    );

    return result.map((json) => FleetVehicleModel.fromOdoo(json)).toList();
  }

  /// الحصول على موديل بالمعرف
  Future<FleetVehicleModel?> getVehicleModelById(int modelId) async {
    final result = await _client.searchRead(
      model: _vehicleModelModel,
      domain: [
        ['id', '=', modelId]
      ],
      fields: _vehicleModelFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return FleetVehicleModel.fromOdoo(result.first);
  }

  /// البحث عن موديلات بالاسم
  Future<List<FleetVehicleModel>> searchVehicleModels(String query) async {
    final result = await _client.searchRead(
      model: _vehicleModelModel,
      domain: [
        '|',
        ['name', 'ilike', query],
        ['brand_id.name', 'ilike', query],
      ],
      fields: _vehicleModelFields,
      order: 'brand_id, name asc',
      limit: 20,
    );

    return result.map((json) => FleetVehicleModel.fromOdoo(json)).toList();
  }

  /// إنشاء موديل سيارة جديد
  Future<FleetVehicleModel> createVehicleModel({
    required String name,
    required int brandId,
    String? vehicleType,
    String? fuelType,
    int seats = 5,
    int doors = 4,
  }) async {
    final values = {
      'name': name,
      'brand_id': brandId,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (fuelType != null) 'default_fuel_type': fuelType,
      'seats': seats,
      'doors': doors,
    };

    final id = await _client.create(
      model: _vehicleModelModel,
      values: values,
    );

    final created = await getVehicleModelById(id);
    if (created == null) throw Exception('Failed to create vehicle model');
    return created;
  }

  // ==================== Fleet Vehicles (سيارات الأسطول) ====================

  /// الحصول على جميع سيارات الأسطول
  Future<List<FleetVehicle>> getFleetVehicles({
    bool activeOnly = true,
    int? limit,
    int? offset,
  }) async {
    final domain = <List<dynamic>>[];

    if (activeOnly) {
      domain.add(['active', '=', true]);
    }

    final result = await _client.searchRead(
      model: _fleetVehicleModel,
      domain: domain,
      fields: _fleetVehicleFields,
      order: 'name asc',
      limit: limit,
      offset: offset,
    );

    return result.map((json) => FleetVehicle.fromOdoo(json)).toList();
  }

  /// الحصول على سيارة أسطول بالمعرف
  Future<FleetVehicle?> getFleetVehicleById(int vehicleId) async {
    final result = await _client.searchRead(
      model: _fleetVehicleModel,
      domain: [
        ['id', '=', vehicleId]
      ],
      fields: _fleetVehicleFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return FleetVehicle.fromOdoo(result.first);
  }

  /// البحث عن سيارات أسطول
  Future<List<FleetVehicle>> searchFleetVehicles(String query) async {
    final result = await _client.searchRead(
      model: _fleetVehicleModel,
      domain: [
        '|',
        '|',
        ['name', 'ilike', query],
        ['license_plate', 'ilike', query],
        ['model_id.name', 'ilike', query],
      ],
      fields: _fleetVehicleFields,
      order: 'name asc',
      limit: 20,
    );

    return result.map((json) => FleetVehicle.fromOdoo(json)).toList();
  }

  /// الحصول على سيارات الأسطول غير المرتبطة بـ shuttle.vehicle
  Future<List<FleetVehicle>> getUnlinkedFleetVehicles() async {
    // نبحث عن سيارات الأسطول التي ليست مرتبطة بأي shuttle.vehicle
    // هذا يتطلب استخدام method خاصة في Odoo أو domain معقد
    // كحل بسيط، سنجلب كل السيارات ونفلتر في التطبيق
    final result = await _client.searchRead(
      model: _fleetVehicleModel,
      domain: [
        ['active', '=', true],
      ],
      fields: _fleetVehicleFields,
      order: 'name asc',
    );

    return result.map((json) => FleetVehicle.fromOdoo(json)).toList();
  }

  /// إنشاء سيارة أسطول جديدة
  Future<FleetVehicle> createFleetVehicle({
    required int modelId,
    required String licensePlate,
    int? driverId,
    String? fuelType,
    String? color,
  }) async {
    final values = {
      'model_id': modelId,
      'license_plate': licensePlate,
      if (driverId != null) 'driver_id': driverId,
      if (fuelType != null) 'fuel_type': fuelType,
      if (color != null) 'color': color,
    };

    final id = await _client.create(
      model: _fleetVehicleModel,
      values: values,
    );

    final created = await getFleetVehicleById(id);
    if (created == null) throw Exception('Failed to create fleet vehicle');
    return created;
  }

  /// تحديث سيارة أسطول
  Future<FleetVehicle> updateFleetVehicle(FleetVehicle vehicle) async {
    await _client.write(
      model: _fleetVehicleModel,
      ids: [vehicle.id],
      values: vehicle.toOdoo(),
    );

    final updated = await getFleetVehicleById(vehicle.id);
    if (updated == null) throw Exception('Failed to update fleet vehicle');
    return updated;
  }

  // ==================== Drivers (السائقين) ====================

  /// الحصول على السائقين المتاحين من res.users
  /// السائقين هم المستخدمين الذين لديهم صلاحية السائق في ShuttleBee
  Future<List<DriverOption>> getAvailableDrivers() async {
    // نحصل على المستخدمين الذين لديهم group_driver
    // أو نحصل على كل المستخدمين النشطين كحل مبسط
    final result = await _client.searchRead(
      model: 'res.users',
      domain: [
        ['active', '=', true],
        ['share', '=', false], // ليس مستخدم بوابة
      ],
      fields: ['id', 'name', 'login', 'partner_id'],
      order: 'name asc',
      limit: 100,
    );

    return result.map((json) => DriverOption.fromOdoo(json)).toList();
  }

  /// البحث عن سائقين
  Future<List<DriverOption>> searchDrivers(String query) async {
    final result = await _client.searchRead(
      model: 'res.users',
      domain: [
        ['active', '=', true],
        ['share', '=', false],
        '|',
        ['name', 'ilike', query],
        ['login', 'ilike', query],
      ],
      fields: ['id', 'name', 'login', 'partner_id'],
      order: 'name asc',
      limit: 20,
    );

    return result.map((json) => DriverOption.fromOdoo(json)).toList();
  }

  // ==================== الحقول المطلوبة ====================

  static const List<String> _brandFields = [
    'id',
    'name',
    'image_128',
  ];

  static const List<String> _vehicleModelFields = [
    'id',
    'name',
    'brand_id',
    'vehicle_type',
    'default_fuel_type',
    'seats',
    'doors',
    'image_128',
  ];

  static const List<String> _fleetVehicleFields = [
    'id',
    'name',
    'model_id',
    'brand_id',
    'license_plate',
    'driver_id',
    'vehicle_type',
    'fuel_type',
    'seats',
    'doors',
    'color',
    'image_128',
    'active',
  ];
}
