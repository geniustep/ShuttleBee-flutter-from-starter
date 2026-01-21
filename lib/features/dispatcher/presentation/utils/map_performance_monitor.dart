import 'dart:async';

/// 📊 Map Performance Monitor - مراقب أداء الخريطة
/// 
/// يتتبع أداء تحديثات الخريطة ويوفر إحصائيات مفيدة
class MapPerformanceMonitor {
  int _markerUpdateCount = 0;
  int _cameraUpdateCount = 0;
  int _polylineUpdateCount = 0;
  DateTime? _lastMarkerUpdateTime;
  DateTime? _lastCameraUpdateTime;
  DateTime? _lastPolylineUpdateTime;
  
  final List<Duration> _markerUpdateDurations = [];
  final List<Duration> _cameraUpdateDurations = [];
  
  /// تسجيل تحديث العلامات
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
  
  /// تسجيل تحديث الكاميرا
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
  
  /// تسجيل تحديث Polylines
  void recordPolylineUpdate() {
    _polylineUpdateCount++;
    _lastPolylineUpdateTime = DateTime.now();
  }
  
  /// الحصول على الإحصائيات
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
  
  /// إعادة تعيين الإحصائيات
  void reset() {
    _markerUpdateCount = 0;
    _cameraUpdateCount = 0;
    _polylineUpdateCount = 0;
    _markerUpdateDurations.clear();
    _cameraUpdateDurations.clear();
  }
}

