/// Fleet Vehicle Model Entity - كيان موديل المركبة
/// يطابق نموذج fleet.vehicle.model في Odoo
class FleetVehicleModel {
  final int id;
  final String name;
  final int? brandId;
  final String? brandName;
  final String? vehicleType;
  final String? fuelType;
  final int seats;
  final int doors;
  final String? image;

  const FleetVehicleModel({
    required this.id,
    required this.name,
    this.brandId,
    this.brandName,
    this.vehicleType,
    this.fuelType,
    this.seats = 5,
    this.doors = 4,
    this.image,
  });

  factory FleetVehicleModel.fromOdoo(Map<String, dynamic> json) {
    return FleetVehicleModel(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      brandId: _extractId(json['brand_id']),
      brandName: _extractName(json['brand_id']),
      vehicleType: _extractString(json['vehicle_type']),
      fuelType: _extractString(json['default_fuel_type']),
      seats: json['seats'] as int? ?? 5,
      doors: json['doors'] as int? ?? 4,
      image: _extractString(json['image_128']),
    );
  }

  factory FleetVehicleModel.fromJson(Map<String, dynamic> json) {
    return FleetVehicleModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      brandId: json['brand_id'] as int?,
      brandName: json['brand_name'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      fuelType: json['fuel_type'] as String?,
      seats: json['seats'] as int? ?? 5,
      doors: json['doors'] as int? ?? 4,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand_id': brandId,
        'brand_name': brandName,
        'vehicle_type': vehicleType,
        'fuel_type': fuelType,
        'seats': seats,
        'doors': doors,
        'image': image,
      };

  Map<String, dynamic> toOdoo() => {
        'name': name,
        if (brandId != null) 'brand_id': brandId,
        if (vehicleType != null) 'vehicle_type': vehicleType,
        if (fuelType != null) 'default_fuel_type': fuelType,
        'seats': seats,
        'doors': doors,
      };

  /// الاسم الكامل مع المُصنّع
  String get displayName {
    if (brandName != null && brandName!.isNotEmpty) {
      return '$brandName $name';
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

  FleetVehicleModel copyWith({
    int? id,
    String? name,
    int? brandId,
    String? brandName,
    String? vehicleType,
    String? fuelType,
    int? seats,
    int? doors,
    String? image,
  }) {
    return FleetVehicleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      vehicleType: vehicleType ?? this.vehicleType,
      fuelType: fuelType ?? this.fuelType,
      seats: seats ?? this.seats,
      doors: doors ?? this.doors,
      image: image ?? this.image,
    );
  }

  @override
  String toString() => 'FleetVehicleModel(id: $id, name: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FleetVehicleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// أنواع المركبات المتاحة في Odoo Fleet
class VehicleTypes {
  static const String car = 'car';
  static const String bike = 'bike';
  static const String minibus = 'minibus'; // Custom addition for shuttle
  static const String bus = 'bus'; // Custom addition for shuttle

  static const List<VehicleTypeOption> all = [
    VehicleTypeOption(value: car, label: 'سيارة', labelFr: 'Voiture'),
    VehicleTypeOption(value: bike, label: 'دراجة', labelFr: 'Moto'),
    VehicleTypeOption(value: minibus, label: 'حافلة صغيرة', labelFr: 'Minibus'),
    VehicleTypeOption(value: bus, label: 'حافلة', labelFr: 'Bus'),
  ];
}

class VehicleTypeOption {
  final String value;
  final String label;
  final String labelFr;

  const VehicleTypeOption({
    required this.value,
    required this.label,
    required this.labelFr,
  });
}

/// أنواع الوقود المتاحة في Odoo Fleet
class FuelTypes {
  static const String diesel = 'diesel';
  static const String gasoline = 'gasoline';
  static const String hybrid = 'hybrid';
  static const String fullHybrid = 'full_hybrid';
  static const String plugInHybrid = 'plug_in_hybrid_diesel';
  static const String electric = 'electric';
  static const String lpg = 'lpg';
  static const String cng = 'cng';
  static const String hydrogen = 'hydrogen';

  static const List<FuelTypeOption> all = [
    FuelTypeOption(value: diesel, label: 'ديزل', labelFr: 'Diesel'),
    FuelTypeOption(value: gasoline, label: 'بنزين', labelFr: 'Essence'),
    FuelTypeOption(value: electric, label: 'كهربائي', labelFr: 'Électrique'),
    FuelTypeOption(value: hybrid, label: 'هجين', labelFr: 'Hybride'),
    FuelTypeOption(
        value: fullHybrid, label: 'هجين كامل', labelFr: 'Hybride complet'),
    FuelTypeOption(
        value: plugInHybrid,
        label: 'هجين قابل للشحن',
        labelFr: 'Hybride rechargeable'),
    FuelTypeOption(value: lpg, label: 'غاز البترول المسال', labelFr: 'GPL'),
    FuelTypeOption(value: cng, label: 'الغاز الطبيعي المضغوط', labelFr: 'GNC'),
    FuelTypeOption(value: hydrogen, label: 'هيدروجين', labelFr: 'Hydrogène'),
  ];
}

class FuelTypeOption {
  final String value;
  final String label;
  final String labelFr;

  const FuelTypeOption({
    required this.value,
    required this.label,
    required this.labelFr,
  });
}
