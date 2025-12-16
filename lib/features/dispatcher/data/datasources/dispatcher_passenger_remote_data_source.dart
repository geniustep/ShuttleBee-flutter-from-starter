import '../../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/passenger_group_line.dart';

/// Dispatcher Passenger Data Source
///
/// Uses Odoo/BridgeCore RPC to manage passengers within groups.
class DispatcherPassengerRemoteDataSource {
  final BridgecoreClient _client;

  static const String _lineModel = 'shuttle.passenger.group.line';
  static const int _pageSize = 500;
  static const int _maxRecords = 20000;

  DispatcherPassengerRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> _searchReadAllLines({
    required List<dynamic> domain,
    required String order,
  }) async {
    final all = <Map<String, dynamic>>[];
    final seenIds = <int>{};

    var offset = 0;
    while (true) {
      final page = await _client.searchRead(
        model: _lineModel,
        domain: domain,
        fields: _lineFields,
        order: order,
        limit: _pageSize,
        offset: offset,
      );

      if (page.isEmpty) break;

      var anyNew = false;
      for (final row in page) {
        final id = row['id'];
        if (id is int) {
          if (seenIds.add(id)) {
            all.add(row);
            anyNew = true;
          }
        } else {
          all.add(row);
          anyNew = true;
        }

        if (all.length >= _maxRecords) return all;
      }

      if (!anyNew) break;
      offset += page.length;
    }

    return all;
  }

  Future<List<PassengerGroupLine>> getGroupPassengers(int groupId) async {
    final result = await _client.searchRead(
      model: _lineModel,
      domain: [
        ['group_id', '=', groupId],
      ],
      fields: _lineFields,
      order: 'sequence asc, id asc',
      limit: 500,
      offset: 0,
    );

    return result.map((e) => PassengerGroupLine.fromOdoo(e)).toList();
  }

  Future<List<PassengerGroupLine>> getPassengerLines(int passengerId) async {
    final result = await _client.searchRead(
      model: _lineModel,
      domain: [
        ['passenger_id', '=', passengerId],
      ],
      fields: _lineFields,
      order: 'group_id asc, sequence asc, id asc',
      limit: 500,
      offset: 0,
    );

    return result.map((e) => PassengerGroupLine.fromOdoo(e)).toList();
  }

  /// Ensure backend created "unassigned" lines for all shuttle passengers.
  ///
  /// Odoo module implements this inside `read_group` override.
  Future<void> syncUnassignedPassengers() async {
    // NOTE:
    // We intentionally call Odoo's `read_group` via `call_kw` here.
    //
    // Some Bridgecore deployments reject the dedicated `/read_group` endpoint when
    // "ids" is empty (it may attempt to browse([]) and raise "record not found"),
    // while `call_kw` properly mirrors Odoo's execute_kw behavior for read_group.
    //
    // This is best-effort: even if the sync fails, fetching unassigned passengers
    // via search_read can still succeed.
    try {
      await _client.callKw(
        model: _lineModel,
        method: 'read_group',
        args: const [
          [],
          ['group_id'],
          ['group_id'],
        ],
        kwargs: const {
          'offset': 0,
          'limit': 1,
          'lazy': true,
        },
      );
    } catch (_) {
      // Ignore: sync is a convenience, not required for correctness.
    }
  }

  Future<List<PassengerGroupLine>> getUnassignedPassengers() async {
    // Trigger backend sync to populate unassigned passengers if missing.
    await syncUnassignedPassengers();

    final result = await _searchReadAllLines(
      domain: [
        ['group_id', '=', false],
      ],
      order: 'passenger_id asc, id asc',
    );

    return result.map((e) => PassengerGroupLine.fromOdoo(e)).toList();
  }

  /// Passengers assigned to other groups (group_id != false and != groupId).
  /// If groupId is 0, returns all passengers in any group.
  Future<List<PassengerGroupLine>> getPassengersInOtherGroups(
    int groupId,
  ) async {
    final domain = <List<dynamic>>[
      ['group_id', '!=', false],
    ];

    // If groupId > 0, exclude that specific group
    if (groupId > 0) {
      domain.add(['group_id', '!=', groupId]);
    }

    final result = await _searchReadAllLines(
      domain: domain,
      order: 'group_id asc, passenger_id asc, id asc',
    );

    return result.map((e) => PassengerGroupLine.fromOdoo(e)).toList();
  }

  Future<void> assignLineToGroup({
    required int lineId,
    required int groupId,
  }) async {
    await _client.write(
      model: _lineModel,
      ids: [lineId],
      values: {
        'group_id': groupId,
      },
    );
  }

  Future<void> unassignLine({required int lineId}) async {
    await _client.write(
      model: _lineModel,
      ids: [lineId],
      values: const {
        'group_id': false,
      },
    );
  }

  Future<void> updateLine({
    required int lineId,
    int? seatCount,
    int? sequence,
    String? notes,
    int? pickupStopId,
    int? dropoffStopId,
  }) async {
    final values = <String, dynamic>{
      if (seatCount != null) 'seat_count': seatCount,
      if (sequence != null) 'sequence': sequence,
      if (notes != null) 'notes': notes,
      if (pickupStopId != null) 'pickup_stop_id': pickupStopId,
      if (dropoffStopId != null) 'dropoff_stop_id': dropoffStopId,
    };

    if (values.isEmpty) return;

    await _client.write(
      model: _lineModel,
      ids: [lineId],
      values: values,
    );
  }

  Future<void> deleteLine({required int lineId}) async {
    await _client.unlink(
      model: _lineModel,
      ids: [lineId],
    );
  }

  static const List<String> _lineFields = [
    'id',
    'group_id',
    'sequence',
    'passenger_id',
    'pickup_stop_id',
    'dropoff_stop_id',
    'seat_count',
    'notes',
    'pickup_info_display',
    'dropoff_info_display',
    'passenger_phone',
    'passenger_mobile',
    'father_phone',
    'mother_phone',
    // Note: guardian_phone was removed from Odoo model shuttle.passenger.group.line
    // Use father_phone and mother_phone instead
  ];
}
