import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../../core/utils/formatters.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../trips/domain/repositories/trip_repository.dart';

class QuickStatsSummary extends StatelessWidget {
  final TripDashboardStats stats;

  const QuickStatsSummary({
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

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.responsive(
            mobile: double.infinity,
            tablet: 900,
            desktop: 1400,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Container(
            padding: EdgeInsets.all(
              context.responsive(mobile: 16.0, tablet: 20.0, desktop: 24.0),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                  AppColors.dispatcherPrimary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                context.responsive(
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
              ),
              border: Border.all(
                color: AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                const dividerWidth = 1.0;
                const totalDividers = 2;
                final itemWidth =
                    (availableWidth - (totalDividers * dividerWidth)) / 3;

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _buildQuickStatItem(
                          context,
                          icon: Icons.route_rounded,
                          value: Formatters.formatSimple(stats.totalTripsToday),
                          label: l10n.trips,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        width: dividerWidth,
                        color:
                            AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _buildQuickStatItem(
                          context,
                          icon: Icons.play_circle_rounded,
                          value: Formatters.formatSimple(stats.ongoingTrips),
                          label: l10n.ongoing,
                          color: AppColors.warning,
                        ),
                      ),
                      Container(
                        width: dividerWidth,
                        color:
                            AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _buildQuickStatItem(
                          context,
                          icon: Icons.directions_bus_rounded,
                          value:
                              '${Formatters.formatSimple(stats.activeVehicles)}/${Formatters.formatSimple(stats.totalVehicles)}',
                          label: l10n.vehicles,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 50.ms)
        .slideY(begin: -0.1, end: 0, duration: 400.ms, delay: 50.ms);
  }

  Widget _buildQuickStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: context.responsive(mobile: 20.0, tablet: 22.0, desktop: 24.0),
        ),
        SizedBox(
          height: context.responsive(mobile: 6.0, tablet: 8.0, desktop: 10.0),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        SizedBox(
          height: context.responsive(mobile: 2.0, tablet: 4.0, desktop: 6.0),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 11.0,
              tablet: 12.0,
              desktop: 13.0,
            ),
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
