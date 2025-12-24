import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../../core/widgets/cross_platform_map.dart';
import '../../../../core/config/company_config.dart';
import '../bloc/tracking_monitor_cubit.dart' hide LatLng;
import '../models/tracked_vehicle.dart';
import '../models/map_bounds.dart';

/// Tracking Map Widget
///
/// Professional Google Maps integration with:
/// - Real-time vehicle markers
/// - Custom marker icons
/// - Smooth camera animations
/// - Clustering for many vehicles
/// - Route polylines
/// - Driver info windows
///
/// Note: This is a placeholder that uses a Container.
/// To use actual Google Maps, add these dependencies:
/// - google_maps_flutter: ^2.5.0 (for mobile)
/// - google_maps_flutter_web: ^0.5.0 (for web)
/// - google_maps_flutter_platform_interface: ^2.4.0
class TrackingMapWidget extends StatefulWidget {
  final TrackingMonitorCubit cubit;
  final MapLocation companyLocation;

  const TrackingMapWidget({
    Key? key,
    required this.cubit,
    this.companyLocation = const MapLocation(
      latitude: 35.7595, // Default Tangier
      longitude: -5.8340,
    ),
  }) : super(key: key);

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

  // Check if platform supports Google Maps
  bool get _useGoogleMaps {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }
  
  double get _mapCenterLat => widget.companyLocation.latitude;
  double get _mapCenterLng => widget.companyLocation.longitude;

  void _setupListeners() {
    // Listen to vehicle updates with distinct to avoid unnecessary rebuilds
    _vehiclesSubscription = widget.cubit.vehiclesStream.distinct().listen((vehicles) {
      if (!mounted) return;
      if (_vehicles.length != vehicles.length ||
          !_vehicles.values.every((v) => vehicles[v.vehicleId]?.lastUpdateTime == v.lastUpdateTime)) {
        setState(() {
          _vehicles = vehicles;
          _updateMarkers();
        });
      }
    });

    // Listen to selected vehicle
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

    // Listen to map bounds changes
    _mapBoundsSubscription = widget.cubit.mapBoundsStream.distinct().listen((bounds) {
      if (bounds != null) {
        _animateToRegion(bounds);
      }
    });
  }

