/// GoRouter Integration Example for Dispatcher Module
///
/// This example shows how to integrate the live tracking monitor
/// with go_router package for navigation.
library;

import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart'; // Add to pubspec.yaml

import 'dispatcher.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Complete GoRouter Setup
// ═══════════════════════════════════════════════════════════════════════════

/*
Add to pubspec.yaml:
dependencies:
  go_router: ^13.0.0

Then run:
flutter pub get
*/

// Main router configuration
/*
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,

  routes: [
    // Home route
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),

    // Dispatcher routes group
    GoRoute(
      path: '/dispatcher',
      name: 'dispatcher',
      builder: (context, state) => const DispatcherDashboard(),
      routes: [
        // Live tracking monitor
        GoRoute(
          path: 'monitor',
          name: 'dispatcherMonitor',
          pageBuilder: (context, state) {
            // Get user ID from query parameters or state
            final userIdParam = state.uri.queryParameters['userId'];
            final userId = int.tryParse(userIdParam ?? '') ??
                          (state.extra as int?) ??
                          1; // Default or from auth

            return MaterialPage(
              key: state.pageKey,
              child: LiveTrackingMonitorScreen(
                dispatcherId: userId,
                trackingService: BridgeCore.instance.liveTracking,
              ),
            );
          },
        ),
      ],
    ),

    // Error/404 route
    GoRoute(
      path: '/error',
      name: 'error',
      builder: (context, state) => ErrorPage(
        error: state.extra as String? ?? 'Unknown error',
      ),
    ),
  ],

  // Error handler
  errorBuilder: (context, state) => ErrorPage(
    error: state.error?.toString() ?? 'Page not found',
  ),

  // Redirect logic for authentication
  redirect: (context, state) {
    // Example: Check if user is authenticated
    // final isAuthenticated = // Your auth check
    // final isGoingToAuth = state.matchedLocation == '/login';

    // if (!isAuthenticated && !isGoingToAuth) {
    //   return '/login';
    // }

    return null; // No redirect
  },
);
*/

// ═══════════════════════════════════════════════════════════════════════════
// App Entry Point
// ═══════════════════════════════════════════════════════════════════════════

/*
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fleet Tracking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
*/

// ═══════════════════════════════════════════════════════════════════════════
// Navigation Examples
// ═══════════════════════════════════════════════════════════════════════════

class NavigationExamples {
  // Example 1: Navigate by name
  static void navigateToMonitor(BuildContext context, int userId) {
    // context.goNamed('dispatcherMonitor', extra: userId);
    // Or with query params:
    // context.goNamed(
    //   'dispatcherMonitor',
    //   queryParameters: {'userId': userId.toString()},
    // );
  }

  // Example 2: Navigate by path
  static void navigateToMonitorByPath(BuildContext context, int userId) {
    // context.go('/dispatcher/monitor?userId=$userId');
  }

  // Example 3: Push (keep previous route in stack)
  static void pushToMonitor(BuildContext context, int userId) {
    // context.pushNamed('dispatcherMonitor', extra: userId);
  }

  // Example 4: Replace current route
  static void replaceWithMonitor(BuildContext context, int userId) {
    // context.replaceNamed('dispatcherMonitor', extra: userId);
  }

  // Example 5: Navigate back
  static void goBack(BuildContext context) {
    // context.pop();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Example Pages
// ═══════════════════════════════════════════════════════════════════════════

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Management')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Open Live Tracking'),
              onPressed: () {
                // Using GoRouter:
                // context.goNamed('dispatcherMonitor', extra: 1);

                // Or navigate to dispatcher dashboard first:
                // context.go('/dispatcher');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DispatcherDashboard extends StatelessWidget {
  const DispatcherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispatcher Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _DashboardCard(
            icon: Icons.location_on,
            title: 'Live Tracking',
            subtitle: 'Monitor fleet in real-time',
            onTap: () {
              // context.go('/dispatcher/monitor?userId=1');
            },
          ),
          _DashboardCard(
            icon: Icons.people,
            title: 'Drivers',
            subtitle: 'Manage driver roster',
            onTap: () {
              // context.go('/dispatcher/drivers');
            },
          ),
          _DashboardCard(
            icon: Icons.local_shipping,
            title: 'Vehicles',
            subtitle: 'Fleet overview',
            onTap: () {
              // context.go('/dispatcher/vehicles');
            },
          ),
          _DashboardCard(
            icon: Icons.route,
            title: 'Trips',
            subtitle: 'Active and history',
            onTap: () {
              // context.go('/dispatcher/trips');
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final String error;

  const ErrorPage({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Oops!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
                onPressed: () {
                  // context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Advanced: Shell Route for Nested Navigation
// ═══════════════════════════════════════════════════════════════════════════

/*
// Create a shell route for persistent bottom navigation
final GoRouter advancedRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DispatcherDashboard(),
        ),
        GoRoute(
          path: '/monitor',
          builder: (context, state) => LiveTrackingMonitorScreen(
            dispatcherId: 1,
            trackingService: BridgeCore.instance.liveTracking,
          ),
        ),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Monitor',
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (idx) => _onItemTapped(idx, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/monitor')) return 1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/monitor');
        break;
    }
  }
}
*/
