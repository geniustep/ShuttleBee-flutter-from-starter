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
import '../../features/driver/presentation/screens/driver_trip_detail_screen.dart';
import '../../features/driver/presentation/screens/driver_active_trip_screen.dart';
import '../../features/driver/presentation/screens/driver_live_trip_map_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_home_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_trips_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_vehicles_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_monitor_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_groups_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_create_group_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_edit_group_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_create_trip_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_shell_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_create_vehicle_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_group_passengers_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_group_detail_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_passengers_board_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_create_passenger_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_passenger_detail_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_edit_passenger_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_holidays_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_holiday_detail_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_trip_detail_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_edit_trip_screen.dart';
import '../../features/dispatcher/presentation/screens/dispatcher_trip_passengers_screen.dart';
import '../../features/groups/presentation/screens/group_schedules_screen.dart';
import '../../features/passenger/presentation/screens/passenger_home_screen.dart';
import '../../features/manager/presentation/screens/manager_home_screen.dart';
import '../../features/manager/presentation/screens/manager_analytics_screen.dart';
import '../../features/manager/presentation/screens/manager_reports_screen.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';

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
      final isOldHome = state.matchedLocation == RoutePaths.home;

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

      // Redirect from old /home to role-based home
      // هذا يمنع الوصول لصفحة home القديمة
      if (isLoggedIn && isOldHome) {
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
              return DriverTripDetailScreen(
                key: ValueKey('driver_trip_detail_$tripId'),
                tripId: tripId,
              );
            },
            routes: [
              GoRoute(
                path: 'active',
                name: RouteNames.driverActiveTrip,
                builder: (context, state) {
                  final tripId = int.parse(state.pathParameters['tripId']!);
                  return DriverActiveTripScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: 'live-map',
                name: RouteNames.driverLiveTripMap,
                builder: (context, state) {
                  final tripId = int.parse(state.pathParameters['tripId']!);
                  return DriverLiveTripMapScreen(
                    key: ValueKey('driver_live_map_$tripId'),
                    tripId: tripId,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // Dispatcher Shell (Bottom Navigation) + branches
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DispatcherShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dispatcherHome,
                name: RouteNames.dispatcherHome,
                builder: (context, state) => const DispatcherHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'holidays',
                    name: RouteNames.dispatcherHolidays,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        const DispatcherHolidaysScreen(),
                    routes: [
                      GoRoute(
                        path: ':holidayId',
                        name: RouteNames.dispatcherHolidayDetail,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final holidayId =
                              int.parse(state.pathParameters['holidayId']!);
                          return DispatcherHolidayDetailScreen(
                            key: ValueKey('dispatcher_holiday_$holidayId'),
                            holidayId: holidayId,
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'passengers',
                    name: RouteNames.dispatcherPassengers,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      return const DispatcherPassengersBoardScreen();
                    },
                    routes: [
                      GoRoute(
                        path: 'p/:passengerId',
                        name: RouteNames.dispatcherPassengerDetail,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final passengerId =
                              int.parse(state.pathParameters['passengerId']!);
                          return DispatcherPassengerDetailScreen(
                            key: ValueKey(
                                'dispatcher_passenger_detail_$passengerId'),
                            passengerId: passengerId,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'edit',
                            name: RouteNames.dispatcherEditPassenger,
                            parentNavigatorKey: rootNavigatorKey,
                            builder: (context, state) {
                              final passengerId = int.parse(
                                  state.pathParameters['passengerId']!);
                              return DispatcherEditPassengerScreen(
                                key: ValueKey(
                                    'dispatcher_edit_passenger_$passengerId'),
                                passengerId: passengerId,
                              );
                            },
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'groups/:groupId',
                        name: RouteNames.dispatcherPassengersGroupPassengers,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final groupId =
                              int.parse(state.pathParameters['groupId']!);
                          return DispatcherGroupPassengersScreen(
                            key: ValueKey(
                                'dispatcher_passengers_group_$groupId'),
                            groupId: groupId,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'create',
                        name: RouteNames.dispatcherCreatePassenger,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          return const DispatcherCreatePassengerScreen();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Monitor
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dispatcherMonitor,
                name: RouteNames.dispatcherMonitor,
                builder: (context, state) => const DispatcherMonitorScreen(),
              ),
            ],
          ),
          // Trips
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dispatcherTrips,
                name: RouteNames.dispatcherTrips,
                builder: (context, state) => const DispatcherTripsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: RouteNames.dispatcherCreateTrip,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final groupId = state.uri.queryParameters['groupId'];
                      return DispatcherCreateTripScreen(
                        initialGroupId:
                            groupId != null ? int.tryParse(groupId) : null,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':tripId',
                    name: RouteNames.dispatcherTripDetail,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final tripId = int.parse(state.pathParameters['tripId']!);
                      return DispatcherTripDetailScreen(
                        key: ValueKey('dispatcher_trip_detail_$tripId'),
                        tripId: tripId,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: RouteNames.dispatcherEditTrip,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final tripId =
                              int.parse(state.pathParameters['tripId']!);
                          return DispatcherEditTripScreen(
                            key: ValueKey('dispatcher_edit_trip_$tripId'),
                            tripId: tripId,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'passengers',
                        name: RouteNames.dispatcherTripPassengers,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final tripId =
                              int.parse(state.pathParameters['tripId']!);
                          return DispatcherTripPassengersScreen(
                            key: ValueKey('dispatcher_trip_passengers_$tripId'),
                            tripId: tripId,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Groups
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dispatcherGroups,
                name: RouteNames.dispatcherGroups,
                builder: (context, state) => const DispatcherGroupsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: RouteNames.dispatcherCreateGroup,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        const DispatcherCreateGroupScreen(),
                  ),
                  GoRoute(
                    path: ':groupId',
                    name: RouteNames.dispatcherGroupDetail,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final groupId =
                          int.parse(state.pathParameters['groupId']!);
                      return DispatcherGroupDetailScreen(
                        key: ValueKey('dispatcher_group_detail_$groupId'),
                        groupId: groupId,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'passengers',
                        name: RouteNames.dispatcherGroupPassengers,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final groupId =
                              int.parse(state.pathParameters['groupId']!);
                          return DispatcherGroupPassengersScreen(
                            key: ValueKey(
                                'dispatcher_group_passengers_$groupId'),
                            groupId: groupId,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'edit',
                        name: RouteNames.dispatcherEditGroup,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final groupId =
                              int.parse(state.pathParameters['groupId']!);
                          return DispatcherEditGroupScreen(
                            key: ValueKey('dispatcher_edit_group_$groupId'),
                            groupId: groupId,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'schedules',
                        name: RouteNames.dispatcherGroupSchedules,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final groupId =
                              int.parse(state.pathParameters['groupId']!);
                          return GroupSchedulesScreen(
                            key:
                                ValueKey('dispatcher_group_schedules_$groupId'),
                            groupId: groupId,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Vehicles
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dispatcherVehicles,
                name: RouteNames.dispatcherVehicles,
                builder: (context, state) => const DispatcherVehiclesScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: RouteNames.dispatcherCreateVehicle,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      return const DispatcherCreateVehicleScreen();
                    },
                  ),
                ],
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
            builder: (context, state) => const ManagerAnalyticsScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: RouteNames.managerReports,
            builder: (context, state) => const ManagerReportsScreen(),
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

      // Chat
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(conversationId: conversationId);
        },
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
