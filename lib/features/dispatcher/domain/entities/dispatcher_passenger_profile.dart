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

  final String? guardianPhone;
  final String? guardianEmail;
  final String? shuttleNotes;

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
    this.guardianPhone,
    this.guardianEmail,
    this.shuttleNotes,
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
      guardianPhone: _asString(json['guardian_phone']),
      guardianEmail: _asString(json['guardian_email']),
      shuttleNotes: _asString(json['shuttle_notes']),
      defaultPickupStopId: _extractId(json['default_pickup_stop_id']),
      defaultPickupStopName: _extractName(json['default_pickup_stop_id']),
      defaultDropoffStopId: _extractId(json['default_dropoff_stop_id']),
      defaultDropoffStopName: _extractName(json['default_dropoff_stop_id']),
    );
  }

  String get shortContact {
    final p = phone?.trim();
    final m = mobile?.trim();
    if (p != null && p.isNotEmpty) return p;
    if (m != null && m.isNotEmpty) return m;
    final g = guardianPhone?.trim();
    if (g != null && g.isNotEmpty) return g;
    return '';
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
