import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

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

  // Default location (Riyadh)
  static const _defaultLocation = LatLng(24.7136, 46.6753);

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(ongoingTripsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ongoingTripsAsync = ref.watch(ongoingTripsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          ongoingTripsAsync.when(
            data: (trips) => _buildMap(trips),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildMap([]),
          ),

          // Top Bar
          _buildTopBar(ongoingTripsAsync),

          // Trips List Panel
          if (_showTripsList)
            _buildTripsListPanel(ongoingTripsAsync),

          // Trip Details Card
          if (_selectedTrip != null && !_showTripsList)
            _buildTripDetailsCard(_selectedTrip!),
        ],
      ),
    );
  }

  Widget _buildMap(List<Trip> trips) {
    final markers = <Marker>{};

    // Add markers for each trip with GPS data
    for (final trip in trips) {
      if (trip.currentLatitude != null && trip.currentLongitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('trip_${trip.id}'),
            position: LatLng(trip.currentLatitude!, trip.currentLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              trip.state == TripState.ongoing
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: trip.name,
              snippet: trip.driverName ?? 'بدون سائق',
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

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _defaultLocation,
        zoom: 11,
      ),
      markers: markers,
      onMapCreated: (controller) {
        _mapController = controller;
        if (trips.isNotEmpty) {
          _fitMapToMarkers(trips);
        }
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

  void _fitMapToMarkers(List<Trip> trips) {
    final tripsWithLocation = trips
        .where((t) => t.currentLatitude != null && t.currentLongitude != null)
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

  Widget _buildTopBar(AsyncValue<List<Trip>> tripsAsync) {
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
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المراقبة الحية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  tripsAsync.when(
                    data: (trips) => Text(
                      '${trips.length} رحلة نشطة',
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
                ref.invalidate(ongoingTripsProvider);
              },
            ),
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
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_circle_rounded,
                      color: Color(0xFF7B1FA2),
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTripChip(Trip trip) {
    final hasLocation =
        trip.currentLatitude != null && trip.currentLongitude != null;

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
                  color: hasLocation
                      ? AppColors.success
                      : AppColors.textSecondary,
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
                color: hasLocation
                    ? AppColors.success
                    : AppColors.textSecondary,
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
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    trip.tripType == TripType.pickup
                        ? Icons.arrow_circle_up_rounded
                        : Icons.arrow_circle_down_rounded,
                    color: const Color(0xFF7B1FA2),
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
                      '${trip.totalPassengers > 0 ? ((trip.boardedCount / trip.totalPassengers) * 100).toStringAsFixed(0) : 0}%',
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
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF7B1FA2)),
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
