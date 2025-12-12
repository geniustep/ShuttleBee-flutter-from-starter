import '../../../../core/enums/enums.dart';

/// Trip Entity - كيان الرحلة - ShuttleBee
/// محدث ليطابق shuttle.trip في Odoo
class Trip {
  final int id;
  final String name;
  final String? reference;
  final TripState state;
  final TripType tripType;
  final DateTime date;
  final DateTime? plannedStartTime;
  final DateTime? plannedArrivalTime;
  final DateTime? actualStartTime;
  final DateTime? actualArrivalTime;
  final int? driverId;
  final String? driverName;
  final int? vehicleId;
  final String? vehicleName;
  final String? vehiclePlateNumber;
  final int? groupId;
  final String? groupName;
  final int totalPassengers;
  final int boardedCount;
  final int absentCount;
  final int droppedCount;
  final double? plannedDistance;
  final double? actualDistance;
  final String? notes;
  final List<TripLine> lines;

  // GPS Tracking
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastGpsUpdate;

  // Environmental Conditions
  final String? weatherStatus;
  final String? trafficStatus;
  final String? riskLevel;

  // Capacity
  final int seatCapacity;
  final int bookedSeats;
  final int availableSeats;
  final double occupancyRate;

  // Duration
  final double plannedDurationMinutes;
  final double actualDurationMinutes;

  // Company (Final Destination)
  final int? companyId;
  final String? companyName;
  final double? companyLatitude;
  final double? companyLongitude;
  final String? companyImage;

  const Trip({
    required this.id,
    required this.name,
    this.reference,
    required this.state,
    required this.tripType,
    required this.date,
    this.plannedStartTime,
    this.plannedArrivalTime,
    this.actualStartTime,
    this.actualArrivalTime,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleName,
    this.vehiclePlateNumber,
    this.groupId,
    this.groupName,
    this.totalPassengers = 0,
    this.boardedCount = 0,
    this.absentCount = 0,
    this.droppedCount = 0,
    this.plannedDistance,
    this.actualDistance,
    this.notes,
    this.lines = const [],
    this.currentLatitude,
    this.currentLongitude,
    this.lastGpsUpdate,
    this.weatherStatus,
    this.trafficStatus,
    this.riskLevel,
    this.seatCapacity = 0,
    this.bookedSeats = 0,
    this.availableSeats = 0,
    this.occupancyRate = 0,
    this.plannedDurationMinutes = 0,
    this.actualDurationMinutes = 0,
    this.companyId,
    this.companyName,
    this.companyLatitude,
    this.companyLongitude,
    this.companyImage,
  });

  /// Create from Odoo JSON response
  factory Trip.fromOdoo(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ??
          _extractString(json['display_name']) ??
          '',
      reference: _extractString(json['reference']),
      state: TripState.tryFromString(_extractString(json['state'])) ??
          TripState.draft,
      tripType: TripType.tryFromString(_extractString(json['trip_type'])) ??
          TripType.pickup,
      date: parseDate(json['date'] ?? json['scheduled_date']),
      plannedStartTime:
          parseDateTime(json['planned_start_time'] ?? json['start_time']),
      plannedArrivalTime:
          parseDateTime(json['planned_arrival_time'] ?? json['end_time']),
      actualStartTime: parseDateTime(json['actual_start_time']),
      actualArrivalTime: parseDateTime(json['actual_arrival_time']),
      driverId: extractId(json['driver_id']),
      driverName: extractName(json['driver_id']),
      vehicleId: extractId(json['vehicle_id']),
      vehicleName: extractName(json['vehicle_id']),
      vehiclePlateNumber: _extractString(json['vehicle_plate']),
      groupId: extractId(json['group_id']),
      groupName: extractName(json['group_id']),
      totalPassengers: json['total_passengers'] as int? ??
          json['passenger_count'] as int? ??
          0,
      boardedCount: json['boarded_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      droppedCount: json['dropped_count'] as int? ?? 0,
      plannedDistance: _extractDouble(json['planned_distance']),
      actualDistance: _extractDouble(json['actual_distance']),
      notes: _extractString(json['notes']),
      lines: (json['line_ids'] as List?)
              ?.map((e) => TripLine.fromOdoo(e as Map<String, dynamic>))
              .toList() ??
          [],
      // GPS Tracking
      currentLatitude: _extractDouble(json['current_latitude']),
      currentLongitude: _extractDouble(json['current_longitude']),
      lastGpsUpdate: parseDateTime(json['last_gps_update']),
      // Environmental Conditions
      weatherStatus: _extractString(json['weather_status']),
      trafficStatus: _extractString(json['traffic_status']),
      riskLevel: _extractString(json['risk_level']),
      // Capacity
      seatCapacity: json['seat_capacity'] as int? ?? 0,
      bookedSeats: json['booked_seats'] as int? ?? 0,
      availableSeats: json['available_seats'] as int? ?? 0,
      occupancyRate: _extractDouble(json['occupancy_rate']) ?? 0,
      // Duration
      plannedDurationMinutes:
          _extractDouble(json['planned_duration_minutes']) ?? 0,
      actualDurationMinutes:
          _extractDouble(json['actual_duration_minutes']) ?? 0,
      // Company (Final Destination)
      companyId: extractId(json['company_id']),
      companyName: extractName(json['company_id']),
      companyLatitude: _extractDouble(json['company_id.shuttle_latitude']),
      companyLongitude: _extractDouble(json['company_id.shuttle_longitude']),
      companyImage: _extractString(json['company_id.image_1920']),
    );
  }

