/// Route paths constants
class RoutePaths {
  RoutePaths._();

  // === Root ===
  static const String splash = '/';
  static const String login = '/login';
  static const String selectCompany = '/select-company';

  // === Main ===
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // === Settings ===
  static const String settings = '/settings';
  static const String profile = '/settings/profile';
  static const String offlineSettings = '/settings/offline';

  // === Notifications ===
  static const String notifications = '/notifications';

  // === Search ===
  static const String search = '/search';

  // === Offline Manager ===
  static const String offlineStatus = '/offline-manager';
  static const String pendingOperations = '/offline-manager/pending';
}

/// Route names for named navigation
class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String selectCompany = 'selectCompany';
  static const String home = 'home';
  static const String dashboard = 'dashboard';
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String offlineSettings = 'offlineSettings';
  static const String notifications = 'notifications';
  static const String search = 'search';
  static const String offlineStatus = 'offlineStatus';
  static const String pendingOperations = 'pendingOperations';
}
