import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../stops/domain/entities/shuttle_stop.dart';
import '../../../stops/presentation/providers/stop_providers.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/dispatcher_app_bar.dart';

/// Dispatcher Create Group Screen - شاشة إنشاء مجموعة جديدة - ShuttleBee
class DispatcherCreateGroupScreen extends ConsumerStatefulWidget {
  final PassengerGroup? initialGroup;

  const DispatcherCreateGroupScreen({
    super.key,
    this.initialGroup,
  });

  @override
  ConsumerState<DispatcherCreateGroupScreen> createState() =>
      _DispatcherCreateGroupScreenState();
}

class _DispatcherCreateGroupScreenState
    extends ConsumerState<DispatcherCreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalSeatsController = TextEditingController(text: '15');

  GroupTripType _tripType = GroupTripType.both;
  int? _selectedVehicleId;
  int? _selectedDriverId;
  String? _selectedDriverName;

  bool _useCompanyDestination = true;
  int? _selectedDestinationStopId;
  bool _autoScheduleEnabled = true;
  int _autoScheduleWeeks = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final group = widget.initialGroup;
    if (group == null) return;

    _nameController.text = group.name;
    _codeController.text = group.code ?? '';
    _notesController.text = group.notes ?? '';
    _totalSeatsController.text = '${group.totalSeats}';

    _tripType = group.tripType;
    _selectedVehicleId = group.vehicleId;
    _selectedDriverId = group.driverId;
    _selectedDriverName = group.driverName;

    _useCompanyDestination = group.useCompanyDestination;
    _selectedDestinationStopId =
        group.useCompanyDestination ? null : group.destinationStopId;

    _autoScheduleEnabled = group.autoScheduleEnabled;
    _autoScheduleWeeks = group.autoScheduleWeeks;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _notesController.dispose();
    _totalSeatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(allVehiclesProvider);
    final dropoffStopsAsync = ref.watch(dropoffStopsProvider);
    final isEditMode = widget.initialGroup != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: DispatcherAppBar(
        title: isEditMode ? 'تعديل المجموعة' : 'إنشاء مجموعة جديدة',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            _buildSectionHeader(
              'المعلومات الأساسية',
              Icons.info_outline_rounded,
            ),
            const SizedBox(height: 12),
            _buildBasicInfoCard(),

            const SizedBox(height: 24),

            // Trip Type Section
            _buildSectionHeader('نوع الرحلة', Icons.route_rounded),
            const SizedBox(height: 12),
            _buildTripTypeCard(),

            const SizedBox(height: 24),

            // Destination Section
            _buildSectionHeader('الوجهة', Icons.flag_rounded),
            const SizedBox(height: 12),
            _buildDestinationCard(dropoffStopsAsync),

            const SizedBox(height: 24),

            // Vehicle Section
            _buildSectionHeader('المركبة', Icons.directions_bus_rounded),
            const SizedBox(height: 12),
            _buildVehicleCard(vehiclesAsync),

            const SizedBox(height: 24),

            // Schedule Section
            _buildSectionHeader('الجدولة التلقائية', Icons.schedule_rounded),
            const SizedBox(height: 12),
            _buildScheduleCard(),

            const SizedBox(height: 24),

            // Notes Section
            _buildSectionHeader('ملاحظات', Icons.notes_rounded),
            const SizedBox(height: 12),
            _buildNotesCard(),

            const SizedBox(height: 32),

            // Submit Button
            _buildSubmitButton(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration(
                label: 'اسم المجموعة',
                hint: 'مثال: مجموعة الصباح - المنطقة الشمالية',
                icon: Icons.group_rounded,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم المجموعة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Code Field
            TextFormField(
              controller: _codeController,
              decoration: _buildInputDecoration(
                label: 'رمز المجموعة (اختياري)',
                hint: 'مثال: GRP-001',
                icon: Icons.tag_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // Total Seats Field
            TextFormField(
              controller: _totalSeatsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _buildInputDecoration(
                label: 'عدد المقاعد',
                hint: '15',
                icon: Icons.event_seat_rounded,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال عدد المقاعد';
                }
                final seats = int.tryParse(value);
                if (seats == null || seats < 1) {
                  return 'يرجى إدخال عدد صحيح';
                }
                return null;
              },
            ),
          ],
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
        child: Column(
          children: GroupTripType.values.map((type) {
            final isSelected = _tripType == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
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
                  child: Row(
                    children: [
                      Icon(
                        _getTripTypeIcon(type),
                        color: isSelected
                            ? AppColors.dispatcherPrimary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.arabicLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: isSelected
                                    ? AppColors.dispatcherPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _getTripTypeDescription(type),
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: AppColors.textSecondary,
                              ),
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
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildVehicleCard(AsyncValue<List<ShuttleVehicle>> vehiclesAsync) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: vehiclesAsync.when(
          data: (vehicles) {
            final activeVehicles =
                vehicles.where((v) => v.active == true).toList();

            final selectedVehicleId = _selectedVehicleId;
            if (selectedVehicleId != null &&
                !activeVehicles.any((v) => v.id == selectedVehicleId)) {
              for (final v in vehicles) {
                if (v.id == selectedVehicleId) {
                  activeVehicles.insert(0, v);
                  break;
                }
              }
            }

            final safeSelectedVehicleId = selectedVehicleId != null &&
                    activeVehicles.any((v) => v.id == selectedVehicleId)
                ? selectedVehicleId
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: safeSelectedVehicleId,
                  decoration: _buildInputDecoration(
                    label: 'اختر المركبة',
                    hint: 'اختر المركبة المخصصة للمجموعة',
                    icon: Icons.directions_bus_rounded,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        'بدون مركبة',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    ...activeVehicles.map((vehicle) {
                      return DropdownMenuItem<int?>(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.name} (${vehicle.licensePlate ?? "بدون لوحة"})',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    ShuttleVehicle? selected;
                    if (value != null) {
                      for (final v in activeVehicles) {
                        if (v.id == value) {
                          selected = v;
                          break;
                        }
                      }
                    }
                    setState(() {
                      _selectedVehicleId = value;
                      _selectedDriverId = selected?.driverId;
                      _selectedDriverName = selected?.driverName;
                      if (selected != null && selected.seatCapacity > 0) {
                        _totalSeatsController.text = '${selected.seatCapacity}';
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDriverId != null
                            ? 'السائق: ${_selectedDriverName ?? "ID: $_selectedDriverId"}'
                            : 'السائق: غير محدد',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => const Text(
            'فشل في تحميل المركبات',
            style: TextStyle(fontFamily: 'Cairo', color: AppColors.error),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildDestinationCard(
      AsyncValue<List<ShuttleStop>> dropoffStopsAsync) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'استخدم وجهة الشركة',
                style:
                    TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'عند الإيقاف: يجب اختيار محطة وجهة (مدرسة/شركة)',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
              value: _useCompanyDestination,
              activeThumbColor: AppColors.dispatcherPrimary,
              onChanged: (v) {
                setState(() {
                  _useCompanyDestination = v;
                  if (v) {
                    _selectedDestinationStopId = null;
                  }
                });
              },
            ),
            if (!_useCompanyDestination) ...[
              const Divider(),
              const SizedBox(height: 8),
              dropoffStopsAsync.when(
                data: (stops) {
                  final activeStops =
                      stops.where((s) => s.active == true).toList();

                  final selectedStopId = _selectedDestinationStopId;
                  if (selectedStopId != null &&
                      !activeStops.any((s) => s.id == selectedStopId)) {
                    for (final s in stops) {
                      if (s.id == selectedStopId) {
                        activeStops.insert(0, s);
                        break;
                      }
                    }
                  }

                  final safeSelectedStopId = selectedStopId != null &&
                          activeStops.any((s) => s.id == selectedStopId)
                      ? selectedStopId
                      : null;
                  return DropdownButtonFormField<int?>(
                    initialValue: safeSelectedStopId,
                    decoration: _buildInputDecoration(
                      label: 'محطة الوجهة',
                      hint: 'اختر محطة الوجهة (مدرسة/شركة)',
                      icon: Icons.flag_rounded,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('اختر...',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      ...activeStops.map(
                        (s) => DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text(s.name,
                              style: const TextStyle(fontFamily: 'Cairo')),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedDestinationStopId = v),
                    validator: (v) {
                      if (!_useCompanyDestination && (v == null)) {
                        return 'يرجى اختيار محطة الوجهة';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text(
                  'فشل في تحميل محطات النزول',
                  style: TextStyle(fontFamily: 'Cairo', color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 250.ms);
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Auto Schedule Toggle
            SwitchListTile(
              title: const Text(
                'تفعيل الجدولة التلقائية',
                style:
                    TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'إنشاء الرحلات تلقائياً بناءً على الجداول',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
              value: _autoScheduleEnabled,
              activeThumbColor: AppColors.dispatcherPrimary,
              onChanged: (value) {
                setState(() => _autoScheduleEnabled = value);
              },
            ),
            if (_autoScheduleEnabled) ...[
              const Divider(),
              const SizedBox(height: 8),

              // Weeks Ahead
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
                      'عدد الأسابيع مقدماً',
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
                          onPressed: _autoScheduleWeeks > 1
                              ? () => setState(() => _autoScheduleWeeks--)
                              : null,
                        ),
                        Text(
                          '$_autoScheduleWeeks',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded),
                          onPressed: _autoScheduleWeeks < 4
                              ? () => setState(() => _autoScheduleWeeks++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms);
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: _buildInputDecoration(
            label: 'ملاحظات إضافية',
            hint: 'أي ملاحظات خاصة بالمجموعة...',
            icon: Icons.notes_rounded,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 600.ms);
  }

  Widget _buildSubmitButton() {
    final isEditMode = widget.initialGroup != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
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
            : const Icon(Icons.check_rounded),
        label: Text(
          _isLoading
              ? (isEditMode ? 'جاري الحفظ...' : 'جاري الإنشاء...')
              : (isEditMode ? 'حفظ التعديلات' : 'إنشاء المجموعة'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 700.ms);
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

  IconData _getTripTypeIcon(GroupTripType type) {
    return switch (type) {
      GroupTripType.pickup => Icons.arrow_upward_rounded,
      GroupTripType.dropoff => Icons.arrow_downward_rounded,
      GroupTripType.both => Icons.swap_vert_rounded,
    };
  }

  String _getTripTypeDescription(GroupTripType type) {
    return switch (type) {
      GroupTripType.pickup => 'نقل الركاب من نقاط التجميع إلى الوجهة',
      GroupTripType.dropoff => 'توصيل الركاب من الوجهة إلى نقاط النزول',
      GroupTripType.both => 'رحلات صعود ونزول للركاب',
    };
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final isEditMode = widget.initialGroup != null;

      if (_autoScheduleEnabled && _selectedDriverId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'لا يمكن تفعيل الجدولة التلقائية بدون سائق. اختر مركبة لها سائق أو عطّل الجدولة التلقائية.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      if (!_useCompanyDestination && _selectedDestinationStopId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'يرجى اختيار محطة الوجهة أو تفعيل "استخدم وجهة الشركة".',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (isEditMode) {
        final existing = widget.initialGroup;
        if (existing == null) return;

        final updated = PassengerGroup(
          id: existing.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isNotEmpty
              ? _codeController.text.trim()
              : null,
          driverId: _selectedDriverId,
          driverName: _selectedDriverName,
          vehicleId: _selectedVehicleId,
          vehicleName: existing.vehicleName,
          totalSeats: int.parse(_totalSeatsController.text),
          tripType: _tripType,
          useCompanyDestination: _useCompanyDestination,
          destinationStopId:
              !_useCompanyDestination ? _selectedDestinationStopId : null,
          destinationStopName: existing.destinationStopName,
          destinationLatitude: existing.destinationLatitude,
          destinationLongitude: existing.destinationLongitude,
          color: existing.color,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          active: existing.active,
          companyId: existing.companyId,
          companyName: existing.companyName,
          memberCount: existing.memberCount,
          subscriptionPrice: existing.subscriptionPrice,
          billingCycle: existing.billingCycle,
          schedules: existing.schedules,
          holidays: existing.holidays,
          autoScheduleEnabled: _autoScheduleEnabled,
          autoScheduleWeeks: _autoScheduleWeeks,
          autoScheduleIncludePickup: _tripType != GroupTripType.dropoff,
          autoScheduleIncludeDropoff: _tripType != GroupTripType.pickup,
          scheduleTimezone: existing.scheduleTimezone,
        );

        final saved =
            await ref.read(groupActionsProvider.notifier).updateGroup(updated);

        if (saved != null && mounted) {
          await _invalidateDispatcherGroupsCache();
          if (!mounted) return;

          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تحديث المجموعة بنجاح',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.success,
            ),
          );

          context.go('${RoutePaths.dispatcherHome}/groups');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'فشل في تحديث المجموعة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }

        return;
      }

      final group = PassengerGroup(
        id: 0,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isNotEmpty
            ? _codeController.text.trim()
            : null,
        driverId: _selectedDriverId,
        vehicleId: _selectedVehicleId,
        totalSeats: int.parse(_totalSeatsController.text),
        tripType: _tripType,
        useCompanyDestination: _useCompanyDestination,
        destinationStopId:
            !_useCompanyDestination ? _selectedDestinationStopId : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        autoScheduleEnabled: _autoScheduleEnabled,
        autoScheduleWeeks: _autoScheduleWeeks,
        autoScheduleIncludePickup: _tripType != GroupTripType.dropoff,
        autoScheduleIncludeDropoff: _tripType != GroupTripType.pickup,
      );

      final createdGroup =
          await ref.read(groupActionsProvider.notifier).createGroup(group);

      if (createdGroup != null && mounted) {
        await _invalidateDispatcherGroupsCache();
        if (!mounted) return;

        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء المجموعة بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );

        // Generate trips immediately (do not wait for Odoo cron).
        if (_autoScheduleEnabled) {
          try {
            final includePickup = _tripType != GroupTripType.dropoff;
            final includeDropoff = _tripType != GroupTripType.pickup;

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final result =
                await ref.read(groupActionsProvider.notifier).generateTrips(
                      createdGroup.id,
                      weeks: _autoScheduleWeeks,
                      startDate: today,
                      includePickup: includePickup,
                      includeDropoff: includeDropoff,
                      limitToWeek: false,
                    );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.count > 0
                      ? 'تم توليد ${result.count} رحلة تلقائياً'
                      : 'لم يتم توليد أي رحلات (تحقق من الجدول أو تعارض السائق/المركبة)',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor:
                    result.count > 0 ? AppColors.success : AppColors.warning,
                action: result.count > 0
                    ? null
                    : SnackBarAction(
                        label: 'فتح الجداول',
                        textColor: Colors.white,
                        onPressed: () {
                          context.go(
                            '${RoutePaths.dispatcherHome}/groups/${createdGroup.id}/schedules',
                          );
                        },
                      ),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            final msg = e.toString();
            final isNoTrips = msg.contains('No trips were created') ||
                msg.contains('لم يتم إنشاء رحلات');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isNoTrips
                      ? 'لم يتم إنشاء رحلات. السبب غالباً: لا يوجد جدول فعّال أو يوجد تعارض مع رحلات أخرى للسائق/المركبة.'
                      : 'فشل توليد الرحلات: $e',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.warning,
                action: SnackBarAction(
                  label: 'فتح الجداول',
                  textColor: Colors.white,
                  onPressed: () {
                    context.go(
                      '${RoutePaths.dispatcherHome}/groups/${createdGroup.id}/schedules',
                    );
                  },
                ),
              ),
            );
          }
        }

        if (!mounted) return;
        context.go('${RoutePaths.dispatcherHome}/groups');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'فشل في إنشاء المجموعة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
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

  Future<void> _invalidateDispatcherGroupsCache() async {
    final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
    if (userId == 0) return;

    final cache = ref.read(dispatcherCacheDataSourceProvider);
    await cache.delete(DispatcherCacheKeys.groups(userId: userId));
    ref.invalidate(dispatcherGroupsProvider);
  }
}
