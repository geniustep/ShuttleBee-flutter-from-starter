import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/services/map_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/cached_trip_provider.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../widgets/passenger_notification_widget.dart';

/// 🐝 ShuttleBee Driver Trip Detail Screen
/// صفحة تفاصيل الرحلة المميزة للسائق - سر نجاح التطبيق
class DriverTripDetailScreen extends ConsumerStatefulWidget {
  final int tripId;

  const DriverTripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<DriverTripDetailScreen> createState() =>
      _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends ConsumerState<DriverTripDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // === Map & Location ===
  final MapService _mapService = MapService();
  GoogleMapController? _mapController;
  geo.Position? _currentPosition;
  StreamSubscription<geo.Position>? _positionSubscription;
  bool _isMapExpanded = false;

  // === Animation Controllers ===
  late AnimationController _pulseController;
  late AnimationController _nearbyPulseController;

  // === State ===
  bool _isLoading = false;
  int _selectedPassengerIndex = -1;
  TripLine? _nearestPassenger;
  double? _nearestDistance;
  DateTime? _lastArrivedNotificationAt;
  int? _lastArrivedPassengerId;

  // === Notification Manager ===
  TripNotificationManager? _notificationManager;
  final Map<int, double> _passengerDistances = {}; // تخزين المسافات لكل راكب

