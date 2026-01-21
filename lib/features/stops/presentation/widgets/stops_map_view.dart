import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/reusable_map_widget.dart';
import '../../../../core/widgets/map_marker_types.dart';
import '../../../../core/widgets/cross_platform_map.dart';
import '../../../../core/config/company_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/shuttle_stop.dart';
import '../providers/stop_providers.dart';

/// 🗺️ Stops Map View - عرض المحطات على الخريطة
class StopsMapView extends ConsumerWidget {
  final List<ShuttleStop>? stops;
  final ShuttleStop? selectedStop;
  final void Function(ShuttleStop)? onStopSelected;

  const StopsMapView({
    super.key,
    this.stops,
    this.selectedStop,
    this.onStopSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopsAsync = stops != null 
        ? AsyncValue.data(stops!)
        : ref.watch(allStopsProvider);

    return stopsAsync.when(
      data: (stopsList) {
        if (stopsList.isEmpty) {
          return _buildEmptyState();
        }

        // تحويل المحطات إلى علامات
        final markers = stopsList
            .where((stop) => stop.hasCoordinates)
            .map((stop) => StopMarkerHelper.createMarker(
                  stopId: stop.id.toString(),
                  location: MapLocation(
                    latitude: stop.latitude!,
                    longitude: stop.longitude!,
                  ),
                  stopName: stop.name,
                  code: stop.code,
                  type: stop.stopType,
                  onTap: () => onStopSelected?.call(stop),
                ))
            .toList();

        // حساب الموقع المركزي
        final centerLocation = _calculateCenter(stopsList);

        return ReusableMapWidget(
          initialLocation: centerLocation,
          initialZoom: 12.0,
          markers: markers,
          showMyLocation: true,
          showMyLocationButton: true,
          showZoomControls: true,
          showTraffic: false,
          enableViewportCulling: true,
          enableClustering: true,
          clusteringThreshold: 20,
          onMarkerTap: (markerId) {
            final stopId = int.tryParse(markerId.replaceFirst('stop_', ''));
            if (stopId != null) {
              final stop = stopsList.firstWhere(
                (s) => s.id == stopId,
                orElse: () => stopsList.first,
              );
              onStopSelected?.call(stop);
            }
          },
          overlayWidgets: [
            // إضافة معلومات في الزاوية
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
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${stopsList.length} محطة',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
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

  /// حساب الموقع المركزي للمحطات
  MapLocation _calculateCenter(List<ShuttleStop> stops) {
    if (stops.isEmpty) {
      return CompanyConfig.defaultLocation;
    }

    final stopsWithCoordinates = stops.where((s) => s.hasCoordinates).toList();
    if (stopsWithCoordinates.isEmpty) {
      return CompanyConfig.defaultLocation;
    }

    double totalLat = 0;
    double totalLng = 0;
    int count = 0;

    for (final stop in stopsWithCoordinates) {
      totalLat += stop.latitude!;
      totalLng += stop.longitude!;
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
            Icons.location_off_rounded,
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

