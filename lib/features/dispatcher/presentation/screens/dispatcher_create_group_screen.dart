import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';

/// Dispatcher Create Group Screen - شاشة إنشاء مجموعة جديدة - ShuttleBee
class DispatcherCreateGroupScreen extends ConsumerStatefulWidget {
  const DispatcherCreateGroupScreen({super.key});

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
  final _subscriptionPriceController = TextEditingController();

  GroupTripType _tripType = GroupTripType.both;
  BillingCycle _billingCycle = BillingCycle.monthly;
  int? _selectedVehicleId;
  bool _useCompanyDestination = true;
  bool _autoScheduleEnabled = true;
  int _autoScheduleWeeks = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _notesController.dispose();
    _totalSeatsController.dispose();
    _subscriptionPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(allVehiclesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إنشاء مجموعة جديدة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            _buildSectionHeader('المعلومات الأساسية', Icons.info_outline_rounded),
            const SizedBox(height: 12),
            _buildBasicInfoCard(),

            const SizedBox(height: 24),

            // Trip Type Section
            _buildSectionHeader('نوع الرحلة', Icons.route_rounded),
            const SizedBox(height: 12),
            _buildTripTypeCard(),

            const SizedBox(height: 24),

            // Vehicle Section
            _buildSectionHeader('المركبة', Icons.directions_bus_rounded),
            const SizedBox(height: 12),
            _buildVehicleCard(vehiclesAsync),

            const SizedBox(height: 24),

            // Billing Section
            _buildSectionHeader('الفوترة', Icons.payments_rounded),
            const SizedBox(height: 12),
            _buildBillingCard(),

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
        Icon(icon, size: 20, color: const Color(0xFF7B1FA2)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: Color(0xFF7B1FA2),
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
                        ? const Color(0xFF7B1FA2).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7B1FA2)
                          : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getTripTypeIcon(type),
                        color: isSelected
                            ? const Color(0xFF7B1FA2)
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
                                    ? const Color(0xFF7B1FA2)
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _getTripTypeDescription(type),
                              style: TextStyle(
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
                          color: Color(0xFF7B1FA2),
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
            return DropdownButtonFormField<int>(
              value: _selectedVehicleId,
              decoration: _buildInputDecoration(
                label: 'اختر المركبة',
                hint: 'اختر المركبة المخصصة للمجموعة',
                icon: Icons.directions_bus_rounded,
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text(
                    'بدون مركبة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                ...activeVehicles.map((vehicle) {
                  return DropdownMenuItem<int>(
                    value: vehicle.id,
                    child: Text(
                      '${vehicle.name} (${vehicle.licensePlate ?? "بدون لوحة"})',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedVehicleId = value);
              },
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

  Widget _buildBillingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Billing Cycle
            DropdownButtonFormField<BillingCycle>(
              value: _billingCycle,
              decoration: _buildInputDecoration(
                label: 'دورة الفوترة',
                hint: 'اختر دورة الفوترة',
                icon: Icons.repeat_rounded,
              ),
              items: BillingCycle.values.map((cycle) {
                return DropdownMenuItem<BillingCycle>(
                  value: cycle,
                  child: Text(
                    cycle.arabicLabel,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _billingCycle = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Subscription Price
            TextFormField(
              controller: _subscriptionPriceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _buildInputDecoration(
                label: 'سعر الاشتراك (اختياري)',
                hint: 'مثال: 500.00',
                icon: Icons.attach_money_rounded,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
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
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'إنشاء الرحلات تلقائياً بناءً على الجداول',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
              value: _autoScheduleEnabled,
              activeColor: const Color(0xFF7B1FA2),
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
                  const Icon(Icons.date_range_rounded,
                      size: 20, color: AppColors.textSecondary),
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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B1FA2),
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
          _isLoading ? 'جاري الإنشاء...' : 'إنشاء المجموعة',
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
      prefixIcon: Icon(icon, color: const Color(0xFF7B1FA2)),
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
        borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 2),
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
      final group = PassengerGroup(
        id: 0,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isNotEmpty
            ? _codeController.text.trim()
            : null,
        vehicleId: _selectedVehicleId,
        totalSeats: int.parse(_totalSeatsController.text),
        tripType: _tripType,
        useCompanyDestination: _useCompanyDestination,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        subscriptionPrice: _subscriptionPriceController.text.isNotEmpty
            ? double.tryParse(_subscriptionPriceController.text)
            : null,
        billingCycle: _billingCycle,
        autoScheduleEnabled: _autoScheduleEnabled,
        autoScheduleWeeks: _autoScheduleWeeks,
        autoScheduleIncludePickup: _tripType != GroupTripType.dropoff,
        autoScheduleIncludeDropoff: _tripType != GroupTripType.pickup,
      );

      final createdGroup =
          await ref.read(groupActionsProvider.notifier).createGroup(group);

      if (createdGroup != null && mounted) {
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
}
