# Google Maps - دليل الإعداد للويب والموبايل

## ✅ ما تم إنجازه

تم تفعيل Google Maps على المنصات التالية:

### 📱 Android
- ✅ Google Maps SDK جاهز ومُفعّل
- ✅ API Key مُضاف إلى `AndroidManifest.xml`

### 🌐 Web (المتصفح)
- ✅ Google Maps JavaScript API مُفعّل
- ✅ API Key مُضاف إلى `web/index.html`
- ✅ حزمة `google_maps_flutter_web` مُثبّتة

### 📱 iOS
- ⚠️ يحتاج إعداد إضافي (انظر أدناه)

### 💻 Windows Desktop
- ❌ Google Maps لا يدعم Windows Desktop بشكل أصلي
- ✅ يستخدم OpenStreetMap (flutter_map) كبديل ممتاز

---

## 🔑 API Key المُستخدم

```
AIzaSyA9lblOmPEN-Aa9oE_ET3cbqiapI6HhjSE
```

### ⚠️ ملاحظات مهمة عن API Key:

1. **تفعيل APIs المطلوبة في Google Cloud Console:**
   - Maps JavaScript API (للويب)
   - Maps SDK for Android
   - Maps SDK for iOS (إذا كنت تستخدم iOS)

2. **تقييد الوصول (Restrictions):**
   - للأمان، يُفضل تقييد API Key حسب المنصة
   - للويب: قيّده بالنطاقات (Domains) المسموحة
   - للموبايل: قيّده بـ Package Name/Bundle ID

3. **الفواتير (Billing):**
   - يجب تفعيل الفواتير في Google Cloud Console
   - تحصل على $200 رصيد مجاني شهرياً

---

## 🚀 الاستخدام

### في الكود (dispatcher_monitor_screen.dart)

التطبيق يستخدم `CrossPlatformMap` الذي يختار تلقائياً:
- **Google Maps** على Android/iOS/Web
- **OpenStreetMap** على Windows/macOS/Linux

```dart
CrossPlatformMap(
  initialLocation: MapLocation(
    latitude: 24.7136,
    longitude: 46.6753,
  ),
  initialZoom: 11,
  markers: markers,
  showMyLocation: true,
  showZoomControls: true,
)
```

---

## 🧪 التجربة

### 1. تشغيل على الويب:
```bash
flutter run -d chrome
```

### 2. تشغيل على Windows:
```bash
flutter run -d windows
```
> ⚠️ سيستخدم OpenStreetMap على Windows (بديل ممتاز)

### 3. تشغيل على Android:
```bash
flutter run -d android
```

---

## 📱 إعداد iOS (إذا لزم الأمر)

إذا كنت تريد تشغيل التطبيق على iOS:

### 1. أضف API Key إلى `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@main
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

### 2. أضف الصلاحيات إلى `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>نحتاج موقعك لعرض الخريطة</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>نحتاج موقعك لتتبع الرحلات</string>
```

---

## 🔧 حل المشاكل الشائعة

### 1. الخريطة لا تظهر على الويب

**المشكلة:** شاشة رمادية بدون خريطة

**الحل:**
- تأكد من تفعيل "Maps JavaScript API" في Google Cloud Console
- تأكد من تفعيل الفواتير (Billing)
- افتح Developer Console في المتصفح وتحقق من الأخطاء

### 2. خطأ: "This API key is not authorized to use this service"

**الحل:**
- راجع إعدادات API Key في Google Cloud Console
- تأكد من تفعيل APIs المطلوبة
- تأكد أن الـ Restrictions لا تمنع استخدام API

### 3. الخريطة تعمل على الموبايل لكن ليس على الويب

**الحل:**
- تأكد من إضافة API Key إلى `web/index.html`
- تأكد من تفعيل "Maps JavaScript API" في Console

---

## 📊 مقارنة المنصات

| المنصة | نوع الخريطة | الأداء | المميزات |
|--------|-------------|---------|-----------|
| Android | Google Maps | ⭐⭐⭐⭐⭐ | كامل |
| iOS | Google Maps | ⭐⭐⭐⭐⭐ | كامل |
| Web | Google Maps | ⭐⭐⭐⭐ | كامل |
| Windows | OpenStreetMap | ⭐⭐⭐⭐ | ممتاز |
| macOS | OpenStreetMap | ⭐⭐⭐⭐ | ممتاز |
| Linux | OpenStreetMap | ⭐⭐⭐⭐ | ممتاز |

---

## 📚 روابط مفيدة

- [Google Maps Platform Console](https://console.cloud.google.com/google/maps-apis)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Google Maps JavaScript API](https://developers.google.com/maps/documentation/javascript)
- [Flutter Map (OpenStreetMap)](https://pub.dev/packages/flutter_map)

---

## ✨ ملاحظات إضافية

### OpenStreetMap على Windows
- **مجاني بالكامل** - لا يحتاج API key
- **أداء ممتاز** - يعمل بسلاسة على Windows
- **خرائط محدثة** - تُحدّث باستمرار من المجتمع
- **لا حدود للاستخدام** - استخدام غير محدود

### لماذا Google Maps على الويب؟
- تجربة موحدة على الموبايل والويب
- أدوات متقدمة للـ monitoring
- دعم كامل للـ markers والـ polylines
- أداء أفضل على المتصفحات الحديثة

---

**✅ الإعداد كامل وجاهز للاستخدام!**
