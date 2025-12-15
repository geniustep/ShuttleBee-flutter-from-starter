import 'dart:async';

import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/logger.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// Re-export models from bridgecore_flutter for convenience
export 'package:bridgecore_flutter/bridgecore_flutter.dart'
    show
        VehiclePosition,
        TripUpdate,
        DriverLocation,
        DriverStatus,
        LocationRequest,
        DriverStatusUpdate;

// ═══════════════════════════════════════════════════════════════════════════
// Live Tracking State
// ═══════════════════════════════════════════════════════════════════════════

/// حالة التتبع الحي
class LiveTrackingState {
  final bool isConnected;
  final bool isConnecting;
  final bool isAutoTracking;
  final int? activeTripId;
  final int? activeVehicleId;
  final String? error;
  final DateTime? lastPositionSent;

  const LiveTrackingState({
    this.isConnected = false,
    this.isConnecting = false,
    this.isAutoTracking = false,
    this.activeTripId,
    this.activeVehicleId,
    this.error,
    this.lastPositionSent,
  });

  LiveTrackingState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isAutoTracking,
    int? activeTripId,
    int? activeVehicleId,
    String? error,
    DateTime? lastPositionSent,
    bool clearActiveTripId = false,
    bool clearActiveVehicleId = false,
  }) {
    return LiveTrackingState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isAutoTracking: isAutoTracking ?? this.isAutoTracking,
      activeTripId:
          clearActiveTripId ? null : (activeTripId ?? this.activeTripId),
      activeVehicleId: clearActiveVehicleId
          ? null
          : (activeVehicleId ?? this.activeVehicleId),
      error: error,
      lastPositionSent: lastPositionSent ?? this.lastPositionSent,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Live Tracking Notifier (للسائق)
// ═══════════════════════════════════════════════════════════════════════════

/// مدير التتبع الحي للسائق
class LiveTrackingNotifier extends Notifier<LiveTrackingState> {
  LiveTrackingService get _tracking => BridgeCore.instance.liveTracking;

  Timer? _autoTrackingTimer;
  StreamSubscription<LocationRequest>? _locationRequestSub;
  StreamSubscription<TripUpdate>? _tripUpdateSub;
  StreamSubscription<bool>? _connectionStatusSub;

  @override
  LiveTrackingState build() {
    // Cleanup when disposed
    ref.onDispose(() {
      _stopAutoTracking();
      _locationRequestSub?.cancel();
      _tripUpdateSub?.cancel();
      _connectionStatusSub?.cancel();
    });

    // Setup listeners AFTER build completes to avoid modifying state during build
    Future.microtask(_setupListeners);

    return const LiveTrackingState();
  }

  /// إعداد المستمعين للأحداث
  void _setupListeners() {
    // تجنب إعادة الإعداد إذا كانت المستمعين موجودة
    if (_connectionStatusSub != null) return;

    // الاستماع لحالة الاتصال
    _connectionStatusSub = _tracking.connectionStatusStream.listen((connected) {
      state = state.copyWith(
        isConnected: connected,
        isConnecting: false,
      );
      AppLogger.info('📡 [LiveTracking] Connection status: $connected');
    });

    // الاستماع لطلبات الموقع من الـ Dispatcher
    _locationRequestSub =
        _tracking.locationRequestStream.listen(_handleLocationRequest);

    // الاستماع لتحديثات الرحلات
    _tripUpdateSub = _tracking.tripUpdateStream.listen(_handleTripUpdate);
  }

  /// الاتصال بـ WebSocket
  ///
  /// لا يُعيد throw الخطأ - يتم تخزينه في state.error
  /// ويتم إعادة المحاولة تلقائياً بواسطة الـ service
  Future<void> connect() async {
    final userId = ref.read(authStateProvider).asData?.value.user?.id;
    if (userId == null) {
      AppLogger.warning('📡 [LiveTracking] Cannot connect: No user ID');
      return;
    }

    if (state.isConnected || state.isConnecting) {
      AppLogger.debug('📡 [LiveTracking] Already connected or connecting');
      return;
    }

    state = state.copyWith(isConnecting: true, error: null);

    try {
      await _tracking.connect(userId: userId);
      _tracking.updateDriverStatus(status: DriverStatus.online);

      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
      );

      AppLogger.info('✅ [LiveTracking] Connected as driver $userId');
    } catch (e) {
      // تخزين الخطأ في الـ state بدون إعادة throw
      // الـ service سيحاول إعادة الاتصال تلقائياً
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        error: e.toString(),
      );
      AppLogger.warning(
        '⚠️ [LiveTracking] Connection failed (will retry automatically): $e',
      );
    }
  }

  /// قطع الاتصال
  void disconnect() {
    _stopAutoTracking();
    _tracking.updateDriverStatus(status: DriverStatus.offline);
    _tracking.disconnect();

    state = const LiveTrackingState();
    AppLogger.info('📡 [LiveTracking] Disconnected');
  }

  /// معالجة طلب الموقع من الـ Dispatcher
  Future<void> _handleLocationRequest(LocationRequest request) async {
    AppLogger.info(
      '📡 [LiveTracking] Received location request from ${request.requesterId}',
    );

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        AppLogger.warning('📡 [LiveTracking] Cannot get GPS position');
        return;
      }

      _tracking.sendLocationResponse(
        requestId: request.requestId,
        requesterId: request.requesterId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
        accuracy: position.accuracy,
      );

      AppLogger.info('📡 [LiveTracking] Sent location response');
    } catch (e) {
      AppLogger.error(
        '📡 [LiveTracking] Failed to respond to location request: $e',
      );
    }
  }

  /// معالجة تحديث حالة الرحلة
  void _handleTripUpdate(TripUpdate tripUpdate) {
    AppLogger.info(
      '📡 [LiveTracking] Trip update: ${tripUpdate.tripId} - ${tripUpdate.state}',
    );

    if (tripUpdate.isOngoing && !state.isAutoTracking) {
      // بدء التتبع التلقائي
      _startAutoTracking(
        tripId: tripUpdate.tripId,
        vehicleId: tripUpdate.vehicleId,
      );
    } else if (!tripUpdate.isOngoing && state.isAutoTracking) {
      // إيقاف التتبع التلقائي
      if (state.activeTripId == tripUpdate.tripId) {
        _stopAutoTracking();
      }
    }
  }

  /// بدء التتبع التلقائي للرحلة الجارية
  void _startAutoTracking({
    required int tripId,
    int? vehicleId,
  }) {
    if (state.isAutoTracking) {
      AppLogger.warning('📡 [LiveTracking] Already auto-tracking');
      return;
    }

    state = state.copyWith(
      isAutoTracking: true,
      activeTripId: tripId,
      activeVehicleId: vehicleId,
    );

    AppLogger.info('🟢 [LiveTracking] Started auto-tracking for trip $tripId');

    // إرسال الموقع فوراً
    _sendGpsToServer();

    // إرسال الموقع كل 10 ثواني
    _autoTrackingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _sendGpsToServer(),
    );
  }

  /// إيقاف التتبع التلقائي
  void _stopAutoTracking() {
    _autoTrackingTimer?.cancel();
    _autoTrackingTimer = null;

    final tripId = state.activeTripId;
    state = state.copyWith(
      isAutoTracking: false,
      clearActiveTripId: true,
      clearActiveVehicleId: true,
    );

    AppLogger.info('🔴 [LiveTracking] Stopped auto-tracking for trip $tripId');
  }

  /// بدء التتبع التلقائي يدوياً (للاستخدام من الشاشات)
  void startAutoTrackingManual({
    required int tripId,
    required int vehicleId,
  }) {
    _startAutoTracking(tripId: tripId, vehicleId: vehicleId);
  }

  /// إيقاف التتبع التلقائي يدوياً
  void stopAutoTrackingManual() {
    _stopAutoTracking();
  }

  /// إرسال GPS للخادم (عبر Odoo create)
  Future<void> _sendGpsToServer() async {
    final vehicleId = state.activeVehicleId;
    if (vehicleId == null) {
      AppLogger.warning('📡 [LiveTracking] No active vehicle ID');
      return;
    }

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        AppLogger.warning('📡 [LiveTracking] Cannot get GPS position');
        return;
      }

      // إرسال الموقع إلى Odoo عبر BridgeCore
      await BridgeCore.instance.odoo.create(
        model: 'shuttle.vehicle.position',
        values: {
          'vehicle_id': vehicleId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
        },
      );

      state = state.copyWith(lastPositionSent: DateTime.now());

      AppLogger.debug(
        '📍 [LiveTracking] GPS sent: ${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}',
      );
    } catch (e) {
      AppLogger.error('📡 [LiveTracking] Failed to send GPS: $e');
    }
  }

  /// الحصول على الموقع الحالي
  Future<Position?> _getCurrentPosition() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      AppLogger.error('📡 [LiveTracking] Error getting position: $e');
      return null;
    }
  }

  /// التحقق من صلاحيات الموقع
  Future<bool> _checkLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Dispatcher Live Tracking State & Notifier
