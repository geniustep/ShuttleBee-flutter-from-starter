import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Passenger Home Screen - الصفحة الرئيسية للراكب - ShuttleBee
class PassengerHomeScreen extends ConsumerWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;
    final tripsAsync = ref.watch(passengerTripsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('رحلاتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, ref),
            tooltip: 'تسجيل خروج',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(passengerTripsProvider);
        },
        child: tripsAsync.when(
          data: (trips) => _buildContent(context, user, trips),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(context, ref, error.toString()),
        ),
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
            onPressed: () => ref.invalidate(passengerTripsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, user, List<Trip> trips) {
    final today = DateTime.now();
    final todayTrips = trips
        .where((t) =>
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day)
        .toList();
    final upcomingTrips = trips.where((t) => t.date.isAfter(today)).toList();
    final activeTrip = trips.where((t) => t.state.isOngoing).firstOrNull;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          _buildUserHeader(user),

          const SizedBox(height: AppDimensions.lg),

          // Active Trip (if any)
          if (activeTrip != null) ...[
            Text('الرحلة النشطة', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildActiveTripCard(context, activeTrip),
            const SizedBox(height: AppDimensions.lg),
          ],

          // Today's Trips
          if (todayTrips.isNotEmpty) ...[
            Text('رحلات اليوم', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            ...todayTrips.map((trip) => _buildTripCard(context, trip)),
            const SizedBox(height: AppDimensions.lg),
          ],

          // Upcoming Trips
          if (upcomingTrips.isNotEmpty) ...[
            Text('الرحلات القادمة', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            ...upcomingTrips
                .take(5)
                .map((trip) => _buildTripCard(context, trip)),
          ],

          // Empty State
          if (trips.isEmpty) ...[
            const SizedBox(height: AppDimensions.xxl),
            _buildEmptyState(),
          ],
        ],
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
              backgroundColor: AppColors.success,
              child: Text(
                user?.name?.substring(0, 1).toUpperCase() ?? 'P',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'راكب', style: AppTypography.h4),
                  const SizedBox(height: 4),
                  Text(
                    'راكب',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.person, size: 32, color: AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(BuildContext context, Trip trip) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () {
          context.go('${RoutePaths.passengerHome}/track/${trip.id}');
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.name, style: AppTypography.h5),
                        const SizedBox(height: 4),
                        Text(
                          'الرحلة جارية',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      trip.tripType == TripType.pickup
                          ? Icons.arrow_circle_up
                          : Icons.arrow_circle_down,
                      size: 20,
                      color: trip.tripType == TripType.pickup
                          ? AppColors.primary
                          : AppColors.success,
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Text(trip.tripType.arabicLabel,
                        style: AppTypography.bodyMedium),
                    const Spacer(),
                    if (trip.vehicleName != null) ...[
                      const Icon(Icons.directions_bus, size: 16),
                      const SizedBox(width: 4),
                      Text(trip.vehicleName!, style: AppTypography.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('${RoutePaths.passengerHome}/track/${trip.id}');
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('تتبع الرحلة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  trip.tripType == TripType.pickup
                      ? Icons.arrow_circle_up
                      : Icons.arrow_circle_down,
                  size: 24,
                  color: trip.tripType == TripType.pickup
                      ? AppColors.primary
                      : AppColors.success,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(trip.name, style: AppTypography.h5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: AppDimensions.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: trip.state.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    trip.state.arabicLabel,
                    style: AppTypography.caption.copyWith(
                      color: trip.state.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(trip.date),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            if (trip.plannedStartTime != null) ...[
              const SizedBox(height: AppDimensions.xxs),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(trip.plannedStartTime!),
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ],
            if (trip.vehicleName != null) ...[
              const SizedBox(height: AppDimensions.xxs),
              Row(
                children: [
                  const Icon(Icons.directions_bus,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(trip.vehicleName!, style: AppTypography.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
          const SizedBox(height: AppDimensions.md),
          Text(
            'لا توجد رحلات مجدولة',
            style: AppTypography.h4.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'سيتم عرض رحلاتك هنا عندما تكون متاحة',
            style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
