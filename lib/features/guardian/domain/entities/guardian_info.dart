/// Guardian Info Entity - كيان معلومات ولي الأمر
/// يطابق حقول res.partner المتعلقة بولي الأمر في Odoo
class GuardianInfo {
  final int id;
  final String name;
  final String? phone;
  final String? mobile;
  final String? email;
  final String? portalToken;
  final List<DependentPassenger> dependents;
  final int? companyId;
  final String? companyName;

  const GuardianInfo({
    required this.id,
    required this.name,
    this.phone,
    this.mobile,
    this.email,
    this.portalToken,
    this.dependents = const [],
    this.companyId,
    this.companyName,
  });

  factory GuardianInfo.fromOdoo(Map<String, dynamic> json) {
    return GuardianInfo(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      phone: _extractString(json['phone']),
      mobile: _extractString(json['mobile']),
      email: _extractString(json['email']),
      portalToken: _extractString(json['shuttle_portal_token']),
      companyId: _extractId(json['company_id']),
      companyName: _extractName(json['company_id']),
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

  static String? _extractName(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    if (value is List && value.length > 1) return value[1] as String?;
    return null;
  }

  /// الهاتف الأساسي
  String? get primaryPhone => mobile ?? phone;

  /// هل لديه تابعين
  bool get hasDependents => dependents.isNotEmpty;

  GuardianInfo copyWith({
    int? id,
    String? name,
    String? phone,
    String? mobile,
    String? email,
    String? portalToken,
    List<DependentPassenger>? dependents,
    int? companyId,
    String? companyName,
  }) {
    return GuardianInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      portalToken: portalToken ?? this.portalToken,
      dependents: dependents ?? this.dependents,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
    );
  }
}

/// الراكب التابع لولي الأمر
class DependentPassenger {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final int? pickupStopId;
  final String? pickupStopName;
  final int? dropoffStopId;
  final String? dropoffStopName;
  final String? direction;
  final String? notes;
  final PassengerStats stats;

  const DependentPassenger({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.pickupStopId,
    this.pickupStopName,
    this.dropoffStopId,
    this.dropoffStopName,
    this.direction,
    this.notes,
    this.stats = const PassengerStats(),
  });

  factory DependentPassenger.fromOdoo(Map<String, dynamic> json) {
    return DependentPassenger(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      phone: _extractString(json['phone']) ?? _extractString(json['mobile']),
      email: _extractString(json['email']),
      pickupStopId: _extractId(json['shuttle_default_pickup_stop_id']),
      pickupStopName: _extractName(json['shuttle_default_pickup_stop_id']),
      dropoffStopId: _extractId(json['shuttle_default_dropoff_stop_id']),
      dropoffStopName: _extractName(json['shuttle_default_dropoff_stop_id']),
      direction: _extractString(json['shuttle_direction']),
      notes: _extractString(json['shuttle_notes']),
      stats: PassengerStats.fromOdoo(json),
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

  static String? _extractName(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    if (value is List && value.length > 1) return value[1] as String?;
    return null;
  }
}

/// إحصائيات الراكب
class PassengerStats {
  final int totalTrips;
  final int presentTrips;
  final int absentTrips;
  final double attendanceRate;

  const PassengerStats({
    this.totalTrips = 0,
    this.presentTrips = 0,
    this.absentTrips = 0,
    this.attendanceRate = 0,
  });

  factory PassengerStats.fromOdoo(Map<String, dynamic> json) {
    return PassengerStats(
      totalTrips: json['shuttle_total_trips'] as int? ?? 0,
      presentTrips: json['shuttle_present_trips'] as int? ?? 0,
      absentTrips: json['shuttle_absent_trips'] as int? ?? 0,
      attendanceRate:
          (json['shuttle_attendance_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

