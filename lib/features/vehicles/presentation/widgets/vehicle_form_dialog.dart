import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/entities/fleet_vehicle_model.dart';
import '../../domain/entities/shuttle_vehicle.dart';
import '../../domain/entities/fleet_vehicle_model.dart' show VehicleTypes, FuelTypes;
import '../providers/fleet_providers.dart';
import '../providers/vehicle_providers.dart';
import '../../data/datasources/vehicle_remote_data_source.dart' show CreateVehicleData;

/// نموذج إضافة/تعديل المركبة - ShuttleBee
class VehicleFormDialog extends ConsumerStatefulWidget {
  final ShuttleVehicle? vehicle; // null = إضافة جديدة، غير null = تعديل

  const VehicleFormDialog({super.key, this.vehicle});

  @override
  ConsumerState<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends ConsumerState<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _noteController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _seatsController = TextEditingController();
  final _newModelNameController = TextEditingController();

  // Form state
  bool _isActive = true;
  bool _useExistingModel = true;
  int? _selectedBrandId;
  int? _selectedModelId;
  int? _selectedDriverId;
  String? _selectedVehicleType;
  String? _selectedFuelType;
  double? _homeLatitude;
  double? _homeLongitude;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.vehicle != null) {
      // وضع التعديل
      final v = widget.vehicle!;
      _nameController.text = v.name;
      _licensePlateController.text = v.licensePlate ?? '';
      _noteController.text = v.note ?? '';
      _homeAddressController.text = v.homeAddress ?? '';
      _seatsController.text = v.seatCapacity.toString();
      _isActive = v.active;
      _selectedDriverId = v.driverId;
      _homeLatitude = v.homeLatitude;
      _homeLongitude = v.homeLongitude;
      // TODO: جلب brandId و modelId من fleetVehicleId
    } else {
      // وضع الإضافة
      _seatsController.text = '12';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licensePlateController.dispose();
    _noteController.dispose();
    _homeAddressController.dispose();
    _seatsController.dispose();
    _newModelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;
    final isMobile = context.isMobile;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isEdit),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // اسم المركبة
                      _buildTextField(
                        controller: _nameController,
                        label: 'اسم المركبة',
                        icon: Icons.directions_bus_rounded,
                        validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      // رقم اللوحة
                      _buildTextField(
                        controller: _licensePlateController,
                        label: 'رقم اللوحة',
                        icon: Icons.confirmation_number_rounded,
                        validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      // اختيار الموديل
                      _buildModelSection(),
                      const SizedBox(height: 16),
                      // السعة
                      _buildTextField(
                        controller: _seatsController,
                        label: 'سعة المقاعد',
                        icon: Icons.event_seat_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'مطلوب';
                          final seats = int.tryParse(v!);
                          if (seats == null || seats < 1) {
                            return 'يجب أن يكون رقم صحيح أكبر من 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // السائق
                      _buildDriverSelector(),
                      const SizedBox(height: 16),
                      // موقع الموقف
                      _buildParkingLocationSection(),
                      const SizedBox(height: 16),
                      // الملاحظات
                      _buildTextField(
                        controller: _noteController,
                        label: 'ملاحظات (اختياري)',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // حالة النشاط
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        title: const Text(
                          'نشط',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            _buildActions(isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'تعديل المركبة' : 'إضافة مركبة جديدة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEdit
                      ? 'قم بتعديل معلومات المركبة'
                      : 'أدخل معلومات المركبة الجديدة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: const TextStyle(fontFamily: 'Cairo'),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
  }

  Widget _buildModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle: موديل موجود أو جديد
        Card(
          child: SwitchListTile(
            value: _useExistingModel,
            onChanged: (v) => setState(() {
              _useExistingModel = v;
              if (v) {
                _selectedBrandId = null;
                _selectedModelId = null;
              } else {
                _newModelNameController.clear();
              }
            }),
            title: const Text(
              'استخدام موديل موجود',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        if (_useExistingModel) ...[
          // اختيار الموديل الموجود
          _buildModelSelector(),
        ] else ...[
          // إنشاء موديل جديد
          _buildNewModelSection(),
        ],
      ],
    );
  }

  Widget _buildModelSelector() {
    final modelsAsync = ref.watch(
      _selectedBrandId != null
          ? vehicleModelsByBrandProvider(_selectedBrandId)
          : allVehicleModelsProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // اختيار المُصنّع
        _buildBrandSelector(),
        const SizedBox(height: 16),
        // اختيار الموديل
        modelsAsync.when(
          data: (models) {
            if (models.isEmpty) {
              return const Text(
                'لا توجد موديلات متاحة',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                textAlign: TextAlign.center,
              );
            }
            return DropdownButtonFormField<int>(
              value: _selectedModelId,
              decoration: InputDecoration(
                labelText: 'الموديل',
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                prefixIcon: const Icon(Icons.directions_car_rounded, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: models.map((model) {
                return DropdownMenuItem<int>(
                  value: model.id,
                  child: Text(
                    model.displayName,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedModelId = v),
              validator: (v) => v == null ? 'مطلوب' : null,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text(
            'خطأ في تحميل الموديلات',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandSelector() {
    final brandsAsync = ref.watch(allBrandsProvider);

    return brandsAsync.when(
      data: (brands) {
        if (brands.isEmpty) {
          return const Text(
            'لا توجد مُصنّعين متاحين',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            textAlign: TextAlign.center,
          );
        }
        return DropdownButtonFormField<int>(
          value: _selectedBrandId,
          decoration: InputDecoration(
            labelText: 'المُصنّع (اختياري)',
            labelStyle: const TextStyle(fontFamily: 'Cairo'),
            prefixIcon: const Icon(Icons.branding_watermark_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('الكل', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ...brands.map((brand) {
              return DropdownMenuItem<int>(
                value: brand.id,
                child: Text(
                  brand.name,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              );
            }),
          ],
          onChanged: (v) => setState(() {
            _selectedBrandId = v;
            _selectedModelId = null; // Reset model when brand changes
          }),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text(
        'خطأ في تحميل المُصنّعين',
        style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
      ),
    );
  }

  Widget _buildNewModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _newModelNameController,
          label: 'اسم الموديل الجديد',
          icon: Icons.add_circle_outline_rounded,
          validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        _buildBrandSelector(),
        const SizedBox(height: 16),
        // نوع المركبة
        DropdownButtonFormField<String>(
          value: _selectedVehicleType,
          decoration: InputDecoration(
            labelText: 'نوع المركبة',
            labelStyle: const TextStyle(fontFamily: 'Cairo'),
            prefixIcon: const Icon(Icons.category_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: VehicleTypes.all.map((type) {
            return DropdownMenuItem<String>(
              value: type.value,
              child: Text(
                type.label,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedVehicleType = v),
        ),
        const SizedBox(height: 16),
        // نوع الوقود
        DropdownButtonFormField<String>(
          value: _selectedFuelType,
          decoration: InputDecoration(
            labelText: 'نوع الوقود',
            labelStyle: const TextStyle(fontFamily: 'Cairo'),
            prefixIcon: const Icon(Icons.local_gas_station_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: FuelTypes.all.map((fuel) {
            return DropdownMenuItem<String>(
              value: fuel.value,
              child: Text(
                fuel.label,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedFuelType = v),
        ),
      ],
    );
  }

  Widget _buildDriverSelector() {
    final driversAsync = ref.watch(availableDriversProvider);

    return driversAsync.when(
      data: (drivers) {
        return DropdownButtonFormField<int>(
          value: _selectedDriverId,
          decoration: InputDecoration(
            labelText: 'السائق (اختياري)',
            labelStyle: const TextStyle(fontFamily: 'Cairo'),
            prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('لا يوجد', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ...drivers.map((driver) {
              return DropdownMenuItem<int>(
                value: driver.id,
                child: Text(
                  driver.name,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              );
            }),
          ],
          onChanged: (v) => setState(() => _selectedDriverId = v),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text(
        'خطأ في تحميل السائقين',
        style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
      ),
    );
  }

  Widget _buildParkingLocationSection() {
    final latController = TextEditingController(
      text: _homeLatitude?.toStringAsFixed(6) ?? '',
    );
    final lngController = TextEditingController(
      text: _homeLongitude?.toStringAsFixed(6) ?? '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.local_parking_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'موقع الموقف',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _homeAddressController,
              label: 'العنوان',
              icon: Icons.location_on_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: latController,
                    decoration: InputDecoration(
                      labelText: 'خط العرض',
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      prefixIcon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return null;
                      final lat = double.tryParse(v!);
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'قيمة غير صحيحة';
                      }
                      return null;
                    },
                    onChanged: (v) {
                      _homeLatitude = v.isEmpty ? null : double.tryParse(v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: lngController,
                    decoration: InputDecoration(
                      labelText: 'خط الطول',
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      prefixIcon: const Icon(Icons.explore_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return null;
                      final lng = double.tryParse(v ?? '');
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'قيمة غير صحيحة';
                      }
                      return null;
                    },
                    onChanged: (v) {
                      _homeLongitude = v.isEmpty ? null : double.tryParse(v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // TODO: فتح خريطة لاختيار الموقع
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم إضافة اختيار الموقع من الخريطة قريباً'),
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded),
              label: const Text(
                'اختيار من الخريطة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit ? 'حفظ التعديلات' : 'إضافة المركبة',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      HapticFeedback.mediumImpact();

      if (widget.vehicle != null) {
        // التعديل
        await _handleUpdate();
      } else {
        // الإضافة
        await _handleCreate();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.vehicle != null
                  ? 'تم تحديث المركبة بنجاح'
                  : 'تم إضافة المركبة بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleCreate() async {
    final seats = int.parse(_seatsController.text);

    if (_useExistingModel) {
      // استخدام موديل موجود
      if (_selectedModelId == null) {
        throw Exception('يجب اختيار موديل');
      }

      final data = CreateVehicleData(
        existingModelId: _selectedModelId,
        licensePlate: _licensePlateController.text.trim(),
        driverId: _selectedDriverId,
        seats: seats,
        name: _nameController.text.trim(),
        homeAddress: _homeAddressController.text.trim().isEmpty
            ? null
            : _homeAddressController.text.trim(),
        homeLatitude: _homeLatitude,
        homeLongitude: _homeLongitude,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        active: _isActive,
      );

      await ref.read(vehicleActionsProvider.notifier).createFullVehicle(data);
    } else {
      // إنشاء موديل جديد
      if (_newModelNameController.text.trim().isEmpty) {
        throw Exception('يجب إدخال اسم الموديل');
      }
      if (_selectedBrandId == null) {
        throw Exception('يجب اختيار المُصنّع');
      }

      final data = CreateVehicleData(
        newModelName: _newModelNameController.text.trim(),
        brandId: _selectedBrandId,
        vehicleType: _selectedVehicleType,
        fuelType: _selectedFuelType,
        licensePlate: _licensePlateController.text.trim(),
        driverId: _selectedDriverId,
        seats: seats,
        name: _nameController.text.trim(),
        homeAddress: _homeAddressController.text.trim().isEmpty
            ? null
            : _homeAddressController.text.trim(),
        homeLatitude: _homeLatitude,
        homeLongitude: _homeLongitude,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        active: _isActive,
      );

      await ref.read(vehicleActionsProvider.notifier).createFullVehicle(data);
    }
  }

  Future<void> _handleUpdate() async {
    final seats = int.parse(_seatsController.text);

    final updatedVehicle = widget.vehicle!.copyWith(
      name: _nameController.text.trim(),
      licensePlate: _licensePlateController.text.trim(),
      seatCapacity: seats,
      driverId: _selectedDriverId,
      active: _isActive,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      homeAddress: _homeAddressController.text.trim().isEmpty
          ? null
          : _homeAddressController.text.trim(),
      homeLatitude: _homeLatitude,
      homeLongitude: _homeLongitude,
    );

    await ref.read(vehicleActionsProvider.notifier).updateVehicle(updatedVehicle);
  }
}

