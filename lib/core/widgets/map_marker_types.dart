import 'package:flutter/material.dart';

import 'cross_platform_map.dart';
import '../../features/stops/domain/entities/shuttle_stop.dart';

/// أنواع العلامات المختلفة
enum MapMarkerType {
  vehicle,    // مركبة
  passenger,  // راكب
  station,    // محطة
  stop,       // نقطة توقف
  company,    // شركة
  custom,     // مخصص
}

/// 🚗 Vehicle Marker Helper - مساعد علامات المركبات
class VehicleMarkerHelper {
  static MapMarkerData createMarker({
    required String vehicleId,
    required MapLocation location,
    required String vehicleName,
    String? driverName,
    VehicleStatus? status,
    double? heading,
    VoidCallback? onTap,
  }) {
    return MapMarkerData(
      id: 'vehicle_$vehicleId',
      location: location,
      title: vehicleName,
      snippet: driverName ?? '',
      color: _getStatusColor(status),
      rotation: heading ?? 0,
      onTap: onTap,
      markerType: MapMarkerType.vehicle,
    );
  }
  
  static MarkerColor _getStatusColor(VehicleStatus? status) {
    // يمكن تخصيص الألوان حسب حالة المركبة
    return MarkerColor.blue;
  }
}

/// 👤 Passenger Marker Helper - مساعد علامات الركاب
class PassengerMarkerHelper {
  static MapMarkerData createMarker({
    required String passengerId,
    required MapLocation location,
    required String passengerName,
    String? phoneNumber,
    PassengerStatus? status,
    VoidCallback? onTap,
  }) {
    return MapMarkerData(
      id: 'passenger_$passengerId',
      location: location,
      title: passengerName,
      snippet: phoneNumber ?? '',
      color: _getStatusColor(status),
      rotation: 0,
      onTap: onTap,
      markerType: MapMarkerType.passenger,
    );
  }
  
  static MarkerColor _getStatusColor(PassengerStatus? status) {
    switch (status) {
      case PassengerStatus.waiting:
        return MarkerColor.orange;
      case PassengerStatus.onTrip:
        return MarkerColor.green;
      case PassengerStatus.completed:
        return MarkerColor.blue;
      default:
        return MarkerColor.red;
    }
  }
}

/// 🚏 Station Marker Helper - مساعد علامات المحطات
class StationMarkerHelper {
  static MapMarkerData createMarker({
    required String stationId,
    required MapLocation location,
    required String stationName,
    String? code,
    StationType? type,
    VoidCallback? onTap,
  }) {
    return MapMarkerData(
      id: 'station_$stationId',
      location: location,
      title: stationName,
      snippet: code ?? '',
      color: _getTypeColor(type),
      rotation: 0,
      onTap: onTap,
      markerType: MapMarkerType.station,
    );
  }
  
  static MarkerColor _getTypeColor(StationType? type) {
    switch (type) {
      case StationType.pickup:
        return MarkerColor.green;
      case StationType.dropoff:
        return MarkerColor.red;
      case StationType.both:
        return MarkerColor.violet;
      default:
        return MarkerColor.blue;
    }
  }
}

/// 🛑 Stop Marker Helper - مساعد علامات نقاط التوقف
class StopMarkerHelper {
  static MapMarkerData createMarker({
    required String stopId,
    required MapLocation location,
    required String stopName,
    String? code,
    StopType? type,
    VoidCallback? onTap,
  }) {
    return MapMarkerData(
      id: 'stop_$stopId',
      location: location,
      title: stopName,
      snippet: code ?? '',
      color: _getTypeColor(type),
      rotation: 0,
      onTap: onTap,
      markerType: MapMarkerType.stop,
    );
  }
  
  static MarkerColor _getTypeColor(StopType? type) {
    switch (type) {
      case StopType.pickup:
        return MarkerColor.green;
      case StopType.dropoff:
        return MarkerColor.red;
      case StopType.both:
        return MarkerColor.violet;
      default:
        return MarkerColor.blue;
    }
  }
}

/// 🚏 Station With Count Marker Helper - علامة محطة مع عدد الركاب
class StationWithCountMarkerHelper {
  static MapMarkerData createMarker({
    required String stationId,
    required MapLocation location,
    required String stationName,
    required int passengerCount,
    bool isPickup = true,
    VoidCallback? onTap,
  }) {
    return MapMarkerData(
      id: 'station_passengers_$stationId',
      location: location,
      title: stationName,
      snippet: '$passengerCount راكب',
      color: isPickup ? MarkerColor.green : MarkerColor.red,
      rotation: 0,
      onTap: onTap,
      markerType: MapMarkerType.station,
      // العدد للعرض في الـ custom marker
      customData: {'count': passengerCount},
    );
  }
}

/// حالات المركبة
enum VehicleStatus {
  available,
  onTrip,
  busy,
  offline,
}

/// حالات الراكب
enum PassengerStatus {
  waiting,
  onTrip,
  completed,
}

/// أنواع المحطات
enum StationType {
  pickup,
  dropoff,
  both,
}


