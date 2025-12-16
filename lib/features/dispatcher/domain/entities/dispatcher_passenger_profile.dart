/// Dispatcher Passenger Profile
///
/// Maps to Odoo `res.partner` fields extended by ShuttleBee.
class DispatcherPassengerProfile {
  final int id;
  final String name;

  final String? phone;
  final String? mobile;

  final String? street;
  final String? street2;
  final String? city;
  final String? zip;

  final bool active;

  // ShuttleBee fields
  final bool isShuttlePassenger;
  final bool autoNotification;
  final bool useGpsForPickup;
  final bool useGpsForDropoff;
  final String tripDirection; // both|pickup|dropoff

  final double? latitude;
  final double? longitude;

  // Guardian fields (new structure)
  final bool hasGuardian;
  final String? fatherName;
  final String? fatherPhone;
  final String? motherName;
  final String? motherPhone;

  // Legacy fields (kept for backward compatibility)
  final String? guardianPhone;
  final String? guardianEmail;

  final String? shuttleNotes;

  // Temporary/Secondary Address
  final String? temporaryAddress;
  final double? temporaryLatitude;
  final double? temporaryLongitude;
  final String? temporaryContactName;
  final String? temporaryContactPhone;

  final int? defaultPickupStopId;
  final String? defaultPickupStopName;
  final int? defaultDropoffStopId;
  final String? defaultDropoffStopName;

  const DispatcherPassengerProfile({
    required this.id,
    required this.name,
    this.phone,
    this.mobile,
    this.street,
    this.street2,
    this.city,
    this.zip,
    this.active = true,
    this.isShuttlePassenger = true,
    this.autoNotification = true,
    this.useGpsForPickup = true,
    this.useGpsForDropoff = true,
    this.tripDirection = 'both',
    this.latitude,
    this.longitude,
    this.hasGuardian = false,
    this.fatherName,
    this.fatherPhone,
    this.motherName,
    this.motherPhone,
    this.guardianPhone,
    this.guardianEmail,
    this.shuttleNotes,
    this.temporaryAddress,
    this.temporaryLatitude,
    this.temporaryLongitude,
    this.temporaryContactName,
    this.temporaryContactPhone,
    this.defaultPickupStopId,
    this.defaultPickupStopName,
    this.defaultDropoffStopId,
    this.defaultDropoffStopName,
  });

  factory DispatcherPassengerProfile.fromOdoo(Map<String, dynamic> json) {
    return DispatcherPassengerProfile(
      id: json['id'] as int? ?? 0,
      name: _asString(json['name']) ?? '',
      phone: _asString(json['phone']),
      mobile: _asString(json['mobile']),
      street: _asString(json['street']),
      street2: _asString(json['street2']),
      city: _asString(json['city']),
      zip: _asString(json['zip']),
      active: json['active'] as bool? ?? true,
      isShuttlePassenger: json['is_shuttle_passenger'] as bool? ?? false,
      autoNotification: json['is_auto_notification'] as bool? ?? true,
      useGpsForPickup: json['use_gps_for_pickup'] as bool? ?? true,
      useGpsForDropoff: json['use_gps_for_dropoff'] as bool? ?? true,
      tripDirection: _asString(json['shuttle_trip_direction']) ?? 'both',
      latitude: _asDouble(json['shuttle_latitude']),
      longitude: _asDouble(json['shuttle_longitude']),
      hasGuardian: json['has_guardian'] as bool? ?? false,
      fatherName: _asString(json['father_name']),
      fatherPhone: _asString(json['father_phone']),
      motherName: _asString(json['mother_name']),
      motherPhone: _asString(json['mother_phone']),
      guardianPhone: _asString(json['guardian_phone']),
      guardianEmail: _asString(json['guardian_email']),
      shuttleNotes: _asString(json['shuttle_notes']),
      temporaryAddress: _asString(json['temporary_address']),
      temporaryLatitude: _asDouble(json['temporary_latitude']),
      temporaryLongitude: _asDouble(json['temporary_longitude']),
      temporaryContactName: _asString(json['temporary_contact_name']),
      temporaryContactPhone: _asString(json['temporary_contact_phone']),
      defaultPickupStopId: _extractId(json['default_pickup_stop_id']),
      defaultPickupStopName: _extractName(json['default_pickup_stop_id']),
      defaultDropoffStopId: _extractId(json['default_dropoff_stop_id']),
      defaultDropoffStopName: _extractName(json['default_dropoff_stop_id']),
    );
  }

