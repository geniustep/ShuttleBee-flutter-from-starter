import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../domain/entities/passenger_group_line.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../providers/dispatcher_passenger_providers.dart';
import '../widgets/dispatcher_app_bar.dart';
import '../widgets/dispatcher_search_field.dart';

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
  String _searchUnassigned = '';
  String _searchGroups = '';
  String _searchKanban = '';

  @override
  Widget build(BuildContext context) {
    final unassignedAsync = ref.watch(dispatcherUnassignedPassengersProvider);
    final groupsAsync = ref.watch(dispatcherGroupsProvider);
    final actionsState = ref.watch(dispatcherPassengerActionsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: DispatcherAppBar(
          title: 'إدارة الركّاب',
          actions: [
            IconButton(
              tooltip: 'إضافة راكب جديد',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go(RoutePaths.dispatcherCreatePassenger);
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(dispatcherUnassignedPassengersProvider);
                ref.invalidate(dispatcherGroupsProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            labelStyle:
                TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'غير مدرجين'),
              Tab(text: 'حسب المجموعات'),
              Tab(text: 'لوحة التوزيع'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Unassigned
            Column(
              children: [
                _buildSearchBar(
                  hint: 'ابحث في غير المدرجين...',
                  value: _searchUnassigned,
                  onChanged: (v) => setState(() => _searchUnassigned = v),
                  onClear: () => setState(() => _searchUnassigned = ''),
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
                                      (e.guardianPhone ?? '')
                                          .toLowerCase()
                                          .contains(q),
                                )
                                .toList();
                          }

                          if (filtered.isEmpty) {
                            return EmptyState(
                              icon: Icons.person_off_rounded,
                              title: 'لا يوجد ركّاب',
                              message: _searchUnassigned.isNotEmpty
                                  ? 'لا توجد نتائج مطابقة'
                                  : 'كل الركاب الحاليين مرتبطين بمجموعات.',
                              buttonText: 'إضافة راكب جديد',
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
                                  duration: 220.ms, delay: (index * 30).ms);
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
                _buildSearchBar(
                  hint: 'ابحث عن مجموعة...',
                  value: _searchGroups,
                  onChanged: (v) => setState(() => _searchGroups = v),
                  onClear: () => setState(() => _searchGroups = ''),
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
                        return const EmptyState(
                          icon: Icons.groups_rounded,
                          title: 'لا توجد مجموعات',
                          message: 'أنشئ مجموعة أولاً ثم أضف الركّاب.',
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
                                  '${RoutePaths.dispatcherPassengers}/groups/${g.id}');
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
                _buildSearchBar(
                  hint: 'بحث سريع في اللوحة...',
                  value: _searchKanban,
                  onChanged: (v) => setState(() => _searchKanban = v),
                  onClear: () => setState(() => _searchKanban = ''),
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
      ),
    );
  }

  Widget _buildSearchBar({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: DispatcherSearchField(
        hintText: hint,
        value: value,
        onChanged: onChanged,
        onClear: onClear,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد مجموعات متاحة',
              style: TextStyle(fontFamily: 'Cairo')),
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
                  const Text(
                    'نقل إلى مجموعة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                          subtitle: Text(
                            '${g.memberCount} راكب',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
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
                                    .read(dispatcherPassengerActionsProvider
                                        .notifier)
                                    .assignToGroup(
                                      lineId: lineId,
                                      groupId: g.id,
                                      fromGroupId: fromGroupId,
                                    );
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text(
                                'نقل',
                                style: TextStyle(fontFamily: 'Cairo'),
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
                      title: 'غير مدرجين',
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
      onWillAccept: (line) {
        if (line == null) return false;
        // No-op if dropped into same group.
        return line.groupId != groupId;
      },
      onAccept: (line) async {
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
            ScaffoldMessenger.of(rootContext).showSnackBar(
              SnackBar(
                content: Text(
                  'تعذر النقل: $e',
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
                      IconButton(
                        tooltip: 'تحديث',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (groupId == null) {
                            ref.invalidate(
                                dispatcherUnassignedPassengersProvider);
                          } else {
                            ref.invalidate(
                                dispatcherGroupPassengersProvider(groupId!));
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded),
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

class _KanbanPassengerCard extends StatelessWidget {
  final PassengerGroupLine line;
  final Color accentColor;

  const _KanbanPassengerCard({
    super.key,
    required this.line,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final phone = (line.guardianPhone?.isNotEmpty ?? false)
        ? 'ولي: ${line.guardianPhone}'
        : (line.passengerPhone ?? line.passengerMobile ?? '');

    final card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                          text: 'صعود',
                          color: Colors.blue,
                        ),
                      if ((line.dropoffInfoDisplay ?? '').trim().isNotEmpty)
                        _pill(
                          icon: Icons.arrow_downward_rounded,
                          text: 'نزول',
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.drag_indicator_rounded,
              color: AppColors.textSecondary,
            ),
          ],
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

class _UnassignedPassengerCard extends StatelessWidget {
  final int lineId;
  final int passengerId;
  final String passengerName;
  final String? phone;
  final String? guardianPhone;
  final VoidCallback onAssign;
  final VoidCallback onOpenDetails;

  const _UnassignedPassengerCard({
    super.key,
    required this.lineId,
    required this.passengerId,
    required this.passengerName,
    this.phone,
    this.guardianPhone,
    required this.onAssign,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
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
                      (guardianPhone?.isNotEmpty ?? false)
                          ? 'ولي: $guardianPhone'
                          : (phone ?? ''),
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
              const SizedBox(width: 10),
              SizedBox(
                width: 106,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.dispatcherPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onAssign,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text(
                    'تعيين',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
