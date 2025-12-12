/// ShuttleBee Passenger Group Entity - كيان مجموعة الركاب
/// يطابق نموذج shuttle.passenger.group في Odoo
class PassengerGroup {
  final int id;
  final String name;
  final String? code;
  final int? driverId;
  final String? driverName;
  final int? vehicleId;
  final String? vehicleName;
  final int totalSeats;
  final GroupTripType tripType;
  final int? destinationStopId;
  final String? destinationStopName;
  final bool useCompanyDestination;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final int color;
  final String? notes;
  final bool active;
  final int? companyId;
  final String? companyName;
  final int memberCount;
  final double? subscriptionPrice;
  final BillingCycle billingCycle;
  final List<GroupSchedule> schedules;
  final List<GroupHoliday> holidays;
  final bool autoScheduleEnabled;
  final int autoScheduleWeeks;
  final bool autoScheduleIncludePickup;
  final bool autoScheduleIncludeDropoff;
  final String scheduleTimezone;

  const PassengerGroup({
    required this.id,
    required this.name,
    this.code,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleName,
    this.totalSeats = 15,
    this.tripType = GroupTripType.both,
    this.destinationStopId,
    this.destinationStopName,
    this.useCompanyDestination = true,
    this.destinationLatitude,
    this.destinationLongitude,
    this.color = 0,
    this.notes,
    this.active = true,
    this.companyId,
    this.companyName,
    this.memberCount = 0,
    this.subscriptionPrice,
    this.billingCycle = BillingCycle.monthly,
    this.schedules = const [],
    this.holidays = const [],
    this.autoScheduleEnabled = true,
    this.autoScheduleWeeks = 1,
    this.autoScheduleIncludePickup = true,
    this.autoScheduleIncludeDropoff = true,
    this.scheduleTimezone = 'UTC',
  });

  factory PassengerGroup.fromOdoo(Map<String, dynamic> json) {
    return PassengerGroup(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? '',
      code: _extractString(json['code']),
      driverId: _extractId(json['driver_id']),
      driverName: _extractName(json['driver_id']),
      vehicleId: _extractId(json['vehicle_id']),
      vehicleName: _extractName(json['vehicle_id']),
      totalSeats: json['total_seats'] as int? ?? 15,
      tripType:
          GroupTripType.fromString(_extractString(json['trip_type']) ?? 'both'),
      destinationStopId: _extractId(json['destination_stop_id']),
      destinationStopName: _extractName(json['destination_stop_id']),
      useCompanyDestination: json['use_company_destination'] as bool? ?? true,
      destinationLatitude: _extractDouble(json['destination_latitude']),
      destinationLongitude: _extractDouble(json['destination_longitude']),
      color: json['color'] as int? ?? 0,
      notes: _extractString(json['notes']),
      active: json['active'] as bool? ?? true,
      companyId: _extractId(json['company_id']),
      companyName: _extractName(json['company_id']),
      memberCount:
          json['member_count'] as int? ?? json['passenger_count'] as int? ?? 0,
      subscriptionPrice: _extractDouble(json['subscription_price']),
      billingCycle: BillingCycle.fromString(
          _extractString(json['billing_cycle']) ?? 'monthly'),
      autoScheduleEnabled: json['auto_schedule_enabled'] as bool? ?? true,
      autoScheduleWeeks: json['auto_schedule_weeks'] as int? ?? 1,
      autoScheduleIncludePickup:
          json['auto_schedule_include_pickup'] as bool? ?? true,
      autoScheduleIncludeDropoff:
          json['auto_schedule_include_dropoff'] as bool? ?? true,
      scheduleTimezone: _extractString(json['schedule_timezone']) ?? 'UTC',
    );
  }

