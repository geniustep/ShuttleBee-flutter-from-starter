import 'package:bridgecore_flutter_starter/features/trips/presentation/providers/trip_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/routing/route_paths.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../../core/utils/formatters.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../../../../shared/widgets/states/empty_state.dart';
import '../../../../../../trips/domain/entities/trip.dart';
import '../../../../../../trips/domain/repositories/trip_repository.dart';
import '../../../../providers/dispatcher_cached_providers.dart';
import '../common/trip_card.dart';

class TodayTripsList extends ConsumerWidget {
  final DateTime today;

  const TodayTripsList({
    super.key,
    required this.today,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final padding = context.responsive(
      mobile: 16.0,
      tablet: 32.0,
      desktop: 48.0,
    );

    final todayFilters = TripFilters(
      fromDate: today,
      toDate: DateTime(today.year, today.month, today.day, 23, 59, 59),
    );

    final tripsAsync = ref.watch(dispatcherTripsProvider(todayFilters));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return Container(
              padding: EdgeInsets.all(
                context.responsive(mobile: 32.0, tablet: 40.0, desktop: 48.0),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  context.responsive(mobile: 16.0, tablet: 18.0, desktop: 20.0),
                ),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dispatcherPrimary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: EmptyState(
                icon: Icons.route_rounded,
                title: l10n.noTripsForDay,
                message: 'لا توجد رحلات مجدولة لهذا اليوم',
                buttonText: l10n.createTrip,
                onButtonPressed: () {
                  HapticFeedback.mediumImpact();
                  context.go('${RoutePaths.dispatcherHome}/trips/create');
                },
              ),
            );
          }

          final sortedTrips = List<Trip>.from(trips)
            ..sort((a, b) {
              final timeA = a.plannedStartTime ?? DateTime(0);
              final timeB = b.plannedStartTime ?? DateTime(0);
              return timeA.compareTo(timeB);
            });

          final displayTrips = sortedTrips.take(6).toList();
          final hasMore = sortedTrips.length > 6;

          return Column(
            children: [
              ...displayTrips.asMap().entries.map((entry) {
                final index = entry.key;
                final trip = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < displayTrips.length - 1
                        ? context.responsive(
                            mobile: 12.0,
                            tablet: 16.0,
                            desktop: 20.0,
                          )
                        : 0,
                  ),
                  child: TripCard(trip: trip, index: index),
                );
              }),
              if (hasMore)
                Padding(
                  padding: EdgeInsets.only(
                    top: context.responsive(
                      mobile: 16.0,
                      tablet: 20.0,
                      desktop: 24.0,
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.go('${RoutePaths.dispatcherHome}/trips');
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        '${l10n.viewAllTrips} (${Formatters.formatSimple(trips.length)})',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: context.responsive(
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 18.0,
                          ),
                        ),
                        side: const BorderSide(
                          color: AppColors.dispatcherPrimary,
                          width: 2,
                        ),
                        foregroundColor: AppColors.dispatcherPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.responsive(
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index < 2
                    ? context.responsive(
                        mobile: 12.0,
                        tablet: 16.0,
                        desktop: 20.0,
                      )
                    : 0,
              ),
              child: ShimmerCard(
                height: context.responsive(
                  mobile: 140.0,
                  tablet: 160.0,
                  desktop: 180.0,
                ),
              ),
            ),
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: l10n.error,
          message: error.toString(),
        ),
      ),
    );
  }
}
