import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: DispatcherAppBar(
        title: 'إنشاء رحلة',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.groups_rounded),
              text: 'من مجموعة',
            ),
            Tab(
              icon: Icon(Icons.add_circle_outline_rounded),
              text: 'رحلة يدوية',
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info Card
        _buildInfoCard(
          icon: Icons.lightbulb_outline_rounded,
          title: 'توليد رحلات من مجموعة',
          message:
              'اختر مجموعة موجودة لتوليد الرحلات تلقائياً بناءً على جداولها المحددة',
        ),
        const SizedBox(height: 24),

        // Group Selection
        _buildSectionHeader('اختر المجموعة', Icons.groups_rounded),
        const SizedBox(height: 12),
        _buildGroupSelectionCard(groupsAsync),

        const SizedBox(height: 24),

        // Generation Options
        _buildSectionHeader('خيارات التوليد', Icons.settings_rounded),
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

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            title: 'إنشاء رحلة يدوياً',
            message:
                'قم بتحديد تفاصيل الرحلة يدوياً بدون الاعتماد على جدول مجموعة',
          ),
          const SizedBox(height: 24),

          // Basic Info
          _buildSectionHeader('المعلومات الأساسية', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _buildManualBasicInfoCard(),

          const SizedBox(height: 24),

          // Trip Type
          _buildSectionHeader('نوع الرحلة', Icons.route_rounded),
          const SizedBox(height: 12),
          _buildTripTypeCard(),

          const SizedBox(height: 24),

          // Date & Time
          _buildSectionHeader('التاريخ والوقت', Icons.schedule_rounded),
          const SizedBox(height: 12),
          _buildDateTimeCard(),

          const SizedBox(height: 24),

          // Group, Driver & Vehicle
          _buildSectionHeader(
              'المجموعة والسائق والمركبة', Icons.directions_bus_rounded),
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
      AsyncValue<List<PassengerGroup>> groupsAsync) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: groupsAsync.when(
          data: (groups) {
            final activeGroups = groups.where((g) => g.active).toList();
            if (activeGroups.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد مجموعات نشطة. قم بإنشاء مجموعة أولاً.',
                    style: TextStyle(fontFamily: 'Cairo'),
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
                                      '${group.memberCount} راكب',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Cairo',
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '• ${group.tripType.arabicLabel}',
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
          error: (_, __) => const Center(
            child: Text(
              'فشل في تحميل المجموعات',
              style: TextStyle(fontFamily: 'Cairo', color: AppColors.error),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildGenerationOptionsCard() {
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
                const Expanded(
                  child: Text(
                    'عدد الأسابيع للتوليد',
                    style: TextStyle(fontFamily: 'Cairo'),
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
                      'سيتم توليد الرحلات لـ $_weeksAhead ${_weeksAhead == 1 ? "أسبوع" : "أسابيع"} قادمة بناءً على جداول المجموعة',
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _nameController,
          decoration: _buildInputDecoration(
            label: 'اسم الرحلة',
            hint: 'مثال: رحلة الصباح - المنطقة الشمالية',
            icon: Icons.route_rounded,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال اسم الرحلة';
            }
            return null;
          },
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildTripTypeCard() {
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
                label: 'صعود',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTripTypeOption(
                type: TripType.dropoff,
                icon: Icons.arrow_downward_rounded,
                label: 'نزول',
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
                          const Text(
                            'التاريخ',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE، d MMMM yyyy', 'ar')
                                .format(_selectedDate),
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
                          const Text(
                            'الوقت',
                            style: TextStyle(
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
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'لا توجد سائقين متاحين',
                            style: TextStyle(
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
                  value: _selectedDriverId,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    label: 'السائق *',
                    hint: 'اختر السائق',
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
                      return 'يرجى اختيار السائق';
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
                  value: _selectedGroupId,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    label: 'المجموعة (اختياري)',
                    hint: 'اختر المجموعة',
                    icon: Icons.groups_rounded,
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        'بدون مجموعة',
                        style: TextStyle(fontFamily: 'Cairo'),
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
                  value: _selectedVehicleId,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                    label: 'المركبة (اختياري)',
                    hint: 'اختر المركبة',
                    icon: Icons.directions_bus_rounded,
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        'بدون مركبة',
                        style: TextStyle(fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...activeVehicles.map((vehicle) {
                      return DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.name} (${vehicle.licensePlate ?? "بدون لوحة"})',
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
                            final driverExists = drivers.any((driver) =>
                                driver.id == selectedVehicle.driverId);
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
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }

  Widget _buildGenerateButton() {
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
          _isLoading ? 'جاري التوليد...' : 'توليد الرحلات',
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
          _isLoading ? 'جاري الإنشاء...' : 'إنشاء الرحلة',
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
                    'تم توليد ${result.count} رحلة بنجاح',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: AppColors.success,
                  action: SnackBarAction(
                    label: 'عرض',
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
                  'تم توليد ${result.count} رحلة بنجاح',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.success,
                action: SnackBarAction(
                  label: 'عرض',
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
            const SnackBar(
              content: Text(
                'لم يتم توليد أي رحلات. تأكد من وجود جداول للمجموعة.',
                style: TextStyle(fontFamily: 'Cairo'),
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
              'خطأ: $e',
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
      List<Trip> trips, int totalCount) async {
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
                'تم توليد الرحلات',
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
                  'تم توليد $totalCount رحلة بنجاح',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'الرحلات المولدة:',
                style: TextStyle(
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
                    'و ${trips.length - 10} رحلة أخرى...',
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
            child: const Text(
              'إغلاق',
              style: TextStyle(fontFamily: 'Cairo'),
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
            child: const Text(
              'عرض جميع الرحلات',
              style: TextStyle(fontFamily: 'Cairo'),
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
          const SnackBar(
            content: Text(
              'يرجى اختيار السائق',
              style: TextStyle(fontFamily: 'Cairo'),
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
        vehicleId: _selectedVehicleId,
        groupId: _selectedGroupId,
        notes: null,
      );

      // إنشاء الرحلة عبر الـ repository
      final repository = ref.read(tripRepositoryProvider);
      if (repository == null) {
        throw Exception('لا يمكن الوصول إلى مستودع الرحلات');
      }

      final result = await repository.createTrip(trip);

      if (mounted) {
        HapticFeedback.heavyImpact();
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'خطأ في إنشاء الرحلة: ${failure.message}',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          },
          (createdTrip) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم إنشاء الرحلة بنجاح',
                  style: TextStyle(fontFamily: 'Cairo'),
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
              'خطأ: $e',
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
