import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/shuttle_stop.dart';

/// Stop Remote Data Source - مصدر بيانات نقاط التوقف
class StopRemoteDataSource {
  final BridgecoreClient _client;

  static const String _stopModel = 'shuttle.stop';

  StopRemoteDataSource(this._client);

  /// الحصول على جميع نقاط التوقف
  Future<List<ShuttleStop>> getStops({
    StopType? stopType,
    bool activeOnly = true,
    int? limit,
    int? offset,
  }) async {
    final domain = <List<dynamic>>[];

    if (activeOnly) {
      domain.add(['active', '=', true]);
    }

    if (stopType != null) {
      domain.add(['stop_type', 'in', ['both', stopType.value]]);
    }

    final result = await _client.searchRead(
      model: _stopModel,
      domain: domain,
      fields: _stopFields,
      order: 'sequence asc, name asc',
      limit: limit,
      offset: offset,
    );

    return result.map((json) => ShuttleStop.fromOdoo(json)).toList();
  }

  /// الحصول على نقطة توقف بالمعرف
  Future<ShuttleStop?> getStopById(int stopId) async {
    final result = await _client.searchRead(
      model: _stopModel,
      domain: [
        ['id', '=', stopId]
      ],
      fields: _stopFields,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ShuttleStop.fromOdoo(result.first);
  }

  /// البحث عن نقاط التوقف
  Future<List<ShuttleStop>> searchStops(String query) async {
    final result = await _client.searchRead(
      model: _stopModel,
      domain: [
        '|',
        ['name', 'ilike', query],
        ['code', 'ilike', query],
      ],
      fields: _stopFields,
      order: 'sequence asc, name asc',
      limit: 20,
    );

    return result.map((json) => ShuttleStop.fromOdoo(json)).toList();
  }

  /// اقتراح أقرب نقاط التوقف
  Future<List<StopSuggestion>> suggestNearestStops({
    required double latitude,
    required double longitude,
    StopType? stopType,
    int limit = 5,
  }) async {
    try {
      final result = await _client.callKw(
        model: _stopModel,
        method: 'suggest_nearest',
        args: [latitude, longitude],
        kwargs: {
          'limit': limit,
          if (stopType != null) 'stop_type': stopType.value,
        },
      );

      if (result is List) {
        return result
            .map((json) => StopSuggestion.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Fallback: حساب المسافة محلياً
    }

    return [];
  }

  /// إنشاء نقطة توقف جديدة
  Future<ShuttleStop> createStop(ShuttleStop stop) async {
    final id = await _client.create(
      model: _stopModel,
      values: stop.toOdoo(),
    );

    final created = await getStopById(id);
    if (created == null) throw Exception('Failed to create stop');
    return created;
  }

  /// تحديث نقطة توقف
  Future<ShuttleStop> updateStop(ShuttleStop stop) async {
    await _client.write(
      model: _stopModel,
      ids: [stop.id],
      values: stop.toOdoo(),
    );

    final updated = await getStopById(stop.id);
    if (updated == null) throw Exception('Failed to update stop');
    return updated;
  }

  /// حذف نقطة توقف
  Future<bool> deleteStop(int stopId) async {
    return await _client.unlink(
      model: _stopModel,
      ids: [stopId],
    );
  }

  /// عدد نقاط التوقف
  Future<int> getStopCount({bool activeOnly = true}) async {
    final domain = <List<dynamic>>[];
    if (activeOnly) {
      domain.add(['active', '=', true]);
    }

    return await _client.searchCount(
      model: _stopModel,
      domain: domain,
    );
  }

  /// الحقول المطلوبة
  static const List<String> _stopFields = [
    'id',
    'name',
    'code',
    'street',
    'street2',
    'city',
    'state_id',
    'zip',
    'country_id',
    'latitude',
    'longitude',
    'stop_type',
    'active',
    'color',
    'sequence',
    'usage_count',
    'notes',
    'company_id',
  ];
}

