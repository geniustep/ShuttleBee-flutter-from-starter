# ⚡ Quick Start Guide - 5 Minutes to Live Tracking

Get your dispatcher tracking monitor running in under 5 minutes!

## 🚀 Step 1: Import (30 seconds)

Add to your Dart file:
```dart
import 'package:bridgecore_flutter/src/dispatcher/dispatcher.dart';
```

## 🚀 Step 2: Navigate (1 minute)

Choose your method:

### Option A: Direct Navigation (Simplest)
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingMonitorScreen(
          dispatcherId: 1, // Your user ID
          trackingService: BridgeCore.instance.liveTracking,
        ),
      ),
    );
  },
  child: Text('Open Tracking'),
)
```

### Option B: GoRouter
```dart
// 1. Add to routes
GoRoute(
  path: '/dispatcher/monitor',
  builder: (context, state) => LiveTrackingMonitorScreen(
    dispatcherId: state.extra as int,
    trackingService: BridgeCore.instance.liveTracking,
  ),
)

// 2. Navigate
context.go('/dispatcher/monitor', extra: userId);
```

## 🚀 Step 3: Run (30 seconds)

```bash
flutter run
```

## ✅ Done!

You now have:
- ✅ Real-time vehicle tracking
- ✅ Responsive UI (Mobile/Tablet/Desktop)
- ✅ Driver list with filters
- ✅ Connection status indicator
- ✅ Auto-reconnection

## 🎨 Optional: Add Google Maps (3 minutes)

### 1. Add dependency
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
```

### 2. Add API key

**Android:** `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_KEY_HERE" />
```

**iOS:** `ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("YOUR_KEY_HERE")
```

**Web:** `web/index.html`
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY_HERE"></script>
```

### 3. Uncomment Google Maps code
In `lib/src/dispatcher/presentation/widgets/tracking_map_widget.dart`:
- Line ~120: Uncomment `GoogleMap` widget
- Line ~80: Uncomment marker creation

## 📱 Test on Different Devices

- **Mobile:** Portrait mode → Drawer layout
- **Tablet:** Landscape mode → Side-by-side
- **Desktop:** Full screen → Multi-panel

## 🎯 What's Working

| Feature | Status |
|---------|--------|
| WebSocket connection | ✅ |
| Real-time updates | ✅ |
| Responsive layout | ✅ |
| Driver list | ✅ |
| Search & filter | ✅ |
| Auto-reconnect | ✅ |
| Google Maps | ⏳ (after setup) |

## 🆘 Troubleshooting

### No vehicles showing?
- Check WebSocket connection (green dot in header)
- Ensure backend is sending vehicle updates

### Map not loading?
- Using placeholder until Google Maps configured
- Follow "Optional: Add Google Maps" above

### Connection failed?
- Check `BridgeCore.instance` is initialized
- Verify base URL is correct

## 📚 Next Steps

1. ✅ You're done! Everything works out of the box
2. 📖 Read [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) for customization
3. 🎨 Check [example.dart](example.dart) for more patterns
4. 🗺️ Configure Google Maps for real maps

## 💡 Pro Tips

- The module uses your app's existing theme
- Connection auto-retries on failure
- Filter vehicles with chips (All, Online, On Trip, etc.)
- Search works on vehicle name, driver name, license plate
- Tap vehicle in list to center map

---

**That's it!** 🎉 You have a professional tracking monitor running!

Need more details? Check:
- [README.md](README.md) - Full documentation
- [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - Detailed setup
- [example.dart](example.dart) - Code examples
