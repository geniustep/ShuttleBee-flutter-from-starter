import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Manager Home Screen - الصفحة الرئيسية للمدير - ShuttleBee
class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;
    final analyticsAsync = ref.watch(managerAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(managerAnalyticsProvider),
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, ref),
            tooltip: 'تسجيل خروج',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(managerAnalyticsProvider);
        },
        child: analyticsAsync.when(
          data: (analytics) => _buildContent(context, user, analytics),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(context, ref, error.toString()),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(error,
              style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.md),
          ElevatedButton(
            onPressed: () => ref.invalidate(managerAnalyticsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, user, ManagerAnalytics analytics) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          _buildUserHeader(user),

          const SizedBox(height: AppDimensions.lg),

          // Quick Navigation
          _buildQuickNavigation(context),

          const SizedBox(height: AppDimensions.lg),

          // Key Metrics
          Text(
            'المقاييس الرئيسية - ${DateFormat('MMMM yyyy', 'ar').format(DateTime.now())}',
            style: AppTypography.h4,
          ),

          const SizedBox(height: AppDimensions.md),

          _buildKeyMetrics(analytics),

          const SizedBox(height: AppDimensions.lg),

          // Performance Metrics
          Text('مقاييس الأداء', style: AppTypography.h4),

          const SizedBox(height: AppDimensions.md),

          _buildPerformanceMetrics(analytics),

          const SizedBox(height: AppDimensions.lg),

          // Resource Utilization
          Text('استخدام الموارد', style: AppTypography.h4),

          const SizedBox(height: AppDimensions.md),

          _buildResourceUtilization(analytics),
        ],
      ),
    );
  }

  Widget _buildUserHeader(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.error,
              child: Text(
                user?.name?.substring(0, 1).toUpperCase() ?? 'M',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'مدير', style: AppTypography.h4),
                  const SizedBox(height: 4),
                  Text(
                    'مدير النقل',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.admin_panel_settings,
                size: 32, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavigation(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.md,
      crossAxisSpacing: AppDimensions.md,
      childAspectRatio: 1.5,
      children: [
        _buildNavCard(
          context: context,
          icon: Icons.bar_chart,
          label: 'التحليلات المتقدمة',
          color: AppColors.primary,
          onTap: () {
            context.go('${RoutePaths.managerHome}/analytics');
          },
        ),
        _buildNavCard(
          context: context,
          icon: Icons.description,
          label: 'التقارير',
          color: AppColors.success,
          onTap: () {
            context.go('${RoutePaths.managerHome}/reports');
          },
        ),
        _buildNavCard(
          context: context,
          icon: Icons.dashboard,
          label: 'نظرة عامة',
          color: AppColors.warning,
          onTap: () {
            context.go('${RoutePaths.managerHome}/overview');
          },
        ),
        _buildNavCard(
          context: context,
          icon: Icons.settings,
          label: 'الإعدادات',
          color: AppColors.error,
          onTap: () {
            context.go(RoutePaths.settings);
          },
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: AppDimensions.sm),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(ManagerAnalytics analytics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'إجمالي الرحلات',
                '${analytics.totalTripsThisMonth}',
                Icons.route,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _buildMetricCard(
                'منتهية',
                '${analytics.completedTripsThisMonth}',
                Icons.check_circle,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'معدل الإنجاز',
                '${analytics.completionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _buildMetricCard(
                'معدل الإلغاء',
                '${analytics.cancellationRate.toStringAsFixed(1)}%',
                Icons.trending_down,
                analytics.cancellationRate > 10
                    ? AppColors.error
                    : AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics(ManagerAnalytics analytics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'الركاب',
                '${analytics.totalPassengersTransported}',
                Icons.people,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _buildMetricCard(
                'معدل الإشغال',
                '${analytics.averageOccupancyRate.toStringAsFixed(1)}%',
                Icons.event_seat,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'في الموعد',
                '${analytics.onTimePercentage.toStringAsFixed(1)}%',
                Icons.schedule,
                analytics.onTimePercentage >= 80
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _buildMetricCard(
                'متوسط التأخير',
                '${analytics.averageDelayMinutes.toStringAsFixed(0)} د',
                Icons.timer,
                analytics.averageDelayMinutes <= 5
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceUtilization(ManagerAnalytics analytics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'المسافة الكلية',
                '${analytics.totalDistanceKm.toStringAsFixed(0)} كم',
                Icons.map,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _buildMetricCard(
                'متوسط المسافة',
                '${analytics.averageDistancePerTrip.toStringAsFixed(1)} كم',
                Icons.straighten,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning.withValues(alpha: 0.1),
                AppColors.warning.withValues(alpha: 0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.local_gas_station,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تكلفة الوقود المقدرة',
                        style: AppTypography.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      '${analytics.estimatedFuelCost.toStringAsFixed(0)} ريال',
                      style:
                          AppTypography.h4.copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: AppDimensions.sm),
            Text(
              value,
              style: AppTypography.h4.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
