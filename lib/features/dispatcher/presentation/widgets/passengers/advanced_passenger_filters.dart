import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/passenger_group_line.dart';
import '../../../../groups/presentation/providers/group_providers.dart';
import '../../providers/dispatcher_cached_providers.dart';

/// Advanced filters state
class PassengerFilters {
  final List<int>? groupIds;
  final bool? hasGroup;
  final String? searchQuery;
  final bool? hasPhone;
  final bool? hasGuardianPhone;

  const PassengerFilters({
    this.groupIds,
    this.hasGroup,
    this.searchQuery,
    this.hasPhone,
    this.hasGuardianPhone,
  });

  PassengerFilters copyWith({
    List<int>? groupIds,
    bool? hasGroup,
    String? searchQuery,
    bool? hasPhone,
    bool? hasGuardianPhone,
  }) {
    return PassengerFilters(
      groupIds: groupIds ?? this.groupIds,
      hasGroup: hasGroup ?? this.hasGroup,
      searchQuery: searchQuery ?? this.searchQuery,
      hasPhone: hasPhone ?? this.hasPhone,
      hasGuardianPhone: hasGuardianPhone ?? this.hasGuardianPhone,
    );
  }

  bool get hasActiveFilters {
    return groupIds != null ||
        hasGroup != null ||
        (searchQuery != null && searchQuery!.isNotEmpty) ||
        hasPhone != null ||
        hasGuardianPhone != null;
  }

  List<PassengerGroupLine> applyFilters(List<PassengerGroupLine> passengers) {
    var filtered = passengers;

    // Filter by groups
    if (groupIds != null && groupIds!.isNotEmpty) {
      filtered = filtered.where((p) {
        if (groupIds!.contains(0)) {
          // 0 means unassigned
          return p.groupId == null;
        }
        return p.groupId != null && groupIds!.contains(p.groupId);
      }).toList();
    }

    // Filter by has group
    if (hasGroup != null) {
      filtered = filtered.where((p) {
        if (hasGroup == true) {
          return p.groupId != null;
        } else {
          return p.groupId == null;
        }
      }).toList();
    }

    // Filter by search query
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      final q = searchQuery!.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.passengerName.toLowerCase().contains(q) ||
            (p.passengerPhone ?? '').toLowerCase().contains(q) ||
            (p.passengerMobile ?? '').toLowerCase().contains(q) ||
            (p.fatherPhone ?? '').toLowerCase().contains(q) ||
            (p.motherPhone ?? '').toLowerCase().contains(q) ||
            (p.guardianPhone ?? '').toLowerCase().contains(q) ||
            (p.groupName ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // Filter by has phone
    if (hasPhone != null) {
      filtered = filtered.where((p) {
        final has =
            (p.passengerPhone ?? '').isNotEmpty ||
            (p.passengerMobile ?? '').isNotEmpty;
        return hasPhone == true ? has : !has;
      }).toList();
    }

    // Filter by has guardian phone
    if (hasGuardianPhone != null) {
      filtered = filtered.where((p) {
        final has =
            (p.fatherPhone ?? '').isNotEmpty ||
            (p.motherPhone ?? '').isNotEmpty ||
            (p.guardianPhone ?? '').isNotEmpty;
        return hasGuardianPhone == true ? has : !has;
      }).toList();
    }

    return filtered;
  }
}

/// Provider for advanced filters
final passengerFiltersProvider =
    NotifierProvider<PassengerFiltersNotifier, PassengerFilters>(
      PassengerFiltersNotifier.new,
    );

class PassengerFiltersNotifier extends Notifier<PassengerFilters> {
  @override
  PassengerFilters build() {
    return const PassengerFilters();
  }

  void setGroupIds(List<int>? groupIds) {
    state = state.copyWith(groupIds: groupIds);
  }

  void setHasGroup(bool? hasGroup) {
    state = state.copyWith(hasGroup: hasGroup);
  }

  void setSearchQuery(String? searchQuery) {
    state = state.copyWith(searchQuery: searchQuery);
  }

  void setHasPhone(bool? hasPhone) {
    state = state.copyWith(hasPhone: hasPhone);
  }

  void setHasGuardianPhone(bool? hasGuardianPhone) {
    state = state.copyWith(hasGuardianPhone: hasGuardianPhone);
  }

  void clearAllFilters() {
    state = const PassengerFilters();
  }
}

/// Advanced filters bottom sheet
class AdvancedPassengerFiltersSheet extends ConsumerWidget {
  final PassengerFilters currentFilters;

  const AdvancedPassengerFiltersSheet({
    super.key,
    required this.currentFilters,
  });

  static Future<void> show(
    BuildContext context, {
    required PassengerFilters currentFilters,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AdvancedPassengerFiltersSheet(currentFilters: currentFilters),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(dispatcherGroupsProvider);
    final filtersNotifier = ref.read(passengerFiltersProvider.notifier);
    final currentState = ref.watch(passengerFiltersProvider);

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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
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
                      Icons.filter_list_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'فلاتر متقدمة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
            ),
            const Divider(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group filter
                    groupsAsync.when(
                      data: (groups) {
                        if (groups.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المجموعات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChip(
                                  label: 'غير معين',
                                  selected:
                                      currentState.groupIds?.contains(0) ??
                                      false,
                                  onTap: () {
                                    final current = currentState.groupIds ?? [];
                                    if (current.contains(0)) {
                                      filtersNotifier.setGroupIds(
                                        current.where((id) => id != 0).toList(),
                                      );
                                    } else {
                                      filtersNotifier.setGroupIds([
                                        ...current,
                                        0,
                                      ]);
                                    }
                                  },
                                ),
                                ...groups.map(
                                  (group) => _FilterChip(
                                    label: group.name,
                                    selected:
                                        currentState.groupIds?.contains(
                                          group.id,
                                        ) ??
                                        false,
                                    onTap: () {
                                      final current =
                                          currentState.groupIds ?? [];
                                      if (current.contains(group.id)) {
                                        filtersNotifier.setGroupIds(
                                          current
                                              .where((id) => id != group.id)
                                              .toList(),
                                        );
                                      } else {
                                        filtersNotifier.setGroupIds([
                                          ...current,
                                          group.id,
                                        ]);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Has group filter
                    const Text(
                      'حالة التعيين',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _FilterChip(
                            label: 'معين لمجموعة',
                            selected: currentState.hasGroup == true,
                            onTap: () {
                              filtersNotifier.setHasGroup(
                                currentState.hasGroup == true ? null : true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'غير معين',
                            selected: currentState.hasGroup == false,
                            onTap: () {
                              filtersNotifier.setHasGroup(
                                currentState.hasGroup == false ? null : false,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Has phone filter
                    const Text(
                      'معلومات الاتصال',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _FilterChip(
                            label: 'لديه هاتف',
                            selected: currentState.hasPhone == true,
                            onTap: () {
                              filtersNotifier.setHasPhone(
                                currentState.hasPhone == true ? null : true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'لديه ولي أمر',
                            selected: currentState.hasGuardianPhone == true,
                            onTap: () {
                              filtersNotifier.setHasGuardianPhone(
                                currentState.hasGuardianPhone == true
                                    ? null
                                    : true,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              filtersNotifier.clearAllFilters();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'مسح الكل',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.dispatcherPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'تطبيق',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.dispatcherPrimary.withValues(alpha: 0.15)
                : AppColors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.dispatcherPrimary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.dispatcherPrimary,
                )
              else
                const Icon(
                  Icons.circle_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.dispatcherPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
