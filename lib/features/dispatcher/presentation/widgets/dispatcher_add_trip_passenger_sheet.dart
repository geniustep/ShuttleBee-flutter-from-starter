import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../domain/entities/passenger_group_line.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/dispatcher_passenger_providers.dart';
import 'dispatcher_search_field.dart';

enum _TripPassengerPickerFilter {
  all,
  unassigned,
  otherGroups,
}

/// Sheet for adding passengers to a trip - shows ALL passengers like group management
class DispatcherAddTripPassengerSheet extends ConsumerStatefulWidget {
  final int tripId;
  final String tripName;
  final List<TripLine> currentPassengers;

  const DispatcherAddTripPassengerSheet({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.currentPassengers,
  });

  @override
  ConsumerState<DispatcherAddTripPassengerSheet> createState() =>
      _DispatcherAddTripPassengerSheetState();
}

class _DispatcherAddTripPassengerSheetState
    extends ConsumerState<DispatcherAddTripPassengerSheet> {
  String _searchQuery = '';
  _TripPassengerPickerFilter _filter = _TripPassengerPickerFilter.all;

  @override
  Widget build(BuildContext context) {
    // Get all passengers from different sources
    final unassignedAsync = ref.watch(dispatcherUnassignedPassengersProvider);
    final otherGroupsAsync = ref
        .watch(dispatcherPassengersInOtherGroupsProvider(0)); // 0 = all groups
    final actionsState = ref.watch(activeTripProvider);

    final unassigned = unassignedAsync.asData?.value ?? const [];
    final otherGroups = otherGroupsAsync.asData?.value ?? const [];

    // Passenger IDs already in this trip
    final passengerIdsInTrip = {
      for (final line in widget.currentPassengers) line.passengerId,
    };

    final filteredUnassigned = _filterItems(unassigned);
    final filteredOtherGroups = _filterItems(otherGroups);

    final showUnassigned = _filter != _TripPassengerPickerFilter.otherGroups;
    final showOtherGroups = _filter != _TripPassengerPickerFilter.unassigned;

    return Container(
      margin: const EdgeInsets.only(top: 90),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'إضافة ركاب إلى "${widget.tripName}"',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ابحث عن راكب ثم أضِفه للرحلة.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              DispatcherSearchField(
                hintText: 'ابحث بالاسم أو الهاتف أو اسم المجموعة...',
                value: _searchQuery,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() => _searchQuery = ''),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text(
                      'الكل',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    selected: _filter == _TripPassengerPickerFilter.all,
                    onSelected: (_) => setState(
                        () => _filter = _TripPassengerPickerFilter.all),
                  ),
                  ChoiceChip(
                    label: const Text(
                      'غير مدرجين',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    selected: _filter == _TripPassengerPickerFilter.unassigned,
                    onSelected: (_) => setState(
                      () => _filter = _TripPassengerPickerFilter.unassigned,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text(
                      'في مجموعات',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    selected: _filter == _TripPassengerPickerFilter.otherGroups,
                    onSelected: (_) => setState(
                      () => _filter = _TripPassengerPickerFilter.otherGroups,
                    ),
                  ),
                ],
              ),
              if (actionsState.isLoading) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (showUnassigned)
                      _buildSection(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'الركاب غير المدرجين في مجموعات',
                        async: unassignedAsync,
                        baseItems: unassigned,
                        items: filteredUnassigned,
                        emptyTitle: 'لا يوجد ركاب غير مدرجين',
                        emptyMessage:
                            'كل الركاب الحاليين مرتبطين بمجموعات، أو لم يتم تفعيل ركاب في النظام.',
                        noResultsTitle: 'لا نتائج',
                        noResultsMessage:
                            'لا يوجد ركاب غير مدرجين مطابقون لبحثك.',
                        itemBuilder: (p) {
                          final alreadyInTrip =
                              passengerIdsInTrip.contains(p.passengerId);
                          final baseSubtitle = _contactSubtitle(p);
                          final subtitle = alreadyInTrip
                              ? _alreadyInTripSubtitle(baseSubtitle)
                              : baseSubtitle;

                          return _TripPassengerPickerTile(
                            line: p,
                            subtitle: subtitle,
                            actionLabel: alreadyInTrip ? 'موجود' : 'إضافة',
                            actionIcon: alreadyInTrip
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            enabled: !actionsState.isLoading && !alreadyInTrip,
                            onPressed: () => _addPassenger(p),
                          );
                        },
                      ),
                    if (showUnassigned && showOtherGroups)
                      const SizedBox(height: 18),
                    if (showOtherGroups)
                      _buildSection(
                        icon: Icons.groups_rounded,
                        title: 'ركاب في مجموعات',
                        async: otherGroupsAsync,
                        baseItems: otherGroups,
                        items: filteredOtherGroups,
                        emptyTitle: 'لا يوجد ركاب في مجموعات',
                        emptyMessage: 'لا يوجد حالياً ركاب مسجلين في مجموعات.',
                        noResultsTitle: 'لا نتائج',
                        noResultsMessage: 'لا يوجد ركاب مطابقون لبحثك.',
                        itemBuilder: (p) {
                          final alreadyInTrip =
                              passengerIdsInTrip.contains(p.passengerId);
                          final baseSubtitle = _groupAndContactSubtitle(p);
                          final subtitle = alreadyInTrip
                              ? _alreadyInTripSubtitle(baseSubtitle)
                              : baseSubtitle;

                          return _TripPassengerPickerTile(
                            line: p,
                            subtitle: subtitle,
                            actionLabel: alreadyInTrip ? 'موجود' : 'إضافة',
                            actionIcon: alreadyInTrip
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            enabled: !actionsState.isLoading && !alreadyInTrip,
                            onPressed: () => _addPassenger(p),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PassengerGroupLine> _filterItems(List<PassengerGroupLine> items) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((p) {
      final name = p.passengerName.toLowerCase();
      final passengerPhone = (p.passengerPhone ?? '').toLowerCase();
      final passengerMobile = (p.passengerMobile ?? '').toLowerCase();
      final guardianPhone = (p.guardianPhone ?? '').toLowerCase();
      final groupName = (p.groupName ?? '').toLowerCase();

      return name.contains(q) ||
          passengerPhone.contains(q) ||
          passengerMobile.contains(q) ||
          guardianPhone.contains(q) ||
          groupName.contains(q);
    }).toList();
  }

  String _contactSubtitle(PassengerGroupLine p) {
    if (p.guardianPhone?.isNotEmpty ?? false) return 'ولي: ${p.guardianPhone}';
    return p.passengerPhone ?? p.passengerMobile ?? '';
  }

  String _groupAndContactSubtitle(PassengerGroupLine p) {
    final groupLabel =
        p.groupName ?? (p.groupId == null ? '' : 'مجموعة #${p.groupId}');
    final contact = _contactSubtitle(p);

    if (groupLabel.isEmpty) return contact;
    if (contact.isEmpty) return 'المجموعة: $groupLabel';
    return 'المجموعة: $groupLabel • $contact';
  }

  String _alreadyInTripSubtitle(String baseSubtitle) {
    final contact = baseSubtitle.trim();
    if (contact.isEmpty) return 'موجود في هذه الرحلة';
    return 'موجود في هذه الرحلة · $contact';
  }

  Future<void> _addPassenger(PassengerGroupLine line) async {
    HapticFeedback.lightImpact();

    final success =
        await ref.read(activeTripProvider.notifier).addPassengerToTrip(
              tripId: widget.tripId,
              passengerId: line.passengerId,
              seatCount: line.seatCount,
            );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إضافة "${line.passengerName}" بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فشل إضافة الراكب',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required AsyncValue<List<PassengerGroupLine>> async,
    required List<PassengerGroupLine> baseItems,
    required List<PassengerGroupLine> items,
    required String emptyTitle,
    required String emptyMessage,
    required String noResultsTitle,
    required String noResultsMessage,
    required Widget Function(PassengerGroupLine line) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.dispatcherPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (async.isLoading && async.asData == null)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (_, __) => const ShimmerCard(height: 70),
          )
        else if (async.hasError && baseItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              async.error.toString(),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: _searchQuery.trim().isEmpty ? emptyTitle : noResultsTitle,
              message:
                  _searchQuery.trim().isEmpty ? emptyMessage : noResultsMessage,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => itemBuilder(items[index]),
          ),
      ],
    );
  }
}

class _TripPassengerPickerTile extends StatelessWidget {
  final PassengerGroupLine line;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final bool enabled;
  final VoidCallback onPressed;

  const _TripPassengerPickerTile({
    required this.line,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFEFF6FF),
        foregroundColor: AppColors.dispatcherPrimary,
        child: Icon(Icons.person_rounded),
      ),
      title: Text(
        line.passengerName,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle.trim().isEmpty
          ? null
          : Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
              ),
            ),
      trailing: SizedBox(
        width: 96,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: AppColors.dispatcherPrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: enabled ? onPressed : null,
          icon: Icon(actionIcon, size: 18),
          label: Text(
            actionLabel,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      ),
    );
  }
}
