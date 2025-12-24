import '../bloc/tracking_monitor_cubit.dart';

/// Represents map bounds for camera positioning
class MapBounds {
  final LatLng southwest;
  final LatLng northeast;
  final double padding;

  const MapBounds({
    required this.southwest,
    required this.northeast,
    this.padding = 50.0,
  });

  /// Create bounds from a single point
  factory MapBounds.fromSinglePoint({
    required double latitude,
    required double longitude,
    double zoom = 15.0,
  }) {
    // Calculate approximate bounds based on zoom level
    // Higher zoom = smaller area
    final delta = 0.01 / (zoom / 10);

    return MapBounds(
      southwest: LatLng(latitude - delta, longitude - delta),
      northeast: LatLng(latitude + delta, longitude + delta),
      padding: 20.0,
    );
  }

  /// Create bounds from multiple points
  factory MapBounds.fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return MapBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Get center point of bounds
  LatLng get center {
    return LatLng(
      (southwest.latitude + northeast.latitude) / 2,
      (southwest.longitude + northeast.longitude) / 2,
    );
  }

  @override
  String toString() =>
      'MapBounds(sw: $southwest, ne: $northeast, padding: $padding)';
}
