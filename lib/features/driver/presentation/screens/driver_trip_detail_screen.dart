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
import '../widgets/trip_info_card.dart';

/// Driver Trip Detail Screen - صفحة تفاصيل الرحلة للسائق
class DriverTripDetailScreen extends ConsumerWidget {
  final int tripId;

  const DriverTripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل الرحلة'),
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return const Center(
              child: Text('لم يتم العثور على الرحلة'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tripDetailProvider(tripId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Info Card
                  TripInfoCard(trip: trip),

                  const SizedBox(height: AppDimensions.md),

                  // Vehicle Info Card
                  _buildVehicleInfoCard(trip),

                  const SizedBox(height: AppDimensions.md),

                  // Route Info Card
                  _buildRouteInfoCard(trip),

                  const SizedBox(height: AppDimensions.md),

                  // Passengers Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة الركاب (${trip.totalPassengers})',
                        style: AppTypography.h5,
                      ),
                      if (trip.state.isOngoing)
                        Text(
                          '${trip.boardedCount + trip.droppedCount}/${trip.totalPassengers}',
                          style: AppTypography.h5.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.sm),

                  // Passengers List
                  if (trip.lines.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.lg),
                        child: Text('لا يوجد ركاب في هذه الرحلة'),
                      ),
                    )
                  else
                    ...trip.lines.map((passenger) => PassengerListItem(
                          passenger: passenger,
                          isActive: false,
                        )),

                  const SizedBox(height: AppDimensions.lg),

                  // Action Buttons
                  if (trip.state.canStart)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startTrip(context, ref),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('بدء الرحلة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.all(AppDimensions.md),
                        ),
                      ),
                    ),

                  if (trip.state.isOngoing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _manageTrip(context),
                        icon: const Icon(Icons.edit_location),
                        label: const Text('إدارة الرحلة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          padding: const EdgeInsets.all(AppDimensions.md),
                        ),
                      ),
                    ),

                  if (trip.state.canCancel) ...[
                    const SizedBox(height: AppDimensions.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelTrip(context, ref),
                        icon: const Icon(Icons.cancel),
                        label: const Text('إلغاء الرحلة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.all(AppDimensions.md),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const TripDetailShimmer(),
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
                onPressed: () => ref.invalidate(tripDetailProvider(tripId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(trip) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معلومات المركبة', style: AppTypography.h6),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              const Icon(Icons.directions_bus, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  trip.vehicleName ?? 'غير محدد',
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
          if (trip.vehiclePlateNumber != null) ...[
            const SizedBox(height: AppDimensions.xs),
            Row(
              children: [
                const Icon(Icons.confirmation_number, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  trip.vehiclePlateNumber!,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard(trip) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معلومات المسار', style: AppTypography.h6),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              const Icon(Icons.map, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'عدد المحطات: ${trip.lines.length}',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
          if (trip.plannedDistance != null) ...[
            const SizedBox(height: AppDimensions.xs),
            Row(
              children: [
                const Icon(Icons.straighten, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'المسافة المتوقعة: ${trip.plannedDistance!.toStringAsFixed(1)} كم',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startTrip(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بدء الرحلة'),
        content: const Text('هل أنت متأكد من بدء الرحلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بدء'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final notifier = ref.read(activeTripProvider.notifier);
      final success = await notifier.startTrip(tripId);

      if (success && context.mounted) {
        // Navigate to active trip screen
        context.go('${RoutePaths.driverHome}/trip/$tripId/active');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل بدء الرحلة. يرجى المحاولة مرة أخرى'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _manageTrip(BuildContext context) {
    context.go('${RoutePaths.driverHome}/trip/$tripId/active');
  }

  Future<void> _cancelTrip(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الرحلة'),
        content: const Text('هل أنت متأكد من إلغاء الرحلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final notifier = ref.read(activeTripProvider.notifier);
      final success = await notifier.cancelTrip(tripId);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الرحلة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إلغاء الرحلة. يرجى المحاولة مرة أخرى'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
