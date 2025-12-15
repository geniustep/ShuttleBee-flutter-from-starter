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
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../shared/widgets/common/hero_header.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Passenger Home Screen - الصفحة الرئيسية للراكب - ShuttleBee
/// تصميم احترافي مطابق لمستوى صفحة السائق
class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen>
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
    final tripsAsync = ref.watch(passengerTripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(passengerTripsProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // === Hero Header ===
            _buildHeroHeader(user, tripsAsync),

            // === Role Switcher ===
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: RoleSwitcherWidget(),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ),

            // === Content ===
            tripsAsync.when(
              data: (trips) => _buildTripsContent(trips),
              loading: () => SliverFillRemaining(
                child: _buildLoadingState(),
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

  Widget _buildHeroHeader(User? user, AsyncValue<List<Trip>> tripsAsync) {
    final isRefreshing = tripsAsync.isLoading;

    return HeroHeader(
      title: 'مرحباً',
      userName: user?.name ?? 'الراكب',
      subtitle: DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
      gradientColors: HeroGradients.passenger,
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
            ref.invalidate(passengerTripsProvider);
          },
        ),
        HeroHeaderAction(
          icon: Icons.settings_rounded,
          tooltip: 'الإعدادات',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(RoutePaths.settings);
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

  SliverList _buildTripsContent(List<Trip> trips) {
    final today = DateTime.now();
    final todayTrips = trips
        .where(
          (t) =>
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .toList();
    final upcomingTrips = trips.where((t) => t.date.isAfter(today)).toList();
    final activeTrip = trips.where((t) => t.state.isOngoing).firstOrNull;

    return SliverList(
      delegate: SliverChildListDelegate([
        // === Active Trip Card ===
        if (activeTrip != null) ...[
          _buildSectionHeader(
            'الرحلة النشطة',
            null,
            Icons.navigation_rounded,
            AppColors.success,
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 12),
          _buildActiveTripCard(activeTrip),
          const SizedBox(height: 24),
        ],

        // === Today's Trips ===
        if (todayTrips.isNotEmpty) ...[
          _buildSectionHeader(
            'رحلات اليوم',
            '${todayTrips.length} رحلة',
            Icons.today_rounded,
            AppColors.primary,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 12),
          ...todayTrips.asMap().entries.map(
                (entry) => _buildTripCard(entry.value, entry.key),
              ),
          const SizedBox(height: 24),
        ],

        // === Upcoming Trips ===
        if (upcomingTrips.isNotEmpty) ...[
          _buildSectionHeader(
            'الرحلات القادمة',
            '${upcomingTrips.length} رحلة',
            Icons.event_rounded,
            AppColors.warning,
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
          const SizedBox(height: 12),
          ...upcomingTrips.take(5).toList().asMap().entries.map(
                (entry) =>
                    _buildTripCard(entry.value, entry.key + todayTrips.length),
              ),
          const SizedBox(height: 24),
        ],

        // === Empty State ===
        if (trips.isEmpty) ...[
          const SizedBox(height: 48),
          _buildEmptyState(),
        ],

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

  Widget _buildActiveTripCard(Trip trip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('${RoutePaths.passengerHome}/track/${trip.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF388E3C).withValues(alpha: 0.3),
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
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 24 + (_pulseController.value * 2),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .fadeIn(duration: 500.ms)
                                .fadeOut(duration: 500.ms),
                            const SizedBox(width: 8),
                            Text(
                              'الرحلة جارية الآن',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActiveInfoItem(
                    Icons.directions_bus_rounded,
                    trip.vehicleName ?? 'المركبة',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  _buildActiveInfoItem(
                    Icons.person_rounded,
                    trip.driverName ?? 'السائق',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  _buildActiveInfoItem(
                    trip.tripType == TripType.pickup
                        ? Icons.arrow_circle_up_rounded
                        : Icons.arrow_circle_down_rounded,
                    trip.tripType.arabicLabel,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, color: Color(0xFF388E3C)),
                    SizedBox(width: 8),
                    Text(
                      'تتبع الرحلة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF388E3C),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: 200.ms,
        );
  }

  Widget _buildActiveInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
            fontFamily: 'Cairo',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTripCard(Trip trip, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (trip.state.isOngoing) {
              context.go('${RoutePaths.passengerHome}/track/${trip.id}');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: trip.tripType == TripType.pickup
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    trip.tripType == TripType.pickup
                        ? Icons.arrow_circle_up_rounded
                        : Icons.arrow_circle_down_rounded,
                    color: trip.tripType == TripType.pickup
                        ? AppColors.primary
                        : AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMMM', 'ar').format(trip.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (trip.plannedStartTime != null) ...[
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
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: trip.state.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trip.state.arabicLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: trip.state.color,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (250 + index * 50).ms).slideX(
          begin: 0.05,
          end: 0,
          duration: 300.ms,
          delay: (250 + index * 50).ms,
        );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 64,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد رحلات مجدولة',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض رحلاتك هنا عندما تكون متاحة',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) => const ShimmerCard(height: 100)),
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
              onPressed: () => ref.invalidate(passengerTripsProvider),
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
