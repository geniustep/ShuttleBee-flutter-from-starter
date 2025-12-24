import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/routing/route_paths.dart';
import '../../../../../../../core/enums/enums.dart';
import '../../../../../../trips/domain/entities/trip.dart';

class CollapsedSidebarView extends ConsumerWidget {
  final AsyncValue<List<Trip>> tripsAsync;

  const CollapsedSidebarView({
    super.key,
    required this.tripsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return tripsAsync.maybeWhen(
      data: (trips) {
        final ongoingTrips = trips
            .where((t) => t.state == TripState.ongoing)
            .take(5)
            .toList();

        if (ongoingTrips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(
                Icons.route_rounded,
                size: 28,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 11),
          itemCount: ongoingTrips.length,
          itemBuilder: (context, index) {
            final trip = ongoingTrips[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: Tooltip(
                  message: trip.name,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go(
                        '${RoutePaths.dispatcherHome}/trips/${trip.id}',
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: trip.state.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: trip.state.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        trip.tripType == TripType.pickup
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: trip.state.color,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