  factory DispatcherPassengerProfile.fromJson(Map<String, dynamic> json) {
    return DispatcherPassengerProfile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      street: json['street'] as String?,
      street2: json['street2'] as String?,
      city: json['city'] as String?,
      zip: json['zip'] as String?,
      active: json['active'] as bool? ?? true,
      isShuttlePassenger: json['is_shuttle_passenger'] as bool? ?? false,
      autoNotification: json['auto_notification'] as bool? ?? true,
      useGpsForPickup: json['use_gps_for_pickup'] as bool? ?? true,
      useGpsForDropoff: json['use_gps_for_dropoff'] as bool? ?? true,
      tripDirection: json['trip_direction'] as String? ?? 'both',
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      hasGuardian: json['has_guardian'] as bool? ?? false,
      fatherName: json['father_name'] as String?,
      fatherPhone: json['father_phone'] as String?,
      motherName: json['mother_name'] as String?,
      motherPhone: json['mother_phone'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      guardianEmail: json['guardian_email'] as String?,
      shuttleNotes: json['shuttle_notes'] as String?,
      temporaryAddress: json['temporary_address'] as String?,
      temporaryLatitude: json['temporary_latitude'] as double?,
      temporaryLongitude: json['temporary_longitude'] as double?,
      temporaryContactName: json['temporary_contact_name'] as String?,
      temporaryContactPhone: json['temporary_contact_phone'] as String?,
      defaultPickupStopId: json['default_pickup_stop_id'] as int?,
      defaultPickupStopName: json['default_pickup_stop_name'] as String?,
      defaultDropoffStopId: json['default_dropoff_stop_id'] as int?,
      defaultDropoffStopName: json['default_dropoff_stop_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'mobile': mobile,
        'street': street,
        'street2': street2,
        'city': city,
        'zip': zip,
        'active': active,
        'is_shuttle_passenger': isShuttlePassenger,
        'auto_notification': autoNotification,
        'use_gps_for_pickup': useGpsForPickup,
        'use_gps_for_dropoff': useGpsForDropoff,
        'trip_direction': tripDirection,
        'latitude': latitude,
        'longitude': longitude,
        'has_guardian': hasGuardian,
        'father_name': fatherName,
        'father_phone': fatherPhone,
        'mother_name': motherName,
        'mother_phone': motherPhone,
        'guardian_phone': guardianPhone,
        'guardian_email': guardianEmail,
        'shuttle_notes': shuttleNotes,
        'temporary_address': temporaryAddress,
        'temporary_latitude': temporaryLatitude,
        'temporary_longitude': temporaryLongitude,
        'temporary_contact_name': temporaryContactName,
        'temporary_contact_phone': temporaryContactPhone,
        'default_pickup_stop_id': defaultPickupStopId,
        'default_pickup_stop_name': defaultPickupStopName,
        'default_dropoff_stop_id': defaultDropoffStopId,
        'default_dropoff_stop_name': defaultDropoffStopName,
      };

  String get shortContact {
    final p = phone?.trim();
    final m = mobile?.trim();
    if (p != null && p.isNotEmpty) return p;
    if (m != null && m.isNotEmpty) return m;
    // Try father phone first, then mother phone
    final fp = fatherPhone?.trim();
    if (fp != null && fp.isNotEmpty) return fp;
    final mp = motherPhone?.trim();
    if (mp != null && mp.isNotEmpty) return mp;
    // Fallback to legacy guardian phone
    final g = guardianPhone?.trim();
    if (g != null && g.isNotEmpty) return g;
    return '';
  }

  /// Returns primary guardian contact (father or mother)
  String get primaryGuardianContact {
    final fp = fatherPhone?.trim();
    if (fp != null && fp.isNotEmpty) return 'الأب: $fp';
    final mp = motherPhone?.trim();
    if (mp != null && mp.isNotEmpty) return 'الأم: $mp';
    final g = guardianPhone?.trim();
    if (g != null && g.isNotEmpty) return 'ولي الأمر: $g';
    return '';
  }

  /// Check if passenger has a temporary address set
  bool get hasTemporaryAddress {
    return (temporaryLatitude != null && temporaryLongitude != null) ||
        (temporaryAddress?.trim().isNotEmpty ?? false);
  }

  /// Get the effective location (temporary if available, else main)
  ({double? lat, double? lng, bool isTemporary}) get effectiveLocation {
    if (temporaryLatitude != null && temporaryLongitude != null) {
      return (
        lat: temporaryLatitude,
        lng: temporaryLongitude,
        isTemporary: true
      );
    }
    return (lat: latitude, lng: longitude, isTemporary: false);
  }

  String get addressLine {
    final parts = <String>[];
    final s = street?.trim();
    final s2 = street2?.trim();
    final c = city?.trim();
    final z = zip?.trim();

    if (s != null && s.isNotEmpty) parts.add(s);
    if (s2 != null && s2.isNotEmpty) parts.add(s2);
    if (c != null && c.isNotEmpty) parts.add(c);
    if (z != null && z.isNotEmpty) parts.add(z);

    return parts.join('، ');
  }

  static String? _asString(dynamic v) {
    if (v == null || v == false) return null;
    return v.toString();
  }

  static double? _asDouble(dynamic v) {
    if (v == null || v == false) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
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
}
