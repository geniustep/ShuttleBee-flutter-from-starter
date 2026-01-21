import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/enums/user_role.dart';
import '../../../../../../../core/routing/route_paths.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../auth/presentation/providers/auth_provider.dart';

/// 🔄 Role Switcher Widget - محوّل الأدوار
/// يسمح للمستخدمين الذين لديهم أدوار متعددة بالتبديل بينها
class RoleSwitcher extends ConsumerWidget {
  /// الوضع الحالي (للتوافق مع الكود القديم)
  final bool isDispatcherMode;

  /// Callback عند تغيير الوضع (للتوافق مع الكود القديم)
  final ValueChanged<bool>? onRoleChanged;

  const RoleSwitcher({
    super.key,
    required this.isDispatcherMode,
    this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value.user;
    final currentRole = user?.role;

    // إذا لم يكن لديه دور أو المستخدم غير موجود
    if (user == null || currentRole == null) {
      return const SizedBox.shrink();
    }

    // الأدوار المتاحة للتبديل بينها
    final availableRoles = _getAvailableRoles(currentRole);

    // إذا كان لديه دور واحد فقط، لا داعي للمحوّل
    if (availableRoles.length <= 1) {
      return _buildCurrentRoleBadge(currentRole);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableRoles.map((role) {
          final isSelected = role == currentRole;
          return _RoleButton(
            role: role,
            isSelected: isSelected,
            onTap: () => _switchRole(context, ref, role),
          );
        }).toList(),
      ),
    );
  }

  /// بناء شارة الدور الحالي (عندما يكون دور واحد فقط)
  Widget _buildCurrentRoleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: _getRoleGradient(role),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getRoleColor(role).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(role),
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            role.arabicLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  /// الحصول على الأدوار المتاحة للتبديل
  List<UserRole> _getAvailableRoles(UserRole currentRole) {
    // المدير والمشغل يمكنهم التبديل بينهما
    if (currentRole == UserRole.manager || currentRole == UserRole.dispatcher) {
      return [UserRole.dispatcher, UserRole.manager];
    }

    // السائق يمكنه فقط رؤية دوره (لا تبديل)
    if (currentRole == UserRole.driver) {
      return [UserRole.driver];
    }

    // الراكب يمكنه فقط رؤية دوره (لا تبديل)
    if (currentRole == UserRole.passenger) {
      return [UserRole.passenger];
    }

    return [currentRole];
  }

  /// التبديل إلى دور آخر
  void _switchRole(BuildContext context, WidgetRef ref, UserRole newRole) {
    HapticFeedback.mediumImpact();

    // التوجه إلى الصفحة الرئيسية للدور الجديد
    final route = _getRouteForRole(newRole);

    // إظهار رسالة تأكيد
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getRoleIcon(newRole), color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'تم التبديل إلى وضع ${newRole.arabicLabel}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: _getRoleColor(newRole),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    // التنقل للصفحة الجديدة
    context.go(route);

    // إبلاغ الـ callback إذا كان موجوداً
    onRoleChanged?.call(newRole == UserRole.dispatcher);
  }

  /// الحصول على المسار حسب الدور
  String _getRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return RoutePaths.driverHome;
      case UserRole.dispatcher:
        return RoutePaths.dispatcherHome;
      case UserRole.passenger:
        return RoutePaths.passengerHome;
      case UserRole.manager:
        return RoutePaths.managerHome;
    }
  }

  /// الحصول على أيقونة الدور
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return Icons.directions_bus_rounded;
      case UserRole.dispatcher:
        return Icons.dashboard_rounded;
      case UserRole.passenger:
        return Icons.person_rounded;
      case UserRole.manager:
        return Icons.analytics_rounded;
    }
  }

  /// الحصول على لون الدور
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return AppColors.secondary;
      case UserRole.dispatcher:
        return AppColors.dispatcherPrimary;
      case UserRole.passenger:
        return AppColors.info;
      case UserRole.manager:
        return AppColors.success;
    }
  }

  /// الحصول على تدرج الدور
  LinearGradient _getRoleGradient(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return AppColors.secondaryGradient;
      case UserRole.dispatcher:
        return AppColors.dispatcherGradient;
      case UserRole.passenger:
        return AppColors.primaryGradient;
      case UserRole.manager:
        return const LinearGradient(
          colors: [AppColors.success, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

/// 🔘 Role Button - زر الدور
class _RoleButton extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _getRoleColor(role).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: _getRoleGradient(role),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Icon(
                _getRoleIcon(role),
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              role.arabicLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _getRoleColor(role) : AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return Icons.directions_bus_rounded;
      case UserRole.dispatcher:
        return Icons.dashboard_rounded;
      case UserRole.passenger:
        return Icons.person_rounded;
      case UserRole.manager:
        return Icons.analytics_rounded;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return AppColors.secondary;
      case UserRole.dispatcher:
        return AppColors.dispatcherPrimary;
      case UserRole.passenger:
        return AppColors.info;
      case UserRole.manager:
        return AppColors.success;
    }
  }

  LinearGradient _getRoleGradient(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return AppColors.secondaryGradient;
      case UserRole.dispatcher:
        return AppColors.dispatcherGradient;
      case UserRole.passenger:
        return AppColors.primaryGradient;
      case UserRole.manager:
        return const LinearGradient(
          colors: [AppColors.success, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
