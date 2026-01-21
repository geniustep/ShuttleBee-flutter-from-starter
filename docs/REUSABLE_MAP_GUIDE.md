# 🗺️ دليل استخدام الخريطة القابلة لإعادة الاستخدام

## 📋 نظرة عامة

تم إنشاء نظام خريطة مرن وقابل لإعادة الاستخدام يمكن استخدامه في أماكن مختلفة من التطبيق لعرض:
- 🚗 المركبات
- 👤 الركاب
- 🚏 المحطات
- 🛑 نقاط التوقف
- أي بيانات جغرافية أخرى

---

## 🚀 الاستخدام الأساسي

### 1. عرض المحطات على الخريطة

```dart
import 'package:shuttlebee/core/widgets/reusable_map_widget.dart';
import 'package:shuttlebee/core/widgets/map_marker_types.dart';

// في شاشتك
ReusableMapWidget(
  initialLocation: MapLocation(
    latitude: 35.7595,
    longitude: -5.8340,
  ),
  markers: [
    StationMarkerHelper.createMarker(
      stationId: '1',
      location: MapLocation(latitude: 35.7595, longitude: -5.8340),
      stationName: 'محطة المركز',
      code: 'ST001',
      type: StationType.pickup,
      onTap: () {
        // معالجة النقر على المحطة
      },
    ),
  ],
  showMyLocation: true,
  showZoomControls: true,
)
```

### 2. عرض الركاب على الخريطة

```dart
ReusableMapWidget(
  initialLocation: MapLocation(
    latitude: 35.7595,
    longitude: -5.8340,
  ),
  markers: passengers.map((passenger) {
    return PassengerMarkerHelper.createMarker(
      passengerId: passenger.id.toString(),
      location: MapLocation(
        latitude: passenger.latitude,
        longitude: passenger.longitude,
      ),
      passengerName: passenger.name,
      phoneNumber: passenger.phone,
      status: PassengerStatus.waiting,
      onTap: () {
        // عرض تفاصيل الراكب
        _showPassengerDetails(passenger);
      },
    );
  }).toList(),
  enableClustering: true,
  clusteringThreshold: 30,
)
```

### 3. عرض المركبات على الخريطة

```dart
ReusableMapWidget(
  initialLocation: MapLocation(
    latitude: 35.7595,
    longitude: -5.8340,
  ),
  markers: vehicles.map((vehicle) {
    return VehicleMarkerHelper.createMarker(
      vehicleId: vehicle.id.toString(),
      location: MapLocation(
        latitude: vehicle.latitude,
        longitude: vehicle.longitude,
      ),
      vehicleName: vehicle.name,
      driverName: vehicle.driverName,
      status: VehicleStatus.onTrip,
      heading: vehicle.heading,
      onTap: () {
        // عرض تفاصيل المركبة
        _showVehicleDetails(vehicle);
      },
    );
  }).toList(),
  enableViewportCulling: true,
  showTraffic: true,
)
```

---

## 🎨 الخصائص المتاحة

### الخصائص الأساسية

- `initialLocation`: الموقع الافتراضي للخريطة
- `initialZoom`: مستوى التكبير الابتدائي (افتراضي: 13.0)
- `markers`: قائمة العلامات لعرضها
- `polylines`: خطوط المسار
- `onMapTap`: استدعاء عند النقر على الخريطة
- `onMarkerTap`: استدعاء عند النقر على علامة
- `onCameraMove`: استدعاء عند تحريك الكاميرا

### خصائص التحكم

- `showMyLocation`: إظهار موقع المستخدم الحالي
- `showMyLocationButton`: إظهار زر الموقع الحالي
- `showZoomControls`: إظهار أدوات التكبير/التصغير
- `showTraffic`: إظهار حركة المرور
- `showCompass`: إظهار البوصلة

### خصائص الأداء

- `enableViewportCulling`: تفعيل إخفاء العلامات خارج الشاشة (افتراضي: true)
- `enableClustering`: تفعيل تجميع العلامات (افتراضي: true)
- `clusteringThreshold`: عتبة التجميع (افتراضي: 50)

