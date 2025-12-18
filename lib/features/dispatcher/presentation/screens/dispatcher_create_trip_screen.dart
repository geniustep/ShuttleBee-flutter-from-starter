import 'package:bridgecore_flutter_starter/features/dispatcher/presentation/providers/dispatcher_cached_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common/desktop_sidebar_wrapper.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../vehicles/presentation/providers/fleet_providers.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../widgets/dispatcher_app_bar.dart';

/// Dispatcher Create Trip Screen - شاشة إنشاء/توليد رحلة - ShuttleBee
class DispatcherCreateTripScreen extends ConsumerStatefulWidget {
  final int? initialGroupId;

  const DispatcherCreateTripScreen({
    super.key,
    this.initialGroupId,
  });

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
  TripType _tripType = TripType.pickup;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedGroupId;
  int? _selectedVehicleId;
  int? _selectedDriverId;
  int? _selectedCompanionId; // NEW: المرافق
  int _weeksAhead = 1;
  bool _isLoading = false;

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
              icon: const Icon(Icons.groups_rounded),
              text: AppLocalizations.of(context).generateFromGroup,
            ),
            Tab(
              icon: const Icon(Icons.add_circle_outline_rounded),
              text: AppLocalizations.of(context).manualTrip,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFromGroupTab(),
          _buildManualTripTab(),
        ],
      ),
    );
  }

  Widget _buildFromGroupTab() {
    final groupsAsync = ref.watch(allGroupsProvider);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info Card
        _buildInfoCard(
          icon: Icons.lightbulb_outline_rounded,
          title: l10n.generateTripsFromGroup,
          message: l10n.selectGroupToGenerate,
        ),
        const SizedBox(height: 24),

        // Group Selection
        _buildSectionHeader(l10n.group, Icons.groups_rounded),
        const SizedBox(height: 12),
        _buildGroupSelectionCard(groupsAsync),

        const SizedBox(height: 24),

        // Generation Options
        _buildSectionHeader(l10n.generationOptions, Icons.settings_rounded),
        const SizedBox(height: 12),
        _buildGenerationOptionsCard(),

        const SizedBox(height: 32),

        // Generate Button
        _buildGenerateButton(),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildManualTripTab() {
    final vehiclesAsync = ref.watch(allVehiclesProvider);
    final groupsAsync = ref.watch(allGroupsProvider);
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            title: l10n.createManualTrip,
            message: l10n.createManualTripDesc,
          ),
          const SizedBox(height: 24),

          // Basic Info
          _buildSectionHeader(l10n.basicInfo, Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _buildManualBasicInfoCard(),

          const SizedBox(height: 24),

          // Trip Type
          _buildSectionHeader(l10n.tripType, Icons.route_rounded),
          const SizedBox(height: 12),
          _buildTripTypeCard(),

          const SizedBox(height: 24),

          // Date & Time
          _buildSectionHeader(
            '${l10n.date} ${l10n.time}',
            Icons.schedule_rounded,
          ),
          const SizedBox(height: 12),
          _buildDateTimeCard(),

          const SizedBox(height: 24),

          // Group, Driver & Vehicle
          _buildSectionHeader(
            '${l10n.group}, ${l10n.driver} & ${l10n.vehicle}',
            Icons.directions_bus_rounded,
          ),
          const SizedBox(height: 12),
          _buildGroupDriverVehicleCard(groupsAsync, vehiclesAsync),

          const SizedBox(height: 32),

          // Create Button
          _buildCreateManualButton(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dispatcherPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.dispatcherPrimary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.dispatcherPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.dispatcherPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.dispatcherPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSelectionCard(
    AsyncValue<List<PassengerGroup>> groupsAsync,
  ) {
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
                    AppLocalizations.of(context).noActiveGroups,
                    style: const TextStyle(fontFamily: 'Cairo'),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: activeGroups.map((group) {
                final isSelected = _selectedGroupId == group.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedGroupId = group.id);
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
                                  ? AppColors.dispatcherPrimary
                                      .withValues(alpha: 0.2)
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
                                      '${group.memberCount} ${AppLocalizations.of(context).passenger}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Cairo',
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '• ${group.tripType.getLocalizedLabel(context)}',
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
              AppLocalizations.of(context).failedToLoadGroups,
              style:
                  const TextStyle(fontFamily: 'Cairo', color: AppColors.error),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildGenerationOptionsCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Weeks Selection
            Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.weeksToGenerate,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded),
                        onPressed: _weeksAhead > 1
                            ? () => setState(() => _weeksAhead--)
                            : null,
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$_weeksAhead',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _weeksAhead < 4
                            ? () => setState(() => _weeksAhead++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
                      '${l10n.willGenerateTrips} $_weeksAhead ${_weeksAhead == 1 ? l10n.week : l10n.weeks} ${l10n.weeksAhead}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildManualBasicInfoCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _nameController,
          decoration: _buildInputDecoration(
            label: l10n.tripName,
            hint: l10n.tripNameExample,
            icon: Icons.route_rounded,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.fieldRequired;
            }
            return null;
          },
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildTripTypeCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildTripTypeOption(
                type: TripType.pickup,
                icon: Icons.arrow_upward_rounded,
                label: l10n.pickup,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTripTypeOption(
                type: TripType.dropoff,
                icon: Icons.arrow_downward_rounded,
                label: l10n.dropoff,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildTripTypeOption({
    required TripType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _tripType == type;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _tripType = type);
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
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.dispatcherPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isSelected
                    ? AppColors.dispatcherPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Selection
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.dispatcherPrimary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).date,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            Formatters.displayDate(_selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time Selection
            InkWell(
              onTap: () => _selectTime(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.dispatcherPrimary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).time,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildGroupDriverVehicleCard(
    AsyncValue<List<PassengerGroup>> groupsAsync,
    AsyncValue<List<ShuttleVehicle>> vehiclesAsync,
  ) {
    final driversAsync = ref.watch(availableDriversProvider);

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
                            AppLocalizations.of(context).noDriversAvailable,
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
                  initialValue: _selectedDriverId,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    label: '${AppLocalizations.of(context).driver} *',
                    hint: AppLocalizations.of(context).selectDriver,
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
                  onChanged: (value) {
                    setState(() => _selectedDriverId = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return AppLocalizations.of(context).pleaseSelectDriver;
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
                  initialValue: _selectedGroupId,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    label:
                        '${AppLocalizations.of(context).group} (${AppLocalizations.of(context).optional})',
                    hint: AppLocalizations.of(context).selectGroup,
                    icon: Icons.groups_rounded,
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        AppLocalizations.of(context).noGroup,
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
                  onChanged: (value) {
                    setState(() => _selectedGroupId = value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Vehicle Dropdown
            vehiclesAsync.when(
              data: (vehicles) {
                final activeVehicles =
                    vehicles.where((v) => v.active == true).toList();
                return DropdownButtonFormField<int>(
                  initialValue: _selectedVehicleId,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    label:
                        '${AppLocalizations.of(context).vehicle} (${AppLocalizations.of(context).optional})',
                    hint: AppLocalizations.of(context).selectVehicle,
                    icon: Icons.directions_bus_rounded,
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        AppLocalizations.of(context).noVehicle,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...activeVehicles.map((vehicle) {
                      return DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.name} (${vehicle.licensePlate ?? AppLocalizations.of(context).noLicensePlate})',
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
                        final selectedVehicle =
                            activeVehicles.firstWhere((v) => v.id == value);
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
                    setState(() {
                      _selectedVehicleId = value;
                      if (newDriverId != null) {
                        _selectedDriverId = newDriverId;
                      }
                    });
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // NEW: Companion Dropdown
            ref.watch(driversAndCompanionsProvider).when(
                  data: (users) {
                    final l10n = AppLocalizations.of(context);
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedCompanionId,
                      isExpanded: true,
                      decoration: _buildInputDecoration(
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
                        ...users.map((user) {
                          return DropdownMenuItem<int>(
                            value: user.id,
                            child: Text(
                              user.name,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCompanionId = value);
                      },
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

  Widget _buildGenerateButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _selectedGroupId == null || _isLoading
            ? null
            : _generateTripsFromGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isLoading
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
          _isLoading ? l10n.generating : l10n.generateTrips,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildCreateManualButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _createManualTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dispatcherPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isLoading
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
          _isLoading ? l10n.creating : l10n.createTrip,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms);
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.dispatcherPrimary),
      labelStyle: const TextStyle(fontFamily: 'Cairo'),
      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.dispatcherPrimary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _generateTripsFromGroup() async {
    if (_selectedGroupId == null) return;

    final l10n = AppLocalizations.of(context);
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
              for (final tripId in result.tripIds) {
                final tripResult = await repository.getTripById(tripId);
                tripResult.fold(
                  (failure) => null,
                  (trip) => trips.add(trip),
                );
              }

              // إظهار حوار مع الرحلات المولدة
              if (mounted && trips.isNotEmpty) {
                await _showGeneratedTripsDialog(trips, result.count);
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
                              DateFormat('HH:mm')
                                  .format(trip.plannedStartTime!),
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

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final l10n = AppLocalizations.of(context);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.assignDriver,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
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
        companionId: _selectedCompanionId, // NEW: المرافق (اختياري)
        vehicleId: _selectedVehicleId,
        groupId: _selectedGroupId,
        notes: null,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${l10n.errorCreatingTrip}: ${failure.message}',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          },
          (createdTrip) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.createdSuccessfully,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.success,
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
}
