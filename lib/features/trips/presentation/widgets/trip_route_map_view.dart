import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/reusable_map_widget.dart';
import '../../../../core/widgets/map_marker_types.dart';
import '../../../../core/widgets/cross_platform_map.dart';
import '../../../../core/config/company_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip.dart';
import '../../../stops/domain/entities/shuttle_stop.dart';
import '../../../stops/presentation/providers/stop_providers.dart';

/// 🗺️ Trip Route Map View - عرض مسار الرحلة على الخريطة
class TripRouteMapView extends ConsumerWidget {
  final Trip trip;
  final void Function(ShuttleStop)? onStopSelected;

  const TripRouteMapView({
    super.key,
    required this.trip,
    this.onStopSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // جلب معلومات المحطات
    final stopsAsync = ref.watch(allStopsProvider);

    return stopsAsync.when(
      data: (allStops) {
        final markers = <MapMarkerData>[];
        final polylines = <MapPolylineData>[];

        // إضافة علامة الشركة (نقطة البداية)
        if (trip.companyLatitude != null && trip.companyLongitude != null) {
          markers.add(
            MapMarkerData(
              id: 'company',
              location: MapLocation(
                latitude: trip.companyLatitude!,
                longitude: trip.companyLongitude!,
              ),
              title: 'المقر الرئيسي',
              snippet: 'نقطة البداية',
              color: MarkerColor.violet,
              markerType: MapMarkerType.company,
            ),
          );
        }

        // إضافة علامات المحطات من خطوط الرحلة
        final tripStops = <ShuttleStop>[];
        final routePoints = <MapLocation>[];
        
        // إضافة نقطة البداية (الشركة) إلى المسار
        if (trip.companyLatitude != null && trip.companyLongitude != null) {
          routePoints.add(MapLocation(
            latitude: trip.companyLatitude!,
            longitude: trip.companyLongitude!,
          ));
        }

        // معالجة خطوط الرحلة
        for (final line in trip.lines) {
          // محطة الصعود
          if (line.pickupStopId != null) {
            final pickupStop = allStops.firstWhere(
              (s) => s.id == line.pickupStopId,
              orElse: () => allStops.firstWhere(
                (s) => false,
                orElse: () => ShuttleStop(
                  id: 0,
                  name: line.pickupStopName ?? 'محطة صعود',
                ),
              ),
            );
            if (pickupStop.hasCoordinates) {
              tripStops.add(pickupStop);
              final location = MapLocation(
                latitude: pickupStop.latitude!,
                longitude: pickupStop.longitude!,
              );
              routePoints.add(location);
              markers.add(
                StopMarkerHelper.createMarker(
                  stopId: 'pickup_${line.id}',
                  location: location,
                  stopName: pickupStop.name,
                  code: pickupStop.code,
                  type: StopType.pickup,
                  onTap: () => onStopSelected?.call(pickupStop),
                ),
              );
            } else if (line.pickupLatitude != null && line.pickupLongitude != null) {
              // استخدام الإحداثيات الشخصية إذا لم تكن هناك محطة
              final location = MapLocation(
                latitude: line.pickupLatitude!,
                longitude: line.pickupLongitude!,
              );
              routePoints.add(location);
              markers.add(
                PassengerMarkerHelper.createMarker(
                  passengerId: 'pickup_${line.id}',
                  location: location,
                  passengerName: line.passengerName ?? 'راكب',
                  phoneNumber: line.passengerPhone,
                  status: PassengerStatus.waiting,
                ),
              );
            }
          }

          // محطة النزول
          if (line.dropoffStopId != null) {
            final dropoffStop = allStops.firstWhere(
              (s) => s.id == line.dropoffStopId,
              orElse: () => allStops.firstWhere(
                (s) => false,
                orElse: () => ShuttleStop(
                  id: 0,
                  name: line.dropoffStopName ?? 'محطة نزول',
                ),
              ),
            );
            if (dropoffStop.hasCoordinates) {
              tripStops.add(dropoffStop);
              final location = MapLocation(
                latitude: dropoffStop.latitude!,
                longitude: dropoffStop.longitude!,
              );
              routePoints.add(location);
              markers.add(
                StopMarkerHelper.createMarker(
                  stopId: 'dropoff_${line.id}',
                  location: location,
                  stopName: dropoffStop.name,
                  code: dropoffStop.code,
                  type: StopType.dropoff,
                  onTap: () => onStopSelected?.call(dropoffStop),
                ),
              );
            } else if (line.dropoffLatitude != null && line.dropoffLongitude != null) {
              // استخدام الإحداثيات الشخصية إذا لم تكن هناك محطة
              final location = MapLocation(
                latitude: line.dropoffLatitude!,
                longitude: line.dropoffLongitude!,
              );
              routePoints.add(location);
              markers.add(
                PassengerMarkerHelper.createMarker(
                  passengerId: 'dropoff_${line.id}',
                  location: location,
                  passengerName: line.passengerName ?? 'راكب',
                  phoneNumber: line.passengerPhone,
                  status: PassengerStatus.completed,
                ),
              );
            }
          }
        }

        // إضافة خط المسار إذا كان هناك نقاط كافية
        if (routePoints.length >= 2) {
          polylines.add(
            MapPolylineData(
              id: 'trip_route_${trip.id}',
              points: routePoints,
              color: AppColors.dispatcherPrimary,
              width: 4,
            ),
          );
        }

        // حساب الموقع المركزي
        final centerLocation = _calculateCenter(markers);

        if (markers.isEmpty) {
          return _buildEmptyState();
        }

        return ReusableMapWidget(
          initialLocation: centerLocation,
          initialZoom: 13.0,
          markers: markers,
          polylines: polylines,
          showMyLocation: true,
          showMyLocationButton: true,
          showZoomControls: true,
          showTraffic: true,
          enableViewportCulling: true,
          enableClustering: false,
          overlayWidgets: [
            // معلومات الرحلة
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route_rounded, color: AppColors.dispatcherPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${markers.length} محطة • ${polylines.isNotEmpty ? "مسار متاح" : "لا يوجد مسار"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل المحطات',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// حساب الموقع المركزي
  MapLocation _calculateCenter(List<MapMarkerData> markers) {
    if (markers.isEmpty) {
      return CompanyConfig.defaultLocation;
    }

    double totalLat = 0;
    double totalLng = 0;
    int count = 0;

    for (final marker in markers) {
      totalLat += marker.location.latitude;
      totalLng += marker.location.longitude;
      count++;
    }

    return MapLocation(
      latitude: totalLat / count,
      longitude: totalLng / count,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد محطات لعرضها',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

