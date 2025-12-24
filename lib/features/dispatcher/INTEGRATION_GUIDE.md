# 🚀 Integration Guide - Live Tracking Monitor

Complete step-by-step guide to integrate the dispatcher tracking module in your Flutter app.

## 📋 Prerequisites

- Flutter SDK ≥ 3.0.0
- BridgeCore Flutter package configured
- Active WebSocket connection to BridgeCore backend

## 🔧 Installation

### Step 1: Import the Module

```dart
import 'package:bridgecore_flutter/src/dispatcher/dispatcher.dart';
```

### Step 2: Basic Setup

The module uses the existing `LiveTrackingService` from BridgeCore, no additional setup needed!

```dart
final trackingService = BridgeCore.instance.liveTracking;
```

## 🎯 Integration Methods

### Method 1: Direct Navigation (Simplest)

```dart
// In any button/menu item
ElevatedButton(
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
  child: const Text('Open Tracking'),
)
```

### Method 2: Named Routes (MaterialApp)

**1. Define routes:**
```dart
MaterialApp(
  routes: {
    '/': (context) => HomePage(),
    '/dispatcher/monitor': (context) => LiveTrackingMonitorScreen(
      dispatcherId: 1, // Get from auth
      trackingService: BridgeCore.instance.liveTracking,
    ),
  },
)
```

**2. Navigate:**
```dart
Navigator.pushNamed(context, '/dispatcher/monitor');
```

### Method 3: GoRouter (Recommended for Large Apps)

**1. Add dependency:**
```yaml
dependencies:
  go_router: ^13.0.0
```

**2. Configure router:**
```dart
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomePage(),
    ),
    GoRoute(
      path: '/dispatcher/monitor',
      builder: (context, state) {
        final userId = state.extra as int? ?? 1;

        return LiveTrackingMonitorScreen(
          dispatcherId: userId,
          trackingService: BridgeCore.instance.liveTracking,
        );
      },
    ),
  ],
);
```

**3. Use MaterialApp.router:**
```dart
MaterialApp.router(
  routerConfig: router,
  title: 'Fleet Tracking',
)
```

**4. Navigate:**
```dart
// By path
context.go('/dispatcher/monitor');

// With data
context.go('/dispatcher/monitor', extra: userId);
```

## 🗺️ Google Maps Setup (Optional but Recommended)

### Step 1: Add Dependencies

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.0  # For web
```

### Step 2: Get API Keys

Visit [Google Cloud Console](https://console.cloud.google.com/):

1. Create a project
2. Enable **Maps SDK for Android**, **Maps SDK for iOS**, and **Maps JavaScript API**
3. Create API credentials

### Step 3: Configure Platforms

#### Android
**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
  <application>
    <!-- Add before </application> -->
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_ANDROID_API_KEY" />
  </application>
</manifest>
```

#### iOS
**File:** `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter
import GoogleMaps  // Add this

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add this line
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**File:** `ios/Podfile`

Ensure minimum iOS version:
```ruby
platform :ios, '12.0'
```

#### Web
**File:** `web/index.html`

```html
<head>
  <!-- Add before </head> -->
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY"></script>
</head>
```

### Step 4: Update TrackingMapWidget

In `lib/src/dispatcher/presentation/widgets/tracking_map_widget.dart`:

1. Uncomment the Google Maps imports
2. Uncomment the `GoogleMap` widget in build method
3. Uncomment marker creation code

## 🎨 Customization

### Theme Integration

The module automatically uses your app's theme:

```dart
MaterialApp(
  theme: ThemeData(
    primaryColor: Colors.blue,        // Used for accents, buttons
    scaffoldBackgroundColor: Colors.grey[50],
    cardColor: Colors.white,
    textTheme: TextTheme(...),        // Used for all text
  ),
  // ...
)
```

### Custom Colors

Override specific colors in `tracked_vehicle.dart`:

```dart
Color _getStatusColor() {
  switch (vehicle.statusColor) {
    case VehicleStatusColor.onTrip:
      return const Color(0xFF00C853);  // Your custom green
    case VehicleStatusColor.available:
      return const Color(0xFF2196F3);  // Your custom blue
    // ...
  }
}
```

### Custom Markers

Create marker assets and update `tracking_map_widget.dart`:

```dart
Future<BitmapDescriptor> _getMarkerIcon(TrackedVehicle vehicle) async {
  if (vehicle.isOnTrip) {
    return BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/markers/truck_active.png',
    );
  }
  return BitmapDescriptor.defaultMarker;
}
```

### Custom Map Style

1. Create `assets/map_style.json`:
```json
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  }
]
```

2. Apply in `tracking_map_widget.dart`:
```dart
void _setMapStyle(GoogleMapController controller) async {
  final style = await rootBundle.loadString('assets/map_style.json');
  controller.setMapStyle(style);
}
```

## 🔐 Authentication Integration

### Example with Provider/Riverpod

```dart
class AuthState {
  final int? userId;
  final bool isAuthenticated;
  final List<String> roles;

