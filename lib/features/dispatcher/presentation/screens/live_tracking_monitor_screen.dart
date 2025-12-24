import 'package:bridgecore_flutter_starter/features/vehicles/data/datasources/vehicle_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import '../../../../core/config/company_config.dart';
import '../widgets/tracking_map_widget.dart';
import '../widgets/driver_list_panel.dart';
import '../widgets/tracking_controls.dart';
import '../widgets/connection_status_indicator.dart';
import '../bloc/tracking_monitor_cubit.dart';

/// Live Tracking Monitor Screen
///
/// Professional tracking interface optimized for:
/// - Mobile (Portrait & Landscape)
/// - Tablet (Adaptive layout)
/// - Desktop (Multi-panel view)
/// - Web (Responsive design)
///
/// Features:
/// - Real-time vehicle tracking with Google Maps
/// - Driver status monitoring
/// - On-demand location requests
/// - Connection status indicator
/// - Responsive adaptive layout
/// - Smooth animations and transitions
/// - Load vehicles from server
class LiveTrackingMonitorScreen extends StatefulWidget {
  final int dispatcherId;
  final LiveTrackingService trackingService;
  final VehicleRemoteDataSource? vehicleDataSource;

  const LiveTrackingMonitorScreen({
    super.key,
    required this.dispatcherId,
    required this.trackingService,
    this.vehicleDataSource,
  });

  @override
  State<LiveTrackingMonitorScreen> createState() =>
      _LiveTrackingMonitorScreenState();
}

