import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../core/enums/enums.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/headers/dispatcher_unified_header.dart';
import '../widgets/headers/dispatcher_secondary_header.dart';
import '../widgets/common/dispatcher_footer.dart';
import '../widgets/common/dispatcher_action_fab.dart';

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
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(dispatcherGroupsProvider);

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
            _buildHeader(context, l10n, groupsAsync),

            // === شريط البحث والفلاتر (للموبايل فقط) ===
            _buildMobileSearchSection(context),

            // === Groups List ===
            Expanded(
              child: groupsAsync.when(
                data: (groups) => _buildGroupsList(groups),
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),

        // === Footer (Tablet/Desktop only) ===
        bottomNavigationBar: _buildFooter(groupsAsync),

        // === FAB (Mobile only) ===
        floatingActionButton: DispatcherActionFAB(
          actions: [
            DispatcherFabAction(
              icon: Icons.add_rounded,
              label: l10n.newGroup,
              isPrimary: true,
              onPressed: () {
                context.go('${RoutePaths.dispatcherHome}/groups/create');
              },
            ),
            if (_hasActiveFilters)
              DispatcherFabAction(
                icon: Icons.clear_all_rounded,
                label: l10n.clearFilters,
                onPressed: () {
                  setState(() {
                    _showActiveOnly = false;
                    _tripTypeFilter = null;
                    _onlyWithDriver = false;
                    _onlyWithVehicle = false;
                    _onlyWithDestination = false;
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
    AsyncValue<List<PassengerGroup>> groupsAsync,
  ) {
    return DispatcherUnifiedHeader(
      title: l10n.groupsManagement,
      subtitle: groupsAsync.maybeWhen(
        data: (groups) {
          final activeCount = groups.where((g) => g.active).length;
          return '${l10n.total}: ${Formatters.formatSimple(groups.length)} • ${l10n.active}: ${Formatters.formatSimple(activeCount)}';
        },
        orElse: () => null,
      ),
      searchHint: l10n.searchGroupHint,
      searchValue: _searchQuery,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      onSearchClear: () => setState(() => _searchQuery = ''),
      showSearch: !context.isMobile,
      onRefresh: () async {
        // Save providers and container before async operations
        if (!mounted) return;
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        final container = ref.container;

        if (userId != 0) {
          await cache.delete(DispatcherCacheKeys.groups(userId: userId));
        }

        // Check if widget is still mounted before using container
        if (mounted) {
          container.invalidate(dispatcherGroupsProvider);
        }
      },
      isLoading: groupsAsync.isLoading,
      actions: [
        const RoleSwitcherButton(),
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
          label: l10n.newGroup,
          isPrimary: true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('${RoutePaths.dispatcherHome}/groups/create');
          },
        ),
        if (_hasActiveFilters)
          DispatcherHeaderAction(
            icon: Icons.clear_all_rounded,
            label: l10n.clearFilters,
            onPressed: () {
              setState(() {
                _showActiveOnly = false;
                _tripTypeFilter = null;
                _onlyWithDriver = false;
                _onlyWithVehicle = false;
                _onlyWithDestination = false;
              });
            },
          ),
      ],
      stats: groupsAsync.maybeWhen(
        data: (groups) {
          final activeGroups = groups.where((g) => g.active).length;
          final totalMembers = groups.fold(0, (sum, g) => sum + g.memberCount);
          return [
            DispatcherHeaderStat(
              icon: Icons.groups_rounded,
              label: l10n.groups,
              value: Formatters.formatSimple(activeGroups),
            ),
            DispatcherHeaderStat(
              icon: Icons.people_rounded,
              label: l10n.passengers,
              value: Formatters.formatSimple(totalMembers),
            ),
            DispatcherHeaderStat(
              icon: Icons.event_repeat_rounded,
              label: '${l10n.trips}/${l10n.week}',
              value: Formatters.formatSimple(activeGroups * 10),
            ),
          ];
        },
        orElse: () => [],
      ),
      filters: context.isMobile ? [] : _buildActiveFilterChips(),
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
                hintText: AppLocalizations.of(context).searchGroupHint,
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

  List<Widget> _buildActiveFilterChips() {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];

    if (_showActiveOnly) {
      chips.add(
        DispatcherFilterChip(
          label: l10n.activeOnly,
          isSelected: true,
          onTap: () => setState(() => _showActiveOnly = false),
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
      );
    }

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
      chips.add(
        DispatcherFilterChip(
          label: l10n.withVehicle,
          isSelected: true,
          onTap: () => setState(() => _onlyWithVehicle = false),
          icon: Icons.directions_bus_rounded,
          color: AppColors.warning,
        ),
      );
    }

    if (_onlyWithDestination) {
      chips.add(
        DispatcherFilterChip(
          label: l10n.hasDestination,
          isSelected: true,
          onTap: () => setState(() => _onlyWithDestination = false),
          icon: Icons.place_rounded,
          color: AppColors.info,
        ),
      );
    }

    return chips;
  }

  Widget _buildFooter(AsyncValue<List<PassengerGroup>> groupsAsync) {
    final l10n = AppLocalizations.of(context);
    return groupsAsync.maybeWhen(
      data: (groups) {
        final filteredCount = _getFilteredGroups(groups).length;
        final totalCount = groups.length;
        final activeCount = groups.where((g) => g.active).length;
        final totalMembers = groups.fold(0, (sum, g) => sum + g.memberCount);

        return DispatcherFooter(
          hideOnMobile: true,
          info: filteredCount != totalCount
              ? '${l10n.showingOf} ${Formatters.formatSimple(filteredCount)} ${l10n.ofText} ${Formatters.formatSimple(totalCount)} ${l10n.group}'
              : '${l10n.total}: ${Formatters.formatSimple(totalCount)} ${l10n.group}',
          stats: [
            DispatcherFooterStat(
              icon: Icons.check_circle_rounded,
              label: l10n.active,
              value: Formatters.formatSimple(activeCount),
              color: AppColors.success,
            ),
            DispatcherFooterStat(
              icon: Icons.people_rounded,
              label: l10n.passengerSingular,
              value: Formatters.formatSimple(totalMembers),
            ),
          ],
          lastUpdated: DateTime.now(),
          syncStatus: DispatcherSyncStatus.synced,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  List<PassengerGroup> _getFilteredGroups(List<PassengerGroup> groups) {
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
      filteredGroups = filteredGroups
          .where((g) => g.tripType == _tripTypeFilter)
          .toList();
    }
    if (_onlyWithDriver) {
      filteredGroups = filteredGroups.where((g) => g.driverId != null).toList();
    }
    if (_onlyWithVehicle) {
      filteredGroups = filteredGroups
          .where((g) => g.vehicleId != null)
          .toList();
    }
    if (_onlyWithDestination) {
      filteredGroups = filteredGroups.where((g) => g.hasDestination).toList();
    }

    return filteredGroups;
  }

  Widget _buildGroupsList(List<PassengerGroup> groups) {
    final l10n = AppLocalizations.of(context);
    final filteredGroups = _getFilteredGroups(groups);

    if (filteredGroups.isEmpty) {
      return EmptyState(
        icon: Icons.groups_rounded,
        title: l10n.noGroupsFound,
        message: _searchQuery.isNotEmpty
            ? l10n.noMatchingSearch
            : l10n.noGroupsCreated,
        buttonText: l10n.createGroup,
        onButtonPressed: () {
          context.go('${RoutePaths.dispatcherHome}/groups/create');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Save providers and container before async operations
        if (!mounted) return;
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        final container = ref.container;

        if (userId != 0) {
          await cache.delete(DispatcherCacheKeys.groups(userId: userId));
        }

        // Check if widget is still mounted before using container
        if (mounted) {
          container.invalidate(dispatcherGroupsProvider);
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          context.isMobile ? 96 : 16, // مساحة إضافية للـ FAB على الهاتف
        ),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                              AppLocalizations.of(ctx).groupFilters,
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
                                localActiveOnly = false;
                                localTripType = null;
                                localWithDriver = false;
                                localWithVehicle = false;
                                localWithDestination = false;
                              });
                            },
                            child: Text(
                              AppLocalizations.of(ctx).reset,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localActiveOnly,
                        onChanged: (v) => setLocal(() => localActiveOnly = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: Text(
                          AppLocalizations.of(ctx).activeOnly,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                            selected: localTripType == GroupTripType.pickup,
                            onSelected: (_) => setLocal(
                              () => localTripType = GroupTripType.pickup,
                            ),
                          ),
                          ChoiceChip(
                            label: Text(
                              AppLocalizations.of(ctx).dropoff,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            selected: localTripType == GroupTripType.dropoff,
                            onSelected: (_) => setLocal(
                              () => localTripType = GroupTripType.dropoff,
                            ),
                          ),
                          ChoiceChip(
                            label: Text(
                              AppLocalizations.of(ctx).bothPickupDropoff,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            selected: localTripType == GroupTripType.both,
                            onSelected: (_) => setLocal(
                              () => localTripType = GroupTripType.both,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                          AppLocalizations.of(ctx).linkedToDriver,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithVehicle,
                        onChanged: (v) => setLocal(() => localWithVehicle = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: Text(
                          AppLocalizations.of(ctx).linkedToVehicle,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithDestination,
                        onChanged: (v) =>
                            setLocal(() => localWithDestination = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: Text(
                          AppLocalizations.of(ctx).hasDestination,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                  _showActiveOnly = localActiveOnly;
                                  _tripTypeFilter = localTripType;
                                  _onlyWithDriver = localWithDriver;
                                  _onlyWithVehicle = localWithVehicle;
                                  _onlyWithDestination = localWithDestination;
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
              context.go('${RoutePaths.dispatcherHome}/groups/${group.id}');
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
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
                                    group.tripType.getLocalizedLabel(context),
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
                                  '${Formatters.formatSimple(group.memberCount)} ${AppLocalizations.of(context).passengerSingular}',
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
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              Icons.person_rounded,
                              group.driverName ??
                                  AppLocalizations.of(context).notAssigned,
                              group.hasDriver
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                            _buildInfoChip(
                              Icons.directions_bus_rounded,
                              group.vehicleName ??
                                  AppLocalizations.of(context).notAssigned,
                              group.hasVehicle
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_rounded),
                        color: AppColors.success,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go(
                            '${RoutePaths.dispatcherHome}/trips/create?groupId=${group.id}',
                          );
                        },
                        tooltip: AppLocalizations.of(context).generateTrip,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms, delay: (index * 50).ms);
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
              style: TextStyle(fontSize: 11, color: color, fontFamily: 'Cairo'),
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
              // Save providers and container before async operations
              if (!mounted) return;
              final cache = ref.read(dispatcherCacheDataSourceProvider);
              final userId =
                  ref.read(authStateProvider).asData?.value.user?.id ?? 0;
              final container = ref.container;

              if (userId != 0) {
                await cache.delete(DispatcherCacheKeys.groups(userId: userId));
              }

              // Check if widget is still mounted before using container
              if (mounted) {
                container.invalidate(dispatcherGroupsProvider);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
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
              '${Formatters.formatSimple(group.memberCount)} ${AppLocalizations.of(context).passengerSingular} • ${group.tripType.getLocalizedLabel(context)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              icon: Icons.play_circle_rounded,
              label: AppLocalizations.of(context).generateTrip,
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
              label: AppLocalizations.of(context).manageSchedules,
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '${RoutePaths.dispatcherHome}/groups/${group.id}/schedules',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.edit_rounded,
              label: AppLocalizations.of(context).editGroup,
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                context.go(
                  '${RoutePaths.dispatcherHome}/groups/${group.id}/edit',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.people_alt_rounded,
              label: AppLocalizations.of(context).viewPassengers,
              color: AppColors.dispatcherPrimary,
              onTap: () {
                Navigator.pop(context);
                context.go(
                  '${RoutePaths.dispatcherHome}/groups/${group.id}/passengers',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.delete_rounded,
              label: AppLocalizations.of(context).deleteGroup,
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteGroup(group);
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

  Future<void> _confirmDeleteGroup(PassengerGroup group) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteGroupTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.deleteGroupConfirm.replaceAll('{name}', group.name),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticFeedback.mediumImpact();

    // Save providers and container before async operations
    if (!mounted) return;
    final groupActionsNotifier = ref.read(groupActionsProvider.notifier);
    final cache = ref.read(dispatcherCacheDataSourceProvider);
    final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
    final container = ref.container;

    final success = await groupActionsNotifier.deleteGroup(group.id);

    if (!mounted) return;

    if (success) {
      // Clear cache and refresh
      if (userId != 0) {
        await cache.delete(DispatcherCacheKeys.groups(userId: userId));
      }

      // Check if widget is still mounted before using container
      if (mounted) {
        container.invalidate(dispatcherGroupsProvider);
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.groupDeleted.replaceAll('{name}', group.name),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.failedToDeleteGroup,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }
}
