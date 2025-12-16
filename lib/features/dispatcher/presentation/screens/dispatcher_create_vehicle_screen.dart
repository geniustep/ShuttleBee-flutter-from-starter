import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/domain/entities/fleet_brand.dart';
import '../../../vehicles/domain/entities/fleet_vehicle_model.dart';
import '../../../vehicles/presentation/providers/fleet_providers.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/dispatcher_app_bar.dart';

/// Dispatcher Create Vehicle Screen - شاشة إضافة مركبة - ShuttleBee
/// تعتمد على إنشاء fleet.vehicle.model + fleet.vehicle + shuttle.vehicle
class DispatcherCreateVehicleScreen extends ConsumerStatefulWidget {
  const DispatcherCreateVehicleScreen({super.key});

  @override
  ConsumerState<DispatcherCreateVehicleScreen> createState() =>
      _DispatcherCreateVehicleScreenState();
}

class _DispatcherCreateVehicleScreenState
    extends ConsumerState<DispatcherCreateVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // === Controllers ===
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _seatCapacityController = TextEditingController(text: '15');
  final _noteController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _homeLatController = TextEditingController();
  final _homeLngController = TextEditingController();
  final _newModelNameController = TextEditingController();

  // === State ===
  bool _active = true;
  bool _submitting = false;
  bool _createNewModel = false;

  // === Selected values ===
  FleetVehicleModel? _selectedModel;
  FleetBrand? _selectedBrand;
  String? _selectedFuelType;
  DriverOption? _selectedDriver;

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _seatCapacityController.dispose();
    _noteController.dispose();
    _homeAddressController.dispose();
    _homeLatController.dispose();
    _homeLngController.dispose();
    _newModelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineStateProvider);
    final brandsAsync = ref.watch(allBrandsProvider);
    final modelsAsync = ref.watch(allVehicleModelsProvider);
    final driversAsync = ref.watch(availableDriversProvider);

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

            // ==================== القسم 1: موديل السيارة ====================
            _buildSectionHeader('موديل السيارة', Icons.directions_car_rounded),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اختيار موديل موجود أو إنشاء جديد
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'إنشاء موديل جديد',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    subtitle: Text(
                      _createNewModel
                          ? 'ستقوم بإنشاء موديل سيارة جديد'
                          : 'اختر من الموديلات الموجودة',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _createNewModel,
                    activeColor: AppColors.dispatcherPrimary,
                    onChanged: (v) {
                      setState(() {
                        _createNewModel = v;
                        if (v) {
                          _selectedModel = null;
                        } else {
                          _selectedBrand = null;
                          _newModelNameController.clear();
                        }
                      });
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  if (!_createNewModel) ...[
                    // === اختيار موديل موجود ===
                    modelsAsync.when(
                      data: (models) => _buildModelDropdown(models),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => _buildInfoBanner(
                        icon: Icons.error_outline,
                        color: AppColors.error,
                        text: 'فشل في تحميل الموديلات: $e',
                      ),
                    ),
                  ] else ...[
                    // === إنشاء موديل جديد ===
                    // المُصنّع
                    brandsAsync.when(
                      data: (brands) => _buildBrandDropdown(brands),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => _buildInfoBanner(
                        icon: Icons.error_outline,
                        color: AppColors.error,
                        text: 'فشل في تحميل المُصنّعين: $e',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // اسم الموديل الجديد
                    TextFormField(
                      controller: _newModelNameController,
                      decoration: _decor(
                        label: 'اسم الموديل',
                        hint: 'مثال: Hiace 2024',
                        icon: Icons.badge_rounded,
                      ),
                      validator: _createNewModel
                          ? (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'يرجى إدخال اسم الموديل';
                              }
                              return null;
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // نوع الوقود
                    _buildFuelTypeDropdown(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==================== القسم 2: بيانات السيارة ====================
            _buildSectionHeader('بيانات السيارة (Parc Automobile)',
                Icons.local_shipping_rounded),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  // رقم اللوحة
                  TextFormField(
                    controller: _plateController,
                    decoration: _decor(
                      label: 'رقم اللوحة (Plaque d\'immatriculation)',
                      hint: 'مثال: 12345-أ-12',
                      icon: Icons.confirmation_number_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال رقم اللوحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // عدد المقاعد
                  TextFormField(
                    controller: _seatCapacityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decor(
                      label: 'عدد المقاعد (Nombre de places)',
                      hint: '15',
                      icon: Icons.event_seat_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال عدد المقاعد';
                      }
                      final seats = int.tryParse(v);
                      if (seats == null || seats < 1) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // السائق
                  driversAsync.when(
                    data: (drivers) => _buildDriverDropdown(drivers),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _buildInfoBanner(
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      text: 'تعذر تحميل السائقين',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==================== القسم 3: معلومات Shuttle ====================
            _buildSectionHeader(
                'معلومات مركبة النقل', Icons.airport_shuttle_rounded),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  // اسم المركبة
                  TextFormField(
                    controller: _nameController,
                    decoration: _decor(
                      label: 'اسم المركبة في النظام',
                      hint: 'مثال: حافلة 12 - المسار الشرقي',
                      icon: Icons.label_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال اسم المركبة';
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

            // ==================== القسم 4: موقع الموقف ====================
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==================== القسم 5: الملاحظات ====================
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

            // ==================== زر الحفظ ====================
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dispatcherPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    fontSize: 16,
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

  // ==================== Dropdowns ====================

  Widget _buildModelDropdown(List<FleetVehicleModel> models) {
    return DropdownButtonFormField<FleetVehicleModel>(
      value: _selectedModel,
      decoration: _decor(
        label: 'الموديل (Modèle)',
        hint: 'اختر موديل السيارة',
        icon: Icons.directions_car_filled_rounded,
      ),
      items: models.map((model) {
        return DropdownMenuItem(
          value: model,
          child: Text(
            model.displayName,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        );
      }).toList(),
      onChanged: (model) {
        setState(() {
          _selectedModel = model;
          // تعبئة تلقائية لعدد المقاعد من الموديل
          if (model != null && model.seats > 0) {
            _seatCapacityController.text = model.seats.toString();
          }
          // تعبئة نوع الوقود
          _selectedFuelType = model?.fuelType;
        });
      },
      validator: !_createNewModel
          ? (v) {
              if (v == null) return 'يرجى اختيار موديل';
              return null;
            }
          : null,
    );
  }

  Widget _buildBrandDropdown(List<FleetBrand> brands) {
    return DropdownButtonFormField<FleetBrand>(
      value: _selectedBrand,
      decoration: _decor(
        label: 'المُصنّع (Fabricant)',
        hint: 'اختر المُصنّع',
        icon: Icons.factory_rounded,
      ),
      items: brands.map((brand) {
        return DropdownMenuItem(
          value: brand,
          child: Text(
            brand.name,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        );
      }).toList(),
      onChanged: (brand) {
        setState(() => _selectedBrand = brand);
      },
      validator: _createNewModel
          ? (v) {
              if (v == null) return 'يرجى اختيار المُصنّع';
              return null;
            }
          : null,
    );
  }

  Widget _buildFuelTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFuelType,
      decoration: _decor(
        label: 'نوع الوقود (Type de carburant)',
        hint: 'اختر نوع الوقود',
        icon: Icons.local_gas_station_rounded,
      ),
      items: FuelTypes.all.map((fuel) {
        return DropdownMenuItem(
          value: fuel.value,
          child: Text(
            '${fuel.label} (${fuel.labelFr})',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        );
      }).toList(),
      onChanged: (fuel) {
        setState(() => _selectedFuelType = fuel);
      },
    );
  }

  Widget _buildDriverDropdown(List<DriverOption> drivers) {
    return DropdownButtonFormField<DriverOption>(
      value: _selectedDriver,
      decoration: _decor(
        label: 'السائق الافتراضي (اختياري)',
        hint: 'اختر السائق',
        icon: Icons.person_rounded,
      ),
      items: [
        const DropdownMenuItem<DriverOption>(
          value: null,
          child: Text(
            'بدون سائق',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...drivers.map((driver) {
          return DropdownMenuItem(
            value: driver,
            child: Text(
              driver.name,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          );
        }),
      ],
      onChanged: (driver) {
        setState(() => _selectedDriver = driver);
      },
    );
  }

  // ==================== UI Helpers ====================

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
        Icon(icon, size: 20, color: AppColors.dispatcherPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
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

  // ==================== Submit ====================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    setState(() => _submitting = true);
    try {
      final seats = int.tryParse(_seatCapacityController.text.trim()) ?? 15;

      double? lat;
      double? lng;
      final latText = _homeLatController.text.trim();
      final lngText = _homeLngController.text.trim();
      if (latText.isNotEmpty) lat = double.tryParse(latText);
      if (lngText.isNotEmpty) lng = double.tryParse(lngText);

      // تجهيز بيانات الإنشاء
      final data = CreateVehicleData(
        // موديل موجود أو جديد
        existingModelId: _createNewModel ? null : _selectedModel?.id,
        newModelName:
            _createNewModel ? _newModelNameController.text.trim() : null,
        brandId: _createNewModel ? _selectedBrand?.id : null,
        vehicleType: 'car', // دائماً car حسب قيود Odoo
        fuelType: _selectedFuelType,
        // fleet.vehicle
        licensePlate: _plateController.text.trim(),
        driverId: _selectedDriver?.id,
        seats: seats,
        // shuttle.vehicle
        name: _nameController.text.trim(),
        homeAddress: _homeAddressController.text.trim().isEmpty
            ? null
            : _homeAddressController.text.trim(),
        homeLatitude: lat,
        homeLongitude: lng,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        active: _active,
      );

      final created = await ref
          .read(vehicleActionsProvider.notifier)
          .createFullVehicle(data);

      if (!mounted) return;

      if (created != null) {
        // Invalidate caches
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        if (userId != 0) {
          await cache.delete(DispatcherCacheKeys.vehicles(userId: userId));
        }
        ref.invalidate(dispatcherVehiclesProvider);
        ref.invalidate(allVehicleModelsProvider);
        ref.invalidate(allFleetVehiclesProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم إنشاء المركبة "${created.name}" بنجاح',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(err, style: const TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
