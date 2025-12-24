import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../groups/domain/entities/passenger_group.dart';

class GroupSelectionCard extends StatelessWidget {
  final AsyncValue<List<PassengerGroup>> groupsAsync;
  final int? selectedGroupId;
  final ValueChanged<int?> onGroupSelected;

  const GroupSelectionCard({
    super.key,
    required this.groupsAsync,
    required this.selectedGroupId,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: groupsAsync.when(
          data: (groups) {
            final activeGroups = groups.where((g) => g.active).toList();
            if (activeGroups.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.noActiveGroups,
                    style: const TextStyle(fontFamily: 'Cairo'),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: activeGroups.map((group) {
                final isSelected = selectedGroupId == group.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onGroupSelected(group.id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.dispatcherPrimary.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.dispatcherPrimary
                              : Colors.grey.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.dispatcherPrimary.withValues(
                                      alpha: 0.2,
                                    )
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.groups_rounded,
                              color: isSelected
                                  ? AppColors.dispatcherPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                    color: isSelected
                                        ? AppColors.dispatcherPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      '${group.memberCount} ${l10n.passenger}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Cairo',
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '• ${group.tripType.name}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Cairo',
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.dispatcherPrimary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Center(
            child: Text(
              l10n.failedToLoadGroups,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }
}
