/// Route paths constants - ShuttleBee
class RoutePaths {
  RoutePaths._();

  // === Root ===
  static const String splash = '/';
  static const String login = '/login';
  static const String selectCompany = '/select-company';

  // === Main ===
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // === Role-Based Home Screens (ShuttleBee) ===
  static const String driverHome = '/driver';
  static const String dispatcherHome = '/dispatcher';
  static const String passengerHome = '/passenger';
  static const String managerHome = '/manager';

  // === Driver Routes ===
  static const String driverTripDetail = '/driver/trip/:tripId';
  static const String driverActiveTrip = '/driver/trip/:tripId/active';
  static const String driverLiveTripMap = '/driver/trip/:tripId/live-map';

  // === Dispatcher Routes ===
  static const String dispatcherTrips = '/dispatcher/trips';
  static const String dispatcherCreateTrip = '/dispatcher/trips/create';
  static const String dispatcherTripDetail = '/dispatcher/trips/:tripId';
  static const String dispatcherEditTrip = '/dispatcher/trips/:tripId/edit';
  static const String dispatcherMonitor = '/dispatcher/monitor';
  static const String dispatcherVehicles = '/dispatcher/vehicles';
  static const String dispatcherCreateVehicle = '/dispatcher/vehicles/create';
  static const String dispatcherGroups = '/dispatcher/groups';
  static const String dispatcherCreateGroup = '/dispatcher/groups/create';
  static const String dispatcherGroupDetail = '/dispatcher/groups/:groupId';
  static const String dispatcherEditGroup = '/dispatcher/groups/:groupId/edit';
  static const String dispatcherGroupSchedules =
      '/dispatcher/groups/:groupId/schedules';
  static const String dispatcherGroupPassengers =
      '/dispatcher/groups/:groupId/passengers';
  static const String dispatcherPassengers = '/dispatcher/passengers';
  static const String dispatcherCreatePassenger =
      '/dispatcher/passengers/create';
  static const String dispatcherPassengersGroupPassengers =
      '/dispatcher/passengers/groups/:groupId';
  static const String dispatcherPassengerDetail =
      '/dispatcher/passengers/p/:passengerId';
  static const String dispatcherHolidays = '/dispatcher/holidays';
  static const String dispatcherHolidayDetail =
      '/dispatcher/holidays/:holidayId';

  // === Passenger Routes ===
  static const String passengerTripTracking = '/passenger/track/:tripId';

  // === Manager Routes ===
  static const String managerAnalytics = '/manager/analytics';
  static const String managerReports = '/manager/reports';
  static const String managerOverview = '/manager/overview';

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

  // ShuttleBee Role-Based
  static const String driverHome = 'driverHome';
  static const String dispatcherHome = 'dispatcherHome';
  static const String passengerHome = 'passengerHome';
  static const String managerHome = 'managerHome';

  // Driver
  static const String driverTripDetail = 'driverTripDetail';
  static const String driverActiveTrip = 'driverActiveTrip';
  static const String driverLiveTripMap = 'driverLiveTripMap';

  // Dispatcher
  static const String dispatcherTrips = 'dispatcherTrips';
  static const String dispatcherCreateTrip = 'dispatcherCreateTrip';
  static const String dispatcherTripDetail = 'dispatcherTripDetail';
  static const String dispatcherEditTrip = 'dispatcherEditTrip';
  static const String dispatcherMonitor = 'dispatcherMonitor';
  static const String dispatcherVehicles = 'dispatcherVehicles';
  static const String dispatcherCreateVehicle = 'dispatcherCreateVehicle';
  static const String dispatcherGroups = 'dispatcherGroups';
  static const String dispatcherCreateGroup = 'dispatcherCreateGroup';
  static const String dispatcherGroupDetail = 'dispatcherGroupDetail';
  static const String dispatcherEditGroup = 'dispatcherEditGroup';
  static const String dispatcherGroupSchedules = 'dispatcherGroupSchedules';
  static const String dispatcherGroupPassengers = 'dispatcherGroupPassengers';
  static const String dispatcherPassengers = 'dispatcherPassengers';
  static const String dispatcherCreatePassenger = 'dispatcherCreatePassenger';
  static const String dispatcherPassengersGroupPassengers =
      'dispatcherPassengersGroupPassengers';
  static const String dispatcherPassengerDetail = 'dispatcherPassengerDetail';
  static const String dispatcherHolidays = 'dispatcherHolidays';
  static const String dispatcherHolidayDetail = 'dispatcherHolidayDetail';

  // Passenger
  static const String passengerTripTracking = 'passengerTripTracking';

  // Manager
  static const String managerAnalytics = 'managerAnalytics';
  static const String managerReports = 'managerReports';
  static const String managerOverview = 'managerOverview';

  // Settings
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String offlineSettings = 'offlineSettings';
  static const String notifications = 'notifications';
  static const String search = 'search';
  static const String offlineStatus = 'offlineStatus';
  static const String pendingOperations = 'pendingOperations';
}
