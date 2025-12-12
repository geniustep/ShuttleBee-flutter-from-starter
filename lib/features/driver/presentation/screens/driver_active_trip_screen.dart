import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/passenger_list_item.dart';

/// Driver Active Trip Screen - صفحة الرحلة النشطة للسائق
class DriverActiveTripScreen extends ConsumerStatefulWidget {
  final int tripId;

  const DriverActiveTripScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<DriverActiveTripScreen> createState() =>
      _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState
    extends ConsumerState<DriverActiveTripScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load trip on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeTripProvider.notifier).loadTrip(widget.tripId);
    });

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(activeTripProvider.notifier).loadTrip(widget.tripId);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الرحلة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              context.go(
                  '${RoutePaths.driverHome}/trip/${widget.tripId}/live-map');
            },
            tooltip: 'الخريطة المباشرة',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(activeTripProvider.notifier).loadTrip(widget.tripId);
            },
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return const Center(
              child: Text('لم يتم العثور على الرحلة'),
            );
          }

          return Column(
            children: [
              // Progress Banner
              _buildProgressBanner(trip),

              // Statistics Summary
              _buildStatisticsSummary(trip),

              const SizedBox(height: AppDimensions.sm),

              // Passengers List
              Expanded(
                child: trip.lines.isEmpty
                    ? const Center(
                        child: Text('لا يوجد ركاب في هذه الرحلة'),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref
                              .read(activeTripProvider.notifier)
                              .loadTrip(widget.tripId);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.md),
                          itemCount: trip.lines.length,
                          itemBuilder: (context, index) {
                            final passenger = trip.lines[index];
                            return PassengerListItem(
                              passenger: passenger,
                              isActive: true,
                              onBoarded: () => _markPassengerBoarded(
                                passenger.id,
                              ),
                              onAbsent: () => _markPassengerAbsent(
                                passenger.id,
                              ),
                              onDropped: () => _markPassengerDropped(
                                passenger.id,
                              ),
                            );
                          },
                        ),
                      ),
              ),

              // Complete Trip Button
              if (_canCompleteTrip(trip))
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _completeTrip(),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('إنهاء الرحلة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.all(AppDimensions.md),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const PassengerListShimmer(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppDimensions.md),
              Text(
                error.toString(),
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.md),
              ElevatedButton(
                onPressed: () {
                  ref.read(activeTripProvider.notifier).loadTrip(widget.tripId);
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBanner(trip) {
    final progress = trip.completionPercentage;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip.name,
                style: AppTypography.h5.copyWith(color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xxs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSummary(trip) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'مجموع الركاب',
              '${trip.totalPassengers}',
              Icons.people,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _buildStatCard(
              'صعد',
              '${trip.boardedCount}',
              Icons.check_circle,
              AppColors.success,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _buildStatCard(
              'غائب',
              '${trip.absentCount}',
              Icons.cancel,
              AppColors.error,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _buildStatCard(
              'نزل',
              '${trip.droppedCount}',
              Icons.location_on,
              AppColors.warning,
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
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppDimensions.xxs),
          Text(
            value,
            style: AppTypography.h6.copyWith(color: color),
          ),
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

  Future<void> _markPassengerBoarded(int tripLineId) async {
    final notifier = ref.read(activeTripProvider.notifier);
    final success = await notifier.markPassengerBoarded(tripLineId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حالة الراكب إلى: صعد'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحديث حالة الراكب'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _markPassengerAbsent(int tripLineId) async {
    final notifier = ref.read(activeTripProvider.notifier);
    final success = await notifier.markPassengerAbsent(tripLineId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حالة الراكب إلى: غائب'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 1),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحديث حالة الراكب'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _markPassengerDropped(int tripLineId) async {
    final notifier = ref.read(activeTripProvider.notifier);
    final success = await notifier.markPassengerDropped(tripLineId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حالة الراكب إلى: نزل'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحديث حالة الراكب'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool _canCompleteTrip(trip) {
    // Can complete if all passengers are either boarded, dropped, or absent
    return trip.remainingPassengers == 0 && trip.state.isOngoing;
  }

  Future<void> _completeTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الرحلة'),
        content: const Text('هل أنت متأكد من إنهاء الرحلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(activeTripProvider.notifier);
      final success = await notifier.completeTrip(widget.tripId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنهاء الرحلة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate back to driver home
        context.go(RoutePaths.driverHome);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إنهاء الرحلة. يرجى المحاولة مرة أخرى'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