// ═══════════════════════════════════════════════════════════════════════════

/// حالة التتبع للـ Dispatcher
class DispatcherLiveTrackingState {
  final bool isConnected;
  final bool isConnecting;
  final bool isSubscribed;
  final String? error;
  final List<VehiclePosition> vehiclePositions;
  final List<TripUpdate> tripUpdates;
  final Map<int, DriverLocation> driverLocations;

  const DispatcherLiveTrackingState({
    this.isConnected = false,
    this.isConnecting = false,
    this.isSubscribed = false,
    this.error,
    this.vehiclePositions = const [],
    this.tripUpdates = const [],
    this.driverLocations = const {},
  });

  DispatcherLiveTrackingState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isSubscribed,
    String? error,
    List<VehiclePosition>? vehiclePositions,
    List<TripUpdate>? tripUpdates,
    Map<int, DriverLocation>? driverLocations,
  }) {
    return DispatcherLiveTrackingState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      error: error,
      vehiclePositions: vehiclePositions ?? this.vehiclePositions,
      tripUpdates: tripUpdates ?? this.tripUpdates,
      driverLocations: driverLocations ?? this.driverLocations,
    );
  }
}

/// مدير التتبع الحي للـ Dispatcher
class DispatcherLiveTrackingNotifier
    extends Notifier<DispatcherLiveTrackingState> {
  LiveTrackingService get _tracking => BridgeCore.instance.liveTracking;

  StreamSubscription<VehiclePosition>? _vehiclePositionSub;
  StreamSubscription<TripUpdate>? _tripUpdateSub;
  StreamSubscription<DriverLocation>? _locationResponseSub;
  StreamSubscription<bool>? _connectionStatusSub;

  @override
  DispatcherLiveTrackingState build() {
    // Cleanup when disposed
    ref.onDispose(() {
      _vehiclePositionSub?.cancel();
      _tripUpdateSub?.cancel();
      _locationResponseSub?.cancel();
      _connectionStatusSub?.cancel();
    });

    // Setup listeners AFTER build completes to avoid modifying state during build
    Future.microtask(_setupListeners);

    return const DispatcherLiveTrackingState();
  }

  /// إعداد المستمعين
  void _setupListeners() {
    // تجنب إعادة الإعداد إذا كانت المستمعين موجودة
    if (_connectionStatusSub != null) return;

    // حالة الاتصال
    _connectionStatusSub = _tracking.connectionStatusStream.listen((connected) {
      state = state.copyWith(
        isConnected: connected,
        isConnecting: false,
      );
    });

    // مواقع المركبات
    _vehiclePositionSub = _tracking.vehiclePositionStream.listen((position) {
      final positions = List<VehiclePosition>.from(state.vehiclePositions);

      // تحديث أو إضافة الموقع
      final index =
          positions.indexWhere((p) => p.vehicleId == position.vehicleId);
      if (index >= 0) {
        positions[index] = position;
      } else {
        positions.add(position);
      }

      state = state.copyWith(vehiclePositions: positions);

      AppLogger.debug(
        '📍 [Dispatcher] Vehicle ${position.vehicleId} position update: '
        '${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}',
      );
    });

    // تحديثات الرحلات
    _tripUpdateSub = _tracking.tripUpdateStream.listen((tripUpdate) {
      final trips = List<TripUpdate>.from(state.tripUpdates);

      final index = trips.indexWhere((t) => t.tripId == tripUpdate.tripId);
      if (index >= 0) {
        trips[index] = tripUpdate;
      } else {
        trips.add(tripUpdate);
      }

      state = state.copyWith(tripUpdates: trips);

      AppLogger.debug(
        '🚌 [Dispatcher] Trip ${tripUpdate.tripId} update: ${tripUpdate.state}',
      );
    });

    // ردود طلبات الموقع
    _locationResponseSub = _tracking.locationResponseStream.listen((location) {
      final updated = Map<int, DriverLocation>.from(state.driverLocations);
      updated[location.driverId] = location;
      state = state.copyWith(driverLocations: updated);

      AppLogger.info(
        '📍 [Dispatcher] Received location from driver ${location.driverId}: '
        '${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}',
      );
    });
  }

  /// الاتصال والاشتراك في التتبع الحي
  ///
  /// لا يُعيد throw الخطأ - يتم تخزينه في state.error
  /// ويُعيد true إذا نجح الاتصال، false إذا فشل
  Future<bool> connectAndSubscribe() async {
    final userId = ref.read(authStateProvider).asData?.value.user?.id;
    if (userId == null) {
      AppLogger.warning('📡 [Dispatcher] Cannot connect: No user ID');
      return false;
    }

    if (state.isConnected) {
      if (!state.isSubscribed) {
        try {
          await _tracking.subscribeLiveTracking();
          state = state.copyWith(isSubscribed: true);
        } catch (e) {
          AppLogger.warning('⚠️ [Dispatcher] Subscribe failed: $e');
          return false;
        }
      }
      return true;
    }

    state = state.copyWith(isConnecting: true, error: null);

    try {
      await _tracking.connect(userId: userId);
      await _tracking.subscribeLiveTracking();

      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        isSubscribed: true,
      );

      AppLogger.info(
        '✅ [Dispatcher] Connected and subscribed to live tracking',
      );
      return true;
    } catch (e) {
      // تخزين الخطأ في الـ state بدون إعادة throw
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        error: e.toString(),
      );
      AppLogger.warning(
        '⚠️ [Dispatcher] Connection failed (will use polling fallback): $e',
      );
      return false;
    }
  }

  /// طلب موقع سائق معين
  Future<DriverLocation?> requestDriverLocation(int driverId) async {
    if (!state.isConnected) {
      AppLogger.warning(
        '📡 [Dispatcher] Cannot request location: Not connected',
      );
      return null;
    }

    try {
      final location = await _tracking.requestDriverLocation(
        driverId: driverId,
        timeout: const Duration(seconds: 15),
      );

      if (location != null) {
        // Ensure UI can render a marker immediately, even if the stream listener
        // is not attached yet for some reason.
        final updated = Map<int, DriverLocation>.from(state.driverLocations);
        updated[driverId] = location;
        state = state.copyWith(driverLocations: updated);

        AppLogger.info(
          '📍 [Dispatcher] Got location for driver $driverId: '
          '${location.latitude.toStringAsFixed(6)}, '
          '${location.longitude.toStringAsFixed(6)}',
        );
      } else {
        AppLogger.warning(
          '📡 [Dispatcher] Location request timed out for driver $driverId',
        );
      }

      return location;
    } catch (e) {
      AppLogger.error('📡 [Dispatcher] Failed to request driver location: $e');
      return null;
    }
  }

  /// الحصول على آخر موقع لمركبة معينة
  VehiclePosition? getVehiclePosition(int vehicleId) {
    try {
      return state.vehiclePositions.firstWhere((p) => p.vehicleId == vehicleId);
    } catch (_) {
      return null;
    }
  }

  /// قطع الاتصال
  void disconnect() {
    _tracking.disconnect();
    state = const DispatcherLiveTrackingState();
    AppLogger.info('📡 [Dispatcher] Disconnected');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Provider للتتبع الحي للسائق
final driverLiveTrackingProvider =
    NotifierProvider<LiveTrackingNotifier, LiveTrackingState>(
  LiveTrackingNotifier.new,
);

/// Provider للتتبع الحي للـ Dispatcher
final dispatcherLiveTrackingProvider = NotifierProvider<
    DispatcherLiveTrackingNotifier, DispatcherLiveTrackingState>(
  DispatcherLiveTrackingNotifier.new,
);

/// Stream لمواقع المركبات (للـ Dispatcher)
final vehiclePositionsStreamProvider = StreamProvider<VehiclePosition>((ref) {
  return BridgeCore.instance.liveTracking.vehiclePositionStream;
});

/// Stream لتحديثات الرحلات
final tripUpdatesStreamProvider = StreamProvider<TripUpdate>((ref) {
  return BridgeCore.instance.liveTracking.tripUpdateStream;
});

/// Stream لحالة الاتصال
final liveTrackingConnectionProvider = StreamProvider<bool>((ref) {
  return BridgeCore.instance.liveTracking.connectionStatusStream;
});
