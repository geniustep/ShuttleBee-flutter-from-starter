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

/// صفحة السائق الرئيسية - ShuttleBee
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.asData?.value.user?.name ?? 'السائق';
    final tripsAsync = ref.watch(driverDailyTripsProvider(DateTime.now()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('رحلاتي اليومية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverDailyTripsProvider(DateTime.now()));
        },
        child: Column(
          children: [
            // User Info Card
            _buildUserInfoCard(userName),

            // Statistics Summary
            tripsAsync.when(
              data: (trips) => _buildStatistics(trips),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppDimensions.md),

            // Trips List
            Expanded(
              child: tripsAsync.when(
                data: (trips) => _buildTripsList(context, trips),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    _buildErrorState(context, ref, error.toString()),
              ),
            ),
          ],
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
            onPressed: () =>
                ref.invalidate(driverDailyTripsProvider(DateTime.now())),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(String userName) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً، $userName',
            style: AppTypography.h4.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.xxs),
          Text(
            DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(List<Trip> trips) {
    final ongoingCount = trips.where((t) => t.state.isOngoing).length;
    final completedCount = trips.where((t) => t.state.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'مجموع الرحلات',
              '${trips.length}',
              Icons.route,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _buildStatCard(
              'الرحلات الجارية',
              '$ongoingCount',
              Icons.directions_bus,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _buildStatCard(
              'منتهية',
              '$completedCount',
              Icons.check_circle,
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppDimensions.xxs),
          Text(
            value,
            style: AppTypography.h4.copyWith(color: color),
          ),
          const SizedBox(height: AppDimensions.xxs),
          Text(
            title,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, List<Trip> trips) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppDimensions.md),
            Text(
              'لا توجد رحلات اليوم',
              style: AppTypography.h5.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'ستظهر رحلاتك هنا',
              style: AppTypography.bodyMedium.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _buildTripCard(context, trip);
      },
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      child: InkWell(
        onTap: () {
          context.go('${RoutePaths.driverHome}/trip/${trip.id}');
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Trip State Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm,
                      vertical: AppDimensions.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: trip.state.color.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      trip.state.arabicLabel,
                      style: AppTypography.caption.copyWith(
                        color: trip.state.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Trip Type Icon
                  Icon(
                    trip.tripType == TripType.pickup
                        ? Icons.arrow_circle_up
                        : Icons.arrow_circle_down,
                    color: trip.tripType == TripType.pickup
                        ? AppColors.primary
                        : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.xxs),
                  Text(
                    trip.tripType.arabicLabel,
                    style: AppTypography.caption.copyWith(
                      color: trip.tripType == TripType.pickup
                          ? AppColors.primary
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.sm),

              // Trip Name
              Text(trip.name, style: AppTypography.h5),

              const SizedBox(height: AppDimensions.xxs),

              // Group Name
              if (trip.groupName != null)
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Colors.grey),
                    const SizedBox(width: AppDimensions.xxs),
                    Text(
                      trip.groupName!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: AppDimensions.sm),

              // Time Info
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.xxs),
                  Text(
                    trip.plannedStartTime != null
                        ? DateFormat('HH:mm').format(trip.plannedStartTime!)
                        : '--:--',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    trip.plannedArrivalTime != null
                        ? DateFormat('HH:mm').format(trip.plannedArrivalTime!)
                        : '--:--',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.sm),

              // Passengers Info
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: AppDimensions.xxs),
                  Text(
                    '${trip.totalPassengers} راكب',
                    style: AppTypography.bodySmall,
                  ),
                  if (trip.state.isOngoing) ...[
                    const SizedBox(width: AppDimensions.md),
                    Text(
                      'صعد: ${trip.boardedCount}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Text(
                      'غائب: ${trip.absentCount}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),

              // Action Button
              if (trip.state.canStart || trip.state.isOngoing) ...[
                const SizedBox(height: AppDimensions.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('${RoutePaths.driverHome}/trip/${trip.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: trip.state.canStart
                          ? AppColors.primary
                          : AppColors.warning,
                    ),
                    child: Text(
                      trip.state.canStart ? 'بدء الرحلة' : 'إدارة الرحلة',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
}
