import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/passenger_group_line.dart';
import '../../providers/dispatcher_passenger_providers.dart';
import '../../providers/dispatcher_cached_providers.dart';

/// Bottom sheet for bulk operations on selected passengers
class BulkOperationsSheet extends ConsumerWidget {
  final List<PassengerGroupLine> selectedPassengers;
  final VoidCallback? onClearSelection;

  const BulkOperationsSheet({
    super.key,
    required this.selectedPassengers,
    this.onClearSelection,
  });

  /// Show the bulk operations sheet
  static Future<void> show(
    BuildContext context, {
    required List<PassengerGroupLine> selectedPassengers,
    VoidCallback? onClearSelection,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BulkOperationsSheet(
        selectedPassengers: selectedPassengers,
        onClearSelection: onClearSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(dispatcherGroupsProvider);
    final actionsState = ref.watch(dispatcherPassengerActionsProvider);

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.dispatcherGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.select_all_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'عمليات مجمعة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${selectedPassengers.length} راكب محدد',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
            const Divider(height: 20),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Move to Group
                  groupsAsync.when(
                    data: (groups) {
                      if (groups.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _BulkActionButton(
                        icon: Icons.swap_horiz_rounded,
                        label: 'نقل إلى مجموعة',
                        color: AppColors.dispatcherPrimary,
                        onTap: () =>
                            _showMoveToGroupDialog(context, ref, groups),
                      ).animate().fadeIn(duration: 200.ms, delay: 50.ms);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  // Unassign from Group
                  _BulkActionButton(
                    icon: Icons.person_off_rounded,
                    label: 'إلغاء التعيين من المجموعة',
                    color: AppColors.warning,
                    onTap: () => _showUnassignDialog(context, ref),
                  ).animate().fadeIn(duration: 200.ms, delay: 100.ms),
                  const SizedBox(height: 12),
                  // Delete
                  _BulkActionButton(
                    icon: Icons.delete_rounded,
                    label: 'حذف الركاب',
                    color: AppColors.error,
                    onTap: () => _showDeleteDialog(context, ref),
                  ).animate().fadeIn(duration: 200.ms, delay: 150.ms),
                  const SizedBox(height: 12),
                  // Clear selection
                  _BulkActionButton(
                    icon: Icons.clear_all_rounded,
                    label: 'إلغاء التحديد',
                    color: AppColors.textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      onClearSelection?.call();
                    },
                  ).animate().fadeIn(duration: 200.ms, delay: 200.ms),
                ],
              ),
            ),
            if (actionsState.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoveToGroupDialog(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> groups,
  ) async {
    final selectedGroup = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'اختر المجموعة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: const Icon(Icons.groups_rounded),
                title: Text(
                  group.name ?? 'مجموعة #${group.id}',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                subtitle: Text(
                  '${group.memberCount ?? 0} راكب',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () => Navigator.pop(ctx, group.id),
              );
            },
          ),
        ),
      ),
    );

    if (selectedGroup != null && context.mounted) {
      await _moveToGroup(context, ref, selectedGroup);
    }
  }

  Future<void> _moveToGroup(
    BuildContext context,
    WidgetRef ref,
    int groupId,
  ) async {
    final actionsNotifier = ref.read(
      dispatcherPassengerActionsProvider.notifier,
    );
    int successCount = 0;
    int failCount = 0;

    for (final passenger in selectedPassengers) {
      try {
        await actionsNotifier.assignToGroup(
          lineId: passenger.id,
          groupId: groupId,
          fromGroupId: passenger.groupId,
        );
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم نقل $successCount راكب${failCount > 0 ? ' • فشل: $failCount' : ''}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: failCount > 0
              ? AppColors.warning
              : AppColors.success,
        ),
      );
      onClearSelection?.call();
    }
  }

  Future<void> _showUnassignDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إلغاء التعيين',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد إلغاء تعيين ${selectedPassengers.length} راكب من مجموعاتهم؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _unassignFromGroups(context, ref);
    }
  }

  Future<void> _unassignFromGroups(BuildContext context, WidgetRef ref) async {
    final actionsNotifier = ref.read(
      dispatcherPassengerActionsProvider.notifier,
    );
    int successCount = 0;
    int failCount = 0;

    for (final passenger in selectedPassengers) {
      if (passenger.groupId == null) continue;
      try {
        await actionsNotifier.unassignFromGroup(
          lineId: passenger.id,
          groupId: passenger.groupId!,
        );
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إلغاء تعيين $successCount راكب${failCount > 0 ? ' • فشل: $failCount' : ''}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: failCount > 0
              ? AppColors.warning
              : AppColors.success,
        ),
      );
      onClearSelection?.call();
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف الركاب',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${selectedPassengers.length} راكب؟\nهذه العملية لا يمكن التراجع عنها.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deletePassengers(context, ref);
    }
  }

  Future<void> _deletePassengers(BuildContext context, WidgetRef ref) async {
    final actionsNotifier = ref.read(
      dispatcherPassengerActionsProvider.notifier,
    );
    int successCount = 0;
    int failCount = 0;

    for (final passenger in selectedPassengers) {
      try {
        await actionsNotifier.deleteLine(
          lineId: passenger.id,
          groupId: passenger.groupId,
        );
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف $successCount راكب${failCount > 0 ? ' • فشل: $failCount' : ''}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: failCount > 0
              ? AppColors.warning
              : AppColors.success,
        ),
      );
      onClearSelection?.call();
    }
  }
}

class _BulkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
