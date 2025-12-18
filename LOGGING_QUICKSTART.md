# 🚀 Logging Quick Start

## المشكلة: Debug Console غير قابل للقراءة ❌

عندما يكون هناك الكثير من الـ logs، يصبح من المستحيل تتبع المشاكل!

## الحل السريع ✅

### خطوة واحدة فقط!

افتح ملف `lib/bootstrap/bootstrap.dart` وأزل التعليق عن السطر المناسب:

```dart
void main() {
  // ... existing code ...
  
  // 🎯 اختر واحدة من هذه:
  
  LoggerConfig.minimal();         // ✅ موصى به! (فقط الأخطاء المهمة)
  // LoggerConfig.networkOnly();  // لتصحيح API
  // LoggerConfig.trackingOnly(); // لتصحيح GPS
  // LoggerConfig.authOnly();     // لتصحيح Login
  
  // ... rest of code ...
}
```

**ثم أعد تشغيل التطبيق!** 🎉

---

## أمثلة سريعة

### 1. مشكلة في Network/API
```dart
LoggerConfig.networkOnly();
```

### 2. مشكلة في GPS/Tracking
```dart
LoggerConfig.trackingOnly();
```

### 3. مشكلة في Login/Auth
```dart
LoggerConfig.authOnly();
```

### 4. تصغير الـ Logs (الافضل للعمل اليومي)
```dart
LoggerConfig.minimal();
```

### 5. أريد كل شيء (كالسابق)
```dart
LoggerConfig.development();
```

---

## نصائح إضافية 💡

### في VS Code
استخدم Filter في Debug Console:
- اكتب `[NETWORK]` لرؤية Network logs فقط
- اكتب `[TRACKING]` لرؤية Tracking logs فقط
- اكتب `[AUTH]` لرؤية Auth logs فقط

### للتحكم الدقيق
```dart
// تعطيل category معين
AppLogger.disableCategory(LogCategory.network);

// تفعيل category معين
AppLogger.enableCategory(LogCategory.network);

// عرض الإعدادات الحالية
LoggerConfig.printConfig();
```

---

## الفئات المتاحة (Categories)

| الفئة | الاستخدام |
|------|-----------|
| `network` | طلبات API |
| `tracking` | GPS والموقع |
| `auth` | تسجيل الدخول |
| `sync` | المزامنة |
| `database` | قاعدة البيانات |
| `ui` | الواجهة |
| `notification` | الإشعارات |
| `general` | عام |

---

## للمزيد

راجع [LOGGING_GUIDE.md](./LOGGING_GUIDE.md) للتفاصيل الكاملة.
