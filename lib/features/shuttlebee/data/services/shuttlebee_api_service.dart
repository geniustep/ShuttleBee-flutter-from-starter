import 'package:dio/dio.dart';

import '../../../../core/enums/enums.dart';
import '../../../trips/domain/entities/trip.dart';

/// Thrown when ShuttleBee REST controllers are not available on the target server.
///
/// This is common when the app points to a BridgeCore server that does not have
/// the ShuttleBee Odoo module installed (or it's installed on a different DB).
class ShuttleBeeRestNotAvailable implements Exception {
  final int? statusCode;
  final String path;
  final dynamic body;

  const ShuttleBeeRestNotAvailable({
    required this.path,
    this.statusCode,
    this.body,
  });

  @override
  String toString() => 'ShuttleBeeRestNotAvailable($path, status=$statusCode)';
}

/// REST API wrapper for ShuttleBee Odoo controllers under `/api/v1/shuttle/*`.
///
/// Auth: Odoo session cookie (`session_id`) is required and is attached by `DioClient`.
class ShuttleBeeApiService {
  final Dio _dio;

  const ShuttleBeeApiService({required Dio dio}) : _dio = dio;

  Future<void> confirmTrip(
    int tripId, {
    double? latitude,
    double? longitude,
    int? stopId,
    String? note,
  }) async {
    final body = <String, dynamic>{
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (stopId != null) 'stop_id': stopId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    await _dio.post(
      '/api/v1/shuttle/trips/$tripId/confirm',
      data: body.isEmpty ? {} : body,
    );
  }

  Future<List<Trip>> getLiveOngoingTrips() async {
    const path = '/api/v1/shuttle/live/ongoing';
    // Treat 404 as a normal response so we can fallback without noisy Dio errors.
    final res = await _dio.get(
      path,
      options: Options(validateStatus: (_) => true),
    );

    if (res.statusCode == 404) {
      throw ShuttleBeeRestNotAvailable(
        path: path,
        statusCode: res.statusCode,
        body: res.data,
      );
    }

    if (res.statusCode != 200) {
      // Keep this as a DioException so upstream can still treat it like a network failure.
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Unexpected status code: ${res.statusCode}',
      );
    }
    final items = _extractList(res.data);
    return items.map((e) => Trip.fromShuttleBeeLiveJson(_asMap(e))).toList();
  }

  Future<List<Trip>> getMyTrips({TripState? state}) async {
    final res = await _dio.get(
      '/api/v1/shuttle/trips/my',
      queryParameters: {
        if (state != null) 'state': state.value,
      },
    );
    final items = _extractList(res.data);
    return items.map((e) => Trip.fromShuttleBeeLiveJson(_asMap(e))).toList();
  }

  Future<List<GpsPoint>> getTripGpsPoints(
    int tripId, {
    DateTime? since,
    int limit = 500,
  }) async {
    final res = await _dio.get(
      '/api/v1/shuttle/trips/$tripId/gps',
      queryParameters: {
        if (since != null) 'since': since.toIso8601String(),
        'limit': limit,
      },
    );

    final items = _extractList(res.data);
    return items.map((e) => GpsPoint.fromJson(_asMap(e))).toList();
  }

  Future<void> postVehiclePosition({
    required int vehicleId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
    DateTime? timestamp,
    String? note,
  }) async {
    await _dio.post(
      '/api/v1/shuttle/vehicle/position',
      data: <String, dynamic>{
        'vehicle_id': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        if (accuracy != null) 'accuracy': accuracy,
        if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final d = data['data'];
      if (d is List) return d;
      final r = data['result'];
      if (r is List) return r;
      final items = data['items'];
      if (items is List) return items;
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }
}

/// A single GPS point from `/trips/<trip_id>/gps`.
class GpsPoint {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;
  final double? speed;
  final double? heading;
  final double? accuracy;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    this.timestamp,
    this.speed,
    this.heading,
    this.accuracy,
  });

  factory GpsPoint.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v == null || v == false) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    DateTime? asDate(dynamic v) {
      if (v == null || v == false) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return GpsPoint(
      latitude: asDouble(json['latitude'] ?? json['lat']) ?? 0,
      longitude: asDouble(json['longitude'] ?? json['lng']) ?? 0,
      timestamp: asDate(json['timestamp']),
      speed: asDouble(json['speed']),
      heading: asDouble(json['heading']),
      accuracy: asDouble(json['accuracy']),
    );
  }
}
