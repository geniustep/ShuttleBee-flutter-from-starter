import 'package:flutter/material.dart';

/// Map Styles - تصاميم الخرائط المخصصة - ShuttleBee
class MapStyles {
  /// Mapbox Style URLs
  static const String shuttlebeeLight =
      'mapbox://styles/mapbox/light-v11'; // Light theme
  static const String shuttlebeeDark =
      'mapbox://styles/mapbox/dark-v11'; // Dark theme
  static const String shuttlebeeStreets =
      'mapbox://styles/mapbox/streets-v12'; // Streets
  static const String shuttlebeeSatellite =
      'mapbox://styles/mapbox/satellite-streets-v12'; // Satellite

  /// Custom Style (يمكن إنشاؤه في Mapbox Studio)
  /// Example: mapbox://styles/YOUR_USERNAME/YOUR_STYLE_ID
  static const String shuttlebeeCustom =
      'mapbox://styles/mapbox/streets-v12';

  /// Map Configuration
  static const double defaultZoom = 14.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 18.0;

  /// Marker Icons
  static const String driverMarkerIcon = '🚌';
  static const String passengerMarkerIcon = '👤';
  static const String stopMarkerIcon = '📍';
  static const String schoolMarkerIcon = '🏫';

  /// Map Colors
  static const Color routeColor = Color(0xFF2196F3); // Primary blue
  static const Color activeRouteColor = Color(0xFF4CAF50); // Green
  static const Color completedRouteColor = Color(0xFF9E9E9E); // Grey
  static const Color geofenceColor = Color(0x332196F3); // Transparent blue

  /// Animation Durations
  static const Duration markerAnimationDuration = Duration(milliseconds: 500);
  static const Duration cameraAnimationDuration = Duration(milliseconds: 800);
}

/// Custom Map Markers
class MapMarkers {
  /// Driver Marker (متحرك مع rotation)
  static Widget driverMarker({
    required double bearing,
    bool isActive = true,
  }) {
    return Transform.rotate(
      angle: bearing * 3.14159 / 180,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_bus,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Passenger Marker (مع حالة)
  static Widget passengerMarker({
    required String status, // boarded, absent, pending
    String? label,
  }) {
    Color color;
    IconData icon;

    switch (status) {
      case 'boarded':
        color = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case 'absent':
        color = const Color(0xFFF44336);
        icon = Icons.cancel;
        break;
      default:
        color = const Color(0xFFFF9800);
        icon = Icons.location_on;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }

  /// Stop/School Marker
  static Widget stopMarker({
    required String label,
    bool isSchool = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSchool ? Icons.school : Icons.home,
                size: 14,
                color: isSchool ? const Color(0xFF2196F3) : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          Icons.location_on,
          size: 32,
          color: isSchool ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
        ),
      ],
    );
  }

  /// Pulsing Marker (للموقع الحالي)
  static Widget pulsingMarker() {
    return _PulsingMarkerWidget();
  }

  /// ETA Badge (يظهر فوق الخريطة)
  static Widget etaBadge({
    required int minutes,
    required double distance,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            size: 20,
            color: Color(0xFF2196F3),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$minutes دقيقة',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              Text(
                '${distance.toStringAsFixed(1)} كم',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Route Progress Indicator
  static Widget routeProgress({
    required int completed,
    required int total,
  }) {
    final progress = completed / total;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route, size: 18, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Text(
                '$completed / $total محطات',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingMarkerWidget extends StatefulWidget {
  @override
  State<_PulsingMarkerWidget> createState() => _PulsingMarkerWidgetState();
}

class _PulsingMarkerWidgetState extends State<_PulsingMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF2196F3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
