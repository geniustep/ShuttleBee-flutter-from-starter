# 🛠️ دليل تطبيق تحسينات الخرائط - Implementation Guide

## 📋 نظرة عامة

هذا الدليل يوضح كيفية تطبيق التحسينات المقترحة خطوة بخطوة.

---

## 🚀 التحسين 1: Marker Clustering

### الخطوة 1: إضافة Dependency

```yaml
# pubspec.yaml
dependencies:
  google_maps_flutter: ^2.5.0  # يدعم Clustering في الإصدارات الحديثة
```

### الخطوة 2: تحديث tracking_map_widget.dart

```dart
class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  // إضافة ClusterManager
  gmaps.ClusterManager? _clusterManager;
  
  @override
  void initState() {
    super.initState();
    _setupListeners();
    _initializeClusterManager();
  }
  
  void _initializeClusterManager() {
    _clusterManager = gmaps.ClusterManager(
      clusterManagerId: const gmaps.ClusterManagerId('vehicles'),
      onClusterTap: (cluster) {
        // Zoom in عند النقر على cluster
        if (_googleMapController != null) {
          _googleMapController!.animateCamera(
            gmaps.CameraUpdate.newLatLngZoom(
              cluster.position,
              (_googleMapController!.getZoomLevel() ?? 10) + 2,
            ),
          );
        }
      },
    );
  }
  
  void _updateMarkers() {
    if (!mounted) return;
    
    setState(() {
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
            // إضافة clusterManagerId
            clusterManagerId: const gmaps.ClusterManagerId('vehicles'),
            infoWindow: gmaps.InfoWindow(
              title: vehicle.vehicleName,
              snippet: '${vehicle.driverName} - ${_getArabicStatus(vehicle)}',
            ),
            rotation: vehicle.currentLocation?.heading ?? 0,
            onTap: () => widget.cubit.selectDriver(vehicle),
          );
        }).toSet();
        
        _googleMarkers = vehicleMarkers;
        
        // تحديث ClusterManager
        _clusterManager?.setItems(_googleMarkers.toList());
      }
    });
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
                  // إضافة clusterManagers
                  clusterManagers: _clusterManager != null 
                      ? [_clusterManager!] 
                      : [],
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  trafficEnabled: true,
                  onMapCreated: (controller) {
                    _googleMapController = controller;
                    _updateMarkers();
                  },
                  onTap: (_) => widget.cubit.deselectVehicle(),
                )
              : CrossPlatformMap(
                  // ... باقي الكود
                ),
        ],
      ),
    );
  }
}
```

---

## ⏱️ التحسين 2: Debounce/Throttle

### تحديث tracking_map_widget.dart

```dart
class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  Timer? _markerUpdateTimer;
  Timer? _polylineUpdateTimer;
  
  // Debounce delay
  static const Duration _markerUpdateDelay = Duration(milliseconds: 300);
  static const Duration _polylineUpdateDelay = Duration(milliseconds: 500);
  
  void _setupListeners() {
    // الاستماع لتحديثات المركبات مع debounce
    _vehiclesSubscription = widget.cubit.vehiclesStream
        .distinct()
        .listen((vehicles) {
      if (!mounted) return;
      
      // إلغاء التحديث السابق
      _markerUpdateTimer?.cancel();
      
      // تأخير التحديث
      _markerUpdateTimer = Timer(_markerUpdateDelay, () {
        if (!mounted) return;
        
        // التحقق من التغييرات الفعلية
        final hasChanges = _vehicles.length != vehicles.length ||
            !_vehicles.values.every((v) => 
                vehicles[v.vehicleId]?.lastUpdateTime == v.lastUpdateTime);
        
        if (hasChanges) {
          setState(() {
            _vehicles = vehicles;
            _updateMarkers();
          });
        }
      });
    });
    
    // ... باقي الـ listeners
  }
  
  void _updatePolylines() {
    // إلغاء التحديث السابق
    _polylineUpdateTimer?.cancel();
    
    // تأخير التحديث
    _polylineUpdateTimer = Timer(_polylineUpdateDelay, () {
      if (!mounted) return;
      
      setState(() {
        // تحديث Polylines هنا
        _rebuildPolylines();
      });
    });
  }
  
  @override
  void dispose() {
    _markerUpdateTimer?.cancel();
    _polylineUpdateTimer?.cancel();
    _vehiclesSubscription?.cancel();
    _selectedVehicleSubscription?.cancel();
    _mapBoundsSubscription?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }
}
```

