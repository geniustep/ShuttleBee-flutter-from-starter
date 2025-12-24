/// Dispatcher Module
///
/// Live tracking and monitoring for fleet dispatchers
///
/// Features:
/// - Real-time vehicle tracking
/// - Driver status monitoring
/// - Google Maps integration
/// - Responsive design (Mobile/Tablet/Desktop)
/// - On-demand location requests
/// - Connection status management
///
/// Usage:
/// ```dart
/// import 'package:bridgecore_flutter/src/dispatcher/dispatcher.dart';
///
/// // Create tracking service
/// final trackingService = BridgeCore.instance.liveTracking;
///
/// // Navigate to monitor screen
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => LiveTrackingMonitorScreen(
///       dispatcherId: currentUserId,
///       trackingService: trackingService,
///     ),
///   ),
/// );
/// ```
library dispatcher;

// Screens
export 'presentation/screens/live_tracking_monitor_screen.dart';

// Widgets
export 'presentation/widgets/tracking_map_widget.dart';
export 'presentation/widgets/driver_list_panel.dart';
export 'presentation/widgets/tracking_controls.dart';
export 'presentation/widgets/connection_status_indicator.dart';

// State Management
export 'presentation/bloc/tracking_monitor_cubit.dart';

// Models
export 'presentation/models/tracked_vehicle.dart';
export 'presentation/models/map_bounds.dart';
