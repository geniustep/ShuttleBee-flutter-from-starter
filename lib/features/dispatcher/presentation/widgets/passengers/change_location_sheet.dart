import 'package:bridgecore_flutter_starter/core/theme/app_colors.dart';
import 'package:bridgecore_flutter_starter/features/dispatcher/domain/entities/dispatcher_passenger_profile.dart';
import 'package:bridgecore_flutter_starter/features/dispatcher/presentation/providers/dispatcher_partner_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';


/// Enum for location input method
enum LocationInputMethod {
  coordinates, // إدخال الإحداثيات يدوياً
  currentLocation, // استخدام الموقع الحالي
  map, // اختيار من الخريطة
}

/// Result from change location sheet
class ChangeLocationResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? contactName;
  final String? contactPhone;
  final bool clearLocation;

  const ChangeLocationResult({
    this.latitude = 0,
    this.longitude = 0,
    this.address,
    this.contactName,
    this.contactPhone,
    this.clearLocation = false,
  });
}

/// Bottom sheet for changing passenger temporary location
class ChangeLocationSheet extends ConsumerStatefulWidget {
  final int passengerId;
  final String passengerName;
  final DispatcherPassengerProfile? profile;

  const ChangeLocationSheet({
    super.key,
    required this.passengerId,
    required this.passengerName,
    this.profile,
  });

  /// Show the change location sheet
  static Future<ChangeLocationResult?> show(
    BuildContext context, {
    required int passengerId,
    required String passengerName,
    DispatcherPassengerProfile? profile,
  }) {
    return showModalBottomSheet<ChangeLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeLocationSheet(
        passengerId: passengerId,
        passengerName: passengerName,
        profile: profile,
      ),
    );
  }

  @override
  ConsumerState<ChangeLocationSheet> createState() =>
      _ChangeLocationSheetState();
}

