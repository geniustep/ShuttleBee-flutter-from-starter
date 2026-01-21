import 'dart:async';
import 'package:flutter/material.dart';

import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import '../models/tracked_vehicle.dart';
import '../models/map_bounds.dart';
import '../../../vehicles/data/datasources/vehicle_remote_data_source.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../shuttlebee/data/services/shuttlebee_api_service.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/config/company_config.dart';
import '../../../../core/widgets/cross_platform_map.dart';

/// Cubit for managing tracking monitor state
///
/// Handles:
/// - Vehicle position updates
/// - Driver selection and filtering
/// - Map camera control
/// - Location requests
/// - Connection state
/// - Loading vehicles from server
/// - Loading active trips for accurate status
class TrackingMonitorCubit {
  final LiveTrackingService trackingService;
  final VehicleRemoteDataSource? vehicleDataSource;
  final ShuttleBeeApiService? shuttleBeeApiService;
  final int? companyId;

  // State streams
  final _vehiclesController =
      StreamController<Map<int, TrackedVehicle>>.broadcast();
  final _selectedVehicleController =
      StreamController<TrackedVehicle?>.broadcast();
  final _mapBoundsController = StreamController<MapBounds?>.broadcast();
  final _activeVehiclesCountController = StreamController<int>.broadcast();
  final _onlineVehiclesCountController = StreamController<int>.broadcast();
  final _filterController = StreamController<VehicleFilter>.broadcast();
  final _companyLocationController = StreamController<MapLocation>.broadcast();

  // Current state
  final Map<int, TrackedVehicle> _vehicles = {};
  TrackedVehicle? _selectedVehicle;
  VehicleFilter _filter = VehicleFilter.all;
  
  // Active trips cache (vehicleId -> tripId)
  final Map<int, int> _activeTripsMap = {};
  
  // Company location from server
  MapLocation _companyLocation = CompanyConfig.defaultLocation;
  String _companyName = CompanyConfig.companyName;

  // Getters
  Stream<Map<int, TrackedVehicle>> get vehiclesStream =>
      _vehiclesController.stream;
  Stream<TrackedVehicle?> get selectedVehicleStream =>
      _selectedVehicleController.stream;
  Stream<MapBounds?> get mapBoundsStream => _mapBoundsController.stream;
  Stream<int> get activeVehiclesCountStream =>
      _activeVehiclesCountController.stream;
  Stream<int> get onlineVehiclesCountStream =>
      _onlineVehiclesCountController.stream;
  Stream<VehicleFilter> get filterStream => _filterController.stream;
  Stream<MapLocation> get companyLocationStream => _companyLocationController.stream;

  Map<int, TrackedVehicle> get vehicles => Map.unmodifiable(_vehicles);
  TrackedVehicle? get selectedVehicle => _selectedVehicle;
  VehicleFilter get currentFilter => _filter;
  MapLocation get companyLocation => _companyLocation;
  String get companyName => _companyName;

