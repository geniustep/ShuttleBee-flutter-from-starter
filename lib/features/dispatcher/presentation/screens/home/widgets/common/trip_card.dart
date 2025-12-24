import 'package:bridgecore_flutter_starter/core/enums/enums.dart';
import 'package:bridgecore_flutter_starter/core/routing/route_paths.dart';
import 'package:bridgecore_flutter_starter/core/theme/app_colors.dart';
import 'package:bridgecore_flutter_starter/core/utils/formatters.dart';
import 'package:bridgecore_flutter_starter/features/trips/domain/entities/trip.dart';
import 'package:bridgecore_flutter_starter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'info_chip.dart';
import 'package:bridgecore_flutter_starter/core/utils/responsive_utils.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final int index;

  const TripCard({super.key, required this.trip, required this.index});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              context.responsive(mobile: 16.0, tablet: 18.0, desktop: 20.0),
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('${RoutePaths.dispatcherHome}/trips/${trip.id}');
            },
            borderRadius: BorderRadius.circular(
              context.responsive(mobile: 16.0, tablet: 18.0, desktop: 20.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                context.responsive(mobile: 16.0, tablet: 18.0, desktop: 20.0),
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
                          color: trip.tripType == TripType.pickup
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            context.responsive(
                              mobile: 10.0,
                              tablet: 12.0,
                              desktop: 14.0,
                            ),
                          ),
                        ),
                        child: Icon(
                          trip.tripType == TripType.pickup
                              ? Icons.arrow_circle_up_rounded
                              : Icons.arrow_circle_down_rounded,
                          color: trip.tripType == TripType.pickup
                              ? AppColors.primary
                              : AppColors.success,
                          size: context.responsive(
                            mobile: 24.0,
                            tablet: 26.0,
                            desktop: 28.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: context.responsive(
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.name,
                              style: TextStyle(
                                fontSize: context.responsive(
                                  mobile: 16.0,
                                  tablet: 17.0,
                                  desktop: 18.0,
                                ),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(
                              height: context.responsive(
                                mobile: 4.0,
                                tablet: 6.0,
                                desktop: 8.0,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: context.responsive(
                                    mobile: 14.0,
                                    tablet: 15.0,
                                    desktop: 16.0,
                                  ),
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(
                                  width: context.responsive(
                                    mobile: 4.0,
                                    tablet: 6.0,
                                    desktop: 8.0,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    Formatters.date(trip.date, pattern: 'd MMM'),
                                    style: TextStyle(
                                      fontSize: context.responsive(
                                        mobile: 13.0,
                                        tablet: 14.0,
                                        desktop: 15.0,
                                      ),
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: context.responsive(
                                    mobile: 12.0,
                                    tablet: 14.0,
                                    desktop: 16.0,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: context.responsive(
                                    mobile: 14.0,
                                    tablet: 15.0,
                                    desktop: 16.0,
                                  ),
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(
                                  width: context.responsive(
                                    mobile: 4.0,
                                    tablet: 6.0,
                                    desktop: 8.0,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    trip.plannedStartTime != null
                                        ? Formatters.time(
                                            trip.plannedStartTime,
                                            use24Hour: true,
                                          )
                                        : '--:--',
                                    style: TextStyle(
                                      fontSize: context.responsive(
                                        mobile: 13.0,
                                        tablet: 14.0,
                                        desktop: 15.0,
                                      ),
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: context.responsive(
                          mobile: 8.0,
                          tablet: 10.0,
                          desktop: 12.0,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                          vertical: context.responsive(
                            mobile: 4.0,
                            tablet: 6.0,
                            desktop: 8.0,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: trip.state.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trip.state.getLocalizedLabel(context),
                          style: TextStyle(
                            fontSize: context.responsive(
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 13.0,
                            ),
                            fontWeight: FontWeight.bold,
                            color: trip.state.color,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: context.responsive(
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: context.responsive(
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),
                  Wrap(
                    spacing: context.responsive(
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                    runSpacing: context.responsive(
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                    children: [
                      InfoChip(
                        icon: Icons.person_rounded,
                        label: trip.driverName ?? 'بدون سائق',
                        color: AppColors.primary,
                      ),
                      if (trip.companionName != null)
                        InfoChip(
                          icon: Icons.person_add_alt_rounded,
                          label: trip.companionName!,
                          color: AppColors.info,
                        ),
                      InfoChip(
                        icon: Icons.directions_bus_rounded,
                        label: trip.vehicleName ?? l10n.noVehicle,
                        color: AppColors.warning,
                      ),
                      InfoChip(
                        icon: Icons.people_rounded,
                        label: Formatters.formatSimple(trip.totalPassengers),
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: (500 + (index * 50)).ms,
          curve: Curves.easeOutCubic,
        )
        .slideX(
          begin: 0.05,
          end: 0,
          duration: 400.ms,
          delay: (500 + (index * 50)).ms,
          curve: Curves.easeOutCubic,
        );
  }
}
