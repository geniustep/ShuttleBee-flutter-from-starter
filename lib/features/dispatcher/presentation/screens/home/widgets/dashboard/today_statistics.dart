import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../../core/utils/formatters.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../shared/widgets/common/stat_card.dart';
import '../../../../../../trips/domain/repositories/trip_repository.dart';

class TodayStatistics extends StatelessWidget {
  final TripDashboardStats stats;

  const TodayStatistics({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final padding = context.responsive(
      mobile: 16.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    final spacing = context.responsive(
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              title: l10n.totalTripsToday,
              value: Formatters.formatSimple(stats.totalTripsToday),
              icon: Icons.route_rounded,
              color: AppColors.primary,
              animationDelay: 0,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: StatCard(
              title: l10n.ongoingTrips,
              value: Formatters.formatSimple(stats.ongoingTrips),
              icon: Icons.play_circle_rounded,
              color: AppColors.warning,
              animationDelay: 50,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: StatCard(
              title: l10n.completed,
              value: Formatters.formatSimple(stats.completedTrips),
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              animationDelay: 100,
            ),
          ),
        ],
      ),
    );
  }
}
