# 🛠️ Core Utils - Logger System

## 📁 الملفات

### 1. `logger.dart`
نظام التسجيل (Logging) المركزي للتطبيق مع دعم التصفية حسب الفئات (Categories).

**المميزات:**
- ✅ 9 فئات مختلفة للتصفية
- ✅ تنسيق محسّن وقابل للقراءة
- ✅ دعم كل مستويات التسجيل (debug, info, warning, error, fatal)
- ✅ اختصار تلقائي للـ Network logs
- ✅ تكامل مع error tracking

**الاستخدام:**
```dart
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

// استخدام بدون category (general)
AppLogger.debug('Debug message');
AppLogger.info('Info message');

// استخدام مع category
AppLogger.debug('Fetching data', null, null, LogCategory.network);
AppLogger.info('Login success', null, null, LogCategory.auth);
AppLogger.error('GPS failed', error, stackTrace, LogCategory.tracking);
```

---

### 2. `logger_config.dart`
إعدادات جاهزة (Presets) لتصفية الـ logs حسب السيناريو.

**الإعدادات المتاحة:**
```dart
LoggerConfig.minimal();        // فقط المهم
LoggerConfig.networkOnly();    // Network فقط
LoggerConfig.authOnly();       // Auth فقط
LoggerConfig.trackingOnly();   // GPS/Tracking فقط
LoggerConfig.syncOnly();       // Sync فقط
LoggerConfig.databaseOnly();   // Database فقط
LoggerConfig.uiOnly();         // UI فقط
LoggerConfig.all();            // كل شيء
LoggerConfig.errorsOnly();     // الأخطاء فقط
LoggerConfig.production();     // Production
LoggerConfig.development();    // Development
LoggerConfig.printConfig();    // عرض الإعدادات
```

**الاستخدام:**
```dart
import 'package:bridgecore_flutter_starter/core/utils/logger_config.dart';

void main() {
  // اختر preset مناسب
  LoggerConfig.minimal();
  
  runApp(MyApp());
}
```

---

### 3. `logger_example.dart`
أمثلة عملية على كيفية استخدام نظام الـ logging في سيناريوهات مختلفة.

**يحتوي على:**
- 9 أمثلة لكل category
- أمثلة تغيير الإعدادات
- أمثلة استخدام في Services، Providers، Widgets

---

## 📊 الفئات (Categories)

| الفئة | متى تستخدمها | مثال |
|------|--------------|-------|
| `network` | طلبات API والشبكة | `AppLogger.debug('Fetching users', null, null, LogCategory.network)` |
| `auth` | تسجيل الدخول والمصادقة | `AppLogger.info('Login success', null, null, LogCategory.auth)` |
| `sync` | مزامنة البيانات | `AppLogger.debug('Syncing data', null, null, LogCategory.sync)` |
| `database` | عمليات قاعدة البيانات | `AppLogger.debug('Saving to DB', null, null, LogCategory.database)` |
| `ui` | الواجهة والـ Widgets | `AppLogger.debug('Button clicked', null, null, LogCategory.ui)` |
| `navigation` | التنقل بين الشاشات | `AppLogger.debug('Navigate to X', null, null, LogCategory.navigation)` |
| `notification` | الإشعارات | `AppLogger.info('Push received', null, null, LogCategory.notification)` |
| `tracking` | تتبع الموقع GPS | `AppLogger.debug('GPS updated', null, null, LogCategory.tracking)` |
| `general` | رسائل عامة | `AppLogger.debug('General message')` (الافتراضي) |

---

## 🚀 البدء السريع

### الخطوة 1: اختر Preset
في `lib/bootstrap/bootstrap.dart` أو `lib/main.dart`:

```dart
import 'package:bridgecore_flutter_starter/core/utils/logger_config.dart';

void main() {
  // للعمل اليومي - موصى به
  LoggerConfig.minimal();
  
  // أو حسب احتياجك
  // LoggerConfig.networkOnly();
  // LoggerConfig.trackingOnly();
  // LoggerConfig.authOnly();
  
  runApp(MyApp());
}
```

### الخطوة 2: استخدم في الكود
```dart
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

class MyService {
  Future<void> fetchData() async {
    AppLogger.debug('Fetching...', null, null, LogCategory.network);
    
    try {
      // ... API call ...
      AppLogger.info('Success', null, null, LogCategory.network);
    } catch (e, st) {
      AppLogger.error('Failed', e, st, LogCategory.network);
    }
  }
}
```

---

## 💡 نصائح

### 1. استخدم Categories دائماً
```dart
// ❌ سيء
AppLogger.debug('Fetching data');

// ✅ جيد
AppLogger.debug('Fetching data', null, null, LogCategory.network);
```

### 2. استخدم المستوى المناسب
```dart
AppLogger.debug('Detailed info');    // معلومات دقيقة
AppLogger.info('Important event');   // حدث مهم
AppLogger.warning('Potential issue'); // تحذير
AppLogger.error('Error occurred');   // خطأ
AppLogger.fatal('Critical failure'); // خطأ حرج
```

### 3. غيّر الإعدادات حسب الحاجة
```dart
// عند تصحيح Network
LoggerConfig.networkOnly();

// عند تصحيح GPS
LoggerConfig.trackingOnly();

// للعمل العادي
LoggerConfig.minimal();
```

### 4. استخدم VS Code Filter
في Debug Console:
- اكتب `[NETWORK]` لرؤية Network logs فقط
- اكتب `[TRACKING]` لرؤية Tracking logs فقط
- اكتب `ERROR` لرؤية الأخطاء فقط

---

## 📖 المزيد من التوثيق

- [LOGGING_QUICKSTART.md](../../../LOGGING_QUICKSTART.md) - البدء السريع (30 ثانية)
- [LOGGING_GUIDE.md](../../../LOGGING_GUIDE.md) - الدليل الشامل
- [LOGGING_IMPROVEMENTS_SUMMARY.md](../../../LOGGING_IMPROVEMENTS_SUMMARY.md) - ملخص التحسينات
- [logger_example.dart](./logger_example.dart) - أمثلة كود عملية

---

## 🎯 أمثلة حالات الاستخدام

### حالة 1: Debug Console مزدحم
```dart
// الحل
LoggerConfig.minimal();
```

### حالة 2: مشكلة في API
```dart
// الحل
LoggerConfig.networkOnly();
```

### حالة 3: مشكلة في GPS
```dart
// الحل
LoggerConfig.trackingOnly();
```

### حالة 4: مشكلة في تسجيل الدخول
```dart
// الحل
LoggerConfig.authOnly();
```

---

**تم التحديث:** 17 ديسمبر 2025
