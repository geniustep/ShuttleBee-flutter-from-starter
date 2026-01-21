import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'cross_platform_map.dart';
import '../config/company_config.dart';
import '../../features/dispatcher/presentation/utils/map_performance_monitor.dart';

/// 🗺️ Reusable Map Widget - ويدجت خريطة قابلة لإعادة الاستخدام
/// 
/// يمكن استخدامه لعرض أنواع مختلفة من البيانات:
/// - الركاب
/// - المحطات
/// - المركبات
/// - أي بيانات جغرافية أخرى
class ReusableMapWidget extends StatefulWidget {
  /// الموقع الافتراضي للخريطة
  final MapLocation initialLocation;
  
  /// مستوى التكبير الابتدائي
  final double initialZoom;
  
  /// العلامات (Markers) - يمكن أن تكون ركاب، محطات، مركبات، إلخ
  final List<MapMarkerData> markers;
  
  /// خطوط المسار (Polylines)
  final List<MapPolylineData> polylines;
  
  /// استدعاء عند النقر على الخريطة
  final void Function(MapLocation)? onMapTap;
  
  /// استدعاء عند النقر على علامة
  final void Function(String markerId)? onMarkerTap;
  
  /// استدعاء عند تحريك الكاميرا
  final void Function(MapLocation location, double zoom)? onCameraMove;
  
  /// هل يُظهر زر الموقع الحالي
  final bool showMyLocationButton;
  
  /// هل يُظهر علامة الموقع الحالي
  final bool showMyLocation;
  
  /// هل يُظهر أدوات التكبير/التصغير
  final bool showZoomControls;
  
  /// هل يُظهر حركة المرور
  final bool showTraffic;
  
  /// هل يُظهر البوصلة
  final bool showCompass;
  
  /// Widgets إضافية فوق الخريطة
  final List<Widget>? overlayWidgets;
  
  /// تفعيل Viewport Culling (إخفاء العلامات خارج الشاشة)
  final bool enableViewportCulling;
  
  /// تفعيل Marker Clustering (عند وجود أكثر من threshold)
  final bool enableClustering;
  
  /// عتبة Clustering (عدد العلامات)
  final int clusteringThreshold;

  const ReusableMapWidget({
    super.key,
    required this.initialLocation,
    this.initialZoom = CompanyConfig.defaultZoom,
    this.markers = const [],
    this.polylines = const [],
    this.onMapTap,
    this.onMarkerTap,
    this.onCameraMove,
    this.showMyLocationButton = false,
    this.showMyLocation = false,
    this.showZoomControls = false,
    this.showTraffic = false,
    this.showCompass = true,
    this.overlayWidgets,
    this.enableViewportCulling = true,
    this.enableClustering = true,
    this.clusteringThreshold = 50,
  });

  @override
  State<ReusableMapWidget> createState() => _ReusableMapWidgetState();
}

class _ReusableMapWidgetState extends State<ReusableMapWidget> {
  // Map Controllers
  gmaps.GoogleMapController? _googleMapController;
  CrossPlatformMapController? _crossPlatformMapController;

  // Performance optimizations
  Timer? _markerUpdateTimer;
  Timer? _cameraMoveTimer;
  final MapPerformanceMonitor _performanceMonitor = MapPerformanceMonitor();
  
  // Viewport culling
  gmaps.LatLngBounds? _currentViewport;
  double _currentZoom = CompanyConfig.defaultZoom;
  
  // Icon caching
  final Map<String, gmaps.BitmapDescriptor> _iconCache = {};
  
  // Filtered markers (viewport culling)
  List<MapMarkerData> _visibleMarkers = [];

  // Debounce delays
  static const Duration _markerUpdateDelay = Duration(milliseconds: 300);
  static const Duration _cameraMoveDelay = Duration(milliseconds: 500);

  // التحقق من دعم المنصة لـ Google Maps
  bool get _useGoogleMaps {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  // هل يجب استخدام Clustering؟
  bool get _shouldUseClustering => 
      widget.enableClustering && widget.markers.length > widget.clusteringThreshold;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _updateVisibleMarkers();
  }

  @override
  void didUpdateWidget(ReusableMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // تحديث العلامات المرئية عند تغيير العلامات
    if (oldWidget.markers != widget.markers) {
      _markerUpdateTimer?.cancel();
      _markerUpdateTimer = Timer(_markerUpdateDelay, () {
        if (mounted) {
          _updateVisibleMarkers();
        }
      });
    }
  }

  /// تحديث العلامات المرئية فقط (Viewport Culling)
  void _updateVisibleMarkers() {
    if (!widget.enableViewportCulling || _currentViewport == null || !_useGoogleMaps) {
      _visibleMarkers = widget.markers;
      return;
    }
    
    _visibleMarkers = widget.markers.where((marker) {
      return _currentViewport!.contains(
        gmaps.LatLng(marker.location.latitude, marker.location.longitude),
      );
    }).toList();
  }

