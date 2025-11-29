import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trips/domain/entities/trip.dart';

/// Passenger List Item - عنصر قائمة الركاب
class PassengerListItem extends StatelessWidget {
  final TripLine passenger;
  final bool isActive;
  final VoidCallback? onBoarded;
  final VoidCallback? onAbsent;
  final VoidCallback? onDropped;

  const PassengerListItem({
    super.key,
    required this.passenger,
    this.isActive = false,
    this.onBoarded,
    this.onAbsent,
    this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
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
          // Header with status
          Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(AppDimensions.xs),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 20,
                ),
              ),

              const SizedBox(width: AppDimensions.sm),

              // Name
              Expanded(
                child: Text(
                  passenger.passengerName ?? 'راكب',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Sequence number
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  '#${passenger.sequence}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.sm),

          // Phone
          if (passenger.passengerPhone != null)
            InkWell(
              onTap: () => _makePhoneCall(passenger.passengerPhone!),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.xs),
                  Text(
                    passenger.passengerPhone!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),

          // Address
          if (passenger.address != null) ...[
            const SizedBox(height: AppDimensions.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.xs),
                Expanded(
                  child: Text(
                    passenger.address!,
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ],

          // Status badge
          const SizedBox(height: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xxs,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              passenger.status.arabicLabel,
              style: AppTypography.caption.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Action buttons (only show if active trip)
          if (isActive && _canShowActions()) ...[
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                if (passenger.status == TripLineStatus.notStarted ||
                    passenger.status == TripLineStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onBoarded,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('صعد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.xs,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAbsent,
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('غائب'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.xs,
                        ),
                      ),
                    ),
                  ),
                ],
                if (passenger.status == TripLineStatus.boarded)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDropped,
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text('نزل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.xs,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (passenger.status == TripLineStatus.boarded) {
      return AppColors.success;
    } else if (passenger.status == TripLineStatus.absent) {
      return AppColors.error;
    } else if (passenger.status == TripLineStatus.dropped) {
      return AppColors.textSecondary;
    }
    return Colors.grey[300]!;
  }

  Color _getStatusColor() {
    switch (passenger.status) {
      case TripLineStatus.boarded:
        return AppColors.success;
      case TripLineStatus.absent:
        return AppColors.error;
      case TripLineStatus.dropped:
        return AppColors.textSecondary;
      case TripLineStatus.pending:
      case TripLineStatus.notStarted:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon() {
    switch (passenger.status) {
      case TripLineStatus.boarded:
        return Icons.check_circle;
      case TripLineStatus.absent:
        return Icons.cancel;
      case TripLineStatus.dropped:
        return Icons.location_on;
      case TripLineStatus.pending:
      case TripLineStatus.notStarted:
        return Icons.schedule;
    }
  }

  bool _canShowActions() {
    return passenger.status == TripLineStatus.notStarted ||
        passenger.status == TripLineStatus.pending ||
        passenger.status == TripLineStatus.boarded;
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