  // === Constants ===
  static const double _nearbyThresholdMeters = 200; // 200 متر للاقتراب
  static const double _arrivedThresholdMeters = 50; // 50 متر للوصول

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initLocation();
    // Load trip into smartTripProvider for optimistic updates and caching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smartTripProvider.notifier).loadTrip(widget.tripId);
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _nearbyPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  Future<void> _initLocation() async {
    final hasPermission = await _mapService.checkLocationPermission();
    if (hasPermission) {
      _currentPosition = await _mapService.getCurrentLocation();
      _startLocationTracking();
      if (mounted) setState(() {});
    }
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = _mapService.watchPosition().listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _checkNearbyPassengers();
      }
    });
  }

  /// التحقق من الركاب القريبين
  void _checkNearbyPassengers() {
    if (_currentPosition == null) return;

    // Use smartTripProvider for real-time updates with caching
    final trip = ref.read(smartTripProvider).trip;
    // Important: DO NOT read tripDetailProvider here.
    // This method is called on every GPS update; tripDetailProvider is autoDispose
    // and would trigger repeated network calls + log spam.
    if (trip == null) return;
    _processNearbyPassengers(trip);
  }

  void _processNearbyPassengers(Trip trip) {
    TripLine? nearest;
    double? minDistance;

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
      // تجاهل الركاب الذين صعدوا أو نزلوا أو غائبين
      if (line.status == TripLineStatus.boarded ||
          line.status == TripLineStatus.dropped ||
          line.status == TripLineStatus.absent) {
        continue;
      }

      // استخدام الإحداثيات الفعلية (محطة أو شخصية)
      final lat = line.effectivePickupLatitude;
      final lng = line.effectivePickupLongitude;

      if (lat != null && lng != null) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );

        // تخزين المسافة لكل راكب
        _passengerDistances[line.id] = distance;

        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          nearest = line;
        }
      }
    }

    setState(() {
      _nearestPassenger = nearest;
      _nearestDistance = minDistance;
    });

    // تحديث مدير الإشعارات بموقع السائق الحالي
    if (_currentPosition != null) {
      _notificationManager?.updateDriverLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }

    // إظهار تنبيه إذا كان السائق قريب جداً
    if (minDistance != null && minDistance <= _arrivedThresholdMeters) {
      _showArrivedNotification(trip, nearest!);
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return geo.Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void _showArrivedNotification(Trip trip, TripLine passenger) {
    // تجنب التكرار
    if (!mounted) return;

    // Cooldown: prevent spamming the same "arrived" notification due to frequent GPS updates
    final now = DateTime.now();
    if (_lastArrivedPassengerId == passenger.id &&
        _lastArrivedNotificationAt != null &&
        now.difference(_lastArrivedNotificationAt!) <
            const Duration(seconds: 10)) {
      return;
    }
    _lastArrivedPassengerId = passenger.id;
    _lastArrivedNotificationAt = now;

    HapticFeedback.heavyImpact();

    final isPickup = trip.tripType == TripType.pickup;
    final isDropoff = trip.tripType == TripType.dropoff;

    // Determine which action to show based on trip type and passenger status
    String? actionLabel;
    VoidCallback? actionCallback;

    if (isPickup &&
        (passenger.status == TripLineStatus.notStarted ||
            passenger.status == TripLineStatus.pending)) {
      actionLabel = 'صعد';
      actionCallback = () => _markBoarded(passenger);
    } else if (isDropoff && passenger.status == TripLineStatus.boarded) {
      actionLabel = 'نزل';
      actionCallback = () => _markDropped(passenger);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎯 وصلت إلى موقع ${passenger.passengerName ?? 'الراكب'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Text(
                    'اضغط للتسجيل',
                    style: TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: actionLabel != null && actionCallback != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: actionCallback,
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nearbyPulseController.dispose();
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Use smartTripProvider for optimistic updates and caching
    final tripState = ref.watch(smartTripProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _buildBodyFromSmartState(tripState),
    );
  }

  Widget _buildBodyFromSmartState(SmartTripState tripState) {
    // Show trip content if we have data (even from cache)
    if (tripState.hasData) {
      return Stack(
        children: [
          _buildTripContent(tripState.trip!),
          // Show sync indicator if syncing
          if (tripState.isSyncing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'جاري المزامنة...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Show pending actions indicator
          if (tripState.hasPendingActions)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${tripState.pendingActionsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Show cache indicator
          if (tripState.isFromCache && !tripState.isSyncing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_bolt, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'محلي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // Show loading state
    if (tripState.isLoading) {
      return _buildLoadingState();
    }

    // Show error state
    if (tripState.hasError) {
      return _buildErrorState(tripState.error!);
    }

    // Fallback to tripDetailProvider
    final fallbackTripAsync = ref.watch(tripDetailProvider(widget.tripId));
    return fallbackTripAsync.when(
      data: (fallbackTrip) {
        if (fallbackTrip == null) {
          return _buildNotFoundState();
        }
        return _buildTripContent(fallbackTrip);
      },
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTripContent(Trip trip) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // === Hero Header with Map ===
            _buildHeroHeader(trip),

            // === Nearby Passenger Alert ===
            if (_nearestPassenger != null &&
                _nearestDistance != null &&
                _nearestDistance! <= _nearbyThresholdMeters &&
                trip.state.isOngoing)
              SliverToBoxAdapter(
                child: _buildNearbyPassengerAlert()
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
              ),

            // === Trip Status Card ===
            SliverToBoxAdapter(
              child: _buildTripStatusCard(trip)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            // === Quick Stats Row ===
            SliverToBoxAdapter(
              child: _buildQuickStats(trip)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            // === Vehicle & Route Info ===
            SliverToBoxAdapter(
              child: _buildInfoCards(trip)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            // === Passengers Section Header ===
            SliverToBoxAdapter(
              child: _buildPassengersHeader(trip)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms),
            ),

            // === Passengers List ===
            _buildPassengersList(trip),

            // === Bottom Spacing for Action Button ===
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),

        // === Floating Action Button ===
        if (trip.state.isOngoing)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildFloatingActions(trip),
          ),

        // === Loading Overlay ===
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'جاري التنفيذ...',
                        style: AppTypography.bodyMedium.copyWith(
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // 🚨 NEARBY PASSENGER ALERT
  // ============================================================
  Widget _buildNearbyPassengerAlert() {
    if (_nearestPassenger == null || _nearestDistance == null) {
      return const SizedBox.shrink();
    }

    final isVeryClose = _nearestDistance! <= _arrivedThresholdMeters;
    final distanceText = _nearestDistance! < 1000
        ? '${_nearestDistance!.toInt()} متر'
        : '${(_nearestDistance! / 1000).toStringAsFixed(1)} كم';

    return AnimatedBuilder(
      animation: _nearbyPulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isVeryClose
                  ? [
                      const Color(0xFF10B981),
                      const Color(0xFF059669),
                    ]
                  : [
                      const Color(0xFFF59E0B),
                      const Color(0xFFD97706),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isVeryClose
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B))
                    .withValues(
                  alpha: 0.3 + (_nearbyPulseController.value * 0.2),
                ),
                blurRadius: 12 + (_nearbyPulseController.value * 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              // Animated icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isVeryClose ? Icons.pin_drop : Icons.near_me,
                      color: Colors.white,
                      size: 28,
                    ),
                    // Pulse ring
                    Transform.scale(
                      scale: 1 + (_nearbyPulseController.value * 0.3),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.5 - (_nearbyPulseController.value * 0.5),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVeryClose ? '🎯 وصلت!' : '📍 اقتربت من راكب',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _nearestPassenger!.passengerName ?? 'راكب',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons - conditional based on trip type
              Builder(
                builder: (context) {
                  // Important: don't read tripDetailProvider here (autoDispose) because
                  // this widget can rebuild frequently due to GPS updates.
                  final trip = ref.read(smartTripProvider).trip;
                  if (trip == null) return const SizedBox.shrink();

                  final isPickup = trip.tripType == TripType.pickup;
                  final isDropoff = trip.tripType == TripType.dropoff;
                  final canMarkBoarded = isPickup &&
                      (_nearestPassenger!.status == TripLineStatus.notStarted ||
                          _nearestPassenger!.status == TripLineStatus.pending);
                  final canMarkDropped = isDropoff &&
                      _nearestPassenger!.status == TripLineStatus.boarded;

                  return Column(
                    children: [
                      if (canMarkBoarded)
                        _buildQuickActionChip(
                          icon: Icons.check_circle,
                          label: 'صعد',
                          onTap: () => _markBoarded(_nearestPassenger!),
                          color: Colors.white,
                          textColor: isVeryClose
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      if (canMarkDropped) ...[
                        if (canMarkBoarded) const SizedBox(height: 8),
                        _buildQuickActionChip(
                          icon: Icons.location_on,
                          label: 'نزل',
                          onTap: () => _markDropped(_nearestPassenger!),
                          color: Colors.white,
                          textColor: isVeryClose
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ],
                      if (canMarkBoarded || canMarkDropped)
                        const SizedBox(height: 8),
                      _buildQuickActionChip(
                        icon: Icons.cancel,
                        label: 'غائب',
                        onTap: () => _markAbsent(_nearestPassenger!),
                        color: Colors.white.withValues(alpha: 0.2),
                        textColor: Colors.white,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🗺️ HERO HEADER WITH MAP
  // ============================================================
  Widget _buildHeroHeader(Trip trip) {
    return SliverAppBar(
      expandedHeight: _isMapExpanded ? 400 : 280,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      leading: _buildBackButton(),
      actions: [
        _buildRefreshButton(),
        if (trip.state.isOngoing) _buildExpandMapButton(),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // === Map Background ===
            _buildMapWidget(trip),

            // === Gradient Overlay ===
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // === Trip Title Overlay ===
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTripTypeBadge(trip),
                      const SizedBox(width: 8),
                      _buildStateBadge(trip),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trip.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('EEEE، d MMMM', 'ar').format(trip.date),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeRange(trip),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // === Driver Location Indicator ===
            if (_currentPosition != null)
              Positioned(
                top: 100,
                right: 16,
                child: _buildDriverLocationBadge(),
              ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
    );
  }

  Widget _buildMapWidget(Trip trip) {
    return ClipRRect(
      child: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
          _fitMapBounds(trip);
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : const LatLng(33.3152, 44.3661), // Baghdad default
          zoom: 13,
        ),
        markers: _buildMarkers(trip),
        polylines: _buildPolylines(trip),
        circles: _buildProximityCircles(trip),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
      ),
    );
  }

  Set<Marker> _buildMarkers(Trip trip) {
    final markers = <Marker>{};

    // === Driver Marker ===
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: '🚌 موقعك الحالي',
            snippet: 'السائق',
          ),
        ),
      );
    }

    // === Passenger Markers ===
    for (int i = 0; i < trip.lines.length; i++) {
      final line = trip.lines[i];
      // استخدام الإحداثيات الفعلية (محطة أو شخصية)
      final lat = line.effectivePickupLatitude;
      final lng = line.effectivePickupLongitude;

      if (lat != null && lng != null) {
        final hue = _getPassengerMarkerHue(line.status);
        final isNearest = _nearestPassenger?.id == line.id;

        markers.add(
          Marker(
            markerId: MarkerId('passenger_${line.id}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title:
                  '${i + 1}. ${line.passengerName ?? 'راكب'}${isNearest ? ' 📍' : ''}',
              snippet: '${line.pickupLocationName}\n${line.status.arabicLabel}',
            ),
            onTap: () {
              setState(() {
                _selectedPassengerIndex = i;
              });
            },
          ),
        );
      }
    }

    return markers;
  }

  Set<Circle> _buildProximityCircles(Trip trip) {
    final circles = <Circle>{};

    // Draw circles around passengers to show proximity zones
    for (final line in trip.lines) {
      // استخدام الإحداثيات الفعلية (محطة أو شخصية)
      final lat = line.effectivePickupLatitude;
      final lng = line.effectivePickupLongitude;

      if (lat != null && lng != null) {
        // Skip completed passengers
        if (line.status == TripLineStatus.boarded ||
            line.status == TripLineStatus.dropped ||
            line.status == TripLineStatus.absent) {
          continue;
        }

        final isNearest = _nearestPassenger?.id == line.id;

        // Arrival zone (50m)
        circles.add(
          Circle(
            circleId: CircleId('arrival_${line.id}'),
            center: LatLng(lat, lng),
            radius: _arrivedThresholdMeters,
            fillColor: isNearest
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.1),
            strokeColor: isNearest ? AppColors.success : AppColors.primary,
            strokeWidth: 2,
          ),
        );

        // Approaching zone (200m)
        if (isNearest) {
          circles.add(
            Circle(
              circleId: CircleId('approach_${line.id}'),
              center: LatLng(lat, lng),
              radius: _nearbyThresholdMeters,
              fillColor: AppColors.warning.withValues(alpha: 0.1),
              strokeColor: AppColors.warning,
              strokeWidth: 1,
            ),
          );
        }
      }
    }

    return circles;
  }

  Set<Polyline> _buildPolylines(Trip trip) {
    final polylines = <Polyline>{};
    final points = <LatLng>[];

    // Add driver position first
    if (_currentPosition != null) {
      points.add(LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ));
    }

    // Add passenger locations in sequence (only pending ones)
    for (final line in trip.lines) {
      // استخدام الإحداثيات الفعلية (محطة أو شخصية)
      final lat = line.effectivePickupLatitude;
      final lng = line.effectivePickupLongitude;

      if (lat != null && lng != null) {
        // Show route only to pending passengers
        if (line.status == TripLineStatus.notStarted ||
            line.status == TripLineStatus.pending) {
          points.add(LatLng(lat, lng));
        }
      }
    }

    if (points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    return polylines;
  }

  double _getPassengerMarkerHue(TripLineStatus status) {
    switch (status) {
      case TripLineStatus.boarded:
        return BitmapDescriptor.hueBlue;
      case TripLineStatus.dropped:
        return BitmapDescriptor.hueGreen;
      case TripLineStatus.absent:
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  void _fitMapBounds(Trip trip) async {
    if (_mapController == null) return;

    final points = <LatLng>[];

    if (_currentPosition != null) {
      points.add(LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ));
    }

    for (final line in trip.lines) {
      // استخدام الإحداثيات الفعلية (محطة أو شخصية)
      final lat = line.effectivePickupLatitude;
      final lng = line.effectivePickupLongitude;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }

    final bounds = _mapService.calculateBounds(points);
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: bounds.southwest,
          northeast: bounds.northeast,
        ),
        80,
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
        onPressed: _isLoading
            ? null
            : () async {
                setState(() => _isLoading = true);
                // ignore: unused_result
                ref.refresh(tripDetailProvider(widget.tripId));
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) setState(() => _isLoading = false);
              },
      ),
    );
  }

  Widget _buildExpandMapButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          _isMapExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.white,
        ),
        onPressed: () {
          setState(() => _isMapExpanded = !_isMapExpanded);
        },
      ),
    );
  }

  Widget _buildTripTypeBadge(Trip trip) {
    final isPickup = trip.tripType.value == 'pickup';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPickup ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPickup ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            trip.tripType.arabicLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateBadge(Trip trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: trip.state.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trip.state.isOngoing)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.5 + (_pulseController.value * 0.5),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          Text(
            trip.state.arabicLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverLocationBadge() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.3 + (_pulseController.value * 0.2),
                ),
                blurRadius: 8 + (_pulseController.value * 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'موقعك مباشر',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 📊 TRIP STATUS CARD
  // ============================================================
  Widget _buildTripStatusCard(Trip trip) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            trip.state.color,
            trip.state.color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: trip.state.color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // === Progress Circle ===
          Row(
            children: [
              // Progress indicator
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: trip.completionPercentage / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    Text(
                      '${trip.completionPercentage.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusMessage(trip),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusSubtitle(trip),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // === Action Buttons ===
          _buildActionButtons(trip),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Trip trip) {
    // Draft state - show confirm button
    if (trip.state == TripState.draft) {
      return Column(
        children: [
          _buildConfirmTripButton(trip),
          const SizedBox(height: 12),
          _buildCancelTripButton(trip),
        ],
      );
    }
    // Planned state - show start button
    else if (trip.state.canStart) {
      return Column(
        children: [
          _buildStartTripButton(trip),
          const SizedBox(height: 12),
          _buildCancelTripButton(trip),
        ],
      );
    }
    // Ongoing state - show manage and complete buttons
    else if (trip.state.isOngoing) {
      return Row(
        children: [
          Expanded(child: _buildManageTripButton(trip)),
          const SizedBox(width: 12),
          Expanded(child: _buildCompleteTripButton(trip)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildConfirmTripButton(Trip trip) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _confirmTrip(trip),
        icon: const Icon(Icons.check_circle_rounded, size: 24),
        label: const Text(
          'تأكيد الرحلة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildStartTripButton(Trip trip) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _startTrip(trip),
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: const Text(
          'بدء الرحلة الآن',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildManageTripButton(Trip trip) {
    return ElevatedButton.icon(
      onPressed: () => _navigateToLiveMap(trip),
      icon: const Icon(Icons.map_outlined, size: 20),
      label: const Text(
        'الخريطة المباشرة',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: trip.state.color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildCompleteTripButton(Trip trip) {
    return ElevatedButton.icon(
      onPressed: () => _completeTrip(trip),
      icon: const Icon(Icons.check_circle_outline, size: 20),
      label: const Text(
        'إنهاء الرحلة',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white, width: 1.5),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildCancelTripButton(Trip trip) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _cancelTrip(trip),
        icon: const Icon(Icons.cancel_outlined, size: 20),
        label: const Text(
          'إلغاء الرحلة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📈 QUICK STATS
  // ============================================================
  Widget _buildQuickStats(Trip trip) {
    final isPickup = trip.tripType == TripType.pickup;
    final isDropoff = trip.tripType == TripType.dropoff;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_alt_rounded,
              label: 'إجمالي الركاب',
              value: '${trip.totalPassengers}',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          // Show "Boarded" only in pickup trips
          if (isPickup) ...[
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_rounded,
                label: 'صعدوا',
                value: '${trip.boardedCount}',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Show "Dropped" only in dropoff trips
          if (isDropoff) ...[
            Expanded(
              child: _buildStatCard(
                icon: Icons.location_on_rounded,
                label: 'نزلوا',
                value: '${trip.droppedCount}',
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _buildStatCard(
              icon: Icons.cancel_rounded,
              label: 'غائبون',
              value: '${trip.absentCount}',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📋 INFO CARDS
  // ============================================================
  Widget _buildInfoCards(Trip trip) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Vehicle Card
          Expanded(
            child: _buildVehicleCard(trip),
          ),
          const SizedBox(width: 12),
          // Route Card
          Expanded(
            child: _buildRouteCard(trip),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'المركبة',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trip.vehicleName ?? 'غير محدد',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (trip.vehiclePlateNumber != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trip.vehiclePlateNumber!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteCard(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'المسار',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${trip.lines.length} محطة',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          if (trip.plannedDistance != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.straighten,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${trip.plannedDistance!.toStringAsFixed(1)} كم',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 👥 PASSENGERS SECTION
  // ============================================================
  Widget _buildPassengersHeader(Trip trip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people_alt_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'قائمة الركاب',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${trip.boardedCount + trip.droppedCount}/${trip.totalPassengers}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersList(Trip trip) {
    if (trip.lines.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.person_off_rounded,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'لا يوجد ركاب في هذه الرحلة',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final passenger = trip.lines[index];
          return _buildPassengerCard(passenger, index, trip)
              .animate()
              .fadeIn(duration: 300.ms, delay: (50 * index).ms)
              .slideX(begin: 0.05, end: 0);
        },
        childCount: trip.lines.length,
      ),
    );
  }

  Widget _buildPassengerCard(TripLine passenger, int index, Trip trip) {
    final isSelected = _selectedPassengerIndex == index;
    final statusColor = _getStatusColor(passenger.status);
    final isNearest = _nearestPassenger?.id == passenger.id;

    // Calculate distance if driver position is available
    // استخدام الإحداثيات الفعلية (محطة أو شخصية)
    final passengerLat = passenger.effectivePickupLatitude;
    final passengerLng = passenger.effectivePickupLongitude;

    String? distanceText;
    if (_currentPosition != null &&
        passengerLat != null &&
        passengerLng != null) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        passengerLat,
        passengerLng,
      );
      distanceText = distance < 1000
          ? '${distance.toInt()} م'
          : '${(distance / 1000).toStringAsFixed(1)} كم';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPassengerIndex = isSelected ? -1 : index;
        });
        HapticFeedback.lightImpact();

        // Center map on this passenger
        if (passengerLat != null && passengerLng != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(passengerLat, passengerLng),
              16,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNearest
                ? AppColors.success
                : (isSelected ? statusColor : Colors.transparent),
            width: isNearest ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isNearest
                  ? AppColors.success.withValues(alpha: 0.3)
                  : (isSelected
                      ? statusColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05)),
              blurRadius: isNearest ? 15 : (isSelected ? 15 : 8),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // === Header Row ===
            Row(
              children: [
                // Sequence number with nearby indicator
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor,
                            statusColor.withValues(alpha: 0.7)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (isNearest)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: AnimatedBuilder(
                          animation: _nearbyPulseController,
                          builder: (context, child) {
                            return Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(
                                      alpha: 0.5 +
                                          (_nearbyPulseController.value * 0.3),
                                    ),
                                    blurRadius:
                                        4 + (_nearbyPulseController.value * 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.near_me,
                                color: Colors.white,
                                size: 8,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Name & status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              passenger.passengerName ?? 'راكب',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          if (distanceText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isNearest
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.straighten,
                                    size: 12,
                                    color: isNearest
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    distanceText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isNearest
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            passenger.status.arabicLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (isNearest) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'الأقرب',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Quick actions
                if (trip.state.isOngoing)
                  _buildPassengerQuickActions(passenger, trip),
              ],
            ),

            // === Expanded Details ===
            if (isSelected) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Phone
              if (passenger.passengerPhone != null)
                _buildDetailRow(
                  icon: Icons.phone_rounded,
                  label: 'الهاتف',
                  value: passenger.passengerPhone!,
                  color: AppColors.primary,
                  onTap: () => _makePhoneCall(passenger.passengerPhone!),
                ),

              // موقع الصعود (محطة أو شخصي)
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: passenger.usesPickupStop
                    ? Icons.location_on_rounded
                    : Icons.gps_fixed_rounded,
                label: passenger.usesPickupStop ? 'محطة الصعود' : 'موقع مخصص',
                value: passenger.pickupLocationDescription,
                color: passenger.usesPickupStop
                    ? const Color(0xFF8B5CF6)
                    : AppColors.info,
                onTap: passenger.hasPickupLocation
                    ? () => _navigateToPassenger(passenger)
                    : null,
              ),

              // موقع النزول إذا كان مختلفاً
              if (passenger.hasDropoffLocation) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: passenger.usesDropoffStop
                      ? Icons.flag_rounded
                      : Icons.gps_fixed_rounded,
                  label:
                      passenger.usesDropoffStop ? 'محطة النزول' : 'موقع النزول',
                  value: passenger.dropoffLocationDescription,
                  color: AppColors.success,
                  onTap: null,
                ),
              ],

              // Action buttons for ongoing trip
              if (trip.state.isOngoing &&
                  _canShowActions(passenger.status)) ...[
                const SizedBox(height: 16),
                _buildPassengerActions(passenger, trip),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerQuickActions(TripLine passenger, Trip trip) {
    if (!_canShowActions(passenger.status)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // أزرار الإشعارات للركاب المكتملين
          PassengerNotificationWidget(
            tripLine: passenger,
            trip: trip,
            compact: true,
            showLabels: false,
            distanceToPassenger: _passengerDistances[passenger.id],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(passenger.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(passenger.status),
              color: _getStatusColor(passenger.status),
              size: 24,
            ),
          ),
        ],
      );
    }

    final isPickup = trip.tripType == TripType.pickup;
    final isDropoff = trip.tripType == TripType.dropoff;

    // For pending passengers in pickup trips: show "Mark Boarded" button
    if ((passenger.status == TripLineStatus.notStarted ||
            passenger.status == TripLineStatus.pending) &&
        isPickup) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ زر أساسي أكبر (الأولوية) - يكون على اليمين في واجهة RTL
          _buildPrimaryActionButton(
            icon: Icons.check_circle,
            label: 'صعد',
            color: AppColors.success,
            onTap: () => _markBoarded(passenger),
          ),
          const SizedBox(width: 8),
          _buildMiniActionButton(
            icon: Icons.cancel,
            color: AppColors.error,
            onTap: () => _markAbsent(passenger),
            tooltip: 'غائب',
          ),
          const SizedBox(width: 8),
          // أزرار الإشعارات
          PassengerNotificationWidget(
            tripLine: passenger,
            trip: trip,
            compact: true,
            showLabels: false,
            distanceToPassenger: _passengerDistances[passenger.id],
          ),
        ],
      );
    }

    // For pending or boarded passengers in dropoff trips: show "Mark Dropped" button with "Mark Absent"
    if ((passenger.status == TripLineStatus.notStarted ||
            passenger.status == TripLineStatus.pending ||
            passenger.status == TripLineStatus.boarded) &&
        isDropoff) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ زر أساسي أكبر (الأولوية) - يكون على اليمين في واجهة RTL
          _buildPrimaryActionButton(
            icon: Icons.location_on,
            label: 'نزل',
            color: const Color(0xFF8B5CF6),
            onTap: () => _markDropped(passenger),
          ),
          const SizedBox(width: 8),
          _buildMiniActionButton(
            icon: Icons.cancel,
            color: AppColors.error,
            onTap: () => _markAbsent(passenger),
            tooltip: 'غائب',
          ),
          const SizedBox(width: 8),
          // أزرار الإشعارات
          PassengerNotificationWidget(
            tripLine: passenger,
            trip: trip,
            compact: true,
            showLabels: false,
            distanceToPassenger: _passengerDistances[passenger.id],
          ),
        ],
      );
    }

    // Show undo button for marked passengers (boarded, absent, dropped)
    if (passenger.status == TripLineStatus.boarded ||
        passenger.status == TripLineStatus.absent ||
        passenger.status == TripLineStatus.dropped) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniActionButton(
            icon: Icons.undo,
            color: AppColors.warning,
            onTap: () => _resetPassenger(passenger),
            tooltip: 'تراجع',
          ),
          const SizedBox(width: 8),
          // أزرار الإشعارات
          PassengerNotificationWidget(
            tripLine: passenger,
            trip: trip,
            compact: true,
            showLabels: false,
            distanceToPassenger: _passengerDistances[passenger.id],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// زر أساسي أكبر لعمليات "صعد/نزل" (أولوية أعلى داخل قائمة الركاب)
  ///
  /// ملاحظة: في واجهة RTL، الطفل الأول في Row يظهر على اليمين، لذلك نستخدمه كزر أساسي.
  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onTap != null ? color : AppColors.textPrimary,
                      fontFamily: 'Cairo',
                      decoration:
                          onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerActions(TripLine passenger, Trip trip) {
    final isPickup = trip.tripType == TripType.pickup;
    final isDropoff = trip.tripType == TripType.dropoff;

    return Row(
      children: [
        // For pending passengers in pickup trips: show "Mark Boarded" button
        if ((passenger.status == TripLineStatus.notStarted ||
                passenger.status == TripLineStatus.pending) &&
            isPickup) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markBoarded(passenger),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('صعد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _markAbsent(passenger),
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('غائب'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
        // For pending passengers in dropoff trips: show "Mark Dropped" button with "Mark Absent"
        if ((passenger.status == TripLineStatus.notStarted ||
                passenger.status == TripLineStatus.pending) &&
            isDropoff) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markDropped(passenger),
              icon: const Icon(Icons.location_on_rounded, size: 18),
              label: const Text('نزل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _markAbsent(passenger),
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('غائب'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
        // For boarded passengers in dropoff trips: show "Mark Dropped" button with "Mark Absent"
        if (passenger.status == TripLineStatus.boarded && isDropoff) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markDropped(passenger),
              icon: const Icon(Icons.location_on_rounded, size: 18),
              label: const Text('نزل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _markAbsent(passenger),
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('غائب'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // 🎯 FLOATING ACTIONS
  // ============================================================
  Widget _buildFloatingActions(Trip trip) {
    final isPickup = trip.tripType == TripType.pickup;

    // Count pending passengers (only for pickup trips)
    final pendingCount = isPickup
        ? trip.lines
            .where((l) =>
                l.status == TripLineStatus.notStarted ||
                l.status == TripLineStatus.pending)
            .length
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mark all as boarded (only for pickup trips)
          if (isPickup && pendingCount > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markAllBoarded(trip),
                icon: const Icon(Icons.done_all_rounded, size: 20),
                label: Text('صعدوا جميعاً ($pendingCount)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (isPickup && pendingCount > 0) const SizedBox(width: 12),
          // Complete trip
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _completeTrip(trip),
              icon: const Icon(Icons.flag_rounded, size: 20),
              label: const Text('إنهاء الرحلة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.5, end: 0);
  }

  // ============================================================
  // 🔧 HELPER METHODS
  // ============================================================
  String _getTimeRange(Trip trip) {
    if (trip.plannedStartTime == null || trip.plannedArrivalTime == null) {
      return 'غير محدد';
    }
    final start = DateFormat('HH:mm').format(trip.plannedStartTime!);
    final end = DateFormat('HH:mm').format(trip.plannedArrivalTime!);
    return '$start - $end';
  }

  String _getStatusMessage(Trip trip) {
    if (trip.state.isOngoing) {
      if (trip.remainingPassengers == 0) {
        return '🎉 تم إكمال جميع الركاب!';
      }
      return '🚌 الرحلة جارية';
    } else if (trip.state == TripState.done) {
      return '✅ تمت الرحلة بنجاح';
    } else if (trip.state == TripState.cancelled) {
      return '❌ تم إلغاء الرحلة';
    } else if (trip.state.canStart) {
      return '⏰ جاهز للانطلاق';
    }
    return '📋 رحلة ${trip.state.arabicLabel}';
  }

  String _getStatusSubtitle(Trip trip) {
    if (trip.state.isOngoing) {
      return 'متبقي ${trip.remainingPassengers} راكب';
    } else if (trip.state.canStart) {
      return 'اضغط لبدء الرحلة';
    }
    return '${trip.totalPassengers} راكب';
  }

  Color _getStatusColor(TripLineStatus status) {
    switch (status) {
      case TripLineStatus.boarded:
        return AppColors.success;
      case TripLineStatus.dropped:
        return const Color(0xFF8B5CF6);
      case TripLineStatus.absent:
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(TripLineStatus status) {
    switch (status) {
      case TripLineStatus.boarded:
        return Icons.check_circle_rounded;
      case TripLineStatus.dropped:
        return Icons.location_on_rounded;
      case TripLineStatus.absent:
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  bool _canShowActions(TripLineStatus status) {
    return status == TripLineStatus.notStarted ||
        status == TripLineStatus.pending ||
        status == TripLineStatus.boarded;
  }

  // ============================================================
  // 📞 ACTIONS
  // ============================================================
  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _navigateToPassenger(TripLine passenger) {
    // استخدام الإحداثيات الفعلية (محطة أو شخصية)
    final lat = passenger.effectivePickupLatitude;
    final lng = passenger.effectivePickupLongitude;

    if (lat == null || lng == null) return;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(lat, lng),
        17,
      ),
    );
  }

  void _navigateToLiveMap(Trip trip) {
    context.go('${RoutePaths.driverHome}/trip/${trip.id}/live-map');
  }

  Future<void> _confirmTrip(Trip trip) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    // استخدام smartTripProvider للتحديث الفوري والمتفائل
    // smartTripProvider يقوم بتحديث smartDriverTripsProvider تلقائياً
    final success = await ref.read(smartTripProvider.notifier).confirmTrip();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessSnackBar('تم تأكيد الرحلة بنجاح! ✅');
      } else {
        _showErrorSnackBar('فشل تأكيد الرحلة');
      }
    }
  }

  Future<void> _startTrip(Trip trip) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    // استخدام smartTripProvider للتحديث الفوري والمتفائل
    // smartTripProvider يقوم بتحديث smartDriverTripsProvider تلقائياً
    final success = await ref.read(smartTripProvider.notifier).startTrip();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessSnackBar('تم بدء الرحلة بنجاح! 🚌');
      } else {
        _showErrorSnackBar('فشل بدء الرحلة');
      }
    }
  }

  Future<void> _completeTrip(Trip trip) async {
    final confirmed = await _showConfirmDialog(
      title: 'إنهاء الرحلة',
      message: 'هل أنت متأكد من إنهاء الرحلة؟',
      confirmText: 'إنهاء',
      confirmColor: AppColors.success,
    );

    if (confirmed && mounted) {
      setState(() => _isLoading = true);

      // استخدام smartTripProvider للتحديث الفوري والمتفائل
      // smartTripProvider يقوم بتحديث smartDriverTripsProvider تلقائياً
      final success = await ref.read(smartTripProvider.notifier).completeTrip();

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _showSuccessSnackBar('تم إنهاء الرحلة بنجاح! ✅');
        } else {
          _showErrorSnackBar('فشل إنهاء الرحلة');
        }
      }
    }
  }

  Future<void> _cancelTrip(Trip trip) async {
    final confirmed = await _showConfirmDialog(
      title: 'إلغاء الرحلة',
      message: 'هل أنت متأكد من إلغاء الرحلة؟',
      confirmText: 'إلغاء الرحلة',
      confirmColor: AppColors.error,
    );

    if (confirmed && mounted) {
      setState(() => _isLoading = true);

      final repository = ref.read(tripRepositoryProvider);
      if (repository == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('خطأ في الاتصال. يرجى المحاولة مرة أخرى');
        }
        return;
      }

      final result = await repository.cancelTrip(widget.tripId);

      if (mounted) {
        setState(() => _isLoading = false);
        result.fold(
          (failure) {
            _showErrorSnackBar('فشل إلغاء الرحلة: ${failure.message}');
          },
          (_) {
            _showSuccessSnackBar('تم إلغاء الرحلة');
            // إعادة تحميل الرحلة لتحديث الحالة
            ref.read(smartTripProvider.notifier).loadTrip(widget.tripId);
            context.pop();
          },
        );
      }
    }
  }

  /// 🎮 تسجيل صعود راكب - تحديث فوري متفائل
  Future<void> _markBoarded(TripLine passenger) async {
    HapticFeedback.mediumImpact();

    // استخدام smartTripProvider للتحديث الفوري
    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.markPassengerBoarded(passenger.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('✅ ${passenger.passengerName ?? 'الراكب'} صعد');
        _checkNearbyPassengers(); // Update nearest passenger
      } else {
        _showErrorSnackBar('فشل تحديث حالة الراكب');
      }
    }
  }

  /// 🎮 تسجيل غياب راكب - تحديث فوري متفائل
  Future<void> _markAbsent(TripLine passenger) async {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.markPassengerAbsent(passenger.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('❌ ${passenger.passengerName ?? 'الراكب'} غائب');
        _checkNearbyPassengers(); // Update nearest passenger
      } else {
        _showErrorSnackBar('فشل تحديث حالة الراكب');
      }
    }
  }

  /// 🎮 تسجيل نزول راكب - تحديث فوري متفائل
  Future<void> _markDropped(TripLine passenger) async {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.markPassengerDropped(passenger.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('📍 ${passenger.passengerName ?? 'الراكب'} نزل');
        _checkNearbyPassengers();
      } else {
        _showErrorSnackBar('فشل تحديث حالة الراكب');
      }
    }
  }

  /// 🎮 إعادة حالة راكب - تحديث فوري متفائل
  Future<void> _resetPassenger(TripLine passenger) async {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(smartTripProvider.notifier);
    final success = await notifier.resetPassengerToPlanned(passenger.id);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar(
            '🔄 تم إعادة حالة ${passenger.passengerName ?? 'الراكب'}');
        _checkNearbyPassengers(); // Update nearest passenger
      } else {
        _showErrorSnackBar('فشل إعادة الحالة');
      }
    }
  }

  /// 🎮 تسجيل صعود جميع الركاب - تحديثات متتالية فورية
  Future<void> _markAllBoarded(Trip trip) async {
    final pendingCount = trip.lines
        .where((l) =>
            l.status == TripLineStatus.notStarted ||
            l.status == TripLineStatus.pending)
        .length;

    final confirmed = await _showConfirmDialog(
      title: 'تسجيل صعود الجميع',
      message: 'هل تريد تسجيل صعود جميع الركاب المتبقين ($pendingCount راكب)؟',
      confirmText: 'نعم، صعدوا جميعاً',
      confirmColor: AppColors.success,
    );

    if (confirmed && mounted) {
      HapticFeedback.heavyImpact();
      final notifier = ref.read(smartTripProvider.notifier);

      int successCount = 0;
      for (final line in trip.lines) {
        if (line.status == TripLineStatus.notStarted ||
            line.status == TripLineStatus.pending) {
          // التحديث الفوري لكل راكب
          final success = await notifier.markPassengerBoarded(line.id);
          if (success) successCount++;
        }
      }

      if (mounted) {
        _showSuccessSnackBar('✅ تم تسجيل صعود $successCount راكب');
      }
    }
  }

  // ============================================================
  // 🎨 DIALOGS & SNACKBARS
  // ============================================================
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================================
  // 🔄 LOADING & ERROR STATES
  // ============================================================
  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, Color(0xFFF8FAFC)],
          stops: [0.0, 0.3],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'جاري تحميل تفاصيل الرحلة...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Cairo',
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
          colors: [AppColors.error, Color(0xFFF8FAFC)],
          stops: [0.0, 0.3],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                error,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // ignore: unused_result
                  ref.refresh(tripDetailProvider(widget.tripId));
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.warning, Color(0xFFF8FAFC)],
          stops: [0.0, 0.3],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لم يتم العثور على الرحلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'قد تكون الرحلة محذوفة أو غير متاحة',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'العودة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
