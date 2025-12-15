import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/services/map_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/cached_trip_provider.dart';
import '../widgets/passenger_notification_widget.dart';

/// 🚌 ShuttleBee Professional Live Trip Map Screen
///
/// Features:
/// ✅ Custom School Bus Marker with Animation
/// ✅ Passenger Markers with Avatars
/// ✅ Smart Stop Clustering
/// ✅ Interactive Passenger Info Cards
/// ✅ Quick Action Menu
/// ✅ Real-time ETA & Distance
/// ✅ Geofencing Alerts
/// ✅ Beautiful UI/UX
class DriverLiveTripMapScreen extends ConsumerStatefulWidget {
  final int tripId;

  const DriverLiveTripMapScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<DriverLiveTripMapScreen> createState() =>
      _DriverLiveTripMapScreenState();
}

class _DriverLiveTripMapScreenState
    extends ConsumerState<DriverLiveTripMapScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final MapService _mapService = MapService();
  GoogleMapController? _mapController;

  // Live Tracking
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  double _currentBearing = 0;

  // Trip Data
  TripLine? _nextStop;
  int _etaMinutes = 0;
  double _distanceKm = 0;

  // Map Elements
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};

  // Custom Marker Icons
  BitmapDescriptor? _schoolBusIcon;

  // UI State
  bool _isMapReady = false;
  bool _hasStartedLoading = false;
  bool _showPassengerCard = false;
  TripLine? _selectedPassenger;
  List<TripLine>? _selectedClusterPassengers;
  String? _selectedStopName;

  // Notification Manager
  TripNotificationManager? _notificationManager;
  final Map<int, double> _passengerDistances = {}; // تخزين المسافات لكل راكب

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeMap();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _initializeMap() async {
    // Check location permission
    final hasPermission = await _mapService.checkLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        _showErrorSnackBar('يرجى تفعيل صلاحيات الموقع');
      }
      return;
    }

    // Get current location first
    final currentLocation = await _mapService.getCurrentLocation();
    if (mounted && currentLocation != null) {
      setState(() {
        _currentPosition = currentLocation;
      });
    }

    // Create custom markers
    await _createCustomMarkers();

    // Load trip data
    _loadTrip();

    // Start live tracking
    _startLiveTracking();
  }

  Future<void> _createCustomMarkers() async {
    // Create school bus marker
    _schoolBusIcon = await _createSchoolBusMarker();
  }

  Future<BitmapDescriptor> _createSchoolBusMarker() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(80, 80);

    // Draw school bus
    final paint = Paint()..style = PaintingStyle.fill;

    // Bus body (yellow)
    paint.color = const Color(0xFFFFB300);
    final busRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 20, 60, 35),
      const Radius.circular(8),
    );
    canvas.drawRRect(busRect, paint);

    // Bus roof
    paint.color = const Color(0xFFFF8F00);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(15, 15, 50, 10),
        const Radius.circular(5),
      ),
      paint,
    );

    // Windows
    paint.color = const Color(0xFF90CAF9);
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(18 + (i * 18), 25, 12, 12),
          const Radius.circular(3),
        ),
        paint,
      );
    }

    // Wheels
    paint.color = const Color(0xFF424242);
    canvas.drawCircle(const Offset(25, 55), 8, paint);
    canvas.drawCircle(const Offset(55, 55), 8, paint);

    // Wheel centers
    paint.color = const Color(0xFF757575);
    canvas.drawCircle(const Offset(25, 55), 4, paint);
    canvas.drawCircle(const Offset(55, 55), 4, paint);

    // Headlights
    paint.color = const Color(0xFFFFEB3B);
    canvas.drawCircle(const Offset(68, 35), 4, paint);

    // Direction indicator (arrow)
    paint.color = const Color(0xFF4CAF50);
    final path = Path();
    path.moveTo(40, 0);
    path.lineTo(50, 12);
    path.lineTo(30, 12);
    path.close();
    canvas.drawPath(path, paint);

    // Shadow
    paint.color = Colors.black.withOpacity(0.2);
    canvas.drawOval(const Rect.fromLTWH(15, 60, 50, 8), paint);

    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createPassengerMarker({
    required String name,
    required String status,
    int count = 1,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(70, 90);

    final paint = Paint()..style = PaintingStyle.fill;

    // Status color
    Color statusColor;
    switch (status) {
      case 'boarded':
      case 'dropped':
        statusColor = AppColors.success;
        break;
      case 'absent':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    // Marker pin shape
    final pinPath = Path();
    pinPath.moveTo(35, 85);
    pinPath.quadraticBezierTo(35, 70, 10, 50);
    pinPath.quadraticBezierTo(0, 35, 10, 20);
    pinPath.quadraticBezierTo(20, 5, 35, 5);
    pinPath.quadraticBezierTo(50, 5, 60, 20);
    pinPath.quadraticBezierTo(70, 35, 60, 50);
    pinPath.quadraticBezierTo(35, 70, 35, 85);
    pinPath.close();

    // Shadow
    paint.color = Colors.black.withOpacity(0.3);
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(pinPath, paint);
    canvas.restore();

    // Main pin
    paint.color = statusColor;
    canvas.drawPath(pinPath, paint);

    // White circle background for avatar
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(35, 35), 22, paint);

    // Avatar circle with initials
    final initials = _getInitials(name);
    final avatarColor = _getColorFromName(name);
    paint.color = avatarColor;
    canvas.drawCircle(const Offset(35, 35), 18, paint);

    // Draw initials
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(35 - textPainter.width / 2, 35 - textPainter.height / 2),
    );

    // Badge for count > 1
    if (count > 1) {
      paint.color = AppColors.primary;
      canvas.drawCircle(const Offset(55, 15), 12, paint);

      paint.color = Colors.white;
      canvas.drawCircle(const Offset(55, 15), 10, paint);

      final countPainter = TextPainter(
        text: TextSpan(
          text: '$count',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      countPainter.layout();
      countPainter.paint(
        canvas,
        Offset(55 - countPainter.width / 2, 15 - countPainter.height / 2),
      );
    }

    // Status indicator
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(50, 48), 8, paint);
    paint.color = statusColor;
    canvas.drawCircle(const Offset(50, 48), 6, paint);

    // Status icon
    if (status == 'boarded' || status == 'dropped') {
      paint.color = Colors.white;
      paint.strokeWidth = 2;
      paint.style = PaintingStyle.stroke;
      final checkPath = Path();
      checkPath.moveTo(46, 48);
      checkPath.lineTo(49, 51);
      checkPath.lineTo(54, 45);
      canvas.drawPath(checkPath, paint);
    } else if (status == 'absent') {
      paint.color = Colors.white;
      paint.strokeWidth = 2;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(47, 45), const Offset(53, 51), paint);
      canvas.drawLine(const Offset(53, 45), const Offset(47, 51), paint);
    }

    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createClusterMarker({
    required int count,
    required String stopName,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(80, 100);

    final paint = Paint()..style = PaintingStyle.fill;

    // Marker pin shape (larger for cluster)
    final pinPath = Path();
    pinPath.moveTo(40, 95);
    pinPath.quadraticBezierTo(40, 78, 8, 55);
    pinPath.quadraticBezierTo(-5, 38, 8, 18);
    pinPath.quadraticBezierTo(22, 0, 40, 0);
    pinPath.quadraticBezierTo(58, 0, 72, 18);
    pinPath.quadraticBezierTo(85, 38, 72, 55);
    pinPath.quadraticBezierTo(40, 78, 40, 95);
    pinPath.close();

    // Shadow
    paint.color = Colors.black.withOpacity(0.3);
    canvas.save();
    canvas.translate(3, 3);
    canvas.drawPath(pinPath, paint);
    canvas.restore();

    // Gradient effect for cluster
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(pinPath, paint);
    paint.shader = null;

    // White inner circle
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(40, 38), 26, paint);

    // Multiple person icon
    paint.color = AppColors.primary;

    // Person 1 (left)
    canvas.drawCircle(const Offset(30, 32), 6, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 40, 12, 14),
        const Radius.circular(4),
      ),
      paint,
    );

    // Person 2 (right, slightly behind)
    paint.color = AppColors.primaryLight;
    canvas.drawCircle(const Offset(50, 32), 6, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 40, 12, 14),
        const Radius.circular(4),
      ),
      paint,
    );

    // Count badge
    paint.color = AppColors.secondary;
    canvas.drawCircle(const Offset(62, 12), 14, paint);

    paint.color = Colors.white;
    canvas.drawCircle(const Offset(62, 12), 12, paint);

    final countPainter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    countPainter.layout();
    countPainter.paint(
      canvas,
      Offset(62 - countPainter.width / 2, 12 - countPainter.height / 2),
    );

    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getColorFromName(String? name) {
    if (name == null || name.isEmpty) return AppColors.primary;
    final colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFF26A69A),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
      const Color(0xFF66BB6A),
      const Color(0xFFFF7043),
      const Color(0xFF42A5F5),
      const Color(0xFFEC407A),
    ];
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  /// 🎮 تحميل الرحلة مع دعم الكاش
  void _loadTrip() {
    _hasStartedLoading = true;
    // استخدام smartTripProvider للكاش والتحديثات الفورية
    ref.read(smartTripProvider.notifier).loadTrip(widget.tripId);
  }

  void _startLiveTracking() {
    _positionSubscription = _mapService.watchPosition().listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _updateETA();
          _checkGeofence(position);
          _updateMapElements();
          _updatePassengerDistances(position);
        });

        // تحديث مدير الإشعارات التلقائية
        _notificationManager?.updateDriverLocation(
          position.latitude,
          position.longitude,
        );
      }
    });
  }

  /// تحديث المسافات لكل راكب
  void _updatePassengerDistances(Position position) {
    final tripState = ref.read(smartTripProvider);
    final trip = tripState.trip;
    if (trip == null) return;

    // تهيئة مدير الإشعارات إذا لم يكن موجوداً
    _notificationManager ??= TripNotificationManager(
      repository: ref.read(notificationRepositoryProvider),
      passengers: trip.lines,
      onNotificationSent: (passenger, type) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                type == 'approaching'
                    ? '🔔 تم إرسال إشعار الاقتراب لـ ${passenger.passengerName}'
                    : '📍 تم إرسال إشعار الوصول لـ ${passenger.passengerName}',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor:
                  type == 'approaching' ? Colors.orange : Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );

    for (final line in trip.lines) {
      final lat = line.effectivePickupLatitude;
      final lng = line.effectivePickupLongitude;

      if (lat != null && lng != null) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat,
          lng,
        );
        _passengerDistances[line.id] = distance;
      }
    }
  }

  void _updateETA() {
    if (_currentPosition == null || _nextStop == null) return;

    final currentLocation = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    final stopLat = _nextStop!.effectivePickupLatitude ?? 0;
    final stopLng = _nextStop!.effectivePickupLongitude ?? 0;
    final nextLocation = LatLng(stopLat, stopLng);

    _distanceKm = _mapService.calculateDistance(currentLocation, nextLocation);
    _etaMinutes = _mapService.calculateETAWithTraffic(
      currentLocation,
      nextLocation,
      trafficMultiplier: 1.3,
    );

    _currentBearing = _mapService.calculateBearing(
      currentLocation,
      nextLocation,
    );
  }

  void _checkGeofence(Position position) {
    if (_nextStop == null) return;

    final currentLocation = LatLng(position.latitude, position.longitude);
    final stopLat = _nextStop!.effectivePickupLatitude ?? 0;
    final stopLng = _nextStop!.effectivePickupLongitude ?? 0;
    final stopLocation = LatLng(stopLat, stopLng);

    final isNearStop = _mapService.isWithinGeofence(
      currentLocation,
      stopLocation,
      100,
    );

    if (isNearStop) {
      _showArrivalNotification();
    }
  }

  void _showArrivalNotification() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 وصلت إلى المحطة!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _nextStop?.passengerName ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _updateMapElements() async {
    // استخدام smartTripProvider للبيانات المخزنة مؤقتاً
    final tripState = ref.read(smartTripProvider);
    final trip = tripState.trip;
    if (trip == null) return;

    // Build markers asynchronously but safely
    await _buildMarkers(trip);

    if (mounted) {
      _buildPolylines(trip);
      _buildCircles(trip);
    }
  }

  Future<void> _buildMarkers(Trip trip) async {
    if (!mounted) return;

    final markers = <Marker>{};

    // التحقق من إكمال جميع الـ pickups (لإخفاء markers الركاب)
    final allPickupsCompleted =
        trip.tripType == TripType.pickup && _areAllPickupsCompleted(trip);

    // Driver marker - يظهر دائماً
    if (_currentPosition != null && _schoolBusIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: _schoolBusIcon!,
          rotation: _currentBearing,
          anchor: const Offset(0.5, 0.5),
          zIndex: 100,
          infoWindow: const InfoWindow(
            title: '🚌 موقعك الحالي',
            snippet: 'السائق',
          ),
        ),
      );
    }

    // إظهار markers الركاب فقط إذا لم تكتمل جميع الـ pickups
    if (!allPickupsCompleted) {
      // Create a local copy of clustered stops to avoid concurrent modification
      final localClusteredStops = <int, List<TripLine>>{};

      // Cluster passengers by stop - create local copy first
      for (final line in trip.lines) {
        if (line.pickupStopId != null) {
          localClusteredStops
              .putIfAbsent(line.pickupStopId!, () => [])
              .add(line);
        }
      }

      // Create all marker icons first (collect futures)
      final stopMarkerFutures = <int, Future<_MarkerData>>{};

      for (final entry in localClusteredStops.entries) {
        final passengers = List<TripLine>.from(entry.value); // Create a copy
        final firstPassenger = passengers.first;
        final lat = firstPassenger.effectivePickupLatitude;
        final lng = firstPassenger.effectivePickupLongitude;

        if (lat != null && lng != null) {
          stopMarkerFutures[entry.key] = _createStopMarkerData(
            stopId: entry.key,
            passengers: passengers,
            firstPassenger: firstPassenger,
            lat: lat,
            lng: lng,
          );
        }
      }

      // Wait for all stop markers to be created
      final stopMarkerResults = await Future.wait(
        stopMarkerFutures.values,
        eagerError: false,
      );

      // Add stop markers
      for (final markerData in stopMarkerResults) {
        if (markerData.marker != null) {
          markers.add(markerData.marker!);
        }
      }

      // Create individual passenger markers (those without stops)
      final individualPassengers =
          trip.lines.where((line) => line.pickupStopId == null).toList();

      final passengerMarkerFutures = <Future<_MarkerData>>[];

      for (final line in individualPassengers) {
        final lat = line.effectivePickupLatitude;
        final lng = line.effectivePickupLongitude;

        if (lat != null && lng != null) {
          passengerMarkerFutures
              .add(_createIndividualPassengerMarkerData(line, lat, lng));
        }
      }

      // Wait for all individual passenger markers
      final passengerMarkerResults = await Future.wait(
        passengerMarkerFutures,
        eagerError: false,
      );

      // Add individual passenger markers
      for (final markerData in passengerMarkerResults) {
        if (markerData.marker != null) {
          markers.add(markerData.marker!);
        }
      }
    }

    // إضافة marker الشركة فقط عند إكمال جميع الـ pickups
    if (allPickupsCompleted) {
      if (trip.companyLatitude != null && trip.companyLongitude != null) {
        final companyMarker = await _createCompanyMarker(
          name: trip.companyName ?? 'الشركة',
          lat: trip.companyLatitude!,
          lng: trip.companyLongitude!,
        );
        if (companyMarker != null) {
          markers.add(companyMarker);
        }
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  bool _areAllPickupsCompleted(Trip trip) {
    // Check if all passengers have been boarded or marked absent
    return trip.lines.every(
      (line) => line.status.value == 'boarded' || line.status.value == 'absent',
    );
  }

  Future<Marker?> _createCompanyMarker({
    required String name,
    required double lat,
    required double lng,
  }) async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(80, 100);

      final paint = Paint()..style = PaintingStyle.fill;

      // Building/Company pin shape
      final pinPath = Path();
      pinPath.moveTo(40, 95);
      pinPath.quadraticBezierTo(40, 75, 10, 55);
      pinPath.quadraticBezierTo(0, 40, 10, 25);
      pinPath.quadraticBezierTo(20, 10, 40, 10);
      pinPath.quadraticBezierTo(60, 10, 70, 25);
      pinPath.quadraticBezierTo(80, 40, 70, 55);
      pinPath.quadraticBezierTo(40, 75, 40, 95);
      pinPath.close();

      // Shadow
      paint.color = Colors.black.withOpacity(0.3);
      canvas.save();
      canvas.translate(3, 3);
      canvas.drawPath(pinPath, paint);
      canvas.restore();

      // Gradient for company marker
      paint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(pinPath, paint);
      paint.shader = null;

      // White circle background
      paint.color = Colors.white;
      canvas.drawCircle(const Offset(40, 40), 24, paint);

      // Building icon
      paint.color = const Color(0xFF10B981);

      // Building body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 30, 20, 20),
          const Radius.circular(2),
        ),
        paint,
      );

      // Windows
      paint.color = Colors.white;
      for (int row = 0; row < 2; row++) {
        for (int col = 0; col < 2; col++) {
          canvas.drawRect(
            Rect.fromLTWH(33 + (col * 7), 33 + (row * 7), 4, 4),
            paint,
          );
        }
      }

      // Flag on top
      paint.color = const Color(0xFFEF4444);
      canvas.drawRect(const Rect.fromLTWH(38, 25, 6, 4), paint);
      paint.color = const Color(0xFF10B981);
      canvas.drawRect(const Rect.fromLTWH(38, 25, 2, 8), paint);

      final picture = pictureRecorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final icon = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());

      return Marker(
        markerId: const MarkerId('company_destination'),
        position: LatLng(lat, lng),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        zIndex: 90,
        infoWindow: InfoWindow(
          title: '🏢 $name',
          snippet: 'الوجهة النهائية',
        ),
      );
    } catch (e) {
      debugPrint('Error creating company marker: $e');
      return null;
    }
  }

  Future<_MarkerData> _createStopMarkerData({
    required int stopId,
    required List<TripLine> passengers,
    required TripLine firstPassenger,
    required double lat,
    required double lng,
  }) async {
    try {
      BitmapDescriptor icon;
      if (passengers.length > 1) {
        icon = await _createClusterMarker(
          count: passengers.length,
          stopName: firstPassenger.pickupStopName ?? 'محطة',
        );
      } else {
        icon = await _createPassengerMarker(
          name: firstPassenger.passengerName ?? 'راكب',
          status: firstPassenger.status.value,
        );
      }

      final marker = Marker(
        markerId: MarkerId('stop_$stopId'),
        position: LatLng(lat, lng),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        zIndex: 50,
        onTap: () => _onStopTapped(passengers, firstPassenger.pickupStopName),
      );

      return _MarkerData(marker: marker);
    } catch (e) {
      debugPrint('Error creating stop marker: $e');
      return _MarkerData(marker: null);
    }
  }

  Future<_MarkerData> _createIndividualPassengerMarkerData(
    TripLine line,
    double lat,
    double lng,
  ) async {
    try {
      final icon = await _createPassengerMarker(
        name: line.passengerName ?? 'راكب',
        status: line.status.value,
      );

      final marker = Marker(
        markerId: MarkerId('passenger_${line.id}'),
        position: LatLng(lat, lng),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        zIndex: 40,
        onTap: () => _onPassengerTapped(line),
      );

      return _MarkerData(marker: marker);
    } catch (e) {
      debugPrint('Error creating passenger marker: $e');
      return _MarkerData(marker: null);
    }
  }

  void _buildPolylines(Trip trip) {
    final polylines = <Polyline>{};

    // التحقق من إكمال جميع الـ pickups
    final allPickupsCompleted =
        trip.tripType == TripType.pickup && _areAllPickupsCompleted(trip);

    // إذا اكتملت جميع الـ pickups، نظهر فقط الخط إلى الشركة
    if (allPickupsCompleted) {
      if (trip.companyLatitude != null && trip.companyLongitude != null) {
        final toCompanyPoints = <LatLng>[];

        // Start from current position
        if (_currentPosition != null) {
          toCompanyPoints.add(
            LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
          );
        }

        // Add company location
        toCompanyPoints.add(
          LatLng(
            trip.companyLatitude!,
            trip.companyLongitude!,
          ),
        );

        if (toCompanyPoints.length >= 2) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('to_company_route'),
              points: toCompanyPoints,
              color:
                  const Color(0xFF10B981), // Green color for final destination
              width: 6,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }
      }
    } else {
      // إظهار خطوط الطريق للركاب (لم تكتمل جميع الـ pickups)
      final points = <LatLng>[];

      // Add driver position
      if (_currentPosition != null) {
        points.add(
          LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
        );
      }

      // Add passenger locations in sequence
      final sortedLines = List<TripLine>.from(trip.lines)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

      for (final line in sortedLines) {
        final lat = line.effectivePickupLatitude;
        final lng = line.effectivePickupLongitude;
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }

      if (points.length >= 2) {
        // Main route
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: AppColors.primary,
            width: 5,
            patterns: [PatternItem.dash(30), PatternItem.gap(15)],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );

        // Completed route (solid line)
        final completedPoints = <LatLng>[];
        if (_currentPosition != null) {
          completedPoints.add(
            LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
          );
        }

        for (final line in sortedLines) {
          if (line.status.value == 'boarded' ||
              line.status.value == 'dropped') {
            final lat = line.effectivePickupLatitude;
            final lng = line.effectivePickupLongitude;
            if (lat != null && lng != null) {
              completedPoints.add(LatLng(lat, lng));
            }
          }
        }

        if (completedPoints.length >= 2) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('completed_route'),
              points: completedPoints,
              color: AppColors.success,
              width: 6,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }
      }
    }

    setState(() {
      _polylines = polylines;
    });
  }

  void _buildCircles(Trip trip) {
    final circles = <Circle>{};

    // التحقق من إكمال جميع الـ pickups
    final allPickupsCompleted =
        trip.tripType == TripType.pickup && _areAllPickupsCompleted(trip);

    // إذا اكتملت جميع الـ pickups، نظهر geofence حول الشركة
    if (allPickupsCompleted) {
      if (trip.companyLatitude != null && trip.companyLongitude != null) {
        circles.add(
          Circle(
            circleId: const CircleId('company_geofence'),
            center: LatLng(trip.companyLatitude!, trip.companyLongitude!),
            radius: 150,
            fillColor: const Color(0xFF10B981).withOpacity(0.1),
            strokeColor: const Color(0xFF10B981).withOpacity(0.5),
            strokeWidth: 2,
          ),
        );
      }
    } else {
      // Next stop geofence (للركاب)
      if (_nextStop != null) {
        final lat = _nextStop!.effectivePickupLatitude;
        final lng = _nextStop!.effectivePickupLongitude;

        if (lat != null && lng != null) {
          circles.add(
            Circle(
              circleId: const CircleId('next_stop_geofence'),
              center: LatLng(lat, lng),
              radius: 100,
              fillColor: AppColors.primary.withOpacity(0.1),
              strokeColor: AppColors.primary.withOpacity(0.5),
              strokeWidth: 2,
            ),
          );
        }
      }
    }

    setState(() {
      _circles = circles;
    });
  }

  void _onStopTapped(List<TripLine> passengers, String? stopName) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedClusterPassengers = passengers;
      _selectedPassenger = null;
      _selectedStopName = stopName;
      _showPassengerCard = true;
    });
    _slideController.forward();
  }

  void _onPassengerTapped(TripLine passenger) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedPassenger = passenger;
      _selectedClusterPassengers = null;
      _selectedStopName = null;
      _showPassengerCard = true;
    });
    _slideController.forward();
  }

  void _closePassengerCard() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showPassengerCard = false;
          _selectedPassenger = null;
          _selectedClusterPassengers = null;
          _selectedStopName = null;
        });
      }
    });
  }

  Future<void> _callPassenger(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showErrorSnackBar('رقم الهاتف غير متوفر');
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showErrorSnackBar('رقم الهاتف غير متوفر');
      return;
    }
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _navigateToLocation(double lat, double lng) async {
    final uri = Uri.parse(
      'google.navigation:q=$lat,$lng&mode=d',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback to Google Maps web
      final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );
      await launchUrl(webUri);
    }
  }

  /// 🎮 تسجيل صعود راكب - تحديث فوري متفائل
  Future<void> _markPassengerBoarded(TripLine passenger) async {
    HapticFeedback.mediumImpact();

    // استخدام smartTripProvider للتحديث الفوري
    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.markPassengerBoarded(passenger.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('✅ ${passenger.passengerName ?? 'الراكب'} صعد');
        // Close passenger card if open
        if (_showPassengerCard) {
          _closePassengerCard();
        }
        // تحديث الخريطة فوراً - البيانات تتحدث تلقائياً
        await _updateMapElements();
      } else {
        _showErrorSnackBar('فشل تحديث حالة الراكب');
      }
    }
  }

  /// 🎮 تسجيل نزول راكب - تحديث فوري متفائل
  Future<void> _markPassengerDropped(TripLine passenger) async {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.markPassengerDropped(passenger.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('✅ ${passenger.passengerName ?? 'الراكب'} نزل');
        // Close passenger card if open
        if (_showPassengerCard) {
          _closePassengerCard();
        }
        // تحديث الخريطة فوراً
        await _updateMapElements();
      } else {
        _showErrorSnackBar('فشل تحديث حالة الراكب');
      }
    }
  }

  /// 🎮 تسجيل غياب راكب - تحديث فوري متفائل
  Future<void> _markPassengerAbsent(TripLine passenger) async {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.markPassengerAbsent(passenger.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('⚠️ ${passenger.passengerName ?? 'الراكب'} غائب');
        // Close passenger card if open
        if (_showPassengerCard) {
          _closePassengerCard();
        }
        // تحديث الخريطة فوراً
        await _updateMapElements();
      } else {
        _showErrorSnackBar('فشل تحديث حالة الراكب');
      }
    }
  }

  /// 🎮 إعادة حالة راكب - تحديث فوري متفائل
  Future<void> _resetPassengerStatus(TripLine passenger) async {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.resetPassengerToPlanned(passenger.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar(
          '🔄 تم إعادة حالة ${passenger.passengerName ?? 'الراكب'}',
        );
        // Close passenger card if open
        if (_showPassengerCard) {
          _closePassengerCard();
        }
        // تحديث الخريطة فوراً
        await _updateMapElements();
      } else {
        _showErrorSnackBar('فشل إعادة الحالة');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _centerOnDriver() {
    if (_mapController == null || _currentPosition == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 16,
          bearing: _currentBearing,
          tilt: 45,
        ),
      ),
    );
  }

  void _fitAllMarkers() {
    if (_mapController == null || _markers.isEmpty) return;

    final points = _markers.map((m) => m.position).toList();
    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }

    final bounds = _mapService.calculateBounds(points);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: bounds.southwest,
          northeast: bounds.northeast,
        ),
        80,
      ),
    );
  }

  TripLine? _getNextStop(Trip trip) {
    for (final line in trip.lines) {
      if (line.status.value == 'not_started' ||
          line.status.value == 'pending') {
        return line;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapService.stopWatchingPosition();
    _pulseController.dispose();
    _slideController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // استخدام smartTripProvider للتحديثات الفورية والكاش
    final tripState = ref.watch(smartTripProvider);
    final trip = tripState.trip;

    return Scaffold(
      body: _buildContent(tripState, trip),
    );
  }

  /// 🎮 بناء المحتوى بناءً على حالة الرحلة
  Widget _buildContent(SmartTripState tripState, Trip? trip) {
    // حالة التحميل
    if (tripState.isLoading) {
      return _buildLoadingState();
    }

    // حالة الخطأ
    if (tripState.hasError && !tripState.hasData) {
      if (_hasStartedLoading) {
        return _buildErrorState(tripState.error ?? 'حدث خطأ غير معروف');
      }
      return _buildLoadingState();
    }

    // لا توجد بيانات
    if (trip == null) {
      if (_hasStartedLoading) {
        return _buildErrorState('لم يتم العثور على الرحلة');
      }
      return _buildLoadingState();
    }

    // عرض البيانات
    _nextStop = _getNextStop(trip);

    // Update map elements when trip data changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMapReady) _updateMapElements();
    });

    return Stack(
      children: [
        // Map
        _buildMap(trip),

        // Top gradient overlay
        _buildTopGradient(),

        // Header
        _buildHeader(trip),

        // مؤشر المزامنة (syncing indicator)
        if (tripState.isSyncing || tripState.isFromCache)
          _buildSyncIndicator(tripState),

        // ETA Card
        if (_nextStop != null && _currentPosition != null) _buildETACard(),

        // Bottom Sheet
        _buildBottomSheet(trip),

        // Passenger/Cluster Card
        if (_showPassengerCard) _buildPassengerCard(),

        // Map Controls
        _buildMapControls(),
      ],
    );
  }

  /// 🔄 مؤشر المزامنة - يظهر عند العمل من الكاش أو أثناء المزامنة
  Widget _buildSyncIndicator(SmartTripState tripState) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tripState.isSyncing
              ? AppColors.warning.withOpacity(0.9)
              : AppColors.info.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
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
            if (tripState.isSyncing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(
                Icons.cloud_off,
                size: 14,
                color: Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              tripState.isSyncing ? 'جاري المزامنة...' : 'وضع الكاش',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(Trip trip) {
    // تحديد الموقع الافتراضي بناءً على بيانات الرحلة
    LatLng initialTarget;
    if (_currentPosition != null) {
      // 1. استخدم موقع السائق الحالي إذا متاح
      initialTarget = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } else if (trip.lines.isNotEmpty) {
      // 2. استخدم موقع أول راكب
      final firstPassenger = trip.lines.first;
      final lat = firstPassenger.effectivePickupLatitude;
      final lng = firstPassenger.effectivePickupLongitude;
      if (lat != null && lng != null) {
        initialTarget = LatLng(lat, lng);
      } else if (trip.companyLatitude != null &&
          trip.companyLongitude != null) {
        // 3. استخدم موقع الشركة
        initialTarget = LatLng(trip.companyLatitude!, trip.companyLongitude!);
      } else {
        // 4. Fallback - الرباط، المغرب (موقع افتراضي أفضل)
        initialTarget = const LatLng(33.9716, -6.8498);
      }
    } else if (trip.companyLatitude != null && trip.companyLongitude != null) {
      initialTarget = LatLng(trip.companyLatitude!, trip.companyLongitude!);
    } else {
      // Fallback
      initialTarget = const LatLng(33.9716, -6.8498);
    }

    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        _isMapReady = true;
        _updateMapElements();
        Future.delayed(const Duration(milliseconds: 500), _fitAllMarkers);
      },
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 14,
      ),
      markers: _markers,
      polylines: _polylines,
      circles: _circles,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onTap: (_) => _closePassengerCard(),
      padding: const EdgeInsets.only(bottom: 200),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 150,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Trip trip) {
    final completedStops = trip.lines
        .where(
          (l) => l.status.value == 'boarded' || l.status.value == 'dropped',
        )
        .length;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Trip info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trip.vehicleName ?? 'مركبة',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$completedStops',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/${trip.lines.length}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildETACard() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 100,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_etaMinutes دقيقة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_distanceKm.toStringAsFixed(1)} كم',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المحطة التالية',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _nextStop?.passengerName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomSheet(Trip trip) {
    final isShowingCompanyDestination = _nextStop == null &&
        trip.tripType == TripType.pickup &&
        _areAllPickupsCompleted(trip) &&
        trip.companyLatitude != null &&
        trip.companyLongitude != null;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Next stop info
            if (_nextStop != null) ...[
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(_nextStop!.status.value),
                          _getStatusColor(_nextStop!.status.value)
                              .withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(_nextStop!.passengerName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${_nextStop!.sequence}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nextStop!.passengerName ?? 'راكب',
                                style: AppTypography.h6,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _nextStop!.usesPickupStop
                                  ? Icons.location_on
                                  : Icons.gps_fixed,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _nextStop!.pickupLocationName,
                                style: AppTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.navigation_rounded,
                      label: 'الملاحة',
                      color: AppColors.primary,
                      onTap: () {
                        final lat = trip.tripType == TripType.pickup
                            ? _nextStop!.effectivePickupLatitude
                            : _nextStop!.effectiveDropoffLatitude;
                        final lng = trip.tripType == TripType.pickup
                            ? _nextStop!.effectivePickupLongitude
                            : _nextStop!.effectiveDropoffLongitude;
                        if (lat != null && lng != null) {
                          _navigateToLocation(lat, lng);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.phone_rounded,
                      label: 'اتصال',
                      color: AppColors.success,
                      onTap: () => _callPassenger(
                        _nextStop!.guardianPhone ?? _nextStop!.passengerPhone,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Show different action based on trip type
                  if (trip.tripType == TripType.pickup)
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.check_circle_rounded,
                        label: 'صعد',
                        color: AppColors.secondary,
                        onTap: () => _markPassengerBoarded(_nextStop!),
                      ),
                    )
                  else
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.location_on_rounded,
                        label: 'نزل',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => _markPassengerDropped(_nextStop!),
                      ),
                    ),
                ],
              ),
            ] else if (trip.tripType == TripType.pickup &&
                _areAllPickupsCompleted(trip) &&
                trip.companyLatitude != null &&
                trip.companyLongitude != null)
              // Show company destination after all pickups completed
              _buildCompanyDestinationCard(trip)
            else
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تم إكمال جميع المحطات! 🎉',
                      style: AppTypography.h6.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

            // === أزرار التحكم بحالة الرحلة ===
            const SizedBox(height: 16),
            _buildTripStateActions(trip),

            // ✅ زر إنهاء الرحلة (يظهر في الحالات التي لم يكن فيها موجوداً بالـ UI)
            // - نُخفيه عندما تكون بطاقة "الوجهة النهائية" ظاهرة لأنها تحتوي بالفعل على زر الإنهاء.
            // - نُفعّله فقط عندما يتم إكمال جميع المحطات (remainingPassengers == 0).
            if (trip.state.isOngoing && !isShowingCompanyDestination) ...[
              const SizedBox(height: 12),
              _buildBottomSheetCompleteTripSection(trip),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDestinationCard(Trip trip) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'الوجهة النهائية',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.companyName ?? 'الشركة',
                    style: AppTypography.h6,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'مقر الشركة',
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Action buttons row
        Row(
          children: [
            // Navigation button
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.navigation_rounded,
                label: 'الملاحة',
                color: const Color(0xFF10B981),
                onTap: () {
                  if (trip.companyLatitude != null &&
                      trip.companyLongitude != null) {
                    _navigateToLocation(
                      trip.companyLatitude!,
                      trip.companyLongitude!,
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            // Complete trip button
            Expanded(
              flex: 2,
              child: _buildCompleteTripButton(trip),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteTripButton(Trip trip) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCompleteTripDialog(trip),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.flag_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'إنهاء الرحلة',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetCompleteTripSection(Trip trip) {
    final canComplete = trip.remainingPassengers == 0;

    return Column(
      children: [
        if (canComplete)
          _buildCompleteTripButton(trip)
        else
          Opacity(
            opacity: 0.45,
            child: IgnorePointer(
              child: _buildCompleteTripButton(trip),
            ),
          ),
        if (!canComplete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'متبقي ${trip.remainingPassengers} راكب',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// 🎮 أزرار التحكم بحالة الرحلة
  Widget _buildTripStateActions(Trip trip) {
    // الرحلة مسودة - زر التأكيد
    if (trip.state == TripState.draft) {
      return _buildStateActionButton(
        icon: Icons.check_circle_rounded,
        label: 'تأكيد الرحلة',
        color: AppColors.success,
        onTap: () => _confirmTrip(trip),
      );
    }

    // الرحلة مخططة - زر البدء
    if (trip.state.canStart) {
      return _buildStateActionButton(
        icon: Icons.play_arrow_rounded,
        label: 'بدء الرحلة الآن',
        color: AppColors.primary,
        onTap: () => _startTrip(trip),
      );
    }

    // الرحلة جارية - زر الإنهاء (موجود أعلاه في الـ bottom sheet)
    if (trip.state.isOngoing) {
      return const SizedBox.shrink(); // الزر موجود في مكان آخر
    }

    // الرحلة منتهية
    if (trip.state == TripState.done) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              'تمت الرحلة بنجاح ✅',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStateActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _promptConfirmTripNote() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('تأكيد الرحلة', style: TextStyle(fontFamily: 'Cairo')),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'ملاحظة (اختياري)...',
              hintStyle: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: const Text('بدون ملاحظة',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  /// 🎮 تأكيد الرحلة
  Future<void> _confirmTrip(Trip trip) async {
    HapticFeedback.mediumImpact();

    final note = await _promptConfirmTripNote();
    if (note == null || !mounted) return; // cancelled

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final success = await ref.read(smartTripProvider.notifier).confirmTrip(
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
          note: note,
        );

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('✅ تم تأكيد الرحلة بنجاح');
      } else {
        _showErrorSnackBar('فشل تأكيد الرحلة');
      }
    }
  }

  /// 🎮 بدء الرحلة
  Future<void> _startTrip(Trip trip) async {
    HapticFeedback.mediumImpact();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final success = await ref.read(smartTripProvider.notifier).startTrip();

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('🚌 تم بدء الرحلة بنجاح');
      } else {
        _showErrorSnackBar('فشل بدء الرحلة');
      }
    }
  }

  Future<void> _showCompleteTripDialog(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'إنهاء الرحلة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من إنهاء الرحلة؟',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'إجمالي الركاب',
                    '${trip.totalPassengers}',
                    Icons.people_outline,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'صعدوا',
                    '${trip.boardedCount}',
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'غائبون',
                    '${trip.absentCount}',
                    Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('إنهاء الرحلة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _completeTrip(trip);
    }
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color ?? AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.bodySmall,
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 🎮 إنهاء الرحلة - تحديث فوري متفائل
  Future<void> _completeTrip(Trip trip) async {
    HapticFeedback.mediumImpact();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );

    // استخدام smartTripProvider للتحديث الفوري
    // ملاحظة: completeTrip يستخدم tripId المحمل حالياً
    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.completeTrip();

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('✅ تم إنهاء الرحلة بنجاح');
        // Navigate back to trips list
        Navigator.pop(context);
      } else {
        _showErrorSnackBar('فشل إنهاء الرحلة');
      }
    }
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerCard() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _closePassengerCard,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping the card
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _selectedClusterPassengers != null
                      ? _buildClusterCard()
                      : _buildSinglePassengerCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClusterCard() {
    final passengers = _selectedClusterPassengers!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStopName ?? 'محطة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${passengers.length} راكب في هذه المحطة',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _closePassengerCard,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),

        // Passengers list
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: passengers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final passenger = passengers[index];
              return _buildPassengerListItem(passenger);
            },
          ),
        ),

        // Navigate button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final lat = passengers.first.effectivePickupLatitude;
                final lng = passengers.first.effectivePickupLongitude;
                if (lat != null && lng != null) {
                  _navigateToLocation(lat, lng);
                }
              },
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('الانتقال إلى المحطة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerListItem(TripLine passenger) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getColorFromName(passenger.passengerName),
                  _getColorFromName(passenger.passengerName).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getInitials(passenger.passengerName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger.passengerName ?? 'راكب',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(passenger.status.value),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(passenger.status.value),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أزرار الإشعارات المصغرة
              PassengerNotificationWidget(
                tripLine: passenger,
                trip: ref.read(smartTripProvider).trip,
                compact: true,
                showLabels: false,
                distanceToPassenger: _passengerDistances[passenger.id],
              ),
              const SizedBox(width: 6),
              _buildMiniActionButton(
                icon: Icons.phone,
                color: AppColors.success,
                onTap: () => _callPassenger(
                  passenger.guardianPhone ?? passenger.passengerPhone,
                ),
              ),
              const SizedBox(width: 8),
              _buildMiniActionButton(
                icon: Icons.message,
                color: AppColors.primary,
                onTap: () => _sendWhatsApp(
                  passenger.guardianPhone ?? passenger.passengerPhone,
                ),
              ),
              // Show undo button if passenger has been marked
              if (passenger.status.value == 'boarded' ||
                  passenger.status.value == 'absent' ||
                  passenger.status.value == 'dropped') ...[
                const SizedBox(width: 8),
                _buildMiniActionButton(
                  icon: Icons.undo,
                  color: AppColors.warning,
                  onTap: () => _resetPassengerStatus(passenger),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePassengerCard() {
    final passenger = _selectedPassenger!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getStatusColor(passenger.status.value),
                _getStatusColor(passenger.status.value).withOpacity(0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(passenger.passengerName),
                    style: TextStyle(
                      color: _getColorFromName(passenger.passengerName),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.passengerName ?? 'راكب',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(passenger.status.value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: _closePassengerCard,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),

        // Details
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Location
              _buildDetailRow(
                icon: passenger.usesPickupStop
                    ? Icons.location_on
                    : Icons.gps_fixed,
                label: 'الموقع',
                value: passenger.pickupLocationName,
              ),

              if (passenger.guardianName != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.person_outline,
                  label: 'ولي الأمر',
                  value: passenger.guardianName!,
                ),
              ],

              if (passenger.guardianPhone != null ||
                  passenger.passengerPhone != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.phone_outlined,
                  label: 'الهاتف',
                  value: passenger.guardianPhone ?? passenger.passengerPhone!,
                ),
              ],

              const SizedBox(height: 16),

              // 🔔 أزرار الإشعارات
              PassengerNotificationWidget(
                tripLine: passenger,
                trip: ref.read(smartTripProvider).trip,
                compact: false,
                showLabels: true,
                distanceToPassenger: _passengerDistances[passenger.id],
                onNotificationSent: () {
                  // تحديث البيانات
                  if (mounted) setState(() {});
                },
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.navigation_rounded,
                      label: 'الملاحة',
                      color: AppColors.primary,
                      onTap: () {
                        final lat = passenger.effectivePickupLatitude;
                        final lng = passenger.effectivePickupLongitude;
                        if (lat != null && lng != null) {
                          _navigateToLocation(lat, lng);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.phone_rounded,
                      label: 'اتصال',
                      color: AppColors.success,
                      onTap: () => _callPassenger(
                        passenger.guardianPhone ?? passenger.passengerPhone,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.message_rounded,
                      label: 'واتساب',
                      color: const Color(0xFF25D366),
                      onTap: () => _sendWhatsApp(
                        passenger.guardianPhone ?? passenger.passengerPhone,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status actions - based on trip type
              _buildPassengerStatusActions(passenger),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerStatusActions(TripLine passenger) {
    // استخدام smartTripProvider للبيانات المخزنة مؤقتاً
    final tripState = ref.read(smartTripProvider);
    final trip = tripState.trip;
    if (trip == null) return const SizedBox.shrink();

    final isPickup = trip.tripType == TripType.pickup;
    final isDropoff = trip.tripType == TripType.dropoff;

    // Check if passenger has been marked (can undo)
    final canUndo = passenger.status.value == 'boarded' ||
        passenger.status.value == 'absent' ||
        passenger.status.value == 'dropped';

    // For pickup trips: show "Mark Boarded" and "Mark Absent" buttons
    if (isPickup) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  label: 'صعد',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  isSelected: passenger.status.value == 'boarded',
                  onTap: () => _markPassengerBoarded(passenger),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusButton(
                  label: 'غائب',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  isSelected: passenger.status.value == 'absent',
                  onTap: () => _markPassengerAbsent(passenger),
                ),
              ),
            ],
          ),
          if (canUndo) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _buildStatusButton(
                label: 'تراجع (إعادة الحالة)',
                icon: Icons.undo,
                color: AppColors.warning,
                isSelected: false,
                onTap: () => _resetPassengerStatus(passenger),
              ),
            ),
          ],
        ],
      );
    }

    // For dropoff trips: show "Mark Dropped" and "Mark Absent" buttons
    if (isDropoff) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  label: 'نزل',
                  icon: Icons.location_on_outlined,
                  color: const Color(0xFF8B5CF6),
                  isSelected: passenger.status.value == 'dropped',
                  onTap: () => _markPassengerDropped(passenger),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusButton(
                  label: 'غائب',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  isSelected: passenger.status.value == 'absent',
                  onTap: () => _markPassengerAbsent(passenger),
                ),
              ),
            ],
          ),
          if (canUndo) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _buildStatusButton(
                label: 'تراجع (إعادة الحالة)',
                icon: Icons.undo,
                color: AppColors.warning,
                isSelected: false,
                onTap: () => _resetPassengerStatus(passenger),
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption,
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: 220,
      child: Column(
        children: [
          _buildMapControlButton(
            icon: Icons.my_location,
            onTap: _centerOnDriver,
          ),
          const SizedBox(height: 8),
          _buildMapControlButton(
            icon: Icons.fit_screen,
            onTap: _fitAllMarkers,
          ),
          const SizedBox(height: 8),
          _buildMapControlButton(
            icon: Icons.add,
            onTap: () {
              _mapController?.animateCamera(CameraUpdate.zoomIn());
            },
          ),
          const SizedBox(height: 8),
          _buildMapControlButton(
            icon: Icons.remove,
            onTap: () {
              _mapController?.animateCamera(CameraUpdate.zoomOut());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'جاري تحميل الخريطة...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFef5350), Color(0xFFe53935)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'حدث خطأ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadTrip,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'boarded':
      case 'dropped':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'boarded':
        return '✓ ركب';
      case 'dropped':
        return '✓ نزل';
      case 'absent':
        return '✗ غائب';
      default:
        return '⏱ في الانتظار';
    }
  }
}

/// Helper class to hold marker data
class _MarkerData {
  final Marker? marker;

  _MarkerData({this.marker});
}
