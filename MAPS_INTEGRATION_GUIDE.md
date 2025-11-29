# 🗺️ دليل تكامل الخرائط - ShuttleBee

## 🎨 الحلول المبدعة المتاحة

### 1️⃣ **Mapbox (موصى به)** ✨
```yaml
# Already added to pubspec.yaml
mapbox_maps_flutter: ^2.3.0
```

**الميزات:**
- ✅ تخصيص كامل للألوان والأيقونات
- ✅ 3D buildings و terrain
- ✅ أداء ممتاز مع offline maps
- ✅ Free tier: 50,000 مستخدم نشط/شهر
- ✅ Custom map styles من Mapbox Studio

**التكلفة:** مجاني حتى 50K MAU، ثم $5 لكل 1000 MAU

---

### 2️⃣ **Google Maps** (تقليدي لكن موثوق)
```yaml
google_maps_flutter: ^2.5.0
```

**الميزات:**
- ✅ معروف للجميع
- ✅ دقة عالية
- ✅ Street View
- ✅ Places API

**التكلفة:** $7 لكل 1000 مرة تحميل خريطة

---

### 3️⃣ **Flutter Map + OpenStreetMap** (مجاني تماماً)
```yaml
flutter_map: ^6.1.0
```

**الميزات:**
- ✅ مجاني 100%
- ✅ Open source
- ✅ تخصيص كامل
- ❌ يحتاج إلى المزيد من العمل

---

## 🚀 التنفيذ المبدع (Mapbox)

### المرحلة 1: الإعداد الأولي

#### 1. الحصول على Access Token من Mapbox

```bash
# 1. سجل في Mapbox
https://account.mapbox.com/auth/signup/

# 2. احصل على Access Token
https://account.mapbox.com/access-tokens/
```

#### 2. إضافة Token للتطبيق

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<application>
    <meta-data
        android:name="com.mapbox.token"
        android:value="YOUR_MAPBOX_ACCESS_TOKEN" />
</application>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>MBXAccessToken</key>
<string>YOUR_MAPBOX_ACCESS_TOKEN</string>
```

**.env file** (الطريقة الآمنة):
```env
MAPBOX_ACCESS_TOKEN=your_token_here
```

---

### المرحلة 2: استخدام الخدمات المتقدمة

#### ✅ MapService (موجود بالفعل)

```dart
import 'package:shuttlebee/core/services/map_service.dart';

final mapService = MapService();

// 1. Live Tracking
final positionStream = mapService.watchPosition();
positionStream.listen((position) {
  print('الموقع الحالي: ${position.latitude}, ${position.longitude}');
});

// 2. حساب المسافة
final distance = mapService.calculateDistance(
  LatLng(24.7136, 46.6753), // الرياض
  LatLng(24.5247, 46.7184), // الدرعية
);
print('المسافة: ${mapService.formatDistance(distance)}');

// 3. حساب ETA
final eta = mapService.calculateETAWithTraffic(
  startPoint,
  endPoint,
  trafficMultiplier: 1.3, // مرور كثيف
);
print('الوقت المتوقع: ${mapService.formatDuration(eta)}');

// 4. تحسين المسار
final optimizedRoute = mapService.optimizeRoute(
  startPoint,
  passengerStops,
);

// 5. Geofencing
final geofenceStream = mapService.watchGeofence(
  positionStream,
  schoolLocation,
  100, // 100 meters radius
);

geofenceStream.listen((event) {
  if (event.type == GeofenceEventType.enter) {
    print('دخل المنطقة! 🎯');
    // Send notification
  }
});

// 6. Geocoding
final address = await mapService.getAddressFromLatLng(24.7136, 46.6753);
print('العنوان: $address');

final coords = await mapService.getLatLngFromAddress('الرياض، السعودية');
print('الإحداثيات: $coords');
```

---

### المرحلة 3: Custom Map Styles و Markers

#### ✅ استخدام Custom Markers (موجود بالفعل)

```dart
import 'package:shuttlebee/core/constants/map_styles.dart';

// 1. Driver Marker (متحرك)
MapMarkers.driverMarker(
  bearing: 45, // الاتجاه
  isActive: true,
);

// 2. Passenger Marker
MapMarkers.passengerMarker(
  status: 'boarded', // boarded, absent, pending
  label: 'أحمد',
);

// 3. Stop Marker
MapMarkers.stopMarker(
  label: 'محطة 1',
  isSchool: false,
);

