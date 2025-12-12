import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/passenger_group.dart';

/// Group Remote Data Source - مصدر بيانات مجموعات الركاب
class GroupRemoteDataSource {
  final BridgecoreClient _client;

  static const String _groupModel = 'shuttle.passenger.group';
  static const String _scheduleModel = 'shuttle.passenger.group.schedule';
  static const String _holidayModel = 'shuttle.passenger.group.holiday';

  GroupRemoteDataSource(this._client);

  /// الحصول على جميع المجموعات
  Future<List<PassengerGroup>> getGroups({
    bool activeOnly = true,
    int? limit,
    int? offset,
  }) async {
    final domain = <List<dynamic>>[];

    if (activeOnly) {
      domain.add(['active', '=', true]);
    }

    final result = await _client.searchRead(
      model: _groupModel,
      domain: domain,
      fields: _groupFields,
      order: 'name asc',
      limit: limit,
      offset: offset,
    );

    return result.map((json) => PassengerGroup.fromOdoo(json)).toList();
  }

  /// الحصول على مجموعة بالمعرف
  Future<PassengerGroup?> getGroupById(int groupId) async {
    final result = await _client.searchRead(
      model: _groupModel,
      domain: [
        ['id', '=', groupId]
      ],
      fields: _groupFields,
      limit: 1,
    );

    if (result.isEmpty) return null;

    final group = PassengerGroup.fromOdoo(result.first);

    // تحميل الجداول
    final schedules = await getGroupSchedules(groupId);
    final holidays = await getGroupHolidays(groupId);

    return group.copyWith(
      schedules: schedules,
      holidays: holidays,
    );
  }

  /// الحصول على جداول المجموعة
  Future<List<GroupSchedule>> getGroupSchedules(int groupId) async {
    final result = await _client.searchRead(
      model: _scheduleModel,
      domain: [
        ['group_id', '=', groupId],
        ['active', '=', true],
      ],
      fields: _scheduleFields,
      order: 'weekday asc',
    );

    return result.map((json) => GroupSchedule.fromOdoo(json)).toList();
  }

  /// الحصول على عطلات المجموعة
  Future<List<GroupHoliday>> getGroupHolidays(int groupId) async {
    final result = await _client.searchRead(
      model: _holidayModel,
      domain: [
        ['group_id', '=', groupId],
        ['active', '=', true],
      ],
      fields: _holidayFields,
      order: 'start_date asc',
    );

    return result.map((json) => GroupHoliday.fromOdoo(json)).toList();
  }

  /// البحث عن مجموعات
  Future<List<PassengerGroup>> searchGroups(String query) async {
    final result = await _client.searchRead(
      model: _groupModel,
      domain: [
        '|',
        ['name', 'ilike', query],
        ['code', 'ilike', query],
      ],
      fields: _groupFields,
      order: 'name asc',
      limit: 20,
    );

    return result.map((json) => PassengerGroup.fromOdoo(json)).toList();
  }

  /// إنشاء مجموعة جديدة
  Future<PassengerGroup> createGroup(PassengerGroup group) async {
    final id = await _client.create(
      model: _groupModel,
      values: group.toOdoo(),
    );

    final created = await getGroupById(id);
    if (created == null) throw Exception('Failed to create group');
    return created;
  }

  /// تحديث مجموعة
  Future<PassengerGroup> updateGroup(PassengerGroup group) async {
    await _client.write(
      model: _groupModel,
      ids: [group.id],
      values: group.toOdoo(),
    );

    final updated = await getGroupById(group.id);
    if (updated == null) throw Exception('Failed to update group');
    return updated;
  }

  /// حذف مجموعة
  Future<bool> deleteGroup(int groupId) async {
    return await _client.unlink(
      model: _groupModel,
      ids: [groupId],
    );
  }

  /// إنشاء جدول للمجموعة
  Future<GroupSchedule?> createSchedule({
    required int groupId,
    required Weekday weekday,
    DateTime? pickupTime,
    DateTime? dropoffTime,
    bool createPickup = true,
    bool createDropoff = true,
  }) async {
    final values = {
      'group_id': groupId,
      'weekday': weekday.value,
      'create_pickup': createPickup,
      'create_dropoff': createDropoff,
    };

    if (pickupTime != null) {
      values['pickup_time'] = pickupTime.toIso8601String();
    }
    if (dropoffTime != null) {
      values['dropoff_time'] = dropoffTime.toIso8601String();
    }

    final id = await _client.create(
      model: _scheduleModel,
      values: values,
    );

    final result = await _client.searchRead(
      model: _scheduleModel,
      domain: [
        ['id', '=', id]
      ],
      fields: _scheduleFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return GroupSchedule.fromOdoo(result.first);
  }

  /// تحديث جدول
  Future<bool> updateSchedule(GroupSchedule schedule) async {
    return await _client.write(
      model: _scheduleModel,
      ids: [schedule.id],
      values: {
        'weekday': schedule.weekday.value,
        'create_pickup': schedule.createPickup,
        'create_dropoff': schedule.createDropoff,
        'active': schedule.active,
      },
    );
  }

  /// حذف جدول
  Future<bool> deleteSchedule(int scheduleId) async {
    return await _client.unlink(
      model: _scheduleModel,
      ids: [scheduleId],
    );
  }

  /// إنشاء عطلة للمجموعة
  Future<GroupHoliday?> createHoliday({
    required int groupId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final id = await _client.create(
      model: _holidayModel,
      values: {
        'group_id': groupId,
        'name': name,
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      },
    );

    final result = await _client.searchRead(
      model: _holidayModel,
      domain: [
        ['id', '=', id]
      ],
      fields: _holidayFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return GroupHoliday.fromOdoo(result.first);
  }

  /// حذف عطلة
  Future<bool> deleteHoliday(int holidayId) async {
    return await _client.unlink(
      model: _holidayModel,
      ids: [holidayId],
    );
  }

  /// توليد رحلات من الجدول
  Future<int> generateTripsFromSchedule(int groupId, {int weeks = 1}) async {
    try {
      final result = await _client.callKw(
        model: _groupModel,
        method: 'action_generate_trips',
        args: [
          [groupId]
        ],
        kwargs: {
          'weeks': weeks,
        },
      );

      if (result is int) return result;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// عدد المجموعات
  Future<int> getGroupCount({bool activeOnly = true}) async {
    final domain = <List<dynamic>>[];
    if (activeOnly) {
      domain.add(['active', '=', true]);
    }

    return await _client.searchCount(
      model: _groupModel,
      domain: domain,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// الحقول المطلوبة للمجموعات
  static const List<String> _groupFields = [
    'id',
    'name',
    'code',
    'driver_id',
    'vehicle_id',
    'total_seats',
    'trip_type',
    'destination_stop_id',
    'use_company_destination',
    'destination_latitude',
    'destination_longitude',
    'color',
    'notes',
    'active',
    'company_id',
    'member_count',
    'subscription_price',
    'billing_cycle',
    'auto_schedule_enabled',
    'auto_schedule_weeks',
    'auto_schedule_include_pickup',
    'auto_schedule_include_dropoff',
    'schedule_timezone',
  ];

  /// الحقول المطلوبة للجداول
  static const List<String> _scheduleFields = [
    'id',
    'group_id',
    'weekday',
    'pickup_time',
    'dropoff_time',
    'pickup_time_display',
    'dropoff_time_display',
    'create_pickup',
    'create_dropoff',
    'active',
  ];

  /// الحقول المطلوبة للعطلات
  static const List<String> _holidayFields = [
    'id',
    'group_id',
    'name',
    'start_date',
    'end_date',
    'active',
  ];
}

