import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../shared/widgets/common/hero_header.dart';
import '../../../../shared/widgets/common/stat_card.dart';
import '../../../../shared/widgets/common/user_avatar.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Manager Home Screen - الصفحة الرئيسية للمدير - ShuttleBee
/// تصميم احترافي مطابق لمستوى صفحة السائق
class ManagerHomeScreen extends ConsumerStatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  ConsumerState<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends ConsumerState<ManagerHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;
    final analyticsAsync = ref.watch(managerAnalyticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(managerAnalyticsProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // === Hero Header ===
            _buildHeroHeader(user, analyticsAsync),

            // === Role Switcher ===
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: RoleSwitcherWidget(),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ),

            // === Quick Navigation ===
            SliverToBoxAdapter(
              child: _buildQuickNavigation()
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            // === Analytics Content ===
            analyticsAsync.when(
              data: (analytics) => _buildAnalyticsContent(analytics),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(User? user, AsyncValue<ManagerAnalytics> analyticsAsync) {
    final isRefreshing = analyticsAsync.isLoading;

    return HeroHeader(
      title: 'مرحباً',
      userName: user?.name ?? 'المدير',
      subtitle: DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
      gradientColors: HeroGradients.manager,
      showOnlineIndicator: true,
      onlineIndicatorController: _pulseController,
      expandedHeight: 180,
      actions: [
        HeroHeaderAction(
          icon: Icons.refresh_rounded,
          tooltip: 'تحديث',
          isLoading: isRefreshing,
          onPressed: () {
            HapticFeedback.mediumImpact();
            ref.invalidate(managerAnalyticsProvider);
          },
        ),
        HeroHeaderAction(
          icon: Icons.notifications_rounded,
          tooltip: 'الإشعارات',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go(RoutePaths.notifications);
          },
        ),
        HeroHeaderAction(
          icon: Icons.logout_rounded,
          tooltip: 'تسجيل الخروج',
          onPressed: () => _showLogoutDialog(),
        ),
      ],
    );
  }

  Widget _buildQuickNavigation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الإجراءات السريعة',
                style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildNavCard(
                icon: Icons.bar_chart_rounded,
                label: 'التحليلات المتقدمة',
                color: AppColors.primary,
                delay: 0,
                onTap: () => context.go('${RoutePaths.managerHome}/analytics'),
              ),
              _buildNavCard(
                icon: Icons.description_rounded,
                label: 'التقارير',
                color: AppColors.success,
                delay: 50,
                onTap: () => context.go('${RoutePaths.managerHome}/reports'),
              ),
              _buildNavCard(
                icon: Icons.dashboard_customize_rounded,
                label: 'نظرة عامة',
                color: AppColors.warning,
                delay: 100,
                onTap: () => context.go('${RoutePaths.managerHome}/overview'),
              ),
              _buildNavCard(
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                color: const Color(0xFF7B1FA2),
                delay: 150,
                onTap: () => context.go(RoutePaths.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String label,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (200 + delay).ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: (200 + delay).ms,
        );
  }

  SliverList _buildAnalyticsContent(ManagerAnalytics analytics) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // === Key Metrics Section ===
        _buildSectionHeader(
          'المقاييس الرئيسية',
          DateFormat('MMMM yyyy', 'ar').format(DateTime.now()),
          Icons.analytics_rounded,
          AppColors.primary,
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        const SizedBox(height: 12),
        _buildKeyMetrics(analytics),

        const SizedBox(height: 24),

        // === Performance Section ===
        _buildSectionHeader(
          'مقاييس الأداء',
          null,
          Icons.speed_rounded,
          AppColors.success,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        const SizedBox(height: 12),
        _buildPerformanceMetrics(analytics),

        const SizedBox(height: 24),

        // === Resource Utilization ===
        _buildSectionHeader(
          'استخدام الموارد',
          null,
          Icons.pie_chart_rounded,
          AppColors.warning,
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

        const SizedBox(height: 12),
        _buildResourceUtilization(analytics),

        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String? subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(ManagerAnalytics analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'إجمالي الرحلات',
                  value: '${analytics.totalTripsThisMonth}',
                  icon: Icons.route_rounded,
                  color: AppColors.primary,
                  animationDelay: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'منتهية',
                  value: '${analytics.completedTripsThisMonth}',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  animationDelay: 50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'معدل الإنجاز',
                  value: '${analytics.completionRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  trend: 2.5,
                  animationDelay: 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'معدل الإلغاء',
                  value: '${analytics.cancellationRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_down_rounded,
                  color: analytics.cancellationRate > 10
                      ? AppColors.error
                      : AppColors.warning,
                  trend: -1.2,
                  animationDelay: 150,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(ManagerAnalytics analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'الركاب',
                  value: '${analytics.totalPassengersTransported}',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary,
                  animationDelay: 200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'معدل الإشغال',
                  value: '${analytics.averageOccupancyRate.toStringAsFixed(1)}%',
                  icon: Icons.event_seat_rounded,
                  color: AppColors.success,
                  trend: 3.2,
                  animationDelay: 250,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'في الموعد',
                  value: '${analytics.onTimePercentage.toStringAsFixed(1)}%',
                  icon: Icons.schedule_rounded,
                  color: analytics.onTimePercentage >= 80
                      ? AppColors.success
                      : AppColors.warning,
                  animationDelay: 300,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'متوسط التأخير',
                  value: '${analytics.averageDelayMinutes.toStringAsFixed(0)} د',
                  icon: Icons.timer_rounded,
                  color: analytics.averageDelayMinutes <= 5
                      ? AppColors.success
                      : AppColors.error,
                  animationDelay: 350,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceUtilization(ManagerAnalytics analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'المسافة الكلية',
                  value: '${analytics.totalDistanceKm.toStringAsFixed(0)} كم',
                  icon: Icons.map_rounded,
                  color: AppColors.primary,
                  animationDelay: 400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'متوسط المسافة',
                  value: '${analytics.averageDistancePerTrip.toStringAsFixed(1)} كم',
                  icon: Icons.straighten_rounded,
                  color: AppColors.success,
                  animationDelay: 450,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fuel Cost Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.1),
                  AppColors.warning.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تكلفة الوقود المقدرة',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${analytics.estimatedFuelCost.toStringAsFixed(0)} ريال',
                        style: AppTypography.h4.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.warning.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideX(
                begin: 0.05,
                end: 0,
                duration: 400.ms,
                delay: 500.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: AppTypography.h5.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(managerAnalyticsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) {
                context.go(RoutePaths.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}
