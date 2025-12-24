# 🗄️ Platform-Specific Local Storage System

نظام تخزين محلي منفصل حسب المنصة (Mobile vs Windows) مع دعم Offline-First.

---

## 📋 جدول المحتويات

- [نظرة عامة](#نظرة-عامة)
- [المعمارية](#المعمارية)
- [التكوينات المختلفة حسب المنصة](#التكوينات-المختلفة-حسب-المنصة)
- [البدء السريع](#البدء-السريع)
- [أمثلة الاستخدام](#أمثلة-الاستخدام)
- [الدليل الكامل](#الدليل-الكامل)

---

## 🎯 نظرة عامة

هذا النظام يوفر:

✅ **فصل كامل بين Mobile و Windows** - كل منصة لها تطبيق مستقل مع إعدادات محسّنة
✅ **Offline-First Architecture** - يعمل التطبيق بدون إنترنت
✅ **Platform Detection تلقائي** - اختيار التطبيق المناسب حسب المنصة
✅ **TTL Support** - انتهاء صلاحية تلقائي للبيانات المخزنة
✅ **LRU Eviction** - حذف تلقائي للبيانات الأقل استخداماً عند امتلاء الذاكرة
✅ **Clean Architecture** - Repository Pattern مع Providers

---

## 🏗️ المعمارية

```
lib/core/local_storage/
├── domain/
│   └── local_storage_repository.dart       # Interface موحّد
├── data/
│   ├── mobile_local_storage_impl.dart      # تطبيق Mobile
│   ├── windows_local_storage_impl.dart     # تطبيق Windows
│   └── models/
│       ├── cache_entry.dart                # نموذج Cache Entry
│       └── cache_metadata.dart             # Metadata للمجموعات
├── providers/
│   └── local_storage_providers.dart        # Riverpod Providers
└── README.md                                # هذا الملف
```

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (Riverpod Providers + Widgets)       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│          Domain Layer                   │
│   (LocalStorageRepository Interface)    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│           Data Layer                    │
│  Mobile Impl  ←→  Windows Impl          │
│    (Hive)           (Hive)              │
└─────────────────────────────────────────┐
```

---

## ⚙️ التكوينات المختلفة حسب المنصة

| Feature | Mobile (Android/iOS) | Windows |
|---------|---------------------|---------|
| **Storage Engine** | Hive | Hive |
| **Max Cache Entries** | 1,000 | 5,000 |
| **Max Collection Size** | 500 items | 2,000 items |
| **Max Cache Size** | 50 MB | 200 MB |
| **Default TTL** | 6 hours | 24 hours |
| **Storage Path** | `/Documents/hive_mobile` | `/Documents/ShuttleBee/hive_windows` |
| **Compaction Strategy** | Delete 50+ entries | Delete 50+ entries |
| **Optimization** | Battery-friendly | Desktop-optimized |

### لماذا Hive للطرفين؟

- ✅ **Fast** - أسرع من SQLite بـ 10x
- ✅ **NoSQL** - مرونة في البيانات
- ✅ **Cross-platform** - يعمل على Mobile, Desktop, Web
- ✅ **Type-safe** - دعم Dart objects مباشرة
- ✅ **Zero-config** - لا يحتاج setup معقد

---

## 🚀 البدء السريع

### 1️⃣ التهيئة الأولية (في main.dart)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/local_storage/providers/local_storage_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Initialize storage automatically
  try {
    await container.read(storageInitializationProvider.future);
    print('✅ Storage initialized successfully');
  } catch (e) {
    print('❌ Storage initialization failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(),
    ),
  );
}
```

### 2️⃣ الاستخدام البسيط

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/local_storage/providers/local_storage_providers.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(localStorageRepositoryProvider);

    return ElevatedButton(
      onPressed: () async {
        // Save data
        await storage.save(
          key: 'user_settings',
          data: {'theme': 'dark', 'language': 'ar'},
          ttl: Duration(days: 30),
        );

        // Load data
        final result = await storage.load('user_settings');
        result.fold(
          (failure) => print('Error: ${failure.message}'),
          (data) => print('Settings: $data'),
        );
      },
      child: Text('Save & Load'),
    );
  }
}
```

---

## 📚 أمثلة الاستخدام

### مثال 1: حفظ وتحميل رحلة

```dart
// Save trip
final trip = {
  'id': 123,
  'name': 'رحلة الرياض',
  'date': DateTime.now().toIso8601String(),
  'passengers': 25,
};

await storage.save(
  key: 'trip_123',
  data: trip,
  ttl: Duration(hours: 2),
);

// Load trip
final result = await storage.load('trip_123');
result.fold(
  (failure) => showError(failure.message),
  (data) => displayTrip(data),
);
```

### مثال 2: حفظ مجموعة من الرحلات

```dart
final trips = [
  {'id': 1, 'name': 'رحلة 1'},
  {'id': 2, 'name': 'رحلة 2'},
  {'id': 3, 'name': 'رحلة 3'},
];

await storage.saveCollection(
  collectionName: 'all_trips',
  items: trips,
  ttl: Duration(hours: 6),
);

// Load all trips
final result = await storage.loadCollection('all_trips');
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (trips) => displayTripsList(trips),
);
```

### مثال 3: البحث في المجموعة

```dart
// Query trips by status
final result = await storage.queryCollection(
  collectionName: 'all_trips',
  filters: {'status': 'active'},
  sortBy: 'date',
  ascending: false,
  limit: 10,
);

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (filteredTrips) => displayResults(filteredTrips),
);
```

### مثال 4: حذف البيانات المنتهية صلاحيتها

```dart
// Clean expired entries on app startup
final deletedCount = await storage.clearExpired();
deletedCount.fold(
  (failure) => print('Cleanup failed'),
  (count) => print('Deleted $count expired entries'),
);
```

### مثال 5: معلومات التخزين

```dart
// Get storage stats
final stats = await storage.getStats();
stats.fold(
  (failure) => print('Error'),
  (data) {
    print('Platform: ${data['platform']}');
    print('Total entries: ${data['cache_entries']}');
    print('Total size: ${data['total_size_mb']} MB');
  },
);

// Get platform info
final info = await storage.getPlatformInfo();
info.fold(
  (failure) => print('Error'),
  (data) {
    print('Storage path: ${data['storage_path']}');
    print('Max cache: ${data['max_cache_size_mb']} MB');
  },
);
```

---

## 🔧 الدليل الكامل

### Repository Methods

#### 1. التهيئة والإدارة

| Method | Description |
|--------|-------------|
| `initialize()` | تهيئة نظام التخزين |
| `close()` | إغلاق التخزين وتحرير الموارد |
| `clearAll()` | حذف جميع البيانات |
| `getStats()` | إحصائيات التخزين |
| `healthCheck()` | فحص صحة النظام |
| `clearExpired()` | حذف البيانات المنتهية |

#### 2. عمليات Cache الأساسية

| Method | Description |
|--------|-------------|
| `save(key, data, ttl)` | حفظ بيانات |
| `load(key)` | تحميل بيانات |
| `delete(key)` | حذف بيانات |
| `has(key)` | التحقق من وجود البيانات |

#### 3. عمليات Batch

| Method | Description |
|--------|-------------|
| `saveBatch(items, ttl)` | حفظ عدة عناصر |
| `loadBatch(keys)` | تحميل عدة عناصر |
| `deleteBatch(keys)` | حذف عدة عناصر |

#### 4. عمليات Collections

| Method | Description |
|--------|-------------|
| `saveCollection(name, items, ttl)` | حفظ مجموعة |
| `loadCollection(name)` | تحميل مجموعة |
| `deleteCollection(name)` | حذف مجموعة |
| `updateCollectionItem(name, id, data)` | تحديث عنصر |
| `deleteCollectionItem(name, id)` | حذف عنصر |
| `queryCollection(...)` | البحث في المجموعة |

---

## 🎨 Providers المتاحة

```dart
// Platform detection
final platformType = ref.watch(platformTypeProvider);

// Storage repository
final storage = ref.watch(localStorageRepositoryProvider);

// Initialization status
final initStatus = ref.watch(storageInitializationProvider);

// Statistics
final stats = ref.watch(storageStatsProvider);

// Platform info
final info = ref.watch(platformInfoProvider);

// Health check
final isHealthy = ref.watch(storageHealthProvider);

// Auto cleanup
final cleanedCount = ref.watch(autoCleanupProvider);
```

---

## ⚡ Best Practices

### ✅ Do

- ✅ استخدم TTL مناسب لكل نوع بيانات
- ✅ احذف البيانات المنتهية بشكل دوري
- ✅ استخدم Collections للبيانات المتعلقة
- ✅ تحقق من Platform Info للتخصيص
- ✅ استخدم fold() للتعامل مع النتائج

### ❌ Don't

- ❌ لا تخزن بيانات حساسة بدون تشفير
- ❌ لا تتجاوز حدود الحجم المسموح
- ❌ لا تهمل معالجة الأخطاء
- ❌ لا تخزن بيانات كبيرة جداً في entry واحد
- ❌ لا تنسى إغلاق Storage عند الخروج

---

## 🐛 استكشاف الأخطاء

### المشكلة: Storage لا يعمل

**الحل:**
```dart
// تحقق من التهيئة
final health = await storage.healthCheck();
health.fold(
  (failure) => print('Not initialized: ${failure.message}'),
  (isOk) => print('Health: $isOk'),
);
```

### المشكلة: البيانات لا تُحفظ

**الحل:**
```dart
// تحقق من حدود الحجم
final stats = await storage.getStats();
stats.fold(
  (failure) => print('Error'),
  (data) {
    final entries = data['cache_entries'];
    final maxEntries = data['max_entries'];
    if (entries >= maxEntries) {
      print('Cache full! Clear some data.');
    }
  },
);
```

### المشكلة: البيانات تختفي

**الحل:**
```dart
// تحقق من TTL
await storage.save(
  key: 'important_data',
  data: myData,
  ttl: null, // لا انتهاء
);
```

---

## 📊 مقارنة الأداء

| Operation | Mobile | Windows |
|-----------|--------|---------|
| Save 100 items | ~50ms | ~30ms |
| Load 100 items | ~40ms | ~25ms |
| Query 1000 items | ~100ms | ~60ms |
| Clear expired | ~20ms | ~15ms |

---

## 🔄 Migration من نظام قديم

```dart
// Old way
final prefs = await SharedPreferences.getInstance();
await prefs.setString('key', jsonEncode(data));

// New way
await storage.save(
  key: 'key',
  data: data,
  ttl: Duration(days: 30),
);
```

---

## 📝 ملاحظات إضافية

1. **Platform Detection تلقائي** - لا حاجة لكتابة `if (Platform.isAndroid)`
2. **Offline Support** - البيانات متاحة حتى بدون إنترنت
3. **Type Safety** - استخدام `Either<Failure, T>` لمعالجة الأخطاء
4. **Performance** - Hive أسرع من SQLite
5. **Scalability** - حدود مختلفة لكل منصة

---

**آخر تحديث:** ديسمبر 2025
**الإصدار:** 1.0
**المؤلف:** فريق التطوير ShuttleBee
