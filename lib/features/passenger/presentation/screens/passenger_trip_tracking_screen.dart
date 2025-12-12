import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// شاشة تتبع الرحلة للراكب - ShuttleBee
class PassengerTripTrackingScreen extends ConsumerStatefulWidget {
  final int tripId;

  const PassengerTripTrackingScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<PassengerTripTrackingScreen> createState() =>
      _PassengerTripTrackingScreenState();
}

class _PassengerTripTrackingScreenState
    extends ConsumerState<PassengerTripTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  BitmapDescriptor? _busMarker;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadCustomMarker() async {
    // يمكن تحميل أيقونة مخصصة للحافلة هنا
  }

  void _startAutoRefresh() {
    // تحديث الموقع كل 10 ثواني
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(tripDetailProvider(widget.tripId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));

    return Scaffold(
      body: tripAsync.when(
        data: (trip) {
        if (trip == null) {
          return const Center(
            child: Text('الرحلة غير موجودة', style: TextStyle(fontFamily: 'Cairo')),
          );
        }
        return _buildContent(trip);
      },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل الرحلة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(tripDetailProvider(widget.tripId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Trip trip) {
    return Stack(
      children: [
        // الخريطة
        _buildMap(trip),

        // الشريط العلوي
        _buildTopBar(trip),

        // بطاقة المعلومات السفلية
        _buildBottomCard(trip),
      ],
    );
  }

  Widget _buildMap(Trip trip) {
    // موقع افتراضي (يمكن استبداله بموقع الرحلة الفعلي)
    const defaultLocation = LatLng(24.7136, 46.6753); // الرياض

    final markers = <Marker>{};

    // إضافة علامة الحافلة إذا كان هناك موقع GPS
    if (trip.currentLatitude != null && trip.currentLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('bus'),
          position: LatLng(trip.currentLatitude!, trip.currentLongitude!),
          icon: _busMarker ?? BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: trip.vehicleName ?? 'الحافلة',
            snippet: 'آخر تحديث: ${_formatTime(trip.lastGpsUpdate)}',
          ),
        ),
      );
    }

    // إضافة علامات الركاب (استخدام الإحداثيات الفعلية)
    for (final line in trip.lines) {
      final lat = line.effectivePickupLatitude;
      final lng = line.effectivePickupLongitude;
      
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('passenger_${line.id}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              line.status == TripLineStatus.boarded
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: line.passengerName ?? 'راكب',
              snippet: '${line.pickupLocationName}\n${line.status.arabicLabel}',
            ),
          ),
        );
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: trip.currentLatitude != null && trip.currentLongitude != null
            ? LatLng(trip.currentLatitude!, trip.currentLongitude!)
            : defaultLocation,
        zoom: 14,
      ),
      markers: markers,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildTopBar(Trip trip) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
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
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      _buildStatusBadge(trip.state),
                      const SizedBox(width: 8),
                      Text(
                        trip.tripType.arabicLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.invalidate(tripDetailProvider(widget.tripId));
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatusBadge(TripState state) {
    Color color;
    String label;

    switch (state) {
      case TripState.ongoing:
        color = Colors.green;
        label = 'جارية';
        break;
      case TripState.planned:
        color = Colors.blue;
        label = 'مخططة';
        break;
      case TripState.done:
        color = Colors.grey;
        label = 'مكتملة';
        break;
      case TripState.cancelled:
        color = Colors.red;
        label = 'ملغاة';
        break;
      default:
        color = Colors.grey;
        label = 'مسودة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == TripState.ongoing) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 500.ms).fadeOut(duration: 500.ms),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(Trip trip) {
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
            // معلومات السائق والمركبة
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.driverName ?? 'السائق',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trip.vehicleName ?? 'المركبة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // زر الاتصال
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.phone_rounded, color: Colors.green),
                    onPressed: () {
                      // TODO: Implement call driver
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // معلومات الوقت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(
                  'الوقت المتوقع',
                  trip.plannedStartTime != null
                      ? _formatTime(trip.plannedStartTime)
                      : '--:--',
                  Icons.schedule_rounded,
                  Colors.blue,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[200],
                ),
                _buildTimeInfo(
                  'آخر تحديث',
                  trip.lastGpsUpdate != null
                      ? _formatTime(trip.lastGpsUpdate)
                      : 'لا يوجد',
                  Icons.gps_fixed_rounded,
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // شريط التقدم
            if (trip.state == TripState.ongoing) ...[
              _buildProgressBar(trip),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(Trip trip) {
    final totalPassengers = trip.totalPassengers;
    final boardedPassengers = trip.boardedCount;
    final progress =
        totalPassengers > 0 ? boardedPassengers / totalPassengers : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تقدم الرحلة',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              '$boardedPassengers / $totalPassengers راكب',
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
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

