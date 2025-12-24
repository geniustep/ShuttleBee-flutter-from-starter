# 🚀 مرجع سريع - Platform-Specific Local Storage

## 📌 الأساسيات في دقيقة واحدة

### 1. الحصول على Storage

```dart
final storage = ref.watch(localStorageRepositoryProvider);
```

### 2. حفظ بيانات

```dart
await storage.save(
  key: 'my_key',
  data: {'name': 'value'},
  ttl: Duration(hours: 24),
);
```

### 3. تحميل بيانات

```dart
final result = await storage.load('my_key');
result.fold(
  (failure) => print(failure.message),
  (data) => print(data),
);
```

---

## 🎯 حالات الاستخدام الشائعة

### ✅ حفظ قائمة رحلات

```dart
await storage.saveCollection(
  collectionName: 'trips',
  items: tripsJson,
  ttl: Duration(hours: 2),
);
```

### ✅ تحميل قائمة رحلات

```dart
final result = await storage.loadCollection('trips');
```

### ✅ البحث

```dart
final result = await storage.queryCollection(
  collectionName: 'trips',
  filters: {'status': 'active'},
  limit: 10,
);
```

### ✅ حذف المنتهية

```dart
await storage.clearExpired();
```

---

## 📊 Platform Differences

| | Mobile | Windows |
|-|--------|---------|
| **Max Size** | 50 MB | 200 MB |
| **Max Items** | 1,000 | 5,000 |
| **TTL** | 6h | 24h |

---

## 🔧 Providers

```dart
// Platform type
final platform = ref.watch(platformTypeProvider);

// Storage
final storage = ref.watch(localStorageRepositoryProvider);

// Stats
final stats = ref.watch(storageStatsProvider);

// Health
final isHealthy = ref.watch(storageHealthProvider);
```

---

## ⚡ أمثلة سريعة

### Offline-First

```dart
try {
  final data = await fetchFromAPI();
  await storage.save(key: 'data', data: data);
} catch (e) {
  final cached = await storage.load('data');
  // Use cached data
}
```

### Auto-Cleanup on Startup

```dart
void main() async {
  final storage = container.read(localStorageRepositoryProvider);
  await storage.clearExpired();
  runApp(MyApp());
}
```

---

**للتفاصيل الكاملة:** اقرأ [README.md](README.md)
