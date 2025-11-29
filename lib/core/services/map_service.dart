import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

/// Map Service - خدمة الخرائط المتقدمة - ShuttleBee
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  StreamController<Position>? _positionStreamController;
  Stream<Position>? _positionStream;

  // === Location Services ===

  /// التحقق من صلاحيات الموقع
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// الحصول على الموقع الحالي
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// تتبع الموقع المباشر (Live Tracking)
  Stream<Position> watchPosition() {
    if (_positionStream != null) {
      return _positionStream!;
    }

    _positionStreamController = StreamController<Position>.broadcast();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _positionStreamController?.add(position);
    });

    _positionStream = _positionStreamController!.stream;
    return _positionStream!;
  }

  /// إيقاف تتبع الموقع
  void stopWatchingPosition() {
    _positionStreamController?.close();
    _positionStreamController = null;
    _positionStream = null;
  }

  // === Geocoding ===

  /// تحويل الإحداثيات إلى عنوان
  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      return '${place.street}, ${place.subLocality}, ${place.locality}';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  /// تحويل العنوان إلى إحداثيات
  Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;

      final location = locations.first;
      return LatLng(location.latitude, location.longitude);
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  // === Distance & Duration ===

  /// حساب المسافة بين نقطتين (بالكيلومترات)
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000; // Convert to kilometers
  }

  /// حساب الوقت المتوقع للوصول (بالدقائق)
  /// افتراض سرعة متوسطة 40 كم/ساعة للحافلة المدرسية
  int calculateETA(LatLng from, LatLng to, {double averageSpeedKmh = 40}) {
    final distanceKm = calculateDistance(from, to);
    final timeHours = distanceKm / averageSpeedKmh;
    return (timeHours * 60).ceil(); // Convert to minutes
  }

  /// حساب الوقت المتوقع مع الأخذ في الاعتبار حركة المرور
  /// multiplier: 1.0 = no traffic, 1.5 = heavy traffic
  int calculateETAWithTraffic(
    LatLng from,
    LatLng to, {
    double trafficMultiplier = 1.2,
    double averageSpeedKmh = 40,
  }) {
    final baseETA = calculateETA(from, to, averageSpeedKmh: averageSpeedKmh);
    return (baseETA * trafficMultiplier).ceil();
  }

  // === Route Optimization ===

  /// ترتيب نقاط التوقف للحصول على أقصر مسار
  /// باستخدام Nearest Neighbor Algorithm
  List<LatLng> optimizeRoute(LatLng start, List<LatLng> stops) {
    if (stops.isEmpty) return [];
    if (stops.length == 1) return stops;

    final optimized = <LatLng>[];
    final remaining = List<LatLng>.from(stops);
    var current = start;

    while (remaining.isNotEmpty) {
      // Find nearest stop
      var nearestIndex = 0;
      var minDistance = calculateDistance(current, remaining[0]);

      for (var i = 1; i < remaining.length; i++) {
        final distance = calculateDistance(current, remaining[i]);
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      // Add nearest stop to optimized route
      final nearest = remaining.removeAt(nearestIndex);
      optimized.add(nearest);
      current = nearest;
    }

    return optimized;
  }

  // === Geofencing ===

  /// التحقق من دخول منطقة معينة (Geofence)
  bool isWithinGeofence(
    LatLng currentLocation,
    LatLng center,
    double radiusMeters,
  ) {
    final distance = calculateDistance(currentLocation, center) * 1000; // to meters
    return distance <= radiusMeters;
  }

  /// مراقبة دخول/خروج منطقة معينة
  Stream<GeofenceEvent> watchGeofence(
    Stream<Position> positionStream,
    LatLng center,
    double radiusMeters,
  ) {
    bool wasInside = false;

    return positionStream.map((position) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      final isInside = isWithinGeofence(currentLocation, center, radiusMeters);

      GeofenceEvent? event;
      if (isInside && !wasInside) {
        event = GeofenceEvent.enter(currentLocation);
      } else if (!isInside && wasInside) {
        event = GeofenceEvent.exit(currentLocation);
      }

      wasInside = isInside;
      return event;
    }).where((event) => event != null).cast<GeofenceEvent>();
  }

  // === Bearing & Direction ===

  /// حساب الاتجاه بين نقطتين (بالدرجات)
  double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLon = (to.longitude - from.longitude) * pi / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;

    return (bearing + 360) % 360;
  }

  /// الحصول على اسم الاتجاه (شمال، جنوب، شرق، غرب)
  String getBearingDirection(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'شمال';
    if (bearing >= 22.5 && bearing < 67.5) return 'شمال شرق';
    if (bearing >= 67.5 && bearing < 112.5) return 'شرق';
    if (bearing >= 112.5 && bearing < 157.5) return 'جنوب شرق';
    if (bearing >= 157.5 && bearing < 202.5) return 'جنوب';
    if (bearing >= 202.5 && bearing < 247.5) return 'جنوب غرب';
    if (bearing >= 247.5 && bearing < 292.5) return 'غرب';
    return 'شمال غرب';
  }

  // === Bounds ===

  /// حساب الحدود (Bounds) لمجموعة من النقاط
  MapBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return MapBounds(
        northeast: const LatLng(0, 0),
        southwest: const LatLng(0, 0),
      );
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return MapBounds(
      northeast: LatLng(maxLat, maxLng),
      southwest: LatLng(minLat, minLng),
    );
  }

  // === Helper Methods ===

  /// تحويل Position إلى LatLng
  LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  /// تنسيق المسافة للعرض
  String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} متر';
    }
    return '${km.toStringAsFixed(1)} كم';
  }

  /// تنسيق الوقت للعرض
  String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes دقيقة';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours ساعة و $mins دقيقة';
  }
}

// === Models ===

class GeofenceEvent {
  final GeofenceEventType type;
  final LatLng location;
  final DateTime timestamp;

  GeofenceEvent({
    required this.type,
    required this.location,
    required this.timestamp,
  });

  factory GeofenceEvent.enter(LatLng location) {
    return GeofenceEvent(
      type: GeofenceEventType.enter,
      location: location,
      timestamp: DateTime.now(),
    );
  }

  factory GeofenceEvent.exit(LatLng location) {
    return GeofenceEvent(
      type: GeofenceEventType.exit,
      location: location,
      timestamp: DateTime.now(),
    );
  }
}

enum GeofenceEventType {
  enter,
  exit,
}

class MapBounds {
  final LatLng northeast;
  final LatLng southwest;

  MapBounds({
    required this.northeast,
    required this.southwest,
  });

  LatLng get center {
    final lat = (northeast.latitude + southwest.latitude) / 2;
    final lng = (northeast.longitude + southwest.longitude) / 2;
    return LatLng(lat, lng);
  }
}
