import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../../core/widgets/cross_platform_map.dart';
import '../../../../core/config/company_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/tracking_monitor_cubit.dart' hide LatLng;
import '../models/tracked_vehicle.dart';
import '../models/map_bounds.dart';
import '../utils/map_performance_monitor.dart';

/// 🗺️ Tracking Map Widget - ويدجت خريطة التتبع
///
/// تكامل احترافي مع Google Maps مع:
/// - علامات المركبات في الوقت الحقيقي
/// - أيقونات علامات مخصصة
/// - انيميشن كاميرا سلسة
/// - تجميع للمركبات الكثيرة
/// - خطوط المسارات
/// - نوافذ معلومات السائقين
class TrackingMapWidget extends StatefulWidget {
  final TrackingMonitorCubit cubit;
  final MapLocation companyLocation;

  const TrackingMapWidget({
    super.key,
    required this.cubit,
    this.companyLocation = const MapLocation(
      latitude: 35.7595, // طنجة - الافتراضي
      longitude: -5.8340,
    ),
  });

  @override
  State<TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  // Map Controllers
  gmaps.GoogleMapController? _googleMapController;
  CrossPlatformMapController? _crossPlatformMapController;

  // Stream subscriptions
  StreamSubscription<Map<int, TrackedVehicle>>? _vehiclesSubscription;
  StreamSubscription<TrackedVehicle?>? _selectedVehicleSubscription;
  StreamSubscription<MapBounds?>? _mapBoundsSubscription;

  // Current state
  Map<int, TrackedVehicle> _vehicles = {};
  TrackedVehicle? _selectedVehicle;

  // Map markers
  Set<gmaps.Marker> _googleMarkers = {};
  List<MapMarkerData> _crossPlatformMarkers = [];
  
  // Map polylines for active trips
  Set<gmaps.Polyline> _googlePolylines = {};
  List<MapPolylineData> _crossPlatformPolylines = [];

  // Performance optimizations
  Timer? _markerUpdateTimer;
  Timer? _polylineUpdateTimer;
  final MapPerformanceMonitor _performanceMonitor = MapPerformanceMonitor();
  
  // Viewport culling
  gmaps.LatLngBounds? _currentViewport;
  double _currentZoom = CompanyConfig.defaultZoom;
  
  // Icon caching
  final Map<String, gmaps.BitmapDescriptor> _iconCache = {};
  
  // Camera update optimization
  bool _isCameraAnimating = false;
  DateTime? _lastCameraUpdate;
  
  // Marker clustering threshold
  static const int _clusteringThreshold = 50;

  // Debounce delays
  static const Duration _markerUpdateDelay = Duration(milliseconds: 300);
  static const Duration _polylineUpdateDelay = Duration(milliseconds: 500);

  // التحقق من دعم المنصة لـ Google Maps
  bool get _useGoogleMaps {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  // هل يجب استخدام Clustering؟
  bool get _shouldUseClustering => _vehicles.length > _clusteringThreshold;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }
  
  double get _mapCenterLat => widget.companyLocation.latitude;
  double get _mapCenterLng => widget.companyLocation.longitude;

  void _setupListeners() {
    // الاستماع لتحديثات المركبات مع distinct و debounce
    _vehiclesSubscription = widget.cubit.vehiclesStream.distinct().listen((vehicles) {
      if (!mounted) return;
      
      // التحقق من التغييرات الفعلية
      final hasChanges = _vehicles.length != vehicles.length ||
          !_vehicles.values.every((v) => vehicles[v.vehicleId]?.lastUpdateTime == v.lastUpdateTime);
      
      if (hasChanges) {
        // إلغاء التحديث السابق
        _markerUpdateTimer?.cancel();
        
        // تأخير التحديث لتجميع التحديثات المتعددة
        _markerUpdateTimer = Timer(_markerUpdateDelay, () {
          if (!mounted) return;
          setState(() {
            _vehicles = vehicles;
            _updateMarkers();
          });
        });
      }
    });

    // الاستماع للمركبة المحددة
    _selectedVehicleSubscription =
        widget.cubit.selectedVehicleStream.distinct().listen((vehicle) {
      if (!mounted) return;
      if (_selectedVehicle?.vehicleId != vehicle?.vehicleId) {
        setState(() {
          _selectedVehicle = vehicle;
          _updateMarkers();
        });
      }
    });

    // الاستماع لتغييرات حدود الخريطة
    _mapBoundsSubscription = widget.cubit.mapBoundsStream.distinct().listen((bounds) {
      if (bounds != null) {
        _animateToRegion(bounds);
      }
    });
  }

