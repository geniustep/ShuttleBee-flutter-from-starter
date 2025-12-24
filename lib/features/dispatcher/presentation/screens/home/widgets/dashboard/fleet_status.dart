import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../../core/utils/formatters.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../shared/widgets/common/stat_card.dart';
import '../../../../../../trips/domain/repositories/trip_repository.dart';

class FleetStatus extends StatelessWidget {
  final TripDashboardStats stats;

  const FleetStatus({
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: l10n.activeVehicles,
                  value:
                      '${Formatters.formatSimple(stats.activeVehicles)}/${Formatters.formatSimple(stats.totalVehicles)}',
                  icon: Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  animationDelay: 200,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: StatCard(
                  title: l10n.activeDrivers,
                  value:
                      '${Formatters.formatSimple(stats.activeDrivers)}/${Formatters.formatSimple(stats.totalDrivers)}',
                  icon: Icons.person_rounded,
                  color: AppColors.success,
                  animationDelay: 250,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(
              context.responsive(mobile: 16.0, tablet: 20.0, desktop: 24.0),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.06),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                context.responsive(mobile: 16.0, tablet: 18.0, desktop: 20.0),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: context.responsive(
                  mobile: 1.0,
                  tablet: 1.5,
                  desktop: 2.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                const BoxShadow(
                  color: AppColors.cardShadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        context.responsive(
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          context.responsive(
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: context.responsive(
                          mobile: 20.0,
                          tablet: 22.0,
                          desktop: 24.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: context.responsive(
                        mobile: 12.0,
                        tablet: 16.0,
                        desktop: 20.0,
                      ),
                    ),
                    Text(
                      l10n.fleetUtilization,
                      style: TextStyle(
                        fontSize: context.responsive(
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        ),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: context.responsive(
                    mobile: 16.0,
                    tablet: 20.0,
                    desktop: 24.0,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    context.responsive(
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 14.0,
                    ),
                  ),
                  child: LinearProgressIndicator(
                    value: stats.totalVehicles > 0
                        ? stats.activeVehicles / stats.totalVehicles
                        : 0,
                    minHeight: context.responsive(
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(
                  height: context.responsive(
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  ),
                ),
                Text(
                  '${Formatters.formatSimple(stats.totalVehicles > 0 ? ((stats.activeVehicles / stats.totalVehicles) * 100).toStringAsFixed(0) : 0)}% ${l10n.fleetInUse}',
                  style: TextStyle(
                    fontSize: context.responsive(
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }
}