class _LiveTrackingMonitorScreenState extends State<LiveTrackingMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TrackingMonitorCubit _cubit;
  bool _isDrawerOpen = false;
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;

  // Stream subscriptions
  StreamSubscription<VehiclePosition>? _vehiclePositionSubscription;
  StreamSubscription<DriverLocation>? _locationResponseSubscription;
  StreamSubscription<DriverStatusUpdate>? _driverStatusSubscription;
  StreamSubscription<bool>? _connectionStatusSubscription;

  // UI State
  bool _isConnected = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  // Layout responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  @override
  void initState() {
    super.initState();
    _cubit = TrackingMonitorCubit(
      trackingService: widget.trackingService,
      vehicleDataSource: widget.vehicleDataSource,
    );
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _drawerAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _initializeTracking();
  }

  Future<void> _initializeTracking({bool isRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (!isRefresh) {
        _isLoading = true;
      }
      _isRefreshing = isRefresh;
      _errorMessage = null;
    });

    try {
      // Load vehicles from server first
      await _cubit.loadVehiclesFromServer();

      // Connect to WebSocket
      await widget.trackingService.connect(userId: widget.dispatcherId);

      // Subscribe to live tracking
      await widget.trackingService.subscribeLiveTracking();

      // Setup stream listeners
      _setupStreamListeners();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _isConnected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = 'Failed to connect: $e';
        });
      }
    }
  }

  void _setupStreamListeners() {
    _clearStreamListeners();

    // Listen to vehicle position updates
    _vehiclePositionSubscription = widget.trackingService.vehiclePositionStream
        .listen(
          (position) {
            _cubit.onVehiclePositionUpdate(position);
          },
          onError: (error) {
            debugPrint('Vehicle position stream error: $error');
          },
        );

    // Listen to location responses
    _locationResponseSubscription = widget
        .trackingService
        .locationResponseStream
        .listen((location) {
          _cubit.onDriverLocationUpdate(location);
        });

    // Listen to driver status updates
    _driverStatusSubscription = widget.trackingService.driverStatusStream
        .listen((statusUpdate) {
          _cubit.onDriverStatusUpdate(statusUpdate);
        });

    // Listen to connection status
    _connectionStatusSubscription = widget
        .trackingService
        .connectionStatusStream
        .listen((isConnected) {
          if (mounted) {
            setState(() {
              _isConnected = isConnected;
            });

            // Haptic feedback on connection change
            if (isConnected) {
              HapticFeedback.mediumImpact();
            }
          }
        });
  }

  @override
  void dispose() {
    _clearStreamListeners();
    widget.trackingService.disconnect();
    _drawerAnimationController.dispose();
    _cubit.dispose();
    super.dispose();
  }

  void _clearStreamListeners() {
    _vehiclePositionSubscription?.cancel();
    _vehiclePositionSubscription = null;
    _locationResponseSubscription?.cancel();
    _locationResponseSubscription = null;
    _driverStatusSubscription?.cancel();
    _driverStatusSubscription = null;
    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = null;
  }

  void _toggleDrawer() {
    if (!mounted) return;
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        // Drawer opens from right (value goes from 1.0 to 0.0)
        _drawerAnimationController.forward();
      } else {
        // Drawer closes to right (value goes from 0.0 to 1.0)
        _drawerAnimationController.reverse();
      }
    });
  }

  void _closeDrawer() {
    if (!mounted) return;
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
        // Close drawer - slide to right (off screen)
        _drawerAnimationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading;
    final errorMessage = _errorMessage;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawerEdgeDragWidth: 0, // Disable left drawer swipe
          body: isLoading
              ? _buildLoadingView()
              : errorMessage != null
              ? _buildErrorView()
              : _buildResponsiveLayout(context),
        ),
        // Custom drawer from right
        if (!isLoading && errorMessage == null) _buildCustomRightDrawer(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Semantics(
      label: 'Connecting to tracking service',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connecting to tracking service...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Semantics(
      label: 'Connection failed',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
                semanticLabel: 'Error icon',
              ),
              const SizedBox(height: 16),
              Text(
                'Connection Failed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _initializeTracking();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Determine layout type based on screen size and orientation
    if (screenWidth >= _desktopBreakpoint ||
        (screenWidth >= _tabletBreakpoint && isLandscape)) {
      return _buildDesktopLayout();
    } else if (screenWidth >= _mobileBreakpoint) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // ---------------------------------------------------------------------------
  // Desktop layout (wide screens, multi-panel)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),

        // Main Content - Map
        Expanded(
          child: Column(
            children: [
              ConnectionStatusIndicator(isConnected: _isConnected),
              Expanded(
                child: Stack(
                  children: [
                    TrackingMapWidget(
                      cubit: _cubit,
                      companyLocation: CompanyConfig.defaultLocation,
                    ),

                    // Floating Controls (Top Right)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: TrackingControls(
                        cubit: _cubit,
                        onRefresh: () => _initializeTracking(isRefresh: true),
                        isRefreshing: _isRefreshing,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // right Panel - Driver List with padding to avoid system sidebar
        Container(
          width: 350,
          margin: const EdgeInsets.only(
            left: 8,
          ), // Add margin to avoid system sidebar
          child: Column(
            children: [
              _buildTopBar(showMenuButton: false),
              Expanded(
                child: DriverListPanel(
                  cubit: _cubit,
                  onDriverSelected: (driver) {
                    _cubit.selectDriver(driver);
                    HapticFeedback.selectionClick();
                  },
                  onRequestLocation: (driverId) async {
                    await _cubit.requestDriverLocation(driverId);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tablet layout (medium screens, adaptive)
  // ---------------------------------------------------------------------------
  Widget _buildTabletLayout() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLandscape && screenWidth >= _tabletBreakpoint) {
      // Landscape: Side-by-side layout
      return Row(
        children: [
          Container(
            width: 300,
            margin: const EdgeInsets.only(left: 8),
            child: Column(
              children: [
                _buildTopBar(showMenuButton: false),
                Expanded(
                  child: DriverListPanel(
                    cubit: _cubit,
                    onDriverSelected: (driver) {
                      _cubit.selectDriver(driver);
                      HapticFeedback.selectionClick();
                    },
                    onRequestLocation: (driverId) async {
                      await _cubit.requestDriverLocation(driverId);
                    },
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(child: _buildMapWithControls()),
        ],
      );
    } else {
      // Portrait: EndDrawer layout (from right)
      return Column(
        children: [
          _buildTopBar(showMenuButton: true),
          Expanded(child: _buildMapWithControls()),
        ],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mobile layout (small screens, drawer-based)
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildTopBar(showMenuButton: true),
        Expanded(child: _buildMapWithControls()),
      ],
    );
  }

  Widget _buildMapWithControls() {
    return Column(
      children: [
        ConnectionStatusIndicator(isConnected: _isConnected),
        Expanded(
          child: Stack(
            children: [
              TrackingMapWidget(
                cubit: _cubit,
                companyLocation: CompanyConfig.defaultLocation,
              ),

              // Floating Controls
              Positioned(
                top: 16,
                right: 16,
                child: TrackingControls(
                  cubit: _cubit,
                  onRefresh: () => _initializeTracking(isRefresh: true),
                  isRefreshing: _isRefreshing,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar({required bool showMenuButton}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final barHeight = isSmallScreen ? 56.0 : 64.0;

    return Semantics(
      label: 'Live Tracking Monitor header',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: barHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showMenuButton) ...[
              // Menu button on the right side to open endDrawer (from right)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: 'Open drivers list',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _toggleDrawer();
                },
              ),
              const SizedBox(width: 8),
            ] else
              const SizedBox(width: 16),

            Icon(
              Icons.location_on,
              color: Colors.white.withOpacity(0.9),
              size: 28,
              semanticLabel: 'Location icon',
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Tracking Monitor',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: _cubit.activeVehiclesCountStream,
                    initialData: 0,
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data! : 0;
                      debugPrint('📊 Header active vehicles count: $count');
                      return Text(
                        '$count active ${count == 1 ? 'vehicle' : 'vehicles'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Connection indicator with tooltip
            Tooltip(
              message: _isConnected ? 'Connected' : 'Disconnected',
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isConnected ? Colors.greenAccent : Colors.redAccent)
                              .withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRightDrawer() {
    // Only show drawer in mobile and tablet portrait layouts
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Hide drawer in desktop and tablet landscape (they use fixed panels)
    if (screenWidth >= _desktopBreakpoint ||
        (screenWidth >= _tabletBreakpoint && isLandscape)) {
      return const SizedBox.shrink();
    }

    final drawerWidth = screenWidth > _mobileBreakpoint
        ? (screenWidth * 0.85).clamp(320.0, 400.0)
        : screenWidth * 0.85;

    return AnimatedBuilder(
      animation: _drawerSlideAnimation,
      builder: (context, child) {
        // Don't render drawer when fully closed to avoid blocking interactions
        if (!_isDrawerOpen && _drawerSlideAnimation.value == 1.0) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Backdrop
            if (_isDrawerOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(
                    color: Colors.black.withOpacity(
                      0.5 * (1 - _drawerSlideAnimation.value),
                    ),
                  ),
                ),
              ),

            // Drawer slides in from the right.
            Positioned(
              right:
                  -drawerWidth *
                  _drawerSlideAnimation
                      .value, // 0 when open, -drawerWidth when closed
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: Material(
                elevation: 16,
                shadowColor: Colors.black.withOpacity(0.3),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: GestureDetector(
                  onTap:
                      () {}, // Prevent tap from closing when clicking inside drawer
                  child: Column(
                    children: [
                      // Simple close button bar (unified with panel header)
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Close',
                              onPressed: _closeDrawer,
                            ),
                          ],
                        ),
                      ),
                      // Drawer content (uses DriverListPanel's own header)
                      Expanded(
                        child: DriverListPanel(
                          cubit: _cubit,
                          onDriverSelected: (driver) {
                            _cubit.selectDriver(driver);
                            HapticFeedback.selectionClick();
                            _closeDrawer();
                          },
                          onRequestLocation: (driverId) async {
                            await _cubit.requestDriverLocation(driverId);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
