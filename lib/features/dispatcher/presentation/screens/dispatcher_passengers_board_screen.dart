import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../domain/entities/passenger_group_line.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../providers/dispatcher_passenger_providers.dart';
import '../widgets/passengers/change_location_sheet.dart';
import '../widgets/common/dispatcher_app_bar.dart';
import '../widgets/headers/dispatcher_secondary_header.dart';
import '../widgets/common/dispatcher_footer.dart';
import '../widgets/passengers/passenger_quick_actions_sheet.dart';
import '../widgets/trips/select_trip_for_absence_sheet.dart';

/// Dispatcher Passengers Board
///
/// - Tab 1: Unassigned passengers (group_id = false)
/// - Tab 2: Groups list (open per-group passenger management)
/// - Tab 3: Kanban distribution board (drag & drop between columns)
class DispatcherPassengersBoardScreen extends ConsumerStatefulWidget {
  const DispatcherPassengersBoardScreen({super.key});

  @override
  ConsumerState<DispatcherPassengersBoardScreen> createState() =>
      _DispatcherPassengersBoardScreenState();
}

class _DispatcherPassengersBoardScreenState
    extends ConsumerState<DispatcherPassengersBoardScreen> {
  String _searchAll = '';
  String _searchUnassigned = '';
  String _searchGroups = '';
  String _searchKanban = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allPassengersAsync = ref.watch(dispatcherAllPassengersProvider);
    final unassignedAsync = ref.watch(dispatcherUnassignedPassengersProvider);
    final groupsAsync = ref.watch(dispatcherGroupsProvider);
    final actionsState = ref.watch(dispatcherPassengerActionsProvider);

    return DefaultTabController(
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: DispatcherAppBar(
          title: l10n.passengersManagement,
          subtitle: allPassengersAsync.maybeWhen(
            data: (items) {
              final unassignedCount = unassignedAsync.maybeWhen(
                data: (u) => u.length,
                orElse: () => 0,
              );
              return '${l10n.total}: ${Formatters.formatSimple(items.length)} • ${l10n.unassigned}: ${Formatters.formatSimple(unassignedCount)}';
            },
            orElse: () => null,
          ),
          actions: [
            IconButton(
              tooltip: l10n.refresh,
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(dispatcherAllPassengersProvider);
                ref.invalidate(dispatcherUnassignedPassengersProvider);
                ref.invalidate(dispatcherGroupsProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: l10n.allPassengers),
              Tab(text: l10n.unassigned),
              Tab(text: l10n.byGroups),
              Tab(text: l10n.distributionBoard),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // All Passengers Tab
            Column(
              children: [
                allPassengersAsync.maybeWhen(
                  data: (items) => DispatcherSecondaryHeader(
                    searchHint: l10n.searchAllPassengers,
                    searchValue: _searchAll,
                    onSearchChanged: (v) => setState(() => _searchAll = v),
                    onSearchClear: () => setState(() => _searchAll = ''),
                    stats: [
                      DispatcherStatChip(
                        icon: Icons.people_rounded,
                        label: l10n.total,
                        value: Formatters.formatSimple(items.length),
                        color: AppColors.dispatcherPrimary,
                      ),
                      DispatcherStatChip(
                        icon: Icons.groups_rounded,
                        label: l10n.groups,
                        value: Formatters.formatSimple(
                          items.where((e) => e.groupId != null).length,
                        ),
                        color: AppColors.success,
                      ),
                      DispatcherStatChip(
                        icon: Icons.person_off_rounded,
                        label: l10n.unassigned,
                        value: Formatters.formatSimple(
                          items.where((e) => e.groupId == null).length,
                        ),
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      allPassengersAsync.when(
                        data: (items) {
                          var filtered = items;
                          if (_searchAll.trim().isNotEmpty) {
                            final q = _searchAll.trim().toLowerCase();
                            filtered = items
                                .where(
                                  (e) =>
                                      e.passengerName
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.passengerPhone ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.passengerMobile ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.fatherPhone ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.motherPhone ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.guardianPhone ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.groupName ?? '')
                                          .toLowerCase()
                                          .contains(q),
                                )
                                .toList();
                          }

                          if (filtered.isEmpty) {
                            return EmptyState(
                              icon: Icons.person_off_rounded,
                              title: l10n.noPassengers,
                              message: _searchAll.isNotEmpty
                                  ? l10n.noMatchingResults
                                  : l10n.noPassengersInSystem,
                              buttonText: l10n.addNewPassenger,
                              onButtonPressed: () => context
                                  .go(RoutePaths.dispatcherCreatePassenger),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final line = filtered[index];
                              return _AllPassengerCard(
                                key: ValueKey('all_${line.id}'),
                                lineId: line.id,
                                passengerId: line.passengerId,
                                passengerName: line.passengerName,
                                phone: line.passengerPhone,
                                mobile: line.passengerMobile,
                                fatherPhone: line.fatherPhone,
                                motherPhone: line.motherPhone,
                                guardianPhone: line.guardianPhone,
                                groupName: line.groupName,
                                onOpenDetails: () => context.push(
                                  '${RoutePaths.dispatcherPassengers}/p/${line.passengerId}',
                                ),
                              ).animate().fadeIn(
                                    duration: 220.ms,
                                    delay: (index * 30).ms,
                                  );
                            },
                          );
                        },
                        loading: () => ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 8,
                          itemBuilder: (_, __) => const ShimmerCard(height: 84),
                        ),
                        error: (e, _) => _error(e.toString()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Unassigned
            Column(
              children: [
                unassignedAsync.maybeWhen(
                  data: (items) => DispatcherSecondaryHeader(
                    searchHint: l10n.searchUnassigned,
                    searchValue: _searchUnassigned,
                    onSearchChanged: (v) =>
                        setState(() => _searchUnassigned = v),
                    onSearchClear: () => setState(() => _searchUnassigned = ''),
                    stats: [
                      DispatcherStatChip(
                        icon: Icons.person_off_rounded,
                        label: l10n.unassigned,
                        value: Formatters.formatSimple(items.length),
                        color: AppColors.warning,
                      ),
                    ],
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go(RoutePaths.dispatcherCreatePassenger);
                        },
                        tooltip: l10n.addNewPassenger,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.dispatcherPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      unassignedAsync.when(
                        data: (items) {
                          var filtered = items;
                          if (_searchUnassigned.trim().isNotEmpty) {
                            final q = _searchUnassigned.trim().toLowerCase();
                            filtered = items
                                .where(
                                  (e) =>
                                      e.passengerName
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.passengerPhone ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.passengerMobile ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.fatherPhone ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.motherPhone ?? '')
                                          .toLowerCase()
                                          .contains(q) ||
                                      (e.guardianPhone ?? '')
                                          .toLowerCase()
                                          .contains(q),
                                )
                                .toList();
                          }

                          if (filtered.isEmpty) {
                            return EmptyState(
                              icon: Icons.person_off_rounded,
                              title: l10n.noPassengers,
                              message: _searchUnassigned.isNotEmpty
                                  ? l10n.noMatchingResults
                                  : l10n.allAssignedToGroups,
                              buttonText: l10n.addNewPassenger,
                              onButtonPressed: () => context
                                  .go(RoutePaths.dispatcherCreatePassenger),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final line = filtered[index];
                              return _UnassignedPassengerCard(
                                key: ValueKey('unassigned_${line.id}'),
                                lineId: line.id,
                                passengerId: line.passengerId,
                                passengerName: line.passengerName,
                                phone: line.passengerPhone,
                                fatherPhone: line.fatherPhone,
                                motherPhone: line.motherPhone,
                                guardianPhone: line.guardianPhone,
                                onAssign: () => _openAssignToGroupSheet(
                                  context,
                                  lineId: line.id,
                                  fromGroupId: null,
                                ),
                                onOpenDetails: () => context.push(
                                  '${RoutePaths.dispatcherPassengers}/p/${line.passengerId}',
                                ),
                              ).animate().fadeIn(
                                    duration: 220.ms,
                                    delay: (index * 30).ms,
                                  );
                            },
                          );
                        },
                        loading: () => ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 8,
                          itemBuilder: (_, __) => const ShimmerCard(height: 84),
                        ),
                        error: (e, _) => _error(e.toString()),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Groups
            Column(
              children: [
                groupsAsync.maybeWhen(
                  data: (groups) => DispatcherSecondaryHeader(
                    searchHint: l10n.searchGroup,
                    searchValue: _searchGroups,
                    onSearchChanged: (v) => setState(() => _searchGroups = v),
                    onSearchClear: () => setState(() => _searchGroups = ''),
                    stats: [
                      DispatcherStatChip(
                        icon: Icons.groups_rounded,
                        label: l10n.groups,
                        value: Formatters.formatSimple(groups.length),
                        color: AppColors.dispatcherPrimary,
                      ),
                      DispatcherStatChip(
                        icon: Icons.check_circle_rounded,
                        label: l10n.active,
                        value: Formatters.formatSimple(
                          groups.where((g) => g.active).length,
                        ),
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                Expanded(
                  child: groupsAsync.when(
                    data: (groups) {
                      var filtered = groups;
                      if (_searchGroups.trim().isNotEmpty) {
                        final q = _searchGroups.trim().toLowerCase();
                        filtered = groups
                            .where(
                              (g) =>
                                  g.name.toLowerCase().contains(q) ||
                                  (g.code ?? '').toLowerCase().contains(q),
                            )
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        return EmptyState(
                          icon: Icons.groups_rounded,
                          title: l10n.noGroups,
                          message: l10n.createGroupFirst,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final g = filtered[index];
                          return _GroupCard(
                            key: ValueKey('group_${g.id}'),
                            group: g,
                            onOpen: () {
                              HapticFeedback.lightImpact();
                              context.push(
                                '${RoutePaths.dispatcherPassengers}/groups/${g.id}',
                              );
                            },
                          )
                              .animate()
                              .fadeIn(duration: 220.ms, delay: (index * 30).ms);
                        },
                      );
                    },
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 8,
                      itemBuilder: (_, __) => const ShimmerCard(height: 96),
                    ),
                    error: (e, _) => _error(e.toString()),
                  ),
                ),
              ],
            ),

            // Kanban distribution board (drag & drop)
            Column(
              children: [
                DispatcherSecondaryHeader(
                  searchHint: l10n.quickSearchBoard,
                  searchValue: _searchKanban,
                  onSearchChanged: (v) => setState(() => _searchKanban = v),
                  onSearchClear: () => setState(() => _searchKanban = ''),
                  stats: [
                    DispatcherStatChip(
                      icon: Icons.dashboard_rounded,
                      label: l10n.distributionBoard,
                      value: Formatters.formatSimple(
                        allPassengersAsync.maybeWhen(
                          data: (items) => items.length,
                          orElse: () => 0,
                        ),
                      ),
                      color: AppColors.dispatcherPrimary,
                    ),
                  ],
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _KanbanDistributionBoard(
                        searchQuery: _searchKanban,
                        groupsAsync: groupsAsync,
                        unassignedAsync: unassignedAsync,
                      ),
                      if (actionsState.isLoading)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.06),
                              alignment: Alignment.topCenter,
                              padding: const EdgeInsets.only(top: 8),
                              child: const LinearProgressIndicator(
                                minHeight: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: DispatcherFooter(
          info: allPassengersAsync.maybeWhen(
            data: (items) {
              final unassignedCount =
                  items.where((e) => e.groupId == null).length;
              return '${l10n.total}: ${Formatters.formatSimple(items.length)} • ${l10n.unassigned}: ${Formatters.formatSimple(unassignedCount)}';
            },
            orElse: () => l10n.passengersManagement,
          ),
          actions: [
            DispatcherFooterAction(
              icon: Icons.person_add_alt_1_rounded,
              label: l10n.addNewPassenger,
              isPrimary: true,
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.go(RoutePaths.dispatcherCreatePassenger);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error, style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  Future<void> _openAssignToGroupSheet(
    BuildContext context, {
    required int lineId,
    required int? fromGroupId,
  }) async {
    var groups = ref.read(dispatcherGroupsProvider).asData?.value ?? const [];
    if (groups.isEmpty) {
      try {
        groups = await ref.read(dispatcherGroupsProvider.future);
      } catch (_) {
        groups = const [];
      }
    }

    if (groups.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.noGroupsAvailable,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.only(top: 90),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (ctx) {
                      final l10n = AppLocalizations.of(ctx);
                      return Text(
                        l10n.moveToGroup,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final g = groups[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            foregroundColor: AppColors.dispatcherPrimary,
                            child: Icon(Icons.groups_rounded),
                          ),
                          title: Text(
                            g.name,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Builder(
                            builder: (ctx) {
                              final l10n = AppLocalizations.of(ctx);
                              return Text(
                                '${g.memberCount} ${l10n.passenger}',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                          trailing: SizedBox(
                            width: 92,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: AppColors.dispatcherPrimary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await ref
                                    .read(
                                      dispatcherPassengerActionsProvider
                                          .notifier,
                                    )
                                    .assignToGroup(
                                      lineId: lineId,
                                      groupId: g.id,
                                      fromGroupId: fromGroupId,
                                    );
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: Builder(
                                builder: (ctx) {
                                  final l10n = AppLocalizations.of(ctx);
                                  return Text(
                                    l10n.move,
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KanbanDistributionBoard extends ConsumerWidget {
  final String searchQuery;
  final AsyncValue<List<PassengerGroup>> groupsAsync;
  final AsyncValue<List<PassengerGroupLine>> unassignedAsync;

  const _KanbanDistributionBoard({
    required this.searchQuery,
    required this.groupsAsync,
    required this.unassignedAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return groupsAsync.when(
      data: (groups) {
        // Always show the "unassigned" column first.
        final sortedGroups = List<PassengerGroup>.from(groups)
          ..sort((a, b) => a.name.compareTo(b.name));

        return LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 330,
                    height: height,
                    child: _KanbanColumn(
                      title: AppLocalizations.of(context).unassigned,
                      color: AppColors.warning,
                      groupId: null,
                      linesAsync: unassignedAsync,
                      searchQuery: searchQuery,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...sortedGroups.map((g) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 330,
                        height: height,
                        child: _KanbanColumn(
                          title: g.name,
                          subtitle: '${g.memberCount} راكب',
                          color: AppColors.dispatcherPrimary,
                          groupId: g.id,
                          linesAsync: ref
                              .watch(dispatcherGroupPassengersProvider(g.id)),
                          searchQuery: searchQuery,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCard(height: 90),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            e.toString(),
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final int? groupId;
  final AsyncValue<List<PassengerGroupLine>> linesAsync;
  final String searchQuery;

  const _KanbanColumn({
    required this.title,
    this.subtitle,
    required this.color,
    required this.groupId,
    required this.linesAsync,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<PassengerGroupLine>(
      onWillAcceptWithDetails: (details) {
        return details.data.groupId != groupId;
      },
      onAcceptWithDetails: (details) async {
        final line = details.data;
        final rootContext = context;
        HapticFeedback.lightImpact();

        try {
          if (groupId == null) {
            // Move to unassigned.
            if (line.groupId != null) {
              await ref
                  .read(dispatcherPassengerActionsProvider.notifier)
                  .unassignFromGroup(lineId: line.id, groupId: line.groupId!);
            }
          } else {
            await ref
                .read(dispatcherPassengerActionsProvider.notifier)
                .assignToGroup(
                  lineId: line.id,
                  groupId: groupId!,
                  fromGroupId: line.groupId,
                );
          }
        } catch (e) {
          if (rootContext.mounted) {
            final l = AppLocalizations.of(rootContext);
            ScaffoldMessenger.of(rootContext).showSnackBar(
              SnackBar(
                content: Text(
                  '${l.move}: $e',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      builder: (context, candidate, rejected) {
        final isHighlighted = candidate.isNotEmpty;
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHighlighted ? color : Colors.transparent,
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          groupId == null
                              ? Icons.person_off_rounded
                              : Icons.groups_rounded,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (ctx) {
                          return IconButton(
                            tooltip: AppLocalizations.of(ctx).refresh,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              if (groupId == null) {
                                ref.invalidate(
                                  dispatcherUnassignedPassengersProvider,
                                );
                              } else {
                                ref.invalidate(
                                  dispatcherGroupPassengersProvider(
                                    groupId!,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.refresh_rounded),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: linesAsync.when(
                    data: (lines) {
                      var filtered = lines;
                      final q = searchQuery.trim().toLowerCase();
                      if (q.isNotEmpty) {
                        filtered = lines
                            .where(
                              (e) =>
                                  e.passengerName.toLowerCase().contains(q) ||
                                  (e.passengerPhone ?? '')
                                      .toLowerCase()
                                      .contains(q) ||
                                  (e.passengerMobile ?? '')
                                      .toLowerCase()
                                      .contains(q) ||
                                  (e.guardianPhone ?? '')
                                      .toLowerCase()
                                      .contains(q),
                            )
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            q.isNotEmpty ? 'لا توجد نتائج' : 'فارغ',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final line = filtered[index];
                          return _KanbanPassengerCard(
                            key: ValueKey('kanban_line_${line.id}'),
                            line: line,
                            accentColor: color,
                          );
                        },
                      );
                    },
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      itemCount: 6,
                      itemBuilder: (_, __) => const ShimmerCard(height: 74),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          e.toString(),
                          style: const TextStyle(fontFamily: 'Cairo'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KanbanPassengerCard extends ConsumerWidget {
  final PassengerGroupLine line;
  final Color accentColor;

  const _KanbanPassengerCard({
    super.key,
    required this.line,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use new guardian phone fields, fallback to legacy
    final phone = line.guardianContactDisplay.isNotEmpty
        ? line.guardianContactDisplay
        : (line.passengerPhone ?? line.passengerMobile ?? '');

    final card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          _showQuickActions(context, ref);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.passengerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _pill(
                          icon: Icons.event_seat_rounded,
                          text: '${line.seatCount}',
                          color: AppColors.primary,
                        ),
                        if ((line.pickupInfoDisplay ?? '').trim().isNotEmpty)
                          _pill(
                            icon: Icons.arrow_upward_rounded,
                            text: AppLocalizations.of(context).pickup,
                            color: Colors.blue,
                          ),
                        if ((line.dropoffInfoDisplay ?? '').trim().isNotEmpty)
                          _pill(
                            icon: Icons.arrow_downward_rounded,
                            text: AppLocalizations.of(context).dropoff,
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Quick actions button
              IconButton(
                icon: const Icon(
                  Icons.flash_on_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                tooltip: AppLocalizations.of(context).quickActions,
                onPressed: () => _showQuickActions(context, ref),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              const Icon(
                Icons.drag_indicator_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );

    return LongPressDraggable<PassengerGroupLine>(
      data: line,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Opacity(
            opacity: 0.95,
            child: card,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    PassengerQuickActionsSheet.show(
      context,
      passengerId: line.passengerId,
      passengerName: line.passengerName,
      onEditProfile: () {
        context.push(
          '${RoutePaths.dispatcherPassengers}/p/${line.passengerId}',
        );
      },
      onChangeLocation: () {
        ChangeLocationSheet.show(
          context,
          passengerId: line.passengerId,
          passengerName: line.passengerName,
        );
      },
      onMarkAbsent: () async {
        final result = await SelectTripForAbsenceSheet.show(
          context,
          passengerId: line.passengerId,
          passengerName: line.passengerName,
        );

        if (result != null && context.mounted) {
          // Mark as absent using trip repository
          final repository = ref.read(tripRepositoryProvider);
          if (repository == null) {
            if (context.mounted) {
              final l = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l.cannotConnectServer,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }

          final apiResult =
              await repository.markPassengerAbsent(result.tripLineId);
          final success = apiResult.isRight();

          if (context.mounted) {
            final l = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? '${l.absenceRecorded} ${line.passengerName} ${l.inText} ${result.tripName}'
                      : l.absenceFailed,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ),
            );
          }
        }
      },
    );
  }

  static Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnassignedPassengerCard extends ConsumerWidget {
  final int lineId;
  final int passengerId;
  final String passengerName;
  final String? phone;
  final String? fatherPhone;
  final String? motherPhone;
  final String? guardianPhone;
  final VoidCallback onAssign;
  final VoidCallback onOpenDetails;

  const _UnassignedPassengerCard({
    super.key,
    required this.lineId,
    required this.passengerId,
    required this.passengerName,
    this.phone,
    this.fatherPhone,
    this.motherPhone,
    this.guardianPhone,
    required this.onAssign,
    required this.onOpenDetails,
  });

  String _guardianDisplay(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (fatherPhone?.isNotEmpty ?? false) return '${l.father}: $fatherPhone';
    if (motherPhone?.isNotEmpty ?? false) return '${l.mother}: $motherPhone';
    if (guardianPhone?.isNotEmpty ?? false)
      return '${l.guardian}: $guardianPhone';
    return phone ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onOpenDetails();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _guardianDisplay(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Quick actions button
              IconButton(
                icon: const Icon(
                  Icons.flash_on_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                tooltip: AppLocalizations.of(context).quickActions,
                onPressed: () => _showQuickActions(context, ref),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 90,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.dispatcherPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onAssign,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: Text(
                    AppLocalizations.of(context).assign,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    PassengerQuickActionsSheet.show(
      context,
      passengerId: passengerId,
      passengerName: passengerName,
      onEditProfile: () {
        context.push(
          '${RoutePaths.dispatcherPassengers}/p/$passengerId',
        );
      },
      onChangeLocation: () {
        ChangeLocationSheet.show(
          context,
          passengerId: passengerId,
          passengerName: passengerName,
        );
      },
      onMarkAbsent: () async {
        final result = await SelectTripForAbsenceSheet.show(
          context,
          passengerId: passengerId,
          passengerName: passengerName,
        );

        if (result != null && context.mounted) {
          final repository = ref.read(tripRepositoryProvider);
          if (repository == null) {
            if (context.mounted) {
              final l = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l.cannotConnectServer,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }

          final apiResult =
              await repository.markPassengerAbsent(result.tripLineId);
          final success = apiResult.isRight();

          if (context.mounted) {
            final l = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? '${l.absenceRecorded} $passengerName ${l.inText} ${result.tripName}'
                      : l.absenceFailed,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ),
            );
          }
        }
      },
    );
  }
}

class _AllPassengerCard extends ConsumerWidget {
  final int lineId;
  final int passengerId;
  final String passengerName;
  final String? phone;
  final String? mobile;
  final String? fatherPhone;
  final String? motherPhone;
  final String? guardianPhone;
  final String? groupName;
  final VoidCallback onOpenDetails;

  const _AllPassengerCard({
    super.key,
    required this.lineId,
    required this.passengerId,
    required this.passengerName,
    this.phone,
    this.mobile,
    this.fatherPhone,
    this.motherPhone,
    this.guardianPhone,
    this.groupName,
    required this.onOpenDetails,
  });

  String _guardianDisplay(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (fatherPhone?.isNotEmpty ?? false) return '${l.father}: $fatherPhone';
    if (motherPhone?.isNotEmpty ?? false) return '${l.mother}: $motherPhone';
    if (guardianPhone?.isNotEmpty ?? false)
      return '${l.guardian}: $guardianPhone';
    return phone ?? mobile ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onOpenDetails();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.dispatcherPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.dispatcherPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Builder(
                      builder: (ctx) {
                        final display = _guardianDisplay(ctx);
                        if (display.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              display,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (groupName != null && groupName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          groupName!,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Quick actions button
              IconButton(
                icon: const Icon(
                  Icons.flash_on_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                tooltip: AppLocalizations.of(context).quickActions,
                onPressed: () => _showQuickActions(context, ref),
                visualDensity: VisualDensity.compact,
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    PassengerQuickActionsSheet.show(
      context,
      passengerId: passengerId,
      passengerName: passengerName,
      onEditProfile: () {
        context.push(
          '${RoutePaths.dispatcherPassengers}/p/$passengerId',
        );
      },
      onChangeLocation: () {
        ChangeLocationSheet.show(
          context,
          passengerId: passengerId,
          passengerName: passengerName,
        );
      },
      onMarkAbsent: () async {
        final result = await SelectTripForAbsenceSheet.show(
          context,
          passengerId: passengerId,
          passengerName: passengerName,
        );

        if (result != null && context.mounted) {
          final repository = ref.read(tripRepositoryProvider);
          if (repository == null) {
            if (context.mounted) {
              final l = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l.cannotConnectServer,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }

          final apiResult =
              await repository.markPassengerAbsent(result.tripLineId);
          final success = apiResult.isRight();

          if (context.mounted) {
            final l = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? '${l.absenceRecorded} $passengerName ${l.inText} ${result.tripName}'
                      : l.absenceFailed,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ),
            );
          }
        }
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  final PassengerGroup group;
  final VoidCallback onOpen;

  const _GroupCard({
    super.key,
    required this.group,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.groups_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} راكب • ${group.tripType.arabicLabel}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