  Map<String, dynamic> toOdoo() {
    return {
      'name': name,
      if (code != null) 'code': code,
      if (driverId != null) 'driver_id': driverId,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      'total_seats': totalSeats,
      'trip_type': tripType.value,
      if (destinationStopId != null) 'destination_stop_id': destinationStopId,
      'use_company_destination': useCompanyDestination,
      if (destinationLatitude != null)
        'destination_latitude': destinationLatitude,
      if (destinationLongitude != null)
        'destination_longitude': destinationLongitude,
      if (notes != null) 'notes': notes,
      'active': active,
      if (subscriptionPrice != null) 'subscription_price': subscriptionPrice,
      'billing_cycle': billingCycle.value,
      'auto_schedule_enabled': autoScheduleEnabled,
      'auto_schedule_weeks': autoScheduleWeeks,
      'auto_schedule_include_pickup': autoScheduleIncludePickup,
      'auto_schedule_include_dropoff': autoScheduleIncludeDropoff,
      'schedule_timezone': scheduleTimezone,
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

  /// هل لديه سائق معين
  bool get hasDriver => driverId != null;

  /// هل لديه مركبة معينة
  bool get hasVehicle => vehicleId != null;

  /// هل لديه وجهة
  bool get hasDestination =>
      destinationStopId != null ||
      (destinationLatitude != null && destinationLongitude != null);

  PassengerGroup copyWith({
    int? id,
    String? name,
    String? code,
    int? driverId,
    String? driverName,
    int? vehicleId,
    String? vehicleName,
    int? totalSeats,
    GroupTripType? tripType,
    int? destinationStopId,
    String? destinationStopName,
    bool? useCompanyDestination,
    double? destinationLatitude,
    double? destinationLongitude,
    int? color,
    String? notes,
    bool? active,
    int? companyId,
    String? companyName,
    int? memberCount,
    double? subscriptionPrice,
    BillingCycle? billingCycle,
    List<GroupSchedule>? schedules,
    List<GroupHoliday>? holidays,
    bool? autoScheduleEnabled,
    int? autoScheduleWeeks,
    bool? autoScheduleIncludePickup,
    bool? autoScheduleIncludeDropoff,
    String? scheduleTimezone,
  }) {
    return PassengerGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      totalSeats: totalSeats ?? this.totalSeats,
      tripType: tripType ?? this.tripType,
      destinationStopId: destinationStopId ?? this.destinationStopId,
      destinationStopName: destinationStopName ?? this.destinationStopName,
      useCompanyDestination:
          useCompanyDestination ?? this.useCompanyDestination,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      memberCount: memberCount ?? this.memberCount,
      subscriptionPrice: subscriptionPrice ?? this.subscriptionPrice,
      billingCycle: billingCycle ?? this.billingCycle,
      schedules: schedules ?? this.schedules,
      holidays: holidays ?? this.holidays,
      autoScheduleEnabled: autoScheduleEnabled ?? this.autoScheduleEnabled,
      autoScheduleWeeks: autoScheduleWeeks ?? this.autoScheduleWeeks,
      autoScheduleIncludePickup:
          autoScheduleIncludePickup ?? this.autoScheduleIncludePickup,
      autoScheduleIncludeDropoff:
          autoScheduleIncludeDropoff ?? this.autoScheduleIncludeDropoff,
      scheduleTimezone: scheduleTimezone ?? this.scheduleTimezone,
    );
  }

  @override
  String toString() =>
      'PassengerGroup(id: $id, name: $name, members: $memberCount)';
}

/// نوع الرحلة للمجموعة
enum GroupTripType {
  pickup('pickup', 'صعود فقط'),
  dropoff('dropoff', 'نزول فقط'),
  both('both', 'صعود ونزول');

  final String value;
  final String arabicLabel;

  const GroupTripType(this.value, this.arabicLabel);

  static GroupTripType fromString(String value) {
    return GroupTripType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupTripType.both,
    );
  }
}

/// دورة الفوترة
enum BillingCycle {
  perTrip('per_trip', 'لكل رحلة'),
  monthly('monthly', 'شهرياً'),
  perTerm('per_term', 'لكل فصل');

  final String value;
  final String arabicLabel;

  const BillingCycle(this.value, this.arabicLabel);

  static BillingCycle fromString(String value) {
    return BillingCycle.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BillingCycle.monthly,
    );
  }
}

/// جدول المجموعة الأسبوعي
class GroupSchedule {
  final int id;
  final int groupId;
  final Weekday weekday;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;
  final String? pickupTimeDisplay;
  final String? dropoffTimeDisplay;
  final bool createPickup;
  final bool createDropoff;
  final bool active;

  const GroupSchedule({
    required this.id,
    required this.groupId,
    required this.weekday,
    this.pickupTime,
    this.dropoffTime,
    this.pickupTimeDisplay,
    this.dropoffTimeDisplay,
    this.createPickup = true,
    this.createDropoff = true,
    this.active = true,
  });

  factory GroupSchedule.fromOdoo(Map<String, dynamic> json) {
    return GroupSchedule(
      id: json['id'] as int? ?? 0,
      groupId: _extractId(json['group_id']) ?? 0,
      weekday: Weekday.fromString(json['weekday'] as String? ?? 'monday'),
      pickupTime: _parseDateTime(json['pickup_time']),
      dropoffTime: _parseDateTime(json['dropoff_time']),
      pickupTimeDisplay: json['pickup_time_display'] as String?,
      dropoffTimeDisplay: json['dropoff_time_display'] as String?,
      createPickup: json['create_pickup'] as bool? ?? true,
      createDropoff: json['create_dropoff'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
    );
  }

  static int? _extractId(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) return value[0] as int?;
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null || value == false) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/// أيام الأسبوع
enum Weekday {
  monday('monday', 'الإثنين', 0),
  tuesday('tuesday', 'الثلاثاء', 1),
  wednesday('wednesday', 'الأربعاء', 2),
  thursday('thursday', 'الخميس', 3),
  friday('friday', 'الجمعة', 4),
  saturday('saturday', 'السبت', 5),
  sunday('sunday', 'الأحد', 6);

  final String value;
  final String arabicLabel;
  final int dayIndex;

  const Weekday(this.value, this.arabicLabel, this.dayIndex);

  static Weekday fromString(String value) {
    return Weekday.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Weekday.monday,
    );
  }

  static Weekday fromDayIndex(int dayIndex) {
    return Weekday.values.firstWhere(
      (e) => e.dayIndex == dayIndex,
      orElse: () => Weekday.monday,
    );
  }
}

/// عطلة/استثناء للمجموعة
class GroupHoliday {
  final int id;
  final int groupId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;

  const GroupHoliday({
    required this.id,
    required this.groupId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.active = true,
  });

  factory GroupHoliday.fromOdoo(Map<String, dynamic> json) {
    return GroupHoliday(
      id: json['id'] as int? ?? 0,
      groupId: _extractId(json['group_id']) ?? 0,
      name: json['name'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      active: json['active'] as bool? ?? true,
    );
  }

  static int? _extractId(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) return value[0] as int?;
    return null;
  }

  /// هل التاريخ ضمن العطلة
  bool containsDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }
}
