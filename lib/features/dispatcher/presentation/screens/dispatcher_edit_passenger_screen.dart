import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../domain/entities/dispatcher_passenger_profile.dart';
import '../providers/dispatcher_partner_providers.dart';
import '../widgets/dispatcher_app_bar.dart';

class DispatcherEditPassengerScreen extends ConsumerStatefulWidget {
  final int passengerId;

  const DispatcherEditPassengerScreen({
    super.key,
    required this.passengerId,
  });

  @override
  ConsumerState<DispatcherEditPassengerScreen> createState() =>
      _DispatcherEditPassengerScreenState();
}

class _DispatcherEditPassengerScreenState
    extends ConsumerState<DispatcherEditPassengerScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _mobile;
  // Guardian fields (legacy)
  late final TextEditingController _guardianPhone;
  late final TextEditingController _guardianEmail;
  // NEW: Father/Mother fields
  late final TextEditingController _fatherName;
  late final TextEditingController _fatherPhone;
  late final TextEditingController _motherName;
  late final TextEditingController _motherPhone;
  // Address fields
  late final TextEditingController _street;
  late final TextEditingController _street2;
  late final TextEditingController _city;
  late final TextEditingController _zip;
  late final TextEditingController _notes;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  bool _useGpsForPickup = true;
  bool _useGpsForDropoff = true;
  bool _autoNotification = true;
  bool _active = true;
  bool _hasGuardian = false;
  String _tripDirection = 'both';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _mobile = TextEditingController();
    _guardianPhone = TextEditingController();
    _guardianEmail = TextEditingController();
    _fatherName = TextEditingController();
    _fatherPhone = TextEditingController();
    _motherName = TextEditingController();
    _motherPhone = TextEditingController();
    _street = TextEditingController();
    _street2 = TextEditingController();
    _city = TextEditingController();
    _zip = TextEditingController();
    _notes = TextEditingController();
    _lat = TextEditingController();
    _lng = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _mobile.dispose();
    _guardianPhone.dispose();
    _guardianEmail.dispose();
    _fatherName.dispose();
    _fatherPhone.dispose();
    _motherName.dispose();
    _motherPhone.dispose();
    _street.dispose();
    _street2.dispose();
    _city.dispose();
    _zip.dispose();
    _notes.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _loadPassengerData(DispatcherPassengerProfile? profile) {
    if (profile == null) return;

    _name.text = profile.name;
    _phone.text = profile.phone ?? '';
    _mobile.text = profile.mobile ?? '';
    // Legacy guardian fields
    _guardianPhone.text = profile.guardianPhone ?? '';
    _guardianEmail.text = profile.guardianEmail ?? '';
    // NEW: Father/Mother fields
    _fatherName.text = profile.fatherName ?? '';
    _fatherPhone.text = profile.fatherPhone ?? '';
    _motherName.text = profile.motherName ?? '';
    _motherPhone.text = profile.motherPhone ?? '';
    _hasGuardian = profile.hasGuardian;
    // Address fields
    _street.text = profile.street ?? '';
    _street2.text = profile.street2 ?? '';
    _city.text = profile.city ?? '';
    _zip.text = profile.zip ?? '';
    _notes.text = profile.shuttleNotes ?? '';
    _lat.text = profile.latitude?.toString() ?? '';
    _lng.text = profile.longitude?.toString() ?? '';

    _useGpsForPickup = profile.useGpsForPickup;
    _useGpsForDropoff = profile.useGpsForDropoff;
    _autoNotification = profile.autoNotification;
    _active = profile.active;
    _tripDirection = profile.tripDirection;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync =
        ref.watch(dispatcherPassengerProfileProvider(widget.passengerId));
    final state = ref.watch(dispatcherPartnerActionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const DispatcherAppBar(title: 'تعديل الراكب'),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Text(
                  'الراكب غير موجود',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              );
            }

            if (!_isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadPassengerData(profile);
                setState(() => _isLoading = true);
              });
            }

            return SingleChildScrollView(
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _hasGuardian,
                      onChanged: (v) => setState(() => _hasGuardian = v),
                      activeThumbColor: AppColors.dispatcherPrimary,
                      title: const Text('تفعيل معلومات ولي الأمر',
                          style: TextStyle(fontFamily: 'Cairo')),
                      subtitle: const Text(
                        'يمكنك إضافة معلومات الأب والأم',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                    ),
                    if (_hasGuardian) ...[
                      const SizedBox(height: 12),
                      // Father section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_rounded,
                                    color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'معلومات الأب',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    controller: _fatherName,
                                    label: 'اسم الأب',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    controller: _fatherPhone,
                                    label: 'هاتف الأب',
                                    icon: Icons.phone_rounded,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mother section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.pink.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_rounded,
                                    color: Colors.pink, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'معلومات الأم',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    controller: _motherName,
                                    label: 'اسم الأم',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    controller: _motherPhone,
                                    label: 'هاتف الأم',
                                    icon: Icons.phone_rounded,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Legacy guardian fields (when hasGuardian is false)
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _guardianPhone,
                              label: 'هاتف ولي الأمر (قديم)',
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
                    ],
                    const SizedBox(height: 18),
                    _sectionTitle('العنوان'),
                    const SizedBox(height: 10),
                    _textField(
                      controller: _street,
                      label: 'الشارع',
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _street2,
                      label: 'الشارع 2',
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: _city,
                            label: 'المدينة',
                            icon: Icons.location_city_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            controller: _zip,
                            label: 'الرمز البريدي',
                            icon: Icons.markunread_mailbox_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('إعدادات النقل'),
                    const SizedBox(height: 10),
                    _buildTripDirection(),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      activeColor: AppColors.dispatcherPrimary,
                      title: const Text('نشط',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
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
                      title: const Text('استخدم GPS للصعود',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _useGpsForDropoff,
                      onChanged: (v) => setState(() => _useGpsForDropoff = v),
                      activeColor: AppColors.dispatcherPrimary,
                      title: const Text('استخدم GPS للشركة للنزول',
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
                        onPressed:
                            state.isLoading ? null : () => _submit(context),
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text(
                          'حفظ التعديلات',
                          style: TextStyle(
                              fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (state.hasError)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          state.error.toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 10,
            itemBuilder: (_, __) => const ShimmerCard(height: 60),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                e.toString(),
                style: const TextStyle(fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
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

    final notifier = ref.read(dispatcherPartnerActionsProvider.notifier);

    // Update basic passenger info
    await notifier.updatePassenger(
      passengerId: widget.passengerId,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      mobile: _mobile.text.trim(),
      guardianPhone: _guardianPhone.text.trim(),
      guardianEmail: _guardianEmail.text.trim(),
      street: _street.text.trim(),
      street2: _street2.text.trim(),
      city: _city.text.trim(),
      zip: _zip.text.trim(),
      notes: _notes.text.trim(),
      latitude: asDouble(_lat.text),
      longitude: asDouble(_lng.text),
      useGpsForPickup: _useGpsForPickup,
      useGpsForDropoff: _useGpsForDropoff,
      tripDirection: _tripDirection,
      autoNotification: _autoNotification,
      active: _active,
    );

    // Update guardian info (new fields)
    await notifier.updateGuardianInfo(
      passengerId: widget.passengerId,
      hasGuardian: _hasGuardian,
      fatherName:
          _fatherName.text.trim().isEmpty ? null : _fatherName.text.trim(),
      fatherPhone:
          _fatherPhone.text.trim().isEmpty ? null : _fatherPhone.text.trim(),
      motherName:
          _motherName.text.trim().isEmpty ? null : _motherName.text.trim(),
      motherPhone:
          _motherPhone.text.trim().isEmpty ? null : _motherPhone.text.trim(),
    );

    if (!mounted) return;

    final result = ref.read(dispatcherPartnerActionsProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: ${result.error}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ التعديلات بنجاح',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
    Navigator.of(context).pop();
  }
}
