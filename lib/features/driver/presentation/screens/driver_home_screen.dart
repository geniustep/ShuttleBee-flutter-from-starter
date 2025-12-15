import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../core/services/vehicle_heartbeat_background_service.dart';
import '../../../../core/services/live_tracking_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/cached_trip_provider.dart';

/// 🐝 ShuttleBee Driver Home Screen
/// صفحة السائق الرئيسية المميزة - تصميم عصري وجذاب
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  bool _hasPreloadedTrips = false;
  bool _hasInitializedAfterAuth = false;

  // === Animation Controllers ===
  late AnimationController _pulseController;

  // === Riverpod Subscription ===
  ProviderSubscription<AsyncValue>? _authSubscription;

  // Background heartbeat (Android foreground service)
  bool _heartbeatStarted = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Setup auth listener after first frame to ensure ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthListener();
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  /// Setup auth state listener using listenManual for better performance
  void _setupAuthListener() {
    _authSubscription = ref.listenManual(
      authStateProvider,
      (previous, next) {
        if (_hasInitializedAfterAuth) return;
        if (next.isLoading) return;
        final user = next.asData?.value.user;
        if (user == null) return;

        _hasInitializedAfterAuth = true;
        _initializeTrips();
      },
      fireImmediately: true,
    );
  }

  /// Initialize trips after auth is ready
  Future<void> _initializeTrips() async {
    await _preloadTodayTrips();
    _loadSelectedDate();
    _startHeartbeat();
  }

  /// 🚌 تحميل رحلات اليوم مسبقاً للكاش مع الركاب
  /// ⚠️ إجبارية: يجب تخزين الركاب مع كل رحلة
  /// ملاحظة: لا نمسح الكاش حتى لا نفقد البيانات أثناء التحميل
  Future<void> _preloadTodayTrips() async {
    if (_hasPreloadedTrips) return;
    _hasPreloadedTrips = true;

    try {
      final today = DateTime.now();

      // Sync from server ONCE on enter (if online) and cache trips + passengers.
      // After that, UI reads 100% from cache (no auto-refresh).
      await ref
          .read(smartDriverTripsProvider.notifier)
          .syncTripsWithPassengers(today);
    } catch (e) {
      // تجاهل الأخطاء - التحميل المسبق اختياري
      debugPrint('⚠️ Failed to preload trips: $e');
    }
  }

  void _loadSelectedDate() {
    ref.read(smartDriverTripsProvider.notifier).loadTrips(_selectedDate);
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _pulseController.dispose();
    super.dispose();
  }

  void _startHeartbeat() {
    if (_heartbeatStarted) return;
    _heartbeatStarted = true;

    // Android foreground-service heartbeat (works in background).
    VehicleHeartbeatBackgroundService.start();

    // 🚀 اتصال WebSocket للتتبع الحي (Live Tracking)
    _connectLiveTracking();
  }

  /// الاتصال بخدمة التتبع الحي
  Future<void> _connectLiveTracking() async {
    // تأخير الاتصال لتجنب تعديل الـ provider أثناء build
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    try {
      await ref.read(driverLiveTrackingProvider.notifier).connect();
      debugPrint('✅ [DriverHome] Live tracking connected successfully');
    } catch (e) {
      // WebSocket غير متاح حالياً - سيتم إعادة المحاولة تلقائياً
      debugPrint(
        '⚠️ [DriverHome] Live tracking unavailable (will retry): $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Wait for auth state to be ready before loading trips
    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _buildLoadingState(),
      );
    }

    final userName = authState.asData?.value.user?.name ?? 'السائق';

    // استخدام smartDriverTripsProvider للتحديثات الفورية
    final tripsState = ref.watch(smartDriverTripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === Hero Header ===
          _buildHeroHeader(userName, tripsState),

          // === Date Selector ===
          SliverToBoxAdapter(
            child: _buildDateSelector()
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(begin: 0.1, end: 0),
          ),

          // === Content ===
          _buildTripsContent(tripsState),
        ],
      ),
    );
  }

  /// بناء محتوى الرحلات بناءً على الحالة
  Widget _buildTripsContent(SmartDriverTripsState tripsState) {
    // حالة التحميل الأولي
    if (tripsState.isLoading && !tripsState.hasData) {
      return SliverFillRemaining(
        child: _buildTripsLoadingState(),
      );
    }

    // حالة الخطأ (بدون بيانات)
    if (tripsState.hasError && !tripsState.hasData) {
      return SliverFillRemaining(
        child: _buildErrorState(
          _getErrorMessage(tripsState.error ?? 'حدث خطأ غير معروف'),
        ),
      );
    }

    // Empty (no error)
    if (tripsState.trips.isEmpty) {
      final isTodaySelected = _isToday(_selectedDate);
      if (isTodaySelected && tripsState.isFromCache) {
        return SliverList(
          delegate: SliverChildListDelegate([
            _buildStatistics(const []),
            const SizedBox(height: 24),
            _buildEmptyState(
              title: 'لا توجد بيانات مخزنة لليوم',
              message: 'اضغط تحديث لمزامنة رحلات اليوم وحفظها محلياً مع الركاب',
              buttonText: 'تحديث رحلات اليوم',
              onPressed: () =>
                  ref.read(smartDriverTripsProvider.notifier).refresh(),
              icon: Icons.cloud_sync_rounded,
            ),
          ]),
        );
      }

      return SliverList(
        delegate: SliverChildListDelegate([
          _buildStatistics(const []),
          const SizedBox(height: 24),
          _buildEmptyState(
            title: 'لا توجد رحلات',
            message:
                'لا توجد رحلات مجدولة في هذا التاريخ\nاختر تاريخاً آخر لعرض الرحلات',
            buttonText: 'اختر تاريخ آخر',
            onPressed: _selectDate,
            icon: Icons.calendar_today_rounded,
          ),
        ]),
      );
    }

    // عرض البيانات (مع مؤشر المزامنة إذا كان يحدث)
    return _buildContent(tripsState.trips);
  }

  // ============================================================
  // 🎨 HERO HEADER
  // ============================================================
  Widget _buildHeroHeader(String userName, SmartDriverTripsState tripsState) {
    final isRefreshing = tripsState.isLoading || tripsState.isSyncing;
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      actions: [
        const RoleSwitcherButton(),
        _buildHeaderButton(
          icon: Icons.calendar_today_rounded,
          onPressed: _selectDate,
          tooltip: 'اختر التاريخ',
        ),
        _buildHeaderButton(
          icon: Icons.settings_rounded,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(RoutePaths.settings);
          },
          tooltip: 'الإعدادات',
        ),
        _buildHeaderButton(
          icon: isRefreshing ? Icons.more_horiz_rounded : Icons.refresh_rounded,
          onPressed: isRefreshing
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  ref.read(smartDriverTripsProvider.notifier).refresh();
                },
          tooltip: 'تحديث',
        ),
        _buildHeaderButton(
          icon: Icons.logout_rounded,
          onPressed: () => _showLogoutDialog(context, ref),
          tooltip: 'تسجيل الخروج',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // === Gradient Background ===
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E88E5),
                    Color(0xFF1565C0),
                    Color(0xFF0D47A1),
                  ],
                ),
              ),
            ),

            // === Pattern Overlay ===
            Positioned.fill(
              child: CustomPaint(
                painter: _HexagonPatternPainter(),
              ),
            ),

            // === Content ===
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // === Live Tracking Status Badge ===
                    _buildLiveTrackingBadge(),
                    const SizedBox(height: 12),

                    // === Welcome Text ===
                    Text(
                      'مرحباً، $userName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // === Date ===
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEEE، d MMMM yyyy', 'ar')
                              .format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: icon == Icons.more_horiz_rounded && onPressed == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  // ============================================================
  // 📅 DATE SELECTOR
  // ============================================================
  Widget _buildDateSelector() {
    final isToday = _isToday(_selectedDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedNormalized =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final canGoToTomorrow = selectedNormalized.isBefore(tomorrow);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: ui.TextDirection.rtl,
        children: [
          // زر الغد (كان مقلوب سابقاً)
          _buildDateNavButton(
            icon: Icons.chevron_right_rounded,
            onPressed: canGoToTomorrow
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1));
                    });
                    _loadSelectedDate();
                  }
                : null,
          ),

          // Date display
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isToday
                      ? LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.primaryLight.withValues(alpha: 0.1),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'اليوم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    Text(
                      DateFormat('EEEE', 'ar').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isToday ? AppColors.primary : AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy', 'ar').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday
                            ? AppColors.primary.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // زر الأمس
          _buildDateNavButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadSelectedDate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: isEnabled
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.3),
            size: 28,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📊 STATISTICS
  // ============================================================
  Widget _buildStatistics(List<Trip> trips) {
    final ongoingCount = trips.where((t) => t.state.isOngoing).length;
    final completedCount = trips.where((t) => t.state.isCompleted).length;

    // حساب الركاب الفريدين (بدون تكرار)
    // نحسب من trip.lines إذا كانت محملة، وإلا نستخدم trip.totalPassengers
    final uniquePassengerIds = <int>{};
    int fallbackTotal = 0; // للرحلات التي لا تحتوي على lines محملة
    bool hasLinesData = false; // هل لدينا بيانات lines محملة؟

    for (final trip in trips) {
      if (trip.lines.isNotEmpty) {
        // إذا كانت lines محملة، نستخدمها لحساب الركاب الفريدين
        hasLinesData = true;
        for (final line in trip.lines) {
          if (line.passengerId != null) {
            uniquePassengerIds.add(line.passengerId!);
          }
        }
      } else {
        // إذا كانت lines فارغة، نستخدم totalPassengers كبديل
        // لكن هذا لن يعطينا الركاب الفريدين عبر الرحلات
        // لذلك نضيفهم كرقم إجمالي (مع العلم أنه قد يكون هناك تكرار)
        if (trip.totalPassengers > 0) {
          fallbackTotal += trip.totalPassengers;
        }
      }
    }

    // إذا كان لدينا lines محملة، نستخدم الركاب الفريدين
    // وإلا نستخدم المجموع (مع العلم أنه قد يكون هناك تكرار)
    final totalPassengers =
        hasLinesData ? uniquePassengerIds.length : fallbackTotal;

    // Debug: طباعة معلومات للتشخيص (فقط في وضع التطوير)
    if (kDebugMode && trips.isNotEmpty) {
      final tripsWithLines = trips.where((t) => t.lines.isNotEmpty).length;
      final tripsWithoutLines = trips.where((t) => t.lines.isEmpty).length;
      final tripsWithPassengers =
          trips.where((t) => t.totalPassengers > 0).length;
      debugPrint(
        '📊 Statistics: ${trips.length} trips, $tripsWithLines with lines, $tripsWithoutLines without lines, $tripsWithPassengers with totalPassengers > 0, calculated passengers: $totalPassengers',
      );

      // إذا كان العدد 0، نطبع تفاصيل أكثر
      if (totalPassengers == 0) {
        for (final trip in trips) {
          debugPrint(
            '  - Trip ${trip.id}: lines=${trip.lines.length}, totalPassengers=${trip.totalPassengers}',
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.route_rounded,
              label: 'الرحلات',
              value: '${trips.length}',
              color: AppColors.primary,
              delay: 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.play_circle_rounded,
              label: 'جارية',
              value: '$ongoingCount',
              color: const Color(0xFFF59E0B),
              delay: 50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_rounded,
              label: 'مكتملة',
              value: '$completedCount',
              color: const Color(0xFF10B981),
              delay: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_alt_rounded,
              label: 'الركاب',
              value: '$totalPassengers',
              color: const Color(0xFF8B5CF6),
              delay: 150,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (200 + delay).ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: (200 + delay).ms,
        );
  }

  // ============================================================
  // 📋 CONTENT
  // ============================================================
  SliverList _buildContent(List<Trip> trips) {
    // Sort trips: ongoing first, then by time
    final sortedTrips = List<Trip>.from(trips)
      ..sort((a, b) {
        if (a.state.isOngoing && !b.state.isOngoing) return -1;
        if (!a.state.isOngoing && b.state.isOngoing) return 1;
        if (a.plannedStartTime != null && b.plannedStartTime != null) {
          return a.plannedStartTime!.compareTo(b.plannedStartTime!);
        }
        return 0;
      });

    final childCount = 4 + sortedTrips.length;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // With trips:
          // 0 stats, 1 spacer, 2 header, 3.. trips, last bottom spacer
          if (index == 0) return _buildStatistics(trips);
          if (index == 1) return const SizedBox(height: 24);
          if (index == 2) return _buildSectionHeader(trips);

          const tripStartIndex = 3;
          final tripEndExclusive = tripStartIndex + sortedTrips.length;
          if (index >= tripStartIndex && index < tripEndExclusive) {
            final tripIndex = index - tripStartIndex;
            final trip = sortedTrips[tripIndex];
            return _buildTripCard(trip, tripIndex);
          }

          return const SizedBox(height: 24);
        },
        childCount: childCount,
      ),
    );
  }

  Widget _buildSectionHeader(List<Trip> trips) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'رحلاتي',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${trips.length} رحلة',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  // ============================================================
  // 🚌 TRIP CARD
  // ============================================================
  Widget _buildTripCard(Trip trip, int index) {
    final isOngoing = trip.state.isOngoing;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('${RoutePaths.driverHome}/trip/${trip.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isOngoing
              ? Border.all(
                  color: trip.state.color.withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isOngoing
                  ? trip.state.color.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isOngoing ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // === Header with Status ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isOngoing
                    ? LinearGradient(
                        colors: [
                          trip.state.color.withValues(alpha: 0.1),
                          trip.state.color.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Badges Row ===
                  Row(
                    children: [
                      // State Badge
                      _buildTripStateBadge(trip),
                      const SizedBox(width: 8),
                      // Type Badge
                      _buildTripTypeBadge(trip),
                      const Spacer(),
                      // Time
                      if (trip.plannedStartTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('HH:mm')
                                    .format(trip.plannedStartTime!),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // === Trip Name ===
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // === Group & Vehicle ===
                  if (trip.groupName != null || trip.vehicleName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (trip.groupName != null) ...[
                          Icon(
                            Icons.group_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              trip.groupName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (trip.groupName != null && trip.vehicleName != null)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (trip.vehicleName != null) ...[
                          Icon(
                            Icons.directions_bus_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trip.vehicleName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // === Stats & Action Row ===
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Stats Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Passengers
                      _buildTripStat(
                        icon: Icons.people_alt_rounded,
                        value: '${trip.totalPassengers}',
                        label: 'راكب',
                        color: AppColors.primary,
                      ),

                      // Progress for ongoing trips
                      if (trip.state.isOngoing) ...[
                        const SizedBox(width: 12),
                        _buildTripStat(
                          icon: Icons.check_circle_rounded,
                          value: '${trip.boardedCount}',
                          label: 'صعدوا',
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        _buildTripStat(
                          icon: Icons.cancel_rounded,
                          value: '${trip.absentCount}',
                          label: 'غائب',
                          color: AppColors.error,
                        ),
                      ],

                      // Distance
                      if (trip.plannedDistance != null &&
                          !trip.state.isOngoing) ...[
                        const SizedBox(width: 12),
                        _buildTripStat(
                          icon: Icons.straighten_rounded,
                          value: trip.plannedDistance!.toStringAsFixed(1),
                          label: 'كم',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ],
                  ),

                  // Action Button
                  _buildTripActionButton(trip),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (350 + (index * 50)).ms).slideX(
          begin: 0.05,
          end: 0,
          duration: 400.ms,
          delay: (350 + (index * 50)).ms,
        );
  }

  Widget _buildTripStateBadge(Trip trip) {
    final isOngoing = trip.state.isOngoing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: trip.state.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOngoing)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.5 + (_pulseController.value * 0.5),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          Text(
            trip.state.arabicLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeBadge(Trip trip) {
    final isPickup = trip.tripType == TripType.pickup;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPickup
            ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
            : const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPickup
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: isPickup ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            trip.tripType.arabicLabel,
            style: TextStyle(
              color:
                  isPickup ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripActionButton(Trip trip) {
    if (trip.state.isOngoing) {
      return Material(
        color: trip.state.color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            // الذهاب للخريطة المباشرة الاحترافية
            context.go('${RoutePaths.driverHome}/trip/${trip.id}/live-map');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'الخريطة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (trip.state.canStart) {
      return Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.go('${RoutePaths.driverHome}/trip/${trip.id}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'بدء',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.textSecondary,
        size: 16,
      ),
    );
  }

  // ============================================================
  // 📡 LIVE TRACKING BADGE
  // ============================================================
  Widget _buildLiveTrackingBadge() {
    final liveTrackingState = ref.watch(driverLiveTrackingProvider);

    final isConnected = liveTrackingState.isConnected;
    final isAutoTracking = liveTrackingState.isAutoTracking;

    String statusText;
    Color statusColor;

    if (isAutoTracking) {
      statusText = 'تتبع حي 📍';
      statusColor = const Color(0xFFF59E0B); // Orange
    } else if (isConnected) {
      statusText = 'متصل الآن';
      statusColor = const Color(0xFF4CAF50); // Green
    } else if (liveTrackingState.isConnecting) {
      statusText = 'جاري الاتصال...';
      statusColor = const Color(0xFF2196F3); // Blue
    } else {
      statusText = 'غير متصل';
      statusColor = const Color(0xFFEF4444); // Red
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(
                        alpha: 0.5 + (_pulseController.value * 0.5),
                      ),
                      blurRadius: 4 + (_pulseController.value * 4),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔧 HELPER METHODS
  // ============================================================
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSelectedDate();
    }
  }

  String _getErrorMessage(Object error) {
    String message;

    if (error is Exception) {
      message = error.toString();
    } else {
      message = error.toString();
    }

    // Remove "Exception: " prefix if present
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    } else if (message.startsWith('Exception')) {
      message = message.replaceFirst('Exception', '').trim();
      if (message.isEmpty) {
        message = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
      }
    }

    // If message is empty or just "Exception", provide default
    if (message.isEmpty || message.trim() == 'Exception') {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    }

    return message;
  }

  // ============================================================
  // 🔄 STATES
  // ============================================================
  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, Color(0xFFF8FAFC)],
          stops: [0.0, 0.4],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'جاري تحميل البيانات...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'جاري تحميل الرحلات...',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label:
                Text(buttonText, style: const TextStyle(fontFamily: 'Cairo')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: 300.ms,
        );
  }

  Widget _buildErrorState(String error) {
    // Check if error requires re-login (session expired, invalid token, etc.)
    final requiresReLogin = ErrorTranslator.requiresReLoginFromMessage(error);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (requiresReLogin ? AppColors.warning : AppColors.error)
                .withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (requiresReLogin ? AppColors.warning : AppColors.error)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              requiresReLogin
                  ? Icons.lock_outline_rounded
                  : Icons.error_outline_rounded,
              size: 56,
              color: requiresReLogin ? AppColors.warning : AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            requiresReLogin ? 'انتهت الجلسة' : 'حدث خطأ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: requiresReLogin ? AppColors.warning : AppColors.error,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              error.isEmpty || error == 'Exception'
                  ? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى'
                  : error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (requiresReLogin)
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go(RoutePaths.login);
                }
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text(
                'تسجيل الدخول',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(smartDriverTripsProvider.notifier)
                    .loadTrips(_selectedDate);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 🚪 LOGOUT DIALOG
  // ============================================================
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
              if (context.mounted) {
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

// ============================================================
// 🎨 CUSTOM PAINTER FOR PATTERN
// ============================================================
class _HexagonPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 40.0;
    final rows = (size.height / spacing).ceil() + 1;
    final cols = (size.width / spacing).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final x = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final y = row * spacing * 0.866;
        _drawHexagon(canvas, Offset(x, y), 15, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
