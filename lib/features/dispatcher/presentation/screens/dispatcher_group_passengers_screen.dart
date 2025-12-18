import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../domain/entities/passenger_group_line.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../providers/dispatcher_passenger_providers.dart';
import '../widgets/dispatcher_add_passenger_sheet.dart';
import '../widgets/dispatcher_app_bar.dart';
import '../widgets/dispatcher_search_field.dart';

/// Manage passengers inside a specific group.
class DispatcherGroupPassengersScreen extends ConsumerStatefulWidget {
  final int groupId;

  const DispatcherGroupPassengersScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<DispatcherGroupPassengersScreen> createState() =>
      _DispatcherGroupPassengersScreenState();
}

class _DispatcherGroupPassengersScreenState
    extends ConsumerState<DispatcherGroupPassengersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    final passengersAsync =
        ref.watch(dispatcherGroupPassengersProvider(groupId));

    // Prefer cached dispatcher groups (fast), fallback to direct groups provider.
    final groupsCachedAsync = ref.watch(dispatcherGroupsProvider);
    final groupsAsync = ref.watch(allGroupsProvider);

    String groupName = 'مجموعة #$groupId';
    int vehicleSeats = 0;
    final cachedGroups = groupsCachedAsync.asData?.value;
    final directGroups = groupsAsync.asData?.value;
    final groups = cachedGroups ?? directGroups;
    if (groups != null) {
      for (final g in groups) {
        if (g.id == groupId) {
          groupName = g.name;
          vehicleSeats = g.totalSeats;
          break;
        }
      }
    }

    final actionsState = ref.watch(dispatcherPassengerActionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: DispatcherAppBar(
        title: 'ركّاب: $groupName',
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(dispatcherGroupPassengersProvider(groupId));
              ref.invalidate(dispatcherUnassignedPassengersProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Stack(
              children: [
                passengersAsync.when(
                  data: (items) => _buildPassengersList(
                    context,
                    groupId: groupId,
                    groupName: groupName,
                    items: items,
                    vehicleSeats: vehicleSeats,
                  ),
                  loading: () => _buildLoadingState(),
                  error: (e, _) => _buildErrorState(e.toString()),
                ),
                if (actionsState.isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.08),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 12),
                        child: const LinearProgressIndicator(minHeight: 3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dispatcher_group_passengers_fab_$groupId',
        onPressed: () => _openAddPassengerSheet(context, groupId, groupName),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('إضافة راكب', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.dispatcherPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: DispatcherSearchField(
        hintText: 'ابحث عن راكب...',
        value: _searchQuery,
        onChanged: (value) => setState(() => _searchQuery = value),
        onClear: () => setState(() => _searchQuery = ''),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildPassengersList(
    BuildContext context, {
    required int groupId,
    required String groupName,
    required List<PassengerGroupLine> items,
    required int vehicleSeats,
  }) {
    var filtered = items;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                (e.passengerName.toLowerCase().contains(q)) ||
                ((e.passengerPhone ?? '').toLowerCase().contains(q)) ||
                ((e.passengerMobile ?? '').toLowerCase().contains(q)) ||
                ((e.guardianPhone ?? '').toLowerCase().contains(q)),
          )
          .toList();
    }

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.people_alt_rounded,
        title: 'لا يوجد ركّاب',
        message: _searchQuery.isNotEmpty
            ? 'لا توجد نتائج مطابقة للبحث'
            : 'هذه المجموعة لا تحتوي على ركّاب بعد',
        buttonText: 'إضافة راكب',
        onButtonPressed: () =>
            _openAddPassengerSheet(context, groupId, groupName),
      );
    }

    final occupiedSeats = filtered.fold<int>(0, (sum, e) => sum + e.seatCount);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dispatcherGroupPassengersProvider(groupId));
        ref.invalidate(dispatcherUnassignedPassengersProvider);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              isMobile ? 96 : 16, // مساحة إضافية للـ FAB على الهاتف
            ),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSummaryCard(
                  passengersCount: filtered.length,
                  vehicleSeats: vehicleSeats,
                  occupiedSeats: occupiedSeats,
                );
              }

              final line = filtered[index - 1];
              return _buildPassengerCard(
                context,
                groupId: groupId,
                line: line,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required int passengersCount,
    required int vehicleSeats,
    required int occupiedSeats,
  }) {
    final availableSeats = vehicleSeats - occupiedSeats;
    final isOverCapacity = occupiedSeats > vehicleSeats;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.dispatcherGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(Icons.people_rounded, 'الركّاب', '$passengersCount'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _stat(
                Icons.event_seat_rounded,
                'مقاعد المركبة',
                '$vehicleSeats',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _stat(
                isOverCapacity
                    ? Icons.warning_rounded
                    : Icons.chair_alt_rounded,
                'المتاح',
                isOverCapacity ? '$availableSeats' : '$availableSeats',
                valueColor: isOverCapacity
                    ? const Color(0xFFFFCDD2)
                    : const Color(0xFFC8E6C9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar showing occupancy
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: vehicleSeats > 0
                  ? (occupiedSeats / vehicleSeats).clamp(0.0, 1.0)
                  : 0.0,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverCapacity
                    ? const Color(0xFFFF8A80)
                    : const Color(0xFFA5D6A7),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isOverCapacity
                ? '⚠️ تجاوز السعة بـ ${-availableSeats} مقعد'
                : 'مشغول: $occupiedSeats من $vehicleSeats مقعد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _stat(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.85),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerCard(
    BuildContext context, {
    required int groupId,
    required PassengerGroupLine line,
  }) {
    final subtitleParts = <String>[];

    final pickup = line.pickupInfoDisplay?.trim();
    final dropoff = line.dropoffInfoDisplay?.trim();
    if (pickup != null && pickup.isNotEmpty) {
      subtitleParts.add('📍 صعود: $pickup');
    }
    if (dropoff != null && dropoff.isNotEmpty) {
      subtitleParts.add('🏁 نزول: $dropoff');
    }

    final note = line.notes?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(
            '${RoutePaths.dispatcherPassengers}/p/${line.passengerId}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          AppColors.dispatcherPrimary.withValues(alpha: 0.12),
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
                          line.passengerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _chip(
                              icon: Icons.event_seat_rounded,
                              label: 'مقاعد: ${line.seatCount}',
                              color: AppColors.primary,
                            ),
                            if (line.passengerPhone?.isNotEmpty ?? false)
                              _chip(
                                icon: Icons.call_rounded,
                                label: line.passengerPhone!,
                                color: AppColors.textSecondary,
                              ),
                            if (line.guardianPhone?.isNotEmpty ?? false)
                              _chip(
                                icon: Icons.phone_in_talk_rounded,
                                label: 'ولي: ${line.guardianPhone}',
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'إجراءات',
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          _openEditLineDialog(
                            context,
                            groupId: groupId,
                            line: line,
                          );
                          break;
                        case 'move':
                          _openMoveToGroupSheet(
                            context,
                            fromGroupId: groupId,
                            lineId: line.id,
                          );
                          break;
                        case 'remove':
                          _confirmUnassign(
                            context,
                            groupId: groupId,
                            lineId: line.id,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded),
                            SizedBox(width: 10),
                            Text(
                              'تعديل',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'move',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded),
                            SizedBox(width: 10),
                            Text(
                              'نقل إلى مجموعة',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_remove_alt_1_rounded,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'إزالة من المجموعة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  subtitleParts.join('\n'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'ملاحظة: $note',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms);
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
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
          itemCount: 6,
          itemBuilder: (_, __) => const ShimmerCard(height: 120),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(fontFamily: 'Cairo'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(
                  dispatcherGroupPassengersProvider(widget.groupId),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddPassengerSheet(
    BuildContext context,
    int groupId,
    String groupName,
  ) async {
    HapticFeedback.lightImpact();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DispatcherAddPassengerSheet(
        groupId: groupId,
        groupName: groupName,
      ),
    );
  }

  Future<void> _openMoveToGroupSheet(
    BuildContext context, {
    required int fromGroupId,
    required int lineId,
  }) async {
    var groups = ref.read(dispatcherGroupsProvider).asData?.value ?? const [];
    if (groups.isEmpty) {
      try {
        groups = await ref.read(dispatcherGroupsProvider.future);
      } catch (_) {
        groups = const [];
      }
    }
    if (groups.isEmpty) return;

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
                        final disabled = g.id == fromGroupId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          enabled: !disabled,
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
                            disabled
                                ? 'المجموعة الحالية'
                                : '${g.memberCount} راكب',
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
                              onPressed: disabled
                                  ? null
                                  : () async {
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

  Future<void> _confirmUnassign(
    BuildContext context, {
    required int groupId,
    required int lineId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo')),
          content: const Text(
            'هل تريد إزالة هذا الراكب من المجموعة؟ سيصبح ضمن "غير مدرجين".',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إزالة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await ref
        .read(dispatcherPassengerActionsProvider.notifier)
        .unassignFromGroup(
          lineId: lineId,
          groupId: groupId,
        );
  }

  Future<void> _openEditLineDialog(
    BuildContext context, {
    required int groupId,
    required PassengerGroupLine line,
  }) async {
    final seatController = TextEditingController(text: '${line.seatCount}');
    final notesController = TextEditingController(text: line.notes ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title:
              const Text('تعديل الراكب', style: TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: seatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد المقاعد',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dispatcherPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final seat = int.tryParse(seatController.text.trim());
    final notes = notesController.text.trim();

    await ref.read(dispatcherPassengerActionsProvider.notifier).updateLine(
          lineId: line.id,
          groupId: groupId,
          seatCount: seat,
          notes: notes,
        );
  }
}