  /// Helper to safely extract String from Odoo (handles false values)
  static String? _extractString(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    return value.toString();
  }

  /// Helper to safely extract double from Odoo (handles false values)
  static double? _extractDouble(dynamic value) {
    if (value == null || value == false) return null;
    if (value is num) return value.toDouble();
    return null;
  }

  /// Create from JSON
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      state:
          TripState.tryFromString(json['state'] as String?) ?? TripState.draft,
      tripType: TripType.tryFromString(json['tripType'] as String?) ??
          TripType.pickup,
      date: DateTime.parse(json['date'] as String),
      plannedStartTime: json['plannedStartTime'] != null
          ? DateTime.parse(json['plannedStartTime'] as String)
          : null,
      plannedArrivalTime: json['plannedArrivalTime'] != null
          ? DateTime.parse(json['plannedArrivalTime'] as String)
          : null,
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'] as String)
          : null,
      actualArrivalTime: json['actualArrivalTime'] != null
          ? DateTime.parse(json['actualArrivalTime'] as String)
          : null,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      vehicleId: json['vehicleId'] as int?,
      vehicleName: json['vehicleName'] as String?,
      vehiclePlateNumber: json['vehiclePlateNumber'] as String?,
      groupId: json['groupId'] as int?,
      groupName: json['groupName'] as String?,
      totalPassengers: json['totalPassengers'] as int? ?? 0,
      boardedCount: json['boardedCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
      droppedCount: json['droppedCount'] as int? ?? 0,
      plannedDistance: (json['plannedDistance'] as num?)?.toDouble(),
      actualDistance: (json['actualDistance'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      lines: (json['lines'] as List?)
              ?.map((e) => TripLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state.value,
      'tripType': tripType.value,
      'date': date.toIso8601String(),
      'plannedStartTime': plannedStartTime?.toIso8601String(),
      'plannedArrivalTime': plannedArrivalTime?.toIso8601String(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualArrivalTime': actualArrivalTime?.toIso8601String(),
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'vehiclePlateNumber': vehiclePlateNumber,
      'groupId': groupId,
      'groupName': groupName,
      'totalPassengers': totalPassengers,
      'boardedCount': boardedCount,
      'absentCount': absentCount,
      'droppedCount': droppedCount,
      'plannedDistance': plannedDistance,
      'actualDistance': actualDistance,
      'notes': notes,
      'lines': lines.map((e) => e.toJson()).toList(),
    };
  }

  /// Helper to parse Odoo date
  static DateTime parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Helper to parse Odoo datetime
  static DateTime? parseDateTime(dynamic value) {
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

  /// Helper to extract ID from Odoo many2one field
  static int? extractId(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) return value[0] as int?;
    return null;
  }

  /// Helper to extract name from Odoo many2one field
  static String? extractName(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value;
    if (value is List && value.length > 1) return value[1] as String?;
    return null;
  }

  // === Computed Properties ===

  /// هل الرحلة جارية
  bool get isOngoing => state.isOngoing;

  /// هل الرحلة منتهية
  bool get isCompleted => state.isCompleted;

  /// هل يمكن بدء الرحلة
  bool get canStart => state.canStart;

  /// هل يمكن إنهاء الرحلة
  bool get canComplete => state.canComplete;

  /// هل يمكن إلغاء الرحلة
  bool get canCancel => state.canCancel;

  /// نسبة الإنجاز
  double get completionPercentage {
    if (totalPassengers == 0) return 0;
    return ((boardedCount + droppedCount) / totalPassengers) * 100;
  }

  /// عدد الركاب المتبقين
  int get remainingPassengers =>
      totalPassengers - boardedCount - absentCount - droppedCount;

  /// Copy with
  Trip copyWith({
    int? id,
    String? name,
    String? reference,
    TripState? state,
    TripType? tripType,
    DateTime? date,
    DateTime? plannedStartTime,
    DateTime? plannedArrivalTime,
    DateTime? actualStartTime,
    DateTime? actualArrivalTime,
    int? driverId,
    String? driverName,
    int? vehicleId,
    String? vehicleName,
    String? vehiclePlateNumber,
    int? groupId,
    String? groupName,
    int? totalPassengers,
    int? boardedCount,
    int? absentCount,
    int? droppedCount,
    double? plannedDistance,
    double? actualDistance,
    String? notes,
    List<TripLine>? lines,
    // GPS Tracking
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastGpsUpdate,
    // Environmental Conditions
    String? weatherStatus,
    String? trafficStatus,
    String? riskLevel,
    // Capacity
    int? seatCapacity,
    int? bookedSeats,
    int? availableSeats,
    double? occupancyRate,
    // Duration
    double? plannedDurationMinutes,
    double? actualDurationMinutes,
    // Company (Final Destination)
    int? companyId,
    String? companyName,
    double? companyLatitude,
    double? companyLongitude,
    String? companyImage,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      state: state ?? this.state,
      tripType: tripType ?? this.tripType,
      date: date ?? this.date,
      plannedStartTime: plannedStartTime ?? this.plannedStartTime,
      plannedArrivalTime: plannedArrivalTime ?? this.plannedArrivalTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      totalPassengers: totalPassengers ?? this.totalPassengers,
      boardedCount: boardedCount ?? this.boardedCount,
      absentCount: absentCount ?? this.absentCount,
      droppedCount: droppedCount ?? this.droppedCount,
      plannedDistance: plannedDistance ?? this.plannedDistance,
      actualDistance: actualDistance ?? this.actualDistance,
      notes: notes ?? this.notes,
      lines: lines ?? this.lines,
      // GPS Tracking
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastGpsUpdate: lastGpsUpdate ?? this.lastGpsUpdate,
      // Environmental Conditions
      weatherStatus: weatherStatus ?? this.weatherStatus,
      trafficStatus: trafficStatus ?? this.trafficStatus,
      riskLevel: riskLevel ?? this.riskLevel,
      // Capacity
      seatCapacity: seatCapacity ?? this.seatCapacity,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      occupancyRate: occupancyRate ?? this.occupancyRate,
      // Duration
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      // Company (Final Destination)
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyLatitude: companyLatitude ?? this.companyLatitude,
      companyLongitude: companyLongitude ?? this.companyLongitude,
      companyImage: companyImage ?? this.companyImage,
    );
  }

  @override
  String toString() => 'Trip(id: $id, name: $name, state: ${state.value})';
}

/// Trip Line Entity - كيان سطر الرحلة (الراكب)
/// محدث ليطابق shuttle.trip.line في Odoo
///
/// قاعدة الإحداثيات (من Odoo):
/// - إذا pickup_stop_id موجود → نستخدم إحداثيات المحطة
/// - إذا pickup_stop_id غير موجود وpickup_latitude/longitude موجودة → نستخدم الإحداثيات الشخصية
/// نفس القاعدة تنطبق على dropoff
class TripLine {
  final int id;
  final int tripId;
  final int? groupLineId;
  final int? passengerId;
  final String? passengerName;
  final String? passengerPhone;
  final String? passengerEmail;
  final TripLineStatus status;
  final int sequence;
  final int seatCount;

  // Pickup Location - المحطة
  final int? pickupStopId;
  final String? pickupStopName;
  final double? pickupStopLatitude;
  final double? pickupStopLongitude;

  // Pickup Location - الإحداثيات الشخصية (تستخدم عندما لا توجد محطة)
  final double? pickupLatitude;
  final double? pickupLongitude;

  // Dropoff Location - المحطة
  final int? dropoffStopId;
  final String? dropoffStopName;
  final double? dropoffStopLatitude;
  final double? dropoffStopLongitude;

  // Dropoff Location - الإحداثيات الشخصية (تستخدم عندما لا توجد محطة)
  final double? dropoffLatitude;
  final double? dropoffLongitude;

  // Legacy fields (for backward compatibility)
  final double? latitude;
  final double? longitude;
  final String? address;

  // Timestamps
  final DateTime? boardingTime;
  final DateTime? dropTime;

  // Notifications
  final bool approachingNotified;
  final bool arrivedNotified;
  final bool isAutoNotification; // هل يتم إرسال الإشعارات تلقائياً

  // Billing
  final bool isBillable;
  final double? price;

  // Absence
  final String? absenceReason;

  // Guardian Info
  final int? guardianId;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianEmail;

  final String? notes;

  const TripLine({
    required this.id,
    required this.tripId,
    this.groupLineId,
    this.passengerId,
    this.passengerName,
    this.passengerPhone,
    this.passengerEmail,
    this.status = TripLineStatus.notStarted,
    this.sequence = 0,
    this.seatCount = 1,
    this.pickupStopId,
    this.pickupStopName,
    this.pickupStopLatitude,
    this.pickupStopLongitude,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffStopId,
    this.dropoffStopName,
    this.dropoffStopLatitude,
    this.dropoffStopLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.latitude,
    this.longitude,
    this.address,
    this.boardingTime,
    this.dropTime,
    this.approachingNotified = false,
    this.arrivedNotified = false,
    this.isAutoNotification = true, // افتراضياً مفعل
    this.isBillable = true,
    this.price,
    this.absenceReason,
    this.guardianId,
    this.guardianName,
    this.guardianPhone,
    this.guardianEmail,
    this.notes,
  });

  /// Create from Odoo JSON
  /// البيانات تأتي مدمجة من trip_line + passenger + stops
  factory TripLine.fromOdoo(Map<String, dynamic> json) {
    // تحديد مصدر إحداثيات الصعود:
    // 1. إذا pickup_stop_id موجود في trip_line → استخدم المحطة
    // 2. إذا pickup_latitude/longitude موجودة في trip_line → استخدمها
    // 3. إذا use_gps_for_pickup = true للراكب → استخدم إحداثيات الراكب
    // 4. إذا default_pickup_stop_id موجود للراكب → استخدم المحطة الافتراضية

    final tripLinePickupStopId = Trip.extractId(json['pickup_stop_id']);
    final tripLineDropoffStopId = Trip.extractId(json['dropoff_stop_id']);
    final useGpsForPickup = json['use_gps_for_pickup'] as bool? ?? true;
    final useGpsForDropoff = json['use_gps_for_dropoff'] as bool? ?? true;

    // تحديد محطة الصعود وإحداثياتها
    int? pickupStopId;
    String? pickupStopName;
    double? pickupStopLat;
    double? pickupStopLng;
    double? pickupLat;
    double? pickupLng;

    if (tripLinePickupStopId != null) {
      // المحطة محددة في trip_line
      pickupStopId = tripLinePickupStopId;
      pickupStopName = Trip._extractString(json['pickup_stop_name']) ??
          Trip.extractName(json['pickup_stop_id']);
      pickupStopLat = Trip._extractDouble(json['pickup_stop_latitude']);
      pickupStopLng = Trip._extractDouble(json['pickup_stop_longitude']);
    } else if (Trip._extractDouble(json['pickup_latitude']) != null) {
      // إحداثيات مخصصة في trip_line
      pickupLat = Trip._extractDouble(json['pickup_latitude']);
      pickupLng = Trip._extractDouble(json['pickup_longitude']);
    } else if (useGpsForPickup) {
      // استخدام إحداثيات الراكب الشخصية
      pickupLat = Trip._extractDouble(json['passenger_latitude']);
      pickupLng = Trip._extractDouble(json['passenger_longitude']);
    } else {
      // استخدام المحطة الافتراضية من الراكب
      pickupStopId = Trip.extractId(json['default_pickup_stop_id']);
      pickupStopName = Trip._extractString(json['default_pickup_stop_name']);
      pickupStopLat = Trip._extractDouble(json['default_pickup_stop_latitude']);
      pickupStopLng =
          Trip._extractDouble(json['default_pickup_stop_longitude']);
    }

    // تحديد محطة النزول وإحداثياتها
    int? dropoffStopId;
    String? dropoffStopName;
    double? dropoffStopLat;
    double? dropoffStopLng;
    double? dropoffLat;
    double? dropoffLng;

    if (tripLineDropoffStopId != null) {
      // المحطة محددة في trip_line
      dropoffStopId = tripLineDropoffStopId;
      dropoffStopName = Trip._extractString(json['dropoff_stop_name']) ??
          Trip.extractName(json['dropoff_stop_id']);
      dropoffStopLat = Trip._extractDouble(json['dropoff_stop_latitude']);
      dropoffStopLng = Trip._extractDouble(json['dropoff_stop_longitude']);
    } else if (Trip._extractDouble(json['dropoff_latitude']) != null) {
      // إحداثيات مخصصة في trip_line
      dropoffLat = Trip._extractDouble(json['dropoff_latitude']);
      dropoffLng = Trip._extractDouble(json['dropoff_longitude']);
    } else if (!useGpsForDropoff) {
      // استخدام المحطة الافتراضية من الراكب
      dropoffStopId = Trip.extractId(json['default_dropoff_stop_id']);
      dropoffStopName = Trip._extractString(json['default_dropoff_stop_name']);
      dropoffStopLat =
          Trip._extractDouble(json['default_dropoff_stop_latitude']);
      dropoffStopLng =
          Trip._extractDouble(json['default_dropoff_stop_longitude']);
    }
    // Note: إذا use_gps_for_dropoff = true، نستخدم إحداثيات الشركة (غير متوفرة هنا)

    return TripLine(
      id: json['id'] as int? ?? 0,
      tripId: Trip.extractId(json['trip_id']) ?? 0,
      groupLineId: Trip.extractId(json['group_line_id']),
      passengerId: Trip.extractId(json['passenger_id'] ?? json['partner_id']),
      passengerName:
          Trip.extractName(json['passenger_id'] ?? json['partner_id']) ??
              Trip._extractString(json['passenger_name']),
      passengerPhone: Trip._extractString(json['passenger_phone']) ??
          Trip._extractString(json['phone']),
      passengerEmail: Trip._extractString(json['passenger_email']),
      status: TripLineStatus.tryFromString(
              Trip._extractString(json['status']) ??
                  Trip._extractString(json['state'])) ??
          TripLineStatus.notStarted,
      sequence: json['sequence'] as int? ?? 0,
      seatCount: json['seat_count'] as int? ?? 1,

      // Pickup Location
      pickupStopId: pickupStopId,
      pickupStopName: pickupStopName,
      pickupStopLatitude: pickupStopLat,
      pickupStopLongitude: pickupStopLng,
      pickupLatitude: pickupLat,
      pickupLongitude: pickupLng,

      // Dropoff Location
      dropoffStopId: dropoffStopId,
      dropoffStopName: dropoffStopName,
      dropoffStopLatitude: dropoffStopLat,
      dropoffStopLongitude: dropoffStopLng,
      dropoffLatitude: dropoffLat,
      dropoffLongitude: dropoffLng,

      // Legacy fields - للتوافق مع الإصدارات القديمة
      latitude: Trip._extractDouble(json['latitude']) ??
          Trip._extractDouble(json['lat']),
      longitude: Trip._extractDouble(json['longitude']) ??
          Trip._extractDouble(json['lng']),
      address: Trip._extractString(json['address']) ??
          Trip._extractString(json['location']),

      // Timestamps
      boardingTime: Trip.parseDateTime(json['boarding_time']),
      dropTime: Trip.parseDateTime(json['drop_time']),
      // Notifications
      approachingNotified: json['approaching_notified'] as bool? ?? false,
      arrivedNotified: json['arrived_notified'] as bool? ?? false,
      isAutoNotification: json['is_auto_notification'] as bool? ?? true,
      // Billing
      isBillable: json['is_billable'] as bool? ?? true,
      price: Trip._extractDouble(json['price']),
      // Absence
      absenceReason: Trip._extractString(json['absence_reason']),
      // Guardian Info
      guardianId: Trip.extractId(json['guardian_id']),
      guardianName: Trip.extractName(json['guardian_id']) ??
          Trip._extractString(json['guardian_name']),
      guardianPhone: Trip._extractString(json['guardian_phone']),
      guardianEmail: Trip._extractString(json['guardian_email']),
      notes: Trip._extractString(json['notes']),
    );
  }

  /// Create from JSON
  factory TripLine.fromJson(Map<String, dynamic> json) {
    return TripLine(
      id: json['id'] as int? ?? 0,
      tripId: json['tripId'] as int? ?? 0,
      groupLineId: json['groupLineId'] as int?,
      passengerId: json['passengerId'] as int?,
      passengerName: json['passengerName'] as String?,
      passengerPhone: json['passengerPhone'] as String?,
      passengerEmail: json['passengerEmail'] as String?,
      status: TripLineStatus.tryFromString(json['status'] as String?) ??
          TripLineStatus.notStarted,
      sequence: json['sequence'] as int? ?? 0,
      seatCount: json['seatCount'] as int? ?? 1,
      // Pickup Stop
      pickupStopId: json['pickupStopId'] as int?,
      pickupStopName: json['pickupStopName'] as String?,
      pickupStopLatitude: (json['pickupStopLatitude'] as num?)?.toDouble(),
      pickupStopLongitude: (json['pickupStopLongitude'] as num?)?.toDouble(),
      // Custom Pickup (الإحداثيات الشخصية)
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      // Dropoff Stop
      dropoffStopId: json['dropoffStopId'] as int?,
      dropoffStopName: json['dropoffStopName'] as String?,
      dropoffStopLatitude: (json['dropoffStopLatitude'] as num?)?.toDouble(),
      dropoffStopLongitude: (json['dropoffStopLongitude'] as num?)?.toDouble(),
      // Custom Dropoff (الإحداثيات الشخصية)
      dropoffLatitude: (json['dropoffLatitude'] as num?)?.toDouble(),
      dropoffLongitude: (json['dropoffLongitude'] as num?)?.toDouble(),
      // Legacy
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      boardingTime: json['boardingTime'] != null
          ? DateTime.parse(json['boardingTime'] as String)
          : null,
      dropTime: json['dropTime'] != null
          ? DateTime.parse(json['dropTime'] as String)
          : null,
      approachingNotified: json['approachingNotified'] as bool? ?? false,
      arrivedNotified: json['arrivedNotified'] as bool? ?? false,
      isAutoNotification: json['isAutoNotification'] as bool? ?? true,
      isBillable: json['isBillable'] as bool? ?? true,
      price: (json['price'] as num?)?.toDouble(),
      absenceReason: json['absenceReason'] as String?,
      guardianId: json['guardianId'] as int?,
      guardianName: json['guardianName'] as String?,
      guardianPhone: json['guardianPhone'] as String?,
      guardianEmail: json['guardianEmail'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'groupLineId': groupLineId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'passengerEmail': passengerEmail,
      'status': status.value,
      'sequence': sequence,
      'seatCount': seatCount,
      // Pickup Stop
      'pickupStopId': pickupStopId,
      'pickupStopName': pickupStopName,
      'pickupStopLatitude': pickupStopLatitude,
      'pickupStopLongitude': pickupStopLongitude,
      // Custom Pickup (الإحداثيات الشخصية)
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      // Dropoff Stop
      'dropoffStopId': dropoffStopId,
      'dropoffStopName': dropoffStopName,
      'dropoffStopLatitude': dropoffStopLatitude,
      'dropoffStopLongitude': dropoffStopLongitude,
      // Custom Dropoff (الإحداثيات الشخصية)
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      // Legacy
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'boardingTime': boardingTime?.toIso8601String(),
      'dropTime': dropTime?.toIso8601String(),
      'approachingNotified': approachingNotified,
      'arrivedNotified': arrivedNotified,
      'isAutoNotification': isAutoNotification,
      'isBillable': isBillable,
      'price': price,
      'absenceReason': absenceReason,
      'guardianId': guardianId,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'guardianEmail': guardianEmail,
      'notes': notes,
    };
  }

  // ============================================
  // خصائص الموقع المحسوبة (تطبيق قاعدة Odoo)
  // ============================================
  //
  // قاعدة Odoo:
  // - إذا pickup_stop_id موجود → نستخدم إحداثيات المحطة
  // - إذا pickup_stop_id غير موجود → نستخدم الإحداثيات الشخصية (pickup_latitude/longitude)
  // نفس القاعدة تنطبق على dropoff
  // ============================================

  /// هل يستخدم محطة للصعود (بدلاً من إحداثيات شخصية)
  bool get usesPickupStop => pickupStopId != null;

  /// هل يستخدم محطة للنزول (بدلاً من إحداثيات شخصية)
  bool get usesDropoffStop => dropoffStopId != null;

  /// هل يستخدم إحداثيات شخصية للصعود (بدلاً من محطة)
  bool get usesCustomPickupLocation =>
      pickupStopId == null && pickupLatitude != null && pickupLongitude != null;

  /// هل يستخدم إحداثيات شخصية للنزول (بدلاً من محطة)
  bool get usesCustomDropoffLocation =>
      dropoffStopId == null &&
      dropoffLatitude != null &&
      dropoffLongitude != null;

  /// الإحداثيات الفعلية للصعود
  /// إذا pickup_stop_id موجود → إحداثيات المحطة
  /// إذا pickup_stop_id غير موجود → الإحداثيات الشخصية
  double? get effectivePickupLatitude {
    if (pickupStopId != null) {
      // المحطة موجودة → نستخدم إحداثيات المحطة
      return pickupStopLatitude;
    }
    // لا توجد محطة → نستخدم الإحداثيات الشخصية
    return pickupLatitude;
  }

  double? get effectivePickupLongitude {
    if (pickupStopId != null) {
      return pickupStopLongitude;
    }
    return pickupLongitude;
  }

  /// الإحداثيات الفعلية للنزول
  /// إذا dropoff_stop_id موجود → إحداثيات المحطة
  /// إذا dropoff_stop_id غير موجود → الإحداثيات الشخصية
  double? get effectiveDropoffLatitude {
    if (dropoffStopId != null) {
      return dropoffStopLatitude;
    }
    return dropoffLatitude;
  }

  double? get effectiveDropoffLongitude {
    if (dropoffStopId != null) {
      return dropoffStopLongitude;
    }
    return dropoffLongitude;
  }

  /// هل لديه موقع صعود فعلي
  bool get hasPickupLocation =>
      effectivePickupLatitude != null && effectivePickupLongitude != null;

  /// هل لديه موقع نزول فعلي
  bool get hasDropoffLocation =>
      effectiveDropoffLatitude != null && effectiveDropoffLongitude != null;

  /// اسم موقع الصعود
  String get pickupLocationName {
    // إذا توجد محطة → اسم المحطة
    if (pickupStopId != null && pickupStopName != null) {
      return pickupStopName!;
    }
    // إذا لا توجد محطة ولكن توجد إحداثيات شخصية
    if (pickupLatitude != null && pickupLongitude != null) {
      return 'موقع مخصص';
    }
    return 'غير محدد';
  }

  /// اسم موقع النزول
  String get dropoffLocationName {
    if (dropoffStopId != null && dropoffStopName != null) {
      return dropoffStopName!;
    }
    if (dropoffLatitude != null && dropoffLongitude != null) {
      return 'موقع مخصص';
    }
    return 'غير محدد';
  }

  /// وصف موقع الصعود التفصيلي
  String get pickupLocationDescription {
    // إذا توجد محطة
    if (pickupStopId != null) {
      final name = pickupStopName ?? 'محطة #$pickupStopId';
      if (pickupStopLatitude != null && pickupStopLongitude != null) {
        return '$name (${pickupStopLatitude!.toStringAsFixed(6)}, ${pickupStopLongitude!.toStringAsFixed(6)})';
      }
      return name;
    }
    // إذا لا توجد محطة ولكن توجد إحداثيات شخصية
    if (pickupLatitude != null && pickupLongitude != null) {
      return 'إحداثيات شخصية: ${pickupLatitude!.toStringAsFixed(6)}, ${pickupLongitude!.toStringAsFixed(6)}';
    }
    return 'غير محدد';
  }

  /// وصف موقع النزول التفصيلي
  String get dropoffLocationDescription {
    if (dropoffStopId != null) {
      final name = dropoffStopName ?? 'محطة #$dropoffStopId';
      if (dropoffStopLatitude != null && dropoffStopLongitude != null) {
        return '$name (${dropoffStopLatitude!.toStringAsFixed(6)}, ${dropoffStopLongitude!.toStringAsFixed(6)})';
      }
      return name;
    }
    if (dropoffLatitude != null && dropoffLongitude != null) {
      return 'إحداثيات شخصية: ${dropoffLatitude!.toStringAsFixed(6)}, ${dropoffLongitude!.toStringAsFixed(6)}';
    }
    return 'غير محدد';
  }

  /// نوع موقع الصعود
  LocationType get pickupLocationType {
    if (pickupStopId != null) return LocationType.stop;
    if (pickupLatitude != null && pickupLongitude != null)
      return LocationType.custom;
    return LocationType.none;
  }

  /// نوع موقع النزول
  LocationType get dropoffLocationType {
    if (dropoffStopId != null) return LocationType.stop;
    if (dropoffLatitude != null && dropoffLongitude != null)
      return LocationType.custom;
    return LocationType.none;
  }

  /// هل لديه ولي أمر
  bool get hasGuardian => guardianId != null || guardianPhone != null;

  /// Copy with
  TripLine copyWith({
    int? id,
    int? tripId,
    int? groupLineId,
    int? passengerId,
    String? passengerName,
    String? passengerPhone,
    String? passengerEmail,
    TripLineStatus? status,
    int? sequence,
    int? seatCount,
    int? pickupStopId,
    String? pickupStopName,
    double? pickupStopLatitude,
    double? pickupStopLongitude,
    double? pickupLatitude,
    double? pickupLongitude,
    int? dropoffStopId,
    String? dropoffStopName,
    double? dropoffStopLatitude,
    double? dropoffStopLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? boardingTime,
    DateTime? dropTime,
    bool? approachingNotified,
    bool? arrivedNotified,
    bool? isAutoNotification,
    bool? isBillable,
    double? price,
    String? absenceReason,
    int? guardianId,
    String? guardianName,
    String? guardianPhone,
    String? guardianEmail,
    String? notes,
  }) {
    return TripLine(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      groupLineId: groupLineId ?? this.groupLineId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      status: status ?? this.status,
      sequence: sequence ?? this.sequence,
      seatCount: seatCount ?? this.seatCount,
      pickupStopId: pickupStopId ?? this.pickupStopId,
      pickupStopName: pickupStopName ?? this.pickupStopName,
      pickupStopLatitude: pickupStopLatitude ?? this.pickupStopLatitude,
      pickupStopLongitude: pickupStopLongitude ?? this.pickupStopLongitude,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropoffStopId: dropoffStopId ?? this.dropoffStopId,
      dropoffStopName: dropoffStopName ?? this.dropoffStopName,
      dropoffStopLatitude: dropoffStopLatitude ?? this.dropoffStopLatitude,
      dropoffStopLongitude: dropoffStopLongitude ?? this.dropoffStopLongitude,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      boardingTime: boardingTime ?? this.boardingTime,
      dropTime: dropTime ?? this.dropTime,
      approachingNotified: approachingNotified ?? this.approachingNotified,
      arrivedNotified: arrivedNotified ?? this.arrivedNotified,
      isAutoNotification: isAutoNotification ?? this.isAutoNotification,
      isBillable: isBillable ?? this.isBillable,
      price: price ?? this.price,
      absenceReason: absenceReason ?? this.absenceReason,
      guardianId: guardianId ?? this.guardianId,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'TripLine(id: $id, passenger: $passengerName, status: ${status.value})';
}
