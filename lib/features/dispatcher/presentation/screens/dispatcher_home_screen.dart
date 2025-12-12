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
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Dispatcher Home Screen - الصفحة الرئيسية للمرسل - ShuttleBee
/// تصميم احترافي مطابق لمستوى صفحة السائق
class DispatcherHomeScreen extends ConsumerStatefulWidget {
  const DispatcherHomeScreen({super.key});

  @override
  ConsumerState<DispatcherHomeScreen> createState() =>
      _DispatcherHomeScreenState();
}

class _DispatcherHomeScreenState extends ConsumerState<DispatcherHomeScreen>
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
    final statsAsync = ref.watch(dashboardStatsProvider(DateTime.now()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider(DateTime.now()));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // === Hero Header ===
            _buildHeroHeader(user, statsAsync),

            // === Role Switcher ===
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: RoleSwitcherWidget(),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ),

            // === Quick Actions ===
            SliverToBoxAdapter(
              child: _buildQuickActions()
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            // === Statistics ===
            statsAsync.when(
              data: (stats) => _buildStatisticsContent(stats),
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

  Widget _buildHeroHeader(
      User? user, AsyncValue<TripDashboardStats> statsAsync) {
    final isRefreshing = statsAsync.isLoading;

    return HeroHeader(
      title: 'مرحباً',
      userName: user?.name ?? 'المرسل',
      subtitle: DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
      gradientColors: HeroGradients.dispatcher,
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
            ref.invalidate(dashboardStatsProvider(DateTime.now()));
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

  Widget _buildQuickActions() {
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
                    colors: [Color(0xFF7B1FA2), Color(0xFF6A1B9A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
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
              _buildActionCard(
                icon: Icons.add_road_rounded,
                label: 'إنشاء رحلة جديدة',
                color: AppColors.primary,
                delay: 0,
                onTap: () =>
                    context.go('${RoutePaths.dispatcherHome}/trips/create'),
              ),
              _buildActionCard(
                icon: Icons.list_alt_rounded,
                label: 'إدارة الرحلات',
                color: AppColors.success,
                delay: 50,
                onTap: () => context.go('${RoutePaths.dispatcherHome}/trips'),
              ),
              _buildActionCard(
                icon: Icons.directions_bus_rounded,
                label: 'إدارة المركبات',
                color: AppColors.warning,
                delay: 100,
                onTap: () => context.go('${RoutePaths.dispatcherHome}/vehicles'),
              ),
              _buildActionCard(
                icon: Icons.map_rounded,
                label: 'المراقبة الحية',
                color: AppColors.error,
                delay: 150,
                onTap: () => context.go('${RoutePaths.dispatcherHome}/monitor'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
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

  SliverList _buildStatisticsContent(TripDashboardStats stats) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // === Today's Statistics ===
        _buildSectionHeader(
          'إحصائيات اليوم',
          DateFormat('EEEE، d MMMM', 'ar').format(DateTime.now()),
          Icons.today_rounded,
          AppColors.primary,
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        const SizedBox(height: 12),
        _buildTodayStatistics(stats),

        const SizedBox(height: 24),

        // === Fleet Status ===
        _buildSectionHeader(
          'حالة الأسطول',
          null,
          Icons.local_shipping_rounded,
          AppColors.success,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        const SizedBox(height: 12),
        _buildFleetStatus(stats),

        const SizedBox(height: 24),

        // === Active Trips ===
        _buildSectionHeader(
          'الرحلات النشطة',
          null,
          Icons.play_circle_rounded,
          AppColors.warning,
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

        const SizedBox(height: 12),
        _buildActiveTripsCard(stats),

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

  Widget _buildTodayStatistics(TripDashboardStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'إجمالي الرحلات',
                  value: '${stats.totalTripsToday}',
                  icon: Icons.route_rounded,
                  color: AppColors.primary,
                  animationDelay: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'رحلات جارية',
                  value: '${stats.ongoingTrips}',
                  icon: Icons.play_circle_rounded,
                  color: AppColors.warning,
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
                  title: 'منتهية',
                  value: '${stats.completedTrips}',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  animationDelay: 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'ملغاة',
                  value: '${stats.cancelledTrips}',
                  icon: Icons.cancel_rounded,
                  color: AppColors.error,
                  animationDelay: 150,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFleetStatus(TripDashboardStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'المركبات النشطة',
                  value: '${stats.activeVehicles}/${stats.totalVehicles}',
                  icon: Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  animationDelay: 200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'السائقين النشطين',
                  value: '${stats.activeDrivers}/${stats.totalDrivers}',
                  icon: Icons.person_rounded,
                  color: AppColors.success,
                  animationDelay: 250,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fleet Utilization Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'معدل استخدام الأسطول',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: stats.totalVehicles > 0
                        ? stats.activeVehicles / stats.totalVehicles
                        : 0,
                    minHeight: 12,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats.totalVehicles > 0 ? ((stats.activeVehicles / stats.totalVehicles) * 100).toStringAsFixed(0) : 0}% من الأسطول قيد الاستخدام',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildActiveTripsCard(TripDashboardStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('${RoutePaths.dispatcherHome}/monitor');
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.gps_fixed_rounded,
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
                          'المراقبة الحية',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          '${stats.ongoingTrips} رحلة نشطة الآن',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Live indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLiveIndicator(
                    icon: Icons.directions_bus_rounded,
                    label: 'مركبات',
                    value: '${stats.activeVehicles}',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  _buildLiveIndicator(
                    icon: Icons.person_rounded,
                    label: 'سائقين',
                    value: '${stats.activeDrivers}',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  _buildLiveIndicator(
                    icon: Icons.play_circle_rounded,
                    label: 'رحلات',
                    value: '${stats.ongoingTrips}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 450.ms).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 400.ms,
            delay: 450.ms,
          ),
    );
  }

  Widget _buildLiveIndicator({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'Cairo',
          ),
        ),
      ],
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
              onPressed: () =>
                  ref.invalidate(dashboardStatsProvider(DateTime.now())),
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
