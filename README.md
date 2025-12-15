# 🚌 ShuttleBee Flutter

<div align="center">

![ShuttleBee Logo](assets/images/logo.png)

**نظام إدارة النقل المدرسي المتكامل**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Odoo](https://img.shields.io/badge/Odoo-18-714B67?logo=odoo)](https://odoo.com)
[![BridgeCore](https://img.shields.io/badge/BridgeCore-3.1.0-00BFA5)](https://bridgecore.geniura.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

[العربية](#العربية) | [English](#english)

</div>

---

## العربية

### 📋 نظرة عامة

**ShuttleBee** هو تطبيق Flutter متكامل لإدارة النقل المدرسي، يعمل مع نظام Odoo 18 كخادم خلفي عبر **BridgeCore Flutter v3.1.0**. يوفر التطبيق واجهات مخصصة لكل من:

- 🚗 **السائقين** - إدارة الرحلات والركاب مع التتبع الحي
- 📡 **المشرفين (Dispatchers)** - مراقبة حية لجميع المركبات
- 👨‍👩‍👧‍👦 **أولياء الأمور** - تتبع الأبناء والإشعارات
- 🎒 **الركاب** - متابعة الرحلات
- 👔 **المدراء** - لوحة تحكم شاملة

---

### ✨ المميزات الرئيسية

#### 🚀 التتبع الحي عبر WebSocket (جديد في v3.1.0)

ميزة جديدة للتتبع الحي في الوقت الفعلي عبر WebSocket:

**للسائقين:**
- إرسال تلقائي لموقع GPS كل 10 ثواني أثناء الرحلة الجارية
- الاستجابة التلقائية لطلبات الموقع من المشرفين
- حفظ المواقع في Odoo (`shuttle.vehicle.position`)
- إعادة الاتصال التلقائي عند انقطاع الشبكة

**للمشرفين (Dispatchers):**
- مراقبة حية لجميع المركبات على الخريطة
- استقبال تحديثات الموقع في الوقت الفعلي
- طلب موقع سائق معين عند الحاجة
- تتبع حالة الرحلات مباشرة

```dart
// استخدام التتبع الحي للسائق
ref.read(driverLiveTrackingProvider.notifier).connect();
ref.read(driverLiveTrackingProvider.notifier).startAutoTrackingManual(
  tripId: trip.id,
  vehicleId: trip.vehicleId!,
);

// استخدام التتبع الحي للمشرف
ref.read(dispatcherLiveTrackingProvider.notifier).connectAndSubscribe();
final location = await ref.read(dispatcherLiveTrackingProvider.notifier)
    .requestDriverLocation(driverId);
```

#### 🗺️ التتبع عبر REST API

- تتبع GPS في الوقت الفعلي
- عرض موقع الحافلة على الخريطة
- تحديث تلقائي (المراقبة الحية: كل 5 ثواني)
- حساب الوقت المتوقع للوصول

#### 🧩 تكامل REST (ShuttleBee API v1)

Endpoints تحت المسار `/api/v1/shuttle/*`:

| Endpoint | الوصف |
|----------|-------|
| `POST /trips/<id>/confirm` | تأكيد الرحلة مع GPS |
| `GET /live/ongoing` | المراقبة الحية للرحلات |
| `GET /trips/<id>/gps` | مسار GPS للرحلة |
| `POST /vehicle/position` | Heartbeat للمركبة |
| `GET /trips/my` | رحلاتي للسائق |

#### 📱 إدارة الرحلات
- إنشاء وتعديل الرحلات
- تعيين السائقين والمركبات
- إدارة حالات الركاب (صعود/غياب/نزول)
- جدولة أسبوعية تلقائية

#### 🔔 نظام الإشعارات
- إشعارات الاقتراب والوصول
- إشعارات بدء وإلغاء الرحلات
- دعم SMS, WhatsApp, Push, Email

---

### 🏗️ هيكل المشروع

```
lib/
├── core/                              # المكونات الأساسية
│   ├── bridgecore_integration/        # تكامل Odoo
│   │   └── client/
│   │       └── bridgecore_client.dart
│   ├── config/
│   │   └── env_config.dart            # إعدادات البيئة
│   ├── services/
│   │   ├── live_tracking_provider.dart # 🆕 التتبع الحي WebSocket
│   │   ├── gps_tracking_service.dart
│   │   └── map_service.dart
│   ├── routing/                       # التنقل (GoRouter)
│   ├── theme/                         # التصميم
│   └── utils/                         # الأدوات المساعدة
│
├── features/                          # الميزات
│   ├── auth/                          # المصادقة
│   │
│   ├── driver/                        # واجهة السائق
│   │   └── presentation/
│   │       └── screens/
│   │           ├── driver_home_screen.dart      # التتبع الحي مفعل
│   │           ├── driver_trip_detail_screen.dart
│   │           └── driver_live_trip_map_screen.dart
│   │
│   ├── dispatcher/                    # واجهة المشرف
│   │   └── presentation/
│   │       └── screens/
│   │           └── dispatcher_monitor_screen.dart  # المراقبة الحية
│   │
│   ├── guardian/                      # واجهة ولي الأمر
│   ├── manager/                       # واجهة المدير
│   ├── trips/                         # إدارة الرحلات
│   ├── notifications/                 # الإشعارات
│   ├── vehicles/                      # المركبات
│   ├── stops/                         # نقاط التوقف
│   └── groups/                        # مجموعات الركاب
│
└── main.dart                          # نقطة البداية
```

---

### 🔧 التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|----------|
| **Flutter 3.x** | إطار العمل الرئيسي |
| **Dart 3.x** | لغة البرمجة |
| **Riverpod 3.x** | إدارة الحالة |
| **GoRouter** | التنقل |
| **Google Maps** | الخرائط والتتبع |
| **Geolocator** | خدمات الموقع |
| **BridgeCore 3.1.0** | تكامل Odoo + WebSocket |
| **WebSocket** | التتبع الحي |

---

### 📦 الحزم الرئيسية

```yaml
dependencies:
  # Odoo Integration with Live Tracking
  bridgecore_flutter: ^3.1.0
  
  # State Management
  flutter_riverpod: ^3.0.3
  
  # Navigation
  go_router: ^17.0.0
  
  # Maps & Location
  google_maps_flutter: ^2.11.1
  geolocator: ^13.0.4
  
  # Background Services
  flutter_foreground_task: ^latest
```

---

### ⚙️ الإعداد والتثبيت

#### المتطلبات
- Flutter SDK 3.x+
- Dart SDK 3.x+
- Android Studio / VS Code
- Odoo 18 Server مع موديول ShuttleBee
- BridgeCore Backend مع دعم WebSocket

#### خطوات التثبيت

1. **استنساخ المشروع**
```bash
git clone https://github.com/your-org/shuttlebee-flutter.git
cd shuttlebee-flutter
```

2. **تثبيت التبعيات**
```bash
flutter pub get
```

3. **إعداد ملف البيئة** (`.env`)
```env
ODOO_URL=https://bridgecore.geniura.com
```

4. **إعداد Google Maps**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

5. **تشغيل التطبيق**
```bash
flutter run
```

---

### 📡 التتبع الحي - دليل الاستخدام

#### للسائق

```dart
import 'package:your_app/core/services/live_tracking_provider.dart';

// في شاشة السائق الرئيسية
class DriverHomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(driverLiveTrackingProvider);
    
    // الاتصال تلقائياً عند بدء التطبيق
    useEffect(() {
      ref.read(driverLiveTrackingProvider.notifier).connect();
      return null;
    }, []);
    
    return Column(
      children: [
        // عرض حالة الاتصال
        Text(trackingState.isConnected ? 'متصل' : 'غير متصل'),
        Text(trackingState.isAutoTracking ? 'تتبع حي نشط' : ''),
      ],
    );
  }
}

// عند بدء رحلة
ref.read(driverLiveTrackingProvider.notifier).startAutoTrackingManual(
  tripId: trip.id,
  vehicleId: trip.vehicleId!,
);

// عند إنهاء رحلة
ref.read(driverLiveTrackingProvider.notifier).stopAutoTrackingManual();
```

#### للمشرف

```dart
import 'package:your_app/core/services/live_tracking_provider.dart';

class DispatcherMonitorScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(dispatcherLiveTrackingProvider);
    
    // الاتصال والاشتراك
    useEffect(() {
      ref.read(dispatcherLiveTrackingProvider.notifier).connectAndSubscribe();
      return null;
    }, []);
    
    // عرض مواقع المركبات على الخريطة
    return GoogleMap(
      markers: trackingState.vehiclePositions.map((pos) => 
        Marker(
          markerId: MarkerId('vehicle_${pos.vehicleId}'),
          position: LatLng(pos.latitude, pos.longitude),
        ),
      ).toSet(),
    );
  }
}

// طلب موقع سائق معين
final location = await ref.read(dispatcherLiveTrackingProvider.notifier)
    .requestDriverLocation(driverId);
```

---

### 🔐 الأدوار والصلاحيات

| الدور | الصلاحيات |
|-------|----------|
| **Manager** | وصول كامل لجميع الميزات |
| **Dispatcher** | مراقبة حية + إدارة الرحلات والجداول |
| **Driver** | تنفيذ الرحلات + التتبع التلقائي |
| **User/Passenger** | عرض الرحلات والإشعارات |
| **Guardian** | تتبع الأبناء وتسجيل الغياب |

---

### 🌐 تكامل Odoo

#### النماذج المدعومة
- `shuttle.trip` - الرحلات
- `shuttle.trip.line` - سطور الرحلة (الركاب)
- `shuttle.vehicle` - المركبات
- `shuttle.vehicle.position` - مواقع GPS (جديد)
- `shuttle.stop` - نقاط التوقف
- `shuttle.passenger.group` - مجموعات الركاب
- `shuttle.notification` - الإشعارات

#### أوامر WebSocket
| الأمر | الاتجاه | الوصف |
|-------|---------|-------|
| `subscribe_live_tracking` | Client → Server | الاشتراك في التتبع الحي |
| `request_driver_location` | Dispatcher → Driver | طلب موقع السائق |
| `location_response` | Driver → Dispatcher | رد موقع السائق |
| `driver_status_update` | Driver → Server | تحديث حالة السائق |
| `vehicle_position` | Server → Clients | تحديث موقع المركبة |
| `trip_update` | Server → Clients | تحديث حالة الرحلة |

---

### 📄 سجل التغييرات

#### v3.1.0 (الإصدار الحالي)
- ✅ إضافة التتبع الحي عبر WebSocket
- ✅ دعم Riverpod 3.x (`Notifier` بدلاً من `StateNotifier`)
- ✅ التتبع التلقائي للسائق كل 10 ثواني
- ✅ طلب موقع السائق عند الطلب
- ✅ إعادة الاتصال التلقائي

---

### 📄 الترخيص

هذا المشروع مملوك وغير مفتوح المصدر.

---

## English

### 📋 Overview

**ShuttleBee** is a comprehensive Flutter application for school transportation management, working with Odoo 18 as the backend via **BridgeCore Flutter v3.1.0**.

### ✨ Key Features

#### 🚀 Live Tracking via WebSocket (New in v3.1.0)

Real-time tracking over WebSocket:

**For Drivers:**
- Automatic GPS sending every 10 seconds during ongoing trips
- Auto-response to dispatcher location requests
- Positions saved to Odoo (`shuttle.vehicle.position`)
- Automatic reconnection on network loss

**For Dispatchers:**
- Live monitoring of all vehicles on map
- Real-time position updates
- On-demand driver location requests
- Direct trip status tracking

```dart
// Driver live tracking
ref.read(driverLiveTrackingProvider.notifier).connect();
ref.read(driverLiveTrackingProvider.notifier).startAutoTrackingManual(
  tripId: trip.id,
  vehicleId: trip.vehicleId!,
);

// Dispatcher live tracking
ref.read(dispatcherLiveTrackingProvider.notifier).connectAndSubscribe();
final location = await ref.read(dispatcherLiveTrackingProvider.notifier)
    .requestDriverLocation(driverId);
```

### 🔐 Roles & Permissions

| Role | Permissions |
|------|------------|
| **Manager** | Full access to all features |
| **Dispatcher** | Live monitoring + Trip and schedule management |
| **Driver** | Execute trips + Auto tracking |
| **User/Passenger** | View trips and notifications |
| **Guardian** | Track children and register absences |

### 📄 License

This project is proprietary and not open source.

---

<div align="center">

**Made with ❤️ for ShuttleBee**

**Powered by BridgeCore Flutter v3.1.0**

</div>
