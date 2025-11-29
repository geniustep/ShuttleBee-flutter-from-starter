import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trips/domain/entities/trip.dart';

/// Trip Info Card - بطاقة معلومات الرحلة
class TripInfoCard extends StatelessWidget {
  final Trip trip;

  const TripInfoCard({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header with status badge
          Row(
            children: [
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

          const SizedBox(height: AppDimensions.md),

          // Trip Type
          _buildInfoRow(
            icon: trip.tripType.value == 'pickup'
                ? Icons.arrow_circle_up
                : Icons.arrow_circle_down,
            label: 'نوع الرحلة',
            value: trip.tripType.arabicLabel,
            color: trip.tripType.value == 'pickup'
                ? AppColors.primary
                : AppColors.success,
          ),

          const SizedBox(height: AppDimensions.sm),

          // Date
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'التاريخ',
            value: DateFormat('EEEE، d MMMM yyyy', 'ar').format(trip.date),
          ),

          const SizedBox(height: AppDimensions.sm),

          // Time Range
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'الوقت',
            value: _getTimeRange(),
          ),

          if (trip.groupName != null) ...[
            const SizedBox(height: AppDimensions.sm),
            _buildInfoRow(
              icon: Icons.group,
              label: 'المجموعة',
              value: trip.groupName!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
        const SizedBox(width: AppDimensions.sm),
        Text('$label: ', style: AppTypography.bodySmall),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeRange() {
    if (trip.plannedStartTime == null || trip.plannedArrivalTime == null) {
      return 'غير محدد';
    }

    final start = DateFormat('HH:mm').format(trip.plannedStartTime!);
    final end = DateFormat('HH:mm').format(trip.plannedArrivalTime!);
    return '$start - $end';
  }
}