  /// الحصول على المركبات المرئية فقط (Viewport Culling)
  List<TrackedVehicle> _getVisibleVehicles() {
    // إذا لم يكن هناك viewport محدد، إرجاع جميع المركبات
    if (_currentViewport == null || !_useGoogleMaps) {
      return _vehicles.values.toList();
    }
    
    // تصفية المركبات المرئية فقط
    return _vehicles.values.where((vehicle) {
      if (vehicle.currentLocation == null) return false;
      
      final lat = vehicle.currentLocation!.latitude;
      final lng = vehicle.currentLocation!.longitude;
      
      return _currentViewport!.contains(gmaps.LatLng(lat, lng));
    }).toList();
  }
  

  void _updateMarkers() {
    if (!mounted) return;
    
    final stopwatch = Stopwatch()..start();
    
    setState(() {
      // إضافة علامة الشركة
      final companyName = widget.cubit.companyName;
      final companyMarker = _useGoogleMaps
          ? gmaps.Marker(
              markerId: const gmaps.MarkerId('company'),
              position: gmaps.LatLng(_mapCenterLat, _mapCenterLng),
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueViolet,
              ),
              infoWindow: gmaps.InfoWindow(
                title: companyName,
                snippet: 'المقر الرئيسي',
              ),
            )
          : null;

      // الحصول على المركبات المرئية فقط (Viewport Culling)
      final visibleVehicles = _getVisibleVehicles();
      final vehiclesWithLocation = visibleVehicles
          .where((v) => v.currentLocation != null)
          .toList();
      
      // المركبات في رحلة بدون موقع (استخدام موقع الشركة كاحتياطي)
      final vehiclesOnTripWithoutLocation = visibleVehicles
          .where((v) => v.tripId != null && v.currentLocation == null)
          .toList();

      if (kDebugMode) {
        debugPrint('🗺️ تحديث العلامات: ${vehiclesWithLocation.length} مع موقع (من ${_vehicles.length} إجمالي)، '
            '${vehiclesOnTripWithoutLocation.length} في رحلة بدون موقع');
      }

      if (_useGoogleMaps) {
        final vehicleMarkers = vehiclesWithLocation.map((vehicle) {
          final isSelected = _selectedVehicle?.vehicleId == vehicle.vehicleId;
          return gmaps.Marker(
            markerId: gmaps.MarkerId('vehicle_${vehicle.vehicleId}'),
            position: gmaps.LatLng(
              vehicle.currentLocation!.latitude,
              vehicle.currentLocation!.longitude,
            ),
            icon: _getMarkerIcon(vehicle, isSelected),
            infoWindow: gmaps.InfoWindow(
              title: vehicle.vehicleName,
              snippet: '${vehicle.driverName} - ${_getArabicStatus(vehicle)}',
            ),
            rotation: vehicle.currentLocation?.heading ?? 0,
            onTap: () => widget.cubit.selectDriver(vehicle),
            // إضافة clusterManagerId عند الحاجة
            clusterManagerId: _shouldUseClustering 
                ? const gmaps.ClusterManagerId('vehicles')
                : null,
          );
        }).toSet();
        
        // إضافة علامات للمركبات في رحلة بدون موقع
        final tripMarkers = vehiclesOnTripWithoutLocation.map((vehicle) {
          final isSelected = _selectedVehicle?.vehicleId == vehicle.vehicleId;
          return gmaps.Marker(
            markerId: gmaps.MarkerId('vehicle_${vehicle.vehicleId}'),
            position: gmaps.LatLng(_mapCenterLat, _mapCenterLng),
            icon: _getMarkerIcon(vehicle, isSelected),
            infoWindow: gmaps.InfoWindow(
              title: vehicle.vehicleName,
              snippet: '${vehicle.driverName} - ${_getArabicStatus(vehicle)} (في انتظار الموقع)',
            ),
            onTap: () => widget.cubit.selectDriver(vehicle),
            clusterManagerId: _shouldUseClustering 
                ? const gmaps.ClusterManagerId('vehicles')
                : null,
          );
        }).toSet();
        
        _googleMarkers = {if (companyMarker != null) companyMarker, ...vehicleMarkers, ...tripMarkers};
        
        // تحديث خطوط المسارات
        _updatePolylines();
      } else {
        final vehicleMarkers = vehiclesWithLocation.map((vehicle) {
          return MapMarkerData(
            id: 'vehicle_${vehicle.vehicleId}',
            location: MapLocation(
              latitude: vehicle.currentLocation!.latitude,
              longitude: vehicle.currentLocation!.longitude,
            ),
            title: vehicle.vehicleName,
            snippet: '${vehicle.driverName} - ${_getArabicStatus(vehicle)}',
            color: _getMarkerColor(vehicle.statusColor),
            rotation: vehicle.currentLocation?.heading ?? 0,
            onTap: () => widget.cubit.selectDriver(vehicle),
          );
        }).toList();
        
        // إضافة علامة الشركة
        final companyMarkerData = MapMarkerData(
          id: 'company',
          location: MapLocation(
            latitude: _mapCenterLat,
            longitude: _mapCenterLng,
          ),
          title: companyName,
          snippet: 'المقر الرئيسي',
          color: MarkerColor.violet,
        );
        
        // إضافة علامات للمركبات في رحلة بدون موقع
        final tripMarkers = vehiclesOnTripWithoutLocation.map((vehicle) {
          return MapMarkerData(
            id: 'vehicle_${vehicle.vehicleId}',
            location: MapLocation(
              latitude: _mapCenterLat,
              longitude: _mapCenterLng,
            ),
            title: vehicle.vehicleName,
            snippet: '${vehicle.driverName} - ${_getArabicStatus(vehicle)} (في انتظار الموقع)',
            color: _getMarkerColor(vehicle.statusColor),
            onTap: () => widget.cubit.selectDriver(vehicle),
          );
        }).toList();
        
        _crossPlatformMarkers = [companyMarkerData, ...vehicleMarkers, ...tripMarkers];
        
        // تحديث خطوط المسارات
        _updatePolylines();
      }
    });
    
