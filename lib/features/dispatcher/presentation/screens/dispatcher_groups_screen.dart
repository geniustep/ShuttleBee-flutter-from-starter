import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/dispatcher_app_bar.dart';
import '../widgets/dispatcher_search_field.dart';

/// Dispatcher Groups Screen - شاشة إدارة المجموعات للمرسل - ShuttleBee
class DispatcherGroupsScreen extends ConsumerStatefulWidget {
  const DispatcherGroupsScreen({super.key});

  @override
  ConsumerState<DispatcherGroupsScreen> createState() =>
      _DispatcherGroupsScreenState();
}

class _DispatcherGroupsScreenState
    extends ConsumerState<DispatcherGroupsScreen> {
  String _searchQuery = '';
  bool _showActiveOnly = true;
  GroupTripType? _tripTypeFilter;
  bool _onlyWithDriver = false;
  bool _onlyWithVehicle = false;
  bool _onlyWithDestination = false;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(dispatcherGroupsProvider);

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) return true;
        context.go(RoutePaths.dispatcherHome);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: DispatcherAppBar(
          title: 'إدارة المجموعات',
          actions: [
            const RoleSwitcherButton(),
            _buildAdvancedFilterButton(),
            IconButton(
              icon: Icon(
                _showActiveOnly
                    ? Icons.filter_alt_rounded
                    : Icons.filter_alt_off_rounded,
              ),
              onPressed: () {
                setState(() {
                  _showActiveOnly = !_showActiveOnly;
                });
              },
              tooltip: _showActiveOnly ? 'إظهار الكل' : 'النشطة فقط',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () async {
                final cache = ref.read(dispatcherCacheDataSourceProvider);
                final userId =
                    ref.read(authStateProvider).asData?.value.user?.id ?? 0;
                if (userId != 0) {
                  await cache
                      .delete(DispatcherCacheKeys.groups(userId: userId));
                }
                ref.invalidate(dispatcherGroupsProvider);
              },
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _buildActiveFiltersRow(),
              ).animate().fadeIn(duration: 200.ms),

            // Stats Summary
            groupsAsync.when(
              data: (groups) => _buildStatsSummary(groups),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Groups List
            Expanded(
              child: groupsAsync.when(
                data: (groups) => _buildGroupsList(groups),
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'dispatcher_groups_fab',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('${RoutePaths.dispatcherHome}/groups/create');
          },
          icon: const Icon(Icons.add_rounded),
          label:
              const Text('مجموعة جديدة', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.dispatcherPrimary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: DispatcherSearchField(
        hintText: 'ابحث عن مجموعة...',
        value: _searchQuery,
        onChanged: (value) => setState(() => _searchQuery = value),
        onClear: () => setState(() => _searchQuery = ''),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatsSummary(List<PassengerGroup> groups) {
    final activeGroups = groups.where((g) => g.active).length;
    final totalMembers = groups.fold(0, (sum, g) => sum + g.memberCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.dispatcherGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.groups_rounded,
            label: 'المجموعات',
            value: '$activeGroups',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.people_rounded,
            label: 'إجمالي الركاب',
            value: '$totalMembers',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.event_repeat_rounded,
            label: 'رحلات/أسبوع',
            value: '${activeGroups * 10}',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsList(List<PassengerGroup> groups) {
    var filteredGroups = groups;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredGroups = filteredGroups
          .where(
            (g) =>
                g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (g.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                    false),
          )
          .toList();
    }

    // Apply active filter
    if (_showActiveOnly) {
      filteredGroups = filteredGroups.where((g) => g.active).toList();
    }

    if (_tripTypeFilter != null) {
      filteredGroups =
          filteredGroups.where((g) => g.tripType == _tripTypeFilter).toList();
    }
    if (_onlyWithDriver) {
      filteredGroups = filteredGroups.where((g) => g.driverId != null).toList();
    }
    if (_onlyWithVehicle) {
      filteredGroups =
          filteredGroups.where((g) => g.vehicleId != null).toList();
    }
    if (_onlyWithDestination) {
      filteredGroups = filteredGroups.where((g) => g.hasDestination).toList();
    }

    if (filteredGroups.isEmpty) {
      return EmptyState(
        icon: Icons.groups_rounded,
        title: 'لا توجد مجموعات',
        message: _searchQuery.isNotEmpty
            ? 'لم يتم العثور على نتائج للبحث'
            : 'لم يتم إنشاء أي مجموعة بعد',
        buttonText: 'إنشاء مجموعة',
        onButtonPressed: () {
          context.go('${RoutePaths.dispatcherHome}/groups/create');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        if (userId != 0) {
          await cache.delete(DispatcherCacheKeys.groups(userId: userId));
        }
        ref.invalidate(dispatcherGroupsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredGroups.length,
        itemBuilder: (context, index) {
          final group = filteredGroups[index];
          return _buildGroupCard(group, index);
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _showActiveOnly ||
      _tripTypeFilter != null ||
      _onlyWithDriver ||
      _onlyWithVehicle ||
      _onlyWithDestination;

  int get _activeFiltersCount {
    var c = 0;
    if (_showActiveOnly) c++;
    if (_tripTypeFilter != null) c++;
    if (_onlyWithDriver) c++;
    if (_onlyWithVehicle) c++;
    if (_onlyWithDestination) c++;
    return c;
  }

  Widget _buildAdvancedFilterButton() {
    return IconButton(
      tooltip: 'فلترة متقدمة',
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
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dispatcherPrimary,
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

    if (_showActiveOnly) {
      chips.add(
        InputChip(
          label: const Text('نشطة فقط', style: TextStyle(fontFamily: 'Cairo')),
          onDeleted: () => setState(() => _showActiveOnly = false),
        ),
      );
    }
    if (_tripTypeFilter != null) {
      chips.add(
        InputChip(
          label: Text(
            _tripTypeFilter!.arabicLabel,
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
    if (_onlyWithDestination) {
      chips.add(
        InputChip(
          label: const Text('لها وجهة', style: TextStyle(fontFamily: 'Cairo')),
          onDeleted: () => setState(() => _onlyWithDestination = false),
        ),
      );
    }

    chips.add(
      TextButton.icon(
        onPressed: () {
          setState(() {
            _showActiveOnly = false;
            _tripTypeFilter = null;
            _onlyWithDriver = false;
            _onlyWithVehicle = false;
            _onlyWithDestination = false;
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
        bool localActiveOnly = _showActiveOnly;
        GroupTripType? localTripType = _tripTypeFilter;
        bool localWithDriver = _onlyWithDriver;
        bool localWithVehicle = _onlyWithVehicle;
        bool localWithDestination = _onlyWithDestination;

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Container(
              margin: const EdgeInsets.only(top: 100),
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
                              'فلترة المجموعات',
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
                                localActiveOnly = false;
                                localTripType = null;
                                localWithDriver = false;
                                localWithVehicle = false;
                                localWithDestination = false;
                              });
                            },
                            child: const Text(
                              'إعادة ضبط',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localActiveOnly,
                        onChanged: (v) => setLocal(() => localActiveOnly = v),
                        activeColor: AppColors.dispatcherPrimary,
                        title: const Text('نشطة فقط',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      const SizedBox(height: 8),
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
                            label: const Text('صعود فقط',
                                style: TextStyle(fontFamily: 'Cairo')),
                            selected: localTripType == GroupTripType.pickup,
                            onSelected: (_) => setLocal(
                                () => localTripType = GroupTripType.pickup),
                          ),
                          ChoiceChip(
                            label: const Text('نزول فقط',
                                style: TextStyle(fontFamily: 'Cairo')),
                            selected: localTripType == GroupTripType.dropoff,
                            onSelected: (_) => setLocal(
                                () => localTripType = GroupTripType.dropoff),
                          ),
                          ChoiceChip(
                            label: const Text('صعود ونزول',
                                style: TextStyle(fontFamily: 'Cairo')),
                            selected: localTripType == GroupTripType.both,
                            onSelected: (_) => setLocal(
                                () => localTripType = GroupTripType.both),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                        title: const Text('مرتبطة بسائق',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithVehicle,
                        onChanged: (v) => setLocal(() => localWithVehicle = v),
                        activeColor: AppColors.dispatcherPrimary,
                        title: const Text('مرتبطة بمركبة',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithDestination,
                        onChanged: (v) =>
                            setLocal(() => localWithDestination = v),
                        activeColor: AppColors.dispatcherPrimary,
                        title: const Text('لها وجهة',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      const SizedBox(height: 12),
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
                                  _showActiveOnly = localActiveOnly;
                                  _tripTypeFilter = localTripType;
                                  _onlyWithDriver = localWithDriver;
                                  _onlyWithVehicle = localWithVehicle;
                                  _onlyWithDestination = localWithDestination;
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

  Widget _buildGroupCard(PassengerGroup group, int index) {
    final tripTypeColor = switch (group.tripType) {
      GroupTripType.pickup => AppColors.primary,
      GroupTripType.dropoff => AppColors.success,
      GroupTripType.both => AppColors.dispatcherPrimary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showGroupActions(group);
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
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tripTypeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      size: 28,
                      color: tripTypeColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (group.code != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  group.code!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tripTypeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                group.tripType.arabicLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: tripTypeColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.people_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.memberCount} راكب',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ],
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
                    group.driverName ?? 'بدون سائق',
                    group.hasDriver
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.directions_bus_rounded,
                    group.vehicleName ?? 'بدون مركبة',
                    group.hasVehicle
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.play_circle_rounded),
                    color: AppColors.success,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.go(
                        '${RoutePaths.dispatcherHome}/trips/create?groupId=${group.id}',
                      );
                    },
                    tooltip: 'توليد رحلة',
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                await cache.delete(DispatcherCacheKeys.groups(userId: userId));
              }
              ref.invalidate(dispatcherGroupsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showGroupActions(PassengerGroup group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${group.memberCount} راكب • ${group.tripType.arabicLabel}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              icon: Icons.play_circle_rounded,
              label: 'توليد رحلة جديدة',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                context.go(
                  '${RoutePaths.dispatcherHome}/trips/create?groupId=${group.id}',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.schedule_rounded,
              label: 'إدارة الجداول',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                context.go(
                  '${RoutePaths.dispatcherHome}/groups/${group.id}/schedules',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.edit_rounded,
              label: 'تعديل المجموعة',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                context
                    .go('${RoutePaths.dispatcherHome}/groups/${group.id}/edit');
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.people_alt_rounded,
              label: 'عرض الركاب',
              color: AppColors.dispatcherPrimary,
              onTap: () {
                Navigator.pop(context);
                context.go(
                  '${RoutePaths.dispatcherHome}/groups/${group.id}/passengers',
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
