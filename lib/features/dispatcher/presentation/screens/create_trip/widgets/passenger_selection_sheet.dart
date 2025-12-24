import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../providers/dispatcher_passenger_providers.dart';
import '../../../widgets/common/dispatcher_search_field.dart';

class PassengerSelectionSheet extends ConsumerStatefulWidget {
  final Set<int> selectedPassengerIds;
  final int? maxSeats;
  final ValueChanged<Set<int>> onSelectionChanged;

  const PassengerSelectionSheet({
    super.key,
    required this.selectedPassengerIds,
    this.maxSeats,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<PassengerSelectionSheet> createState() =>
      _PassengerSelectionSheetState();
}

class _PassengerSelectionSheetState
    extends ConsumerState<PassengerSelectionSheet> {
  String _searchQuery = '';
  String? _selectedGroupFilter;
  final Set<int> _tempSelectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    _tempSelectedIds.addAll(widget.selectedPassengerIds);
  }

  @override
  Widget build(BuildContext context) {
    final allPassengersAsync = ref.watch(dispatcherAllPassengersProvider);
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 90),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.selectPassengers,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Selected count badge with seat info
                      if (_tempSelectedIds.isNotEmpty)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.maxSeats != null &&
                                        _tempSelectedIds.length >
                                            widget.maxSeats!
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.maxSeats != null
                                    ? '${_tempSelectedIds.length} / ${widget.maxSeats} ${l10n.seats}'
                                    : '${_tempSelectedIds.length} ${l10n.selected}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.maxSeats != null &&
                                          _tempSelectedIds.length >
                                              widget.maxSeats!
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          widget.onSelectionChanged(_tempSelectedIds);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          l10n.done,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  DispatcherSearchField(
                    hintText: l10n.searchPassengers,
                    value: _searchQuery,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _tempSelectedIds.isEmpty
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _tempSelectedIds.clear());
                                },
                          icon: const Icon(Icons.clear_all_rounded, size: 18),
                          label: Text(
                            l10n.clearAll,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            allPassengersAsync.whenData((passengers) {
                              setState(() {
                                _tempSelectedIds.clear();
                                _tempSelectedIds.addAll(
                                  passengers.map((p) => p.passengerId),
                                );
                              });
                            });
                          },
                          icon: const Icon(Icons.select_all_rounded, size: 18),
                          label: Text(
                            l10n.selectAll,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dispatcherPrimary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Group filter chips (if group filter selected)
            if (_selectedGroupFilter != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        '${l10n.filterByGroup}: $_selectedGroupFilter',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                        ),
                      ),
                      avatar: const Icon(Icons.filter_list_rounded, size: 16),
                      onDeleted: () {
                        setState(() => _selectedGroupFilter = null);
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Passengers list
            Flexible(
              child: allPassengersAsync.when(
                data: (allPassengers) {
                  // Filter passengers
                  var filteredPassengers = allPassengers;

                  // Filter by search query
                  if (_searchQuery.isNotEmpty) {
                    filteredPassengers = filteredPassengers.where((p) {
                      final query = _searchQuery.toLowerCase();
                      return p.passengerName.toLowerCase().contains(query) ||
                          (p.groupName?.toLowerCase().contains(query) ??
                              false) ||
                          (p.passengerPhone?.contains(query) ?? false);
                    }).toList();
                  }

                  // Filter by group if selected
                  if (_selectedGroupFilter != null) {
                    filteredPassengers = filteredPassengers.where((p) {
                      return p.groupName == _selectedGroupFilter;
                    }).toList();
                  }

                  if (filteredPassengers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? l10n.noResultsFound
                                  : l10n.noPassengersAvailable,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredPassengers.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final passenger = filteredPassengers[index];
                      final isSelected = _tempSelectedIds.contains(
                        passenger.passengerId,
                      );

                      // Check if can select more (respecting seat capacity)
                      final canSelectMore = widget.maxSeats == null ||
                          _tempSelectedIds.length < widget.maxSeats! ||
                          isSelected;
                      final isOverCapacity = widget.maxSeats != null &&
                          !isSelected &&
                          _tempSelectedIds.length >= widget.maxSeats!;

                      return InkWell(
                        onTap: canSelectMore
                            ? () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (isSelected) {
                                    _tempSelectedIds.remove(
                                      passenger.passengerId,
                                    );
                                  } else {
                                    _tempSelectedIds.add(passenger.passengerId);
                                  }
                                });
                              }
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.dispatcherPrimary.withValues(
                                    alpha: 0.1,
                                  )
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
                              Checkbox(
                                value: isSelected,
                                onChanged: canSelectMore
                                    ? (value) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          if (value == true) {
                                            _tempSelectedIds.add(
                                              passenger.passengerId,
                                            );
                                          } else {
                                            _tempSelectedIds.remove(
                                              passenger.passengerId,
                                            );
                                          }
                                        });
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isSelected
                                    ? AppColors.dispatcherPrimary
                                    : Colors.grey.withValues(alpha: 0.2),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      passenger.passengerName,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isSelected
                                            ? AppColors.dispatcherPrimary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (passenger.groupName != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.groups_rounded,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            passenger.groupName!,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (passenger.passengerPhone != null) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.phone_rounded,
                                            size: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            passenger.passengerPhone!,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 24,
                                ),
                              if (isOverCapacity)
                                Tooltip(
                                  message: l10n.seatCapacityExceeded,
                                  child: const Icon(
                                    Icons.block_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.failedToLoadPassengers,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
