/// Passenger Group Line Entity
///
/// Maps to Odoo model: `shuttle.passenger.group.line`
class PassengerGroupLine {
  final int id;

  /// Can be null/false for "unassigned" passengers.
  final int? groupId;
  final String? groupName;

  final int passengerId;
  final String passengerName;

  final int sequence;
  final int seatCount;
  final String? notes;

  final int? pickupStopId;
  final String? pickupStopName;

  final int? dropoffStopId;
  final String? dropoffStopName;

  /// Stored computed fields on the backend.
  final String? pickupInfoDisplay;
  final String? dropoffInfoDisplay;

  /// Related fields (not stored) but readable via RPC.
  final String? passengerPhone;
  final String? passengerMobile;

  /// Guardian fields (new structure)
  final String? fatherPhone;
  final String? motherPhone;

  /// Legacy field (kept for backward compatibility)
  final String? guardianPhone;

  const PassengerGroupLine({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    this.groupId,
    this.groupName,
    this.sequence = 10,
    this.seatCount = 1,
    this.notes,
    this.pickupStopId,
    this.pickupStopName,
    this.dropoffStopId,
    this.dropoffStopName,
    this.pickupInfoDisplay,
    this.dropoffInfoDisplay,
    this.passengerPhone,
    this.passengerMobile,
    this.fatherPhone,
    this.motherPhone,
    this.guardianPhone,
  });

  /// Get the best guardian contact available
  String get primaryGuardianPhone {
    if (fatherPhone != null && fatherPhone!.isNotEmpty) return fatherPhone!;
    if (motherPhone != null && motherPhone!.isNotEmpty) return motherPhone!;
    if (guardianPhone != null && guardianPhone!.isNotEmpty)
      return guardianPhone!;
    return '';
  }

  /// Get guardian display with label
  String get guardianContactDisplay {
    if (fatherPhone != null && fatherPhone!.isNotEmpty)
      return 'الأب: $fatherPhone';
    if (motherPhone != null && motherPhone!.isNotEmpty)
      return 'الأم: $motherPhone';
    if (guardianPhone != null && guardianPhone!.isNotEmpty)
      return 'ولي الأمر: $guardianPhone';
    return '';
  }

  factory PassengerGroupLine.fromOdoo(Map<String, dynamic> json) {
    return PassengerGroupLine(
      id: json['id'] as int? ?? 0,
      groupId: _extractId(json['group_id']),
      groupName: _extractName(json['group_id']),
      passengerId: _extractId(json['passenger_id']) ?? 0,
      passengerName: _extractName(json['passenger_id']) ??
          (json['passenger_name']?.toString() ?? ''),
      sequence: (json['sequence'] as num?)?.toInt() ?? 10,
      seatCount: (json['seat_count'] as num?)?.toInt() ?? 1,
      notes: _extractString(json['notes']),
      pickupStopId: _extractId(json['pickup_stop_id']),
      pickupStopName: _extractName(json['pickup_stop_id']),
      dropoffStopId: _extractId(json['dropoff_stop_id']),
      dropoffStopName: _extractName(json['dropoff_stop_id']),
      pickupInfoDisplay: _extractString(json['pickup_info_display']),
      dropoffInfoDisplay: _extractString(json['dropoff_info_display']),
      passengerPhone: _extractString(json['passenger_phone'] ?? json['phone']),
      passengerMobile:
          _extractString(json['passenger_mobile'] ?? json['mobile']),
      fatherPhone: _extractString(json['father_phone']),
      motherPhone: _extractString(json['mother_phone']),
      guardianPhone: _extractString(json['guardian_phone']),
    );
  }

  /// Local JSON for caching/state.
  factory PassengerGroupLine.fromJson(Map<String, dynamic> json) {
    return PassengerGroupLine(
      id: json['id'] as int? ?? 0,
      groupId: json['group_id'] as int?,
      groupName: json['group_name'] as String?,
      passengerId: json['passenger_id'] as int? ?? 0,
      passengerName: json['passenger_name'] as String? ?? '',
      sequence: json['sequence'] as int? ?? 10,
      seatCount: json['seat_count'] as int? ?? 1,
      notes: json['notes'] as String?,
      pickupStopId: json['pickup_stop_id'] as int?,
      pickupStopName: json['pickup_stop_name'] as String?,
      dropoffStopId: json['dropoff_stop_id'] as int?,
      dropoffStopName: json['dropoff_stop_name'] as String?,
      pickupInfoDisplay: json['pickup_info_display'] as String?,
      dropoffInfoDisplay: json['dropoff_info_display'] as String?,
      passengerPhone: json['passenger_phone'] as String?,
      passengerMobile: json['passenger_mobile'] as String?,
      fatherPhone: json['father_phone'] as String?,
      motherPhone: json['mother_phone'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'group_name': groupName,
        'passenger_id': passengerId,
        'passenger_name': passengerName,
        'sequence': sequence,
        'seat_count': seatCount,
        'notes': notes,
        'pickup_stop_id': pickupStopId,
        'pickup_stop_name': pickupStopName,
        'dropoff_stop_id': dropoffStopId,
        'dropoff_stop_name': dropoffStopName,
        'pickup_info_display': pickupInfoDisplay,
        'dropoff_info_display': dropoffInfoDisplay,
        'passenger_phone': passengerPhone,
        'passenger_mobile': passengerMobile,
        'father_phone': fatherPhone,
        'mother_phone': motherPhone,
        'guardian_phone': guardianPhone,
      };

  static String? _extractString(dynamic value) {
    if (value == null || value == false) return null;
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

  PassengerGroupLine copyWith({
    int? id,
    int? groupId,
    String? groupName,
    int? passengerId,
    String? passengerName,
    int? sequence,
    int? seatCount,
    String? notes,
    int? pickupStopId,
    String? pickupStopName,
    int? dropoffStopId,
    String? dropoffStopName,
    String? pickupInfoDisplay,
    String? dropoffInfoDisplay,
    String? passengerPhone,
    String? passengerMobile,
    String? fatherPhone,
    String? motherPhone,
    String? guardianPhone,
  }) {
    return PassengerGroupLine(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      sequence: sequence ?? this.sequence,
      seatCount: seatCount ?? this.seatCount,
      notes: notes ?? this.notes,
      pickupStopId: pickupStopId ?? this.pickupStopId,
      pickupStopName: pickupStopName ?? this.pickupStopName,
      dropoffStopId: dropoffStopId ?? this.dropoffStopId,
      dropoffStopName: dropoffStopName ?? this.dropoffStopName,
      pickupInfoDisplay: pickupInfoDisplay ?? this.pickupInfoDisplay,
      dropoffInfoDisplay: dropoffInfoDisplay ?? this.dropoffInfoDisplay,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerMobile: passengerMobile ?? this.passengerMobile,
      fatherPhone: fatherPhone ?? this.fatherPhone,
      motherPhone: motherPhone ?? this.motherPhone,
      guardianPhone: guardianPhone ?? this.guardianPhone,
    );
  }

  bool get isUnassigned => groupId == null;
}
