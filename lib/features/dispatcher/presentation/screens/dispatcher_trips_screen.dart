import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/dispatcher_app_bar.dart';
import '../widgets/dispatcher_search_field.dart';

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
            _selectedDate.year, _selectedDate.month, _selectedDate.day),
        toDate: DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, 23, 59, 59),
      );

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(dispatcherTripsProvider(_tripFilters));

    return WillPopScope(
      onWillPop: () async {
        // Close any open dialog/sheet first.
        if (Navigator.of(context).canPop()) return true;
        // From any Dispatcher sub-tab, go back to Dispatcher home.
        context.go(RoutePaths.dispatcherHome);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: DispatcherAppBar(
          title: 'إدارة الرحلات',
          actions: [
            const RoleSwitcherButton(),
            _buildFilterButton(),
            IconButton(
              icon: const Icon(Icons.calendar_today_rounded),
              onPressed: () => _selectDate(context),
              tooltip: 'اختيار التاريخ',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () async {
                final cache = ref.read(dispatcherCacheDataSourceProvider);
                final userId =
                    ref.read(authStateProvider).asData?.value.user?.id ?? 0;
                if (userId != 0) {
                  await cache.delete(
                    DispatcherCacheKeys.trips(
                        userId: userId, filters: _tripFilters),
                  );
                }
                ref.invalidate(dispatcherTripsProvider(_tripFilters));
              },
              tooltip: 'تحديث',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'مخططة'),
              Tab(text: 'جارية'),
              Tab(text: 'منتهية'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Date Header
            _buildDateHeader(),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DispatcherSearchField(
                hintText: 'ابحث عن رحلة/سائق/مركبة...',
                value: _searchQuery,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () => setState(() => _searchQuery = ''),
              ),
            ).animate().fadeIn(duration: 250.ms),
            // Active filters chips
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _buildActiveFiltersRow(),
              ).animate().fadeIn(duration: 200.ms),

            // Trips Content
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
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'dispatcher_trips_fab',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('${RoutePaths.dispatcherHome}/trips/create');
          },
          icon: const Icon(Icons.add_rounded),
          label:
              const Text('رحلة جديدة', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.dispatcherPrimary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_rounded,
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
                  DateFormat('EEEE', 'ar').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  DateFormat('d MMMM yyyy', 'ar').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate =
                        _selectedDate.subtract(const Duration(days: 1));
                  });
                  ref.invalidate(dispatcherTripsProvider(_tripFilters));
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                  ref.invalidate(dispatcherTripsProvider(_tripFilters));
                },
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTripsTab(AsyncValue<List<Trip>> tripsAsync, TripState? filter) {
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
                .where((t) =>
                    t.currentLatitude != null && t.currentLongitude != null)
                .toList();
          }

          final q = _searchQuery.trim().toLowerCase();
          if (q.isNotEmpty) {
            filteredTrips = filteredTrips.where((t) {
              final name = t.name.toLowerCase();
              final driver = (t.driverName ?? '').toLowerCase();
              final vehicle = (t.vehicleName ?? '').toLowerCase();
              return name.contains(q) ||
                  driver.contains(q) ||
                  vehicle.contains(q);
            }).toList();
          }

          if (filteredTrips.isEmpty) {
            return EmptyState(
              icon: Icons.route_rounded,
              title: 'لا توجد رحلات',
              message: filter == null
                  ? (_searchQuery.trim().isNotEmpty
                      ? 'لا توجد نتائج مطابقة للبحث'
                      : (_hasActiveFilters
                          ? 'لا توجد نتائج مطابقة للفلاتر'
                          : 'لا توجد رحلات مجدولة لهذا اليوم'))
                  : (_searchQuery.trim().isNotEmpty
                      ? 'لا توجد نتائج مطابقة للبحث'
                      : (_hasActiveFilters
                          ? 'لا توجد نتائج مطابقة للفلاتر'
                          : 'لا توجد رحلات ${filter.arabicLabel}')),
              buttonText: 'إنشاء رحلة جديدة',
              onButtonPressed: () {
                context.go('${RoutePaths.dispatcherHome}/trips/create');
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
          // Navigate to trip details
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
                            Text(
                              trip.plannedStartTime != null
                                  ? DateFormat('HH:mm')
                                      .format(trip.plannedStartTime!)
                                  : '--:--',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: trip.state.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trip.state.arabicLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trip.state.color,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.person_rounded,
                    trip.driverName ?? 'بدون سائق',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.directions_bus_rounded,
                    trip.vehicleName ?? 'بدون مركبة',
                    AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.people_rounded,
                    '${trip.totalPassengers}',
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const ShimmerCard(height: 140);
      },
    );
  }

  Widget _buildErrorState(String error) {
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
                      userId: userId, filters: _tripFilters),
                );
              }
              ref.invalidate(dispatcherTripsProvider(_tripFilters));
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
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

  int get _activeFiltersCount {
    var count = 0;
    if (_tripTypeFilter != null) count++;
    if (_onlyWithDriver) count++;
    if (_onlyWithVehicle) count++;
    if (_onlyWithGps) count++;
    return count;
  }

  Widget _buildFilterButton() {
    return IconButton(
      tooltip: 'فلترة',
      onPressed: _openFiltersSheet,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.tune_rounded),
          if (_activeFiltersCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$_activeFiltersCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.dispatcherPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow() {
    final chips = <Widget>[];

    if (_tripTypeFilter != null) {
      chips.add(
        InputChip(
          label: Text(
            _tripTypeFilter == TripType.pickup ? 'صعود' : 'نزول',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          onDeleted: () => setState(() => _tripTypeFilter = null),
        ),
      );
    }
    if (_onlyWithDriver) {
      chips.add(
        InputChip(
          label: const Text('بسائق', style: TextStyle(fontFamily: 'Cairo')),
          onDeleted: () => setState(() => _onlyWithDriver = false),
        ),
      );
    }
    if (_onlyWithVehicle) {
      chips.add(
        InputChip(
          label: const Text('بمركبة', style: TextStyle(fontFamily: 'Cairo')),
          onDeleted: () => setState(() => _onlyWithVehicle = false),
        ),
      );
    }
    if (_onlyWithGps) {
      chips.add(
        InputChip(
          label: const Text('GPS متاح', style: TextStyle(fontFamily: 'Cairo')),
          onDeleted: () => setState(() => _onlyWithGps = false),
        ),
      );
    }

    chips.add(
      TextButton.icon(
        onPressed: () {
          setState(() {
            _tripTypeFilter = null;
            _onlyWithDriver = false;
            _onlyWithVehicle = false;
            _onlyWithGps = false;
          });
        },
        icon: const Icon(Icons.clear_all_rounded, size: 18),
        label: const Text('مسح', style: TextStyle(fontFamily: 'Cairo')),
      ),
    );

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
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
                          const Icon(Icons.tune_rounded,
                              color: AppColors.dispatcherPrimary),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'فلترة متقدمة',
                              style: TextStyle(
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
                            child: const Text('إعادة ضبط',
                                style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'نوع الرحلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          ChoiceChip(
                            label: const Text('الكل',
                                style: TextStyle(fontFamily: 'Cairo')),
                            selected: localTripType == null,
                            onSelected: (_) =>
                                setLocal(() => localTripType = null),
                          ),
                          ChoiceChip(
                            label: const Text('صعود',
                                style: TextStyle(fontFamily: 'Cairo')),
                            selected: localTripType == TripType.pickup,
                            onSelected: (_) =>
                                setLocal(() => localTripType = TripType.pickup),
                          ),
                          ChoiceChip(
                            label: const Text('نزول',
                                style: TextStyle(fontFamily: 'Cairo')),
                            selected: localTripType == TripType.dropoff,
                            onSelected: (_) => setLocal(
                                () => localTripType = TripType.dropoff),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'خيارات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithDriver,
                        onChanged: (v) => setLocal(() => localWithDriver = v),
                        activeColor: AppColors.dispatcherPrimary,
                        title: const Text('فقط الرحلات التي لها سائق',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithVehicle,
                        onChanged: (v) => setLocal(() => localWithVehicle = v),
                        activeColor: AppColors.dispatcherPrimary,
                        title: const Text('فقط الرحلات التي لها مركبة',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithGps,
                        onChanged: (v) => setLocal(() => localWithGps = v),
                        activeColor: AppColors.dispatcherPrimary,
                        title: const Text('فقط الرحلات التي لديها GPS',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء',
                                  style: TextStyle(fontFamily: 'Cairo')),
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
                              child: const Text('تطبيق',
                                  style: TextStyle(fontFamily: 'Cairo')),
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
