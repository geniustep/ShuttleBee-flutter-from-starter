import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart' as ll;

/// 🗺️ Map Tile Cache Service - خدمة تخزين tiles الخريطة للاستخدام offline
///
/// تستخدم flutter_map_tile_caching (FMTC) لتحميل وتخزين tiles الخريطة
class MapTileCacheService {
  static const String _storeName = 'shuttlebee_map_store';
  static bool _isInitialized = false;

  /// تهيئة FMTC
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // FMTC يعمل فقط على المنصات غير الويب
    if (kIsWeb) {
      debugPrint('⚠️ FMTC غير مدعوم على الويب');
      return;
    }

    try {
      // تهيئة الـ backend
      await FMTCObjectBoxBackend().initialise();

      // إنشاء الـ store إذا لم يكن موجوداً
      final store = const FMTCStore(_storeName);
      final stats = await store.stats.all;

      if (stats.length == 0) {
        await store.manage.create();
        debugPrint('✅ تم إنشاء store جديد للخريطة');
      } else {
        debugPrint(
          '✅ FMTC جاهز - ${stats.length} tiles مخزنة, '
          '${(stats.size / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة FMTC: $e');
    }
  }

  /// التحقق من حالة التهيئة
  static bool get isInitialized => _isInitialized;

  /// الحصول على الـ store
  static FMTCStore get store => const FMTCStore(_storeName);

  /// الحصول على TileProvider للخريطة
  static FMTCTileProvider? getTileProvider() {
    if (!_isInitialized || kIsWeb) return null;

    return FMTCTileProvider(
      stores: {_storeName: BrowseStoreStrategy.read},
    );
  }

  /// الحصول على إحصائيات الـ cache
  static Future<MapCacheStats?> getStats() async {
    if (!_isInitialized) return null;

    try {
      final stats = await store.stats.all;

      return MapCacheStats(
        tileCount: stats.length,
        sizeInMB: stats.size / 1024 / 1024,
      );
    } catch (e) {
      debugPrint('خطأ في جلب إحصائيات الـ cache: $e');
      return null;
    }
  }

  /// تحميل منطقة للاستخدام offline
  static Future<void> downloadRegion({
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
    int minZoom = 10,
    int maxZoom = 16,
    String urlTemplate =
        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    void Function(DownloadProgress)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('FMTC غير مهيأ');
    }

    final southWest = ll.LatLng(southWestLat, southWestLng);
    final northEast = ll.LatLng(northEastLat, northEastLng);
    final bounds = fmap.LatLngBounds(southWest, northEast);
    final region = RectangleRegion(bounds);

    final downloadableRegion = region.toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: fmap.TileLayer(urlTemplate: urlTemplate),
    );

    // حساب عدد الـ tiles المتوقعة
    final tilesCount = await store.download.countTiles(downloadableRegion);

    debugPrint('📥 بدء تحميل $tilesCount tile...');

    final instanceId = DateTime.now().millisecondsSinceEpoch;

    final downloadResult = store.download.startForeground(
      region: downloadableRegion,
      instanceId: instanceId,
    );

    // الاستماع لتقدم التحميل
    await for (final progress in downloadResult.downloadProgress) {
      onProgress?.call(progress);

      if (progress.percentageProgress >= 100) {
        debugPrint('✅ تم تحميل tiles بنجاح');
        break;
      }
    }
  }

  /// تحميل منطقة حول موقع معين
  static Future<void> downloadAroundLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int minZoom = 10,
    int maxZoom = 16,
    void Function(DownloadProgress)? onProgress,
  }) async {
    // حساب حدود المنطقة بناءً على نصف القطر
    // 1 درجة ≈ 111 كم عند خط الاستواء
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * _cosine(latitude));

    await downloadRegion(
      southWestLat: latitude - latDelta,
      southWestLng: longitude - lngDelta,
      northEastLat: latitude + latDelta,
      northEastLng: longitude + lngDelta,
      minZoom: minZoom,
      maxZoom: maxZoom,
      onProgress: onProgress,
    );
  }

  static double _cosine(double degrees) {
    return math.cos(degrees * math.pi / 180.0);
  }

  /// مسح الـ cache
  static Future<void> clearCache() async {
    if (!_isInitialized) return;

    try {
      await store.manage.reset();
      debugPrint('🗑️ تم مسح cache الخريطة');
    } catch (e) {
      debugPrint('خطأ في مسح الـ cache: $e');
    }
  }

  /// إلغاء التحميل الجاري
  static Future<void> cancelDownload(int instanceId) async {
    if (!_isInitialized) return;

    try {
      await store.download.cancel(instanceId: instanceId);
      debugPrint('⏹️ تم إلغاء التحميل');
    } catch (e) {
      debugPrint('خطأ في إلغاء التحميل: $e');
    }
  }
}

/// إحصائيات الـ cache
class MapCacheStats {
  final int tileCount;
  final double sizeInMB;

  const MapCacheStats({
    required this.tileCount,
    required this.sizeInMB,
  });

  String get formattedSize => '${sizeInMB.toStringAsFixed(2)} MB';
}
