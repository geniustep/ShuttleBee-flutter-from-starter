import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng2;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Cross-Platform Map Widget - ويدجت خريطة يعمل على جميع المنصات
///
/// يستخدم:
/// - Google Maps على Android/iOS
/// - flutter_map (OpenStreetMap) على Windows/macOS/Linux/Web
class CrossPlatformMap extends StatefulWidget {
  /// الموقع الافتراضي للخريطة
  final MapLocation initialLocation;

  /// مستوى التكبير الابتدائي
  final double initialZoom;

  /// علامات الخريطة
  final List<MapMarkerData> markers;

  /// خطوط المسار (Polylines)
  final List<MapPolylineData> polylines;

  /// استدعاء عند إنشاء الخريطة
  final void Function(CrossPlatformMapController)? onMapCreated;

  /// استدعاء عند النقر على الخريطة
  final void Function(MapLocation)? onTap;

  /// هل يُظهر زر الموقع الحالي
  final bool showMyLocationButton;

  /// هل يُظهر علامة الموقع الحالي
  final bool showMyLocation;

  /// هل يُظهر أدوات التكبير/التصغير
  final bool showZoomControls;

  const CrossPlatformMap({
    super.key,
    required this.initialLocation,
    this.initialZoom = 13.0,
    this.markers = const [],
    this.polylines = const [],
    this.onMapCreated,
    this.onTap,
    this.showMyLocationButton = false,
    this.showMyLocation = false,
    this.showZoomControls = false,
  });

  @override
  State<CrossPlatformMap> createState() => _CrossPlatformMapState();

  /// هل المنصة تدعم Google Maps
  static bool get useGoogleMaps {
    // 🚀 Google Maps متاح على Android/iOS/Web
    if (kIsWeb) return true; // استخدم Google Maps على الويب
    return Platform.isAndroid || Platform.isIOS;
  }
}

class _CrossPlatformMapState extends State<CrossPlatformMap> {
  late CrossPlatformMapController _controller;
  gmaps.GoogleMapController? _googleMapController;
  fmap.MapController? _flutterMapController;

  @override
  void initState() {
    super.initState();
    _controller = CrossPlatformMapController();
    _flutterMapController = fmap.MapController();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _flutterMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (CrossPlatformMap.useGoogleMaps) {
      return _buildGoogleMap();
    } else {
      return _buildFlutterMap();
    }
  }

  /// بناء خريطة Google Maps (Android/iOS)
  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(
          widget.initialLocation.latitude,
          widget.initialLocation.longitude,
        ),
        zoom: widget.initialZoom,
      ),
      markers: widget.markers.map((m) => m.toGoogleMarker()).toSet(),
      polylines: widget.polylines.map((p) => p.toGooglePolyline()).toSet(),
      onMapCreated: (controller) {
        _googleMapController = controller;
        _controller._googleMapController = controller;
        widget.onMapCreated?.call(_controller);
      },
      onTap: (latLng) {
        widget.onTap?.call(
          MapLocation(latitude: latLng.latitude, longitude: latLng.longitude),
        );
      },
      myLocationEnabled: widget.showMyLocation,
      myLocationButtonEnabled: widget.showMyLocationButton,
      zoomControlsEnabled: widget.showZoomControls,
      mapToolbarEnabled: false,
    );
  }

  /// بناء خريطة flutter_map (Windows/macOS/Linux/Web)
  Widget _buildFlutterMap() {
    return fmap.FlutterMap(
      mapController: _flutterMapController,
      options: fmap.MapOptions(
        initialCenter: latlng2.LatLng(
          widget.initialLocation.latitude,
          widget.initialLocation.longitude,
        ),
        initialZoom: widget.initialZoom,
        onTap: (tapPosition, point) {
          widget.onTap?.call(
            MapLocation(latitude: point.latitude, longitude: point.longitude),
          );
        },
        onMapReady: () {
          _controller._flutterMapController = _flutterMapController;
          widget.onMapCreated?.call(_controller);
        },
      ),
      children: [
        // طبقة الخريطة - استخدام CartoDB (بديل مجاني لـ OpenStreetMap)
        // يمكن تغييرها إلى Mapbox أو أي خدمة خرائط أخرى
        fmap.TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.shuttlebee.app',
          // بديل: استخدام OpenStreetMap (يتطلب مراجعة سياسة الاستخدام)
          // urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        // طبقة الخطوط (Polylines)
        if (widget.polylines.isNotEmpty)
          fmap.PolylineLayer(
            polylines: widget.polylines
                .map((p) => p.toFlutterMapPolyline())
                .toList(),
          ),
        // طبقة العلامات (Markers)
        if (widget.markers.isNotEmpty)
          fmap.MarkerLayer(
            markers: widget.markers.map((m) => m.toFlutterMapMarker()).toList(),
          ),
        // أدوات التكبير/التصغير
        if (widget.showZoomControls)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () {
                  final currentZoom = _flutterMapController?.camera.zoom ?? 13;
                  _flutterMapController?.move(
                    _flutterMapController!.camera.center,
                    currentZoom + 1,
                  );
                }),
                const SizedBox(height: 8),
                _buildZoomButton(Icons.remove, () {
                  final currentZoom = _flutterMapController?.camera.zoom ?? 13;
                  _flutterMapController?.move(
                    _flutterMapController!.camera.center,
                    currentZoom - 1,
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

/// Controller للتحكم في الخريطة
class CrossPlatformMapController {
  gmaps.GoogleMapController? _googleMapController;
  fmap.MapController? _flutterMapController;

  /// تحريك الكاميرا إلى موقع معين
  Future<void> animateTo(MapLocation location, {double? zoom}) async {
    if (_googleMapController != null) {
      await _googleMapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: gmaps.LatLng(location.latitude, location.longitude),
            zoom: zoom ?? 15,
          ),
        ),
      );
    } else if (_flutterMapController != null) {
      _flutterMapController!.move(
        latlng2.LatLng(location.latitude, location.longitude),
        zoom ?? 15,
      );
    }
  }

  /// تحريك الكاميرا لتشمل جميع النقاط
  Future<void> fitBounds(
    List<MapLocation> locations, {
    double padding = 50,
  }) async {
    if (locations.isEmpty) return;

    if (locations.length == 1) {
      await animateTo(locations.first, zoom: 15);
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

    if (_googleMapController != null) {
      await _googleMapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            southwest: gmaps.LatLng(minLat, minLng),
            northeast: gmaps.LatLng(maxLat, maxLng),
          ),
          padding,
        ),
      );
    } else if (_flutterMapController != null) {
      _flutterMapController!.fitCamera(
        fmap.CameraFit.bounds(
          bounds: fmap.LatLngBounds(
            latlng2.LatLng(minLat, minLng),
            latlng2.LatLng(maxLat, maxLng),
          ),
          padding: EdgeInsets.all(padding),
        ),
      );
    }
  }
}

