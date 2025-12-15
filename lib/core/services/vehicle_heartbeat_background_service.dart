import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../config/env_config.dart';
import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../storage/prefs_service.dart';
import '../storage/secure_storage_service.dart';

/// Android foreground-service heartbeat to report vehicle location even when the app is backgrounded.
///
/// Notes:
/// - This is "true background" on Android via a foreground service + notification.
/// - Requires location permissions (including background on Android 10+).
class VehicleHeartbeatBackgroundService {
  VehicleHeartbeatBackgroundService._();

  static const String _channelId = 'shuttlebee_heartbeat';
  static const int _serviceId = 1337;

  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: 'ShuttleBee Heartbeat',
        channelDescription:
            'Vehicle position heartbeat while app is in background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // 60s
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> start() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final running = await FlutterForegroundTask.isRunningService;
    if (running) return true;

    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'ShuttleBee يعمل بالخلفية',
      notificationText: 'إرسال موقع المركبة للأمان',
      callback: startCallback,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<bool> stop() async {
    final running = await FlutterForegroundTask.isRunningService;
    if (!running) return true;
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }

  /// Entrypoint called by the native foreground service.
  @pragma('vm:entry-point')
  static void startCallback() {
    FlutterForegroundTask.setTaskHandler(_VehicleHeartbeatTaskHandler());
  }
}

class _VehicleHeartbeatTaskHandler extends TaskHandler {
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Also run immediately on start.
    await _sendHeartbeat();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _timer ??= Timer(const Duration(seconds: 1), () async {
      _timer?.cancel();
      _timer = null;
      await _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    try {
      final prefs = PrefsService();
      final vehicleId = prefs.getInt(StorageKeys.lastVehicleId);
      if (vehicleId == null || vehicleId == 0) return;

      final sessionId =
          await SecureStorageService().read(StorageKeys.shuttleBeeSessionId);
      if (sessionId == null || sessionId.isEmpty) return;

      // Location permission check (best-effort).
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final dio = Dio(
        BaseOptions(
          // Heartbeat uses ShuttleBee REST API endpoints.
          baseUrl: EnvConfig.shuttleBeeApiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            ApiConstants.headerContentType: ApiConstants.contentTypeJson,
            ApiConstants.headerAccept: ApiConstants.contentTypeJson,
            ApiConstants.headerCookie: 'session_id=$sessionId',
          },
        ),
      );

      await dio.post(
        '/api/v1/shuttle/vehicle/position',
        data: {
          'vehicle_id': vehicleId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        },
      );
    } catch (_) {
      // Best-effort. Ignore failures.
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _timer?.cancel();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
