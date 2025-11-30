import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/constants/map_styles.dart';
import '../../../../core/services/map_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../trips/domain/entities/trip.dart';

/// Trip Map Widget - ويدجت خريطة الرحلة القابل لإعادة الاستخدام
/// 
/// يعرض خريطة تفاعلية مع:
/// - موقع السائق الحالي (إذا كان متاحاً)
/// - مواقع الركاب
/// - مسار الرحلة
class TripMapWidget extends StatefulWidget {
  final Trip trip;
  final geo.Position? currentPosition;
  final double? currentBearing;
  final bool showRoute;
  final bool showPassengerMarkers;
  final bool showDriverMarker;
  final bool autoFitBounds;
  final VoidCallback? onMapReady;
  final Function(LatLng)? onMapTap;

  const TripMapWidget({
    super.key,
    required this.trip,
    this.currentPosition,
    this.currentBearing,
    this.showRoute = true,
    this.showPassengerMarkers = true,
    this.showDriverMarker = true,
    this.autoFitBounds = true,
    this.onMapReady,
    this.onMapTap,
  });

  @override
  State<TripMapWidget> createState() => _TripMapWidgetState();
}

class _TripMapWidgetState extends State<TripMapWidget> {
  final MapService _mapService = MapService();
  MapboxMap? _mapboxMap;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    // Wait a bit for the map to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && _mapboxMap != null) {
      _updateMap();
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _isMapReady = true;
    _updateMap();
    widget.onMapReady?.call();
  }

  Future<void> _updateMap() async {
    if (!_isMapReady || _mapboxMap == null) return;

    try {
      // Auto-fit bounds or center on driver
      if (widget.autoFitBounds) {
        await _fitBounds();
      } else if (widget.showDriverMarker && widget.currentPosition != null) {
        await _centerOnDriver();
      }
    } catch (e) {
      debugPrint('Error updating map: $e');
    }
  }

  Future<void> _centerOnDriver() async {
    if (_mapboxMap == null || widget.currentPosition == null) return;

    try {
      final latLng = LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );

      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              latLng.longitude,
              latLng.latitude,
            ),
          ),
          zoom: 15.0,
          bearing: widget.currentBearing,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (e) {
      debugPrint('Error centering on driver: $e');
    }
  }

  Future<void> _fitBounds() async {
    if (_mapboxMap == null) return;

    try {
      final points = <LatLng>[];

      // Add driver position
      if (widget.currentPosition != null) {
        points.add(LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ));
      }

      // Add passenger locations
      for (final line in widget.trip.lines) {
        if (line.latitude != null && line.longitude != null) {
          points.add(LatLng(line.latitude!, line.longitude!));
        }
      }

      if (points.isEmpty) {
        // Default to Baghdad if no points
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(44.3661, 33.3152),
            ),
            zoom: 12.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
        return;
      }

      final bounds = _mapService.calculateBounds(points);
      final center = bounds.center;

      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              center.longitude,
              center.latitude,
            ),
          ),
          zoom: 13.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (e) {
      debugPrint('Error fitting bounds: $e');
    }
  }

  @override
  void didUpdateWidget(TripMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip != widget.trip ||
        oldWidget.currentPosition != widget.currentPosition) {
      _updateMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Stack(
          children: [
            // Map Widget
            MapWidget(
              key: const ValueKey('trip_map'),
              cameraOptions: CameraOptions(
                center: Point(
                  coordinates: Position(44.3661, 33.3152), // Default: Baghdad
                ),
                zoom: 12.0,
              ),
              styleUri: MapStyles.shuttlebeeStreets,
              textureView: true,
              onMapCreated: _onMapCreated,
            ),
            
            // Overlay with trip info (optional)
            if (widget.showPassengerMarkers || widget.showDriverMarker)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showDriverMarker && widget.currentPosition != null)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (widget.showDriverMarker && widget.currentPosition != null)
                        const SizedBox(width: 4),
                      if (widget.showDriverMarker && widget.currentPosition != null)
                        const Text(
                          'موقعك',
                          style: TextStyle(fontSize: 12),
                        ),
                      if (widget.showPassengerMarkers &&
                          widget.showDriverMarker &&
                          widget.currentPosition != null)
                        const SizedBox(width: 8),
                      if (widget.showPassengerMarkers)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (widget.showPassengerMarkers) const SizedBox(width: 4),
                      if (widget.showPassengerMarkers)
                        Text(
                          '${widget.trip.lines.length} محطة',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