  bool get isDispatcher => roles.contains('dispatcher');
}

// In your widget
Consumer(
  builder: (context, ref, child) {
    final auth = ref.watch(authProvider);

    if (!auth.isDispatcher) {
      return UnauthorizedScreen();
    }

    return LiveTrackingMonitorScreen(
      dispatcherId: auth.userId!,
      trackingService: BridgeCore.instance.liveTracking,
    );
  },
)
```

### Example with Bloc

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is! Authenticated || !state.hasDispatcherRole) {
      return UnauthorizedScreen();
    }

    return LiveTrackingMonitorScreen(
      dispatcherId: state.userId,
      trackingService: BridgeCore.instance.liveTracking,
    );
  },
)
```

## 📱 Platform-Specific Configurations

### Android: Permissions

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS: Permissions

**File:** `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby vehicles</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to track vehicle positions</string>
```

### Web: CORS

Ensure your backend allows WebSocket connections from your web domain.

## 🧪 Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/src/dispatcher/dispatcher.dart';

void main() {
  test('TrackedVehicle status color', () {
    final vehicle = TrackedVehicle(
      vehicleId: 1,
      driverId: 1,
      driverName: 'Test Driver',
      vehicleName: 'Test Vehicle',
      lastUpdateTime: DateTime.now(),
      isOnline: true,
      tripId: 123, // On trip
    );

    expect(vehicle.statusColor, VehicleStatusColor.onTrip);
  });
}
```

### Widget Tests

```dart
testWidgets('LiveTrackingMonitorScreen loads', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LiveTrackingMonitorScreen(
        dispatcherId: 1,
        trackingService: mockTrackingService,
      ),
    ),
  );

  expect(find.text('Live Tracking Monitor'), findsOneWidget);
});
```

## 🐛 Troubleshooting

### Issue: WebSocket not connecting

**Solution:**
- Check BridgeCore base URL configuration
- Verify network connectivity
- Check backend WebSocket endpoint is running
- Review connection logs in debug console

### Issue: Vehicles not appearing

**Solution:**
- Ensure dispatcher has subscribed: `trackingService.subscribeLiveTracking()`
- Check that vehicles are sending GPS updates
- Verify WebSocket connection is active
- Check filter settings (not filtering out all vehicles)

### Issue: Google Maps not showing

**Solution:**
- Verify API keys are correctly configured
- Check API key has proper restrictions/permissions
- Ensure billing is enabled on Google Cloud project
- Check platform-specific setup (Android/iOS/Web)

### Issue: Poor performance with many vehicles

**Solution:**
- Implement marker clustering (google_maps_cluster_manager)
- Reduce GPS update frequency
- Use vehicle filtering
- Optimize marker icon size

## 📊 Performance Best Practices

1. **Marker Clustering**: For 50+ vehicles
2. **Update Throttling**: Limit map updates to 1-2 per second
3. **Lazy Loading**: Load vehicle details on demand
4. **Memory Management**: Dispose cubit properly
5. **Network Optimization**: Use WebSocket compression

## 🔗 Useful Links

- [Google Maps Flutter Documentation](https://pub.dev/packages/google_maps_flutter)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [BridgeCore API Documentation](https://bridgecore.dev/docs)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

## 💡 Tips

- Always dispose the cubit when screen is disposed
- Use connection status indicator for user feedback
- Implement proper error handling for WebSocket disconnections
- Test on real devices for accurate GPS behavior
- Use the filter feature to reduce visual clutter
- Consider implementing route polylines for trips

## 🎓 Next Steps

1. Review the example files in `example.dart` and `go_router_example.dart`
2. Customize the UI to match your brand
3. Add custom markers and map styles
4. Implement additional features (routes, geofences, etc.)
5. Set up proper error tracking and analytics

---

Need help? Check the README.md or open an issue!
