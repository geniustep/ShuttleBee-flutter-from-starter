import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../../shared/widgets/common/hero_header.dart';
import '../../../../shared/widgets/common/stat_card.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../providers/dispatcher_cached_providers.dart';

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final statsAsync = ref.watch(dispatcherDashboardStatsProvider(today));

    return Scaffold(
      backgroundColor: AppColors.dispatcherBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          final cache = ref.read(dispatcherCacheDataSourceProvider);
          final userId =
              ref.read(authStateProvider).asData?.value.user?.id ?? 0;
          if (userId != 0) {
            await cache.delete(
              DispatcherCacheKeys.dashboardStats(
                userId: userId,
                date: today,
              ),
            );
          }
          ref.invalidate(dispatcherDashboardStatsProvider(today));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // === Hero Header ===
            _buildHeroHeader(user, statsAsync),

            // === Role Switcher ===
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.responsive(
                      mobile: double.infinity,
                      tablet: 900,
                      desktop: 1400,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(
                        mobile: 16.0,
                        tablet: 32.0,
                        desktop: 48.0,
                      ),
                      vertical: 8,
                    ),
                    child: const RoleSwitcherWidget(),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ),

            // === Quick Actions ===
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.responsive(
                      mobile: double.infinity,
                      tablet: 900,
                      desktop: 1400,
                    ),
                  ),
                  child: _buildQuickActions(),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            // === Statistics ===
            statsAsync.when(
              data: (stats) => SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.responsive(
                        mobile: double.infinity,
                        tablet: 900,
                        desktop: 1400,
                      ),
                    ),
                    child: _buildStatisticsContent(stats),
                  ),
                ),
              ),
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
    User? user,
    AsyncValue<TripDashboardStats> statsAsync,
  ) {
    final isRefreshing = statsAsync.isLoading;
    final isOnline = ref.watch(isOnlineStateProvider);

    final l10n = AppLocalizations.of(context);
    return HeroHeader(
      title: l10n.welcome,
      userName: user?.name ?? l10n.dispatcher,
      subtitle: _formatDate(context, DateTime.now()),
      gradientColors: HeroGradients.dispatcher,
      showOnlineIndicator: isOnline,
      onlineIndicatorController: _pulseController,
      expandedHeight: 180,
      bottomWidget: !isOnline
          ? GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(RoutePaths.offlineStatus);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.disconnected} • ${l10n.viewSyncStatus}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      actions: [
        HeroHeaderAction(
          icon: Icons.refresh_rounded,
          tooltip: l10n.refresh,
          isLoading: isRefreshing,
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final cache = ref.read(dispatcherCacheDataSourceProvider);
            final userId =
                ref.read(authStateProvider).asData?.value.user?.id ?? 0;
            if (userId != 0) {
              await cache.delete(
                DispatcherCacheKeys.dashboardStats(
                  userId: userId,
                  date: today,
                ),
              );
            }
            ref.invalidate(dispatcherDashboardStatsProvider(today));
          },
        ),
        HeroHeaderAction(
          icon: Icons.settings_rounded,
          tooltip: l10n.settings,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(RoutePaths.settings);
          },
        ),
        HeroHeaderAction(
          icon: Icons.notifications_rounded,
          tooltip: l10n.notifications,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go(RoutePaths.notifications);
          },
        ),
        HeroHeaderAction(
          icon: Icons.chat_bubble_rounded,
          tooltip: 'Messages',
          badge: ref.watch(unreadMessagesCountProvider).maybeWhen(
            data: (count) => count > 0 ? count : null,
            orElse: () => null,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/conversations');
          },
        ),
        HeroHeaderAction(
          icon: Icons.logout_rounded,
          tooltip: l10n.logout,
          onPressed: () => _showLogoutDialog(),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);

    // Responsive grid columns
    final crossAxisCount = context.responsive(
      mobile: 2,
      tablet: 3,
      desktop: 6, // عرض جميع البطاقات في صف واحد على الشاشات الكبيرة
    );

    // Responsive aspect ratio
    final aspectRatio = context.responsive(
      mobile: 1.5,
      tablet: 1.3,
      desktop: 1.1, // نسبة أطول للشاشات الكبيرة
    );

    // Responsive padding
    final padding = context.responsive(
      mobile: 16.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    // Responsive spacing
    final spacing = context.responsive(
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: context.responsive(
                  mobile: const EdgeInsets.all(10),
                  tablet: const EdgeInsets.all(12),
                  desktop: const EdgeInsets.all(14),
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.dispatcherGradient,
                  borderRadius: BorderRadius.circular(
                    context.responsive(
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.dispatcherPrimary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: context.responsive(
                    mobile: 22.0,
                    tablet: 24.0,
                    desktop: 26.0,
                  ),
                ),
              ),
              SizedBox(
                width: context.responsive(
                  mobile: 12.0,
                  tablet: 16.0,
                  desktop: 20.0,
                ),
              ),
              Text(
                l10n.quickActions,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsive(
                    mobile: 18.0,
                    tablet: 20.0,
                    desktop: 24.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: context.responsive(
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
            children: [
              _buildActionCard(
                icon: Icons.list_alt_rounded,
                label: l10n.trips,
                color: AppColors.success,
                delay: 50,
                onTap: () => context.go('${RoutePaths.dispatcherHome}/trips'),
              ),
              _buildActionCard(
                icon: Icons.groups_rounded,
                label: l10n.groups,
                color: AppColors.dispatcherPrimary,
                delay: 150,
                onTap: () => context.go('${RoutePaths.dispatcherHome}/groups'),
              ),
              _buildActionCard(
                icon: Icons.event_busy_rounded,
                label: l10n.holidays,
                color: const Color(0xFFF59E0B), // Amber - أكثر وضوحاً
                delay: 165,
                onTap: () => context.go(RoutePaths.dispatcherHolidays),
              ),
              _buildActionCard(
                icon: Icons.people_alt_rounded,
                label: l10n.passengers,
                color: AppColors.primary,
                delay: 175,
                onTap: () => context.go(RoutePaths.dispatcherPassengers),
              ),
              _buildActionCard(
                icon: Icons.directions_bus_rounded,
                label: l10n.vehicles,
                color: const Color(0xFF6366F1), // Indigo - لون مميز للمركبات
                delay: 100,
                onTap: () =>
                    context.go('${RoutePaths.dispatcherHome}/vehicles'),
              ),
              _buildActionCard(
                icon: Icons.map_rounded,
                label: l10n.liveTracking,
                color: const Color(0xFFEF4444), // Red 500 - أكثر حيوية
                delay: 200,
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              context.responsive(
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
              width: context.responsive(
                mobile: 1.0,
                tablet: 1.5,
                desktop: 2.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: context.responsive(
                  mobile: 16.0,
                  tablet: 20.0,
                  desktop: 24.0,
                ),
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColors.cardShadowLight,
                blurRadius: context.responsive(
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  context.responsive(
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: context.responsive(
                    mobile: 28.0,
                    tablet: 32.0,
                    desktop: 36.0,
                  ),
                  color: color,
                ),
              ),
              SizedBox(
                height: context.responsive(
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsive(
                      mobile: 13.0,
                      tablet: 14.0,
                      desktop: 15.0,
                    ),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: (200 + delay).ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: (200 + delay).ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildStatisticsContent(TripDashboardStats stats) {
    final l10n = AppLocalizations.of(context);
    final padding = context.responsive(
      mobile: 16.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    final sectionSpacing = context.responsive(
      mobile: 24.0,
      tablet: 32.0,
      desktop: 40.0,
    );

    return Column(
      children: [
        // === Today's Statistics ===
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildSectionHeader(
            l10n.todayStatistics,
            _formatDate(context, DateTime.now()),
            Icons.today_rounded,
            AppColors.primary,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        SizedBox(
          height: context.responsive(
            mobile: 12.0,
            tablet: 16.0,
            desktop: 20.0,
          ),
        ),
        _buildTodayStatistics(stats),

        SizedBox(height: sectionSpacing),

        // === Fleet Status ===
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildSectionHeader(
            l10n.fleetStatus,
            null,
            Icons.local_shipping_rounded,
            AppColors.success,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        SizedBox(
          height: context.responsive(
            mobile: 12.0,
            tablet: 16.0,
            desktop: 20.0,
          ),
        ),
        _buildFleetStatus(stats),

        SizedBox(height: sectionSpacing),

        // === Active Trips ===
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildSectionHeader(
            l10n.activeTrips,
            null,
            Icons.play_circle_rounded,
            AppColors.warning,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

        SizedBox(
          height: context.responsive(
            mobile: 12.0,
            tablet: 16.0,
            desktop: 20.0,
          ),
        ),
        _buildActiveTripsCard(stats),

        SizedBox(
          height: context.responsive(
            mobile: 32.0,
            tablet: 48.0,
            desktop: 64.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String? subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(
            context.responsive(
              mobile: 10.0,
              tablet: 12.0,
              desktop: 14.0,
            ),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              context.responsive(
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: context.responsive(
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
            ),
          ),
        ),
        SizedBox(
          width: context.responsive(
            mobile: 12.0,
            tablet: 16.0,
            desktop: 20.0,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsive(
                    mobile: 18.0,
                    tablet: 20.0,
                    desktop: 22.0,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: context.responsive(
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatistics(TripDashboardStats stats) {
    final l10n = AppLocalizations.of(context);
    final padding = context.responsive(
      mobile: 16.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    final spacing = context.responsive(
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              title: l10n.totalTripsToday,
              value: Formatters.formatSimple(stats.totalTripsToday),
              icon: Icons.route_rounded,
              color: AppColors.primary,
              animationDelay: 0,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: StatCard(
              title: l10n.ongoingTrips,
              value: Formatters.formatSimple(stats.ongoingTrips),
              icon: Icons.play_circle_rounded,
              color: AppColors.warning,
              animationDelay: 50,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: StatCard(
              title: l10n.completed,
              value: Formatters.formatSimple(stats.completedTrips),
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              animationDelay: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetStatus(TripDashboardStats stats) {
    final l10n = AppLocalizations.of(context);
    final padding = context.responsive(
      mobile: 16.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    final spacing = context.responsive(
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: l10n.activeVehicles,
                  value: '${Formatters.formatSimple(stats.activeVehicles)}/${Formatters.formatSimple(stats.totalVehicles)}',
                  icon: Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  animationDelay: 200,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: StatCard(
                  title: l10n.activeDrivers,
                  value: '${Formatters.formatSimple(stats.activeDrivers)}/${Formatters.formatSimple(stats.totalDrivers)}',
                  icon: Icons.person_rounded,
                  color: AppColors.success,
                  animationDelay: 250,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          // Fleet Utilization Card
          Container(
            padding: EdgeInsets.all(
              context.responsive(
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.06),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                context.responsive(
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: context.responsive(
                  mobile: 1.0,
                  tablet: 1.5,
                  desktop: 2.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                const BoxShadow(
                  color: AppColors.cardShadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        context.responsive(
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          context.responsive(
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: context.responsive(
                          mobile: 20.0,
                          tablet: 22.0,
                          desktop: 24.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: context.responsive(
                        mobile: 12.0,
                        tablet: 16.0,
                        desktop: 20.0,
                      ),
                    ),
                    Text(
                      l10n.fleetUtilization,
                      style: TextStyle(
                        fontSize: context.responsive(
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        ),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: context.responsive(
                    mobile: 16.0,
                    tablet: 20.0,
                    desktop: 24.0,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    context.responsive(
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 14.0,
                    ),
                  ),
                  child: LinearProgressIndicator(
                    value: stats.totalVehicles > 0
                        ? stats.activeVehicles / stats.totalVehicles
                        : 0,
                    minHeight: context.responsive(
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(
                  height: context.responsive(
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  ),
                ),
                Text(
                  '${Formatters.formatSimple(stats.totalVehicles > 0 ? ((stats.activeVehicles / stats.totalVehicles) * 100).toStringAsFixed(0) : 0)}% ${l10n.fleetInUse}',
                  style: TextStyle(
                    fontSize: context.responsive(
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
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
    final l10n = AppLocalizations.of(context);
    final padding = context.responsive(
      mobile: 16.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('${RoutePaths.dispatcherHome}/monitor');
          },
          child: Container(
            padding: EdgeInsets.all(
              context.responsive(
                mobile: 20.0,
                tablet: 24.0,
                desktop: 28.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: AppColors.dispatcherGradient,
              borderRadius: BorderRadius.circular(
                context.responsive(
                  mobile: 20.0,
                  tablet: 22.0,
                  desktop: 24.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.35),
                  blurRadius: context.responsive(
                    mobile: 20.0,
                    tablet: 24.0,
                    desktop: 28.0,
                  ),
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                  blurRadius: context.responsive(
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        context.responsive(
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          context.responsive(
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        color: Colors.white,
                        size: context.responsive(
                          mobile: 24.0,
                          tablet: 26.0,
                          desktop: 28.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: context.responsive(
                        mobile: 16.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.liveMonitoring,
                            style: TextStyle(
                              fontSize: context.responsive(
                                mobile: 18.0,
                                tablet: 20.0,
                                desktop: 22.0,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            '${Formatters.formatSimple(stats.ongoingTrips)} ${l10n.activeTripsNow}',
                            style: TextStyle(
                              fontSize: context.responsive(
                                mobile: 13.0,
                                tablet: 14.0,
                                desktop: 15.0,
                              ),
                              color: Colors.white.withValues(alpha: 0.8),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(
                        context.responsive(
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          context.responsive(
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: context.responsive(
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 22.0,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: context.responsive(
                    mobile: 20.0,
                    tablet: 24.0,
                    desktop: 28.0,
                  ),
                ),
                // Live indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLiveIndicator(
                      icon: Icons.directions_bus_rounded,
                      label: l10n.vehicles,
                      value: Formatters.formatSimple(stats.activeVehicles),
                    ),
                    Container(
                      width: 1,
                      height: context.responsive(
                        mobile: 40.0,
                        tablet: 45.0,
                        desktop: 50.0,
                      ),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _buildLiveIndicator(
                      icon: Icons.person_rounded,
                      label: l10n.drivers,
                      value: Formatters.formatSimple(stats.activeDrivers),
                    ),
                    Container(
                      width: 1,
                      height: context.responsive(
                        mobile: 40.0,
                        tablet: 45.0,
                        desktop: 50.0,
                      ),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _buildLiveIndicator(
                      icon: Icons.play_circle_rounded,
                      label: l10n.trips,
                      value: Formatters.formatSimple(stats.ongoingTrips),
                    ),
                  ],
                ),
              ],
            ),
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
        Icon(
          icon,
          color: Colors.white,
          size: context.responsive(
            mobile: 24.0,
            tablet: 26.0,
            desktop: 28.0,
          ),
        ),
        SizedBox(
          height: context.responsive(
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 18.0,
              tablet: 20.0,
              desktop: 22.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 11.0,
              tablet: 12.0,
              desktop: 13.0,
            ),
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);
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
              l10n.error,
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
              onPressed: () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                ref.invalidate(dispatcherDashboardStatsProvider(today));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
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

  String _formatDate(BuildContext context, DateTime date) {
    return Formatters.displayDate(date);
  }

  void _showLogoutDialog() {
    final l10n = AppLocalizations.of(context);
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
            Text(
              l10n.logout,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.logoutConfirm,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontFamily: 'Cairo'),
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
            child: Text(
              l10n.logout,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}
