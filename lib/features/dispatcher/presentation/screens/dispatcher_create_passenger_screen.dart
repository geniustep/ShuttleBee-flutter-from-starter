import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/dispatcher_partner_providers.dart';
import '../widgets/dispatcher_app_bar.dart';

class DispatcherCreatePassengerScreen extends ConsumerStatefulWidget {
  const DispatcherCreatePassengerScreen({super.key});

  @override
  ConsumerState<DispatcherCreatePassengerScreen> createState() =>
      _DispatcherCreatePassengerScreenState();
}

class _DispatcherCreatePassengerScreenState
    extends ConsumerState<DispatcherCreatePassengerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _mobile = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _guardianEmail = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _notes = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  bool _useGpsForPickup = true;
  bool _useGpsForDropoff = true;
  bool _autoNotification = true;
  String _tripDirection = 'both';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _mobile.dispose();
    _guardianPhone.dispose();
    _guardianEmail.dispose();
    _street.dispose();
    _city.dispose();
    _notes.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dispatcherPartnerActionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const DispatcherAppBar(title: 'إضافة راكب جديد'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('المعلومات الأساسية'),
                const SizedBox(height: 10),
                _textField(
                  controller: _name,
                  label: 'اسم الراكب *',
                  icon: Icons.person_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _phone,
                        label: 'هاتف الراكب',
                        icon: Icons.call_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        controller: _mobile,
                        label: 'جوال الراكب',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle('ولي الأمر'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _guardianPhone,
                        label: 'هاتف ولي الأمر',
                        icon: Icons.phone_in_talk_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        controller: _guardianEmail,
                        label: 'Email ولي الأمر',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle('العنوان'),
                const SizedBox(height: 10),
                _textField(
                  controller: _street,
                  label: 'العنوان',
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _city,
                  label: 'المدينة',
                  icon: Icons.location_city_rounded,
                ),
                const SizedBox(height: 18),
                _sectionTitle('إعدادات النقل'),
                const SizedBox(height: 10),
                _buildTripDirection(),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoNotification,
                  onChanged: (v) => setState(() => _autoNotification = v),
                  activeColor: AppColors.dispatcherPrimary,
                  title: const Text('إشعارات تلقائية',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _useGpsForPickup,
                  onChanged: (v) => setState(() => _useGpsForPickup = v),
                  activeColor: AppColors.dispatcherPrimary,
                  title: const Text('استخدم GPS للصعود (افتراضي)',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _useGpsForDropoff,
                  onChanged: (v) => setState(() => _useGpsForDropoff = v),
                  activeColor: AppColors.dispatcherPrimary,
                  title: const Text('استخدم GPS للشركة للنزول (افتراضي)',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _lat,
                        label: 'Latitude',
                        icon: Icons.my_location_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        controller: _lng,
                        label: 'Longitude',
                        icon: Icons.my_location_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle('ملاحظات'),
                const SizedBox(height: 10),
                _textField(
                  controller: _notes,
                  label: 'ملاحظات النقل',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dispatcherPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: state.isLoading ? null : () => _submit(context),
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text(
                      'حفظ',
                      style: TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (state.hasError)
                  Text(
                    state.error.toString(),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.dispatcherPrimary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildTripDirection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اتجاه الرحلات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('صعود ونزول',
                    style: TextStyle(fontFamily: 'Cairo')),
                selected: _tripDirection == 'both',
                onSelected: (_) => setState(() => _tripDirection = 'both'),
              ),
              ChoiceChip(
                label: const Text('صعود فقط',
                    style: TextStyle(fontFamily: 'Cairo')),
                selected: _tripDirection == 'pickup',
                onSelected: (_) => setState(() => _tripDirection = 'pickup'),
              ),
              ChoiceChip(
                label: const Text('نزول فقط',
                    style: TextStyle(fontFamily: 'Cairo')),
                selected: _tripDirection == 'dropoff',
                onSelected: (_) => setState(() => _tripDirection = 'dropoff'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    HapticFeedback.mediumImpact();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    double? asDouble(String v) {
      final t = v.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }

    final id = await ref
        .read(dispatcherPartnerActionsProvider.notifier)
        .createPassenger(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          mobile: _mobile.text.trim(),
          guardianPhone: _guardianPhone.text.trim(),
          guardianEmail: _guardianEmail.text.trim(),
          street: _street.text.trim(),
          city: _city.text.trim(),
          notes: _notes.text.trim(),
          latitude: asDouble(_lat.text),
          longitude: asDouble(_lng.text),
          useGpsForPickup: _useGpsForPickup,
          useGpsForDropoff: _useGpsForDropoff,
          tripDirection: _tripDirection,
          autoNotification: _autoNotification,
        );

    if (!mounted) return;

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إنشاء الراكب بنجاح (ID: $id) وسيظهر ضمن "غير مدرجين"',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
