import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Dispatcher Home Screen - الصفحة الرئيسية للمرسل - ShuttleBee
class DispatcherHomeScreen extends ConsumerWidget {
  const DispatcherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;
    final statsAsync = ref.watch(dashboardStatsProvider(DateTime.now()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة تحكم المرسل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(dashboardStatsProvider(DateTime.now())),
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
          ref.invalidate(dashboardStatsProvider(DateTime.now()));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Header
              _buildUserHeader(user),

              const SizedBox(height: AppDimensions.lg),

              // Quick Actions
              Text('الإجراءات السريعة', style: AppTypography.h4),

              const SizedBox(height: AppDimensions.md),

              _buildQuickActions(context),

              const SizedBox(height: AppDimensions.lg),

              // Statistics
              const Text('إحصائيات اليوم', style: AppTypography.h4),

              const SizedBox(height: AppDimensions.md),

              statsAsync.when(
                data: (stats) => _buildStatistics(stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildStatistics(const TripDashboardStats()),
              ),
            ],
          ),
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

  Widget _buildUserHeader(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Text(
                user?.name != null
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'D',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'مرسل', style: AppTypography.h4),
                  const SizedBox(height: 4),
                  Text(
                    'مرسل النقل المدرسي',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.md,
      crossAxisSpacing: AppDimensions.md,
      childAspectRatio: 1.5,
      children: [
        _buildQuickActionCard(
          icon: Icons.add_road,
          label: 'إنشاء رحلة جديدة',
          color: AppColors.primary,
          onTap: () {
            context.go('${RoutePaths.dispatcherHome}/trips/create');
          },
        ),
        _buildQuickActionCard(
          icon: Icons.list_alt,
          label: 'إدارة الرحلات',
          color: AppColors.success,
          onTap: () {
            context.go('${RoutePaths.dispatcherHome}/trips');
          },
        ),
        _buildQuickActionCard(
          icon: Icons.directions_bus,
          label: 'إدارة المركبات',
          color: AppColors.warning,
          onTap: () {
            context.go('${RoutePaths.dispatcherHome}/vehicles');
          },
        ),
        _buildQuickActionCard(
          icon: Icons.map,
          label: 'المراقبة الحية',
          color: AppColors.error,
          onTap: () {
            context.go('${RoutePaths.dispatcherHome}/monitor');
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
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

  Widget _buildStatistics(TripDashboardStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'المجموع',
                '${stats.totalTripsToday}',
                Icons.calendar_today,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _buildStatCard(
                'جارية',
                '${stats.ongoingTrips}',
                Icons.play_circle,
                AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'منتهية',
                '${stats.completedTrips}',
                Icons.check_circle,
                AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _buildStatCard(
                'ملغاة',
                '${stats.cancelledTrips}',
                Icons.cancel,
                AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'المركبات',
                '${stats.activeVehicles}/${stats.totalVehicles}',
                Icons.directions_bus,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _buildStatCard(
                'السائقين',
                '${stats.activeDrivers}/${stats.totalDrivers}',
                Icons.person,
                AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
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
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppDimensions.sm),
            Text(
              value,
              style: AppTypography.h3.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
