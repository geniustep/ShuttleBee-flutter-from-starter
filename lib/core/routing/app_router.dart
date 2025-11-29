import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/select_company_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/offline_manager/presentation/screens/offline_status_screen.dart';
import '../../features/offline_manager/presentation/screens/pending_operations_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/offline_settings_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

// ShuttleBee Screens
import '../../features/driver/presentation/screens/driver_home_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_home_screen.dart';
import '../../features/passenger/presentation/screens/passenger_home_screen.dart';
import '../../features/manager/presentation/screens/manager_home_screen.dart';

import 'role_routing.dart';
import 'route_paths.dart';

/// Global navigator key
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value.isAuthenticated ?? false;
      final user = authState.asData?.value.user;
      final isLoggingIn = state.matchedLocation == RoutePaths.login;
      final isSplash = state.matchedLocation == RoutePaths.splash;
      final isSelectCompany = state.matchedLocation == RoutePaths.selectCompany;

      // Allow splash screen
      if (isSplash) return null;

      // Allow select company after login
      if (isSelectCompany && isLoggedIn) return null;

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isLoggingIn) {
        return RoutePaths.login;
      }

      // Redirect to role-based home if authenticated and on login page
      if (isLoggedIn && isLoggingIn) {
        return getHomeRouteForRole(user?.role);
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.selectCompany,
        name: RouteNames.selectCompany,
        builder: (context, state) => const SelectCompanyScreen(),
      ),

      // Home
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),

      // Dashboard
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      // === ShuttleBee Role-Based Routes ===

      // Driver Home + children
      GoRoute(
        path: RoutePaths.driverHome,
        name: RouteNames.driverHome,
        builder: (context, state) => const DriverHomeScreen(),
        routes: [
          GoRoute(
            path: 'trip/:tripId',
            name: RouteNames.driverTripDetail,
            builder: (context, state) {
              final tripId = int.parse(state.pathParameters['tripId']!);
              // TODO: Replace with actual TripDetailScreen
              return Scaffold(
                appBar: AppBar(title: const Text('تفاصيل الرحلة')),
                body: Center(child: Text('تفاصيل الرحلة رقم: $tripId')),
              );
            },
            routes: [
              GoRoute(
                path: 'active',
                name: RouteNames.driverActiveTrip,
                builder: (context, state) {
                  final tripId = int.parse(state.pathParameters['tripId']!);
                  // TODO: Replace with actual ActiveTripScreen
                  return Scaffold(
                    appBar: AppBar(title: const Text('الرحلة النشطة')),
                    body: Center(child: Text('إدارة الرحلة رقم: $tripId')),
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // Dispatcher Home + children
      GoRoute(
        path: RoutePaths.dispatcherHome,
        name: RouteNames.dispatcherHome,
        builder: (context, state) => const DispatcherHomeScreen(),
        routes: [
          GoRoute(
            path: 'trips',
            name: RouteNames.dispatcherTrips,
            builder: (context, state) {
              // TODO: Replace with actual TripListScreen
              return Scaffold(
                appBar: AppBar(title: const Text('إدارة الرحلات')),
                body: const Center(child: Text('قائمة الرحلات')),
              );
            },
            routes: [
              GoRoute(
                path: 'create',
                name: RouteNames.dispatcherCreateTrip,
                builder: (context, state) {
                  // TODO: Replace with actual CreateTripScreen
                  return Scaffold(
                    appBar: AppBar(title: const Text('إنشاء رحلة جديدة')),
                    body: const Center(child: Text('نموذج إنشاء رحلة')),
                  );
                },
              ),
              GoRoute(
                path: ':tripId',
                name: RouteNames.dispatcherTripDetail,
                builder: (context, state) {
                  final tripId = int.parse(state.pathParameters['tripId']!);
                  // TODO: Replace with actual DispatcherTripDetailScreen
                  return Scaffold(
                    appBar: AppBar(title: const Text('تفاصيل الرحلة')),
                    body: Center(child: Text('تفاصيل الرحلة رقم: $tripId')),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.dispatcherEditTrip,
                    builder: (context, state) {
                      final tripId = int.parse(state.pathParameters['tripId']!);
                      // TODO: Replace with actual EditTripScreen
                      return Scaffold(
                        appBar: AppBar(title: const Text('تعديل الرحلة')),
                        body: Center(child: Text('تعديل الرحلة رقم: $tripId')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'monitor',
            name: RouteNames.dispatcherMonitor,
            builder: (context, state) {
              // TODO: Replace with actual RealTimeMonitoringScreen
              return Scaffold(
                appBar: AppBar(title: const Text('المراقبة الحية')),
                body: const Center(child: Text('خريطة المراقبة الحية')),
              );
            },
          ),
          GoRoute(
            path: 'vehicles',
            name: RouteNames.dispatcherVehicles,
            builder: (context, state) {
              // TODO: Replace with actual VehicleManagementScreen
              return Scaffold(
                appBar: AppBar(title: const Text('إدارة المركبات')),
                body: const Center(child: Text('قائمة المركبات')),
              );
            },
            routes: [
              GoRoute(
                path: 'create',
                name: RouteNames.dispatcherCreateVehicle,
                builder: (context, state) {
                  // TODO: Replace with actual CreateEditVehicleScreen
                  return Scaffold(
                    appBar: AppBar(title: const Text('إضافة مركبة')),
                    body: const Center(child: Text('نموذج إضافة مركبة')),
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // Passenger Home + children
      GoRoute(
        path: RoutePaths.passengerHome,
        name: RouteNames.passengerHome,
        builder: (context, state) => const PassengerHomeScreen(),
        routes: [
          GoRoute(
            path: 'track/:tripId',
            name: RouteNames.passengerTripTracking,
            builder: (context, state) {
              final tripId = int.parse(state.pathParameters['tripId']!);
              // TODO: Replace with actual TripTrackingScreen
              return Scaffold(
                appBar: AppBar(title: const Text('تتبع الرحلة')),
                body: Center(child: Text('تتبع الرحلة رقم: $tripId')),
              );
            },
          ),
        ],
      ),

      // Manager Home + children
      GoRoute(
        path: RoutePaths.managerHome,
        name: RouteNames.managerHome,
        builder: (context, state) => const ManagerHomeScreen(),
        routes: [
          GoRoute(
            path: 'analytics',
            name: RouteNames.managerAnalytics,
            builder: (context, state) {
              // TODO: Replace with actual AnalyticsScreen
              return Scaffold(
                appBar: AppBar(title: const Text('التحليلات المتقدمة')),
                body: const Center(child: Text('شاشة التحليلات')),
              );
            },
          ),
          GoRoute(
            path: 'reports',
            name: RouteNames.managerReports,
            builder: (context, state) {
              // TODO: Replace with actual ReportsScreen
              return Scaffold(
                appBar: AppBar(title: const Text('التقارير')),
                body: const Center(child: Text('شاشة التقارير')),
              );
            },
          ),
          GoRoute(
            path: 'overview',
            name: RouteNames.managerOverview,
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(title: const Text('نظرة عامة')),
                body: const Center(child: Text('نظرة عامة على الأداء')),
              );
            },
          ),
        ],
      ),

      // Settings
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'offline',
            name: RouteNames.offlineSettings,
            builder: (context, state) => const OfflineSettingsScreen(),
          ),
        ],
      ),

      // Notifications
      GoRoute(
        path: RoutePaths.notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Search
      GoRoute(
        path: RoutePaths.search,
        name: RouteNames.search,
        builder: (context, state) => const SearchScreen(),
      ),

      // Offline Manager
      GoRoute(
        path: RoutePaths.offlineStatus,
        name: RouteNames.offlineStatus,
        builder: (context, state) => const OfflineStatusScreen(),
        routes: [
          GoRoute(
            path: 'pending',
            name: RouteNames.pendingOperations,
            builder: (context, state) => const PendingOperationsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
