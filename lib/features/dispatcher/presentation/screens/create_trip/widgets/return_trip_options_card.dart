import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../l10n/app_localizations.dart';

class ReturnTripOptionsCard extends StatelessWidget {
  final bool createReturnTrip;
  final DateTime? returnTripStartTime;
  final DateTime? returnTripArrivalTime;
  final bool hasPassengers;
  final ValueChanged<bool> onCreateReturnTripChanged;
  final VoidCallback onReturnTripStartTimeSelect;
  final VoidCallback onReturnTripArrivalTimeSelect;

  const ReturnTripOptionsCard({
    super.key,
    required this.createReturnTrip,
    required this.returnTripStartTime,
    required this.returnTripArrivalTime,
    required this.hasPassengers,
    required this.onCreateReturnTripChanged,
    required this.onReturnTripStartTimeSelect,
    required this.onReturnTripArrivalTimeSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Row(
              children: [
                Checkbox(
                  value: createReturnTrip,
                  onChanged: hasPassengers
                      ? (value) => onCreateReturnTripChanged(value ?? false)
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.createReturnTripRoundTrip,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          color: hasPassengers ? null : AppColors.textSecondary,
                        ),
                      ),
                      if (!hasPassengers)
                        Text(
                          l10n.addPassengersFirstToEnableReturnTrip,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!hasPassengers && !createReturnTrip)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.addPassengersFirstToEnableReturnTrip,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (createReturnTrip) ...[
              const SizedBox(height: 16),
              Text(
                l10n.createReturnTripDesc,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // Start Time
              InkWell(
                onTap: onReturnTripStartTimeSelect,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.dispatcherPrimary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.returnTripStartTime} *',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              returnTripStartTime != null
                                  ? Formatters.displayDateTime(
                                      returnTripStartTime!,
                                    )
                                  : l10n.selectTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Arrival Time (optional)
              InkWell(
                onTap: onReturnTripArrivalTimeSelect,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        color: AppColors.dispatcherPrimary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.returnTripArrivalTime} (${l10n.optional})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              returnTripArrivalTime != null
                                  ? Formatters.displayDateTime(
                                      returnTripArrivalTime!,
                                    )
                                  : l10n.selectTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }
}
