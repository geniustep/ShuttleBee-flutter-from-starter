# 🚌 ShuttleBee Flutter

<div align="center">

![ShuttleBee Logo](assets/images/logo.png)

**نظام إدارة النقل المدرسي المتكامل**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Odoo](https://img.shields.io/badge/Odoo-18-714B67?logo=odoo)](https://odoo.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

[العربية](#العربية) | [English](#english)

</div>

---

## العربية

### 📋 نظرة عامة

**ShuttleBee** هو تطبيق Flutter متكامل لإدارة النقل المدرسي، يعمل مع نظام Odoo 18 كخادم خلفي. يوفر التطبيق واجهات مخصصة لكل من:

- 🚗 **السائقين** - إدارة الرحلات والركاب
- 👨‍👩‍👧‍👦 **أولياء الأمور** - تتبع الأبناء والإشعارات
- 🎒 **الركاب** - متابعة الرحلات
- 👔 **المدراء** - لوحة تحكم شاملة

### ✨ المميزات الرئيسية

#### 🗺️ التتبع الحي
- تتبع GPS في الوقت الفعلي
- عرض موقع الحافلة على الخريطة
- تحديث تلقائي كل 10 ثواني
- حساب الوقت المتوقع للوصول

#### 📱 إدارة الرحلات
- إنشاء وتعديل الرحلات
- تعيين السائقين والمركبات
- إدارة حالات الركاب (صعود/غياب/نزول)
- جدولة أسبوعية تلقائية

#### 🔔 نظام الإشعارات
- إشعارات الاقتراب والوصول
- إشعارات بدء وإلغاء الرحلات
- دعم SMS, WhatsApp, Push, Email
- تتبع حالة التسليم

#### 👨‍👩‍👧 بوابة ولي الأمر
- تتبع الأبناء مباشرة
- تسجيل الغياب المسبق
- إحصائيات الحضور
- إشعارات فورية

#### 📊 لوحة تحكم المدير
- إحصائيات شاملة
- إدارة المركبات ونقاط التوقف
- إدارة المجموعات والجداول
- تقارير متقدمة

### 🏗️ هيكل المشروع

```
lib/
├── core/                          # المكونات الأساسية
│   ├── bridgecore_integration/    # تكامل Odoo
│   │   └── client/
│   │       └── bridgecore_client.dart
│   ├── enums/                     # التعدادات
│   ├── error/                     # معالجة الأخطاء
│   ├── routing/                   # التنقل (GoRouter)
│   ├── services/                  # الخدمات
│   │   ├── gps_tracking_service.dart
│   │   └── map_service.dart
│   ├── theme/                     # التصميم
│   └── utils/                     # الأدوات المساعدة
│
├── features/                      # الميزات
│   ├── auth/                      # المصادقة
│   ├── driver/                    # واجهة السائق
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── driver_home_screen.dart
│   │   │   │   ├── driver_trip_detail_screen.dart
│   │   │   │   └── driver_live_trip_map_screen.dart
│   │   │   └── widgets/
│   │   │       └── trip_map_widget.dart
│   │
│   ├── passenger/                 # واجهة الراكب
│   │   └── presentation/
│   │       └── screens/
│   │           ├── passenger_home_screen.dart
│   │           └── passenger_trip_tracking_screen.dart
│   │
│   ├── guardian/                  # واجهة ولي الأمر
│   │   ├── domain/entities/
│   │   │   └── guardian_info.dart
│   │   ├── data/datasources/
│   │   │   └── guardian_remote_data_source.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── guardian_providers.dart
│   │       └── screens/
│   │           └── guardian_home_screen.dart
│   │
│   ├── manager/                   # واجهة المدير
│   │   └── presentation/
│   │       └── screens/
│   │           └── manager_dashboard_screen.dart
│   │
│   ├── trips/                     # إدارة الرحلات
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── trip.dart
│   │   │   └── repositories/
│   │   │       └── trip_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── trip_remote_data_source.dart
│   │   │   └── repositories/
│   │   │       └── trip_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── trip_providers.dart
│   │       └── widgets/
│   │           └── trip_conditions_widget.dart
│   │
│   ├── notifications/             # الإشعارات
│   │   ├── domain/entities/
│   │   │   └── shuttle_notification.dart
│   │   ├── data/datasources/
│   │   │   └── notification_remote_data_source.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── notification_providers.dart
│   │       └── screens/
│   │           └── notifications_screen.dart
│   │
│   ├── vehicles/                  # المركبات
│   │   ├── domain/entities/
│   │   │   └── shuttle_vehicle.dart
│   │   ├── data/datasources/
│   │   │   └── vehicle_remote_data_source.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── vehicle_providers.dart
│   │       └── screens/
│   │           └── vehicles_screen.dart
│   │
│   ├── stops/                     # نقاط التوقف
│   │   ├── domain/entities/
│   │   │   └── shuttle_stop.dart
│   │   ├── data/datasources/
│   │   │   └── stop_remote_data_source.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── stop_providers.dart
│   │       └── screens/
│   │           └── stops_screen.dart
│   │
│   └── groups/                    # مجموعات الركاب
│       ├── domain/entities/
│       │   └── passenger_group.dart
│       ├── data/datasources/
│       │   └── group_remote_data_source.dart
│       └── presentation/
│           ├── providers/
│           │   └── group_providers.dart
│           └── screens/
│               └── group_schedules_screen.dart
│
├── l10n/                          # الترجمة
│   └── app_localizations.dart
│
├── shared/                        # المكونات المشتركة
│   └── widgets/
│
└── main.dart                      # نقطة البداية
```

### 🔧 التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|----------|
| **Flutter 3.x** | إطار العمل الرئيسي |
| **Dart 3.x** | لغة البرمجة |
| **Riverpod** | إدارة الحالة |
| **GoRouter** | التنقل |
| **Google Maps** | الخرائط والتتبع |
| **Geolocator** | خدمات الموقع |
| **BridgeCore** | تكامل Odoo |
| **flutter_animate** | الرسوم المتحركة |
| **Dartz** | البرمجة الوظيفية |

### 📦 الحزم الرئيسية

```yaml
dependencies:
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Navigation
  go_router: ^12.0.0
  
  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Odoo Integration
  bridgecore_flutter: ^latest
  
  # UI
  flutter_animate: ^4.3.0
  
  # Utilities
  dartz: ^0.10.1
  intl: ^0.18.1
```

### ⚙️ الإعداد والتثبيت

#### المتطلبات
- Flutter SDK 3.x+
- Dart SDK 3.x+
- Android Studio / VS Code
- Odoo 18 Server مع موديول ShuttleBee

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

3. **إعداد Google Maps**

أضف مفتاح API في:

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

4. **إعداد الاتصال بـ Odoo**

قم بتحديث إعدادات الخادم في التطبيق أو ملف الإعدادات.

5. **تشغيل التطبيق**
```bash
flutter run
```

### 🔐 الأدوار والصلاحيات

| الدور | الصلاحيات |
|-------|----------|
| **Manager** | وصول كامل لجميع الميزات |
| **Dispatcher** | إدارة الرحلات والجداول |
| **Driver** | تنفيذ الرحلات وتحديث الحالات |
| **User/Passenger** | عرض الرحلات والإشعارات |
| **Guardian** | تتبع الأبناء وتسجيل الغياب |

### 📱 الشاشات الرئيسية

#### شاشة السائق
- قائمة الرحلات اليومية
- تفاصيل الرحلة مع قائمة الركاب
- خريطة التتبع الحي
- تحديث حالة الركاب

#### شاشة ولي الأمر
- قائمة الأبناء
- رحلات اليوم
- تتبع مباشر
- إحصائيات الحضور

#### لوحة المدير
- إحصائيات سريعة
- نظرة عامة اليوم
- إدارة الموارد
- إجراءات سريعة

### 🌐 تكامل Odoo

التطبيق يتكامل مع موديول **ShuttleBee** في Odoo 18:

#### النماذج المدعومة
- `shuttle.trip` - الرحلات
- `shuttle.trip.line` - سطور الرحلة (الركاب)
- `shuttle.vehicle` - المركبات
- `shuttle.stop` - نقاط التوقف
- `shuttle.passenger.group` - مجموعات الركاب
- `shuttle.notification` - الإشعارات
- `shuttle.gps.position` - مواقع GPS

#### الطرق المدعومة
```dart
// Trip Actions
action_confirm()      // تأكيد الرحلة
action_start()        // بدء الرحلة
action_complete()     // إكمال الرحلة
action_cancel()       // إلغاء الرحلة

// Passenger Actions
action_board()        // صعود الراكب
action_absent()       // تسجيل غياب
action_drop()         // نزول الراكب

// GPS Tracking
register_gps_position()  // تسجيل موقع GPS

// Notifications
action_send_approaching_notifications()
action_send_arrived_notifications()
```

### 🎨 التصميم

- دعم RTL (العربية)
- تصميم Material Design 3
- ألوان متناسقة مع الهوية
- رسوم متحركة سلسة
- واجهة سهلة الاستخدام

### 📄 الترخيص

هذا المشروع مملوك وغير مفتوح المصدر.

---

## English

### 📋 Overview

**ShuttleBee** is a comprehensive Flutter application for school transportation management, working with Odoo 18 as the backend. The app provides customized interfaces for:

- 🚗 **Drivers** - Trip and passenger management
- 👨‍👩‍👧‍👦 **Guardians** - Child tracking and notifications
- 🎒 **Passengers** - Trip monitoring
- 👔 **Managers** - Comprehensive dashboard

### ✨ Key Features

#### 🗺️ Live Tracking
- Real-time GPS tracking
- Bus location on map
- Auto-refresh every 10 seconds
- ETA calculation

#### 📱 Trip Management
- Create and edit trips
- Assign drivers and vehicles
- Manage passenger status (boarded/absent/dropped)
- Automatic weekly scheduling

#### 🔔 Notification System
- Approaching and arrival notifications
- Trip start and cancellation alerts
- Support for SMS, WhatsApp, Push, Email
- Delivery status tracking

#### 👨‍👩‍👧 Guardian Portal
- Direct child tracking
- Pre-register absences
- Attendance statistics
- Instant notifications

#### 📊 Manager Dashboard
- Comprehensive statistics
- Vehicle and stop management
- Group and schedule management
- Advanced reports

### ⚙️ Setup & Installation

#### Requirements
- Flutter SDK 3.x+
- Dart SDK 3.x+
- Android Studio / VS Code
- Odoo 18 Server with ShuttleBee module

#### Installation Steps

1. **Clone the project**
```bash
git clone https://github.com/your-org/shuttlebee-flutter.git
cd shuttlebee-flutter
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Google Maps**

Add API key in:

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

4. **Configure Odoo connection**

Update server settings in the app or configuration file.

5. **Run the app**
```bash
flutter run
```

### 🔐 Roles & Permissions

| Role | Permissions |
|------|------------|
| **Manager** | Full access to all features |
| **Dispatcher** | Trip and schedule management |
| **Driver** | Execute trips and update statuses |
| **User/Passenger** | View trips and notifications |
| **Guardian** | Track children and register absences |

### 📄 License

This project is proprietary and not open source.

---

<div align="center">

**Made with ❤️ for ShuttleBee**

</div>
