import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/dispatcher_app_bar.dart';

/// Dispatcher Create Vehicle Screen - شاشة إضافة مركبة - ShuttleBee
class DispatcherCreateVehicleScreen extends ConsumerStatefulWidget {
  const DispatcherCreateVehicleScreen({super.key});

  @override
  ConsumerState<DispatcherCreateVehicleScreen> createState() =>
      _DispatcherCreateVehicleScreenState();
}

class _DispatcherCreateVehicleScreenState
    extends ConsumerState<DispatcherCreateVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _seatCapacityController = TextEditingController(text: '15');
  final _noteController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _homeLatController = TextEditingController();
  final _homeLngController = TextEditingController();

  bool _active = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _seatCapacityController.dispose();
    _noteController.dispose();
    _homeAddressController.dispose();
    _homeLatController.dispose();
    _homeLngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const DispatcherAppBar(title: 'إضافة مركبة'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isOnline)
              _buildInfoBanner(
                icon: Icons.cloud_off_rounded,
                color: AppColors.warning,
                text:
                    'أنت غير متصل. قد يفشل إنشاء المركبة حتى تعود الشبكة للعمل.',
              ),
            _buildSectionHeader(
                'المعلومات الأساسية', Icons.info_outline_rounded),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: _decor(
                      label: 'اسم المركبة',
                      hint: 'مثال: حافلة 12',
                      icon: Icons.directions_bus_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال اسم المركبة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plateController,
                    decoration: _decor(
                      label: 'رقم اللوحة (اختياري)',
                      hint: 'مثال: ABC-1234',
                      icon: Icons.credit_card_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _seatCapacityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decor(
                      label: 'سعة المقاعد',
                      hint: '15',
                      icon: Icons.event_seat_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال سعة المقاعد';
                      }
                      final seats = int.tryParse(v);
                      if (seats == null || seats < 1) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'مركبة نشطة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    value: _active,
                    activeColor: AppColors.dispatcherPrimary,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              'موقع الموقف (اختياري)',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _homeAddressController,
                    decoration: _decor(
                      label: 'العنوان',
                      hint: 'مثال: موقف المدرسة الرئيسي',
                      icon: Icons.place_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _homeLatController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: _decor(
                            label: 'Latitude',
                            hint: '24.7136',
                            icon: Icons.my_location_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _homeLngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: _decor(
                            label: 'Longitude',
                            hint: '46.6753',
                            icon: Icons.my_location_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ملاحظة: اترك الإحداثيات فارغة إذا لا تحتاجها.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('ملاحظات', Icons.notes_rounded),
            const SizedBox(height: 12),
            _buildCard(
              child: TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: _decor(
                  label: 'ملاحظات (اختياري)',
                  hint: 'أي ملاحظات خاصة بالمركبة...',
                  icon: Icons.sticky_note_2_rounded,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dispatcherPrimary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _submitting ? 'جاري الحفظ...' : 'حفظ المركبة',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.dispatcherPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.dispatcherPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  InputDecoration _decor({
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    setState(() => _submitting = true);
    try {
      final seats = int.tryParse(_seatCapacityController.text.trim()) ?? 12;

      double? lat;
      double? lng;
      final latText = _homeLatController.text.trim();
      final lngText = _homeLngController.text.trim();
      if (latText.isNotEmpty) lat = double.tryParse(latText);
      if (lngText.isNotEmpty) lng = double.tryParse(lngText);

      final vehicle = ShuttleVehicle(
        id: 0,
        name: _nameController.text.trim(),
        licensePlate: _plateController.text.trim().isEmpty
            ? null
            : _plateController.text.trim(),
        seatCapacity: seats,
        active: _active,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        homeAddress: _homeAddressController.text.trim().isEmpty
            ? null
            : _homeAddressController.text.trim(),
        homeLatitude: lat,
        homeLongitude: lng,
      );

      final created = await ref
          .read(vehicleActionsProvider.notifier)
          .createVehicle(vehicle);

      if (!mounted) return;

      if (created != null) {
        // Invalidate Dispatcher cache for vehicles list (cache-first providers)
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        if (userId != 0) {
          await cache.delete(DispatcherCacheKeys.vehicles(userId: userId));
        }
        ref.invalidate(dispatcherVehiclesProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء المركبة بنجاح',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(RoutePaths.dispatcherVehicles);
      } else {
        final err = ref.read(vehicleActionsProvider).when(
              data: (_) => 'فشل في إنشاء المركبة',
              loading: () => 'جاري التنفيذ...',
              error: (e, _) => 'خطأ: $e',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
