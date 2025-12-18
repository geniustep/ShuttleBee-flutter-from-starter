import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../enums/user_role.dart';
import '../routing/role_routing.dart';
import '../services/role_switcher_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

/// Role Switcher Widget - عنصر التبديل بين الأدوار
class RoleSwitcherWidget extends ConsumerWidget {
  const RoleSwitcherWidget({
    super.key,
    this.allowedRoles,
  });

  /// Optional hard filter for roles to show in this widget.
  /// Useful for pages like Manager Home where you want Manager <-> Dispatcher only.
  final Set<UserRole>? allowedRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;

    if (user == null) return const SizedBox.shrink();

    final activeRole = ref.watch(activeRoleProvider);
    final currentRole = activeRole ?? user.role;

    final roleSwitcher = ref.watch(roleSwitcherServiceProvider);
    var availableRoles = roleSwitcher.getAvailableRoles(user);
    if (allowedRoles != null) {
      availableRoles =
          availableRoles.where((r) => allowedRoles!.contains(r)).toList();
    }

    // إذا كان هناك دور واحد فقط، لا نعرض المبدل
    if (availableRoles.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.xs),
              Text(
                '${l10n.viewAs}:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (activeRole != null && activeRole != user.role)
                TextButton.icon(
                  onPressed: () => _resetRole(context, ref),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.returnText),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Wrap(
            spacing: AppDimensions.xs,
            runSpacing: AppDimensions.xs,
            children: availableRoles.map((role) {
              final isActive = currentRole == role;
              final isOriginalRole = user.role == role;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(role),
                      size: 16,
                      color: isActive ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(role.getLabel(l10n.locale.languageCode)),
                    if (isOriginalRole) ...[
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.3)
                              : AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.original,
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? Colors.white : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isActive,
                onSelected: (selected) {
                  if (selected && !isActive) {
                    _switchRole(context, ref, role);
                  }
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : AppColors.textPrimary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.3),
                  width: isActive ? 2 : 1,
                ),
              );
            }).toList(),
          ),
          if (activeRole != null && activeRole != user.role) ...[
            const SizedBox(height: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.all(AppDimensions.xs),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppDimensions.xs),
                  Expanded(
                    child: Text(
                      '${l10n.youAreViewingAs} ${activeRole.getLabel(l10n.locale.languageCode)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.manager:
        return Icons.admin_panel_settings;
      case UserRole.dispatcher:
        return Icons.dashboard;
      case UserRole.driver:
        return Icons.directions_bus;
      case UserRole.passenger:
        return Icons.person;
    }
  }

  Future<void> _switchRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    final l10n = AppLocalizations.of(context);
    // تحديث الدور النشط + حفظه (داخل الـ notifier)
    ref.read(activeRoleProvider.notifier).setRole(role);

    // الانتقال للصفحة المناسبة
    if (context.mounted) {
      final homeRoute = getHomeRouteForRole(role);
      context.go(homeRoute);

      // إظهار رسالة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${l10n.switchedToView} ${role.getLabel(l10n.locale.languageCode)}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetRole(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final authState = ref.read(authStateProvider);
    final user = authState.asData?.value.user;
    if (user == null) return;
    // مسح الدور النشط (داخل الـ notifier)
    ref.read(activeRoleProvider.notifier).clearRole();

    // الانتقال للصفحة الأصلية
    if (context.mounted) {
      final homeRoute = getHomeRouteForRole(user.role);
      context.go(homeRoute);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${l10n.returnedToView} ${user.role!.getLabel(l10n.locale.languageCode)}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Role Switcher Button (للاستخدام في AppBar)
class RoleSwitcherButton extends ConsumerWidget {
  const RoleSwitcherButton({
    super.key,
    this.allowedRoles,
  });

  /// Optional hard filter for roles to show in the bottom sheet.
  final Set<UserRole>? allowedRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;

    if (user == null) return const SizedBox.shrink();

    final activeRole = ref.watch(activeRoleProvider);
    final currentRole = activeRole ?? user.role;

    final roleSwitcher = ref.watch(roleSwitcherServiceProvider);
    var availableRoles = roleSwitcher.getAvailableRoles(user);
    if (allowedRoles != null) {
      availableRoles =
          availableRoles.where((r) => allowedRoles!.contains(r)).toList();
    }

    if (availableRoles.length <= 1) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Stack(
        children: [
          Icon(
            Icons.swap_horiz,
            color: activeRole != null && activeRole != user.role
                ? AppColors.warning
                : null,
          ),
          if (activeRole != null && activeRole != user.role)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
      tooltip:
          '${l10n.switchRole} (${currentRole!.getLabel(l10n.locale.languageCode)})',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) =>
              RoleSwitcherBottomSheet(allowedRoles: allowedRoles),
        );
      },
    );
  }
}

/// Bottom Sheet للاختيار السريع
class RoleSwitcherBottomSheet extends ConsumerWidget {
  const RoleSwitcherBottomSheet({
    super.key,
    this.allowedRoles,
  });

  final Set<UserRole>? allowedRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;

    if (user == null) return const SizedBox.shrink();

    final activeRole = ref.watch(activeRoleProvider);
    final currentRole = activeRole ?? user.role;

    final roleSwitcher = ref.watch(roleSwitcherServiceProvider);
    var availableRoles = roleSwitcher.getAvailableRoles(user);
    if (allowedRoles != null) {
      availableRoles =
          availableRoles.where((r) => allowedRoles!.contains(r)).toList();
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text(l10n.switchRole, style: AppTypography.h5),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          ...availableRoles.map((role) {
            final isActive = currentRole == role;
            final isOriginal = user.role == role;

            return ListTile(
              leading: Icon(
                _getRoleIcon(role),
                color: isActive ? AppColors.primary : Colors.grey,
              ),
              title: Row(
                children: [
                  Text(role.getLabel(l10n.locale.languageCode)),
                  if (isOriginal) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.originalRole,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: isActive
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              selected: isActive,
              onTap: isActive
                  ? null
                  : () {
                      Navigator.pop(context);
                      _switchRole(context, ref, role);
                    },
            );
          }),
        ],
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.manager:
        return Icons.admin_panel_settings;
      case UserRole.dispatcher:
        return Icons.dashboard;
      case UserRole.driver:
        return Icons.directions_bus;
      case UserRole.passenger:
        return Icons.person;
    }
  }

  Future<void> _switchRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    ref.read(activeRoleProvider.notifier).setRole(role);

    if (context.mounted) {
      final homeRoute = getHomeRouteForRole(role);
      context.go(homeRoute);

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${l10n.switchedToView} ${role.getLabel(l10n.locale.languageCode)}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