---

## 👁️ التحسين 3: Viewport Culling

### تحديث tracking_map_widget.dart

```dart
class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  gmaps.LatLngBounds? _currentViewport;
  double _currentZoom = CompanyConfig.defaultZoom;
  
  List<TrackedVehicle> _getVisibleVehicles() {
    // إذا لم يكن هناك viewport محدد، إرجاع جميع المركبات
    if (_currentViewport == null) {
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
    
    setState(() {
      // استخدام فقط المركبات المرئية
      final visibleVehicles = _getVisibleVehicles();
      
      if (_useGoogleMaps) {
        final vehicleMarkers = visibleVehicles
            .where((v) => v.currentLocation != null)
            .map((vehicle) {
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
          );
        }).toSet();
        
        _googleMarkers = vehicleMarkers;
      }
    });
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
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  trafficEnabled: true,
                  onMapCreated: (controller) {
                    _googleMapController = controller;
                    _updateMarkers();
                  },
                  // إضافة onCameraMove لتحديث viewport
                  onCameraMove: (position) {
                    _currentZoom = position.zoom;
                    _updateViewport();
                  },
                  onCameraIdle: () {
                    _updateViewport();
                  },
                  onTap: (_) => widget.cubit.deselectVehicle(),
                )
              : CrossPlatformMap(
                  // ... باقي الكود
                ),
        ],
      ),
    );
  }
  
  Future<void> _updateViewport() async {
    if (_googleMapController == null) return;
    
    try {
      final bounds = await _googleMapController!.getVisibleRegion();
      if (mounted && bounds != null) {
        setState(() {
          _currentViewport = bounds;
          _updateMarkers(); // تحديث العلامات المرئية فقط
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحديث viewport: $e');
    }
  }
}
```

---

## 💾 التحسين 4: Caching للأيقونات

### تحديث tracking_map_widget.dart

```dart
class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  // Cache للأيقونات
  final Map<String, gmaps.BitmapDescriptor> _iconCache = {};
  
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
  
  // تنظيف الـ cache عند الحاجة
  void _clearIconCache() {
    _iconCache.clear();
  }
  
  @override
  void dispose() {
    _clearIconCache();
    _markerUpdateTimer?.cancel();
    _polylineUpdateTimer?.cancel();
    _vehiclesSubscription?.cancel();
    _selectedVehicleSubscription?.cancel();
    _mapBoundsSubscription?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }
}
```

---

## 🎯 التحسين 5: تحسين تحديثات الكاميرا

### تحديث tracking_map_widget.dart

```dart
class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  bool _isCameraAnimating = false;
  DateTime? _lastCameraUpdate;
  
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
        });
      } else {
        _googleMapController!.moveCamera(update);
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
}
```

---

## 📐 التحسين 6: LayoutBuilder للـ Responsive Design

### تحديث live_tracking_monitor_screen.dart

```dart
Widget _buildResponsiveLayout(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      
      // تحديد نوع التخطيط حسب حجم الشاشة والاتجاه
      if (screenWidth >= _desktopBreakpoint ||
          (screenWidth >= _tabletBreakpoint && isLandscape)) {
        return _buildDesktopLayout();
      } else if (screenWidth >= _mobileBreakpoint) {
        return _buildTabletLayout();
      } else {
        return _buildMobileLayout();
      }
    },
  );
}
```

---

## 📊 التحسين 7: Performance Monitoring

### إنشاء ملف جديد: map_performance_monitor.dart