  TrackingMonitorCubit({
    required this.trackingService,
    this.vehicleDataSource,
    this.shuttleBeeApiService,
    this.companyId,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Load Company Location from Server
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load company location from server based on companyId
  Future<void> loadCompanyLocation() async {
    if (companyId == null) {
      debugPrint('⚠️ No companyId provided, using default location');
      return;
    }

    try {
      debugPrint('🏢 Loading company location for company ID: $companyId...');
      
      final result = await BridgeCore.instance.odoo.searchRead(
        model: 'res.company',
        domain: [['id', '=', companyId]],
        fields: ['id', 'name', 'shuttle_latitude', 'shuttle_longitude'],
        limit: 1,
      );
      
      if (result.isEmpty) {
        debugPrint('⚠️ Company not found, using default location');
        return;
      }
      
      final company = result.first;
      final lat = company['shuttle_latitude'];
      final lng = company['shuttle_longitude'];
      final name = company['name'];
      
      // التحقق من صلاحية الإحداثيات
      if (lat != null && lat != false && lng != null && lng != false) {
        final latitude = (lat is num) ? lat.toDouble() : double.tryParse(lat.toString());
        final longitude = (lng is num) ? lng.toDouble() : double.tryParse(lng.toString());
        
        if (latitude != null && longitude != null) {
          _companyLocation = MapLocation(latitude: latitude, longitude: longitude);
          _companyName = name?.toString() ?? CompanyConfig.companyName;
          _companyLocationController.add(_companyLocation);
          
          debugPrint('✅ Company location loaded: $_companyName at ($latitude, $longitude)');
          return;
        }
      }
      
      debugPrint('⚠️ Invalid company coordinates, using default location');
    } catch (e) {
      debugPrint('❌ Error loading company location: $e');
      // استمر باستخدام الموقع الافتراضي
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Load Vehicles from Server
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load vehicles from server and initialize tracking
  Future<void> loadVehiclesFromServer() async {
    if (vehicleDataSource == null) {
      debugPrint(
        '⚠️ VehicleRemoteDataSource not provided, skipping server load',
      );
      return;
    }

    try {
      debugPrint('🔄 Loading vehicles from server...');
      
      // أولاً: تحميل موقع الشركة
      await loadCompanyLocation();
      
      // ثانياً: تحميل الرحلات النشطة للحصول على الحالة الصحيحة
      await _loadActiveTrips();
      
      final vehicles = await vehicleDataSource!.getVehicles(activeOnly: true);
      debugPrint('✅ Received ${vehicles.length} vehicles from server');

      if (vehicles.isEmpty) {
        debugPrint('⚠️ No vehicles returned from server');
        return;
      }

      for (final vehicle in vehicles) {
        // Convert ShuttleVehicle to TrackedVehicle with accurate trip status
        final trackedVehicle = _convertToTrackedVehicle(vehicle);
        debugPrint(
          '📦 Vehicle: ${trackedVehicle.vehicleName} (ID: ${trackedVehicle.vehicleId}), '
          'Driver: ${trackedVehicle.driverName}, Online: ${trackedVehicle.isOnline}, '
          'Trip: ${trackedVehicle.tripId}, Status: ${trackedVehicle.statusText}',
        );

        // Always update/add vehicle from server
        _vehicles[trackedVehicle.vehicleId] = trackedVehicle;
      }

      debugPrint('✅ Added ${_vehicles.length} vehicles to tracking');
      _notifyVehiclesChanged();
      debugPrint(
        '✅ Notified listeners: ${_vehicles.length} vehicles available',
      );

      // Force emit initial values to ensure UI updates
      final onlineCount = _vehicles.values.where((v) => v.isOnline).length;
      final activeCount = _vehicles.values
          .where((v) => v.tripId != null)
          .length;
      _activeVehiclesCountController.add(activeCount);
      _onlineVehiclesCountController.add(onlineCount);
      debugPrint(
        '📊 Force emitted counts: Active (on trip)=$activeCount, Online=$onlineCount',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading vehicles from server: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Load active trips to determine which vehicles are actually on a trip
  Future<void> _loadActiveTrips() async {
    _activeTripsMap.clear();
    
    if (shuttleBeeApiService == null) {
      debugPrint('⚠️ ShuttleBeeApiService not provided, skipping active trips load');
      return;
    }

    try {
      debugPrint('🔄 Loading active trips...');
      final activeTrips = await shuttleBeeApiService!.getLiveOngoingTrips();
      debugPrint('✅ Received ${activeTrips.length} active trips');
      
      for (final trip in activeTrips) {
        if (trip.vehicleId != null && trip.state == TripState.ongoing) {
          _activeTripsMap[trip.vehicleId!] = trip.id;
          debugPrint(
            '🚗 Vehicle ${trip.vehicleId} is on active trip ${trip.id} '
            '(${trip.name})',
          );
        }
      }
      
      debugPrint('📊 Active trips map: ${_activeTripsMap.length} vehicles on trip');
    } on ShuttleBeeRestNotAvailable catch (e) {
      debugPrint('⚠️ ShuttleBee REST API not available: $e');
      // Fallback: سنستخدم بيانات المركبات فقط بدون حالة الرحلة
    } catch (e) {
      debugPrint('❌ Error loading active trips: $e');
      // لا نرمي الخطأ، نستمر بدون بيانات الرحلات
    }
  }

  /// Refresh active trips and update vehicle statuses
  Future<void> refreshActiveTrips() async {
    await _loadActiveTrips();
    
    // تحديث حالة المركبات بناءً على الرحلات النشطة
    for (final entry in _vehicles.entries) {
      final vehicleId = entry.key;
      final vehicle = entry.value;
      final activeTripId = _activeTripsMap[vehicleId];
      
      if (vehicle.tripId != activeTripId) {
        _vehicles[vehicleId] = vehicle.copyWith(
          tripId: activeTripId,
          driverStatus: activeTripId != null
              ? DriverStatus.online
              : (vehicle.isOnline ? DriverStatus.available : null),
        );
      }
    }
    
    _notifyVehiclesChanged();
  }

  /// Convert ShuttleVehicle to TrackedVehicle with accurate trip status
  TrackedVehicle _convertToTrackedVehicle(ShuttleVehicle vehicle) {
    // تحقق من وجود رحلة نشطة فعلية (من _activeTripsMap)
    final activeTripId = _activeTripsMap[vehicle.id];
    final hasActiveTrip = activeTripId != null;

    // Always mark active vehicles as online so they appear in the list
    // Real-time position updates will come via WebSocket
    final isOnline = vehicle.active;
    
    // استخدام موقع المركبة الافتراضي (home location) إذا كان متاحًا
    VehiclePosition? initialPosition;
    if (vehicle.homeLatitude != null && vehicle.homeLongitude != null) {
      initialPosition = VehiclePosition(
        id: 0, // ID مؤقت للموقع الابتدائي
        vehicleId: vehicle.id,
        latitude: vehicle.homeLatitude!,
        longitude: vehicle.homeLongitude!,
        timestamp: DateTime.now(),
        driverId: vehicle.driverId,
      );
      debugPrint(
        '📍 Using home location for vehicle ${vehicle.id}: '
        '(${vehicle.homeLatitude}, ${vehicle.homeLongitude})',
      );
    }

    return TrackedVehicle(
      vehicleId: vehicle.id,
      // استخدام tripId الفعلي من الرحلات النشطة
      tripId: activeTripId,
      driverId: vehicle.driverId ?? 0,
      driverName: vehicle.driverName ?? 'بدون سائق',
      vehicleName: vehicle.name,
      lastPosition: initialPosition, // استخدام موقع المنزل كموقع ابتدائي
      driverLocation: null,
      lastUpdateTime: DateTime.now(),
      // Mark as online if vehicle is active (so it appears in the list)
      isOnline: isOnline,
      driverStatus: isOnline && hasActiveTrip
          ? DriverStatus.online
          : (isOnline ? DriverStatus.available : null),
      licensePlate: vehicle.licensePlate,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Vehicle Position Updates
  // ═══════════════════════════════════════════════════════════════════════════

  void onVehiclePositionUpdate(VehiclePosition position) {
    final vehicleId = position.vehicleId;
    debugPrint(
      '📍 Vehicle position update: Vehicle ID=$vehicleId, '
      'Lat=${position.latitude}, Lng=${position.longitude}, '
      'Driver=${position.driverId}',
    );

    // Update or create tracked vehicle
    if (_vehicles.containsKey(vehicleId)) {
      _vehicles[vehicleId] = _vehicles[vehicleId]!.copyWith(
        lastPosition: position,
        lastUpdateTime: DateTime.now(),
        isOnline: true,
      );
      debugPrint('✅ Updated existing vehicle $vehicleId with position');
    } else {
      _vehicles[vehicleId] = TrackedVehicle(
        vehicleId: vehicleId,
        tripId: null, // Trip ID comes from trip update events
        driverId: position.driverId ?? 0,
        lastPosition: position,
        lastUpdateTime: DateTime.now(),
        isOnline: true,
        driverName: position.driverId != null
            ? 'Driver #${position.driverId}'
            : 'Unknown Driver', // TODO: Fetch from API
        vehicleName: 'Vehicle #$vehicleId',
      );
      debugPrint('✅ Created new vehicle $vehicleId with position');
    }

    _notifyVehiclesChanged();

    // If this is the selected vehicle, update selection
    if (_selectedVehicle?.vehicleId == vehicleId) {
      _selectedVehicle = _vehicles[vehicleId];
      _selectedVehicleController.add(_selectedVehicle);
    }
  }

  void onDriverLocationUpdate(DriverLocation location) {
    final driverId = location.driverId;

    // Find vehicle with this driver
    final vehicle = _vehicles.values.firstWhere(
      (v) => v.driverId == driverId,
      orElse: () => TrackedVehicle(
        vehicleId: -1,
        driverId: driverId,
        lastUpdateTime: DateTime.now(),
        isOnline: true,
        driverName: 'Driver #$driverId',
        vehicleName: 'Unknown Vehicle',
      ),
    );

    if (vehicle.vehicleId != -1) {
      // Update existing vehicle with driver location
      _vehicles[vehicle.vehicleId] = vehicle.copyWith(
        driverLocation: location,
        lastUpdateTime: DateTime.now(),
      );

      _notifyVehiclesChanged();

      if (_selectedVehicle?.vehicleId == vehicle.vehicleId) {
        _selectedVehicle = _vehicles[vehicle.vehicleId];
        _selectedVehicleController.add(_selectedVehicle);
      }
    }
  }

  void onDriverStatusUpdate(DriverStatusUpdate statusUpdate) {
    final vehicleId = statusUpdate.vehicleId;
    if (vehicleId == null) return;

    if (_vehicles.containsKey(vehicleId)) {
      _vehicles[vehicleId] = _vehicles[vehicleId]!.copyWith(
        driverStatus: statusUpdate.status,
        lastUpdateTime: DateTime.now(),
      );

      _notifyVehiclesChanged();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Vehicle Selection
  // ═══════════════════════════════════════════════════════════════════════════

  void selectDriver(TrackedVehicle vehicle) {
    _selectedVehicle = vehicle;
    _selectedVehicleController.add(_selectedVehicle);

    // Center map on selected vehicle
    if (vehicle.lastPosition != null) {
      final position = vehicle.lastPosition!;
      _mapBoundsController.add(
        MapBounds.fromSinglePoint(
          latitude: position.latitude,
          longitude: position.longitude,
          zoom: 15.0,
        ),
      );
    }
  }

  void deselectVehicle() {
    _selectedVehicle = null;
    _selectedVehicleController.add(null);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Location Requests
  // ═══════════════════════════════════════════════════════════════════════════

  Future<DriverLocation?> requestDriverLocation(int driverId) async {
    try {
      final location = await trackingService.requestDriverLocation(
        driverId: driverId,
        timeout: const Duration(seconds: 10),
      );

      if (location != null) {
        onDriverLocationUpdate(location);
      }

      return location;
    } catch (e) {
      debugPrint('Error requesting driver location: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtering
  // ═══════════════════════════════════════════════════════════════════════════

  void setFilter(VehicleFilter filter) {
    _filter = filter;
    _filterController.add(_filter);
    _notifyVehiclesChanged();
  }

  Map<int, TrackedVehicle> getFilteredVehicles() {
    switch (_filter) {
      case VehicleFilter.all:
        return _vehicles;

      case VehicleFilter.online:
        return Map.fromEntries(
          _vehicles.entries.where((entry) => entry.value.isOnline),
        );

      case VehicleFilter.offline:
        return Map.fromEntries(
          _vehicles.entries.where((entry) => !entry.value.isOnline),
        );

      case VehicleFilter.onTrip:
        return Map.fromEntries(
          _vehicles.entries.where((entry) => entry.value.tripId != null),
        );

      case VehicleFilter.available:
        return Map.fromEntries(
          _vehicles.entries.where(
            (entry) =>
                entry.value.tripId == null &&
                entry.value.driverStatus == DriverStatus.available,
          ),
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Map Controls
  // ═══════════════════════════════════════════════════════════════════════════

  void fitAllVehicles() {
    if (_vehicles.isEmpty) return;

    final positions = _vehicles.values
        .where((v) => v.lastPosition != null)
        .map((v) => v.lastPosition!)
        .toList();

    if (positions.isEmpty) return;

    // Calculate bounds
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    _mapBoundsController.add(
      MapBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
        padding: 50.0,
      ),
    );
  }

  void centerOnVehicle(int vehicleId) {
    final vehicle = _vehicles[vehicleId];
    if (vehicle?.lastPosition == null) return;

    final position = vehicle!.lastPosition!;
    _mapBoundsController.add(
      MapBounds.fromSinglePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        zoom: 16.0,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utility Methods
  // ═══════════════════════════════════════════════════════════════════════════

  void _notifyVehiclesChanged() {
    final vehiclesCount = _vehicles.length;
    final onlineCount = _vehicles.values.where((v) => v.isOnline).length;
    // Active vehicles = vehicles that are on a trip
    final activeCount = _vehicles.values.where((v) => v.tripId != null).length;
    debugPrint(
      '📊 Notifying vehicles changed: Total=$vehiclesCount, Online=$onlineCount, Active (on trip)=$activeCount, Filter=${_filter.name}',
    );

    _vehiclesController.add(Map.unmodifiable(_vehicles));
    // Active vehicles = vehicles on trip
    _activeVehiclesCountController.add(activeCount);
    // Online vehicles count
    _onlineVehiclesCountController.add(onlineCount);

    // Also log filtered vehicles count
    final filtered = getFilteredVehicles();
    debugPrint('📊 Filtered vehicles count: ${filtered.length}');
  }

  void clearOfflineVehicles() {
    _vehicles.removeWhere((_, vehicle) => !vehicle.isOnline);
    _notifyVehiclesChanged();
  }

  void dispose() {
    _vehiclesController.close();
    _selectedVehicleController.close();
    _mapBoundsController.close();
    _activeVehiclesCountController.close();
    _onlineVehiclesCountController.close();
    _filterController.close();
    _companyLocationController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════════════════

enum VehicleFilter { all, online, offline, onTrip, available }

// ═══════════════════════════════════════════════════════════════════════════
// Helper Classes
// ═══════════════════════════════════════════════════════════════════════════

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
