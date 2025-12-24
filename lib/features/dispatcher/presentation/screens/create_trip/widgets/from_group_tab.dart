import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../groups/presentation/providers/group_providers.dart';
import 'generation_options_card.dart';
import 'group_selection_card.dart';
import 'info_card.dart';
import 'return_trip_options_card.dart';
import 'section_header.dart';

class FromGroupTab extends ConsumerWidget {
  final int? selectedGroupId;
  final int weeksAhead;
  final bool createReturnTrip;
  final DateTime? returnTripStartTime;
  final DateTime? returnTripArrivalTime;
  final bool isLoading;
  final Set<int> selectedPassengerIds;
  final ValueChanged<int?> onGroupSelected;
  final ValueChanged<int> onWeeksAheadChanged;
  final ValueChanged<bool> onCreateReturnTripChanged;
  final VoidCallback onReturnTripStartTimeSelect;
  final VoidCallback onReturnTripArrivalTimeSelect;
  final VoidCallback onGenerate;

  const FromGroupTab({
    super.key,
    required this.selectedGroupId,
    required this.weeksAhead,
    required this.createReturnTrip,
    required this.returnTripStartTime,
    required this.returnTripArrivalTime,
    required this.isLoading,
    required this.selectedPassengerIds,
    required this.onGroupSelected,
    required this.onWeeksAheadChanged,
    required this.onCreateReturnTripChanged,
    required this.onReturnTripStartTimeSelect,
    required this.onReturnTripArrivalTimeSelect,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info Card
        InfoCard(
          icon: Icons.lightbulb_outline_rounded,
          title: l10n.generateTripsFromGroup,
          message: l10n.selectGroupToGenerate,
        ),
        const SizedBox(height: 24),

        // Group Selection
        SectionHeader(title: l10n.group, icon: Icons.groups_rounded),
        const SizedBox(height: 12),
        GroupSelectionCard(
          groupsAsync: groupsAsync,
          selectedGroupId: selectedGroupId,
          onGroupSelected: onGroupSelected,
        ),

        const SizedBox(height: 24),

        // Generation Options
        SectionHeader(
          title: l10n.generationOptions,
          icon: Icons.settings_rounded,
        ),
        const SizedBox(height: 12),
        GenerationOptionsCard(
          weeksAhead: weeksAhead,
          onWeeksAheadChanged: onWeeksAheadChanged,
        ),

        const SizedBox(height: 24),

        // Return Trip Options
        SectionHeader(
          title: l10n.returnTripRoundTrip,
          icon: Icons.swap_horiz_rounded,
        ),
        const SizedBox(height: 12),
        ReturnTripOptionsCard(
          createReturnTrip: createReturnTrip,
          returnTripStartTime: returnTripStartTime,
          returnTripArrivalTime: returnTripArrivalTime,
          hasPassengers: selectedPassengerIds.isNotEmpty,
          onCreateReturnTripChanged: onCreateReturnTripChanged,
          onReturnTripStartTimeSelect: onReturnTripStartTimeSelect,
          onReturnTripArrivalTimeSelect: onReturnTripArrivalTimeSelect,
        ),

        const SizedBox(height: 32),

        // Generate Button
        _buildGenerateButton(context, l10n),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGenerateButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: selectedGroupId == null || isLoading ? null : onGenerate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(
          isLoading ? l10n.generating : l10n.generateTrips,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }
}
