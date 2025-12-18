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
import '../widgets/dispatcher_unified_header.dart';
import '../widgets/dispatcher_secondary_header.dart';
import '../widgets/dispatcher_footer.dart';
import '../widgets/dispatcher_action_fab.dart';

/// Dispatcher Trips Screen - شاشة إدارة الرحلات للمرسل - ShuttleBee
class DispatcherTripsScreen extends ConsumerStatefulWidget {
  const DispatcherTripsScreen({super.key});

  @override
  ConsumerState<DispatcherTripsScreen> createState() =>
      _DispatcherTripsScreenState();
}

class _DispatcherTripsScreenState extends ConsumerState<DispatcherTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  TripType? _tripTypeFilter;
  bool _onlyWithDriver = false;
  bool _onlyWithVehicle = false;
  bool _onlyWithGps = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TripFilters get _tripFilters => TripFilters(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tripsAsync = ref.watch(dispatcherTripsProvider(_tripFilters));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // From any Dispatcher sub-tab, go back to Dispatcher home.
        context.go(RoutePaths.dispatcherHome);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // === Unified Header ===
            _buildHeader(context, l10n, tripsAsync),

            // === شريط البحث والفلاتر (للموبايل فقط) ===
            _buildMobileSearchSection(context),

            // === Trips Content ===
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTripsTab(tripsAsync, null),
                  _buildTripsTab(tripsAsync, TripState.planned),
                  _buildTripsTab(tripsAsync, TripState.ongoing),
                  _buildTripsTab(tripsAsync, TripState.done),
                ],
              ),
            ),
          ],
        ),

        // === Footer (Tablet/Desktop only) - شريط معلومات فقط ===
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
            if (_hasActiveFilters)
              DispatcherFabAction(
                icon: Icons.clear_all_rounded,
                label: l10n.clearFilters,
                onPressed: () {
                  setState(() {
                    _tripTypeFilter = null;
                    _onlyWithDriver = false;
                    _onlyWithVehicle = false;
                    _onlyWithGps = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 HEADER BUILDER - يختلف حسب الجهاز
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Trip>> tripsAsync,
  ) {
    return DispatcherUnifiedHeader(
      title: l10n.tripsManagement,
      subtitle:       tripsAsync.maybeWhen(
        data: (trips) {
          final ongoing =
              trips.where((t) => t.state == TripState.ongoing).length;
          return '${l10n.total}: ${Formatters.formatSimple(trips.length)} • ${l10n.ongoing}: ${Formatters.formatSimple(ongoing)}';
        },
        orElse: () => null,
      ),
      // البحث يظهر فقط على Tablet/Desktop (الموبايل له شريط منفصل)
      searchHint: l10n.searchTrip,
      searchValue: _searchQuery,
      onSearchChanged: (v) => setState(() => _searchQuery = v),
      onSearchClear: () => setState(() => _searchQuery = ''),
      showSearch: !context.isMobile, // لا تظهر البحث في Header على الموبايل
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
        IconButton(
          icon: const Icon(Icons.calendar_today_rounded),
          color: Colors.white,
          onPressed: () => _selectDate(context),
          tooltip: l10n.selectDate,
        ),
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: _hasActiveFilters ? AppColors.warning : Colors.white,
          ),
          onPressed: _openFiltersSheet,
          tooltip: l10n.filter,
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
        if (_hasActiveFilters)
          DispatcherHeaderAction(
            icon: Icons.clear_all_rounded,
            label: l10n.clearFilters,
            onPressed: () {
              setState(() {
                _tripTypeFilter = null;
                _onlyWithDriver = false;
                _onlyWithVehicle = false;
                _onlyWithGps = false;
              });
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
            value: Formatters.formatSimple(trips.where((t) => t.state == TripState.planned).length),
          ),
          DispatcherHeaderStat(
            icon: Icons.play_circle_rounded,
            label: l10n.ongoing,
            value: Formatters.formatSimple(trips.where((t) => t.state == TripState.ongoing).length),
          ),
          DispatcherHeaderStat(
            icon: Icons.check_circle_rounded,
            label: l10n.completed,
            value: Formatters.formatSimple(trips.where((t) => t.state == TripState.done).length),
          ),
        ],
        orElse: () => [],
      ),
      filters: context.isMobile ? [] : _buildActiveFilterChips(),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(text: l10n.all),
          Tab(text: l10n.planned),
          Tab(text: l10n.ongoing),
          Tab(text: l10n.completed),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE SEARCH SECTION - شريط البحث والفلاتر للموبايل فقط
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileSearchSection(BuildContext context) {
    if (!context.isMobile) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // حقل البحث
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchTrip,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
            ),
          ),

          // الفلاتر النشطة
          if (_buildActiveFilterChips().isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildActiveFilterChips()
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: f,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripsTab(AsyncValue<List<Trip>> tripsAsync, TripState? filter) {
    final l10n = AppLocalizations.of(context);
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
        data: (trips) {
          var filteredTrips = filter == null
              ? trips
              : trips.where((t) => t.state == filter).toList();

          // Advanced filters
          if (_tripTypeFilter != null) {
            filteredTrips = filteredTrips
                .where((t) => t.tripType == _tripTypeFilter)
                .toList();
          }
          if (_onlyWithDriver) {
            filteredTrips =
                filteredTrips.where((t) => t.driverId != null).toList();
          }
          if (_onlyWithVehicle) {
            filteredTrips =
                filteredTrips.where((t) => t.vehicleId != null).toList();
          }
          if (_onlyWithGps) {
            filteredTrips = filteredTrips
                .where(
                  (t) =>
                      t.currentLatitude != null && t.currentLongitude != null,
                )
                .toList();
          }

          final q = _searchQuery.trim().toLowerCase();
          if (q.isNotEmpty) {
            filteredTrips = filteredTrips.where((t) {
              final name = t.name.toLowerCase();
              final driver = (t.driverName ?? '').toLowerCase();
              final companion =
                  (t.companionName ?? '').toLowerCase(); // NEW: المرافق
              final vehicle = (t.vehicleName ?? '').toLowerCase();
              return name.contains(q) ||
                  driver.contains(q) ||
                  companion.contains(q) || // NEW: بحث في المرافق
                  vehicle.contains(q);
            }).toList();
          }

          if (filteredTrips.isEmpty) {
            return EmptyState(
              icon: Icons.route_rounded,
              title: l10n.noTrips,
              message: filter == null
                  ? (_searchQuery.trim().isNotEmpty
                      ? l10n.noResultsMatching
                      : (_hasActiveFilters
                          ? l10n.noResultsForFilters
                          : l10n.noTripsForDay))
                      : (_searchQuery.trim().isNotEmpty
                      ? l10n.noResultsMatching
                      : (_hasActiveFilters
                          ? l10n.noResultsForFilters
                          : '${l10n.noTrips} ${filter.getLocalizedLabel(context)}')),
              buttonText: l10n.createNewTrip,
              onButtonPressed: () {
                context.go('${RoutePaths.dispatcherHome}/trips/create');
              },
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              context.isMobile ? 96 : 16, // مساحة إضافية للـ FAB على الهاتف
            ),
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              final trip = filteredTrips[index];
              return _buildTripCard(trip, index);
            },
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
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
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                trip.plannedStartTime != null
                                    ? Formatters.time(trip.plannedStartTime, use24Hour: true)
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
                  // NEW: عرض المرافق إذا كان موجوداً
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
            isMobile ? 96 : 16, // مساحة إضافية للـ FAB على الهاتف
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
      // Note: _tripFilters getter uses _selectedDate, so it will have the new value after setState
      ref.invalidate(dispatcherTripsProvider(_tripFilters));
    }
  }

  bool get _hasActiveFilters =>
      _tripTypeFilter != null ||
      _onlyWithDriver ||
      _onlyWithVehicle ||
      _onlyWithGps;

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_tripTypeFilter != null) {
      chips.add(
        DispatcherFilterChip(
          label: _tripTypeFilter!.getLocalizedLabel(context),
          isSelected: true,
          onTap: () => setState(() => _tripTypeFilter = null),
          icon: Icons.directions_bus_rounded,
          color: AppColors.dispatcherPrimary,
        ),
      );
    }

    if (_onlyWithDriver) {
      final l10n = AppLocalizations.of(context);
      chips.add(
        DispatcherFilterChip(
          label: l10n.withDriver,
          isSelected: true,
          onTap: () => setState(() => _onlyWithDriver = false),
          icon: Icons.person_rounded,
          color: AppColors.primary,
        ),
      );
    }

    if (_onlyWithVehicle) {
      final l10n = AppLocalizations.of(context);
      chips.add(
        DispatcherFilterChip(
          label: l10n.withVehicle,
          isSelected: true,
          onTap: () => setState(() => _onlyWithVehicle = false),
          icon: Icons.directions_bus_rounded,
          color: AppColors.success,
        ),
      );
    }

    if (_onlyWithGps) {
      final l10n = AppLocalizations.of(context);
      chips.add(
        DispatcherFilterChip(
          label: l10n.withGps,
          isSelected: true,
          onTap: () => setState(() => _onlyWithGps = false),
          icon: Icons.gps_fixed_rounded,
          color: AppColors.warning,
        ),
      );
    }

    return chips;
  }

  Future<void> _openFiltersSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Local state inside sheet for smooth toggling
        TripType? localTripType = _tripTypeFilter;
        bool localWithDriver = _onlyWithDriver;
        bool localWithVehicle = _onlyWithVehicle;
        bool localWithGps = _onlyWithGps;

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Container(
              margin: const EdgeInsets.only(top: 80),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: AppColors.dispatcherPrimary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(ctx).advancedFilters,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setLocal(() {
                                localTripType = null;
                                localWithDriver = false;
                                localWithVehicle = false;
                                localWithGps = false;
                              });
                            },
                            child: Text(
                              AppLocalizations.of(ctx).reset,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(ctx).tripType,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          ChoiceChip(
                            label: Text(
                              AppLocalizations.of(ctx).all,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            selected: localTripType == null,
                            onSelected: (_) =>
                                setLocal(() => localTripType = null),
                          ),
                          ChoiceChip(
                            label: Text(
                              AppLocalizations.of(ctx).pickup,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            selected: localTripType == TripType.pickup,
                            onSelected: (_) =>
                                setLocal(() => localTripType = TripType.pickup),
                          ),
                          ChoiceChip(
                            label: Text(
                              AppLocalizations.of(ctx).dropoff,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            selected: localTripType == TripType.dropoff,
                            onSelected: (_) => setLocal(
                              () => localTripType = TripType.dropoff,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppLocalizations.of(ctx).options,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithDriver,
                        onChanged: (v) => setLocal(() => localWithDriver = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: Text(
                          AppLocalizations.of(ctx).onlyWithDriver,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithVehicle,
                        onChanged: (v) => setLocal(() => localWithVehicle = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: Text(
                          AppLocalizations.of(ctx).onlyWithVehicle,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithGps,
                        onChanged: (v) => setLocal(() => localWithGps = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: Text(
                          AppLocalizations.of(ctx).onlyWithGps,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                AppLocalizations.of(ctx).cancel,
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dispatcherPrimary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _tripTypeFilter = localTripType;
                                  _onlyWithDriver = localWithDriver;
                                  _onlyWithVehicle = localWithVehicle;
                                  _onlyWithGps = localWithGps;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                AppLocalizations.of(ctx).apply,
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