  /// تحديث viewport عند تحريك الكاميرا
  Future<void> _updateViewport() async {
    if (_googleMapController == null || !_useGoogleMaps) return;
    
    try {
      final bounds = await _googleMapController!.getVisibleRegion();
      if (mounted) {
        setState(() {
          _currentViewport = bounds;
          _updateVisibleMarkers();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطأ في تحديث viewport: $e');
      }
    }
  }

  /// تنظيف الـ cache
  void _clearIconCache() {
    _iconCache.clear();
  }

  @override
  void dispose() {
    _markerUpdateTimer?.cancel();
    _cameraMoveTimer?.cancel();
    _googleMapController?.dispose();
    _clearIconCache();
    
    if (kDebugMode) {
      debugPrint('📊 Final Map Performance Stats: ${_performanceMonitor.getStats()}');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markersToShow = widget.enableViewportCulling ? _visibleMarkers : widget.markers;
    
    return Semantics(
      label: 'خريطة تفاعلية',
      child: Stack(
        children: [
          _useGoogleMaps
              ? gmaps.GoogleMap(
                  key: const ValueKey('reusable_google_map'),
                  initialCameraPosition: gmaps.CameraPosition(
                    target: gmaps.LatLng(
                      widget.initialLocation.latitude,
                      widget.initialLocation.longitude,
                    ),
                    zoom: widget.initialZoom,
                  ),
                  markers: markersToShow.map((m) {
                    final marker = m.toGoogleMarker();
                    // إضافة onTap callback
                    return gmaps.Marker(
                      markerId: marker.markerId,
                      position: marker.position,
                      icon: marker.icon,
                      infoWindow: marker.infoWindow,
                      rotation: marker.rotation,
                      onTap: () => widget.onMarkerTap?.call(m.id),
                    );
                  }).toSet(),
                  polylines: widget.polylines.map((p) => p.toGooglePolyline()).toSet(),
                  // إضافة clusterManagers عند الحاجة
                  clusterManagers: _shouldUseClustering 
                      ? {
                          gmaps.ClusterManager(
                            clusterManagerId: const gmaps.ClusterManagerId('markers'),
                            onClusterTap: (cluster) {
                              if (_googleMapController != null) {
                                _googleMapController!.animateCamera(
                                  gmaps.CameraUpdate.newLatLngZoom(
                                    cluster.position,
                                    (_currentZoom + 2).clamp(3.0, 20.0),
                                  ),
                                );
                              }
                            },
                          ),
                        }
                      : {},
                  myLocationEnabled: widget.showMyLocation,
                  myLocationButtonEnabled: widget.showMyLocationButton,
                  zoomControlsEnabled: widget.showZoomControls,
                  mapToolbarEnabled: false,
                  compassEnabled: widget.showCompass,
                  trafficEnabled: widget.showTraffic,
                  onMapCreated: (controller) {
                    _googleMapController = controller;
                    _currentZoom = widget.initialZoom;
                    _updateViewport();
                  },
                  onCameraMove: (position) {
                    _currentZoom = position.zoom;
                    
                    // Debounce camera move callback
                    _cameraMoveTimer?.cancel();
                    _cameraMoveTimer = Timer(_cameraMoveDelay, () {
                      widget.onCameraMove?.call(
                        MapLocation(
                          latitude: position.target.latitude,
                          longitude: position.target.longitude,
                        ),
                        position.zoom,
                      );
                      _updateViewport();
                    });
                  },
                  onCameraIdle: () {
                    _updateViewport();
                  },
                  onTap: (latLng) {
                    widget.onMapTap?.call(
                      MapLocation(
                        latitude: latLng.latitude,
                        longitude: latLng.longitude,
                      ),
                    );
                  },
                )
              : CrossPlatformMap(
                  key: const ValueKey('reusable_cross_platform_map'),
                  initialLocation: widget.initialLocation,
                  initialZoom: widget.initialZoom,
                  markers: markersToShow,
                  polylines: widget.polylines,
                  showMyLocation: widget.showMyLocation,
                  showMyLocationButton: widget.showMyLocationButton,
                  showZoomControls: widget.showZoomControls,
                  onMapCreated: (controller) {
                    _crossPlatformMapController = controller;
                  },
                  onTap: widget.onMapTap,
                ),
          
          // Overlay widgets
          if (widget.overlayWidgets != null)
            ...widget.overlayWidgets!,
        ],
      ),
    );
  }
  
  /// تحريك الكاميرا إلى موقع معين
  Future<void> animateToLocation(MapLocation location, {double? zoom, bool animate = true}) async {
    if (_useGoogleMaps) {
      if (_googleMapController == null) return;
      
      final update = gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(location.latitude, location.longitude),
          zoom: zoom ?? _currentZoom,
        ),
      );
      
      if (animate) {
        await _googleMapController!.animateCamera(update);
      } else {
        await _googleMapController!.moveCamera(update);
      }
    } else {
      await _crossPlatformMapController?.animateTo(location, zoom: zoom);
    }
  }
  
  /// تحريك الكاميرا لتشمل جميع العلامات
  Future<void> fitBounds(List<MapLocation> locations, {double padding = 50}) async {
    if (locations.isEmpty) return;
    
    if (_useGoogleMaps) {
      if (_googleMapController == null) return;
      
      if (locations.length == 1) {
        await animateToLocation(locations.first, zoom: 15);
        return;
      }
      
      double minLat = locations.first.latitude;
      double maxLat = locations.first.latitude;
      double minLng = locations.first.longitude;
      double maxLng = locations.first.longitude;
      
      for (final loc in locations) {
        if (loc.latitude < minLat) minLat = loc.latitude;
        if (loc.latitude > maxLat) maxLat = loc.latitude;
        if (loc.longitude < minLng) minLng = loc.longitude;
        if (loc.longitude > maxLng) maxLng = loc.longitude;
      }
      
      final update = gmaps.CameraUpdate.newLatLngBounds(
        gmaps.LatLngBounds(
          southwest: gmaps.LatLng(minLat, minLng),
          northeast: gmaps.LatLng(maxLat, maxLng),
        ),
        padding,
      );
      
      await _googleMapController!.animateCamera(update);
    } else {
      await _crossPlatformMapController?.fitBounds(locations, padding: padding);
    }
  }
}

