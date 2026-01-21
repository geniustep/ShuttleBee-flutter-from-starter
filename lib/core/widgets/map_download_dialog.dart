import 'package:flutter/material.dart';

import '../config/company_config.dart';
import '../services/map_tile_cache_service.dart';
import '../theme/app_colors.dart';

/// 📥 Map Download Dialog - نافذة تحميل الخريطة للاستخدام offline
class MapDownloadDialog extends StatefulWidget {
  /// الموقع المركزي للتحميل (اختياري - يستخدم الموقع الافتراضي إذا لم يُحدد)
  final double? centerLatitude;
  final double? centerLongitude;

  /// نصف قطر التحميل بالكيلومتر (افتراضي: 10 كم)
  final double radiusKm;

  const MapDownloadDialog({
    super.key,
    this.centerLatitude,
    this.centerLongitude,
    this.radiusKm = 10.0,
  });

  /// عرض النافذة
  static Future<bool?> show(
    BuildContext context, {
    double? centerLatitude,
    double? centerLongitude,
    double radiusKm = 10.0,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MapDownloadDialog(
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
        radiusKm: radiusKm,
      ),
    );
  }

  @override
  State<MapDownloadDialog> createState() => _MapDownloadDialogState();
}

class _MapDownloadDialogState extends State<MapDownloadDialog> {
  bool _isDownloading = false;
  bool _isCompleted = false;
  String _statusMessage = '';
  double _progress = 0.0;
  MapCacheStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await MapTileCacheService.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  Future<void> _startDownload() async {
    if (!MapTileCacheService.isInitialized) {
      setState(() {
        _statusMessage = '❌ FMTC غير مهيأ';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = '🔄 جاري تحضير التحميل...';
    });

    try {
      final centerLat =
          widget.centerLatitude ?? CompanyConfig.defaultLocation.latitude;
      final centerLng =
          widget.centerLongitude ?? CompanyConfig.defaultLocation.longitude;

      await MapTileCacheService.downloadAroundLocation(
        latitude: centerLat,
        longitude: centerLng,
        radiusKm: widget.radiusKm,
        minZoom: 10,
        maxZoom: 16,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress.percentageProgress / 100;
              _statusMessage =
                  '📥 تقدم التحميل: ${progress.percentageProgress.toStringAsFixed(1)}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isCompleted = true;
          _isDownloading = false;
          _statusMessage = '✅ تم تحميل الخريطة بنجاح!';
        });
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = '❌ خطأ: $e';
        });
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'مسح الخريطة المحفوظة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل أنت متأكد من حذف جميع بيانات الخريطة المحفوظة؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await MapTileCacheService.clearCache();
      await _loadStats();
      if (mounted) {
        setState(() {
          _statusMessage = '🗑️ تم مسح الخريطة المحفوظة';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _isCompleted ? Icons.check_circle : Icons.download_rounded,
            color: _isCompleted ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'تحميل الخريطة Offline',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إحصائيات الـ Cache
          if (_stats != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storage_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_stats!.tileCount} tile محفوظة (${_stats!.formattedSize})',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isDownloading ? null : _clearCache,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.error,
                    tooltip: 'مسح الخريطة المحفوظة',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // معلومات التحميل
          Text(
            'سيتم تحميل خريطة بنصف قطر ${widget.radiusKm.toInt()} كم '
            'حول الموقع المحدد للاستخدام بدون انترنت.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          if (_isDownloading || _isCompleted) ...[
            const SizedBox(height: 16),
            // شريط التقدم
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isCompleted ? AppColors.success : AppColors.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: _isCompleted ? AppColors.success : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context, _isCompleted),
            child: Text(
              _isCompleted ? 'تم' : 'إلغاء',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        if (!_isDownloading && !_isCompleted)
          ElevatedButton.icon(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text(
              'تحميل',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
      ],
    );
  }
}

