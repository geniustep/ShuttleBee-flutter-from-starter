# 📋 دليل نظام التسجيل (Logging Guide)

## المشكلة
عند وجود الكثير من الـ logs في debug console، يصبح من الصعب قراءتها وتتبع المشاكل.

## الحل
تم تحسين نظام الـ logging لجعله أكثر وضوحاً وقابلية للقراءة من خلال:

### ✨ التحسينات
1. **تقليل طول السطر** من 120 إلى 80 حرف
2. **إزالة الـ Emojis** من الـ logs العادية
3. **تقليل عدد الـ Stack Frames** في الأخطاء
4. **إضافة نظام Categories** للتصفية
5. **اختصار الـ Network Logs** تلقائياً

---

## 🎯 كيفية الاستخدام

### 1. استخدام Categories في الكود

```dart
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

// Network logs
AppLogger.debug('Fetching data...', null, null, LogCategory.network);

// Auth logs
AppLogger.info('User logged in', null, null, LogCategory.auth);

// Database logs
AppLogger.debug('Saving to cache', null, null, LogCategory.database);

// UI logs
AppLogger.debug('Building widget', null, null, LogCategory.ui);

// Tracking logs
AppLogger.info('Location updated', null, null, LogCategory.tracking);

// Sync logs
AppLogger.debug('Syncing data', null, null, LogCategory.sync);

// Navigation logs
AppLogger.debug('Navigating to screen', null, null, LogCategory.navigation);

// Notification logs
AppLogger.info('Push notification received', null, null, LogCategory.notification);

// General logs
AppLogger.debug('General message'); // Default category
```

### 2. تصفية الـ Logs

#### في ملف `main.dart` أو `bootstrap.dart`:

```dart
import 'package:bridgecore_flutter_starter/core/utils/logger_config.dart';

void main() {
  // اختر واحد من هذه الإعدادات:
  
  // 1. عرض جميع الـ logs (افتراضي)
  LoggerConfig.development();
  
  // 2. عرض فقط Network logs
  LoggerConfig.networkOnly();
  
  // 3. عرض فقط Auth logs
  LoggerConfig.authOnly();
  
  // 4. عرض فقط Tracking logs
  LoggerConfig.trackingOnly();
  
  // 5. عرض فقط Sync logs
  LoggerConfig.syncOnly();
  
  // 6. تصغير الـ logs (فقط الأخطاء المهمة)
  LoggerConfig.minimal();
  
  // 7. إيقاف كل شيء ما عدا الأخطاء
  LoggerConfig.errorsOnly();
  
  // عرض الإعدادات الحالية
  LoggerConfig.printConfig();
  
  runApp(MyApp());
}
```

### 3. تعطيل/تفعيل Category معين

```dart
// تعطيل Network logs
AppLogger.disableCategory(LogCategory.network);

// تفعيل Network logs
AppLogger.enableCategory(LogCategory.network);

// التحقق من حالة Category
if (AppLogger.isCategoryEnabled(LogCategory.network)) {
  print('Network logging is enabled');
}
```

---

## 🎨 أمثلة الاستخدام

### مثال 1: تصحيح مشكلة في Network
```dart
void main() {
  // عرض فقط Network logs لتصحيح مشاكل API
  LoggerConfig.networkOnly();
  runApp(MyApp());
}
```

### مثال 2: تصحيح مشكلة في Authentication
```dart
void main() {
  // عرض فقط Auth logs لتصحيح مشاكل تسجيل الدخول
  LoggerConfig.authOnly();
  runApp(MyApp());
}
```

### مثال 3: تصحيح مشكلة في Live Tracking
```dart
void main() {
  // عرض Tracking و Network logs معاً
  LoggerConfig.minimal();
  AppLogger.enableCategory(LogCategory.tracking);
  AppLogger.enableCategory(LogCategory.network);
  runApp(MyApp());
}
```

### مثال 4: Production Mode
```dart
void main() {
  // في الإنتاج، عرض فقط الأخطاء المهمة
  LoggerConfig.production();
  runApp(MyApp());
}
```

---

## 📊 Categories المتاحة

| Category | الاستخدام |
|----------|-----------|
| `network` | طلبات API والشبكة |
| `auth` | تسجيل الدخول والمصادقة |
| `sync` | مزامنة البيانات |
| `database` | عمليات قاعدة البيانات والـ Cache |
| `ui` | بناء الواجهات والـ Widgets |
| `navigation` | التنقل بين الشاشات |
| `notification` | الإشعارات |
| `tracking` | تتبع الموقع (GPS) |
| `general` | رسائل عامة |

---

## 🔧 نصائح إضافية

### 1. استخدم Flutter DevTools
- افتح DevTools من VS Code أو Android Studio
- استخدم تبويب "Logging" لتصفية أفضل
- استخدم البحث للعثور على رسائل محددة

### 2. استخدم Console Filters في IDE
في VS Code:
- اضغط على أيقونة الفلتر في Debug Console
- اكتب `[NETWORK]` لعرض Network logs فقط
- اكتب `[AUTH]` لعرض Auth logs فقط

### 3. قلل من استخدام print()
استخدم `AppLogger` بدلاً من `print()` دائماً:

```dart
// ❌ سيء
print('User logged in');

// ✅ جيد
AppLogger.info('User logged in', null, null, LogCategory.auth);
```

### 4. استخدم المستويات المناسبة
```dart
AppLogger.debug('Detailed info');    // للتفاصيل الدقيقة
AppLogger.info('Important event');   // للأحداث المهمة
AppLogger.warning('Potential issue'); // للتحذيرات
AppLogger.error('Error occurred');   // للأخطاء
AppLogger.fatal('Critical failure'); // للأخطاء الحرجة
```

---

## 🚀 الخطوات التالية

1. افتح `main.dart` أو `bootstrap.dart`
2. أضف السطر المناسب لاحتياجاتك (مثل `LoggerConfig.networkOnly()`)
3. أعد تشغيل التطبيق
4. استمتع بـ console نظيف وواضح! 🎉

---

## 📝 ملاحظات

- **الأخطاء تظهر دائماً** بغض النظر عن الإعدادات
- يمكنك تغيير الإعدادات في أي وقت أثناء runtime
- في Production، استخدم `LoggerConfig.production()` لتقليل الـ logs