```dart
import 'dart:async';

class MapPerformanceMonitor {
  int _markerUpdateCount = 0;
  int _cameraUpdateCount = 0;
  int _polylineUpdateCount = 0;
  DateTime? _lastMarkerUpdateTime;
  DateTime? _lastCameraUpdateTime;
  DateTime? _lastPolylineUpdateTime;
  
  final List<Duration> _markerUpdateDurations = [];
  final List<Duration> _cameraUpdateDurations = [];
  
  void recordMarkerUpdate({Duration? duration}) {
    _markerUpdateCount++;
    _lastMarkerUpdateTime = DateTime.now();
    if (duration != null) {
      _markerUpdateDurations.add(duration);
      // الاحتفاظ بآخر 100 قياس فقط
      if (_markerUpdateDurations.length > 100) {
        _markerUpdateDurations.removeAt(0);
      }
    }
  }
  
  void recordCameraUpdate({Duration? duration}) {
    _cameraUpdateCount++;
    _lastCameraUpdateTime = DateTime.now();
    if (duration != null) {
      _cameraUpdateDurations.add(duration);
      if (_cameraUpdateDurations.length > 100) {
        _cameraUpdateDurations.removeAt(0);
      }
    }
  }
  
  void recordPolylineUpdate() {
    _polylineUpdateCount++;
    _lastPolylineUpdateTime = DateTime.now();
  }
  
  Map<String, dynamic> getStats() {
    final avgMarkerUpdateTime = _markerUpdateDurations.isEmpty
        ? 0.0
        : _markerUpdateDurations
                .map((d) => d.inMilliseconds)
                .reduce((a, b) => a + b) /
            _markerUpdateDurations.length;
    
    final avgCameraUpdateTime = _cameraUpdateDurations.isEmpty
        ? 0.0
        : _cameraUpdateDurations
                .map((d) => d.inMilliseconds)
                .reduce((a, b) => a + b) /
            _cameraUpdateDurations.length;
    
    return {
      'marker_updates': _markerUpdateCount,
      'camera_updates': _cameraUpdateCount,
      'polyline_updates': _polylineUpdateCount,
      'last_marker_update': _lastMarkerUpdateTime?.toIso8601String(),
      'last_camera_update': _lastCameraUpdateTime?.toIso8601String(),
      'last_polyline_update': _lastPolylineUpdateTime?.toIso8601String(),
      'avg_marker_update_time_ms': avgMarkerUpdateTime,
      'avg_camera_update_time_ms': avgCameraUpdateTime,
    };
  }
  
  void reset() {
    _markerUpdateCount = 0;
    _cameraUpdateCount = 0;
    _polylineUpdateCount = 0;
    _markerUpdateDurations.clear();
    _cameraUpdateDurations.clear();
  }
}
```

### استخدام Performance Monitor في tracking_map_widget.dart

```dart
class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  final MapPerformanceMonitor _performanceMonitor = MapPerformanceMonitor();
  
  void _updateMarkers() {
    if (!mounted) return;
    
    final stopwatch = Stopwatch()..start();
    
    setState(() {
      // تحديث العلامات هنا
      _rebuildMarkers();
    });
    
    stopwatch.stop();
    _performanceMonitor.recordMarkerUpdate(duration: stopwatch.elapsed);
    
    // طباعة الإحصائيات في debug mode
    if (kDebugMode && _markerUpdateCount % 10 == 0) {
      debugPrint('📊 Map Performance: ${_performanceMonitor.getStats()}');
    }
  }
  
  @override
  void dispose() {
    // طباعة الإحصائيات النهائية
    if (kDebugMode) {
      debugPrint('📊 Final Map Performance Stats: ${_performanceMonitor.getStats()}');
    }
    super.dispose();
  }
}
```

---

## ✅ خطوات التطبيق

1. **ابدأ بالتحسينات عالية الأولوية**:
   - Marker Clustering
   - Debounce/Throttle
   - Viewport Culling
   - Icon Caching

2. **اختبر كل تحسين على حدة**:
   - قم بقياس الأداء قبل وبعد كل تحسين
   - تأكد من عدم وجود regressions

3. **راقب الأداء**:
   - استخدم Performance Monitor
   - راقب استهلاك البطارية
   - راقب استهلاك الذاكرة

4. **حسّن تدريجياً**:
   - لا تطبق جميع التحسينات دفعة واحدة
   - ابدأ بالتحسينات الأكثر تأثيراً

---

## 🎯 النتائج المتوقعة

بعد تطبيق جميع التحسينات:
- ⚡ تحسين الأداء بنسبة 50-70%
- 🔋 تقليل استهلاك البطارية بنسبة 30-40%
- 📱 تجربة أفضل للمستخدم
- 🚀 استجابة أسرع

