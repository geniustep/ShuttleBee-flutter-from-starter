import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../../../core/enums/enums.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

/// Trip Remote Data Source - ShuttleBee
class TripRemoteDataSource {
  final BridgecoreClient _client;

  /// Odoo model names
  static const String _tripModel = 'shuttle.trip';
  static const String _tripLineModel = 'shuttle.trip.line';
  // ignore: unused_field - will be used for vehicle operations
  static const String _vehicleModel = 'shuttle.vehicle';
  // ignore: unused_field - will be used for stop operations
  static const String _stopModel = 'shuttle.stop';
  // ignore: unused_field - will be used for passenger group operations
  static const String _passengerGroupModel = 'shuttle.passenger.group';
  // ignore: unused_field - will be used for notification operations
  static const String _notificationModel = 'shuttle.notification';
  // ignore: unused_field - will be used for GPS tracking
  static const String _gpsPositionModel = 'shuttle.gps.position';

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
  Future<List<Trip>> getDriverTrips(
    int driverId,
    DateTime date, {
    List<TripState>? states,
  }) async {
    final dateStr = _formatDate(date);

    final domain = <List<dynamic>>[
      ['driver_id', '=', driverId],
      ['date', '=', dateStr],
    ];

    // Add state filter only if specified
    if (states != null && states.isNotEmpty) {
      domain.add([
        'state',
        'in',
        states.map((s) => s.value).toList(),
      ]);
    }

    final result = await _client.searchRead(
      model: _tripModel,
      domain: domain,
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
    // Use searchRead instead of read to avoid SDK null casting issues
    final result = await _client.searchRead(
      model: _tripModel,
      domain: [['id', '=', tripId]],
      fields: _tripFields,
      limit: 1,
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

    return _getTripLineById(tripLineId);
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

    return _getTripLineById(tripLineId);
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

    return _getTripLineById(tripLineId);
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

    return _getTripLineById(tripLineId);
  }

  /// Helper to get a single trip line by ID using searchRead (avoids SDK read issues)
  Future<TripLine> _getTripLineById(int tripLineId) async {
    final result = await _client.searchRead(
      model: _tripLineModel,
      domain: [['id', '=', tripLineId]],
      fields: _tripLineFields,
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('Trip line not found');
    }

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
  // Future<ManagerAnalytics> getManagerAnalytics() async {
  //   // Try to get analytics from custom Odoo method first
  //   try {
  //     final result = await _client.callKw(
  //       model: _tripModel,
  //       method: 'get_manager_analytics',
  //       args: [],
  //       kwargs: {},
  //     );

  //     if (result is Map<String, dynamic>) {
  //       return ManagerAnalytics.fromJson(result);
  //     }
  //   } catch (e) {
  //     debugPrint('⚠️ get_manager_analytics method not available: $e');
  //     debugPrint('📊 Calculating analytics from trip data...');
  //   }

  //   // Fallback: calculate analytics from trip data
  //   try {
  //     final now = DateTime.now();
  //     final startOfMonth = DateTime(now.year, now.month, 1);
  //     final endOfMonth = DateTime(now.year, now.month + 1, 0);

  //     // Get all trips for this month using searchRead directly
  //     final trips = await _client.searchRead(
  //       model: _tripModel,
  //       domain: [
  //         ['date', '>=', _formatDate(startOfMonth)],
  //         ['date', '<=', _formatDate(endOfMonth)],
  //       ],
  //       fields: ['name', 'state', 'total_passengers', 'planned_distance', 'actual_distance'],
  //       limit: 1000,
  //     );

  //     if (trips.isNotEmpty) {

  //       final completedTrips = trips.where((t) => t['state'] == 'done').toList();
  //       final cancelledTrips = trips.where((t) => t['state'] == 'cancelled').toList();

  //       final totalPassengers = trips.fold<int>(
  //         0, (sum, t) => sum + ((t['total_passengers'] as num?)?.toInt() ?? 0));
  //       final totalDistance = trips.fold<double>(
  //         0.0, (sum, t) => sum + ((t['actual_distance'] as num?)?.toDouble() ?? (t['planned_distance'] as num?)?.toDouble() ?? 0.0));

  //       return ManagerAnalytics(
  //         totalTripsThisMonth: trips.length,
  //         completedTripsThisMonth: completedTrips.length,
  //         completionRate: trips.isNotEmpty
  //             ? (completedTrips.length / trips.length) * 100
  //             : 0,
  //         cancellationRate: trips.isNotEmpty
  //             ? (cancelledTrips.length / trips.length) * 100
  //             : 0,
  //         totalPassengersTransported: totalPassengers,
  //         averageOccupancyRate: 75.0, // Placeholder
  //         onTimePercentage: 85.0, // Placeholder
  //         averageDelayMinutes: 5.0, // Placeholder
  //         totalDistanceKm: totalDistance,
  //         averageDistancePerTrip: completedTrips.isNotEmpty
  //             ? totalDistance / completedTrips.length
  //             : 0,
  //         estimatedFuelCost: totalDistance * 2.5,
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('⚠️ Failed to calculate analytics: $e');
  //   }

  //   // Return empty analytics if all else fails
  //   return const ManagerAnalytics();
  // }

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
  // Note: Some fields removed as they don't exist on the server
  // - vehicle_plate, dropped_count, planned_distance, actual_distance
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
