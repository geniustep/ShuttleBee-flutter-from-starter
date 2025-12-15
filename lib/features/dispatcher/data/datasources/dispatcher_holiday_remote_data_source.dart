import '../../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/dispatcher_holiday.dart';

/// Dispatcher Holiday Remote Data Source
///
/// Uses Odoo/BridgeCore RPC to manage global holidays (`shuttle.holiday`).
class DispatcherHolidayRemoteDataSource {
  final BridgecoreClient _client;

  static const String _holidayModel = 'shuttle.holiday';

  DispatcherHolidayRemoteDataSource(this._client);

  Future<List<DispatcherHoliday>> getHolidays({bool activeOnly = true}) async {
    final domain = <List<dynamic>>[];
    if (activeOnly) {
      domain.add(['active', '=', true]);
    }

    final result = await _client.searchRead(
      model: _holidayModel,
      domain: domain,
      fields: _holidayFields,
      order: 'start_date asc, id asc',
      limit: 500,
      offset: 0,
    );

    return result.map((e) => DispatcherHoliday.fromOdoo(e)).toList();
  }

  Future<DispatcherHoliday?> getHolidayById(int holidayId) async {
    final result = await _client.searchRead(
      model: _holidayModel,
      domain: [
        ['id', '=', holidayId],
      ],
      fields: _holidayFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DispatcherHoliday.fromOdoo(result.first);
  }

  Future<DispatcherHoliday?> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final id = await _client.create(
      model: _holidayModel,
      values: {
        'name': name,
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    final result = await _client.searchRead(
      model: _holidayModel,
      domain: [
        ['id', '=', id],
      ],
      fields: _holidayFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DispatcherHoliday.fromOdoo(result.first);
  }

  Future<bool> updateHoliday({
    required int holidayId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    bool? active,
  }) async {
    final values = <String, dynamic>{
      'name': name,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      if (notes != null) 'notes': notes.trim(),
      if (active != null) 'active': active,
    };

    return await _client.write(
      model: _holidayModel,
      ids: [holidayId],
      values: values,
    );
  }

  Future<bool> deleteHoliday(int holidayId) async {
    return await _client.unlink(
      model: _holidayModel,
      ids: [holidayId],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static const List<String> _holidayFields = [
    'id',
    'name',
    'start_date',
    'end_date',
    'active',
    'notes',
    'company_id',
  ];
}
