import '../enums/user_role.dart';
import 'route_paths.dart';

/// Helper to get home route based on user role
/// Used across the app for role-based navigation
/// 
/// إذا لم يكن للمستخدم دور محدد، يتم توجيهه لصفحة الراكب كافتراضي
/// لأن ShuttleBee لا يحتاج صفحة home عامة
String getHomeRouteForRole(UserRole? role) {
  switch (role) {
    case UserRole.driver:
      return RoutePaths.driverHome;
    case UserRole.dispatcher:
      return RoutePaths.dispatcherHome;
    case UserRole.passenger:
      return RoutePaths.passengerHome;
    case UserRole.manager:
      return RoutePaths.managerHome;
    case null:
      // إذا لم يكن هناك دور، نوجه للراكب كافتراضي
      // يمكن تغيير هذا لصفحة "اختر دورك" إذا لزم الأمر
      return RoutePaths.passengerHome;
  }
}

/// Check if a route is a role-based home route
bool isRoleHomeRoute(String route) {
  return route == RoutePaths.driverHome ||
      route == RoutePaths.dispatcherHome ||
      route == RoutePaths.passengerHome ||
      route == RoutePaths.managerHome;
}

/// Get the user role from a home route
UserRole? getRoleFromHomeRoute(String route) {
  switch (route) {
    case RoutePaths.driverHome:
      return UserRole.driver;
    case RoutePaths.dispatcherHome:
      return UserRole.dispatcher;
    case RoutePaths.passengerHome:
      return UserRole.passenger;
    case RoutePaths.managerHome:
      return UserRole.manager;
    default:
      return null;
  }
}
