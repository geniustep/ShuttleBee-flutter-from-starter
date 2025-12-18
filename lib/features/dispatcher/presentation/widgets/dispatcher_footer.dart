import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// Footer widget for Dispatcher screens - INFO BAR ONLY
///
/// شريط معلومات فقط (بدون أزرار) لصفحات المنسق:
/// - معلومات سريعة (التاريخ، العدد)
/// - حالة الاتصال/المزامنة
/// - إحصائيات إضافية
///
/// ملاحظات:
/// - يختفي تلقائياً على الهاتف
/// - الأزرار تظهر في الـ Header على Tablet/Desktop
/// - الـ FAB يُستخدم على الهاتف
class DispatcherFooter extends StatelessWidget {
  const DispatcherFooter({
    super.key,
    this.info,
    this.secondaryInfo,
    this.stats = const [],
    this.syncStatus,
    this.lastUpdated,
    this.backgroundColor,
    this.elevation = 4.0,
    this.showShadow = true,
    this.hideOnMobile = true,
    // Legacy support - ignored
    this.actions = const [],
  });

  /// نص معلومات رئيسي (مثل: "15 رحلة")
  final String? info;

  /// نص معلومات ثانوي (مثل: "3 جارية")
  final String? secondaryInfo;

  /// إحصائيات صغيرة
  final List<DispatcherFooterStat> stats;

  /// حالة المزامنة
  final DispatcherSyncStatus? syncStatus;

  /// آخر تحديث
  final DateTime? lastUpdated;

  /// لون الخلفية
  final Color? backgroundColor;

  /// ارتفاع الظل
  final double elevation;

  /// إظهار الظل
  final bool showShadow;

  /// إخفاء الفوتر على الهاتف (الافتراضي: true)
  final bool hideOnMobile;

  /// Legacy - لم يعد مستخدماً (الأزرار في الـ Header)
  @Deprecated('Use header primaryActions instead')
  final List<DispatcherFooterAction> actions;

  @override
  Widget build(BuildContext context) {
    // إخفاء الفوتر على الهاتف
    if (context.isMobile && hideOnMobile) {
      return const SizedBox.shrink();
    }

    final safeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFFAFBFC),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: elevation,
                  offset: Offset(0, -elevation / 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.responsive(mobile: 12.0, tablet: 20.0, desktop: 24.0),
          context.responsive(mobile: 8.0, tablet: 10.0, desktop: 12.0),
          context.responsive(mobile: 12.0, tablet: 20.0, desktop: 24.0),
          context.responsive(mobile: 8.0, tablet: 10.0, desktop: 12.0) +
              safeArea,
        ),
        child: Row(
          children: [
            // === المعلومات الرئيسية ===
            if (info != null) ...[
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                info!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // === الفاصل ===
            if (info != null && (secondaryInfo != null || stats.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 1,
                  height: 16,
                  color: Colors.grey.shade300,
                ),
              ),

            // === المعلومات الثانوية ===
            if (secondaryInfo != null)
              Text(
                secondaryInfo!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),

            // === الإحصائيات ===
            if (stats.isNotEmpty) ...[
              if (secondaryInfo != null) const SizedBox(width: 16),
              ...stats.map((stat) => _buildStatChip(context, stat)),
            ],

            const Spacer(),

            // === آخر تحديث ===
            if (lastUpdated != null) ...[
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textDisabled,
              ),
              const SizedBox(width: 4),
              Text(
                _formatLastUpdated(lastUpdated!),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDisabled,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(width: 16),
            ],

            // === حالة المزامنة ===
            if (syncStatus != null) _buildSyncStatus(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, DispatcherFooterStat stat) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            (stat.color ?? AppColors.dispatcherPrimary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stat.icon,
            size: 14,
            color: stat.color ?? AppColors.dispatcherPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            '${stat.value} ${stat.label}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: stat.color ?? AppColors.dispatcherPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context) {
    if (syncStatus == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    final statusColor = switch (syncStatus!) {
      DispatcherSyncStatus.synced => AppColors.success,
      DispatcherSyncStatus.syncing => AppColors.warning,
      DispatcherSyncStatus.offline => AppColors.error,
    };

    final statusIcon = switch (syncStatus!) {
      DispatcherSyncStatus.synced => Icons.cloud_done_rounded,
      DispatcherSyncStatus.syncing => Icons.sync_rounded,
      DispatcherSyncStatus.offline => Icons.cloud_off_rounded,
    };

    final statusText = switch (syncStatus!) {
      DispatcherSyncStatus.synced => l10n.synced,
      DispatcherSyncStatus.syncing => l10n.syncing,
      DispatcherSyncStatus.offline => l10n.offline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} د';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} س';
    } else {
      return 'منذ ${diff.inDays} يوم';
    }
  }
}

/// Footer stat chip data
class DispatcherFooterStat {
  const DispatcherFooterStat({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
}

/// Legacy - kept for backward compatibility
@Deprecated('Footer no longer has action buttons. Use Header primaryActions.')
class DispatcherFooterAction {
  const DispatcherFooterAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
}

/// Sync status enum
enum DispatcherSyncStatus {
  synced,
  syncing,
  offline,
}
