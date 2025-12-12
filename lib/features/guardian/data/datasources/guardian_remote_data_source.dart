import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../domain/entities/guardian_info.dart';

/// Guardian Remote Data Source - مصدر بيانات ولي الأمر
class GuardianRemoteDataSource {
  final BridgecoreClient _client;

  static const String _partnerModel = 'res.partner';
  static const String _tripLineModel = 'shuttle.trip.line';
  static const String _tripModel = 'shuttle.trip';

  GuardianRemoteDataSource(this._client);

  /// الحصول على معلومات ولي الأمر مع التابعين
  Future<GuardianInfo?> getGuardianInfo(int guardianId) async {
    final result = await _client.searchRead(
      model: _partnerModel,
      domain: [
        ['id', '=', guardianId]
      ],
      fields: _guardianFields,
      limit: 1,
    );

    if (result.isEmpty) return null;

    final guardian = GuardianInfo.fromOdoo(result.first);

    // تحميل التابعين
    final dependents = await getDependents(guardianId);

    return guardian.copyWith(dependents: dependents);
  }

  /// الحصول على التابعين
  Future<List<DependentPassenger>> getDependents(int guardianId) async {
    final result = await _client.searchRead(
      model: _partnerModel,
      domain: [
        ['shuttle_guardian_id', '=', guardianId],
        ['is_shuttle_passenger', '=', true],
      ],
      fields: _dependentFields,
      order: 'name asc',
    );

    return result.map((json) => DependentPassenger.fromOdoo(json)).toList();
  }

  /// الحصول على رحلات التابعين
  Future<List<Trip>> getDependentTrips(int dependentId, {
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 20,
  }) async {
    // أولاً نحصل على trip lines للتابع
    final linesDomain = <List<dynamic>>[
      ['passenger_id', '=', dependentId],
    ];

    if (fromDate != null) {
      linesDomain.add(['trip_id.date', '>=', _formatDate(fromDate)]);
    }
    if (toDate != null) {
      linesDomain.add(['trip_id.date', '<=', _formatDate(toDate)]);
    }

    final lines = await _client.searchRead(
      model: _tripLineModel,
      domain: linesDomain,
      fields: ['trip_id'],
      order: 'trip_id desc',
      limit: limit,
    );

    if (lines.isEmpty) return [];

    final tripIds = lines
        .map((l) => Trip.extractId(l['trip_id']))
        .whereType<int>()
        .toSet()
        .toList();

    if (tripIds.isEmpty) return [];

    final result = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['id', 'in', tripIds]
      ],
      fields: _tripFields,
      order: 'date desc, planned_start_time asc',
    );

    return result.map((json) => Trip.fromOdoo(json)).toList();
  }

  /// الحصول على رحلات اليوم للتابعين
  Future<List<Trip>> getTodayTripsForDependents(List<int> dependentIds) async {
    if (dependentIds.isEmpty) return [];

    final today = DateTime.now();
    final dateStr = _formatDate(today);

    // الحصول على trip lines للتابعين اليوم
    final lines = await _client.searchRead(
      model: _tripLineModel,
      domain: [
        ['passenger_id', 'in', dependentIds],
        ['trip_id.date', '=', dateStr],
      ],
      fields: ['trip_id', 'passenger_id', 'status'],
    );

    if (lines.isEmpty) return [];

    final tripIds = lines
        .map((l) => Trip.extractId(l['trip_id']))
        .whereType<int>()
        .toSet()
        .toList();

    if (tripIds.isEmpty) return [];

    final result = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['id', 'in', tripIds]
      ],
      fields: _tripFields,
      order: 'planned_start_time asc',
    );

    return result.map((json) => Trip.fromOdoo(json)).toList();
  }

  /// الحصول على الرحلة النشطة للتابع
  Future<Trip?> getActiveTripForDependent(int dependentId) async {
    final lines = await _client.searchRead(
      model: _tripLineModel,
      domain: [
        ['passenger_id', '=', dependentId],
        ['trip_id.state', '=', 'ongoing'],
      ],
      fields: ['trip_id'],
      limit: 1,
    );

    if (lines.isEmpty) return null;

    final tripId = Trip.extractId(lines.first['trip_id']);
    if (tripId == null) return null;

    final result = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['id', '=', tripId]
      ],
      fields: _tripFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Trip.fromOdoo(result.first);
  }

  /// تسجيل غياب مسبق
  Future<bool> reportAbsence({
    required int dependentId,
    required DateTime date,
    String? reason,
  }) async {
    try {
      // البحث عن trip line للتابع في التاريخ المحدد
      final dateStr = _formatDate(date);
      final lines = await _client.searchRead(
        model: _tripLineModel,
        domain: [
          ['passenger_id', '=', dependentId],
          ['trip_id.date', '=', dateStr],
          ['status', '=', 'planned'],
        ],
        fields: ['id'],
      );

      if (lines.isEmpty) return false;

      // تحديث الحالة إلى غائب
      for (final line in lines) {
        await _client.callKw(
          model: _tripLineModel,
          method: 'action_absent',
          args: [
            [line['id'] as int]
          ],
          kwargs: {
            if (reason != null) 'reason': reason,
          },
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// تحديث معلومات التابع
  Future<bool> updateDependentInfo({
    required int dependentId,
    int? pickupStopId,
    int? dropoffStopId,
    String? notes,
  }) async {
    try {
      final values = <String, dynamic>{};
      
      if (pickupStopId != null) {
        values['shuttle_default_pickup_stop_id'] = pickupStopId;
      }
      if (dropoffStopId != null) {
        values['shuttle_default_dropoff_stop_id'] = dropoffStopId;
      }
      if (notes != null) {
        values['shuttle_notes'] = notes;
      }

      if (values.isEmpty) return true;

      return await _client.write(
        model: _partnerModel,
        ids: [dependentId],
        values: values,
      );
    } catch (e) {
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// حقول ولي الأمر
  static const List<String> _guardianFields = [
    'id',
    'name',
    'phone',
    'mobile',
    'email',
    'shuttle_portal_token',
    'company_id',
  ];

  /// حقول التابع
  static const List<String> _dependentFields = [
    'id',
    'name',
    'phone',
    'mobile',
    'email',
    'shuttle_default_pickup_stop_id',
    'shuttle_default_dropoff_stop_id',
    'shuttle_direction',
    'shuttle_notes',
    'shuttle_total_trips',
    'shuttle_present_trips',
    'shuttle_absent_trips',
    'shuttle_attendance_rate',
  ];

  /// حقول الرحلة
  static const List<String> _tripFields = [
    'id',
    'name',
    'display_name',
    'state',
    'trip_type',
    'date',
    'planned_start_time',
    'planned_arrival_time',
    'actual_start_time',
    'actual_arrival_time',
    'driver_id',
    'vehicle_id',
    'group_id',
    'total_passengers',
    'boarded_count',
    'absent_count',
    'current_latitude',
    'current_longitude',
    'last_gps_update',
    'notes',
  ];
}

