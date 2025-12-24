import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/enums/enums.dart';
import '../../../../../../trips/domain/entities/trip.dart';

class SidebarStats extends ConsumerWidget {
  final AsyncValue<List<Trip>> tripsAsync;

  const SidebarStats({
    super.key,
    required this.tripsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return tripsAsync.maybeWhen(
      data: (trips) {
        final ongoingCount =
            trips.where((t) => t.state == TripState.ongoing).length;
        final plannedCount =
            trips.where((t) => t.state == TripState.planned).length;
        final completedCount =
            trips.where((t) => t.state == TripState.done).length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.dispatcherPrimary.withValues(alpha: 0.08),
                AppColors.dispatcherPrimary.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.dispatcherPrimary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                icon: Icons.play_circle_rounded,
                value: '$ongoingCount',
                color: AppColors.warning,
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.dispatcherPrimary.withValues(alpha: 0.15),
              ),
              _buildMiniStat(
                icon: Icons.schedule_rounded,
                value: '$plannedCount',
                color: AppColors.primary,
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.dispatcherPrimary.withValues(alpha: 0.15),
              ),
              _buildMiniStat(
                icon: Icons.check_circle_rounded,
                value: '$completedCount',
                color: AppColors.success,
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
