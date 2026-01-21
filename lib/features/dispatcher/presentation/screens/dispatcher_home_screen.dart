import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/enums/enums.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/presentation/providers/trip_providers.dart'
    show TripFilters, TripDashboardStats;
import '../providers/dispatcher_cached_providers.dart';
import '../providers/dispatcher_initial_load_provider.dart';
import '../widgets/initial_load_widget.dart';

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

  // 🎯 Initial Load State
  bool _initialLoadTriggered = false;

  // حفظ تاريخ اليوم لتجنب إعادة الحساب المتكررة
  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // 🚀 بدء التحميل الأولي للمنصات التي تحتاجه
    _triggerInitialLoad();
  }

  void _triggerInitialLoad() {
    if (_initialLoadTriggered) return;
    _initialLoadTriggered = true;

    // تأخير حسب المنصة
    Future.delayed(
      Duration(milliseconds: PlatformUtils.initialLoadDelayMs),
      () {
        if (!mounted) return;

        // التحقق من المنصة والحالة
        if (PlatformUtils.needsInitialDataLoad) {
          final loadState = ref.read(dispatcherInitialLoadProvider);
          if (!loadState.isLoading && !loadState.isComplete) {
            ref.read(dispatcherInitialLoadProvider.notifier).startInitialLoad();
          }
        }
      },
    );
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

    // 🎯 مراقبة حالة التحميل الأولي
    final initialLoadState = ref.watch(dispatcherInitialLoadProvider);

    // عدم جلب dashboard stats أثناء التحميل الأولي لتجنب الاستدعاءات المتكررة
    final shouldLoadStats = !PlatformUtils.needsInitialDataLoad ||
        !initialLoadState.isLoading ||
        initialLoadState.isComplete;

    final statsAsync = shouldLoadStats
        ? ref.watch(dispatcherDashboardStatsProvider(_today))
        : const AsyncValue<TripDashboardStats>.loading();

    // Listen for authentication errors and handle them
    ref.listen<AsyncValue<TripDashboardStats>>(
      dispatcherDashboardStatsProvider(_today),
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            if (_isAuthenticationError(error)) {
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
      body: Stack(
        children: [
          // المحتوى الرئيسي
          context.isDesktop && !context.isTablet
              ? _buildDesktopLayout(user, statsAsync, _today)
              : _buildMobileLayout(user, statsAsync, _today),

          // 🎯 Overlay التحميل الأولي للمنصات التي تحتاجه
          if (PlatformUtils.needsInitialDataLoad && initialLoadState.isLoading)
            DispatcherInitialLoadWidget(
              asOverlay: true,
              onLoadComplete: () {
                // لا حاجة لتحديث البيانات - الـ provider سيتحقق تلقائياً من الكاش
              },
            ),
        ],
      ),
    );
  }

  /// 🖥️ Desktop Layout with Smart Sidebar
  Widget _buildDesktopLayout(
    User? user,
    AsyncValue<TripDashboardStats> statsAsync,
    DateTime today,
  ) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(_today),
      color: AppColors.dispatcherPrimary,
      backgroundColor: Colors.white,
      child: Row(
        children: [
          // 📊 Main Content Area
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero Header
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

                // Role Switcher
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: RoleSwitcher(
                        isDispatcherMode: true,
                        onRoleChanged: (isDispatcher) {
                          // يتم التعامل مع التبديل داخل الـ widget
                        },
                      ),
                    ),
                  ),
                ),

                // Performance Insights - استخدام الـ TripDashboardStats مباشرة
                statsAsync.maybeWhen(
                  data: (stats) => SliverToBoxAdapter(
                    child: PerformanceInsights(stats: stats),
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
                  loading: () => SliverToBoxAdapter(
                    child: _buildLoadingState(),
                  ),
                  error: (error, _) => SliverToBoxAdapter(
                    child: _buildErrorState(error, today),
                  ),
                ),

                // Bottom Spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
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
      onRefresh: () => _refreshData(_today),
      color: AppColors.dispatcherPrimary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header
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
                    // يتم التعامل مع التبديل داخل الـ widget
                  },
                ),
              ),
            ),
          ),

          // Performance Insights - استخدام الـ TripDashboardStats مباشرة
          statsAsync.maybeWhen(
            data: (stats) => SliverToBoxAdapter(
              child: PerformanceInsights(stats: stats),
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
            loading: () => SliverToBoxAdapter(
              child: _buildLoadingState(),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: _buildErrorState(error, today),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  /// 🔄 Loading State Widget
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.dispatcherPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'جاري تحميل البيانات...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ❌ Error State Widget
  Widget _buildErrorState(Object error, DateTime today) {
    if (_isAuthenticationError(error)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAuthenticationError();
      });
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'حدث خطأ في تحميل البيانات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _refreshData(today),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dispatcherPrimary,
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
      await ref.read(authStateProvider.notifier).logout();
    } catch (e) {
      // Continue even if logout fails
    }

    if (mounted) {
      context.go(RoutePaths.login);
    }
  }

  /// Refresh data
  Future<void> _refreshData(DateTime today) async {
    // Haptic feedback للمنصات التي تدعمه
    if (PlatformUtils.supportsHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    final cache = ref.read(dispatcherCacheDataSourceProvider);
    final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;

    if (userId != 0) {
      // مسح بيانات الـ dashboard stats من الكاش
      await cache.delete(
        DispatcherCacheKeys.dashboardStats(userId: userId, date: today),
      );
    }

    // تحديث الـ providers
    ref.invalidate(dispatcherDashboardStatsProvider(today));

    // تحديث بيانات الرحلات
    final todayFilters = TripFilters(
      fromDate: today,
      toDate: DateTime(today.year, today.month, today.day, 23, 59, 59),
    );
    ref.invalidate(dispatcherTripsProvider(todayFilters));

    // تحديث بيانات المركبات والسائقين
    ref.invalidate(dispatcherVehiclesProvider);
    ref.invalidate(driversProvider);

    // إذا كانت المنصة تدعم التحميل الأولي وكان مكتملاً، نحدث البيانات المحفوظة
    if (PlatformUtils.needsInitialDataLoad) {
      final loadState = ref.read(dispatcherInitialLoadProvider);
      if (loadState.isComplete && !loadState.hasError) {
        ref
            .read(dispatcherInitialLoadProvider.notifier)
            .startInitialLoad(forceRefresh: true);
      }
    }
  }
}
