import 'package:bridgecore_flutter_starter/core/theme/app_colors.dart';
import 'package:bridgecore_flutter_starter/features/dispatcher/domain/entities/dispatcher_passenger_profile.dart';
import 'package:bridgecore_flutter_starter/features/dispatcher/presentation/providers/dispatcher_partner_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';


/// Quick action types for passenger management
enum PassengerQuickAction {
  changeLocation, // تغيير العنوان
  callFather, // اتصال بالأب
  callMother, // اتصال بالأم
  callPassenger, // اتصال بالراكب
  whatsappFather, // واتساب الأب
  whatsappMother, // واتساب الأم
  editProfile, // تعديل الملف الشخصي
  markAbsent, // تسجيل غياب
}

/// Bottom sheet for quick passenger actions
class PassengerQuickActionsSheet extends ConsumerWidget {
  final int passengerId;
  final String passengerName;
  final DispatcherPassengerProfile? profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangeLocation;
  final VoidCallback? onMarkAbsent;

  const PassengerQuickActionsSheet({
    super.key,
    required this.passengerId,
    required this.passengerName,
    this.profile,
    this.onEditProfile,
    this.onChangeLocation,
    this.onMarkAbsent,
  });

  /// Show the quick actions sheet
  static Future<PassengerQuickAction?> show(
    BuildContext context, {
    required int passengerId,
    required String passengerName,
    DispatcherPassengerProfile? profile,
    VoidCallback? onEditProfile,
    VoidCallback? onChangeLocation,
    VoidCallback? onMarkAbsent,
  }) {
    return showModalBottomSheet<PassengerQuickAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PassengerQuickActionsSheet(
        passengerId: passengerId,
        passengerName: passengerName,
        profile: profile,
        onEditProfile: onEditProfile,
        onChangeLocation: onChangeLocation,
        onMarkAbsent: onMarkAbsent,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = profile != null
        ? AsyncValue.data(profile)
        : ref.watch(dispatcherPassengerProfileProvider(passengerId));

    return Container(
      margin: const EdgeInsets.only(top: 60),
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
                      gradient: AppColors.dispatcherGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إجراءات سريعة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          passengerName,
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
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
            const Divider(height: 20),
            // Actions grid
            profileAsync.when(
              data: (p) => _buildActionsGrid(context, p),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'خطأ: $e',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid(
      BuildContext context, DispatcherPassengerProfile? p) {
    final actions = <_QuickActionItem>[];

    // Absence action
    actions.add(_QuickActionItem(
      icon: Icons.event_busy_rounded,
      label: 'غياب',
      color: AppColors.warning,
      description: 'تسجيل غياب في رحلة',
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, PassengerQuickAction.markAbsent);
        onMarkAbsent?.call();
      },
    ));

    // Location action
    actions.add(_QuickActionItem(
      icon: Icons.location_on_rounded,
      label: 'تغيير العنوان',
      color: AppColors.primary,
      description: p?.hasTemporaryAddress == true
          ? 'عنوان مؤقت نشط'
          : 'تعيين عنوان مؤقت',
      badge: p?.hasTemporaryAddress == true ? '!' : null,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context, PassengerQuickAction.changeLocation);
        onChangeLocation?.call();
      },
    ));

    // Call actions - Father
    final fatherPhone = p?.fatherPhone?.trim();
    if (fatherPhone != null && fatherPhone.isNotEmpty) {
      actions.add(_QuickActionItem(
        icon: Icons.call_rounded,
        label: 'اتصال بالأب',
        color: AppColors.success,
        description: fatherPhone,
        onTap: () {
          HapticFeedback.lightImpact();
          _makePhoneCall(fatherPhone);
          Navigator.pop(context, PassengerQuickAction.callFather);
        },
      ));

      actions.add(_QuickActionItem(
        icon: Icons.chat_rounded,
        label: 'واتساب الأب',
        color: const Color(0xFF25D366),
        description: fatherPhone,
        onTap: () {
          HapticFeedback.lightImpact();
          _openWhatsApp(fatherPhone);
          Navigator.pop(context, PassengerQuickAction.whatsappFather);
        },
      ));
    }

    // Call actions - Mother
    final motherPhone = p?.motherPhone?.trim();
    if (motherPhone != null && motherPhone.isNotEmpty) {
      actions.add(_QuickActionItem(
        icon: Icons.call_rounded,
        label: 'اتصال بالأم',
        color: AppColors.success,
        description: motherPhone,
        onTap: () {
          HapticFeedback.lightImpact();
          _makePhoneCall(motherPhone);
          Navigator.pop(context, PassengerQuickAction.callMother);
        },
      ));

      actions.add(_QuickActionItem(
        icon: Icons.chat_rounded,
        label: 'واتساب الأم',
        color: const Color(0xFF25D366),
        description: motherPhone,
        onTap: () {
          HapticFeedback.lightImpact();
          _openWhatsApp(motherPhone);
          Navigator.pop(context, PassengerQuickAction.whatsappMother);
        },
      ));
    }

    // Fallback to legacy guardian phone
    final guardianPhone = p?.guardianPhone?.trim();
    if ((fatherPhone == null || fatherPhone.isEmpty) &&
        (motherPhone == null || motherPhone.isEmpty) &&
        guardianPhone != null &&
        guardianPhone.isNotEmpty) {
      actions.add(_QuickActionItem(
        icon: Icons.call_rounded,
        label: 'اتصال ولي الأمر',
        color: AppColors.success,
        description: guardianPhone,
        onTap: () {
          HapticFeedback.lightImpact();
          _makePhoneCall(guardianPhone);
          Navigator.pop(context, PassengerQuickAction.callFather);
        },
      ));
    }

    // Call passenger directly
    final passengerPhone = p?.phone?.trim() ?? p?.mobile?.trim();
    if (passengerPhone != null && passengerPhone.isNotEmpty) {
      actions.add(_QuickActionItem(
        icon: Icons.phone_android_rounded,
        label: 'اتصال بالراكب',
        color: AppColors.dispatcherPrimary,
        description: passengerPhone,
        onTap: () {
          HapticFeedback.lightImpact();
          _makePhoneCall(passengerPhone);
          Navigator.pop(context, PassengerQuickAction.callPassenger);
        },
      ));
    }

    // Edit profile
    actions.add(_QuickActionItem(
      icon: Icons.edit_rounded,
      label: 'تعديل الملف',
      color: AppColors.textSecondary,
      description: 'فتح صفحة التعديل',
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context, PassengerQuickAction.editProfile);
        onEditProfile?.call();
      },
    ));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _ActionCard(
            icon: action.icon,
            label: action.label,
            color: action.color,
            description: action.description,
            badge: action.badge,
            onTap: action.onTap,
          ).animate().fadeIn(
                duration: 200.ms,
                delay: (50 * index).ms,
              );
        },
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    // Remove any non-digit characters except +
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
    this.badge,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
