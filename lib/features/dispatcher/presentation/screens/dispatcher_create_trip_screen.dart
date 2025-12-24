import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common/desktop_sidebar_wrapper.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../widgets/common/dispatcher_app_bar.dart';

// Import extracted widgets
import 'create_trip/widgets/from_group_tab.dart';
import 'create_trip/widgets/manual_trip_tab.dart';
import 'create_trip/widgets/passenger_selection_sheet.dart';

/// Dispatcher Create Trip Screen - شاشة إنشاء/توليد رحلة - ShuttleBee
class DispatcherCreateTripScreen extends ConsumerStatefulWidget {
  final int? initialGroupId;

  const DispatcherCreateTripScreen({super.key, this.initialGroupId});

  @override
  ConsumerState<DispatcherCreateTripScreen> createState() =>
      _DispatcherCreateTripScreenState();
}

class _DispatcherCreateTripScreenState
    extends ConsumerState<DispatcherCreateTripScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  TripType _tripType = TripType.pickup;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedGroupId;
  int? _selectedVehicleId;
  int? _selectedDriverId;
  int? _selectedCompanionId;
  int _weeksAhead = 1;
  bool _isLoading = false;

  // Selected passengers
  final Set<int> _selectedPassengerIds = <int>{};

  // Return trip options
  bool _createReturnTrip = false;
  DateTime? _returnTripStartTime;
  DateTime? _returnTripArrivalTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Set initial group if provided
    if (widget.initialGroupId != null) {
      _selectedGroupId = widget.initialGroupId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffoldWithSidebar(
      backgroundColor: AppColors.dispatcherBackground,
      appBar: DispatcherAppBar(
        title: AppLocalizations.of(context).createTrip,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.add_circle_outline_rounded),
              text: AppLocalizations.of(context).manualTrip,
            ),
            Tab(
              icon: const Icon(Icons.groups_rounded),
              text: AppLocalizations.of(context).generateFromGroup,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ManualTripTab(
            formKey: _formKey,
            nameController: _nameController,
            notesController: _notesController,
            tripType: _tripType,
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            selectedGroupId: _selectedGroupId,
            selectedVehicleId: _selectedVehicleId,
            selectedDriverId: _selectedDriverId,
            selectedCompanionId: _selectedCompanionId,
            selectedPassengerIds: _selectedPassengerIds,
            createReturnTrip: _createReturnTrip,
            returnTripStartTime: _returnTripStartTime,
            returnTripArrivalTime: _returnTripArrivalTime,
            isLoading: _isLoading,
            onTripTypeChanged: (type) {
              setState(() => _tripType = type);
            },
            onDateTimeSelect: () => _selectDateTime(context),
            onQuickTimeSelect: (time) {
              setState(() => _selectedTime = time);
              HapticFeedback.selectionClick();
            },
            onGroupChanged: (groupId) {
              setState(() => _selectedGroupId = groupId);
            },
            onDriverChanged: (driverId) {
              setState(() => _selectedDriverId = driverId);
            },
            onVehicleChanged: (vehicleId) {
              setState(() {
                _selectedVehicleId = vehicleId;
                // Auto-assign driver when vehicle is selected
                if (vehicleId != null) {
                  final vehiclesAsync = ref.read(allVehiclesProvider);
                  vehiclesAsync.whenData((vehicles) {
                    final vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
                    if (vehicle.driverId != null) {
                      _selectedDriverId = vehicle.driverId;
                    }
                  });
                }
              });
            },
            onCompanionChanged: (companionId) {
              setState(() => _selectedCompanionId = companionId);
            },
            onRemovePassenger: (passengerId) {
              setState(() => _selectedPassengerIds.remove(passengerId));
            },
            onShowPassengerSheet: () => _showPassengerSelectionSheet(context),
            onCreateReturnTripChanged: (value) {
              setState(() => _createReturnTrip = value);
            },
            onReturnTripStartTimeSelect: () =>
                _selectReturnTripStartTime(context),
            onReturnTripArrivalTimeSelect: () =>
                _selectReturnTripArrivalTime(context),
            onCreateManualTrip: _createManualTrip,
            buildInputDecoration: ({
              required String label,
              required String hint,
              required IconData icon,
            }) {
              return InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Icon(icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              );
            },
          ),
          FromGroupTab(
            selectedGroupId: _selectedGroupId,
            weeksAhead: _weeksAhead,
            createReturnTrip: _createReturnTrip,
            returnTripStartTime: _returnTripStartTime,
            returnTripArrivalTime: _returnTripArrivalTime,
            isLoading: _isLoading,
            selectedPassengerIds: _selectedPassengerIds,
            onGroupSelected: (groupId) {
              setState(() => _selectedGroupId = groupId);
            },
            onWeeksAheadChanged: (weeks) {
              setState(() => _weeksAhead = weeks);
            },
            onCreateReturnTripChanged: (value) {
              setState(() => _createReturnTrip = value);
            },
            onReturnTripStartTimeSelect: () =>
                _selectReturnTripStartTime(context),
            onReturnTripArrivalTimeSelect: () =>
                _selectReturnTripArrivalTime(context),
            onGenerate: _generateTripsFromGroup,
          ),
        ],
      ),
    );
  }

  // ==================== Business Logic Methods ====================

  Future<void> _selectDateTime(BuildContext context) async {
    // First select date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );

    if (pickedDate == null) return;

    // Then select time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTime = pickedTime;
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _generateTripsFromGroup() async {
    if (_selectedGroupId == null) return;

    final l10n = AppLocalizations.of(context);

    // Validate return trip options
    if (_createReturnTrip && _returnTripStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.pleaseSelectReturnTripStartTime,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await ref
          .read(groupActionsProvider.notifier)
          .generateTrips(_selectedGroupId!, weeks: _weeksAhead);

      if (mounted) {
        HapticFeedback.heavyImpact();
        if (result.count > 0) {
          // جلب بيانات الرحلات المولدة
          final repository = ref.read(tripRepositoryProvider);
          if (repository != null && result.tripIds.isNotEmpty) {
            try {
              final trips = <Trip>[];
              Trip? pickupTrip;

              for (final tripId in result.tripIds) {
                final tripResult = await repository.getTripById(tripId);
                tripResult.fold((failure) => null, (trip) {
                  trips.add(trip);
                  // Find the first pickup trip for return trip creation
                  if (pickupTrip == null && trip.tripType == TripType.pickup) {
                    pickupTrip = trip;
                  }
                });
              }

              // Create return trip if requested
              if (_createReturnTrip &&
                  pickupTrip != null &&
                  _returnTripStartTime != null) {
                try {
                  final returnTripResult = await repository.createReturnTrip(
                    pickupTrip!.id,
                    startTime: _returnTripStartTime!,
                    arrivalTime: _returnTripArrivalTime,
                  );

                  returnTripResult.fold(
                    (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${l10n.errorCreatingReturnTrip}: ${failure.message}',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    },
                    (returnTrip) {
                      trips.add(returnTrip);
                    },
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${l10n.errorCreatingReturnTrip}: $e',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              }

              // إظهار حوار مع الرحلات المولدة
              if (mounted && trips.isNotEmpty) {
                await _showGeneratedTripsDialog(trips, trips.length);
              }
            } catch (e) {
              // في حالة فشل جلب الرحلات، نعرض رسالة بسيطة
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${Formatters.formatSimple(result.count)} ${l10n.tripsGeneratedSuccessfully}',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: AppColors.success,
                  action: SnackBarAction(
                    label: l10n.view,
                    textColor: Colors.white,
                    onPressed: () {
                      context.go('${RoutePaths.dispatcherHome}/trips');
                    },
                  ),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${Formatters.formatSimple(result.count)} ${l10n.tripsGeneratedSuccessfully}',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.success,
                action: SnackBarAction(
                  label: l10n.view,
                  textColor: Colors.white,
                  onPressed: () {
                    context.go('${RoutePaths.dispatcherHome}/trips');
                  },
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.noTripsGenerated,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.error}: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectReturnTripStartTime(BuildContext context) async {
    final now = DateTime.now();
    final initialDate =
        _returnTripStartTime ?? now.add(const Duration(hours: 2));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime != null) {
      setState(() {
        _returnTripStartTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        // Auto-set arrival time to 1 hour after start if not set
        if (_returnTripArrivalTime == null ||
            _returnTripArrivalTime!.isBefore(_returnTripStartTime!)) {
          _returnTripArrivalTime = _returnTripStartTime!.add(
            const Duration(hours: 1),
          );
        }
      });
    }
  }

  Future<void> _selectReturnTripArrivalTime(BuildContext context) async {
    if (_returnTripStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).pleaseSelectStartTimeFirst,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _returnTripArrivalTime ?? _returnTripStartTime!,
      firstDate: _returnTripStartTime!,
      lastDate: _returnTripStartTime!.add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _returnTripArrivalTime ??
            _returnTripStartTime!.add(const Duration(hours: 1)),
      ),
    );

    if (pickedTime != null) {
      final selected = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (selected.isBefore(_returnTripStartTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).arrivalTimeMustBeAfterStartTime,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _returnTripArrivalTime = selected;
      });
    }
  }

  Future<void> _showGeneratedTripsDialog(
    List<Trip> trips,
    int totalCount,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.generatedTrips,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${Formatters.formatSimple(totalCount)} ${l10n.tripsGeneratedSuccessfully}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.generatedTrips}:',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: trips.length > 10 ? 10 : trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            trip.tripType == TripType.pickup
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 16,
                            color: AppColors.dispatcherPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              trip.name,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (trip.plannedStartTime != null)
                            Text(
                              Formatters.time(trip.plannedStartTime!),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (trips.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${l10n.andMore} ${trips.length - 10} ${l10n.moreTrips}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.close,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('${RoutePaths.dispatcherHome}/trips');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dispatcherPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n.viewAllTrips,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createManualTrip() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    // Validate return trip options if enabled
    if (_createReturnTrip && _tripType == TripType.pickup) {
      if (_returnTripStartTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.pleaseSelectReturnTripStartTime,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // إنشاء كائن الرحلة من البيانات المدخلة
      final plannedStartDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // حساب وقت الوصول المتوقع (إضافة ساعة افتراضياً)
      final plannedArrivalDateTime = plannedStartDateTime.add(
        const Duration(hours: 1),
      );

      // التحقق من وجود السائق (إلزامي)
      if (_selectedDriverId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.assignDriver,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.ok,
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }

      // التحقق من وجود ركاب (إلزامي)
      if (_selectedPassengerIds.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.pleaseSelectAtLeastOnePassenger,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.ok,
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }

      // التحقق من أن التاريخ والوقت في المستقبل
      if (plannedStartDateTime.isBefore(DateTime.now())) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.dateTimeMustBeInFuture,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final trip = Trip(
        id: 0, // سيتم تعيينه من الخادم
        name: _nameController.text.trim(),
        state: TripState.draft,
        tripType: _tripType,
        date: _selectedDate,
        plannedStartTime: plannedStartDateTime,
        plannedArrivalTime: plannedArrivalDateTime,
        driverId: _selectedDriverId, // السائق إلزامي
        companionId: _selectedCompanionId, // المرافق (اختياري)
        vehicleId: _selectedVehicleId,
        groupId: _selectedGroupId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(), // الملاحظات
      );

      // إنشاء الرحلة عبر الـ repository
      final repository = ref.read(tripRepositoryProvider);
      if (repository == null) {
        throw Exception(l10n.cannotAccessTripRepository);
      }

      final result = await repository.createTrip(trip);

      if (mounted) {
        HapticFeedback.heavyImpact();
        result.fold(
          (failure) {
            // Check if it's a driver conflict error
            if (failure.message.contains('Driver conflict') ||
                failure.message.contains('already assigned')) {
              _showDriverConflictDialog(failure.message, l10n);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${l10n.errorCreatingTrip}: ${failure.message}',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          (createdTrip) async {
            // Create return trip if requested and trip is pickup
            Trip? returnTrip;
            if (_createReturnTrip &&
                _tripType == TripType.pickup &&
                _returnTripStartTime != null) {
              try {
                final returnTripResult = await repository.createReturnTrip(
                  createdTrip.id,
                  startTime: _returnTripStartTime!,
                  arrivalTime: _returnTripArrivalTime,
                );

                returnTripResult.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${l10n.errorCreatingReturnTrip}: ${failure.message}',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  },
                  (trip) {
                    returnTrip = trip;
                  },
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n.errorCreatingReturnTrip}: $e',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            }

            // Show success message
            final message = returnTrip != null
                ? l10n.returnTripCreatedSuccessfully
                : l10n.createdSuccessfully;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.success,
                action: returnTrip != null
                    ? SnackBarAction(
                        label: l10n.view,
                        textColor: Colors.white,
                        onPressed: () {
                          context.go(
                            '${RoutePaths.dispatcherHome}/trips/${returnTrip!.id}',
                          );
                        },
                      )
                    : null,
              ),
            );

            // الانتقال مباشرة إلى صفحة تفاصيل الرحلة بعد إنشاء الرحلة
            context.go('${RoutePaths.dispatcherHome}/trips/${createdTrip.id}');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.error}: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show driver conflict dialog with formatted details
  Future<void> _showDriverConflictDialog(
    String errorMessage,
    AppLocalizations l10n,
  ) async {
    // Parse conflict details from error message
    final conflictDetails = _parseDriverConflict(errorMessage);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.driverConflict,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  l10n.driverConflictMessage,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (conflictDetails.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.details,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                // Conflict details
                if (conflictDetails.containsKey('driver'))
                  _buildConflictDetailRow(
                    icon: Icons.person_rounded,
                    label: l10n.driver,
                    value: conflictDetails['driver']!,
                    color: AppColors.dispatcherPrimary,
                  ),
                if (conflictDetails.containsKey('driver'))
                  const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.route_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.trip,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (conflictDetails.containsKey('trip'))
                        _buildConflictDetailRow(
                          icon: Icons.label_rounded,
                          label: l10n.tripName,
                          value: conflictDetails['trip']!,
                        ),
                      if (conflictDetails.containsKey('trip'))
                        const SizedBox(height: 6),
                      if (conflictDetails.containsKey('time'))
                        _buildConflictDetailRow(
                          icon: Icons.schedule_rounded,
                          label: l10n.time,
                          value: conflictDetails['time']!,
                        ),
                      if (conflictDetails.containsKey('time'))
                        const SizedBox(height: 6),
                      if (conflictDetails.containsKey('group'))
                        _buildConflictDetailRow(
                          icon: Icons.groups_rounded,
                          label: l10n.group,
                          value: conflictDetails['group']!,
                        ),
                      if (conflictDetails.containsKey('group'))
                        const SizedBox(height: 6),
                      if (conflictDetails.containsKey('vehicle'))
                        _buildConflictDetailRow(
                          icon: Icons.directions_bus_rounded,
                          label: l10n.vehicle,
                          value: conflictDetails['vehicle']!,
                        ),
                      if (conflictDetails.containsKey('vehicle'))
                        const SizedBox(height: 6),
                      if (conflictDetails.containsKey('status'))
                        _buildConflictDetailRow(
                          icon: Icons.info_rounded,
                          label: l10n.status,
                          value: conflictDetails['status']!,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.ok,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _parseDriverConflict(String errorMessage) {
    final details = <String, String>{};

    // Extract driver name
    final driverMatch = RegExp(r'Driver "([^"]+)"').firstMatch(errorMessage);
    if (driverMatch != null) {
      details['driver'] = driverMatch.group(1)!;
    }

    // Extract trip name
    final tripMatch = RegExp(r'Trip: ([^\n]+)').firstMatch(errorMessage);
    if (tripMatch != null) {
      details['trip'] = tripMatch.group(1)!.trim();
    }

    // Extract time
    final timeMatch = RegExp(r'Time: ([^\n]+)').firstMatch(errorMessage);
    if (timeMatch != null) {
      details['time'] = timeMatch.group(1)!.trim();
    }

    // Extract group
    final groupMatch = RegExp(r'Group: ([^\n]+)').firstMatch(errorMessage);
    if (groupMatch != null) {
      details['group'] = groupMatch.group(1)!.trim();
    }

    // Extract vehicle
    final vehicleMatch = RegExp(r'Vehicle: ([^\n]+)').firstMatch(errorMessage);
    if (vehicleMatch != null) {
      details['vehicle'] = vehicleMatch.group(1)!.trim();
    }

    // Extract status
    final statusMatch = RegExp(r'Status: ([^\n]+)').firstMatch(errorMessage);
    if (statusMatch != null) {
      details['status'] = statusMatch.group(1)!.trim();
    }

    return details;
  }

  /// Build a conflict detail row
  Widget _buildConflictDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPassengerSelectionSheet(BuildContext context) async {
    final vehiclesAsync = ref.read(allVehiclesProvider);
    int? maxSeats;

    // Get max seats from selected vehicle
    if (_selectedVehicleId != null) {
      vehiclesAsync.whenData((vehicles) {
        final vehicle =
            vehicles.firstWhere((v) => v.id == _selectedVehicleId);
        maxSeats = vehicle.seatCapacity;
      });
    }

    // Show passenger selection sheet from extracted widget
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PassengerSelectionSheet(
        selectedPassengerIds: Set.from(_selectedPassengerIds),
        maxSeats: maxSeats,
        onSelectionChanged: (ids) {
          Navigator.of(context).pop(ids);
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPassengerIds.clear();
        _selectedPassengerIds.addAll(result);
      });
    }
  }
}
