import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../trips/domain/entities/trip.dart';
import '../../providers/trip_filter_provider.dart';
import 'empty_passengers_view.dart';
import 'passenger_stats_row.dart';
import 'passenger_tile.dart';

/// قسم قائمة الركاب مع الفلترة
class PassengersListSection extends ConsumerWidget {
  final int tripId;
  final Trip trip;

  const PassengersListSection({
    super.key,
    required this.tripId,
    required this.trip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filteredPassengers = ref.watch(filteredPassengersProvider(tripId));
    final filterState = ref.watch(tripFilterProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dispatcherPrimary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dispatcherPrimary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.people_rounded,
                        color: AppColors.dispatcherPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.passengers,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            filterState.hasActiveFilters
                                ? 'عرض ${Formatters.formatSimple(filteredPassengers.length)} من ${Formatters.formatSimple(trip.totalPassengers)}'
                                : '${Formatters.formatSimple(trip.totalPassengers)} ${l10n.passenger}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // زر إضافة سريع
                    Flexible(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'إضافة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        onPressed: () =>
                            _showAddPassengerOptions(context, trip),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dispatcherPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر عرض الكل
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push(
                          '${RoutePaths.dispatcherTrips}/${trip.id}/passengers',
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      tooltip: l10n.passengersManagement,
                      iconSize: 22,
                      color: AppColors.dispatcherPrimary,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // صف الإحصائيات
                PassengerStatsRow(trip: trip),
              ],
            ),
          ),

          // قائمة الركاب
          if (filteredPassengers.isEmpty)
            EmptyPassengersView(
              hasFilters: filterState.hasActiveFilters,
              onClearFilters: () =>
                  ref.read(tripFilterProvider.notifier).clearAllFilters(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredPassengers.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                return PassengerTile(
                  passenger: filteredPassengers[index],
                  index: index,
                  onTap: () =>
                      _showPassengerDetails(context, filteredPassengers[index]),
                );
              },
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  void _showAddPassengerOptions(BuildContext context, Trip trip) {
    // هنا يمكن فتح نافذة خيارات إضافة الراكب
    // لكن للتبسيط، سنفتح الصفحة الكاملة مباشرة
    context.push('${RoutePaths.dispatcherTrips}/${trip.id}/passengers');
  }

  void _showPassengerDetails(BuildContext context, TripLine passenger) {
    // يمكن إضافة نافذة تفاصيل الراكب هنا
    // لكن للتبسيط، نفتح صفحة الركاب الكاملة
    context.push(
      '${RoutePaths.dispatcherTrips}/${passenger.tripId}/passengers',
    );
  }
}
