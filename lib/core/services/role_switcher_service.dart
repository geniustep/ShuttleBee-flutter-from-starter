import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../enums/user_role.dart';
import '../storage/prefs_service.dart';
import '../../features/auth/domain/entities/user.dart';

/// Role Switcher Service - خدمة التبديل بين الأدوار - ShuttleBee
///
/// تسمح للمدير بالتبديل بين دوره الأساسي وأدوار أخرى للاطلاع عليها
class RoleSwitcherService {
  static const String _activeRoleKey = 'active_role';

  RoleSwitcherService();

  /// الحصول على الدور النشط الحالي
  UserRole? getActiveRole() {
    final roleStr = PrefsService.instance.getString(_activeRoleKey);
    if (roleStr == null) return null;
    return UserRole.tryFromString(roleStr);
  }

  /// حفظ الدور النشط
  Future<void> setActiveRole(UserRole role) async {
    await PrefsService.instance.setString(_activeRoleKey, role.value);
  }

  /// مسح الدور النشط (العودة للدور الأصلي)
  Future<void> clearActiveRole() async {
    await PrefsService.instance.remove(_activeRoleKey);
  }

  /// التحقق من إمكانية التبديل لهذا الدور
  bool canSwitchToRole(User user, UserRole targetRole) {
    // المدير يمكنه التبديل لجميع الأدوار
    if (user.role == UserRole.manager) {
      return true;
    }

    // Dispatcher يمكنه التبديل لـ Driver فقط
    if (user.role == UserRole.dispatcher && targetRole == UserRole.driver) {
      return true;
    }

    // باقي الأدوار لا يمكنها التبديل
    return false;
  }

  /// الحصول على قائمة الأدوار المتاحة للتبديل
  List<UserRole> getAvailableRoles(User user) {
    if (user.role == UserRole.manager) {
      return [
        UserRole.manager,
        UserRole.dispatcher,
        UserRole.driver,
        UserRole.passenger,
      ];
    }

    if (user.role == UserRole.dispatcher) {
      return [
        UserRole.dispatcher,
        UserRole.driver,
      ];
    }

    return [user.role];
  }
}

/// Provider for RoleSwitcherService
final roleSwitcherServiceProvider = Provider<RoleSwitcherService>((ref) {
  return RoleSwitcherService();
});

/// Active Role Notifier
class ActiveRoleNotifier extends StateNotifier<UserRole?> {
  ActiveRoleNotifier(this._service) : super(_service.getActiveRole());

  final RoleSwitcherService _service;

  void setRole(UserRole role) {
    _service.setActiveRole(role);
    state = role;
  }

  void clearRole() {
    _service.clearActiveRole();
    state = null;
  }

  void refresh() {
    state = _service.getActiveRole();
  }
}

/// Provider for active role
final activeRoleProvider =
    StateNotifierProvider.autoDispose<ActiveRoleNotifier, UserRole?>((ref) {
  final service = ref.watch(roleSwitcherServiceProvider);
  return ActiveRoleNotifier(service);
});
