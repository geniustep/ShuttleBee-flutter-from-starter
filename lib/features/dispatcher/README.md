# Dispatcher Module - Live Tracking Monitor

Professional fleet tracking interface with real-time GPS monitoring, optimized for all platforms.

## 🎯 Features

### Core Features
- ✅ Real-time vehicle position tracking via WebSocket
- ✅ Driver status monitoring (Online, Offline, On Trip, Available, Busy)
- ✅ On-demand location requests for drivers
- ✅ Automatic reconnection with exponential backoff
- ✅ Connection status indicators
- ✅ Vehicle filtering and search
- ✅ Sort by name, status, or last update

### Platform Optimizations
- ✅ **Mobile** (Portrait & Landscape): Drawer-based layout with full-screen map
- ✅ **Tablet**: Adaptive layout switching between drawer and side-by-side
- ✅ **Desktop**: Multi-panel layout with persistent driver list
- ✅ **Web**: Fully responsive with optimized controls

### UI/UX Features
- ✅ Smooth animations and transitions
- ✅ Real-time status color indicators
- ✅ Time since last update display
- ✅ Filter chips for quick vehicle filtering
- ✅ Search functionality
- ✅ Loading and error states
- ✅ Empty states with helpful messages

## 📱 Responsive Breakpoints

```dart
Mobile:   < 600px   - Drawer layout, compact controls
Tablet:   600-1200px - Adaptive based on orientation
Desktop:  > 1200px  - Multi-panel persistent layout
```

## 🚀 Quick Start

### 1. Basic Usage

```dart
import 'package:bridgecore_flutter/src/dispatcher/dispatcher.dart';

// In your router or navigation
final trackingService = BridgeCore.instance.liveTracking;

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LiveTrackingMonitorScreen(
      dispatcherId: currentUserId,
      trackingService: trackingService,
    ),
  ),
);
```

### 2. GoRouter Integration

```dart
import 'package:go_router/go_router.dart';
import 'package:bridgecore_flutter/src/dispatcher/dispatcher.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/dispatcher/monitor',
      builder: (context, state) {
        final trackingService = BridgeCore.instance.liveTracking;
        final userId = // Get from auth state

        return LiveTrackingMonitorScreen(
          dispatcherId: userId,
          trackingService: trackingService,
        );
      },
    ),
  ],
);
```

### 3. With Custom Theme

```dart
MaterialApp(
  theme: ThemeData(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[50],
    // ... your theme
  ),
  home: LiveTrackingMonitorScreen(
    dispatcherId: userId,
    trackingService: trackingService,
  ),
);
```

## 🗺️ Google Maps Integration

The module includes a placeholder map widget. To enable real Google Maps:

### Step 1: Add Dependencies

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.0  # For web support
  google_maps_flutter_platform_interface: ^2.4.0
```

### Step 2: Configure API Keys

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest>
  <application>
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_ANDROID_API_KEY"/>
  </application>
</manifest>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Web** (`web/index.html`):
```html
<head>
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY"></script>
</head>
```

### Step 3: Update TrackingMapWidget

In `tracking_map_widget.dart`, uncomment the Google Maps implementation and replace the placeholder.

## 🎨 Customization

### Custom Marker Icons

```dart
// In tracking_map_widget.dart
BitmapDescriptor _getMarkerIcon(TrackedVehicle vehicle) {
  if (vehicle.isOnTrip) {
    return BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/markers/vehicle_active.png',
    );
  }
  return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
}
```

### Custom Map Style

Create `assets/map_style.json`:
```json
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  }
]
```

### Custom Status Colors

In `tracked_vehicle.dart`, modify `statusColor` getter:
```dart
VehicleStatusColor get statusColor {
  // Your custom logic
}
```

## 📊 State Management

### TrackingMonitorCubit

Central state management for the monitor screen:

```dart
final cubit = TrackingMonitorCubit(trackingService: trackingService);

// Listen to vehicle updates
cubit.vehiclesStream.listen((vehicles) {
  print('Active vehicles: ${vehicles.length}');
});

// Select a vehicle
cubit.selectDriver(vehicle);

// Request location
await cubit.requestDriverLocation(driverId);

// Filter vehicles
cubit.setFilter(VehicleFilter.onTrip);

// Fit all vehicles on map
cubit.fitAllVehicles();

// Cleanup
cubit.dispose();
```

### Streams Available

```dart
Stream<Map<int, TrackedVehicle>> vehiclesStream
Stream<TrackedVehicle?> selectedVehicleStream
Stream<MapBounds?> mapBoundsStream
Stream<int> activeVehiclesCountStream
Stream<VehicleFilter> filterStream
```

## 🔧 Architecture

```
lib/src/dispatcher/
├── presentation/
│   ├── screens/
│   │   └── live_tracking_monitor_screen.dart   # Main screen with responsive layouts
│   ├── widgets/
│   │   ├── tracking_map_widget.dart            # Google Maps integration
│   │   ├── driver_list_panel.dart              # Driver/vehicle list with filters
│   │   ├── tracking_controls.dart              # Floating map controls
│   │   └── connection_status_indicator.dart    # Connection status banner
│   ├── bloc/
│   │   └── tracking_monitor_cubit.dart         # State management
│   └── models/
│       ├── tracked_vehicle.dart                # Vehicle data model
│       └── map_bounds.dart                     # Map bounds helper
├── dispatcher.dart                              # Public API exports
└── README.md                                    # This file
```

## 🎯 Layout Behavior

### Mobile (< 600px)
```
┌─────────────────┐
│   Top Bar       │
├─────────────────┤
│                 │
│                 │
│    Full Map     │
│                 │
│                 │
└─────────────────┘
  [Drawer Menu]
```

### Tablet Landscape (600-1200px)
```
┌──────┬──────────────┐
│ List │   Top Bar    │
│      ├──────────────┤
│      │              │
│      │     Map      │
│      │              │
└──────┴──────────────┘
```

### Desktop (> 1200px)
```
┌────────┬──────────────┐
│ Driver │   Top Bar    │
│  List  ├──────────────┤
│        │              │
│ Filter │     Map      │
│ Search │   +Controls  │
│        │              │
└────────┴──────────────┘
```

## 🔌 WebSocket Events

The module automatically handles:

- `vehicle.position` - Real-time GPS updates
- `location_response` - Driver location responses
- `driver_status` - Status changes
- `trip_update` - Trip state changes
- Auto-reconnection on disconnect

## 🎨 Theming

Respects your app's theme:
- `primaryColor` - Accent colors, buttons, selected items
- `scaffoldBackgroundColor` - Background
- `cardColor` - Cards and elevated surfaces
- `textTheme` - All text styles

## 📝 Best Practices

1. **Connection Management**: Always connect before showing the screen
2. **Cleanup**: Dispose cubit when screen is disposed
3. **Error Handling**: Handle WebSocket connection errors gracefully
4. **Performance**: Use filtering to reduce rendered markers
5. **UX**: Show loading states during connection
6. **Accessibility**: All buttons have proper tooltips

## 🐛 Troubleshooting

### No vehicles showing
- Check WebSocket connection status
- Verify dispatcher has subscribed to live tracking
- Check if vehicles are sending GPS updates

### Map not loading
- Verify Google Maps API keys are configured
- Check internet connectivity
- Ensure google_maps_flutter is added to dependencies

### Poor performance
- Enable marker clustering for 50+ vehicles
- Reduce update frequency if needed
- Use filtering to show only relevant vehicles

## 📄 License

Part of BridgeCore Flutter SDK
