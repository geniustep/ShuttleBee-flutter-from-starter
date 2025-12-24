import 'package:bridgecore_flutter/src/live_tracking/models/vehicle_position.dart';
import 'package:bridgecore_flutter/src/live_tracking/models/driver_location.dart';
import 'package:bridgecore_flutter/src/live_tracking/live_tracking_service.dart';

/// Represents a tracked vehicle with its current state
class TrackedVehicle {
  final int vehicleId;
  final int? tripId;
  final int driverId;
  final String driverName;
  final String vehicleName;
  final VehiclePosition? lastPosition;
  final DriverLocation? driverLocation;
  final DateTime lastUpdateTime;
  final bool isOnline;
  final DriverStatus? driverStatus;
  final String? vehicleType;
  final String? licensePlate;

  const TrackedVehicle({
    required this.vehicleId,
    this.tripId,
    required this.driverId,
    required this.driverName,
    required this.vehicleName,
    this.lastPosition,
    this.driverLocation,
    required this.lastUpdateTime,
    required this.isOnline,
    this.driverStatus,
    this.vehicleType,
    this.licensePlate,
  });

  /// Get the most recent location (prioritize real-time position over requested location)
  PositionData? get currentLocation {
    if (lastPosition != null) {
      return PositionData(
        latitude: lastPosition!.latitude,
        longitude: lastPosition!.longitude,
        speed: lastPosition!.speed,
        heading: lastPosition!.heading,
        timestamp: lastPosition!.timestamp,
      );
    } else if (driverLocation != null) {
      return PositionData(
        latitude: driverLocation!.latitude,
        longitude: driverLocation!.longitude,
        speed: driverLocation!.speed,
        heading: driverLocation!.heading,
        timestamp: driverLocation!.timestamp,
      );
    }
    return null;
  }

  /// Check if vehicle is active (on a trip)
  bool get isOnTrip => tripId != null;

  /// Check if vehicle data is stale (no update in 5 minutes)
  bool get isStale {
    final now = DateTime.now();
    return now.difference(lastUpdateTime).inMinutes > 5;
  }

  /// Get time since last update
  Duration get timeSinceUpdate => DateTime.now().difference(lastUpdateTime);

  /// Get formatted time since last update
  String get formattedTimeSinceUpdate {
    final duration = timeSinceUpdate;
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s ago';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else {
      return '${duration.inHours}h ago';
    }
  }

  /// Get status color based on vehicle state
  VehicleStatusColor get statusColor {
    if (!isOnline || isStale) {
      return VehicleStatusColor.offline;
    } else if (isOnTrip) {
      return VehicleStatusColor.onTrip;
    } else if (driverStatus == DriverStatus.available) {
      return VehicleStatusColor.available;
    } else if (driverStatus == DriverStatus.busy) {
      return VehicleStatusColor.busy;
    }
    return VehicleStatusColor.unknown;
  }

  /// Get status text
  String get statusText {
    if (!isOnline || isStale) {
      return 'Offline';
    } else if (isOnTrip) {
      return 'On Trip';
    } else if (driverStatus == DriverStatus.available) {
      return 'Available';
    } else if (driverStatus == DriverStatus.busy) {
      return 'Busy';
    } else if (driverStatus == DriverStatus.online) {
      return 'Online';
    }
    return 'Unknown';
  }

  TrackedVehicle copyWith({
    int? vehicleId,
    int? tripId,
    int? driverId,
    String? driverName,
    String? vehicleName,
    VehiclePosition? lastPosition,
    DriverLocation? driverLocation,
    DateTime? lastUpdateTime,
    bool? isOnline,
    DriverStatus? driverStatus,
    String? vehicleType,
    String? licensePlate,
  }) {
    return TrackedVehicle(
      vehicleId: vehicleId ?? this.vehicleId,
      tripId: tripId ?? this.tripId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleName: vehicleName ?? this.vehicleName,
      lastPosition: lastPosition ?? this.lastPosition,
      driverLocation: driverLocation ?? this.driverLocation,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isOnline: isOnline ?? this.isOnline,
      driverStatus: driverStatus ?? this.driverStatus,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
    );
  }

  @override
  String toString() {
    return 'TrackedVehicle(id: $vehicleId, driver: $driverName, status: $statusText, location: $currentLocation)';
  }
}

/// Position data helper class
class PositionData {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  const PositionData({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  @override
  String toString() => 'PositionData($latitude, $longitude)';
}

/// Vehicle status color enum
enum VehicleStatusColor {
  online,
  offline,
  onTrip,
  available,
  busy,
  unknown,
}
