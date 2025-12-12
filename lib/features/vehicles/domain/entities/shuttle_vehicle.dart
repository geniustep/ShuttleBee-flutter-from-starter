/// ShuttleBee Vehicle Entity - كيان المركبة
/// يطابق نموذج shuttle.vehicle في Odoo
class ShuttleVehicle {
  final int id;
  final String name;
  final int? fleetVehicleId;
  final String? fleetVehicleName;
  final String? licensePlate;
  final int seatCapacity;
  final int? driverId;
  final String? driverName;
  final int color;
  final bool active;
  final String? note;
  final int? companyId;
  final String? companyName;
  final int tripCount;
  final double? homeLatitude;
  final double? homeLongitude;
  final String? homeAddress;

  const ShuttleVehicle({
    required this.id,
    required this.name,
    this.fleetVehicleId,
    this.fleetVehicleName,
    this.licensePlate,
    this.seatCapacity = 12,
    this.driverId,
    this.driverName,
    this.color = 0,
    this.active = true,
    this.note,
    this.companyId,
    this.companyName,
    this.tripCount = 0,
    this.homeLatitude,
    this.homeLongitude,
    this.homeAddress,
  });

  factory ShuttleVehicle.fromOdoo(Map<String, dynamic> json) {
    return ShuttleVehicle(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      fleetVehicleId: _extractId(json['fleet_vehicle_id']),
      fleetVehicleName: _extractName(json['fleet_vehicle_id']),
      licensePlate: _extractString(json['license_plate']),
      seatCapacity: json['seat_capacity'] as int? ?? 12,
      driverId: _extractId(json['driver_id']),
      driverName: _extractName(json['driver_id']),
      color: json['color'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      note: _extractString(json['note']),
      companyId: _extractId(json['company_id']),
      companyName: _extractName(json['company_id']),
      tripCount: (json['trip_ids'] as List?)?.length ?? 0,
      homeLatitude: _extractDouble(json['home_latitude']),
      homeLongitude: _extractDouble(json['home_longitude']),
      homeAddress: _extractString(json['home_address']),
    );
  }

  Map<String, dynamic> toOdoo() {
    return {
      'name': name,
      if (fleetVehicleId != null) 'fleet_vehicle_id': fleetVehicleId,
      'seat_capacity': seatCapacity,
      if (driverId != null) 'driver_id': driverId,
      'active': active,
      if (note != null) 'note': note,
      if (homeLatitude != null) 'home_latitude': homeLatitude,
      if (homeLongitude != null) 'home_longitude': homeLongitude,
      if (homeAddress != null) 'home_address': homeAddress,
    };
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

  static String? _extractName(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    if (value is List && value.length > 1) return value[1] as String?;
    return null;
  }

  static double? _extractDouble(dynamic value) {
    if (value == null || value == false) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// اسم العرض مع لوحة الترخيص
  String get displayName {
    if (licensePlate != null && licensePlate!.isNotEmpty) {
      return '$name ($licensePlate)';
    }
    return name;
  }

  /// هل لديه سائق معين
  bool get hasDriver => driverId != null;

  /// هل لديه موقع موقف محدد
  bool get hasParkingLocation =>
      homeLatitude != null && homeLongitude != null;

  ShuttleVehicle copyWith({
    int? id,
    String? name,
    int? fleetVehicleId,
    String? fleetVehicleName,
    String? licensePlate,
    int? seatCapacity,
    int? driverId,
    String? driverName,
    int? color,
    bool? active,
    String? note,
    int? companyId,
    String? companyName,
    int? tripCount,
    double? homeLatitude,
    double? homeLongitude,
    String? homeAddress,
  }) {
    return ShuttleVehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      fleetVehicleId: fleetVehicleId ?? this.fleetVehicleId,
      fleetVehicleName: fleetVehicleName ?? this.fleetVehicleName,
      licensePlate: licensePlate ?? this.licensePlate,
      seatCapacity: seatCapacity ?? this.seatCapacity,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      color: color ?? this.color,
      active: active ?? this.active,
      note: note ?? this.note,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      tripCount: tripCount ?? this.tripCount,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      homeAddress: homeAddress ?? this.homeAddress,
    );
  }

  @override
  String toString() =>
      'ShuttleVehicle(id: $id, name: $name, plate: $licensePlate)';
}

