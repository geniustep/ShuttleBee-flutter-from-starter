/// Example usage of the Dispatcher Module
///
/// This file demonstrates how to integrate the live tracking monitor
/// in your Flutter application.

import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart'; // Uncomment if using GoRouter

import 'dispatcher.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Example 1: Basic Navigation
// ═══════════════════════════════════════════════════════════════════════════

class DispatcherDashboard extends StatelessWidget {
  final int currentUserId;

  const DispatcherDashboard({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatcher Dashboard'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.map),
          label: const Text('Open Live Tracking Monitor'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LiveTrackingMonitorScreen(
                  dispatcherId: currentUserId,
                  trackingService: BridgeCore.instance.liveTracking,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Example 2: GoRouter Integration
// ═══════════════════════════════════════════════════════════════════════════

/*
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/dispatcher/monitor',
      name: 'dispatcherMonitor',
      builder: (context, state) {
        final userId = state.extra as int? ?? 0; // Or get from auth state

        return LiveTrackingMonitorScreen(
          dispatcherId: userId,
          trackingService: BridgeCore.instance.liveTracking,
        );
      },
    ),
  ],
);

// Navigate to monitor
context.goNamed('dispatcherMonitor', extra: currentUserId);
*/

// ═══════════════════════════════════════════════════════════════════════════
// Example 3: With Authentication Check
// ═══════════════════════════════════════════════════════════════════════════

class SecureDispatcherMonitor extends StatefulWidget {
  const SecureDispatcherMonitor({Key? key}) : super(key: key);

  @override
  State<SecureDispatcherMonitor> createState() =>
      _SecureDispatcherMonitorState();
}

class _SecureDispatcherMonitorState extends State<SecureDispatcherMonitor> {
  bool _isLoading = true;
  bool _isAuthorized = false;
  int? _userId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    try {
      // Check if user is authenticated
      // final bridgeCore = BridgeCore.instance;

      // Assuming you have an auth service
      // final userInfo = await bridgeCore.auth.getUserInfo();
      // final hasDispatcherRole = userInfo.roles.contains('dispatcher');

      // For this example:
      const hasDispatcherRole = true;
      const userId = 1;

      setState(() {
        _isAuthorized = hasDispatcherRole;
        _userId = userId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Authorization failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthorized || _userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Access Denied',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('You need dispatcher role to access this feature'),
            ],
          ),
        ),
      );
    }

    return LiveTrackingMonitorScreen(
      dispatcherId: _userId!,
      trackingService: BridgeCore.instance.liveTracking,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Example 4: Custom Integration with State Management
// ═══════════════════════════════════════════════════════════════════════════

class CustomTrackingScreen extends StatefulWidget {
  const CustomTrackingScreen({Key? key}) : super(key: key);

  @override
  State<CustomTrackingScreen> createState() => _CustomTrackingScreenState();
}

class _CustomTrackingScreenState extends State<CustomTrackingScreen> {
  late TrackingMonitorCubit _cubit;

  @override
  void initState() {
    super.initState();
    final trackingService = BridgeCore.instance.liveTracking;
    _cubit = TrackingMonitorCubit(trackingService: trackingService);

    // Setup custom listeners
    _setupCustomListeners();
  }

  void _setupCustomListeners() {
    // Listen to vehicle updates and do custom logic
    _cubit.vehiclesStream.listen((vehicles) {
      debugPrint('Active vehicles: ${vehicles.length}');

      // Custom logic: Alert if any vehicle goes offline
      for (final vehicle in vehicles.values) {
        if (!vehicle.isOnline && vehicle.isOnTrip) {
          _showAlert('Vehicle ${vehicle.vehicleName} went offline during trip!');
        }
      }
    });

    // Listen to selected vehicle
    _cubit.selectedVehicleStream.listen((vehicle) {
      if (vehicle != null) {
        debugPrint('Selected: ${vehicle.vehicleName}');
      }
    });
  }

  void _showAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _cubit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the cubit directly with custom widgets
    return LiveTrackingMonitorScreen(
      dispatcherId: 1, // Your user ID
      trackingService: BridgeCore.instance.liveTracking,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Example 5: Minimal Integration
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fleet Tracking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LiveTrackingMonitorScreen(
        dispatcherId: 1,
        trackingService: BridgeCore.instance.liveTracking,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Example 6: With Custom Theme
// ═══════════════════════════════════════════════════════════════════════════

class ThemedTrackingApp extends StatelessWidget {
  const ThemedTrackingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // Custom colors
        primaryColor: const Color(0xFF1976D2),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardColor: Colors.white,

        // Custom text theme
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF616161),
          ),
        ),

        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        useMaterial3: true,
      ),
      home: LiveTrackingMonitorScreen(
        dispatcherId: 1,
        trackingService: BridgeCore.instance.liveTracking,
      ),
    );
  }
}