class _ChangeLocationSheetState extends ConsumerState<ChangeLocationSheet> {
  LocationInputMethod _selectedMethod = LocationInputMethod.coordinates;

  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _initFromProfile();
  }

  void _initFromProfile() {
    final p = widget.profile;
    if (p != null) {
      if (p.temporaryLatitude != null) {
        _latController.text = p.temporaryLatitude!.toStringAsFixed(6);
      }
      if (p.temporaryLongitude != null) {
        _lngController.text = p.temporaryLongitude!.toStringAsFixed(6);
      }
      _addressController.text = p.temporaryAddress ?? '';
      _contactNameController.text = p.temporaryContactName ?? '';
      _contactPhoneController.text = p.temporaryContactPhone ?? '';
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingTemp = widget.profile?.hasTemporaryAddress ?? false;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تغيير العنوان المؤقت',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.passengerName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.border.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms),

              // Existing temp address warning
              if (hasExistingTemp) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'يوجد عنوان مؤقت مُفعّل حالياً',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearTemporaryLocation,
                          child: const Text(
                            'إزالة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms, delay: 50.ms),
                const SizedBox(height: 12),
              ],

              const Divider(height: 20),

              // Method selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'طريقة تحديد الموقع',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MethodChip(
                            icon: Icons.edit_location_alt_rounded,
                            label: 'إحداثيات',
                            isSelected: _selectedMethod ==
                                LocationInputMethod.coordinates,
                            onTap: () => setState(() => _selectedMethod =
                                LocationInputMethod.coordinates),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MethodChip(
                            icon: Icons.my_location_rounded,
                            label: 'الموقع الحالي',
                            isSelected: _selectedMethod ==
                                LocationInputMethod.currentLocation,
                            onTap: () {
                              setState(() => _selectedMethod =
                                  LocationInputMethod.currentLocation);
                              _getCurrentLocation();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MethodChip(
                            icon: Icons.map_rounded,
                            label: 'الخريطة',
                            isSelected:
                                _selectedMethod == LocationInputMethod.map,
                            onTap: () {
                              setState(() =>
                                  _selectedMethod = LocationInputMethod.map);
                              _showMapPicker();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms, delay: 100.ms),

              const SizedBox(height: 20),

              // Loading indicator for getting location
              if (_isGettingLocation)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text(
                        'جاري تحديد الموقع...',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Coordinates input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الإحداثيات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              style: const TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'خط العرض (Latitude)',
                                hintText: '24.7136',
                                prefixIcon: const Icon(Icons.north_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              style: const TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'خط الطول (Longitude)',
                                hintText: '46.6753',
                                prefixIcon: const Icon(Icons.east_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'وصف العنوان (اختياري)',
                          hintText: 'مثال: بيت الجد، شارع الملك فهد...',
                          prefixIcon: const Icon(Icons.home_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms, delay: 150.ms),

                const SizedBox(height: 16),

                // Contact person section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'شخص الاتصال في هذا العنوان (اختياري)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactNameController,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'الاسم',
                                hintText: 'مثال: الجد، العم...',
                                prefixIcon: const Icon(Icons.person_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _contactPhoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'رقم الهاتف',
                                hintText: '05xxxxxxxx',
                                prefixIcon: const Icon(Icons.phone_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms, delay: 200.ms),
              ],

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dispatcherPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'حفظ العنوان المؤقت',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms, delay: 250.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'خدمة تحديد الموقع غير مفعلة. يرجى تفعيلها من الإعدادات.';
          _isGettingLocation = false;
        });
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'تم رفض إذن الوصول للموقع.';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من إعدادات التطبيق.';
          _isGettingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحديد الموقع: $e';
        _isGettingLocation = false;
      });
    }
  }

  void _showMapPicker() {
    // TODO: Implement map picker dialog
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'قريباً: اختيار الموقع من الخريطة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
    setState(() => _selectedMethod = LocationInputMethod.coordinates);
  }

  Future<void> _saveLocation() async {
    final latText = _latController.text.trim();
    final lngText = _lngController.text.trim();

    if (latText.isEmpty || lngText.isEmpty) {
      setState(
          () => _errorMessage = 'يرجى إدخال الإحداثيات (خط العرض وخط الطول)');
      return;
    }

    final lat = double.tryParse(latText);
    final lng = double.tryParse(lngText);

    if (lat == null || lng == null) {
      setState(() => _errorMessage = 'الإحداثيات غير صالحة');
      return;
    }

    if (lat < -90 || lat > 90) {
      setState(() => _errorMessage = 'خط العرض يجب أن يكون بين -90 و 90');
      return;
    }

    if (lng < -180 || lng > 180) {
      setState(() => _errorMessage = 'خط الطول يجب أن يكون بين -180 و 180');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(dispatcherPartnerActionsProvider.notifier)
          .updateTemporaryLocation(
            passengerId: widget.passengerId,
            temporaryLatitude: lat,
            temporaryLongitude: lng,
            temporaryAddress: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            temporaryContactName: _contactNameController.text.trim().isEmpty
                ? null
                : _contactNameController.text.trim(),
            temporaryContactPhone: _contactPhoneController.text.trim().isEmpty
                ? null
                : _contactPhoneController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(
          context,
          ChangeLocationResult(
            latitude: lat,
            longitude: lng,
            address: _addressController.text.trim(),
            contactName: _contactNameController.text.trim(),
            contactPhone: _contactPhoneController.text.trim(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في حفظ الموقع: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTemporaryLocation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إزالة العنوان المؤقت',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد إزالة العنوان المؤقت والعودة للعنوان الأصلي؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'إزالة',
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await ref
            .read(dispatcherPartnerActionsProvider.notifier)
            .clearTemporaryLocation(
              widget.passengerId,
            );

        if (mounted) {
          Navigator.pop(
            context,
            const ChangeLocationResult(clearLocation: true),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'فشل في إزالة الموقع: $e';
          _isLoading = false;
        });
      }
    }
  }
}

class _MethodChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.dispatcherPrimary.withValues(alpha: 0.1)
                : AppColors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.dispatcherPrimary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.dispatcherPrimary
                    : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.dispatcherPrimary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
