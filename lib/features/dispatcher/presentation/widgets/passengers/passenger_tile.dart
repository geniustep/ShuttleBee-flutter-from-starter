import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/enums/trip_line_status.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../trips/domain/entities/trip.dart';

/// بطاقة عرض راكب واحد
class PassengerTile extends StatelessWidget {
  final TripLine passenger;
  final int index;
  final VoidCallback? onTap;

  const PassengerTile({
    super.key,
    required this.passenger,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // رقم الراكب
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: passenger.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: passenger.status.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // أيقونة الحالة
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: passenger.status.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: passenger.status.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(passenger.status),
                  color: passenger.status.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // معلومات الراكب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.passengerName ?? 'راكب #${passenger.id}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (passenger.passengerPhone != null)
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 12,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            passenger.passengerPhone!,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: passenger.status.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        passenger.status.arabicLabel,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: passenger.status.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // شارات إضافية
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (passenger.pickupLocationName != 'غير محدد')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: AppColors.dispatcherPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            passenger.pickupLocationName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'Cairo',
                              color: AppColors.dispatcherPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (passenger.hasGuardian) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.family_restroom_rounded,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ولي أمر',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Cairo',
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, delay: (50 * index).ms);
  }

  IconData _getStatusIcon(TripLineStatus status) {
    switch (status) {
      case TripLineStatus.pending:
        return Icons.hourglass_empty_rounded;
      case TripLineStatus.notStarted:
        return Icons.schedule_rounded;
      case TripLineStatus.boarded:
        return Icons.check_circle_rounded;
      case TripLineStatus.absent:
        return Icons.cancel_rounded;
      case TripLineStatus.dropped:
        return Icons.place_rounded;
    }
  }
}
