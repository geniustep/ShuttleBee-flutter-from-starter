# إعداد Google Maps في التطبيق

تم إعداد `google_maps_flutter` بنجاح في التطبيق واستبدال Mapbox بـ Google Maps بالكامل.

## ما تم تنفيذه

### 1. إضافة الحزم
تم إضافة الحزم التالية إلى ملف `pubspec.yaml`:
- `google_maps_flutter: ^2.11.1`
- `geolocator: ^13.0.4`
- `geocoding: ^4.0.0`

### 2. إعداد Android

#### AndroidManifest.xml
تم إضافة مفتاح Google Maps API:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyA9lblOmPEN-Aa9oE_ET3cbqiapI6HhjSE" />
```

#### الأذونات المطلوبة
تم إضافة الأذونات التالية:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### build.gradle.kts
تم تحديث `minSdk` إلى 21 (وهو الحد الأدنى المطلوب لـ Google Maps)

### 3. الملفات المحدثة

#### MapService
- تم تحديث `lib/core/services/map_service.dart` لاستخدام `google_maps_flutter` بدلاً من `latlong2`
- جميع الدوال تعمل الآن مع `LatLng` من Google Maps
- تم الحفاظ على جميع الميزات: تتبع الموقع، حساب المسافة، ETA، Geofencing، إلخ

#### TripMapWidget
- تم إعادة كتابة `lib/features/driver/presentation/widgets/trip_map_widget.dart`
- استخدام `GoogleMap` widget بدلاً من `MapWidget` من Mapbox
- إضافة Markers ديناميكية للسائق والركاب
- إضافة Polylines لعرض المسار
- دعم Auto-fit bounds لعرض جميع النقاط

#### DriverLiveTripMapScreen
- تم تحديث `lib/features/driver/presentation/screens/driver_live_trip_map_screen.dart`
- يعمل الآن مع Google Maps بشكل كامل
- تتبع مباشر لموقع السائق
- حساب ETA والمسافة
- تنبيهات Geofencing عند الاقتراب من المحطات

### 4. الميزات المتاحة

✅ **Live GPS Tracking** - تتبع موقع السائق مباشرة
✅ **Animated Driver Marker** - علامة السائق متحركة ومتجهة
✅ **Passenger Markers** - علامات الركاب بألوان حسب الحالة
✅ **Route Drawing** - رسم المسار بين النقاط
✅ **ETA Calculation** - حساب الوقت المتوقع للوصول
✅ **Geofencing** - تنبيهات عند الاقتراب من المحطات
✅ **Auto-Zoom** - تكبير تلقائي لعرض المسار كاملاً

## كيفية الاستخدام

### استخدام بسيط:

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(33.3152, 44.3661), // بغداد
    zoom: 12.0,
  ),
  onMapCreated: (GoogleMapController controller) {
    // يمكنك التحكم بالخريطة هنا
  },
)
```

### استخدام TripMapWidget:

```dart
import 'package:bridgecore_flutter_starter/features/driver/presentation/widgets/trip_map_widget.dart';

TripMapWidget(
  trip: trip, // كائن Trip
  currentPosition: currentPosition, // موقع السائق الحالي
  currentBearing: bearing, // اتجاه السائق
  showRoute: true,
  showPassengerMarkers: true,
  showDriverMarker: true,
  autoFitBounds: true,
)
```

### استخدام MapService:

```dart
import 'package:bridgecore_flutter_starter/core/services/map_service.dart';

final mapService = MapService();

// الحصول على الموقع الحالي
final position = await mapService.getCurrentLocation();

// تتبع الموقع مباشرة
mapService.watchPosition().listen((position) {
  print('Lat: ${position.latitude}, Lng: ${position.longitude}');
});

// حساب المسافة
final distance = mapService.calculateDistance(
  LatLng(33.3152, 44.3661),
  LatLng(33.3400, 44.4000),
);

// حساب ETA
final eta = mapService.calculateETA(
  LatLng(33.3152, 44.3661),
  LatLng(33.3400, 44.4000),
);
```

## الفرق بين Mapbox و Google Maps

| الميزة | Mapbox (قديم) | Google Maps (جديد) |
|--------|--------------|-------------------|
| API | mapbox_maps_flutter | google_maps_flutter |
| LatLng | latlong2.LatLng | google_maps_flutter.LatLng |
| Markers | Custom implementation | Built-in Marker widget |
| Polylines | Custom implementation | Built-in Polyline widget |
| تكلفة | مجاني حتى حد معين | مجاني حتى حد معين |
| دعم العربية | محدود | ممتاز |

## ملاحظات مهمة

1. **مفتاح API**: تأكد من أن مفتاح Google Maps API مفعّل ومُعدّ بشكل صحيح في Google Cloud Console
2. **الأذونات**: لا تنسى طلب أذونات الموقع من المستخدم في وقت التشغيل
3. **iOS**: إذا كنت تريد دعم iOS، ستحتاج إلى:
   - إضافة المفتاح في `ios/Runner/Info.plist`
   - إضافة أذونات الموقع في نفس الملف
4. **الحدود اليومية**: Google Maps لديه حد يومي مجاني، بعده قد تحتاج للدفع

## إعداد iOS (اختياري)

إذا كنت تريد دعم iOS، أضف التالي إلى `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>نحتاج إلى موقعك لعرض الخريطة وتتبع الرحلة</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>نحتاج إلى موقعك لتتبع الرحلة في الخلفية</string>
```

وأضف مفتاح Google Maps في `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyA9lblOmPEN-Aa9oE_ET3cbqiapI6HhjSE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## روابط مفيدة

- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Get API Key](https://developers.google.com/maps/documentation/android-sdk/get-api-key)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Geocoding Package](https://pub.dev/packages/geocoding)

## الاختبار

لتجربة الخرائط:

```bash
flutter run
```

تأكد من:
1. تفعيل GPS على جهازك
2. منح التطبيق أذونات الموقع
3. اتصالك بالإنترنت

## المشاكل الشائعة

### الخريطة لا تظهر
- تأكد من صحة مفتاح API
- تأكد من تفعيل Maps SDK for Android في Google Cloud Console

### الموقع لا يعمل
- تأكد من منح التطبيق أذونات الموقع
- تأكد من تفعيل GPS على الجهاز

### Markers لا تظهر
- تأكد من أن الإحداثيات صحيحة
- تأكد من استدعاء `setState()` بعد تحديث Markers

