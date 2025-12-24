import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../core/enums/enums.dart';
import '../../../../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../../../trips/domain/entities/trip.dart';
import 'sidebar_trip_card.dart';

class SidebarTripsList extends ConsumerWidget {
  final AsyncValue<List<Trip>> tripsAsync;
  final String tripSearchQuery;
  final TripState? selectedTripFilter;

  const SidebarTripsList({
    super.key,
    required this.tripsAsync,
    required this.tripSearchQuery,
    required this.selectedTripFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return tripsAsync.when(
      data: (trips) {
        // Apply Filters
        final filteredTrips = trips.where((trip) {
          // Search filter
          if (tripSearchQuery.isNotEmpty) {
            final searchLower = tripSearchQuery.toLowerCase();
            final matchesName = trip.name.toLowerCase().contains(searchLower);
            final matchesDriver =
                trip.driverName?.toLowerCase().contains(searchLower) ?? false;
            final matchesVehicle =
                trip.vehicleName?.toLowerCase().contains(searchLower) ?? false;
            if (!matchesName && !matchesDriver && !matchesVehicle) return false;
          }

          // State filter
          if (selectedTripFilter != null && trip.state != selectedTripFilter) {
            return false;
          }

          return true;
        }).toList();

        // Sort by time
        filteredTrips.sort((a, b) {
          final timeA = a.plannedStartTime ?? DateTime(0);
          final timeB = b.plannedStartTime ?? DateTime(0);
          return timeA.compareTo(timeB);
        });

        if (filteredTrips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tripSearchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.route_rounded,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tripSearchQuery.isNotEmpty
                        ? 'لا توجد نتائج'
                        : 'لا توجد رحلات',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (tripSearchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد رحلات مجدولة لهذا اليوم',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTrips.length,
          itemBuilder: (context, index) {
            final trip = filteredTrips[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < filteredTrips.length - 1 ? 12 : 0,
              ),
              child: SidebarTripCard(trip: trip, index: index),
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
          child: const ShimmerCard(height: 110),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.error,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
