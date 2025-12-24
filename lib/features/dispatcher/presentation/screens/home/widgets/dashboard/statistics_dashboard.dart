import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../trips/domain/repositories/trip_repository.dart';
import '../common/section_header.dart';
import 'today_statistics.dart';
import 'fleet_status.dart';
import 'active_trips_card.dart';

class StatisticsDashboard extends StatelessWidget {
  final TripDashboardStats stats;
  final DateTime today;

  const StatisticsDashboard({
    super.key,
    required this.stats,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final padding = context.responsive(
      mobile: 16.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    final sectionSpacing = context.responsive(
      mobile: 24.0,
      tablet: 32.0,
      desktop: 40.0,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          children: [
            // Today's Statistics
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: SectionHeader(
                title: l10n.todayStatistics,
                subtitle: _formatDate(context, DateTime.now()),
                icon: Icons.today_rounded,
                color: AppColors.primary,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            SizedBox(
              height: context.responsive(
                mobile: 12.0,
                tablet: 16.0,
                desktop: 20.0,
              ),
            ),
            TodayStatistics(stats: stats),

            SizedBox(height: sectionSpacing),

            // Fleet Status
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: SectionHeader(
                title: l10n.fleetStatus,
                icon: Icons.local_shipping_rounded,
                color: AppColors.success,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

            SizedBox(
              height: context.responsive(
                mobile: 12.0,
                tablet: 16.0,
                desktop: 20.0,
              ),
            ),
            FleetStatus(stats: stats),

            SizedBox(height: sectionSpacing),

            // Active Trips
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: SectionHeader(
                title: l10n.activeTrips,
                icon: Icons.play_circle_rounded,
                color: AppColors.warning,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

            SizedBox(
              height: context.responsive(
                mobile: 12.0,
                tablet: 16.0,
                desktop: 20.0,
              ),
            ),
            ActiveTripsCard(stats: stats),

            SizedBox(
              height: context.responsive(
                mobile: 32.0,
                tablet: 48.0,
                desktop: 64.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return l10n.today;
    } else if (dateOnly == yesterday) {
      return l10n.yesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