// 4. ETA Badge
MapMarkers.etaBadge(
  minutes: 15,
  distance: 3.5,
);

// 5. Route Progress
MapMarkers.routeProgress(
  completed: 5,
  total: 10,
);
```

---

### المرحلة 4: تنفيذ الخريطة الفعلية

#### مثال: Integration مع Mapbox

```dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class LiveTripMapWidget extends StatefulWidget {
  @override
  State<LiveTripMapWidget> createState() => _LiveTripMapWidgetState();
}

class _LiveTripMapWidgetState extends State<LiveTripMapWidget> {
  MapboxMap? _mapboxMap;

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      styleUri: MapStyles.shuttlebeeStreets,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(46.6753, 24.7136)), // Riyadh
        zoom: 14.0,
      ),
      onMapCreated: (MapboxMap mapboxMap) {
        _mapboxMap = mapboxMap;
        _initializeMap();
      },
    );
  }

  Future<void> _initializeMap() async {
    // Add driver marker
    await _mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
      manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(46.6753, 24.7136)),
          iconImage: 'bus-icon',
          iconSize: 2.0,
        ),
      );
    });

    // Add route line
    await _mapboxMap?.annotations.createPolylineAnnotationManager().then((manager) {
      manager.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: routeCoordinates),
          lineColor: Colors.blue.value,
          lineWidth: 5.0,
        ),
      );
    });
  }
}
```

---

## 🎯 الميزات المتقدمة المنفذة

### 1. **Live GPS Tracking** ✅
```dart
// في driver_live_trip_map_screen.dart
_positionSubscription = _mapService.watchPosition().listen((position) {
  setState(() {
    _currentPosition = position;
    _updateETA();
    _checkGeofence(position);
  });
});
```

### 2. **Animated Markers** ✅
```dart
// في map_styles.dart
Transform.rotate(
  angle: bearing * 3.14159 / 180,
  child: MapMarkers.driverMarker(bearing: bearing),
);
```

### 3. **Route Optimization** ✅
```dart
final optimizedStops = mapService.optimizeRoute(
  currentLocation,
  pendingStops,
);
```

### 4. **Geofencing** ✅
```dart
final isNear = mapService.isWithinGeofence(
  currentLocation,
  stopLocation,
  100, // meters
);

if (isNear) {
  _showNotification('اقتربت من المحطة!');
}
```

### 5. **ETA Calculation** ✅
```dart
final eta = mapService.calculateETAWithTraffic(
  from,
  to,
  trafficMultiplier: 1.3,
);
```

---

## 🎨 Custom Map Styling (Mapbox Studio)

### الخطوات:

1. **انتقل إلى Mapbox Studio**
   ```
   https://studio.mapbox.com/
   ```

2. **أنشئ Style جديد**
   - اختر Template (Streets, Satellite، إلخ)
   - خصص الألوان
   - أضف Custom Icons
   - احفظ

3. **احصل على Style URL**
   ```
   mapbox://styles/YOUR_USERNAME/STYLE_ID
   ```

4. **استخدمه في التطبيق**
   ```dart
   static const String shuttlebeeCustom =
       'mapbox://styles/YOUR_USERNAME/STYLE_ID';
   ```

---

## 📱 سيناريوهات الاستخدام

### السيناريو 1: السائق يبدأ الرحلة
```dart
// 1. تحميل بيانات الرحلة
final trip = await tripRepository.getTripById(tripId);

// 2. بدء Live Tracking
final positionStream = mapService.watchPosition();

// 3. عرض الخريطة مع المسار
showMap(
  route: trip.lines.map((l) => LatLng(l.latitude, l.longitude)),
  driverLocation: currentPosition,
);