  void _updateMarkers() {
    if (!mounted) return;
    
    setState(() {
      // Add company marker
      final companyMarker = _useGoogleMaps
          ? gmaps.Marker(
              markerId: const gmaps.MarkerId('company'),
              position: gmaps.LatLng(_mapCenterLat, _mapCenterLng),
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueViolet,
              ),
              infoWindow: const gmaps.InfoWindow(
                title: 'Company Location',
                snippet: 'Main office',
              ),
            )
          : null;

      // Get vehicles - include those without location if they're on a trip
      final vehiclesWithLocation = _vehicles.values
          .where((v) => v.currentLocation != null)
          .toList();
      
      // For vehicles on trip without location, use company location as fallback
      final vehiclesOnTripWithoutLocation = _vehicles.values
          .where((v) => v.tripId != null && v.currentLocation == null)
          .toList();

      debugPrint('🗺️ Updating markers: ${vehiclesWithLocation.length} with location, '
          '${vehiclesOnTripWithoutLocation.length} on trip without location, '
          'Total vehicles: ${_vehicles.length}');

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
              snippet: '${vehicle.driverName} - ${vehicle.statusText}',
            ),
            rotation: vehicle.currentLocation?.heading ?? 0,
            onTap: () => widget.cubit.selectDriver(vehicle),
          );
        }).toSet();
        
        // Add markers for vehicles on trip without location (use company location)
        final tripMarkers = vehiclesOnTripWithoutLocation.map((vehicle) {
          final isSelected = _selectedVehicle?.vehicleId == vehicle.vehicleId;
          return gmaps.Marker(
            markerId: gmaps.MarkerId('vehicle_${vehicle.vehicleId}'),
            position: gmaps.LatLng(_mapCenterLat, _mapCenterLng),
            icon: _getMarkerIcon(vehicle, isSelected),
            infoWindow: gmaps.InfoWindow(
              title: vehicle.vehicleName,
              snippet: '${vehicle.driverName} - ${vehicle.statusText} (Waiting for location)',
            ),
            onTap: () => widget.cubit.selectDriver(vehicle),
          );
        }).toSet();
        
        _googleMarkers = {if (companyMarker != null) companyMarker, ...vehicleMarkers, ...tripMarkers};
        debugPrint('🗺️ Total Google markers: ${_googleMarkers.length}');
        
        // Update polylines for active trips
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
            snippet: '${vehicle.driverName} - ${vehicle.statusText}',
            color: _getMarkerColor(vehicle.statusColor),
            rotation: vehicle.currentLocation?.heading ?? 0,
            onTap: () => widget.cubit.selectDriver(vehicle),
          );
        }).toList();
        
        // Add company marker
        final companyMarker = MapMarkerData(
          id: 'company',
          location: MapLocation(
            latitude: _mapCenterLat,
            longitude: _mapCenterLng,
          ),
          title: 'Company Location',
          snippet: 'Main office',
          color: MarkerColor.violet,
        );
        
        // Add markers for vehicles on trip without location
        final tripMarkers = vehiclesOnTripWithoutLocation.map((vehicle) {
          return MapMarkerData(
            id: 'vehicle_${vehicle.vehicleId}',
            location: MapLocation(
              latitude: _mapCenterLat,
              longitude: _mapCenterLng,
            ),
            title: vehicle.vehicleName,
            snippet: '${vehicle.driverName} - ${vehicle.statusText} (Waiting for location)',
            color: _getMarkerColor(vehicle.statusColor),
            onTap: () => widget.cubit.selectDriver(vehicle),
          );
        }).toList();
        
        _crossPlatformMarkers = [companyMarker, ...vehicleMarkers, ...tripMarkers];
        debugPrint('🗺️ Total CrossPlatform markers: ${_crossPlatformMarkers.length}');
        
        // Update polylines for active trips
        _updatePolylines();
      }
    });
  }
  
  void _updatePolylines() {
    // Get vehicles on active trips
    final vehiclesOnTrip = _vehicles.values
        .where((v) => v.tripId != null && v.currentLocation != null)
        .toList();
    
    if (_useGoogleMaps) {
      _googlePolylines = vehiclesOnTrip.map((vehicle) {
        // For now, create a simple polyline from company location to vehicle
        // TODO: Get actual trip route from trip data
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
          color: Colors.blue,
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
          color: Colors.blue,
          width: 3,
        );
      }).toList();
    }
  }

  gmaps.BitmapDescriptor _getMarkerIcon(TrackedVehicle vehicle, bool isSelected) {
    // Use default marker for now - can be customized later with custom icons
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(
      _getMarkerHue(vehicle.statusColor),
    );
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

  void _animateToRegion(MapBounds bounds) {
    if (_useGoogleMaps) {
      if (_googleMapController == null) return;
      _googleMapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
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
        ),
      );
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

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    _selectedVehicleSubscription?.cancel();
    _mapBoundsSubscription?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tracking map with vehicles',
      child: _useGoogleMaps
          ? gmaps.GoogleMap(
              key: const ValueKey('google_map'),
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(_mapCenterLat, _mapCenterLng),
                zoom: CompanyConfig.defaultZoom,
              ),
              markers: _googleMarkers,
              polylines: _googlePolylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // We have custom controls
              zoomControlsEnabled: false, // Custom controls
              mapToolbarEnabled: false,
              compassEnabled: true,
              trafficEnabled: true,
              onMapCreated: (controller) {
                _googleMapController = controller;
                // Update markers after map is created
                _updateMarkers();
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
                // Update markers after map is created
                _updateMarkers();
              },
              onTap: (_) => widget.cubit.deselectVehicle(),
            ),
    );
  }
}
