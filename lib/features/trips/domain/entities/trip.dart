import '../../../../core/enums/enums.dart';

/// Trip Entity - كيان الرحلة - ShuttleBee
class Trip {
  final int id;
  final String name;
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

  const Trip({
    required this.id,
    required this.name,
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
  });

  /// Create from Odoo JSON response
  factory Trip.fromOdoo(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int? ?? 0,
      name: _extractString(json['name']) ?? _extractString(json['display_name']) ?? '',
      state:
          TripState.tryFromString(_extractString(json['state'])) ?? TripState.draft,
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
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
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
    );
  }

  @override
  String toString() => 'Trip(id: $id, name: $name, state: ${state.value})';
}

/// Trip Line Entity - كيان سطر الرحلة (الراكب)
class TripLine {
  final int id;
  final int tripId;
  final int? passengerId;
  final String? passengerName;
  final String? passengerPhone;
  final TripLineStatus status;
  final int sequence;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? boardingTime;
  final DateTime? dropTime;
  final String? notes;

  const TripLine({
    required this.id,
    required this.tripId,
    this.passengerId,
    this.passengerName,
    this.passengerPhone,
    this.status = TripLineStatus.notStarted,
    this.sequence = 0,
    this.latitude,
    this.longitude,
    this.address,
    this.boardingTime,
    this.dropTime,
    this.notes,
  });

  /// Create from Odoo JSON
  factory TripLine.fromOdoo(Map<String, dynamic> json) {
    return TripLine(
      id: json['id'] as int? ?? 0,
      tripId: Trip.extractId(json['trip_id']) ?? 0,
      passengerId: Trip.extractId(json['passenger_id'] ?? json['partner_id']),
      passengerName:
          Trip.extractName(json['passenger_id'] ?? json['partner_id']) ??
              Trip._extractString(json['passenger_name']),
      passengerPhone:
          Trip._extractString(json['passenger_phone']) ?? Trip._extractString(json['phone']),
      status: TripLineStatus.tryFromString(
              Trip._extractString(json['status']) ?? Trip._extractString(json['state'])) ??
          TripLineStatus.notStarted,
      sequence: json['sequence'] as int? ?? 0,
      latitude: Trip._extractDouble(json['latitude']) ??
          Trip._extractDouble(json['lat']),
      longitude: Trip._extractDouble(json['longitude']) ??
          Trip._extractDouble(json['lng']),
      address: Trip._extractString(json['address']) ?? Trip._extractString(json['location']),
      boardingTime: Trip.parseDateTime(json['boarding_time']),
      dropTime: Trip.parseDateTime(json['drop_time']),
      notes: Trip._extractString(json['notes']),
    );
  }

  /// Create from JSON
  factory TripLine.fromJson(Map<String, dynamic> json) {
    return TripLine(
      id: json['id'] as int? ?? 0,
      tripId: json['tripId'] as int? ?? 0,
      passengerId: json['passengerId'] as int?,
      passengerName: json['passengerName'] as String?,
      passengerPhone: json['passengerPhone'] as String?,
      status: TripLineStatus.tryFromString(json['status'] as String?) ??
          TripLineStatus.notStarted,
      sequence: json['sequence'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      boardingTime: json['boardingTime'] != null
          ? DateTime.parse(json['boardingTime'] as String)
          : null,
      dropTime: json['dropTime'] != null
          ? DateTime.parse(json['dropTime'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'status': status.value,
      'sequence': sequence,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'boardingTime': boardingTime?.toIso8601String(),
      'dropTime': dropTime?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Copy with
  TripLine copyWith({
    int? id,
    int? tripId,
    int? passengerId,
    String? passengerName,
    String? passengerPhone,
    TripLineStatus? status,
    int? sequence,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? boardingTime,
    DateTime? dropTime,
    String? notes,
  }) {
    return TripLine(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      status: status ?? this.status,
      sequence: sequence ?? this.sequence,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      boardingTime: boardingTime ?? this.boardingTime,
      dropTime: dropTime ?? this.dropTime,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'TripLine(id: $id, passenger: $passengerName, status: ${status.value})';
}
