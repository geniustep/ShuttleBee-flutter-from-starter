import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../core/services/live_tracking_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../providers/dispatcher_cached_providers.dart';

/// Dispatcher Monitor Screen - شاشة المراقبة الحية للمرسل - ShuttleBee
class DispatcherMonitorScreen extends ConsumerStatefulWidget {
  const DispatcherMonitorScreen({super.key});

  @override
  ConsumerState<DispatcherMonitorScreen> createState() =>
      _DispatcherMonitorScreenState();
}

class _DispatcherMonitorScreenState
    extends ConsumerState<DispatcherMonitorScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  Trip? _selectedTrip;
  bool _showTripsList = true;
  String? _lastFitSignature;

  // 🚀 WebSocket Live Tracking
  final bool _useLiveTracking = true; // استخدام WebSocket بدلاً من Polling

  // Default location (Riyadh)
  static const _defaultLocation = LatLng(24.7136, 46.6753);

  /// Treat (0,0) and out-of-range values as "no GPS yet".
  /// This prevents the map from snapping to the ocean when the backend sends
  /// placeholder coordinates.
  static bool _isValidLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.isNaN || lng.isNaN) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;

    // Common placeholder from some backends.
    if (lat.abs() < 0.00001 && lng.abs() < 0.00001) return false;

    return true;
  }

  static String _formatLastGpsUpdate(DateTime? dt) {
    if (dt == null) return 'آخر تحديث: غير معروف';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return 'آخر تحديث: الآن';
    if (diff.inMinutes < 1) return 'آخر تحديث: منذ ${diff.inSeconds} ث';
    if (diff.inHours < 1) return 'آخر تحديث: منذ ${diff.inMinutes} د';
    return 'آخر تحديث: منذ ${diff.inHours} س';
  }

  @override
  void initState() {
    super.initState();
    _initLiveTracking();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// تهيئة التتبع الحي عبر WebSocket
  Future<void> _initLiveTracking() async {
    // تأخير الاتصال لتجنب تعديل الـ provider أثناء build
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    if (_useLiveTracking) {
      // 🚀 استخدام WebSocket للتتبع الحي (الطريقة الجديدة)
      final success = await ref
          .read(dispatcherLiveTrackingProvider.notifier)
          .connectAndSubscribe();

      if (!success && mounted) {
        // إذا فشل WebSocket، نعود للـ Polling تلقائياً
        debugPrint(
          '⚠️ [Dispatcher] WebSocket unavailable, using polling fallback',
        );
        _startAutoRefresh();
      }
    } else {
      // الطريقة القديمة: Polling كل 5 ثواني
      _startAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    // Poll live monitoring frequently (backend recommends 2–5s).
    // ⚠️ هذه الطريقة القديمة - الآن نستخدم WebSocket
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(dispatcherOngoingTripsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ongoingTripsAsync = ref.watch(dispatcherOngoingTripsProvider);
    final liveTrackingState = ref.watch(dispatcherLiveTrackingProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          ongoingTripsAsync.when(
            data: (trips) =>
                _buildMap(trips, liveTrackingState.vehiclePositions),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildMap([], liveTrackingState.vehiclePositions),
          ),

          // Top Bar
          _buildTopBar(ongoingTripsAsync, liveTrackingState),

          // Trips List Panel
          if (_showTripsList) _buildTripsListPanel(ongoingTripsAsync),

          // Trip Details Card
          if (_selectedTrip != null && !_showTripsList)
            _buildTripDetailsCard(_selectedTrip!),
        ],
      ),
    );
  }

  Widget _buildMap(List<Trip> trips, List<VehiclePosition> livePositions) {
    final markers = <Marker>{};
    final liveTrackingState = ref.watch(dispatcherLiveTrackingProvider);

    // 🚀 أولاً: إضافة markers من التتبع الحي (WebSocket) - الأولوية
    final liveVehicleIds = <int>{};
    for (final position in livePositions) {
      if (_isValidLatLng(position.latitude, position.longitude)) {
        liveVehicleIds.add(position.vehicleId);
        markers.add(
          Marker(
            markerId: MarkerId('live_vehicle_${position.vehicleId}'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: 'مركبة ${position.vehicleId}',
              snippet:
                  '📍 تتبع حي • ${_formatLastGpsUpdate(position.timestamp)}',
            ),
            rotation: position.heading ?? 0,
          ),
        );
      }
    }

    // 🚗 ثالثاً: ماركر السائق عند العثور عليه عبر "أين السائق الآن؟"
    // يتم تعبئة هذه القيم عند استقبال location_response.
    for (final entry in liveTrackingState.driverLocations.entries) {
      final driverId = entry.key;
      final loc = entry.value;

      if (!_isValidLatLng(loc.latitude, loc.longitude)) continue;

      markers.add(
        Marker(
          markerId: MarkerId('driver_$driverId'),
          position: LatLng(loc.latitude, loc.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: 'سائق $driverId',
            snippet: '📍 تم العثور عليه الآن (طلب مباشر)',
          ),
          rotation: loc.heading ?? 0,
          zIndex: 10,
        ),
      );
    }

    // ثانياً: إضافة markers من الرحلات (للمركبات غير الموجودة في التتبع الحي)
    for (final trip in trips) {
      // تخطي إذا المركبة موجودة في التتبع الحي
      if (trip.vehicleId != null && liveVehicleIds.contains(trip.vehicleId)) {
        continue;
      }

      if (_isValidLatLng(trip.currentLatitude, trip.currentLongitude)) {
        markers.add(
          Marker(
            markerId: MarkerId('trip_${trip.id}'),
            position: LatLng(trip.currentLatitude!, trip.currentLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              trip.state == TripState.ongoing
                  ? BitmapDescriptor.hueOrange // برتقالي للبيانات غير الحية
                  : BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: trip.name,
              snippet:
                  '${trip.driverName ?? 'بدون سائق'} • ${_formatLastGpsUpdate(trip.lastGpsUpdate)}',
            ),
            onTap: () {
              setState(() {
                _selectedTrip = trip;
                _showTripsList = false;
              });
            },
          ),
        );
      }
    }

    // If trips arrive AFTER the map is created, auto-fit once to avoid landing on a far default location.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeFitMapToTrips(trips);
    });

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _defaultLocation,
        zoom: 11,
      ),
      markers: markers,
      onMapCreated: (controller) {
        _mapController = controller;
        _maybeFitMapToTrips(trips);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onTap: (_) {
        setState(() {
          _selectedTrip = null;
        });
      },
    );
  }

  void _maybeFitMapToTrips(List<Trip> trips) {
    if (_mapController == null) return;

    final tripsWithLocation = trips
        .where((t) => _isValidLatLng(t.currentLatitude, t.currentLongitude))
        .toList();
    if (tripsWithLocation.isEmpty) return;

    // Create a lightweight signature to avoid re-fitting on every rebuild.
    final signature = tripsWithLocation
        .map(
          (t) =>
              '${t.id}:${t.currentLatitude!.toStringAsFixed(5)},${t.currentLongitude!.toStringAsFixed(5)}',
        )
        .join('|');

    if (signature == _lastFitSignature) return;
    _lastFitSignature = signature;

    _fitMapToMarkers(tripsWithLocation);
  }

  void _fitMapToMarkers(List<Trip> trips) {
    final tripsWithLocation = trips
        .where((t) => _isValidLatLng(t.currentLatitude, t.currentLongitude))
        .toList();

    if (tripsWithLocation.isEmpty) return;

    if (tripsWithLocation.length == 1) {
      final trip = tripsWithLocation.first;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(trip.currentLatitude!, trip.currentLongitude!),
          15,
        ),
      );
    } else {
      // Calculate bounds
      double minLat = tripsWithLocation.first.currentLatitude!;
      double maxLat = tripsWithLocation.first.currentLatitude!;
      double minLng = tripsWithLocation.first.currentLongitude!;
      double maxLng = tripsWithLocation.first.currentLongitude!;

      for (final trip in tripsWithLocation) {
        if (trip.currentLatitude! < minLat) minLat = trip.currentLatitude!;
        if (trip.currentLatitude! > maxLat) maxLat = trip.currentLatitude!;
        if (trip.currentLongitude! < minLng) minLng = trip.currentLongitude!;
        if (trip.currentLongitude! > maxLng) maxLng = trip.currentLongitude!;
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          50,
        ),
      );
    }
  }

  Widget _buildTopBar(
    AsyncValue<List<Trip>> tripsAsync,
    DispatcherLiveTrackingState liveState,
  ) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.go(RoutePaths.dispatcherHome),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'المراقبة الحية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 🚀 WebSocket Connection Badge
                      _buildConnectionBadge(liveState),
                    ],
                  ),
                  tripsAsync.when(
                    data: (trips) => Text(
                      '${Formatters.formatSimple(trips.length)} رحلة نشطة${liveState.vehiclePositions.isNotEmpty ? ' • ${Formatters.formatSimple(liveState.vehiclePositions.length)} تتبع حي' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    loading: () => const Text(
                      'جاري التحميل...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    error: (_, __) => const Text(
                      'خطأ في التحميل',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _showTripsList ? Icons.map_rounded : Icons.list_rounded,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showTripsList = !_showTripsList;
                  if (_showTripsList) _selectedTrip = null;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.invalidate(dispatcherOngoingTripsProvider);
              },
            ),
            const RoleSwitcherButton(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildTripsListPanel(AsyncValue<List<Trip>> tripsAsync) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_circle_rounded,
                      color: AppColors.dispatcherPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'الرحلات النشطة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: tripsAsync.when(
                data: (trips) {
                  if (trips.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد رحلات نشطة حالياً',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: trips.length,
                    itemBuilder: (context, index) =>
                        _buildTripChip(trips[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text(
                    'خطأ في تحميل الرحلات',
                    style: TextStyle(
                      color: AppColors.error,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildTripChip(Trip trip) {
    final hasLocation =
        _isValidLatLng(trip.currentLatitude, trip.currentLongitude);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedTrip = trip;
          _showTripsList = false;
        });
        if (hasLocation) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(trip.currentLatitude!, trip.currentLongitude!),
              15,
            ),
          );
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasLocation
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLocation
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  hasLocation ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                  size: 16,
                  color:
                      hasLocation ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              trip.driverName ?? 'بدون سائق',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${trip.boardedCount}/${trip.totalPassengers} راكب',
              style: TextStyle(
                fontSize: 11,
                color:
                    hasLocation ? AppColors.success : AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailsCard(Trip trip) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    trip.tripType == TripType.pickup
                        ? Icons.arrow_circle_up_rounded
                        : Icons.arrow_circle_down_rounded,
                    color: AppColors.dispatcherPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: trip.state.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              trip.state.arabicLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: trip.state.color,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            trip.tripType.arabicLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() {
                      _selectedTrip = null;
                      _showTripsList = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  Icons.person_rounded,
                  'السائق',
                  trip.driverName ?? 'غير محدد',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[200],
                ),
                _buildDetailItem(
                  Icons.directions_bus_rounded,
                  'المركبة',
                  trip.vehicleName ?? 'غير محدد',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[200],
                ),
                _buildDetailItem(
                  Icons.people_rounded,
                  'الركاب',
                  '${trip.boardedCount}/${trip.totalPassengers}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تقدم الرحلة',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      '${Formatters.formatSimple(trip.totalPassengers > 0 ? ((trip.boardedCount / trip.totalPassengers) * 100).toStringAsFixed(0) : 0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: trip.totalPassengers > 0
                        ? trip.boardedCount / trip.totalPassengers
                        : 0,
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),

            // 🚀 زر طلب موقع السائق (عندما الرحلة غير ongoing أو GPS غير متوفر)
            if (trip.driverId != null &&
                (!_isValidLatLng(trip.currentLatitude, trip.currentLongitude) ||
                    !trip.state.isOngoing)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _requestDriverLocation(trip.driverId!),
                  icon: const Icon(Icons.location_searching_rounded, size: 18),
                  label: const Text(
                    'أين السائق الآن؟',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dispatcherPrimary,
                    side: const BorderSide(color: AppColors.dispatcherPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  /// 🚀 WebSocket Connection Badge
  Widget _buildConnectionBadge(DispatcherLiveTrackingState liveState) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    if (liveState.isConnected && liveState.isSubscribed) {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      text = 'WS';
      icon = Icons.wifi_rounded;
    } else if (liveState.isConnecting) {
      bgColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
      text = '...';
      icon = Icons.wifi_rounded;
    } else {
      bgColor = AppColors.textSecondary.withValues(alpha: 0.1);
      textColor = AppColors.textSecondary;
      text = 'REST';
      icon = Icons.cloud_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  /// طلب موقع سائق (عندما الرحلة غير ongoing)
  Future<void> _requestDriverLocation(int driverId) async {
    HapticFeedback.mediumImpact();

    final location = await ref
        .read(dispatcherLiveTrackingProvider.notifier)
        .requestDriverLocation(driverId);

    if (location != null && mounted) {
      // تحريك الكاميرا لموقع السائق
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          15,
        ),
      );

      // عرض snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📍 موقع السائق $driverId: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ السائق غير متصل أو لم يستجب',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.dispatcherPrimary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
