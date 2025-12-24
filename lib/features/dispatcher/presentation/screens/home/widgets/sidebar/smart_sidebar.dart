import 'package:bridgecore_flutter_starter/features/trips/presentation/providers/trip_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../core/enums/enums.dart';
import '../../../../../../trips/domain/entities/trip.dart';
import '../../../../providers/dispatcher_cached_providers.dart';
import 'sidebar_header.dart';
import 'sidebar_filters.dart';
import 'sidebar_stats.dart';
import 'sidebar_trips_list.dart';
import 'collapsed_sidebar_view.dart';

class SmartSidebar extends ConsumerWidget {
  final DateTime today;
  final bool isSidebarExpanded;
  final ValueChanged<bool> onToggleSidebar;
  final String tripSearchQuery;
  final ValueChanged<String> onSearchChanged;
  final TripState? selectedTripFilter;
  final ValueChanged<TripState?> onFilterChanged;
  final TextEditingController searchController;

  const SmartSidebar({
    super.key,
    required this.today,
    required this.isSidebarExpanded,
    required this.onToggleSidebar,
    required this.tripSearchQuery,
    required this.onSearchChanged,
    required this.selectedTripFilter,
    required this.onFilterChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayFilters = TripFilters(
      fromDate: today,
      toDate: DateTime(today.year, today.month, today.day, 23, 59, 59),
    );

    final tripsAsync = ref.watch(dispatcherTripsProvider(todayFilters));
    final sidebarWidth = isSidebarExpanded ? 380.0 : 65.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.dispatcherPrimary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          left: BorderSide(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(-4, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar Header with Toggle
          SidebarHeader(
            isSidebarExpanded: isSidebarExpanded,
            onToggle: () => onToggleSidebar(!isSidebarExpanded),
            todayFilters: todayFilters,
            tripsAsync: tripsAsync,
          ),

          if (isSidebarExpanded) ...[
            // Search & Filters
            SidebarFilters(
              searchController: searchController,
              tripSearchQuery: tripSearchQuery,
              onSearchChanged: onSearchChanged,
              selectedTripFilter: selectedTripFilter,
              onFilterChanged: onFilterChanged,
            ),

            // Trip Stats Summary
            SidebarStats(tripsAsync: tripsAsync),

            // Trips List
            Expanded(
              child: SidebarTripsList(
                tripsAsync: tripsAsync,
                tripSearchQuery: tripSearchQuery,
                selectedTripFilter: selectedTripFilter,
              ),
            ),
          ] else
            // Collapsed View - Icon Only
            Expanded(
              child: CollapsedSidebarView(tripsAsync: tripsAsync),
            ),
        ],
      ),
    );
  }
}
