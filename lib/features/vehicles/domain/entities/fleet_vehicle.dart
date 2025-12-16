/// Fleet Vehicle Entity - كيان سيارة الأسطول
/// يطابق نموذج fleet.vehicle في Odoo (Parc Automobile)
class FleetVehicle {
  final int id;
  final String name;
  final int? modelId;
  final String? modelName;
  final int? brandId;
  final String? brandName;
  final String? licensePlate;
  final int? driverId;
  final String? driverName;
  final String? vehicleType;
  final String? fuelType;
  final int seats;
  final int doors;
  final String? color;
  final String? image;
  final bool active;

  const FleetVehicle({
    required this.id,
    required this.name,
    this.modelId,
    this.modelName,
    this.brandId,
    this.brandName,
    this.licensePlate,
    this.driverId,
    this.driverName,
    this.vehicleType,
    this.fuelType,
    this.seats = 5,
    this.doors = 4,
    this.color,
    this.image,
    this.active = true,
  });

  factory FleetVehicle.fromOdoo(Map<String, dynamic> json) {
    return FleetVehicle(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      modelId: _extractId(json['model_id']),
      modelName: _extractName(json['model_id']),
      brandId: _extractId(json['brand_id']),
      brandName: _extractName(json['brand_id']),
      licensePlate: _extractString(json['license_plate']),
      driverId: _extractId(json['driver_id']),
      driverName: _extractName(json['driver_id']),
      vehicleType: _extractString(json['vehicle_type']),
      fuelType: _extractString(json['fuel_type']),
      seats: json['seats'] as int? ?? 5,
      doors: json['doors'] as int? ?? 4,
      color: _extractString(json['color']),
      image: _extractString(json['image_128']),
      active: json['active'] as bool? ?? true,
    );
  }

  factory FleetVehicle.fromJson(Map<String, dynamic> json) {
    return FleetVehicle(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      modelId: json['model_id'] as int?,
      modelName: json['model_name'] as String?,
      brandId: json['brand_id'] as int?,
      brandName: json['brand_name'] as String?,
      licensePlate: json['license_plate'] as String?,
      driverId: json['driver_id'] as int?,
      driverName: json['driver_name'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      fuelType: json['fuel_type'] as String?,
      seats: json['seats'] as int? ?? 5,
      doors: json['doors'] as int? ?? 4,
      color: json['color'] as String?,
      image: json['image'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'model_id': modelId,
        'model_name': modelName,
        'brand_id': brandId,
        'brand_name': brandName,
        'license_plate': licensePlate,
        'driver_id': driverId,
        'driver_name': driverName,
        'vehicle_type': vehicleType,
        'fuel_type': fuelType,
        'seats': seats,
        'doors': doors,
        'color': color,
        'image': image,
        'active': active,
      };

  Map<String, dynamic> toOdoo() => {
        if (modelId != null) 'model_id': modelId,
        if (licensePlate != null) 'license_plate': licensePlate,
        if (driverId != null) 'driver_id': driverId,
        if (fuelType != null) 'fuel_type': fuelType,
        if (color != null) 'color': color,
        'active': active,
      };

  /// اسم العرض
  String get displayName {
    if (licensePlate != null && licensePlate!.isNotEmpty) {
      return '$name ($licensePlate)';
    }
    return name;
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

  FleetVehicle copyWith({
    int? id,
    String? name,
    int? modelId,
    String? modelName,
    int? brandId,
    String? brandName,
    String? licensePlate,
    int? driverId,
    String? driverName,
    String? vehicleType,
    String? fuelType,
    int? seats,
    int? doors,
    String? color,
    String? image,
    bool? active,
  }) {
    return FleetVehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      licensePlate: licensePlate ?? this.licensePlate,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleType: vehicleType ?? this.vehicleType,
      fuelType: fuelType ?? this.fuelType,
      seats: seats ?? this.seats,
      doors: doors ?? this.doors,
      color: color ?? this.color,
      image: image ?? this.image,
      active: active ?? this.active,
    );
  }

  @override
  String toString() =>
      'FleetVehicle(id: $id, name: $name, plate: $licensePlate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FleetVehicle &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
