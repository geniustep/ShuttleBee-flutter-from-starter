import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/enums/enums.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/dispatcher_cached_providers.dart';

// Common widgets
import 'home/widgets/common/performance_insights.dart';
import 'home/widgets/common/role_switcher.dart';

// Sidebar widgets
import 'home/widgets/sidebar/smart_sidebar.dart';

// Dashboard widgets
import 'home/widgets/dashboard/hero_header.dart';
import 'home/widgets/dashboard/quick_stats_summary.dart';
import 'home/widgets/dashboard/statistics_dashboard.dart';

// Quick actions widgets
import 'home/widgets/quick_actions/quick_actions_grid.dart';

/// Dispatcher Home Screen - الصفحة الرئيسية للمرسل - ShuttleBee
/// 🚀 تصميم احترافي عالمي مع Sidebar ذكي وديناميكي
class DispatcherHomeScreen extends ConsumerStatefulWidget {
  const DispatcherHomeScreen({super.key});

  @override
  ConsumerState<DispatcherHomeScreen> createState() =>
      _DispatcherHomeScreenState();
}

class _DispatcherHomeScreenState extends ConsumerState<DispatcherHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  // 🎯 Sidebar State Management
  bool _isSidebarExpanded = true;
  String _tripSearchQuery = '';
  TripState? _selectedTripFilter;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final statsAsync = ref.watch(dispatcherDashboardStatsProvider(today));

    // Listen for authentication errors and handle them
    ref.listen<AsyncValue<TripDashboardStats>>(
      dispatcherDashboardStatsProvider(today),
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            if (_isAuthenticationError(error)) {
              // Handle authentication error immediately
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleAuthenticationError();
              });
            }
          },
        );
      },
    );

    return Scaffold(
      backgroundColor: AppColors.dispatcherBackground,
      body: context.isDesktop && !context.isTablet
          ? _buildDesktopLayout(user, statsAsync, today)
          : _buildMobileLayout(user, statsAsync, today),
    );
  }

  /// 🖥️ Desktop Layout with Smart Sidebar
  Widget _buildDesktopLayout(
    User? user,
    AsyncValue<TripDashboardStats> statsAsync,
    DateTime today,
  ) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(today),
      color: AppColors.dispatcherPrimary,
      backgroundColor: Colors.white,
      child: Row(
        children: [
          // 📊 Main Content Area
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero Header (returns SliverAppBar, so no SliverToBoxAdapter needed)
                DispatcherHeroHeader(
                  user: user,
                  statsAsync: statsAsync,
                  pulseController: _pulseController,
                  onRefresh: () => _refreshData(today),
                ),

                // Spacing after header
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: context.responsive(
                      mobile: 16.0,
                      tablet: 20.0,
                      desktop: 24.0,
                    ),
                  ),
                ),

                // Quick Stats Bar
                statsAsync.maybeWhen(
                  data: (stats) => SliverToBoxAdapter(
                    child: QuickStatsSummary(stats: stats),
                  ),
                  orElse: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Role Switcher (Placeholder - implement based on your needs)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: RoleSwitcher(
                        isDispatcherMode: true,
                        onRoleChanged: (isDispatcher) {
                          // Handle role change
                        },
                      ),
                    ),
                  ),
                ),

                // Performance Insights
                statsAsync.maybeWhen(
                  data: (stats) => SliverToBoxAdapter(
                    child: PerformanceInsights(
                      totalTrips: stats.totalTripsToday,
                      completedTrips: stats.completedTrips,
                      activeTrips: stats.ongoingTrips,
                      delayedTrips: 0, // TODO: Add delayed trips tracking
                    ),
                  ),
                  orElse: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Quick Actions Grid
                const SliverToBoxAdapter(child: QuickActionsGrid()),

                // Statistics Dashboard
                statsAsync.when(
                  data: (stats) => SliverToBoxAdapter(
                    child: StatisticsDashboard(stats: stats, today: today),
                  ),
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  error: (error, _) {
                    if (_isAuthenticationError(error)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _handleAuthenticationError();
                      });
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Error: ${error.toString()}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 🎯 Smart Collapsible Sidebar
          SmartSidebar(
            today: today,
            isSidebarExpanded: _isSidebarExpanded,
            onToggleSidebar: (value) {
              setState(() {
                _isSidebarExpanded = value;
              });
            },
            tripSearchQuery: _tripSearchQuery,
            onSearchChanged: (value) {
              setState(() {
                _tripSearchQuery = value;
              });
            },
            selectedTripFilter: _selectedTripFilter,
            onFilterChanged: (value) {
              setState(() {
                _selectedTripFilter = value;
              });
            },
            searchController: _searchController,
          ),
        ],
      ),
    );
  }

  /// 📱 Mobile/Tablet Layout
  Widget _buildMobileLayout(
    User? user,
    AsyncValue<TripDashboardStats> statsAsync,
    DateTime today,
  ) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(today),
      color: AppColors.dispatcherPrimary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header (returns SliverAppBar, so no SliverToBoxAdapter needed)
          DispatcherHeroHeader(
            user: user,
            statsAsync: statsAsync,
            pulseController: _pulseController,
            onRefresh: () => _refreshData(today),
          ),

          // Spacing after header
          SliverToBoxAdapter(
            child: SizedBox(
              height: context.responsive(
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              ),
            ),
          ),

          // Quick Stats Bar
          statsAsync.maybeWhen(
            data: (stats) =>
                SliverToBoxAdapter(child: QuickStatsSummary(stats: stats)),
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Role Switcher
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: RoleSwitcher(
                  isDispatcherMode: true,
                  onRoleChanged: (isDispatcher) {
                    // Handle role change
                  },
                ),
              ),
            ),
          ),

          // Performance Insights
          statsAsync.maybeWhen(
            data: (stats) => SliverToBoxAdapter(
              child: PerformanceInsights(
                totalTrips: stats.totalTripsToday,
                completedTrips: stats.completedTrips,
                activeTrips: stats.ongoingTrips,
                delayedTrips: 0, // TODO: Add delayed trips tracking
              ),
            ),
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Quick Actions Grid
          const SliverToBoxAdapter(child: QuickActionsGrid()),

          // Statistics Dashboard
          statsAsync.when(
            data: (stats) => SliverToBoxAdapter(
              child: StatisticsDashboard(stats: stats, today: today),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (error, _) {
              if (_isAuthenticationError(error)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleAuthenticationError();
                });
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Error: ${error.toString()}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Check if error is authentication-related
  bool _isAuthenticationError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unauthorized') ||
        errorString.contains('unauthenticated') ||
        errorString.contains('invalid session') ||
        errorString.contains('session expired') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('forbidden') ||
        errorString.contains('missing odoo credentials') ||
        errorString.contains('no tokens found') ||
        (error is StateError && errorString.contains('authenticated'));
  }

  /// Handle authentication error by logging out and redirecting to login
  Future<void> _handleAuthenticationError() async {
    if (!mounted) return;

    try {
      // Logout first to clear session
      await ref.read(authStateProvider.notifier).logout();
    } catch (e) {
      // Continue even if logout fails
    }

    // Always redirect to login
    if (mounted) {
      context.go(RoutePaths.login);
    }
  }

  /// Refresh data
  Future<void> _refreshData(DateTime today) async {
    HapticFeedback.lightImpact();
    final cache = ref.read(dispatcherCacheDataSourceProvider);
    final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
    if (userId != 0) {
      await cache.delete(
        DispatcherCacheKeys.dashboardStats(userId: userId, date: today),
      );
    }
    ref.invalidate(dispatcherDashboardStatsProvider(today));
    final todayFilters = TripFilters(
      fromDate: today,
      toDate: DateTime(today.year, today.month, today.day, 23, 59, 59),
    );
    ref.invalidate(dispatcherTripsProvider(todayFilters));
  }
}
