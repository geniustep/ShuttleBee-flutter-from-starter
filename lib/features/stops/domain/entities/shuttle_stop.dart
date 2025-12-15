/// ShuttleBee Stop Entity - كيان نقطة التوقف
/// يطابق نموذج shuttle.stop في Odoo
class ShuttleStop {
  final int id;
  final String name;
  final String? code;
  final String? street;
  final String? street2;
  final String? city;
  final int? stateId;
  final String? stateName;
  final String? zip;
  final int? countryId;
  final String? countryName;
  final double? latitude;
  final double? longitude;
  final StopType stopType;
  final bool active;
  final int color;
  final int sequence;
  final int usageCount;
  final String? notes;
  final int? companyId;

  const ShuttleStop({
    required this.id,
    required this.name,
    this.code,
    this.street,
    this.street2,
    this.city,
    this.stateId,
    this.stateName,
    this.zip,
    this.countryId,
    this.countryName,
    this.latitude,
    this.longitude,
    this.stopType = StopType.both,
    this.active = true,
    this.color = 0,
    this.sequence = 10,
    this.usageCount = 0,
    this.notes,
    this.companyId,
  });

  factory ShuttleStop.fromOdoo(Map<String, dynamic> json) {
    return ShuttleStop(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      code: _extractString(json['code']),
      street: _extractString(json['street']),
      street2: _extractString(json['street2']),
      city: _extractString(json['city']),
      stateId: _extractId(json['state_id']),
      stateName: _extractName(json['state_id']),
      zip: _extractString(json['zip']),
      countryId: _extractId(json['country_id']),
      countryName: _extractName(json['country_id']),
      latitude: _extractDouble(json['latitude']),
      longitude: _extractDouble(json['longitude']),
      stopType:
          StopType.fromString(_extractString(json['stop_type']) ?? 'both'),
      active: json['active'] as bool? ?? true,
      color: json['color'] as int? ?? 0,
      sequence: json['sequence'] as int? ?? 10,
      usageCount: json['usage_count'] as int? ?? 0,
      notes: _extractString(json['notes']),
      companyId: _extractId(json['company_id']),
    );
  }

  Map<String, dynamic> toOdoo() {
    return {
      'name': name,
      if (code != null) 'code': code,
      if (street != null) 'street': street,
      if (street2 != null) 'street2': street2,
      if (city != null) 'city': city,
      if (stateId != null) 'state_id': stateId,
      if (zip != null) 'zip': zip,
      if (countryId != null) 'country_id': countryId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'stop_type': stopType.value,
      'active': active,
      'sequence': sequence,
      if (notes != null) 'notes': notes,
    };
  }

  static String? _extractString(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    return value.toString();
  }

  static double? _extractDouble(dynamic value) {
    if (value == null || value == false) return null;
    if (value is num) return value.toDouble();
    return null;
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

  /// العنوان الكامل
  String get fullAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (street2 != null && street2!.isNotEmpty) parts.add(street2!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (stateName != null && stateName!.isNotEmpty) parts.add(stateName!);
    if (zip != null && zip!.isNotEmpty) parts.add(zip!);
    if (countryName != null && countryName!.isNotEmpty) parts.add(countryName!);
    return parts.join(', ');
  }

  /// هل لديه إحداثيات GPS
  bool get hasCoordinates => latitude != null && longitude != null;

  /// اسم العرض
  String get displayName {
    if (code != null && code!.isNotEmpty) {
      return '[$code] $name';
    }
    return name;
  }

  ShuttleStop copyWith({
    int? id,
    String? name,
    String? code,
    String? street,
    String? street2,
    String? city,
    int? stateId,
    String? stateName,
    String? zip,
    int? countryId,
    String? countryName,
    double? latitude,
    double? longitude,
    StopType? stopType,
    bool? active,
    int? color,
    int? sequence,
    int? usageCount,
    String? notes,
    int? companyId,
  }) {
    return ShuttleStop(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      street: street ?? this.street,
      street2: street2 ?? this.street2,
      city: city ?? this.city,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      zip: zip ?? this.zip,
      countryId: countryId ?? this.countryId,
      countryName: countryName ?? this.countryName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      stopType: stopType ?? this.stopType,
      active: active ?? this.active,
      color: color ?? this.color,
      sequence: sequence ?? this.sequence,
      usageCount: usageCount ?? this.usageCount,
      notes: notes ?? this.notes,
      companyId: companyId ?? this.companyId,
    );
  }

  @override
  String toString() =>
      'ShuttleStop(id: $id, name: $name, type: ${stopType.value})';
}

/// نوع نقطة التوقف
enum StopType {
  pickup('pickup', 'صعود فقط', 0xFF3B82F6),
  dropoff('dropoff', 'نزول فقط', 0xFF10B981),
  both('both', 'صعود ونزول', 0xFF8B5CF6);

  final String value;
  final String arabicLabel;
  final int colorValue;

  const StopType(this.value, this.arabicLabel, this.colorValue);

  static StopType fromString(String value) {
    return StopType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StopType.both,
    );
  }
}

/// اقتراح نقطة توقف قريبة
class StopSuggestion {
  final int stopId;
  final String name;
  final double distanceKm;
  final StopType stopType;

  const StopSuggestion({
    required this.stopId,
    required this.name,
    required this.distanceKm,
    required this.stopType,
  });

  factory StopSuggestion.fromJson(Map<String, dynamic> json) {
    return StopSuggestion(
      stopId: json['stop_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      stopType: StopType.fromString(json['stop_type'] as String? ?? 'both'),
    );
  }

  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} متر';
    }
    return '${distanceKm.toStringAsFixed(1)} كم';
  }
}