### Widgets إضافية

- `overlayWidgets`: قائمة widgets إضافية فوق الخريطة

---

## 📝 أمثلة متقدمة

### مثال 1: عرض المحطات مع تفاصيل

```dart
class StopsMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('المحطات على الخريطة')),
      body: StopsMapView(
        onStopSelected: (stop) {
          // عرض تفاصيل المحطة
          showModalBottomSheet(
            context: context,
            builder: (context) => StopDetailsSheet(stop: stop),
          );
        },
      ),
    );
  }
}
```

### مثال 2: عرض الركاب مع فلترة

```dart
class PassengersMapScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passengers = ref.watch(filteredPassengersProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('الركاب على الخريطة')),
      body: ReusableMapWidget(
        initialLocation: CompanyConfig.defaultLocation,
        markers: passengers
            .where((p) => p.hasLocation)
            .map((p) => PassengerMarkerHelper.createMarker(
                  passengerId: p.id.toString(),
                  location: MapLocation(
                    latitude: p.latitude,
                    longitude: p.longitude,
                  ),
                  passengerName: p.name,
                  status: p.status,
                  onTap: () => _showPassengerDetails(context, p),
                ))
            .toList(),
        overlayWidgets: [
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${passengers.length} راكب'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### مثال 3: عرض مسار رحلة

```dart
ReusableMapWidget(
  initialLocation: trip.startLocation,
  markers: [
    // نقطة البداية
    MapMarkerData(
      id: 'start',
      location: trip.startLocation,
      title: 'نقطة البداية',
      color: MarkerColor.green,
    ),
    // نقطة النهاية
    MapMarkerData(
      id: 'end',
      location: trip.endLocation,
      title: 'نقطة النهاية',
      color: MarkerColor.red,
    ),
    // المحطات
    ...trip.stops.map((stop) => StationMarkerHelper.createMarker(
          stationId: stop.id.toString(),
          location: stop.location,
          stationName: stop.name,
          type: stop.type,
        )),
  ],
  polylines: [
    MapPolylineData(
      id: 'route',
      points: trip.routePoints,
      color: AppColors.primary,
      width: 4,
    ),
  ],
)
```

---

## 🛠️ Helpers المتاحة

### VehicleMarkerHelper
إنشاء علامات المركبات بسهولة

### PassengerMarkerHelper
إنشاء علامات الركاب بسهولة

### StationMarkerHelper
إنشاء علامات المحطات بسهولة

### StopMarkerHelper
إنشاء علامات نقاط التوقف بسهولة

---

## ⚡ تحسينات الأداء المدمجة

1. **Viewport Culling**: تحديث فقط العلامات المرئية
2. **Marker Clustering**: تجميع العلامات القريبة
3. **Debouncing**: تقليل التحديثات المتكررة
4. **Icon Caching**: تخزين الأيقونات في cache

---

## 📱 الاستجابة للمنصات المختلفة

الخريطة تعمل تلقائياً على:
- ✅ Android/iOS (Google Maps)
- ✅ Web (Google Maps)
- ✅ Windows/macOS/Linux (flutter_map)

---

## 🎯 أفضل الممارسات

1. **استخدم Helpers**: استخدم الـ helpers المخصصة لإنشاء العلامات
2. **فعّل Clustering**: عند وجود أكثر من 30 علامة
3. **فعّل Viewport Culling**: لتحسين الأداء
4. **استخدم Overlay Widgets**: لإضافة معلومات إضافية
5. **معالجة الأخطاء**: تأكد من معالجة حالات عدم وجود إحداثيات

---

## 📚 الملفات ذات الصلة

- `reusable_map_widget.dart`: الويدجت الرئيسي
- `map_marker_types.dart`: أنواع العلامات والـ helpers
- `cross_platform_map.dart`: الخريطة متعددة المنصات
- `stops_map_view.dart`: مثال على استخدام المحطات

