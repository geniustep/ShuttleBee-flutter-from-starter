import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../../../core/enums/enums.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

/// Trip Remote Data Source - ShuttleBee
class TripRemoteDataSource {
  final BridgecoreClient _client;

  /// Odoo model name for trips
  static const String _tripModel = 'shuttlebee.trip';
  static const String _tripLineModel = 'shuttlebee.trip.line';

  TripRemoteDataSource(this._client);

  /// Get trips by date
  Future<List<Trip>> getTripsByDate(DateTime date) async {
    final dateStr = _formatDate(date);

    final result = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['date', '=', dateStr],
      ],
      fields: _tripFields,
      order: 'planned_start_time asc',
    );

    return result.map((json) => Trip.fromOdoo(json)).toList();
  }

  /// Get driver trips for a date
  Future<List<Trip>> getDriverTrips(int driverId, DateTime date) async {
    final dateStr = _formatDate(date);

    final result = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['driver_id', '=', driverId],
        ['date', '=', dateStr],
        [
          'state',
          'in',
          ['planned', 'ongoing']
        ],
      ],
      fields: _tripFields,
      order: 'planned_start_time asc',
    );

    return result.map((json) => Trip.fromOdoo(json)).toList();
  }

  /// Get passenger trips
  Future<List<Trip>> getPassengerTrips(int passengerId) async {
    // First get trip lines for this passenger
    final lines = await _client.searchRead(
      model: _tripLineModel,
      domain: [
        ['passenger_id', '=', passengerId],
      ],
      fields: ['trip_id'],
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
        ['id', 'in', tripIds],
      ],
      fields: _tripFields,
      order: 'date desc, planned_start_time asc',
    );

    return result.map((json) => Trip.fromOdoo(json)).toList();
  }

  /// Get trip by ID with lines
  Future<Trip> getTripById(int tripId) async {
    final result = await _client.read(
      model: _tripModel,
      ids: [tripId],
      fields: _tripFields,
    );

    if (result.isEmpty) {
      throw Exception('Trip not found');
    }

    final trip = Trip.fromOdoo(result.first);

    // Load trip lines
    final lines = await getTripLines(tripId);

    return trip.copyWith(lines: lines);
  }

  /// Get trip lines
  Future<List<TripLine>> getTripLines(int tripId) async {
    final result = await _client.searchRead(
      model: _tripLineModel,
      domain: [
        ['trip_id', '=', tripId],
      ],
      fields: _tripLineFields,
      order: 'sequence asc',
    );

    return result.map((json) => TripLine.fromOdoo(json)).toList();
  }

  /// Get trips with filters
  Future<List<Trip>> getTrips({
    TripState? state,
    TripType? tripType,
    DateTime? fromDate,
    DateTime? toDate,
    int? driverId,
    int? vehicleId,
    int limit = 50,
    int offset = 0,
  }) async {
    final domain = <List<dynamic>>[];

    if (state != null) {
      domain.add(['state', '=', state.value]);
    }
    if (tripType != null) {
      domain.add(['trip_type', '=', tripType.value]);
    }
    if (fromDate != null) {
      domain.add(['date', '>=', _formatDate(fromDate)]);
    }
    if (toDate != null) {
      domain.add(['date', '<=', _formatDate(toDate)]);
    }
    if (driverId != null) {
      domain.add(['driver_id', '=', driverId]);
    }
    if (vehicleId != null) {
      domain.add(['vehicle_id', '=', vehicleId]);
    }

    final result = await _client.searchRead(
      model: _tripModel,
      domain: domain,
      fields: _tripFields,
      limit: limit,
      offset: offset,
      order: 'date desc, planned_start_time asc',
    );

    return result.map((json) => Trip.fromOdoo(json)).toList();
  }

  /// Create trip
  Future<Trip> createTrip(Trip trip) async {
    final values = _tripToOdooValues(trip);

    final id = await _client.create(
      model: _tripModel,
      values: values,
    );

    return getTripById(id);
  }

  /// Update trip
  Future<Trip> updateTrip(Trip trip) async {
    final values = _tripToOdooValues(trip);

    await _client.write(
      model: _tripModel,
      ids: [trip.id],
      values: values,
    );

    return getTripById(trip.id);
  }

  /// Start trip
  Future<Trip> startTrip(int tripId) async {
    await _client.callKw(
      model: _tripModel,
      method: 'action_start',
      args: [
        [tripId]
      ],
    );

    return getTripById(tripId);
  }

  /// Complete trip
  Future<Trip> completeTrip(int tripId) async {
    await _client.callKw(
      model: _tripModel,
      method: 'action_complete',
      args: [
        [tripId]
      ],
    );

    return getTripById(tripId);
  }

  /// Cancel trip
  Future<void> cancelTrip(int tripId) async {
    await _client.callKw(
      model: _tripModel,
      method: 'action_cancel',
      args: [
        [tripId]
      ],
    );
  }

  /// Update passenger status
  Future<TripLine> updatePassengerStatus(
      int tripLineId, TripLineStatus status) async {
    await _client.write(
      model: _tripLineModel,
      ids: [tripLineId],
      values: {'status': status.value},
    );

    final result = await _client.read(
      model: _tripLineModel,
      ids: [tripLineId],
      fields: _tripLineFields,
    );

    return TripLine.fromOdoo(result.first);
  }

  /// Mark passenger as boarded
  Future<TripLine> markPassengerBoarded(int tripLineId) async {
    await _client.callKw(
      model: _tripLineModel,
      method: 'action_board',
      args: [
        [tripLineId]
      ],
    );

    final result = await _client.read(
      model: _tripLineModel,
      ids: [tripLineId],
      fields: _tripLineFields,
    );

    return TripLine.fromOdoo(result.first);
  }

  /// Mark passenger as absent
  Future<TripLine> markPassengerAbsent(int tripLineId) async {
    await _client.callKw(
      model: _tripLineModel,
      method: 'action_absent',
      args: [
        [tripLineId]
      ],
    );

    final result = await _client.read(
      model: _tripLineModel,
      ids: [tripLineId],
      fields: _tripLineFields,
    );

    return TripLine.fromOdoo(result.first);
  }

  /// Mark passenger as dropped
  Future<TripLine> markPassengerDropped(int tripLineId) async {
    await _client.callKw(
      model: _tripLineModel,
      method: 'action_drop',
      args: [
        [tripLineId]
      ],
    );

    final result = await _client.read(
      model: _tripLineModel,
      ids: [tripLineId],
      fields: _tripLineFields,
    );

    return TripLine.fromOdoo(result.first);
  }

  /// Get dashboard statistics
  Future<TripDashboardStats> getDashboardStats(DateTime date) async {
    final dateStr = _formatDate(date);

    final result = await _client.callKw(
      model: _tripModel,
      method: 'get_dashboard_stats',
      args: [dateStr],
    );

    if (result is Map<String, dynamic>) {
      return TripDashboardStats.fromJson(result);
    }

    // Fallback: calculate stats manually
    final trips = await getTripsByDate(date);

    return TripDashboardStats(
      totalTripsToday: trips.length,
      ongoingTrips: trips.where((t) => t.state == TripState.ongoing).length,
      completedTrips: trips.where((t) => t.state == TripState.done).length,
      cancelledTrips: trips.where((t) => t.state == TripState.cancelled).length,
      plannedTrips: trips.where((t) => t.state == TripState.planned).length,
      totalPassengers: trips.fold(0, (sum, t) => sum + t.totalPassengers),
      boardedPassengers: trips.fold(0, (sum, t) => sum + t.boardedCount),
      absentPassengers: trips.fold(0, (sum, t) => sum + t.absentCount),
    );
  }

  /// Get manager analytics
  Future<ManagerAnalytics> getManagerAnalytics() async {
    try {
      final result = await _client.callKw(
        model: _tripModel,
        method: 'get_manager_analytics',
        args: [],
      );

      if (result is Map<String, dynamic>) {
        return ManagerAnalytics.fromJson(result);
      }
    } catch (_) {
      // Fallback to manual calculation
    }

    // Fallback: calculate analytics manually
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final trips = await getTrips(
      fromDate: startOfMonth,
      toDate: endOfMonth,
      limit: 1000,
    );

    if (trips.isEmpty) {
      return const ManagerAnalytics();
    }

    final completedTrips =
        trips.where((t) => t.state == TripState.done).toList();
    final cancelledTrips =
        trips.where((t) => t.state == TripState.cancelled).toList();

    final totalPassengers =
        completedTrips.fold(0, (sum, t) => sum + t.totalPassengers);
    final boardedPassengers =
        completedTrips.fold(0, (sum, t) => sum + t.boardedCount);
    final totalDistance =
        completedTrips.fold(0.0, (sum, t) => sum + (t.actualDistance ?? 0));

    return ManagerAnalytics(
      totalTripsThisMonth: trips.length,
      completedTripsThisMonth: completedTrips.length,
      completionRate:
          trips.isNotEmpty ? (completedTrips.length / trips.length) * 100 : 0,
      cancellationRate:
          trips.isNotEmpty ? (cancelledTrips.length / trips.length) * 100 : 0,
      totalPassengersTransported: boardedPassengers,
      averageOccupancyRate: totalPassengers > 0
          ? (boardedPassengers / totalPassengers) * 100
          : 0,
      onTimePercentage: 85.0, // Placeholder - calculate from actual data
      averageDelayMinutes: 5.0, // Placeholder
      totalDistanceKm: totalDistance,
      averageDistancePerTrip:
          completedTrips.isNotEmpty ? totalDistance / completedTrips.length : 0,
      estimatedFuelCost: totalDistance * 2.5, // Estimated cost per km
    );
  }

  // === Helper Methods ===

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _tripToOdooValues(Trip trip) {
    return {
      'name': trip.name,
      'state': trip.state.value,
      'trip_type': trip.tripType.value,
      'date': _formatDate(trip.date),
      if (trip.plannedStartTime != null)
        'planned_start_time': trip.plannedStartTime!.toIso8601String(),
      if (trip.plannedArrivalTime != null)
        'planned_arrival_time': trip.plannedArrivalTime!.toIso8601String(),
      if (trip.driverId != null) 'driver_id': trip.driverId,
      if (trip.vehicleId != null) 'vehicle_id': trip.vehicleId,
      if (trip.groupId != null) 'group_id': trip.groupId,
      if (trip.notes != null) 'notes': trip.notes,
    };
  }

  // Fields to fetch for trips
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
    'dropped_count',
    'planned_distance',
    'actual_distance',
    'notes',
  ];

  // Fields to fetch for trip lines
  static const List<String> _tripLineFields = [
    'id',
    'trip_id',
    'passenger_id',
    'passenger_name',
    'passenger_phone',
    'status',
    'sequence',
    'latitude',
    'longitude',
    'address',
    'boarding_time',
    'drop_time',
    'notes',
  ];
}
