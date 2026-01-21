import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../groups/domain/entities/passenger_group.dart';
import '../../../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../../../vehicles/presentation/providers/fleet_providers.dart';
import '../../../providers/dispatcher_cached_providers.dart';
import '../../../providers/dispatcher_passenger_providers.dart';

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
  final ValueChanged<Set<int>>? onPassengersChanged;
  final InputDecoration Function({
    required String label,
    required String hint,
    required IconData icon,
  })
  buildInputDecoration;

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
    this.onPassengersChanged,
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
            // Group Dropdown (First)
            groupsAsync.when(
              data: (groups) {
                final activeGroups = groups.where((g) => g.active).toList();

                // إنشاء قائمة العناصر مع التأكد من عدم وجود تكرارات
                final items = <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text(
                      l10n.noGroup,
                      style: const TextStyle(fontFamily: 'Cairo'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ];
                final seenIds = <int>{};
                for (final group in activeGroups) {
                  if (!seenIds.contains(group.id)) {
                    seenIds.add(group.id);
                    items.add(
                      DropdownMenuItem<int>(
                        value: group.id,
                        child: Text(
                          group.name,
                          style: const TextStyle(fontFamily: 'Cairo'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                }

                // التأكد من أن القيمة المحددة موجودة في القائمة
                final validValue =
                    selectedGroupId != null && seenIds.contains(selectedGroupId)
                    ? selectedGroupId
                    : null;

                return DropdownButtonFormField<int>(
                  key: ValueKey('group_$validValue'),
                  initialValue: validValue,
                  isExpanded: true,
                  decoration: buildInputDecoration(
                    label: '${l10n.group} (${l10n.optional})',
                    hint: l10n.selectGroup,
                    icon: Icons.groups_rounded,
                  ),
                  items: items,
                  onChanged: (value) async {
                    // مسح الركاب أولاً عند تغيير المجموعة
                    if (onPassengersChanged != null) {
                      onPassengersChanged!(<int>{});
                    }

                    onGroupChanged(value);

                    // عند اختيار المجموعة، تعيين السيارة والسائق والمرافق والركاب
                    if (value != null) {
                      try {
                        final selectedGroup = activeGroups.firstWhere(
                          (g) => g.id == value,
                        );

                        // إظهار نافذة التحميل الجميلة
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) => _GroupLoadingDialog(
                              groupName: selectedGroup.name,
                            ),
                          );

                          // انتظار قليل لضمان ظهور النافذة
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );
                        }

                        // تعيين السيارة
                        if (selectedGroup.vehicleId != null) {
                          final vehicles = vehiclesAsync.value;
                          if (vehicles != null) {
                            final vehicleExists = vehicles.any(
                              (v) =>
                                  v.id == selectedGroup.vehicleId &&
                                  v.active == true,
                            );
                            if (vehicleExists) {
                              onVehicleChanged(selectedGroup.vehicleId);
                              // انتظار قليل لضمان تحديث الـ state
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                            }
                          }
                        }

                        // تعيين السائق
                        if (selectedGroup.driverId != null) {
                          final drivers = driversAsync.value;
                          if (drivers != null) {
                            final driverExists = drivers.any(
                              (driver) => driver.id == selectedGroup.driverId,
                            );
                            if (driverExists) {
                              onDriverChanged(selectedGroup.driverId);
                              // انتظار قليل لضمان تحديث الـ state
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                            }
                          }
                        }

                        // تعيين المرافق
                        if (selectedGroup.companionId != null) {
                          final companionsAsync = ref.read(companionsProvider);
                          companionsAsync.whenData((companions) {
                            final companionExists = companions.any(
                              (companion) =>
                                  companion.id == selectedGroup.companionId,
                            );
                            if (companionExists) {
                              debugPrint(
                                'Setting companion: ${selectedGroup.companionId}',
                              );
                              onCompanionChanged(selectedGroup.companionId);
                            } else {
                              debugPrint(
                                'Companion ${selectedGroup.companionId} not found in list',
                              );
                            }
                          });
                          // انتظار قليل لضمان تحديث الـ state
                          await Future.delayed(
                            const Duration(milliseconds: 200),
                          );
                        }

                        // تعيين الركاب
                        int passengersCount = 0;
                        if (onPassengersChanged != null) {
                          try {
                            debugPrint('Loading passengers for group: $value');

                            // استخدام الـ data source مباشرة لتجنب مشكلة الـ autoDispose
                            final ds = ref.read(
                              dispatcherPassengerDataSourceProvider,
                            );
                            if (ds != null) {
                              final passengers = await ds.getGroupPassengers(
                                value,
                              );

                              debugPrint(
                                'Loaded ${passengers.length} passengers from data source',
                              );

                              // إزالة التكرارات بناءً على passengerId باستخدام Set
                              final uniquePassengerIds = <int>{};
                              for (final passenger in passengers) {
                                if (!uniquePassengerIds.contains(
                                  passenger.passengerId,
                                )) {
                                  uniquePassengerIds.add(passenger.passengerId);
                                }
                              }

                              passengersCount = uniquePassengerIds.length;
                              debugPrint(
                                'Setting ${uniquePassengerIds.length} unique passengers: $uniquePassengerIds',
                              );

                              // التحقق من أن الـ widget لا يزال موجوداً قبل استدعاء الـ callback
                              if (context.mounted) {
                                onPassengersChanged!(uniquePassengerIds);
                              }
                            } else {
                              debugPrint(
                                'Data source is null, cannot load passengers',
                              );
                            }
                          } catch (e, stackTrace) {
                            debugPrint('Error loading passengers: $e');
                            debugPrint('Stack trace: $stackTrace');
                          }
                        }

                        // إغلاق نافذة التحميل وإظهار النتيجة
                        if (context.mounted) {
                          Navigator.of(context).pop();

                          // إظهار نافذة النتيجة الجميلة
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (dialogContext) {
                                // إغلاق النافذة تلقائياً بعد 3 ثوان
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                });

                                return _GroupLoadedDialog(
                                  groupName: selectedGroup.name,
                                  vehicleName: selectedGroup.vehicleName,
                                  driverName: selectedGroup.driverName,
                                  companionName: selectedGroup.companionName,
                                  passengersCount: passengersCount,
                                );
                              },
                            );
                          }
                        }
                      } catch (e) {
                        // إغلاق نافذة التحميل في حالة الخطأ
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        debugPrint('Error finding group: $e');
                      }
                    }
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Vehicle Dropdown (Second)
            vehiclesAsync.when(
              data: (vehicles) {
                // إزالة المركبات المكررة بناءً على الـ ID
                // التأكد من عدم وجود قيم مكررة في القائمة
                final uniqueVehicles = <int, ShuttleVehicle>{};
                for (final vehicle in vehicles) {
                  if (vehicle.active == true &&
                      !uniqueVehicles.containsKey(vehicle.id)) {
                    uniqueVehicles[vehicle.id] = vehicle;
                  }
                }
                final vehiclesList = uniqueVehicles.values.toList();

                // إنشاء قائمة العناصر مع التأكد من عدم وجود تكرارات
                final items = <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text(
                      l10n.noVehicle,
                      style: const TextStyle(fontFamily: 'Cairo'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ];
                final seenIds = <int>{};
                for (final vehicle in vehiclesList) {
                  if (!seenIds.contains(vehicle.id)) {
                    seenIds.add(vehicle.id);
                    items.add(
                      DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.name} (${vehicle.licensePlate ?? l10n.noLicensePlate})',
                          style: const TextStyle(fontFamily: 'Cairo'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                }

                // التأكد من أن القيمة المحددة موجودة في القائمة
                final validValue =
                    selectedVehicleId != null &&
                        seenIds.contains(selectedVehicleId)
                    ? selectedVehicleId
                    : null;

                return DropdownButtonFormField<int>(
                  key: ValueKey('vehicle_$validValue'),
                  initialValue: validValue,
                  isExpanded: true,
                  decoration: buildInputDecoration(
                    label: '${l10n.vehicle} (${l10n.optional})',
                    hint: l10n.selectVehicle,
                    icon: Icons.directions_bus_rounded,
                  ),
                  items: items,
                  onChanged: (value) async {
                    onVehicleChanged(value);

                    // تحديث السائق تلقائياً عند تغيير السيارة
                    if (value != null) {
                      try {
                        final selectedVehicle = vehiclesList.firstWhere(
                          (v) => v.id == value && v.active == true,
                        );
                        if (selectedVehicle.driverId != null) {
                          // التحقق من أن السائق موجود في قائمة السائقين المتاحين
                          final drivers = driversAsync.value;
                          if (drivers != null) {
                            final driverExists = drivers.any(
                              (driver) => driver.id == selectedVehicle.driverId,
                            );
                            if (driverExists) {
                              debugPrint(
                                'Setting driver: ${selectedVehicle.driverId}',
                              );
                              onDriverChanged(selectedVehicle.driverId);
                              // انتظار قليل لضمان تحديث الـ state
                              await Future.delayed(
                                const Duration(milliseconds: 200),
                              );
                            } else {
                              debugPrint(
                                'Driver ${selectedVehicle.driverId} not found in list',
                              );
                              // إذا لم يكن السائق موجوداً، إعادة تعيين السائق
                              onDriverChanged(null);
                            }
                          }
                        } else {
                          debugPrint('Vehicle $value has no driver');
                          // إذا لم يكن للسيارة سائق، إعادة تعيين السائق
                          onDriverChanged(null);
                        }
                      } catch (e) {
                        debugPrint('Error finding vehicle: $e');
                        // السيارة غير موجودة، إعادة تعيين السائق
                        onDriverChanged(null);
                      }
                    } else {
                      // إذا تم إلغاء اختيار السيارة، إعادة تعيين السائق
                      onDriverChanged(null);
                    }
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Driver Dropdown (Third - Required)
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
                // إزالة السائقين المكررين بناءً على الـ ID
                final uniqueDrivers = <int, DriverOption>{};
                for (final driver in drivers) {
                  if (!uniqueDrivers.containsKey(driver.id)) {
                    uniqueDrivers[driver.id] = driver;
                  }
                }
                final driversList = uniqueDrivers.values.toList();

                // إنشاء قائمة العناصر مع التأكد من عدم وجود تكرارات
                final items = <DropdownMenuItem<int>>[];
                final seenIds = <int>{};
                for (final driver in driversList) {
                  if (!seenIds.contains(driver.id)) {
                    seenIds.add(driver.id);
                    items.add(
                      DropdownMenuItem<int>(
                        value: driver.id,
                        child: Text(
                          driver.name,
                          style: const TextStyle(fontFamily: 'Cairo'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                }

                // التأكد من أن القيمة المحددة موجودة في القائمة
                final validValue =
                    selectedDriverId != null &&
                        seenIds.contains(selectedDriverId)
                    ? selectedDriverId
                    : null;

                return DropdownButtonFormField<int>(
                  key: ValueKey('driver_$validValue'),
                  initialValue: validValue,
                  isExpanded: true,
                  decoration: buildInputDecoration(
                    label: '${l10n.driver} *',
                    hint: l10n.selectDriver,
                    icon: Icons.person_rounded,
                  ),
                  items: items,
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

            // Companion Dropdown
            ref
                .watch(companionsProvider)
                .when(
                  data: (companions) {
                    if (companions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'لا يوجد مرافقون متاحون',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // إنشاء قائمة العناصر مع التأكد من عدم وجود تكرارات
                    final items = <DropdownMenuItem<int>>[
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(
                          l10n.noCompanion,
                          style: const TextStyle(fontFamily: 'Cairo'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ];
                    final seenIds = <int>{};
                    for (final companion in companions) {
                      if (!seenIds.contains(companion.id)) {
                        seenIds.add(companion.id);
                        items.add(
                          DropdownMenuItem<int>(
                            value: companion.id,
                            child: Text(
                              companion.name,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }
                    }

                    // التأكد من أن القيمة المحددة موجودة في القائمة
                    final validValue =
                        selectedCompanionId != null &&
                            seenIds.contains(selectedCompanionId)
                        ? selectedCompanionId
                        : null;

                    return DropdownButtonFormField<int>(
                      key: ValueKey('companion_$validValue'),
                      initialValue: validValue,
                      isExpanded: true,
                      decoration: buildInputDecoration(
                        label: l10n.companionOptional,
                        hint: l10n.selectCompanion,
                        icon: Icons.person_add_alt_rounded,
                      ),
                      items: items,
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

/// نافذة التحميل الجميلة عند اختيار المجموعة
class _GroupLoadingDialog extends StatelessWidget {
  final String groupName;

  const _GroupLoadingDialog({required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 20),
            const Text(
              'جاري تحميل بيانات المجموعة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              groupName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة النتيجة الجميلة بعد تحميل بيانات المجموعة
class _GroupLoadedDialog extends StatelessWidget {
  final String groupName;
  final String? vehicleName;
  final String? driverName;
  final String? companionName;
  final int passengersCount;

  const _GroupLoadedDialog({
    required this.groupName,
    this.vehicleName,
    this.driverName,
    this.companionName,
    required this.passengersCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة النجاح
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تم تحميل بيانات المجموعة بنجاح',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              groupName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            // تفاصيل المجموعة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (vehicleName != null)
                    _InfoRow(
                      icon: Icons.directions_bus_rounded,
                      label: 'المركبة',
                      value: vehicleName!,
                    ),
                  if (driverName != null) ...[
                    if (vehicleName != null) const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'السائق',
                      value: driverName!,
                    ),
                  ],
                  if (companionName != null) ...[
                    if (driverName != null || vehicleName != null)
                      const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.person_add_alt_rounded,
                      label: 'المرافق',
                      value: companionName!,
                    ),
                  ],
                  if (passengersCount > 0) ...[
                    if (companionName != null ||
                        driverName != null ||
                        vehicleName != null)
                      const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.people_rounded,
                      label: 'الركاب',
                      value: '$passengersCount ${l10n.passenger}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صف معلومات في نافذة النتيجة
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
