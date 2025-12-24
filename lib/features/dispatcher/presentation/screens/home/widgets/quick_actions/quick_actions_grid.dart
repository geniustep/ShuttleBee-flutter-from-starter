import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_typography.dart';
import '../../../../../../../core/routing/route_paths.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../../l10n/app_localizations.dart';
import 'action_card.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final crossAxisCount = context.responsive(mobile: 2, tablet: 3, desktop: 4);

    final aspectRatio = context.responsive(
      mobile: 1.0,
      tablet: 0.95,
      desktop: 0.9,
    );

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
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: context.responsive(
                      mobile: const EdgeInsets.all(10),
                      tablet: const EdgeInsets.all(12),
                      desktop: const EdgeInsets.all(14),
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.dispatcherGradient,
                      borderRadius: BorderRadius.circular(
                        context.responsive(
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dispatcherPrimary.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: context.responsive(
                        mobile: 22.0,
                        tablet: 24.0,
                        desktop: 26.0,
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
                  Expanded(
                    child: Text(
                      l10n.quickActions,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: context.responsive(
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 24.0,
                        ),
                      ),
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
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
                children: [
                  ActionCard(
                    icon: Icons.list_alt_rounded,
                    label: l10n.trips,
                    color: AppColors.success,
                    delay: 50,
                    onTap: () =>
                        context.go('${RoutePaths.dispatcherHome}/trips'),
                  ),
                  ActionCard(
                    icon: Icons.groups_rounded,
                    label: l10n.groups,
                    color: AppColors.dispatcherPrimary,
                    delay: 100,
                    onTap: () =>
                        context.go('${RoutePaths.dispatcherHome}/groups'),
                  ),
                  ActionCard(
                    icon: Icons.event_busy_rounded,
                    label: l10n.holidays,
                    color: const Color(0xFFF59E0B),
                    delay: 150,
                    onTap: () => context.go(RoutePaths.dispatcherHolidays),
                  ),
                  ActionCard(
                    icon: Icons.people_alt_rounded,
                    label: l10n.passengers,
                    color: AppColors.primary,
                    delay: 175,
                    onTap: () => context.go(RoutePaths.dispatcherPassengers),
                  ),
                  ActionCard(
                    icon: Icons.directions_bus_rounded,
                    label: l10n.vehicles,
                    color: const Color(0xFF6366F1),
                    delay: 200,
                    onTap: () =>
                        context.go('${RoutePaths.dispatcherHome}/vehicles'),
                  ),
                  ActionCard(
                    icon: Icons.map_rounded,
                    label: l10n.liveTracking,
                    color: const Color(0xFFEF4444),
                    delay: 225,
                    onTap: () =>
                        context.go('${RoutePaths.dispatcherHome}/monitor'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
