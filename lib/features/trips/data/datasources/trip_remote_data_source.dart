import '../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../../../core/enums/enums.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../../shuttlebee/data/services/shuttlebee_api_service.dart';

/// Trip Remote Data Source - ShuttleBee
class TripRemoteDataSource {
  final BridgecoreClient _client;
  final ShuttleBeeApiService? _shuttleBeeApi;

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

  TripRemoteDataSource(this._client, {ShuttleBeeApiService? shuttleBeeApi})
      : _shuttleBeeApi = shuttleBeeApi;

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

  /// Get passenger trips with their lines
  Future<List<Trip>> getPassengerTrips(int passengerId) async {
    // First get trip lines for this passenger with full details
    final passengerLines = await _client.searchRead(
      model: _tripLineModel,
      domain: [
        ['passenger_id', '=', passengerId],
      ],
      fields: _tripLineFields,
    );

    if (passengerLines.isEmpty) return [];

    // Group lines by trip_id
    final Map<int, List<Map<String, dynamic>>> linesByTrip = {};
    for (final line in passengerLines) {
      final tripId = Trip.extractId(line['trip_id']);
      if (tripId != null) {
        linesByTrip.putIfAbsent(tripId, () => []).add(line);
      }
    }

    if (linesByTrip.isEmpty) return [];

    // Fetch trips
    final tripIds = linesByTrip.keys.toList();
    final result = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['id', 'in', tripIds],
      ],
      fields: _tripFields,
      order: 'date desc, planned_start_time asc',
    );

    // Build trips with their lines (only for this passenger)
    return result.map((tripJson) {
      final tripId = tripJson['id'] as int;
      final tripLines = linesByTrip[tripId] ?? [];

      // Create Trip with embedded lines
      final trip = Trip.fromOdoo(tripJson);

      // Parse lines for this passenger
      final parsedLines = tripLines.map((l) => TripLine.fromOdoo(l)).toList();

      return trip.copyWith(lines: parsedLines);
    }).toList();
  }

  /// Get trip by ID with lines
  Future<Trip> getTripById(int tripId) async {
    print('🚗 [getTripById] Fetching trip $tripId...');

    // Use searchRead instead of read to avoid SDK null casting issues
    List<Map<String, dynamic>> result;
    try {
      result = await _client.searchRead(
        model: _tripModel,
        domain: [
          ['id', '=', tripId],
        ],
        fields: _tripFields,
        limit: 1,
      );
      print('✅ [getTripById] Got trip data');
    } catch (e) {
      print('❌ [getTripById] FAILED to fetch $_tripModel: $e');
      rethrow;
    }

    if (result.isEmpty) {
      throw Exception('Trip not found');
    }

    final tripJson = result.first;
    // Log state value from server for debugging
    final stateValue = tripJson['state'];
    print('🔍 [getTripById] Raw state value from server: $stateValue (type: ${stateValue.runtimeType})');
    var trip = Trip.fromOdoo(tripJson);
    print('🔍 [getTripById] Parsed trip state: ${trip.state.value} (${trip.state.arabicLabel})');

    // جلب بيانات الشركة (إحداثيات الوجهة النهائية) إذا لم تكن موجودة
    if (trip.companyId != null &&
        (trip.companyLatitude == null || trip.companyLongitude == null)) {
      print('🏢 [getTripById] Fetching company location...');
      try {
        final companyData = await _getCompanyLocation(trip.companyId!);
        if (companyData != null) {
          trip = trip.copyWith(
            companyLatitude: companyData['latitude'] as double?,
            companyLongitude: companyData['longitude'] as double?,
          );
          print('✅ [getTripById] Got company location');
        }
      } catch (e) {
        print('❌ [getTripById] FAILED to fetch company: $e');
        // Continue without company location
      }
    }

    // Load trip lines
    final lines = await getTripLines(tripId);

    return trip.copyWith(lines: lines);
  }

  /// جلب إحداثيات الشركة
  Future<Map<String, dynamic>?> _getCompanyLocation(int companyId) async {
    try {
      final result = await _client.searchRead(
        model: 'res.company',
        domain: [
          ['id', '=', companyId],
        ],
        fields: ['id', 'name', 'shuttle_latitude', 'shuttle_longitude'],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final company = result.first;
      final lat = company['shuttle_latitude'];
      final lng = company['shuttle_longitude'];

      // التحقق من أن الإحداثيات صالحة
      if (lat == null || lat == false || lng == null || lng == false) {
        return null;
      }

      return {
        'latitude': (lat is num) ? lat.toDouble() : null,
        'longitude': (lng is num) ? lng.toDouble() : null,
      };
    } catch (e) {
      // في حالة الخطأ، نرجع null بدلاً من إيقاف العملية
      return null;
    }
  }

  /// Get trip lines with passenger location data
  Future<List<TripLine>> getTripLines(int tripId) async {
    print('📋 [getTripLines] Fetching lines for trip $tripId...');

    List<Map<String, dynamic>> result;
    try {
      result = await _client.searchRead(
        model: _tripLineModel,
        domain: [
          ['trip_id', '=', tripId],
        ],
        fields: _tripLineFields,
        order: 'sequence asc',
      );
      print('✅ [getTripLines] Got ${result.length} trip lines');
    } catch (e) {
      print('❌ [getTripLines] FAILED to fetch $_tripLineModel: $e');
      rethrow;
    }

    if (result.isEmpty) return [];

    // جلب معرفات الركاب
    final passengerIds = result
        .map((json) => Trip.extractId(json['passenger_id']))
        .whereType<int>()
        .toSet()
        .toList();

    // جلب بيانات الركاب (الإحداثيات والمحطات)
    final Map<int, Map<String, dynamic>> passengersData = {};
    if (passengerIds.isNotEmpty) {
      print('👥 [getTripLines] Fetching ${passengerIds.length} passengers...');
      try {
        final passengers = await _client.searchRead(
          model: 'res.partner',
          domain: [
            ['id', 'in', passengerIds],
          ],
          fields: _passengerLocationFields,
        );
        print('✅ [getTripLines] Got ${passengers.length} passengers');
        for (final p in passengers) {
          final id = p['id'] as int?;
          if (id != null) {
            passengersData[id] = p;
          }
        }
      } catch (e) {
        print('❌ [getTripLines] FAILED to fetch res.partner: $e');
        // Continue without passenger data instead of failing completely
        print('⚠️ [getTripLines] Continuing without passenger location data');
      }
    }

    // جلب بيانات المحطات إذا لزم الأمر
    final stopIds = <int>{};
    for (final p in passengersData.values) {
      final pickupStopId = Trip.extractId(p['default_pickup_stop_id']);
      final dropoffStopId = Trip.extractId(p['default_dropoff_stop_id']);
      if (pickupStopId != null) stopIds.add(pickupStopId);
      if (dropoffStopId != null) stopIds.add(dropoffStopId);
    }
    // أيضاً من trip_line نفسها
    for (final json in result) {
      final pickupStopId = Trip.extractId(json['pickup_stop_id']);
      final dropoffStopId = Trip.extractId(json['dropoff_stop_id']);
      if (pickupStopId != null) stopIds.add(pickupStopId);
      if (dropoffStopId != null) stopIds.add(dropoffStopId);
    }

    final Map<int, Map<String, dynamic>> stopsData = {};
    if (stopIds.isNotEmpty) {
      print('📍 [getTripLines] Fetching ${stopIds.length} stops...');
      try {
        final stops = await _client.searchRead(
          model: _stopModel,
          domain: [
            ['id', 'in', stopIds.toList()],
          ],
          fields: ['id', 'name', 'latitude', 'longitude'],
        );
        print('✅ [getTripLines] Got ${stops.length} stops');
        for (final s in stops) {
          final id = s['id'] as int?;
          if (id != null) {
            stopsData[id] = s;
          }
        }
      } catch (e) {
        print('❌ [getTripLines] FAILED to fetch $_stopModel: $e');
        // Continue without stop data instead of failing completely
        print('⚠️ [getTripLines] Continuing without stop location data');
      }
    }

    // تحويل البيانات مع إضافة معلومات الموقع
    return result.map((json) {
      final passengerId = Trip.extractId(json['passenger_id']);
      final passengerData =
          passengerId != null ? passengersData[passengerId] : null;

      // دمج بيانات الموقع
      final enrichedJson = Map<String, dynamic>.from(json);

      if (passengerData != null) {
        // إحداثيات الراكب الشخصية
        enrichedJson['passenger_latitude'] = passengerData['shuttle_latitude'];
        enrichedJson['passenger_longitude'] =
            passengerData['shuttle_longitude'];
        enrichedJson['use_gps_for_pickup'] =
            passengerData['use_gps_for_pickup'];
        enrichedJson['use_gps_for_dropoff'] =
            passengerData['use_gps_for_dropoff'];
        enrichedJson['passenger_phone'] =
            passengerData['phone'] ?? passengerData['mobile'];

        // محطة الصعود الافتراضية من الراكب
        final defaultPickupStopId =
            Trip.extractId(passengerData['default_pickup_stop_id']);
        if (defaultPickupStopId != null &&
            stopsData.containsKey(defaultPickupStopId)) {
          final stop = stopsData[defaultPickupStopId]!;
          enrichedJson['default_pickup_stop_id'] = defaultPickupStopId;
          enrichedJson['default_pickup_stop_name'] = stop['name'];
          enrichedJson['default_pickup_stop_latitude'] = stop['latitude'];
          enrichedJson['default_pickup_stop_longitude'] = stop['longitude'];
        }

        // محطة النزول الافتراضية من الراكب
        final defaultDropoffStopId =
            Trip.extractId(passengerData['default_dropoff_stop_id']);
        if (defaultDropoffStopId != null &&
            stopsData.containsKey(defaultDropoffStopId)) {
          final stop = stopsData[defaultDropoffStopId]!;
          enrichedJson['default_dropoff_stop_id'] = defaultDropoffStopId;
          enrichedJson['default_dropoff_stop_name'] = stop['name'];
          enrichedJson['default_dropoff_stop_latitude'] = stop['latitude'];
          enrichedJson['default_dropoff_stop_longitude'] = stop['longitude'];
        }
      }

      // محطة الصعود من trip_line (إذا موجودة)
      final pickupStopId = Trip.extractId(json['pickup_stop_id']);
      if (pickupStopId != null && stopsData.containsKey(pickupStopId)) {
        final stop = stopsData[pickupStopId]!;
        enrichedJson['pickup_stop_name'] = stop['name'];
        enrichedJson['pickup_stop_latitude'] = stop['latitude'];
        enrichedJson['pickup_stop_longitude'] = stop['longitude'];
      }

      // محطة النزول من trip_line (إذا موجودة)
      final dropoffStopId = Trip.extractId(json['dropoff_stop_id']);
      if (dropoffStopId != null && stopsData.containsKey(dropoffStopId)) {
        final stop = stopsData[dropoffStopId]!;
        enrichedJson['dropoff_stop_name'] = stop['name'];
        enrichedJson['dropoff_stop_latitude'] = stop['latitude'];
        enrichedJson['dropoff_stop_longitude'] = stop['longitude'];
      }

      return TripLine.fromOdoo(enrichedJson);
    }).toList();
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

  /// Confirm trip (draft → planned)
  /// Returns minimal trip data to avoid multiple API calls
  Future<Trip> confirmTrip(
    int tripId, {
    double? latitude,
    double? longitude,
    int? stopId,
    String? note,
  }) async {
    // Prefer the new ShuttleBee REST endpoint when available.
    if (_shuttleBeeApi != null) {
      try {
        await _shuttleBeeApi.confirmTrip(
          tripId,
          latitude: latitude,
          longitude: longitude,
          stopId: stopId,
          note: note,
        );
      } catch (_) {
        // Fallback to RPC below (older servers / temporary failures).
        await _client.callKw(
          model: _tripModel,
          method: 'action_confirm',
          args: [
            [tripId],
          ],
        );
      }
    } else {
      await _client.callKw(
        model: _tripModel,
        method: 'action_confirm',
        args: [
          [tripId],
        ],
      );
    }

    // Get minimal trip data (without all related data to avoid rate limiting)
    final tripResult = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['id', '=', tripId],
      ],
      fields: _tripFields,
      limit: 1,
    );

    if (tripResult.isEmpty) {
      throw Exception('Trip not found after confirming');
    }

    return Trip.fromOdoo(tripResult.first);
  }

  /// Start trip (planned → ongoing)
  /// Returns minimal trip data to avoid multiple API calls
  Future<Trip> startTrip(int tripId) async {
    final result = await _client.callKw(
      model: _tripModel,
      method: 'action_start',
      args: [
        [tripId],
      ],
    );

    // action_start returns trip data, use it directly if available
    if (result is Map<String, dynamic> && result.containsKey('trip_id')) {
      // Get just the trip record without all the related data
      final tripResult = await _client.searchRead(
        model: _tripModel,
        domain: [
          ['id', '=', tripId],
        ],
        fields: _tripFields,
        limit: 1,
      );

      if (tripResult.isNotEmpty) {
        return Trip.fromOdoo(tripResult.first);
      }
    }

    // Fallback: get minimal trip data
    final tripResult = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['id', '=', tripId],
      ],
      fields: _tripFields,
      limit: 1,
    );

    if (tripResult.isEmpty) {
      throw Exception('Trip not found after starting');
    }

    return Trip.fromOdoo(tripResult.first);
  }

  /// Complete trip
  /// Returns minimal trip data to avoid multiple API calls
  Future<Trip> completeTrip(int tripId) async {
    await _client.callKw(
      model: _tripModel,
      method: 'action_complete',
      args: [
        [tripId],
      ],
    );

    // Get minimal trip data (without all related data to avoid rate limiting)
    final tripResult = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['id', '=', tripId],
      ],
      fields: _tripFields,
      limit: 1,
    );

    if (tripResult.isEmpty) {
      throw Exception('Trip not found after completing');
    }

    return Trip.fromOdoo(tripResult.first);
  }

  /// Cancel trip
  Future<void> cancelTrip(int tripId) async {
    await _client.callKw(
      model: _tripModel,
      method: 'action_cancel',
      args: [
        [tripId],
      ],
    );
  }

  /// Create return trip from an existing trip
  Future<Trip> createReturnTrip(
    int tripId, {
    required DateTime startTime,
    DateTime? arrivalTime,
  }) async {
    final formattedStartTime = _formatOdooDateTime(startTime);
    final formattedArrivalTime =
        arrivalTime != null ? _formatOdooDateTime(arrivalTime) : false;

    // Call the Odoo method - it takes start_time and optional arrival_time
    // The method signature is: create_return_trip(self, start_time, arrival_time=False)
    final result = await _client.callKw(
      model: _tripModel,
      method: 'create_return_trip',
      args: [
        [tripId],
        formattedStartTime,
        formattedArrivalTime,
      ],
    );

    // The method might return the trip ID directly or in a dict
    int? returnTripId;
    if (result is int) {
      returnTripId = result;
    } else if (result is Map<String, dynamic>) {
      returnTripId = result['id'] as int?;
    }

    // If we got the ID, fetch the trip
    if (returnTripId != null) {
      return getTripById(returnTripId);
    }

    // Fallback: search for the return trip
    final originalTrip = await getTripById(tripId);
    final returnTrips = await _client.searchRead(
      model: _tripModel,
      domain: [
        if (originalTrip.groupId != null) ['group_id', '=', originalTrip.groupId],
        ['date', '=', _formatDate(originalTrip.date)],
        ['name', 'ilike', 'Return'],
      ],
      fields: _tripFields,
      order: 'id desc',
      limit: 1,
    );

    if (returnTrips.isNotEmpty) {
      return getTripById(returnTrips.first['id'] as int);
    }

    // Last fallback: search all recent trips
    final allTrips = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['date', '=', _formatDate(originalTrip.date)],
      ],
      fields: _tripFields,
      order: 'id desc',
      limit: 10,
    );

    // Find the return trip (opposite type, same group)
    for (final tripJson in allTrips) {
      final trip = Trip.fromOdoo(tripJson);
      if (trip.groupId == originalTrip.groupId &&
          trip.tripType != originalTrip.tripType &&
          trip.name.contains('Return')) {
        return getTripById(trip.id);
      }
    }

    throw Exception('Return trip not found after creation');
  }

  /// Update passenger status
  Future<TripLine> updatePassengerStatus(
    int tripLineId,
    TripLineStatus status,
  ) async {
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
      method: 'action_mark_boarded',
      args: [
        [tripLineId],
      ],
    );

    return _getTripLineById(tripLineId);
  }

  /// Mark passenger as absent
  Future<TripLine> markPassengerAbsent(int tripLineId) async {
    await _client.callKw(
      model: _tripLineModel,
      method: 'action_mark_absent',
      args: [
        [tripLineId],
      ],
    );

    return _getTripLineById(tripLineId);
  }

  /// Mark passenger as dropped
  Future<TripLine> markPassengerDropped(int tripLineId) async {
    await _client.callKw(
      model: _tripLineModel,
      method: 'action_mark_dropped',
      args: [
        [tripLineId],
      ],
    );

    return _getTripLineById(tripLineId);
  }

  /// Reset passenger status to planned (undo action for mistakes)
  Future<TripLine> resetPassengerToPlanned(int tripLineId) async {
    await _client.callKw(
      model: _tripLineModel,
      method: 'action_reset_to_planned',
      args: [
        [tripLineId],
      ],
    );

    return _getTripLineById(tripLineId);
  }

  /// Add a passenger to a trip
  Future<TripLine> addPassengerToTrip({
    required int tripId,
    required int passengerId,
    int seatCount = 1,
    String? notes,
    int? pickupStopId,
    int? dropoffStopId,
  }) async {
    // جلب نوع الرحلة أولاً
    String? tripType;
    int? companyId;
    try {
      final tripData = await _client.searchRead(
        model: _tripModel,
        domain: [
          ['id', '=', tripId],
        ],
        fields: ['trip_type', 'company_id'],
        limit: 1,
      );

      if (tripData.isNotEmpty) {
        tripType = tripData.first['trip_type'] as String?;
        companyId = Trip.extractId(tripData.first['company_id']);
      }
    } catch (e) {
      print('⚠️ [addPassengerToTrip] Failed to fetch trip type: $e');
    }

    final values = <String, dynamic>{
      'trip_id': tripId,
      'passenger_id': passengerId,
      'seat_count': seatCount,
      'status': 'planned',
    };

    if (notes != null && notes.isNotEmpty) {
      values['notes'] = notes;
    }
    if (pickupStopId != null) {
      values['pickup_stop_id'] = pickupStopId;
    }
    if (dropoffStopId != null) {
      values['dropoff_stop_id'] = dropoffStopId;
    }

    // جلب بيانات الراكب والشركة للحصول على الإحداثيات
    try {
      final passengerData = await _client.searchRead(
        model: 'res.partner',
        domain: [
          ['id', '=', passengerId],
        ],
        fields: ['shuttle_latitude', 'shuttle_longitude'],
        limit: 1,
      );

      Map<String, dynamic>? companyData;
      if (companyId != null) {
        try {
          final companyResult = await _client.searchRead(
            model: 'res.company',
            domain: [
              ['id', '=', companyId],
            ],
            fields: ['shuttle_latitude', 'shuttle_longitude'],
            limit: 1,
          );
          if (companyResult.isNotEmpty) {
            companyData = companyResult.first;
          }
        } catch (e) {
          print('⚠️ [addPassengerToTrip] Failed to fetch company data: $e');
        }
      }

      if (passengerData.isNotEmpty) {
        final passenger = passengerData.first;
        final passengerLat = passenger['shuttle_latitude'];
        final passengerLng = passenger['shuttle_longitude'];

        // إضافة إحداثيات الصعود إذا لم تكن هناك محطة صعود
        if (pickupStopId == null &&
            passengerLat != null &&
            passengerLat != false &&
            passengerLng != null &&
            passengerLng != false) {
          values['pickup_latitude'] = (passengerLat is num)
              ? passengerLat.toDouble()
              : double.tryParse(passengerLat.toString());
          values['pickup_longitude'] = (passengerLng is num)
              ? passengerLng.toDouble()
              : double.tryParse(passengerLng.toString());
        }

        // إضافة إحداثيات النزول إذا كانت الرحلة من نوع dropoff ولم تكن هناك محطة نزول
        if (tripType == 'dropoff' &&
            dropoffStopId == null &&
            companyData != null) {
          final companyLat = companyData['shuttle_latitude'];
          final companyLng = companyData['shuttle_longitude'];

          // محاولة استخدام إحداثيات الشركة أولاً
          if (companyLat != null &&
              companyLat != false &&
              companyLng != null &&
              companyLng != false) {
            values['dropoff_latitude'] = (companyLat is num)
                ? companyLat.toDouble()
                : double.tryParse(companyLat.toString());
            values['dropoff_longitude'] = (companyLng is num)
                ? companyLng.toDouble()
                : double.tryParse(companyLng.toString());
          }
          // إذا لم تكن هناك إحداثيات للشركة، استخدم إحداثيات الراكب
          else if (passengerLat != null &&
              passengerLat != false &&
              passengerLng != null &&
              passengerLng != false) {
            values['dropoff_latitude'] = (passengerLat is num)
                ? passengerLat.toDouble()
                : double.tryParse(passengerLat.toString());
            values['dropoff_longitude'] = (passengerLng is num)
                ? passengerLng.toDouble()
                : double.tryParse(passengerLng.toString());
          }
        }
      }
    } catch (e) {
      // في حالة فشل جلب البيانات، نتابع بدون إحداثيات GPS
      // Odoo سيرمي خطأ إذا لم تكن هناك محطة أو إحداثيات
      print(
          '⚠️ [addPassengerToTrip] Failed to fetch passenger/company GPS: $e');
    }

    final id = await _client.create(
      model: _tripLineModel,
      values: values,
    );

    return _getTripLineById(id);
  }

  /// Remove a passenger from a trip
  Future<void> removePassengerFromTrip(int tripLineId) async {
    await _client.unlink(
      model: _tripLineModel,
      ids: [tripLineId],
    );
  }

  /// Update a trip line (passenger in trip)
  Future<TripLine> updateTripLine({
    required int tripLineId,
    int? seatCount,
    String? notes,
    int? pickupStopId,
    int? dropoffStopId,
    int? sequence,
  }) async {
    final values = <String, dynamic>{};

    if (seatCount != null) {
      values['seat_count'] = seatCount;
    }
    if (notes != null) {
      values['notes'] = notes;
    }
    if (pickupStopId != null) {
      values['pickup_stop_id'] = pickupStopId;
    }
    if (dropoffStopId != null) {
      values['dropoff_stop_id'] = dropoffStopId;
    }
    if (sequence != null) {
      values['sequence'] = sequence;
    }

    if (values.isNotEmpty) {
      await _client.write(
        model: _tripLineModel,
        ids: [tripLineId],
        values: values,
      );
    }

    return _getTripLineById(tripLineId);
  }

  /// Get passengers not in a specific trip (from the trip's group)
  Future<List<Map<String, dynamic>>> getAvailablePassengersForTrip(
      int tripId) async {
    // First get the trip to know its group
    final tripResult = await _client.searchRead(
      model: _tripModel,
      domain: [
        ['id', '=', tripId],
      ],
      fields: ['group_id'],
      limit: 1,
    );

    if (tripResult.isEmpty) {
      throw Exception('Trip not found');
    }

    final groupId = Trip.extractId(tripResult.first['group_id']);
    if (groupId == null) {
      return []; // Trip has no group, so no available passengers from group
    }

    // Get all passengers in the trip
    final tripLines = await _client.searchRead(
      model: _tripLineModel,
      domain: [
        ['trip_id', '=', tripId],
      ],
      fields: ['passenger_id'],
    );

    final passengerIdsInTrip = tripLines
        .map((l) => Trip.extractId(l['passenger_id']))
        .whereType<int>()
        .toSet();

    // Get all passengers in the group
    final groupLines = await _client.searchRead(
      model: 'shuttle.passenger.group.line',
      domain: [
        ['group_id', '=', groupId],
      ],
      fields: ['passenger_id', 'passenger_name', 'seat_count'],
    );

    // Filter out passengers already in the trip
    return groupLines.where((line) {
      final passengerId = Trip.extractId(line['passenger_id']);
      return passengerId != null && !passengerIdsInTrip.contains(passengerId);
    }).toList();
  }

  /// Helper to get a single trip line by ID using searchRead (avoids SDK read issues)
  Future<TripLine> _getTripLineById(int tripLineId) async {
    final result = await _client.searchRead(
      model: _tripLineModel,
      domain: [
        ['id', '=', tripLineId],
      ],
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
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateFromStr = _formatDate(dateOnly);
    final dateToStr = _formatDate(dateOnly);

    final result = await _client.callKw(
      model: _tripModel,
      method: 'get_dashboard_stats',
      // Odoo signature: get_dashboard_stats(date_from, date_to, company_id=None)
      args: [dateFromStr, dateToStr],
    );

    if (result is Map<String, dynamic>) {
      // Backward/forward compatible parsing:
      // - Some server versions return "total_trips_today/ongoing_trips/..." (TripDashboardStats JSON)
      // - Current ShuttleBee Odoo module returns "total_trips/total_passengers/present_count/absent_count"
      if (result.containsKey('total_trips_today') ||
          result.containsKey('ongoing_trips') ||
          result.containsKey('active_vehicles')) {
        return TripDashboardStats.fromJson(result);
      }

      if (result.containsKey('total_trips') ||
          result.containsKey('total_passengers') ||
          result.containsKey('present_count') ||
          result.containsKey('absent_count')) {
        // حساب المركبات والسائقين من الرحلات إذا لم تكن موجودة في النتيجة
        final trips = await getTripsByDate(date);
        final uniqueVehicles = trips
            .where((t) => t.vehicleId != null)
            .map((t) => t.vehicleId!)
            .toSet();
        final activeVehiclesSet = trips
            .where((t) =>
                t.vehicleId != null &&
                (t.state == TripState.ongoing || t.state == TripState.planned))
            .map((t) => t.vehicleId!)
            .toSet();
        
        final uniqueDrivers = trips
            .where((t) => t.driverId != null)
            .map((t) => t.driverId!)
            .toSet();
        final activeDriversSet = trips
            .where((t) =>
                t.driverId != null &&
                (t.state == TripState.ongoing || t.state == TripState.planned))
            .map((t) => t.driverId!)
            .toSet();

        return TripDashboardStats(
          totalTripsToday: (result['total_trips'] as num?)?.toInt() ?? trips.length,
          ongoingTrips: trips.where((t) => t.state == TripState.ongoing).length,
          completedTrips: trips.where((t) => t.state == TripState.done).length,
          cancelledTrips: trips.where((t) => t.state == TripState.cancelled).length,
          plannedTrips: trips.where((t) => t.state == TripState.planned).length,
          totalPassengers: (result['total_passengers'] as num?)?.toInt() ?? 
              trips.fold(0, (sum, t) => sum + t.totalPassengers),
          boardedPassengers: (result['present_count'] as num?)?.toInt() ?? 
              trips.fold(0, (sum, t) => sum + t.boardedCount),
          absentPassengers: (result['absent_count'] as num?)?.toInt() ?? 
              trips.fold(0, (sum, t) => sum + t.absentCount),
          totalVehicles: (result['total_vehicles'] as num?)?.toInt() ?? uniqueVehicles.length,
          activeVehicles: (result['active_vehicles'] as num?)?.toInt() ?? activeVehiclesSet.length,
          totalDrivers: (result['total_drivers'] as num?)?.toInt() ?? uniqueDrivers.length,
          activeDrivers: (result['active_drivers'] as num?)?.toInt() ?? activeDriversSet.length,
        );
      }
    }

    // Fallback: calculate stats manually
    final trips = await getTripsByDate(date);

    // حساب المركبات والسائقين من الرحلات
    final uniqueVehicles = trips
        .where((t) => t.vehicleId != null)
        .map((t) => t.vehicleId!)
        .toSet();
    final activeVehiclesSet = trips
        .where((t) =>
            t.vehicleId != null &&
            (t.state == TripState.ongoing || t.state == TripState.planned))
        .map((t) => t.vehicleId!)
        .toSet();
    
    final uniqueDrivers = trips
        .where((t) => t.driverId != null)
        .map((t) => t.driverId!)
        .toSet();
    final activeDriversSet = trips
        .where((t) =>
            t.driverId != null &&
            (t.state == TripState.ongoing || t.state == TripState.planned))
        .map((t) => t.driverId!)
        .toSet();

    return TripDashboardStats(
      totalTripsToday: trips.length,
      ongoingTrips: trips.where((t) => t.state == TripState.ongoing).length,
      completedTrips: trips.where((t) => t.state == TripState.done).length,
      cancelledTrips: trips.where((t) => t.state == TripState.cancelled).length,
      plannedTrips: trips.where((t) => t.state == TripState.planned).length,
      totalPassengers: trips.fold(0, (sum, t) => sum + t.totalPassengers),
      boardedPassengers: trips.fold(0, (sum, t) => sum + t.boardedCount),
      absentPassengers: trips.fold(0, (sum, t) => sum + t.absentCount),
      totalVehicles: uniqueVehicles.length,
      activeVehicles: activeVehiclesSet.length,
      totalDrivers: uniqueDrivers.length,
      activeDrivers: activeDriversSet.length,
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

  /// تنسيق DateTime للتنسيق الذي يتوقعه Odoo: 'YYYY-MM-DD HH:MM:SS'
  String _formatOdooDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  Map<String, dynamic> _tripToOdooValues(Trip trip) {
    return {
      'name': trip.name,
      'state': trip.state.value,
      'trip_type': trip.tripType.value,
      'date': _formatDate(trip.date),
      if (trip.plannedStartTime != null)
        'planned_start_time': _formatOdooDateTime(trip.plannedStartTime!),
      if (trip.plannedArrivalTime != null)
        'planned_arrival_time': _formatOdooDateTime(trip.plannedArrivalTime!),
      if (trip.driverId != null) 'driver_id': trip.driverId,
      if (trip.companionId != null)
        'companion_id': trip.companionId, // NEW: المرافق
      if (trip.vehicleId != null) 'vehicle_id': trip.vehicleId,
      if (trip.groupId != null) 'group_id': trip.groupId,
      if (trip.notes != null) 'notes': trip.notes,
    };
  }

  // Fields to fetch for trips - MINIMAL SET
  // Reduced to avoid 500 errors from BridgeCore backend
  // Note: Some fields removed as they don't exist on the server or cause issues
  // - vehicle_plate, planned_distance, actual_distance, display_name
  // Company data is fetched separately in _getCompanyLocation()
  static const List<String> _tripFields = [
    'id',
    'name',
    'state',
    'trip_type',
    'date',
    'planned_start_time',
    'planned_arrival_time',
    'actual_start_time',
    'actual_arrival_time',
    'driver_id',
    'companion_id', // NEW: المرافق
    'vehicle_id',
    'group_id',
    'total_passengers',
    'boarded_count',
    'absent_count',
    'dropped_count',
    'notes',
    'company_id',
    // Live tracking (needed for dispatcher monitor map)
    'current_latitude',
    'current_longitude',
    'last_gps_update',
  ];

  // Fields to fetch for trip lines - MINIMAL SET
  // Reduced to avoid 500 errors from BridgeCore backend
  static const List<String> _tripLineFields = [
    'id',
    'trip_id',
    'passenger_id',
    'status',
    'sequence',
    'seat_count',
    // Pickup/Dropoff Stops
    'pickup_stop_id',
    'dropoff_stop_id',
    // Pickup/Dropoff Coordinates (GPS)
    'pickup_latitude',
    'pickup_longitude',
    'dropoff_latitude',
    'dropoff_longitude',
    // Timestamps
    'boarding_time',
    // Notes
    'notes',
  ];

  // حقول الراكب للحصول على بيانات الموقع
  static const List<String> _passengerLocationFields = [
    'id',
    'name',
    'phone',
    'mobile',
    'shuttle_latitude',
    'shuttle_longitude',
    'use_gps_for_pickup',
    'use_gps_for_dropoff',
    'default_pickup_stop_id',
    'default_dropoff_stop_id',
  ];
}
