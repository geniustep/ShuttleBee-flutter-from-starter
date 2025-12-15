import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bridgecore_integration/client/bridgecore_client.dart';
import '../utils/logger.dart';

/// GPS Tracking Service - خدمة تتبع GPS للسائق
/// ترسل موقع السائق للخادم بشكل دوري أثناء الرحلة
class GpsTrackingService {
  static final GpsTrackingService _instance = GpsTrackingService._internal();
  factory GpsTrackingService() => _instance;
  GpsTrackingService._internal();

  static const String _tripModel = 'shuttle.trip';
  static const String _gpsPositionModel = 'shuttle.gps.position';

  BridgecoreClient? _client;
  int? _activeTripId;
  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  bool _isTracking = false;

  /// التحقق من حالة التتبع
  bool get isTracking => _isTracking;

  /// الرحلة النشطة
  int? get activeTripId => _activeTripId;

  /// آخر موقع مسجل
  Position? get lastPosition => _lastPosition;

  /// تهيئة الخدمة
  void initialize(BridgecoreClient client) {
    _client = client;
    AppLogger.info('🛰️ [GpsTrackingService] Initialized');
  }

  /// بدء تتبع الموقع لرحلة معينة
  Future<bool> startTracking(int tripId) async {
    if (_isTracking) {
      AppLogger.warning(
          '🛰️ [GpsTrackingService] Already tracking trip $_activeTripId');
      return false;
    }

    if (_client == null) {
      AppLogger.error('🛰️ [GpsTrackingService] Client not initialized');
      return false;
    }

    // التحقق من صلاحيات الموقع
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      AppLogger.error('🛰️ [GpsTrackingService] Location permission denied');
      return false;
    }

    _activeTripId = tripId;
    _isTracking = true;

    // بدء الاستماع لتحديثات الموقع
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // تحديث كل 10 متر
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        AppLogger.error(
            '🛰️ [GpsTrackingService] Position stream error: $error');
      },
    );

    // إرسال الموقع كل 30 ثانية كحد أدنى
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendLastPosition(),
    );

    AppLogger.info('🛰️ [GpsTrackingService] Started tracking trip $tripId');
    return true;
  }

  /// إيقاف تتبع الموقع
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _trackingTimer?.cancel();
    _trackingTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    // إرسال آخر موقع قبل الإيقاف
    await _sendLastPosition();

    final tripId = _activeTripId;
    _activeTripId = null;
    _isTracking = false;
    _lastPosition = null;

    AppLogger.info('🛰️ [GpsTrackingService] Stopped tracking trip $tripId');
  }

  /// معالجة تحديث الموقع
  void _onPositionUpdate(Position position) {
    _lastPosition = position;

    // إرسال فوري إذا تغير الموقع بشكل كبير
    if (_shouldSendImmediately(position)) {
      _sendPosition(position);
    }
  }

  /// التحقق من ضرورة الإرسال الفوري
  bool _shouldSendImmediately(Position position) {
    // إرسال فوري إذا السرعة عالية أو تغير الاتجاه بشكل كبير
    return position.speed > 10; // أكثر من 36 كم/ساعة
  }

  /// إرسال آخر موقع مسجل
  Future<void> _sendLastPosition() async {
    if (_lastPosition != null) {
      await _sendPosition(_lastPosition!);
    }
  }

  /// إرسال الموقع للخادم
  Future<void> _sendPosition(Position position) async {
    if (_client == null || _activeTripId == null) return;

    try {
      // استخدام الطريقة المخصصة في Odoo
      await _client!.callKw(
        model: _tripModel,
        method: 'register_gps_position',
        args: [
          _activeTripId,
          position.latitude,
          position.longitude,
        ],
        kwargs: {
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.debug(
        '🛰️ [GpsTrackingService] Position sent: '
        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} '
        'speed: ${position.speed.toStringAsFixed(1)} m/s',
      );
    } catch (e) {
      AppLogger.error('🛰️ [GpsTrackingService] Failed to send position: $e');
      // محاولة الإرسال المباشر للجدول
      await _sendPositionDirect(position);
    }
  }

  /// إرسال الموقع مباشرة لجدول GPS
  Future<void> _sendPositionDirect(Position position) async {
    if (_client == null || _activeTripId == null) return;

    try {
      await _client!.create(
        model: _gpsPositionModel,
        values: {
          'trip_id': _activeTripId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error(
          '🛰️ [GpsTrackingService] Direct position save failed: $e');
    }
  }

  /// التحقق من صلاحيات الموقع
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// الحصول على الموقع الحالي
  Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// تحديث حالة الرحلة (الطقس/المرور)
  Future<bool> updateTripConditions({
    required int tripId,
    String? weatherStatus,
    String? trafficStatus,
    String? riskLevel,
  }) async {
    if (_client == null) return false;

    try {
      await _client!.callKw(
        model: _tripModel,
        method: 'update_trip_conditions',
        args: [tripId],
        kwargs: {
          if (weatherStatus != null) 'weather_status': weatherStatus,
          if (trafficStatus != null) 'traffic_status': trafficStatus,
          if (riskLevel != null) 'risk_level': riskLevel,
        },
      );

      AppLogger.info('🛰️ [GpsTrackingService] Trip conditions updated');
      return true;
    } catch (e) {
      AppLogger.error(
          '🛰️ [GpsTrackingService] Failed to update conditions: $e');
      return false;
    }
  }

  /// تنظيف الموارد
  void dispose() {
    stopTracking();
    _client = null;
  }
}

/// حالة الطقس
enum WeatherStatus {
  clear('clear', 'صافي', '☀️'),
  rain('rain', 'مطر', '🌧️'),
  storm('storm', 'عاصفة', '⛈️'),
  fog('fog', 'ضباب', '🌫️'),
  snow('snow', 'ثلج', '❄️'),
  unknown('unknown', 'غير معروف', '❓');

  final String value;
  final String arabicLabel;
  final String icon;

  const WeatherStatus(this.value, this.arabicLabel, this.icon);

  static WeatherStatus fromString(String value) {
    return WeatherStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WeatherStatus.unknown,
    );
  }
}

/// حالة المرور
enum TrafficStatus {
  normal('normal', 'طبيعي', '🟢'),
  heavy('heavy', 'مزدحم', '🟡'),
  jam('jam', 'ازدحام شديد', '🔴'),
  accident('accident', 'حادث', '⚠️'),
  unknown('unknown', 'غير معروف', '❓');

  final String value;
  final String arabicLabel;
  final String icon;

  const TrafficStatus(this.value, this.arabicLabel, this.icon);

  static TrafficStatus fromString(String value) {
    return TrafficStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TrafficStatus.unknown,
    );
  }
}

/// مستوى الخطورة
enum RiskLevel {
  low('low', 'منخفض', 0xFF10B981),
  medium('medium', 'متوسط', 0xFFF59E0B),
  high('high', 'عالي', 0xFFEF4444);

  final String value;
  final String arabicLabel;
  final int colorValue;

  const RiskLevel(this.value, this.arabicLabel, this.colorValue);

  static RiskLevel fromString(String value) {
    return RiskLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RiskLevel.low,
    );
  }
}