    stopwatch.stop();
    _performanceMonitor.recordMarkerUpdate(duration: stopwatch.elapsed);
    
    // طباعة الإحصائيات في debug mode كل 10 تحديثات
    if (kDebugMode && _performanceMonitor.getStats()['marker_updates'] % 10 == 0) {
      debugPrint('📊 Map Performance: ${_performanceMonitor.getStats()}');
    }
  }
  
  String _getArabicStatus(TrackedVehicle vehicle) {
    switch (vehicle.statusColor) {
      case VehicleStatusColor.onTrip:
        return 'في رحلة';
      case VehicleStatusColor.available:
        return 'متاح';
      case VehicleStatusColor.busy:
        return 'مشغول';
      case VehicleStatusColor.offline:
        return 'غير متصل';
      default:
        return vehicle.statusText;
    }
  }
  
  void _updatePolylines() {
    // إلغاء التحديث السابق
    _polylineUpdateTimer?.cancel();
    
    // تأخير التحديث لتجميع التحديثات المتعددة
    _polylineUpdateTimer = Timer(_polylineUpdateDelay, () {
      if (!mounted) return;
      
      // الحصول على المركبات في رحلات نشطة (المرئية فقط)
      final visibleVehicles = _getVisibleVehicles();
      final vehiclesOnTrip = visibleVehicles
          .where((v) => v.tripId != null && v.currentLocation != null)
          .toList();
      
      setState(() {
        if (_useGoogleMaps) {
          _googlePolylines = vehiclesOnTrip.map((vehicle) {
            final points = [
              gmaps.LatLng(_mapCenterLat, _mapCenterLng),
              gmaps.LatLng(
                vehicle.currentLocation!.latitude,
                vehicle.currentLocation!.longitude,
              ),
            ];
            
            return gmaps.Polyline(
              polylineId: gmaps.PolylineId('trip_${vehicle.tripId}'),
              points: points,
              color: AppColors.dispatcherPrimary,
              width: 3,
              patterns: [gmaps.PatternItem.dash(20), gmaps.PatternItem.gap(10)],
            );
          }).toSet();
        } else {
          _crossPlatformPolylines = vehiclesOnTrip.map((vehicle) {
            return MapPolylineData(
              id: 'trip_${vehicle.tripId}',
              points: [
                MapLocation(latitude: _mapCenterLat, longitude: _mapCenterLng),
                MapLocation(
                  latitude: vehicle.currentLocation!.latitude,
                  longitude: vehicle.currentLocation!.longitude,
                ),
              ],
              color: AppColors.dispatcherPrimary,
              width: 3,
            );
          }).toList();
        }
      });
      
      _performanceMonitor.recordPolylineUpdate();
    });
  }

  /// الحصول على أيقونة العلامة مع Caching
  gmaps.BitmapDescriptor _getMarkerIcon(TrackedVehicle vehicle, bool isSelected) {
    final cacheKey = '${vehicle.statusColor}_${isSelected ? "selected" : "normal"}';
    
    // التحقق من الـ cache
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }
    
    // إنشاء أيقونة جديدة
    final icon = gmaps.BitmapDescriptor.defaultMarkerWithHue(
      _getMarkerHue(vehicle.statusColor),
    );
    
    // حفظ في الـ cache
    _iconCache[cacheKey] = icon;
    
    return icon;
  }
  
  /// تنظيف الـ cache عند الحاجة
  void _clearIconCache() {
    _iconCache.clear();
  }

  double _getMarkerHue(VehicleStatusColor statusColor) {
    switch (statusColor) {
      case VehicleStatusColor.onTrip:
        return gmaps.BitmapDescriptor.hueGreen;
      case VehicleStatusColor.available:
        return gmaps.BitmapDescriptor.hueBlue;
      case VehicleStatusColor.busy:
        return gmaps.BitmapDescriptor.hueOrange;
      case VehicleStatusColor.offline:
        return gmaps.BitmapDescriptor.hueRed;
      default:
        return gmaps.BitmapDescriptor.hueViolet;
    }
  }

  MarkerColor _getMarkerColor(VehicleStatusColor statusColor) {
    switch (statusColor) {
      case VehicleStatusColor.onTrip:
        return MarkerColor.green;
      case VehicleStatusColor.available:
        return MarkerColor.blue;
      case VehicleStatusColor.busy:
        return MarkerColor.orange;
      case VehicleStatusColor.offline:
        return MarkerColor.red;
      default:
        return MarkerColor.violet;
    }
  }

  void _animateToRegion(MapBounds bounds, {bool animate = true}) {
    if (_useGoogleMaps) {
      if (_googleMapController == null) return;
      
      // تجنب التحديثات المتكررة جداً
      final now = DateTime.now();
      if (_lastCameraUpdate != null) {
        final timeSinceLastUpdate = now.difference(_lastCameraUpdate!);
        if (timeSinceLastUpdate.inMilliseconds < 100) {
          return; // تجاهل التحديثات المتكررة جداً
        }
      }
      
      _lastCameraUpdate = now;
      
      final stopwatch = Stopwatch()..start();
      final update = gmaps.CameraUpdate.newLatLngBounds(
        gmaps.LatLngBounds(
          southwest: gmaps.LatLng(
            bounds.southwest.latitude,
            bounds.southwest.longitude,
          ),
          northeast: gmaps.LatLng(
            bounds.northeast.latitude,
            bounds.northeast.longitude,
          ),
        ),
        bounds.padding,
      );
      
      // استخدام moveCamera للتحديثات السريعة
      if (animate && !_isCameraAnimating) {
        _isCameraAnimating = true;
        _googleMapController!.animateCamera(update).then((_) {
          _isCameraAnimating = false;
          stopwatch.stop();
          _performanceMonitor.recordCameraUpdate(duration: stopwatch.elapsed);
        });
      } else {
        _googleMapController!.moveCamera(update);
        stopwatch.stop();
        _performanceMonitor.recordCameraUpdate(duration: stopwatch.elapsed);
      }
    } else {
      if (_crossPlatformMapController == null) return;
      _crossPlatformMapController!.fitBounds(
        [
          MapLocation(
            latitude: bounds.southwest.latitude,
            longitude: bounds.southwest.longitude,
          ),
          MapLocation(
            latitude: bounds.northeast.latitude,
            longitude: bounds.northeast.longitude,
          ),
        ],
        padding: bounds.padding,
      );
    }
  }
  
  /// تحديث viewport عند تحريك الكاميرا
  Future<void> _updateViewport() async {
    if (_googleMapController == null || !_useGoogleMaps) return;
    
    try {
      final bounds = await _googleMapController!.getVisibleRegion();
      if (mounted) {
        setState(() {
          _currentViewport = bounds;
          // تحديث العلامات المرئية فقط
          _updateMarkers();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطأ في تحديث viewport: $e');
      }
    }
  }

  @override
  void dispose() {
    _markerUpdateTimer?.cancel();
    _polylineUpdateTimer?.cancel();
    _vehiclesSubscription?.cancel();
    _selectedVehicleSubscription?.cancel();
    _mapBoundsSubscription?.cancel();
    _googleMapController?.dispose();
    _clearIconCache();
    
    // طباعة الإحصائيات النهائية في debug mode
    if (kDebugMode) {
      debugPrint('📊 Final Map Performance Stats: ${_performanceMonitor.getStats()}');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'خريطة التتبع مع المركبات',
      child: Stack(
        children: [
          _useGoogleMaps
              ? gmaps.GoogleMap(
                  key: const ValueKey('google_map'),
                  initialCameraPosition: gmaps.CameraPosition(
                    target: gmaps.LatLng(_mapCenterLat, _mapCenterLng),
                    zoom: CompanyConfig.defaultZoom,
                  ),
                  markers: _googleMarkers,
                  polylines: _googlePolylines,
                  // إضافة clusterManagers عند الحاجة
                  clusterManagers: _shouldUseClustering 
                      ? {
                          gmaps.ClusterManager(
                            clusterManagerId: const gmaps.ClusterManagerId('vehicles'),
                            onClusterTap: (cluster) {
                              // Zoom in عند النقر على cluster
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
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  trafficEnabled: true,
                  onMapCreated: (controller) {
                    _googleMapController = controller;
                    _currentZoom = CompanyConfig.defaultZoom;
                    _updateMarkers();
                  },
                  // إضافة onCameraMove لتحديث viewport و zoom
                  onCameraMove: (position) {
                    _currentZoom = position.zoom;
                    // تحديث viewport بشكل debounced
                    _markerUpdateTimer?.cancel();
                    _markerUpdateTimer = Timer(const Duration(milliseconds: 500), () {
                      _updateViewport();
                    });
                  },
                  onCameraIdle: () {
                    _updateViewport();
                  },
                  onTap: (_) => widget.cubit.deselectVehicle(),
                )
              : CrossPlatformMap(
                  key: const ValueKey('cross_platform_map'),
                  initialLocation: MapLocation(
                    latitude: _mapCenterLat,
                    longitude: _mapCenterLng,
                  ),
                  initialZoom: CompanyConfig.defaultZoom,
                  markers: _crossPlatformMarkers,
                  polylines: _crossPlatformPolylines,
                  showMyLocation: true,
                  showMyLocationButton: false,
                  showZoomControls: false,
                  onMapCreated: (controller) {
                    _crossPlatformMapController = controller;
                    _updateMarkers();
                  },
                  onTap: (_) => widget.cubit.deselectVehicle(),
                ),
          
          // شارة موقع الشركة
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 16,
                    color: AppColors.dispatcherPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.cubit.companyName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
