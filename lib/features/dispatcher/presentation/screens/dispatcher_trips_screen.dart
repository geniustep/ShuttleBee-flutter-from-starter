import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../providers/trips_filter_provider.dart';
import '../models/trips_filter_model.dart';
import '../widgets/headers/dispatcher_unified_header.dart';
import '../widgets/common/dispatcher_footer.dart';
import '../widgets/common/dispatcher_action_fab.dart';
import '../widgets/trips/trips_search_bar.dart';

/// Dispatcher Trips Screen - شاشة إدارة الرحلات للمرسل (النسخة المحسّنة)
class DispatcherTripsScreen extends ConsumerStatefulWidget {
  const DispatcherTripsScreen({super.key});

  @override
  ConsumerState<DispatcherTripsScreen> createState() =>
      _DispatcherTripsScreenState();
}

class _DispatcherTripsScreenState extends ConsumerState<DispatcherTripsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // تهيئة التاريخ في الفلتر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripsFilterProvider.notifier).setSelectedDate(_selectedDate);
    });
  }

  @override
  void dispose() {
    // مسح الفلاتر عند مغادرة الصفحة
    ref.read(tripsFilterProvider.notifier).clearAllFilters();
    super.dispose();
  }

  TripFilters _getTripFilters(WidgetRef ref) {
    final filterState = ref.read(tripsFilterProvider);
    if (!filterState.useDateFilter) {
      // بدون فلتر تاريخ - عرض كل الرحلات
      return const TripFilters();
    }
    // مع فلتر تاريخ - رحلات اليوم المحدد
    return TripFilters(
      fromDate: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      toDate: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
        59,
      ),
    );
  }

  TripFilters get _tripFilters => _getTripFilters(ref);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tripsAsync = ref.watch(dispatcherTripsProvider(_tripFilters));
    final filteredTrips = ref.watch(filteredTripsProvider(_tripFilters));
    final filterState = ref.watch(tripsFilterProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RoutePaths.dispatcherHome);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // === Unified Header ===
            _buildHeader(context, l10n, tripsAsync),

            // === شريط البحث والفلتر ===
            const TripsSearchBar(),

            // === Trips Content ===
            Expanded(
              child: _buildTripsContent(tripsAsync, filteredTrips, filterState, l10n),
            ),
          ],
        ),

        // === Footer (Tablet/Desktop only) ===
        bottomNavigationBar: tripsAsync.maybeWhen(
          data: (trips) {
            final ongoing =
                trips.where((t) => t.state == TripState.ongoing).length;
            final planned =
                trips.where((t) => t.state == TripState.planned).length;
            final done = trips.where((t) => t.state == TripState.done).length;

            return DispatcherFooter(
              hideOnMobile: true,
              info: Formatters.displayDate(_selectedDate),
              stats: [
                DispatcherFooterStat(
                  icon: Icons.event_rounded,
                  label: l10n.trips,
                  value: Formatters.formatSimple(trips.length),
                ),
                if (ongoing > 0)
                  DispatcherFooterStat(
                    icon: Icons.play_circle_rounded,
                    label: l10n.ongoing,
                    value: Formatters.formatSimple(ongoing),
                    color: AppColors.warning,
                  ),
                if (planned > 0)
                  DispatcherFooterStat(
                    icon: Icons.schedule_rounded,
                    label: l10n.planned,
                    value: Formatters.formatSimple(planned),
                    color: AppColors.info,
                  ),
                if (done > 0)
                  DispatcherFooterStat(
                    icon: Icons.check_circle_rounded,
                    label: l10n.completed,
                    value: Formatters.formatSimple(done),
                    color: AppColors.success,
                  ),
              ],
              lastUpdated: DateTime.now(),
              syncStatus: DispatcherSyncStatus.synced,
            );
          },
          orElse: () => null,
        ),

        // === FAB (Mobile only) ===
        floatingActionButton: DispatcherActionFAB(
          actions: [
            DispatcherFabAction(
              icon: Icons.add_rounded,
              label: l10n.createTrip,
              isPrimary: true,
              onPressed: () {
                context.go('${RoutePaths.dispatcherHome}/trips/create');
              },
            ),
            if (filterState.hasActiveFilters)
              DispatcherFabAction(
                icon: Icons.clear_all_rounded,
                label: l10n.clearFilters,
                onPressed: () {
                  ref.read(tripsFilterProvider.notifier).clearAllFilters();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Trip>> tripsAsync,
  ) {
    return DispatcherUnifiedHeader(
      title: l10n.tripsManagement,
      subtitle: tripsAsync.maybeWhen(
        data: (trips) {
          final ongoing =
              trips.where((t) => t.state == TripState.ongoing).length;
          return '${l10n.total}: ${Formatters.formatSimple(trips.length)} • ${l10n.ongoing}: ${Formatters.formatSimple(ongoing)}';
        },
        orElse: () => null,
      ),
      showSearch: false, // البحث في شريط منفصل
      onRefresh: () async {
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        if (userId != 0) {
          await cache.delete(
            DispatcherCacheKeys.trips(
              userId: userId,
              filters: _tripFilters,
            ),
          );
        }
        ref.invalidate(dispatcherTripsProvider(_tripFilters));
      },
      isLoading: tripsAsync.isLoading,
      actions: [
        const RoleSwitcherButton(),
        // زر إلغاء/تفعيل فلتر التاريخ
        Consumer(
          builder: (context, ref, _) {
            final filterState = ref.watch(tripsFilterProvider);
            return IconButton(
              icon: Icon(
                filterState.useDateFilter
                    ? Icons.calendar_today_rounded
                    : Icons.calendar_view_week_rounded,
              ),
              color: filterState.useDateFilter
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
              onPressed: () {
                final notifier = ref.read(tripsFilterProvider.notifier);
                if (filterState.useDateFilter) {
                  // إلغاء فلتر التاريخ
                  notifier.toggleDateFilter(false);
                } else {
                  // تفعيل فلتر التاريخ
                  notifier.toggleDateFilter(true);
                }
                ref.invalidate(dispatcherTripsProvider(_getTripFilters(ref)));
              },
              tooltip: filterState.useDateFilter
                  ? 'عرض كل الرحلات'
                  : 'عرض رحلات اليوم',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today_rounded),
          color: Colors.white,
          onPressed: () => _selectDate(context),
          tooltip: l10n.selectDate,
        ),
      ],
      primaryActions: [
        DispatcherHeaderAction(
          icon: Icons.add_rounded,
          label: l10n.createTrip,
          isPrimary: true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('${RoutePaths.dispatcherHome}/trips/create');
          },
        ),
      ],
      stats: tripsAsync.maybeWhen(
        data: (trips) => [
          DispatcherHeaderStat(
            icon: Icons.event_rounded,
            label: Formatters.date(_selectedDate, pattern: 'd MMM'),
            value: Formatters.formatSimple(trips.length),
          ),
          DispatcherHeaderStat(
            icon: Icons.schedule_rounded,
            label: l10n.planned,
            value: Formatters.formatSimple(
                trips.where((t) => t.state == TripState.planned).length),
          ),
          DispatcherHeaderStat(
            icon: Icons.play_circle_rounded,
            label: l10n.ongoing,
            value: Formatters.formatSimple(
                trips.where((t) => t.state == TripState.ongoing).length),
          ),
          DispatcherHeaderStat(
            icon: Icons.check_circle_rounded,
            label: l10n.completed,
            value: Formatters.formatSimple(
                trips.where((t) => t.state == TripState.done).length),
          ),
        ],
        orElse: () => [],
      ),
    );
  }

  Widget _buildTripsContent(
    AsyncValue<List<Trip>> tripsAsync,
    List<Trip> filteredTrips,
    TripsFilterState filterState,
    AppLocalizations l10n,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        if (userId != 0) {
          await cache.delete(
            DispatcherCacheKeys.trips(userId: userId, filters: _tripFilters),
          );
        }
        ref.invalidate(dispatcherTripsProvider(_tripFilters));
      },
      child: tripsAsync.when(
        data: (allTrips) {
          if (filteredTrips.isEmpty) {
            return EmptyState(
              icon: Icons.route_rounded,
              title: l10n.noTrips,
              message: filterState.hasActiveFilters
                  ? l10n.noResultsForFilters
                  : l10n.noTripsForDay,
              buttonText: filterState.hasActiveFilters
                  ? l10n.clearFilters
                  : l10n.createNewTrip,
              onButtonPressed: () {
                if (filterState.hasActiveFilters) {
                  ref.read(tripsFilterProvider.notifier).clearAllFilters();
                } else {
                  context.go('${RoutePaths.dispatcherHome}/trips/create');
                }
              },
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              context.isMobile ? 96 : 16,
            ),
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              final trip = filteredTrips[index];
              return _buildTripCard(trip, index);
            },
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildTripCard(Trip trip, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('${RoutePaths.dispatcherHome}/trips/${trip.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: trip.tripType == TripType.pickup
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      trip.tripType == TripType.pickup
                          ? Icons.arrow_circle_up_rounded
                          : Icons.arrow_circle_down_rounded,
                      color: trip.tripType == TripType.pickup
                          ? AppColors.primary
                          : AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                Formatters.date(trip.date, pattern: 'd MMM'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                trip.plannedStartTime != null
                                    ? Formatters.time(trip.plannedStartTime,
                                        use24Hour: true)
                                    : '--:--',
                                style: const TextStyle(
                                  fontSize: 13,
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
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: trip.state.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trip.state.getLocalizedLabel(context),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: trip.state.color,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.person_rounded,
                    trip.driverName ?? 'بدون سائق',
                    AppColors.primary,
                  ),
                  if (trip.companionName != null)
                    _buildInfoChip(
                      Icons.person_add_alt_rounded,
                      trip.companionName!,
                      AppColors.info,
                    ),
                  _buildInfoChip(
                    Icons.directions_bus_rounded,
                    trip.vehicleName ?? 'بدون مركبة',
                    AppColors.warning,
                  ),
                  _buildInfoChip(
                    Icons.people_rounded,
                    Formatters.formatSimple(trip.totalPassengers),
                    AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(
          begin: 0.05,
          end: 0,
          duration: 300.ms,
          delay: (index * 50).ms,
        );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            isMobile ? 96 : 16,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            return const ShimmerCard(height: 140);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final cache = ref.read(dispatcherCacheDataSourceProvider);
              final userId =
                  ref.read(authStateProvider).asData?.value.user?.id ?? 0;
              if (userId != 0) {
                await cache.delete(
                  DispatcherCacheKeys.trips(
                    userId: userId,
                    filters: _tripFilters,
                  ),
                );
              }
              ref.invalidate(dispatcherTripsProvider(_tripFilters));
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      ref.read(tripsFilterProvider.notifier).setSelectedDate(picked);
      ref.invalidate(dispatcherTripsProvider(_tripFilters));
    }
  }
}