/// موقع على الخريطة
class MapLocation {
  final double latitude;
  final double longitude;

  const MapLocation({required this.latitude, required this.longitude});

  /// الموقع الافتراضي (الرياض)
  static const defaultLocation = MapLocation(
    latitude: 24.7136,
    longitude: 46.6753,
  );

  gmaps.LatLng toGoogleLatLng() => gmaps.LatLng(latitude, longitude);
  latlng2.LatLng toFlutterMapLatLng() => latlng2.LatLng(latitude, longitude);

  @override
  String toString() => 'MapLocation($latitude, $longitude)';
}

/// بيانات علامة على الخريطة
class MapMarkerData {
  final String id;
  final MapLocation location;
  final String? title;
  final String? snippet;
  final MarkerColor color;
  final double rotation;
  final VoidCallback? onTap;

  const MapMarkerData({
    required this.id,
    required this.location,
    this.title,
    this.snippet,
    this.color = MarkerColor.red,
    this.rotation = 0,
    this.onTap,
  });

  gmaps.Marker toGoogleMarker() {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(id),
      position: location.toGoogleLatLng(),
      infoWindow: gmaps.InfoWindow(title: title, snippet: snippet),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(color.googleHue),
      rotation: rotation,
      onTap: onTap,
    );
  }

  fmap.Marker toFlutterMapMarker() {
    return fmap.Marker(
      key: ValueKey(id),
      point: location.toFlutterMapLatLng(),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: title ?? '',
          child: Transform.rotate(
            angle: rotation * 3.14159 / 180,
            child: Icon(
              Icons.location_on,
              color: color.flutterColor,
              size: 36,
              shadows: const [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ألوان العلامات
enum MarkerColor {
  red,
  green,
  blue,
  orange,
  violet,
  cyan,
  yellow;

  double get googleHue {
    switch (this) {
      case MarkerColor.red:
        return gmaps.BitmapDescriptor.hueRed;
      case MarkerColor.green:
        return gmaps.BitmapDescriptor.hueGreen;
      case MarkerColor.blue:
        return gmaps.BitmapDescriptor.hueBlue;
      case MarkerColor.orange:
        return gmaps.BitmapDescriptor.hueOrange;
      case MarkerColor.violet:
        return gmaps.BitmapDescriptor.hueViolet;
      case MarkerColor.cyan:
        return gmaps.BitmapDescriptor.hueCyan;
      case MarkerColor.yellow:
        return gmaps.BitmapDescriptor.hueYellow;
    }
  }

  Color get flutterColor {
    switch (this) {
      case MarkerColor.red:
        return Colors.red;
      case MarkerColor.green:
        return Colors.green;
      case MarkerColor.blue:
        return Colors.blue;
      case MarkerColor.orange:
        return Colors.orange;
      case MarkerColor.violet:
        return Colors.purple;
      case MarkerColor.cyan:
        return Colors.cyan;
      case MarkerColor.yellow:
        return Colors.amber;
    }
  }
}

/// بيانات خط على الخريطة
class MapPolylineData {
  final String id;
  final List<MapLocation> points;
  final Color color;
  final double width;

  const MapPolylineData({
    required this.id,
    required this.points,
    this.color = Colors.blue,
    this.width = 4,
  });

  gmaps.Polyline toGooglePolyline() {
    return gmaps.Polyline(
      polylineId: gmaps.PolylineId(id),
      points: points.map((p) => p.toGoogleLatLng()).toList(),
      color: color,
      width: width.toInt(),
    );
  }

  fmap.Polyline toFlutterMapPolyline() {
    return fmap.Polyline(
      points: points.map((p) => p.toFlutterMapLatLng()).toList(),
      color: color,
      strokeWidth: width,
    );
  }
}
