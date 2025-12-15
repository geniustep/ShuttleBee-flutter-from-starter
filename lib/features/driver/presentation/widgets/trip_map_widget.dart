import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  GoogleMapController? _googleMapController;
  bool _isMapReady = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

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
    if (mounted && _googleMapController != null) {
      _updateMap();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
    _isMapReady = true;
    _updateMap();
    widget.onMapReady?.call();
  }

  Future<void> _updateMap() async {
    if (!_isMapReady || _googleMapController == null) return;

    try {
      await _updateMarkers();
      if (widget.showRoute) {
        await _updatePolylines();
      }

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

  Future<void> _updateMarkers() async {
    final markers = <Marker>{};

    // Add driver marker
    if (widget.showDriverMarker && widget.currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          rotation: widget.currentBearing ?? 0,
          infoWindow: const InfoWindow(
            title: 'موقعك',
            snippet: 'السائق',
          ),
        ),
      );
    }

    // Add passenger markers
    if (widget.showPassengerMarkers) {
      for (final line in widget.trip.lines) {
        // استخدام الإحداثيات الفعلية (محطة أو شخصية)
        final lat = line.effectivePickupLatitude;
        final lng = line.effectivePickupLongitude;

        if (lat != null && lng != null) {
          final hue = _getMarkerHue(line.status.value);
          markers.add(
            Marker(
              markerId: MarkerId('passenger_${line.id}'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              infoWindow: InfoWindow(
                title: line.passengerName ?? 'راكب',
                snippet:
                    '${line.pickupLocationName}\n${_getStatusText(line.status.value)}',
              ),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _updatePolylines() async {
    final polylines = <Polyline>{};
    final points = <LatLng>[];

    // Add driver position
    if (widget.currentPosition != null) {
      points.add(
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
      );
    }

    // Add passenger locations (استخدام الإحداثيات الفعلية)
    for (final line in widget.trip.lines) {
      final lat = line.effectivePickupLatitude;
      final lng = line.effectivePickupLongitude;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
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

    setState(() {
      _polylines = polylines;
    });
  }

  double _getMarkerHue(String status) {
    switch (status) {
      case 'boarded':
      case 'dropped':
        return BitmapDescriptor.hueGreen;
      case 'absent':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueOrange;
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
        return '⏱ قيد الانتظار';
    }
  }

  Future<void> _centerOnDriver() async {
    if (_googleMapController == null || widget.currentPosition == null) return;

    try {
      await _googleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
            ),
            zoom: 15.0,
            bearing: widget.currentBearing ?? 0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error centering on driver: $e');
    }
  }

  Future<void> _fitBounds() async {
    if (_googleMapController == null) return;

    try {
      final points = <LatLng>[];

      // Add driver position
      if (widget.currentPosition != null) {
        points.add(
          LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
        );
      }

      // Add passenger locations (استخدام الإحداثيات الفعلية)
      for (final line in widget.trip.lines) {
        final lat = line.effectivePickupLatitude;
        final lng = line.effectivePickupLongitude;
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }

      if (points.isEmpty) {
        // If driver position available, center on it
        if (widget.currentPosition != null) {
          await _googleMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                widget.currentPosition!.latitude,
                widget.currentPosition!.longitude,
              ),
              15.0,
            ),
          );
        } else {
          // Default to a fallback location only if no driver position
          await _googleMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              const LatLng(33.3152, 44.3661),
              12.0,
            ),
          );
        }
        return;
      }

      if (points.length == 1) {
        await _googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15.0),
        );
        return;
      }

      final bounds = _mapService.calculateBounds(points);
      await _googleMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: bounds.southwest,
            northeast: bounds.northeast,
          ),
          100, // padding
        ),
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
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                // Use driver's position if available, otherwise default location
                target: widget.currentPosition != null
                    ? LatLng(
                        widget.currentPosition!.latitude,
                        widget.currentPosition!.longitude,
                      )
                    : const LatLng(33.3152, 44.3661),
                zoom: 15.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onTap: widget.onMapTap,
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
                      if (widget.showDriverMarker &&
                          widget.currentPosition != null)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (widget.showDriverMarker &&
                          widget.currentPosition != null)
                        const SizedBox(width: 4),
                      if (widget.showDriverMarker &&
                          widget.currentPosition != null)
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
    _googleMapController?.dispose();
    super.dispose();
  }
}
