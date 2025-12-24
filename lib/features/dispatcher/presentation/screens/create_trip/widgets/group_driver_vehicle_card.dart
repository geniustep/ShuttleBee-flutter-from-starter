import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../groups/domain/entities/passenger_group.dart';
import '../../../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../../../vehicles/presentation/providers/fleet_providers.dart';
import '../../../providers/dispatcher_cached_providers.dart';

class GroupDriverVehicleCard extends ConsumerWidget {
  final AsyncValue<List<PassengerGroup>> groupsAsync;
  final AsyncValue<List<ShuttleVehicle>> vehiclesAsync;
  final int? selectedDriverId;
  final int? selectedGroupId;
  final int? selectedVehicleId;
  final int? selectedCompanionId;
  final ValueChanged<int?> onDriverChanged;
  final ValueChanged<int?> onGroupChanged;
  final ValueChanged<int?> onVehicleChanged;
  final ValueChanged<int?> onCompanionChanged;
  final InputDecoration Function({
    required String label,
    required String hint,
    required IconData icon,
  }) buildInputDecoration;

  const GroupDriverVehicleCard({
    super.key,
    required this.groupsAsync,
    required this.vehiclesAsync,
    required this.selectedDriverId,
    required this.selectedGroupId,
    required this.selectedVehicleId,
    required this.selectedCompanionId,
    required this.onDriverChanged,
    required this.onGroupChanged,
    required this.onVehicleChanged,
    required this.onCompanionChanged,
    required this.buildInputDecoration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(availableDriversProvider);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Driver Dropdown (Required)
            driversAsync.when(
              data: (drivers) {
                if (drivers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.noDriversAvailable,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return DropdownButtonFormField<int>(
                  value: selectedDriverId,
                  isExpanded: true,
                  decoration: buildInputDecoration(
                    label: '${l10n.driver} *',
                    hint: l10n.selectDriver,
                    icon: Icons.person_rounded,
                  ),
                  items: drivers.map((driver) {
                    return DropdownMenuItem<int>(
                      value: driver.id,
                      child: Text(
                        driver.name,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: onDriverChanged,
                  validator: (value) {
                    if (value == null) {
                      return l10n.pleaseSelectDriver;
                    }
                    return null;
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Group Dropdown
            groupsAsync.when(
              data: (groups) {
                final activeGroups = groups.where((g) => g.active).toList();
                return DropdownButtonFormField<int>(
                  value: selectedGroupId,
                  isExpanded: true,
                  decoration: buildInputDecoration(
                    label: '${l10n.group} (${l10n.optional})',
                    hint: l10n.selectGroup,
                    icon: Icons.groups_rounded,
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        l10n.noGroup,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...activeGroups.map((group) {
                      return DropdownMenuItem<int>(
                        value: group.id,
                        child: Text(
                          group.name,
                          style: const TextStyle(fontFamily: 'Cairo'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: onGroupChanged,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Vehicle Dropdown
            vehiclesAsync.when(
              data: (vehicles) {
                final activeVehicles = vehicles
                    .where((v) => v.active == true)
                    .toList();
                return DropdownButtonFormField<int>(
                  value: selectedVehicleId,
                  isExpanded: true,
                  decoration: buildInputDecoration(
                    label: '${l10n.vehicle} (${l10n.optional})',
                    hint: l10n.selectVehicle,
                    icon: Icons.directions_bus_rounded,
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        l10n.noVehicle,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...activeVehicles.map((vehicle) {
                      return DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.name} (${vehicle.licensePlate ?? l10n.noLicensePlate})',
                          style: const TextStyle(fontFamily: 'Cairo'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    int? newDriverId;
                    // تحديث السائق تلقائياً عند تغيير السيارة
                    if (value != null) {
                      try {
                        final selectedVehicle = activeVehicles.firstWhere(
                          (v) => v.id == value,
                        );
                        if (selectedVehicle.driverId != null) {
                          // التحقق من أن السائق موجود في قائمة السائقين المتاحين
                          final drivers = driversAsync.value;
                          if (drivers != null) {
                            final driverExists = drivers.any(
                              (driver) => driver.id == selectedVehicle.driverId,
                            );
                            if (driverExists) {
                              newDriverId = selectedVehicle.driverId;
                            }
                          }
                        }
                      } catch (e) {
                        // السيارة غير موجودة، لا شيء
                      }
                    }
                    onVehicleChanged(value);
                    if (newDriverId != null) {
                      onDriverChanged(newDriverId);
                    }
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Companion Dropdown
            ref.watch(companionsProvider).when(
                  data: (companions) {
                    if (companions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'لا يوجد مرافقون متاحون',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      value: selectedCompanionId,
                      isExpanded: true,
                      decoration: buildInputDecoration(
                        label: l10n.companionOptional,
                        hint: l10n.selectCompanion,
                        icon: Icons.person_add_alt_rounded,
                      ),
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text(
                            l10n.noCompanion,
                            style: const TextStyle(fontFamily: 'Cairo'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...companions.map((companion) {
                          return DropdownMenuItem<int>(
                            value: companion.id,
                            child: Text(
                              companion.name,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: onCompanionChanged,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }
}
