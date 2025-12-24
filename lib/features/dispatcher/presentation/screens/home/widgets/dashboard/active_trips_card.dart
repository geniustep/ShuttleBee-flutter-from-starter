import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/routing/route_paths.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../../core/utils/formatters.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../trips/domain/repositories/trip_repository.dart';

class ActiveTripsCard extends StatelessWidget {
  final TripDashboardStats stats;

  const ActiveTripsCard({
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('${RoutePaths.dispatcherHome}/monitor');
          },
          child: Container(
            padding: EdgeInsets.all(
              context.responsive(
                mobile: 20.0,
                tablet: 24.0,
                desktop: 28.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: AppColors.dispatcherGradient,
              borderRadius: BorderRadius.circular(
                context.responsive(
                  mobile: 20.0,
                  tablet: 22.0,
                  desktop: 24.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.35),
                  blurRadius: context.responsive(
                    mobile: 20.0,
                    tablet: 24.0,
                    desktop: 28.0,
                  ),
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                  blurRadius: context.responsive(
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                  offset: const Offset(0, 4),
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
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          context.responsive(
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        color: Colors.white,
                        size: context.responsive(
                          mobile: 24.0,
                          tablet: 26.0,
                          desktop: 28.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: context.responsive(
                        mobile: 16.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.liveMonitoring,
                            style: TextStyle(
                              fontSize: context.responsive(
                                mobile: 18.0,
                                tablet: 20.0,
                                desktop: 22.0,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            '${Formatters.formatSimple(stats.ongoingTrips)} ${l10n.activeTripsNow}',
                            style: TextStyle(
                              fontSize: context.responsive(
                                mobile: 13.0,
                                tablet: 14.0,
                                desktop: 15.0,
                              ),
                              color: Colors.white.withValues(alpha: 0.8),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(
                        context.responsive(
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          context.responsive(
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: context.responsive(
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 22.0,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: context.responsive(
                    mobile: 20.0,
                    tablet: 24.0,
                    desktop: 28.0,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLiveIndicator(
                      context,
                      icon: Icons.directions_bus_rounded,
                      label: l10n.vehicles,
                      value: Formatters.formatSimple(stats.activeVehicles),
                    ),
                    Container(
                      width: 1,
                      height: context.responsive(
                        mobile: 40.0,
                        tablet: 45.0,
                        desktop: 50.0,
                      ),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _buildLiveIndicator(
                      context,
                      icon: Icons.person_rounded,
                      label: l10n.drivers,
                      value: Formatters.formatSimple(stats.activeDrivers),
                    ),
                    Container(
                      width: 1,
                      height: context.responsive(
                        mobile: 40.0,
                        tablet: 45.0,
                        desktop: 50.0,
                      ),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _buildLiveIndicator(
                      context,
                      icon: Icons.play_circle_rounded,
                      label: l10n.trips,
                      value: Formatters.formatSimple(stats.ongoingTrips),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 450.ms)
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 400.ms,
            delay: 450.ms,
          ),
    );
  }

  Widget _buildLiveIndicator(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: context.responsive(mobile: 24.0, tablet: 26.0, desktop: 28.0),
        ),
        SizedBox(
          height: context.responsive(mobile: 6.0, tablet: 8.0, desktop: 10.0),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 18.0,
              tablet: 20.0,
              desktop: 22.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive(
              mobile: 11.0,
              tablet: 12.0,
              desktop: 13.0,
            ),
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
