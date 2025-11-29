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
import '../widgets/loading_widgets.dart';

/// صفحة السائق الرئيسية - ShuttleBee
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.asData?.value.user?.name ?? 'السائق';
    final tripsAsync = ref.watch(driverDailyTripsProvider(_selectedDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('رحلاتي اليومية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'اختر التاريخ',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Banner
          _buildDateBanner(),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(driverDailyTripsProvider(_selectedDate));
              },
              child: tripsAsync.when(
                data: (trips) => Column(
                  children: [
                    // User Info Card
                    _buildUserInfoCard(userName),

                    // Statistics Summary
                    _buildStatistics(trips),

                    const SizedBox(height: AppDimensions.md),

                    // Trips List
                    Expanded(
                      child: _buildTripsList(context, trips),
                    ),
                  ],
                ),
                loading: () => Column(
                  children: [
                    // User Info Card
                    _buildUserInfoCard(userName),
                    // Statistics shimmer
                    const StatisticsShimmer(),
                    const SizedBox(height: AppDimensions.md),
                    // Trips list shimmer
                    const Expanded(child: TripsListShimmer()),
                  ],
                ),
                error: (error, stackTrace) => Column(
                  children: [
                    // User Info Card
                    _buildUserInfoCard(userName),
                    // Error state
                    Expanded(
                      child: _buildErrorState(
                          context, ref, _getErrorMessage(error)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBanner() {
    final isToday = _isToday(_selectedDate);

    return Container(
      color:
          isToday ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[200],
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous day button
          if (!isToday)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () {
                setState(() {
                  _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1));
                });
              },
            ),

          // Date display
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              child: Center(
                child: Text(
                  isToday
                      ? 'اليوم - ${DateFormat('d MMMM yyyy', 'ar').format(_selectedDate)}'
                      : DateFormat('EEEE، d MMMM yyyy', 'ar')
                          .format(_selectedDate),
                  style: AppTypography.h6.copyWith(
                    color: isToday ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),

          // Next day button
          if (!_isFuture(_selectedDate))
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
              },
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(today) || checkDate.isAtSameMomentAs(today);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              'حدث خطأ',
              style: AppTypography.h5.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
              child: Text(
                error.isEmpty || error == 'Exception'
                    ? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى'
                    : error,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(driverDailyTripsProvider(_selectedDate));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String userName) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
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
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(List<Trip> trips) {
    final ongoingCount = trips.where((t) => t.state.isOngoing).length;
    final completedCount = trips.where((t) => t.state.isCompleted).length;
    final plannedCount = trips.where((t) => t.state.canStart).length;
    final totalPassengers =
        trips.fold<int>(0, (sum, t) => sum + t.totalPassengers);
    final boardedPassengers =
        trips.fold<int>(0, (sum, t) => sum + t.boardedCount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'مخططة',
                  '$plannedCount',
                  Icons.schedule,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: _buildStatCard(
                  'إجمالي الركاب',
                  '$totalPassengers',
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: _buildStatCard(
                  'صعدوا',
                  '$boardedPassengers',
                  Icons.person_add,
                  AppColors.success,
                ),
              ),
            ],
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
              'لا توجد رحلات في هذا التاريخ',
              style: AppTypography.h5.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'اختر تاريخاً آخر لعرض الرحلات',
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
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
              Row(
                children: [
                  Expanded(
                    child: Text(trip.name, style: AppTypography.h5),
                  ),
                  if (trip.vehicleName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.xxs,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_bus,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            trip.vehicleName!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppDimensions.xxs),

              // Group Name
              if (trip.groupName != null)
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Colors.grey),
                    const SizedBox(width: AppDimensions.xxs),
                    Expanded(
                      child: Text(
                        trip.groupName!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
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
                  if (trip.plannedDistance != null) ...[
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.straighten,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.plannedDistance!.toStringAsFixed(1)} كم',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.xxs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'صعد: ${trip.boardedCount}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.xxs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, size: 12, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            'غائب: ${trip.absentCount}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trip.droppedCount > 0) ...[
                      const SizedBox(width: AppDimensions.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.xxs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off,
                                size: 12, color: AppColors.info),
                            const SizedBox(width: 4),
                            Text(
                              'نزل: ${trip.droppedCount}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),

              // Action Buttons
              if (trip.state.canStart || trip.state.isOngoing) ...[
                const SizedBox(height: AppDimensions.md),
                Row(
                  children: [
                    if (trip.state.isOngoing) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.go(
                                '${RoutePaths.driverHome}/trip/${trip.id}/active');
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('الخريطة المباشرة'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                    ],
                    Expanded(
                      flex: trip.state.isOngoing ? 1 : 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context
                              .go('${RoutePaths.driverHome}/trip/${trip.id}');
                        },
                        icon: Icon(
                          trip.state.canStart
                              ? Icons.play_arrow
                              : Icons.edit_location,
                          size: 18,
                        ),
                        label: Text(
                          trip.state.canStart ? 'بدء الرحلة' : 'إدارة الرحلة',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trip.state.canStart
                              ? AppColors.primary
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
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
