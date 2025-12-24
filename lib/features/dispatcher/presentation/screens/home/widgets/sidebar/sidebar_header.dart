import 'package:bridgecore_flutter_starter/features/trips/presentation/providers/trip_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/utils/formatters.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../core/enums/enums.dart';
import '../../../../../../trips/domain/entities/trip.dart';
import '../../../../providers/dispatcher_cached_providers.dart';

class SidebarHeader extends ConsumerWidget {
  final bool isSidebarExpanded;
  final VoidCallback onToggle;
  final TripFilters todayFilters;
  final AsyncValue<List<Trip>> tripsAsync;

  const SidebarHeader({
    super.key,
    required this.isSidebarExpanded,
    required this.onToggle,
    required this.todayFilters,
    required this.tripsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tripCount = tripsAsync.maybeWhen(
      data: (trips) => trips.length,
      orElse: () => 0,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSidebarExpanded ? 20 : 12,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Toggle Button
          Material(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  isSidebarExpanded
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  color: AppColors.dispatcherPrimary,
                  size: 18,
                ),
              ),
            ),
          ),

          if (isSidebarExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.today_rounded,
                        color: AppColors.dispatcherPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.trips,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      // Trip Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.dispatcherGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dispatcherPrimary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$tripCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.displayDate(DateTime.now()),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Refresh Button
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.dispatcherPrimary,
                size: 20,
              ),
              tooltip: l10n.refresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(dispatcherTripsProvider(todayFilters));
              },
            ),
          ],
        ],
      ),
    );
  }
}
