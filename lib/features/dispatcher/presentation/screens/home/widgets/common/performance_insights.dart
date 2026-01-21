import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../trips/presentation/providers/trip_providers.dart'
    show TripDashboardStats;

/// 📊 Performance Insights Widget - رؤى الأداء
/// تصميم احترافي مع animations وألوان متناسقة
class PerformanceInsights extends StatelessWidget {
  final TripDashboardStats stats;

  const PerformanceInsights({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.dispatcherBackground.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.dispatcherPrimaryLight.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Main Metrics Row
            Row(
              children: [
                Expanded(
                  child: _PerformanceMetricCard(
                    title: 'معدل الإنجاز',
                    value: '${stats.completionRate.toStringAsFixed(1)}%',
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                    backgroundColor: AppColors.successLight.withValues(alpha: 0.3),
                    trend: _getTrend(stats.completionRate, 80),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PerformanceMetricCard(
                    title: 'الالتزام بالوقت',
                    value: '${stats.onTimeRate.toStringAsFixed(1)}%',
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.info,
                    backgroundColor: AppColors.infoLight.withValues(alpha: 0.3),
                    trend: _getTrend(stats.onTimeRate, 85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Secondary Metrics Row
            Row(
              children: [
                Expanded(
                  child: _PerformanceMetricCard(
                    title: 'الرحلات النشطة',
                    value: '${stats.ongoingTrips}',
                    icon: Icons.directions_bus_rounded,
                    iconColor: AppColors.secondary,
                    backgroundColor: AppColors.secondaryLight.withValues(alpha: 0.3),
                    subtitle: 'من ${stats.totalTripsToday} رحلة',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PerformanceMetricCard(
                    title: 'المتأخرة',
                    value: '${stats.delayedTrips}',
                    icon: Icons.warning_amber_rounded,
                    iconColor: stats.delayedTrips > 0 ? AppColors.error : AppColors.success,
                    backgroundColor: stats.delayedTrips > 0
                        ? AppColors.errorLight.withValues(alpha: 0.3)
                        : AppColors.successLight.withValues(alpha: 0.3),
                    isAlert: stats.delayedTrips > 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar Section
            _buildProgressSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppColors.dispatcherGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.dispatcherPrimary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رؤى الأداء',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'نظرة شاملة على أداء اليوم',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        _buildLiveIndicator(),
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'مباشر',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final attendanceRate = stats.attendanceRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'معدل حضور الركاب',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${attendanceRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: _getProgressColor(attendanceRate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: attendanceRate / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(attendanceRate),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حضور: ${stats.boardedPassengers}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'غياب: ${stats.absentPassengers}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'إجمالي: ${stats.totalPassengers}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _TrendType _getTrend(double value, double threshold) {
    if (value >= threshold) return _TrendType.up;
    if (value >= threshold - 10) return _TrendType.neutral;
    return _TrendType.down;
  }

  Color _getProgressColor(double value) {
    if (value >= 90) return AppColors.success;
    if (value >= 70) return AppColors.secondary;
    return AppColors.error;
  }
}

enum _TrendType { up, down, neutral }

/// 📊 Performance Metric Card
class _PerformanceMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final _TrendType? trend;
  final String? subtitle;
  final bool isAlert;

  const _PerformanceMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.trend,
    this.subtitle,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: isAlert
            ? Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trend != null) _buildTrendIndicator(trend!),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: iconColor,
              fontFamily: 'Cairo',
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(_TrendType trend) {
    IconData trendIcon;
    Color trendColor;

    switch (trend) {
      case _TrendType.up:
        trendIcon = Icons.trending_up_rounded;
        trendColor = AppColors.success;
        break;
      case _TrendType.down:
        trendIcon = Icons.trending_down_rounded;
        trendColor = AppColors.error;
        break;
      case _TrendType.neutral:
        trendIcon = Icons.trending_flat_rounded;
        trendColor = AppColors.textSecondary;
        break;
    }

    return Icon(trendIcon, size: 16, color: trendColor);
  }
}
