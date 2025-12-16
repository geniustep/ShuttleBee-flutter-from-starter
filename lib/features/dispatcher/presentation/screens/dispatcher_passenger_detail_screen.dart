import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../domain/entities/dispatcher_passenger_profile.dart';
import '../../domain/entities/passenger_group_line.dart';
import '../providers/dispatcher_passenger_providers.dart';
import '../providers/dispatcher_partner_providers.dart';
import '../widgets/change_location_sheet.dart';
import '../widgets/dispatcher_app_bar.dart';
import '../widgets/passenger_quick_actions_sheet.dart';
import '../widgets/select_trip_for_absence_sheet.dart';

class DispatcherPassengerDetailScreen extends ConsumerWidget {
  final int passengerId;

  const DispatcherPassengerDetailScreen({
    super.key,
    required this.passengerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync =
        ref.watch(dispatcherPassengerProfileProvider(passengerId));
    final linesAsync = ref.watch(dispatcherPassengerLinesProvider(passengerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: DispatcherAppBar(
        title: 'تفاصيل الراكب',
        actions: [
          // Quick actions button
          IconButton(
            tooltip: 'إجراءات سريعة',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showQuickActions(context, ref);
            },
            icon: const Icon(Icons.flash_on_rounded, color: AppColors.warning),
          ),
          IconButton(
            tooltip: 'تعديل',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(
                '${RoutePaths.dispatcherPassengers}/p/$passengerId/edit',
              );
            },
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: () => _showDeleteDialog(context, ref),
            icon: const Icon(Icons.delete_rounded, color: AppColors.error),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
          ref.invalidate(dispatcherPassengerLinesProvider(passengerId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              data: (p) {
                if (p == null) {
                  return const EmptyState(
                    icon: Icons.person_off_rounded,
                    title: 'الراكب غير موجود',
                    message: 'قد يكون تم حذفه أو لا تملك صلاحية الوصول.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(
                      name: p.name,
                      active: p.active,
                      contact: p.shortContact,
                      address: p.addressLine,
                      phone: p.phone,
                      mobile: p.mobile,
                      hasTemporaryAddress: p.hasTemporaryAddress,
                    ),
                    const SizedBox(height: 16),
                    _ActionButtons(
                      passengerId: passengerId,
                      profile: p,
                      onEdit: () => context.push(
                        '${RoutePaths.dispatcherPassengers}/p/$passengerId/edit',
                      ),
                      onDelete: () => _showDeleteDialog(context, ref),
                      onQuickActions: () => _showQuickActions(context, ref),
                      onChangeLocation: () =>
                          _showChangeLocation(context, ref, p),
                    ),
                    const SizedBox(height: 16),
                    // Guardian Information Card (NEW)
                    if (p.hasGuardian) ...[
                      _GuardianInfoCard(profile: p),
                      const SizedBox(height: 12),
                    ],
                    // Temporary Address Card (NEW)
                    if (p.hasTemporaryAddress) ...[
                      _TemporaryAddressCard(
                        profile: p,
                        onClear: () => _clearTemporaryLocation(context, ref),
                        onEdit: () => _showChangeLocation(context, ref, p),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _InfoCard(
                      title: 'معلومات الاتصال',
                      icon: Icons.contact_phone_rounded,
                      children: [
                        if (p.phone != null && p.phone!.isNotEmpty)
                          _InfoRow(
                            label: 'هاتف',
                            value: p.phone!,
                            icon: Icons.call_rounded,
                          ),
                        if (p.mobile != null && p.mobile!.isNotEmpty)
                          _InfoRow(
                            label: 'جوال',
                            value: p.mobile!,
                            icon: Icons.phone_android_rounded,
                          ),
                        // Legacy guardian info (for backward compatibility)
                        if (!p.hasGuardian &&
                            p.guardianPhone != null &&
                            p.guardianPhone!.isNotEmpty)
                          _InfoRow(
                            label: 'هاتف ولي الأمر',
                            value: p.guardianPhone!,
                            icon: Icons.phone_in_talk_rounded,
                          ),
                        if (!p.hasGuardian &&
                            p.guardianEmail != null &&
                            p.guardianEmail!.isNotEmpty)
                          _InfoRow(
                            label: 'Email ولي الأمر',
                            value: p.guardianEmail!,
                            icon: Icons.email_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'إعدادات النقل',
                      icon: Icons.settings_rounded,
                      children: [
                        _InfoRow(
                          label: 'اتجاه الرحلات',
                          value: _directionLabel(p.tripDirection),
                          icon: Icons.directions_rounded,
                        ),
                        _InfoRow(
                          label: 'إشعارات تلقائية',
                          value: p.autoNotification ? 'نعم' : 'لا',
                          icon: Icons.notifications_rounded,
                        ),
                        _InfoRow(
                          label: 'GPS للصعود',
                          value: p.useGpsForPickup ? 'نعم' : 'لا',
                          icon: Icons.gps_fixed_rounded,
                        ),
                        _InfoRow(
                          label: 'GPS للشركة للنزول',
                          value: p.useGpsForDropoff ? 'نعم' : 'لا',
                          icon: Icons.gps_fixed_rounded,
                        ),
                        if (p.latitude != null && p.longitude != null)
                          _InfoRow(
                            label: 'الموقع',
                            value: '${p.latitude}, ${p.longitude}',
                            icon: Icons.location_on_rounded,
                          ),
                        if (p.defaultPickupStopName != null)
                          _InfoRow(
                            label: 'محطة صعود افتراضية',
                            value: p.defaultPickupStopName!,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        if (p.defaultDropoffStopName != null)
                          _InfoRow(
                            label: 'محطة نزول افتراضية',
                            value: p.defaultDropoffStopName!,
                            icon: Icons.arrow_downward_rounded,
                          ),
                      ],
                    ),
                    if (p.shuttleNotes != null &&
                        p.shuttleNotes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'ملاحظات',
                        icon: Icons.notes_rounded,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              p.shuttleNotes!,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
              loading: () => const ShimmerCard(height: 200),
              error: (e, _) => _ErrorBox(error: e.toString()),
            ),
            const SizedBox(height: 12),
            linesAsync.when(
              data: (lines) => _LinesSection(
                passengerId: passengerId,
                lines: lines,
              ),
              loading: () => const ShimmerCard(height: 180),
              error: (e, _) => _ErrorBox(error: e.toString()),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف الراكب',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا الراكب؟ لا يمكن التراجع عن هذه العملية.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(dispatcherPartnerActionsProvider.notifier)
                  .deletePassenger(passengerId);
              if (ctx.mounted) {
                final result = ref.read(dispatcherPartnerActionsProvider);
                if (result.hasError) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'حدث خطأ: ${result.error}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم حذف الراكب بنجاح',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  );
                  if (ctx.mounted) {
                    context.go(RoutePaths.dispatcherPassengers);
                  }
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'حذف',
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static String _directionLabel(String v) {
    switch (v) {
      case 'pickup':
        return 'صعود فقط';
      case 'dropoff':
        return 'نزول فقط';
      default:
        return 'صعود ونزول';
    }
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    final profileAsync =
        ref.read(dispatcherPassengerProfileProvider(passengerId));
    final profile = profileAsync.asData?.value;

    PassengerQuickActionsSheet.show(
      context,
      passengerId: passengerId,
      passengerName: profile?.name ?? 'الراكب',
      onEditProfile: () {
        context.push(
          '${RoutePaths.dispatcherPassengers}/p/$passengerId/edit',
        );
      },
      onChangeLocation: () {
        if (profile != null) {
          _showChangeLocation(context, ref, profile);
        }
      },
      onMarkAbsent: () async {
        final passengerName = profile?.name ?? 'الراكب';
        final result = await SelectTripForAbsenceSheet.show(
          context,
          passengerId: passengerId,
          passengerName: passengerName,
        );

        if (result != null && context.mounted) {
          final repository = ref.read(tripRepositoryProvider);
          if (repository == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'لا يمكن الاتصال بالخادم',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }

          final apiResult =
              await repository.markPassengerAbsent(result.tripLineId);
          final success = apiResult.isRight();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'تم تسجيل غياب $passengerName في ${result.tripName}'
                      : 'فشل تسجيل الغياب',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ),
            );
          }
        }
      },
    );
  }

  void _showChangeLocation(
      BuildContext context, WidgetRef ref, DispatcherPassengerProfile profile) {
    ChangeLocationSheet.show(
      context,
      passengerId: passengerId,
      passengerName: profile.name,
      profile: profile,
    ).then((result) {
      if (result != null) {
        ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.clearLocation
                  ? 'تم إزالة العنوان المؤقت'
                  : 'تم حفظ العنوان المؤقت',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    });
  }

  Future<void> _clearTemporaryLocation(
      BuildContext context, WidgetRef ref) async {
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
      try {
        await ref
            .read(dispatcherPartnerActionsProvider.notifier)
            .clearTemporaryLocation(passengerId);
        ref.invalidate(dispatcherPassengerProfileProvider(passengerId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم إزالة العنوان المؤقت',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'فشل في إزالة العنوان: $e',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final bool active;
  final String contact;
  final String address;
  final String? phone;
  final String? mobile;
  final bool hasTemporaryAddress;

  const _HeaderCard({
    required this.name,
    required this.active,
    required this.contact,
    required this.address,
    this.phone,
    this.mobile,
    this.hasTemporaryAddress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.dispatcherGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasTemporaryAddress)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'مؤقت',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    active ? Icons.check_circle : Icons.cancel,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    active ? 'نشط' : 'غير نشط',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (contact.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              contact,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final int passengerId;
  final DispatcherPassengerProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onQuickActions;
  final VoidCallback onChangeLocation;

  const _ActionButtons({
    required this.passengerId,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    required this.onQuickActions,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick action buttons row
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.flash_on_rounded,
                label: 'إجراءات سريعة',
                color: AppColors.warning,
                onTap: onQuickActions,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.location_on_rounded,
                label:
                    profile.hasTemporaryAddress ? 'عنوان مؤقت' : 'تغيير الموقع',
                color: profile.hasTemporaryAddress
                    ? AppColors.warning
                    : AppColors.primary,
                badge: profile.hasTemporaryAddress ? '!' : null,
                onTap: onChangeLocation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Main actions row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dispatcherPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onEdit();
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text(
                  'تعديل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onDelete();
                },
                icon: const Icon(Icons.delete_rounded),
                label: const Text(
                  'حذف',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 20),
                  if (badge != null)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guardian Information Card (Father/Mother)
class _GuardianInfoCard extends StatelessWidget {
  final DispatcherPassengerProfile profile;

  const _GuardianInfoCard({required this.profile});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'معلومات ولي الأمر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Father info
            if (profile.fatherName?.isNotEmpty == true ||
                profile.fatherPhone?.isNotEmpty == true)
              _GuardianRow(
                title: 'الأب',
                name: profile.fatherName,
                phone: profile.fatherPhone,
                icon: Icons.person_rounded,
                color: Colors.blue,
                onCall: profile.fatherPhone?.isNotEmpty == true
                    ? () => _makeCall(profile.fatherPhone!)
                    : null,
                onWhatsApp: profile.fatherPhone?.isNotEmpty == true
                    ? () => _openWhatsApp(profile.fatherPhone!)
                    : null,
              ),
            // Mother info
            if (profile.motherName?.isNotEmpty == true ||
                profile.motherPhone?.isNotEmpty == true)
              _GuardianRow(
                title: 'الأم',
                name: profile.motherName,
                phone: profile.motherPhone,
                icon: Icons.person_rounded,
                color: Colors.pink,
                onCall: profile.motherPhone?.isNotEmpty == true
                    ? () => _makeCall(profile.motherPhone!)
                    : null,
                onWhatsApp: profile.motherPhone?.isNotEmpty == true
                    ? () => _openWhatsApp(profile.motherPhone!)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _GuardianRow extends StatelessWidget {
  final String title;
  final String? name;
  final String? phone;
  final IconData icon;
  final Color color;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const _GuardianRow({
    required this.title,
    this.name,
    this.phone,
    required this.icon,
    required this.color,
    this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (name?.isNotEmpty == true)
                  Text(
                    name!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (phone?.isNotEmpty == true)
                  Text(
                    phone!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onCall != null)
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onCall!();
              },
              icon: Icon(Icons.call_rounded, color: color),
              tooltip: 'اتصال',
            ),
          if (onWhatsApp != null)
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onWhatsApp!();
              },
              icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              tooltip: 'واتساب',
            ),
        ],
      ),
    );
  }
}

/// Temporary Address Card
class _TemporaryAddressCard extends StatelessWidget {
  final DispatcherPassengerProfile profile;
  final VoidCallback onClear;
  final VoidCallback onEdit;

  const _TemporaryAddressCard({
    required this.profile,
    required this.onClear,
    required this.onEdit,
  });

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.warning.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'العنوان المؤقت',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                // Edit button
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  tooltip: 'تعديل',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.dispatcherPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                // Clear button
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onClear();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'إزالة',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Address details
            if (profile.temporaryAddress?.isNotEmpty == true)
              _InfoRow(
                label: 'العنوان',
                value: profile.temporaryAddress!,
                icon: Icons.home_rounded,
              ),
            if (profile.temporaryLatitude != null &&
                profile.temporaryLongitude != null)
              _InfoRow(
                label: 'الإحداثيات',
                value:
                    '${profile.temporaryLatitude!.toStringAsFixed(6)}, ${profile.temporaryLongitude!.toStringAsFixed(6)}',
                icon: Icons.gps_fixed_rounded,
              ),
            // Contact person
            if (profile.temporaryContactName?.isNotEmpty == true ||
                profile.temporaryContactPhone?.isNotEmpty == true) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.person_pin_rounded,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    'شخص الاتصال',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (profile.temporaryContactName?.isNotEmpty == true)
                Text(
                  profile.temporaryContactName!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                ),
              if (profile.temporaryContactPhone?.isNotEmpty == true)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.temporaryContactPhone!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _makeCall(profile.temporaryContactPhone!);
                      },
                      icon: const Icon(Icons.call_rounded, size: 18),
                      tooltip: 'اتصال',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.success.withValues(alpha: 0.1),
                        foregroundColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.dispatcherPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinesSection extends ConsumerWidget {
  final int passengerId;
  final List<PassengerGroupLine> lines;

  const _LinesSection({
    required this.passengerId,
    required this.lines,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigned = lines.where((l) => l.groupId != null).toList();
    final unassigned = lines.where((l) => l.groupId == null).toList();

    if (lines.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_rounded,
        title: 'لا توجد بيانات مجموعات',
        message: 'لم يتم العثور على سجل ربط لهذا الراكب.',
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.dispatcherPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'المجموعات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (assigned.isEmpty)
              const Text(
                'غير مدرج في أي مجموعة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
            ...assigned.map((l) => _lineTile(context, ref, l)),
            if (unassigned.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'سجل غير مدرجين',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...unassigned.map((l) => _lineTile(context, ref, l)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lineTile(BuildContext context, WidgetRef ref, PassengerGroupLine l) {
    final subtitleParts = <String>[];
    final pickup = l.pickupInfoDisplay?.trim();
    final dropoff = l.dropoffInfoDisplay?.trim();
    if (pickup != null && pickup.isNotEmpty) subtitleParts.add('صعود: $pickup');
    if (dropoff != null && dropoff.isNotEmpty)
      subtitleParts.add('نزول: $dropoff');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.dispatcherPrimary.withValues(alpha: 0.12),
        foregroundColor: AppColors.dispatcherPrimary,
        child: const Icon(Icons.groups_rounded),
      ),
      title: Text(
        l.groupName ?? 'غير مدرجين',
        style:
            const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'مقاعد: ${l.seatCount}${subtitleParts.isEmpty ? '' : '\n${subtitleParts.join('\n')}'}',
        style: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textSecondary,
          height: 1.3,
        ),
      ),
      isThreeLine: subtitleParts.isNotEmpty,
      trailing: PopupMenuButton<String>(
        tooltip: 'إجراءات',
        onSelected: (v) async {
          switch (v) {
            case 'unassign':
              if (l.groupId == null) return;
              HapticFeedback.lightImpact();
              await ref
                  .read(dispatcherPassengerActionsProvider.notifier)
                  .unassignFromGroup(
                    lineId: l.id,
                    groupId: l.groupId!,
                  );
              break;
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'unassign',
            enabled: l.groupId != null,
            child: const Row(
              children: [
                Icon(Icons.person_remove_alt_1_rounded, color: AppColors.error),
                SizedBox(width: 10),
                Text(
                  'إزالة من المجموعة',
                  style: TextStyle(fontFamily: 'Cairo', color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;

  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style:
                  const TextStyle(fontFamily: 'Cairo', color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