// 4. تحديث ETA لكل محطة
trip.lines.forEach((stop) {
  final eta = mapService.calculateETA(currentPosition, stop.location);
  updateStopETA(stop.id, eta);
});
```

### السيناريو 2: إشعار قرب المحطة
```dart
// Setup geofence لكل محطة
trip.lines.forEach((stop) {
  final geofenceStream = mapService.watchGeofence(
    positionStream,
    stop.location,
    100, // 100m radius
  );

  geofenceStream.listen((event) {
    if (event.type == GeofenceEventType.enter) {
      // Send notification to passenger
      notificationService.send(
        to: stop.passengerId,
        title: 'الحافلة اقتربت!',
        body: 'سيصل السائق خلال دقيقة واحدة',
      );

      // Vibrate driver's phone
      HapticFeedback.vibrate();

      // Show dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('محطة ${stop.passengerName}'),
          content: Text('أنت على بُعد ${distance}m'),
        ),
      );
    }
  });
});
```

### السيناريو 3: تتبع الراكب للحافلة
```dart
// في Passenger App
class PassengerTrackingScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Position>(
      stream: driverLocationStream, // من Firebase/WebSocket
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LoadingWidget();

        final driverLocation = snapshot.data!;
        final passengerLocation = myLocation;

        final distance = mapService.calculateDistance(
          driverLocation,
          passengerLocation,
        );

        final eta = mapService.calculateETA(
          driverLocation,
          passengerLocation,
        );

        return MapWidget(
          markers: [
            DriverMarker(location: driverLocation),
            PassengerMarker(location: passengerLocation),
          ],
          routeLine: routeBetween(driverLocation, passengerLocation),
          etaBadge: ETABadge(
            distance: distance,
            minutes: eta,
          ),
        );
      },
    );
  }
}
```

---

## 🔧 التكوينات المتقدمة

### Offline Maps (Mapbox)
```dart
// تحميل خريطة المنطقة للاستخدام دون إنترنت
await mapboxMap.tileStore.loadRegion(
  regionId: 'riyadh',
  geometry: RegionGeometry(
    type: GeometryType.polygon,
    coordinates: riyadhBoundary,
  ),
  zoom: 10,
  pixelRatio: 2.0,
);
```

### Traffic Layer
```dart
// إضافة طبقة المرور
await mapboxMap.style.addLayer(
  TrafficLayer(
    id: 'traffic',
    source: 'mapbox-traffic',
  ),
);
```

### Real-time Driver Updates
```dart
// WebSocket للتحديثات الفورية
final driverChannel = IOWebSocketChannel.connect(
  'wss://your-backend.com/driver/${driverId}',
);

driverChannel.stream.listen((position) {
  updateDriverMarker(
    LatLng(position['lat'], position['lng']),
    bearing: position['bearing'],
  );
});

// Send driver position
positionStream.listen((position) {
  driverChannel.sink.add({
    'lat': position.latitude,
    'lng': position.longitude,
    'bearing': position.heading,
    'speed': position.speed,
    'timestamp': DateTime.now().toIso8601String(),
  });
});
```

---

## 📊 مقارنة الحلول

| الميزة | Mapbox | Google Maps | Flutter Map |
|--------|---------|-------------|-------------|
| التخصيص | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| السعر | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| الأداء | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| الدقة | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Offline | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| التوثيق | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## 🎁 الميزات الإضافية المبدعة

### 1. **AR Navigation** (مستقبلي)
```dart
// استخدام AR لتوجيه السائق
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

ARView(
  onARViewCreated: (controller) {
    controller.addARObject(
      ARArrow(
        direction: nextStopDirection,
        distance: nextStopDistance,
      ),
    );
  },
);
```

### 2. **Heatmap لتحليل الرحلات**
```dart
// عرض المناطق الأكثر ازدحاماً
HeatmapLayer(
  data: tripHistory.map((trip) =>
    HeatPoint(
      latLng: trip.location,
      intensity: trip.delayMinutes,
    ),
  ),
);
```

### 3. **3D Buildings**
```dart
// عرض المباني بشكل 3D
mapboxMap.style.addLayer(
  FillExtrusionLayer(
    id: '3d-buildings',
    source: 'composite',
    minzoom: 15,
    paint: {
      'fill-extrusion-color': '#aaa',
      'fill-extrusion-height': ['get', 'height'],
      'fill-extrusion-base': ['get', 'min_height'],
    },
  ),
);
```

---

## 🚀 الخطوات التالية

1. ✅ **اختر الحل المناسب** (موصى به: Mapbox)
2. ✅ **احصل على API Token**
3. ✅ **أكمل integration في `driver_live_trip_map_screen.dart`**
4. ✅ **اختبر Live Tracking**
5. ✅ **أضف Geofencing Notifications**
6. ✅ **أضف Passenger Tracking View**
7. ✅ **نشر التطبيق!**

---

## 📚 موارد إضافية

- [Mapbox Documentation](https://docs.mapbox.com/flutter/)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Flutter Map Package](https://pub.dev/packages/flutter_map)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

---

**تم إعداده بواسطة Claude لـ ShuttleBee 🚌**
