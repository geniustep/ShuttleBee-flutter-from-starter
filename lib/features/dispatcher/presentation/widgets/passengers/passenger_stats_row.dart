import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../trips/domain/entities/trip.dart';

/// صف إحصائيات الركاب
class PassengerStatsRow extends StatelessWidget {
  final Trip trip;

  const PassengerStatsRow({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              icon: Icons.check_circle_rounded,
              label: 'صعد',
              count: trip.boardedCount,
              total: trip.totalPassengers,
              color: AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: _buildStatChip(
              icon: Icons.cancel_rounded,
              label: 'غائب',
              count: trip.absentCount,
              total: trip.totalPassengers,
              color: AppColors.error,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: _buildStatChip(
              icon: Icons.place_rounded,
              label: 'نزل',
              count: trip.droppedCount,
              total: trip.totalPassengers,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          Formatters.formatSimple(count),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'Cairo',
            color: AppColors.textSecondary,
          ),
        ),
        if (total > 0)
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'Cairo',
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
