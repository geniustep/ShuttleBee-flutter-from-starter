import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/enums/enums.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../groups/domain/entities/passenger_group.dart';
import '../../../../../groups/presentation/providers/group_providers.dart';
import '../../../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../../../vehicles/presentation/providers/vehicle_providers.dart';
import 'date_time_card.dart';
import 'group_driver_vehicle_card.dart';
import 'info_card.dart';
import 'notes_card.dart';
import 'passengers_selection_card.dart';
import 'return_trip_options_card.dart';
import 'section_header.dart';
import 'trip_basic_info_card.dart';
import 'trip_type_card.dart';

class ManualTripTab extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController notesController;
  final TripType tripType;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int? selectedGroupId;
  final int? selectedVehicleId;
  final int? selectedDriverId;
  final int? selectedCompanionId;
  final Set<int> selectedPassengerIds;
  final bool createReturnTrip;
  final DateTime? returnTripStartTime;
  final DateTime? returnTripArrivalTime;
  final bool isLoading;
  final ValueChanged<TripType> onTripTypeChanged;
  final VoidCallback onDateTimeSelect;
  final ValueChanged<TimeOfDay> onQuickTimeSelect;
  final ValueChanged<int?> onGroupChanged;
  final ValueChanged<int?> onVehicleChanged;
  final ValueChanged<int?> onDriverChanged;
  final ValueChanged<int?> onCompanionChanged;
  final VoidCallback onShowPassengerSheet;
  final ValueChanged<int> onRemovePassenger;
  final ValueChanged<bool> onCreateReturnTripChanged;
  final VoidCallback onReturnTripStartTimeSelect;
  final VoidCallback onReturnTripArrivalTimeSelect;
  final VoidCallback onCreateManualTrip;
  final InputDecoration Function({
    required String label,
    required String hint,
    required IconData icon,
  }) buildInputDecoration;

  const ManualTripTab({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.notesController,
    required this.tripType,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedGroupId,
    required this.selectedVehicleId,
    required this.selectedDriverId,
    required this.selectedCompanionId,
    required this.selectedPassengerIds,
    required this.createReturnTrip,
    required this.returnTripStartTime,
    required this.returnTripArrivalTime,
    required this.isLoading,
    required this.onTripTypeChanged,
    required this.onDateTimeSelect,
    required this.onQuickTimeSelect,
    required this.onGroupChanged,
    required this.onVehicleChanged,
    required this.onDriverChanged,
    required this.onCompanionChanged,
    required this.onShowPassengerSheet,
    required this.onRemovePassenger,
    required this.onCreateReturnTripChanged,
    required this.onReturnTripStartTimeSelect,
    required this.onReturnTripArrivalTimeSelect,
    required this.onCreateManualTrip,
    required this.buildInputDecoration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(allVehiclesProvider);
    final groupsAsync = ref.watch(allGroupsProvider);
    final l10n = AppLocalizations.of(context);

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          InfoCard(
            icon: Icons.info_outline_rounded,
            title: l10n.createManualTrip,
            message: l10n.createManualTripDesc,
          ),
          const SizedBox(height: 24),

          // Basic Info
          SectionHeader(title: l10n.basicInfo, icon: Icons.info_outline_rounded),
          const SizedBox(height: 12),
          TripBasicInfoCard(
            nameController: nameController,
            buildInputDecoration: buildInputDecoration,
          ),

          const SizedBox(height: 24),

          // Trip Type
          SectionHeader(title: l10n.tripType, icon: Icons.route_rounded),
          const SizedBox(height: 12),
          TripTypeCard(
            tripType: tripType,
            onTripTypeChanged: onTripTypeChanged,
          ),

          const SizedBox(height: 24),

          // Date & Time
          SectionHeader(
            title: '${l10n.date} ${l10n.time}',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 12),
          DateTimeCard(
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            onDateTimeSelect: onDateTimeSelect,
            onQuickTimeSelect: onQuickTimeSelect,
          ),

          const SizedBox(height: 24),

          // Notes (Optional)
          SectionHeader(
            title: '${l10n.notes} (${l10n.optional})',
            icon: Icons.note_rounded,
          ),
          const SizedBox(height: 12),
          NotesCard(
            notesController: notesController,
            buildInputDecoration: buildInputDecoration,
          ),

          const SizedBox(height: 24),

          // Group, Driver & Vehicle
          SectionHeader(
            title: '${l10n.group}, ${l10n.driver} & ${l10n.vehicle}',
            icon: Icons.directions_bus_rounded,
          ),
          const SizedBox(height: 12),
          GroupDriverVehicleCard(
            groupsAsync: groupsAsync,
            vehiclesAsync: vehiclesAsync,
            selectedDriverId: selectedDriverId,
            selectedGroupId: selectedGroupId,
            selectedVehicleId: selectedVehicleId,
            selectedCompanionId: selectedCompanionId,
            onDriverChanged: onDriverChanged,
            onGroupChanged: onGroupChanged,
            onVehicleChanged: onVehicleChanged,
            onCompanionChanged: onCompanionChanged,
            buildInputDecoration: buildInputDecoration,
          ),

          const SizedBox(height: 24),

          // Passengers Selection
          SectionHeader(title: '${l10n.passengers} *', icon: Icons.people_rounded),
          const SizedBox(height: 12),
          PassengersSelectionCard(
            selectedPassengerIds: selectedPassengerIds,
            selectedVehicleId: selectedVehicleId,
            onShowPassengerSheet: onShowPassengerSheet,
            onRemovePassenger: onRemovePassenger,
          ),

          const SizedBox(height: 24),

          // Return Trip Options (only for pickup trips)
          if (tripType == TripType.pickup) ...[
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
          ],

          const SizedBox(height: 32),

          // Create Button
          _buildCreateManualButton(context, l10n),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCreateManualButton(BuildContext context, AppLocalizations l10n) {
    final isValid =
        nameController.text.trim().isNotEmpty && selectedDriverId != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: (isLoading || !isValid) ? null : onCreateManualTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dispatcherPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isValid ? 4 : 0,
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
            : const Icon(Icons.add_rounded),
        label: Text(
          isLoading ? l10n.creating : l10n.createTrip,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms);
  }
}
