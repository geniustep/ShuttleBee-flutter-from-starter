import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../providers/dispatcher_passenger_providers.dart';

class PassengersSelectionCard extends ConsumerWidget {
  final Set<int> selectedPassengerIds;
  final int? selectedVehicleId;
  final VoidCallback onShowPassengerSheet;
  final ValueChanged<int> onRemovePassenger;

  const PassengersSelectionCard({
    super.key,
    required this.selectedPassengerIds,
    required this.selectedVehicleId,
    required this.onShowPassengerSheet,
    required this.onRemovePassenger,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPassengersAsync = ref.watch(dispatcherAllPassengersProvider);
    final vehiclesAsync = ref.watch(allVehiclesProvider);
    final l10n = AppLocalizations.of(context);
    final hasPassengers = selectedPassengerIds.isNotEmpty;

    // Get selected vehicle and its seat capacity
    ShuttleVehicle? selectedVehicle;
    int? seatCapacity;

    vehiclesAsync.whenData((vehicles) {
      if (selectedVehicleId != null) {
        try {
          selectedVehicle = vehicles.firstWhere(
            (v) => v.id == selectedVehicleId,
          );
          seatCapacity = selectedVehicle?.seatCapacity;
        } catch (e) {
          // Vehicle not found
        }
      }
    });

    final hasVehicle = selectedVehicleId != null && seatCapacity != null;
    final availableSeats = seatCapacity ?? 0;
    final usedSeats = selectedPassengerIds.length;
    final remainingSeats = availableSeats - usedSeats;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count and seat info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: hasPassengers
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              hasPassengers
                                  ? '${selectedPassengerIds.length} ${l10n.passenger}'
                                  : l10n.noPassengersSelected,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: hasPassengers
                                    ? AppColors.success
                                    : Colors.orange,
                              ),
                            ),
                          ),
                          if (hasVehicle) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: remainingSeats >= 0
                                    ? AppColors.dispatcherPrimary.withValues(
                                        alpha: 0.1,
                                      )
                                    : AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$usedSeats / $availableSeats ${l10n.seats}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: remainingSeats >= 0
                                      ? AppColors.dispatcherPrimary
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (hasVehicle && remainingSeats < 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.exceededSeatCapacity,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: hasVehicle ? onShowPassengerSheet : null,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    hasPassengers ? l10n.edit : l10n.select,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: hasVehicle
                        ? AppColors.dispatcherPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Message if no vehicle selected
            if (!hasVehicle)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.selectVehicleFirstToAddPassengers,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Selected passengers list
            if (hasVehicle)
              allPassengersAsync.when(
                data: (allPassengers) {
                  final selectedPassengers = allPassengers
                      .where(
                        (p) => selectedPassengerIds.contains(p.passengerId),
                      )
                      .toList();

                  if (selectedPassengers.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.pleaseSelectAtLeastOnePassenger,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: Colors.orange,
                                  ),
                                ),
                                if (availableSeats > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${l10n.availableSeats}: $availableSeats',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: selectedPassengers.map((passenger) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.dispatcherPrimary,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      passenger.passengerName,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (passenger.groupName != null)
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
                              ),
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  onRemovePassenger(passenger.passengerId);
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                tooltip: l10n.removePassenger,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.failedToLoadPassengers,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }
}
