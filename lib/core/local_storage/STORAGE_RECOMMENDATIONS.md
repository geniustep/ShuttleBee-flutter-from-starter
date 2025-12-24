# 🗄️ توصيات التخزين المحلي - Storage Recommendations

## 📋 نظرة عامة

هذا الملف يحتوي على اقتراحات شاملة لأماكن استخدام التخزين المحلي في التطبيق لتحسين الأداء وتجربة المستخدم.

---

## 🎯 الأولويات العالية (High Priority)

### 1. **Chat Messages & Conversations** 💬
**الملف المقترح:** `lib/features/chat/data/cache/chat_local_cache.dart`

**البيانات:**
- محادثات المستخدم (conversations)
- الرسائل الأخيرة لكل محادثة (last 100 message per conversation)
- حالة القراءة (read status)
- المرفقات المحلية (local attachments metadata)

**TTL:**
- Conversations: 7 days
- Messages: 30 days
- Read status: Permanent

**الفائدة:**
- عرض المحادثات فوراً عند فتح التطبيق
- قراءة الرسائل السابقة بدون اتصال
- تحسين تجربة المستخدم بشكل كبير

---

### 2. **Passenger Profiles & Groups** 👥
**الملف المقترح:** `lib/features/dispatcher/data/cache/passenger_local_cache.dart`

**البيانات:**
- Passenger profiles (معلومات الركاب)
- Passenger groups (المجموعات)
- Passenger lines (خطوط الركاب)
- Unassigned passengers (الركاب غير المعينين)

**TTL:**
- Profiles: 24 hours
- Groups: 12 hours
- Lines: 6 hours

**الفائدة:**
- البحث السريع في الركاب
- عرض المجموعات بدون انتظار
- تحسين أداء شاشات Dispatcher

---

### 3. **Vehicles & Drivers** 🚗
**الملف المقترح:** `lib/features/vehicles/data/cache/vehicle_local_cache.dart`

**البيانات:**
- Vehicle list (قائمة المركبات)
- Driver profiles (معلومات السائقين)
- Vehicle status (حالة المركبة)
- Vehicle location history (سجل المواقع)

**TTL:**
- Vehicles: 12 hours
- Drivers: 24 hours
- Status: 5 minutes
- Location: 1 hour

**الفائدة:**
- عرض المركبات المتاحة فوراً
- تتبع المواقع حتى بدون اتصال
- تحسين أداء الخرائط

---

### 4. **Search History & Filters** 🔍
**الملف المقترح:** `lib/core/local_storage/cache/search_local_cache.dart`

**البيانات:**
- Recent searches (البحث الأخير)
- Saved filters (الفلاتر المحفوظة)
- Favorite searches (البحث المفضل)

**TTL:**
- Search history: 30 days
- Filters: Permanent
- Favorites: Permanent

**الفائدة:**
- توفير الوقت للمستخدم
- تحسين تجربة البحث
- تذكر تفضيلات المستخدم

---

## 🎯 الأولويات المتوسطة (Medium Priority)

### 5. **Notifications** 🔔
**الملف المقترح:** `lib/features/notifications/data/cache/notification_local_cache.dart`

**البيانات:**
- Unread notifications (الإشعارات غير المقروءة)
- Notification history (سجل الإشعارات)
- Notification preferences (تفضيلات الإشعارات)

**TTL:**
- Unread: Permanent (until read)
- History: 90 days
- Preferences: Permanent

**الفائدة:**
- عرض الإشعارات حتى بدون اتصال
- تتبع الإشعارات المهمة
- تحسين تجربة الإشعارات

---

### 6. **Dashboard & KPIs** 📊
**الملف المقترح:** `lib/features/dashboard/data/cache/dashboard_local_cache.dart`

**البيانات:**
- KPI values (قيم المؤشرات)
- Chart data (بيانات الرسوم البيانية)
- Last update timestamp (وقت آخر تحديث)

**TTL:**
- KPIs: 15 minutes
- Charts: 30 minutes

**الفائدة:**
- عرض Dashboard فوراً
- تحسين أداء الشاشة الرئيسية
- تقليل استهلاك البيانات

---

### 7. **Stops & Locations** 📍
**الملف المقترح:** `lib/features/stops/data/cache/stop_local_cache.dart`

**البيانات:**
- Stop list (قائمة المحطات)
- Location coordinates (إحداثيات المواقع)
- Stop metadata (معلومات المحطات)

**TTL:**
- Stops: 24 hours
- Coordinates: 7 days

**الفائدة:**
- عرض المحطات بدون اتصال
- تحسين أداء الخرائط
- البحث السريع في المحطات

---

### 8. **User Preferences & Settings** ⚙️
**الملف المقترح:** `lib/core/local_storage/cache/user_preferences_cache.dart`

**البيانات:**
- Theme preferences (تفضيلات الثيم)
- Language settings (إعدادات اللغة)
- Display preferences (تفضيلات العرض)
- Notification settings (إعدادات الإشعارات)

**TTL:**
- All: Permanent

**الفائدة:**
- حفظ تفضيلات المستخدم
- تحسين تجربة الاستخدام
- تخصيص التطبيق

---

## 🎯 الأولويات المنخفضة (Low Priority)

### 9. **Offline Actions Queue** 📤
**الملف المقترح:** `lib/features/offline_manager/data/cache/offline_actions_cache.dart`

**البيانات:**
- Pending actions (الإجراءات المعلقة)
- Failed syncs (المزامنة الفاشلة)
- Retry metadata (معلومات إعادة المحاولة)

**TTL:**
- Actions: Until synced
- Failed: 7 days

**الفائدة:**
- العمل بدون اتصال
- مزامنة تلقائية عند الاتصال
- عدم فقدان البيانات

---

### 10. **Trip History & Analytics** 📈
**الملف المقترح:** `lib/features/trips/data/cache/trip_history_cache.dart`

**البيانات:**
- Completed trips (الرحلات المكتملة)
- Trip statistics (إحصائيات الرحلات)
- Monthly summaries (ملخصات شهرية)

**TTL:**
- Completed trips: 90 days
- Statistics: 365 days
- Summaries: Permanent

**الفائدة:**
- عرض التاريخ بدون اتصال
- تحليل الأداء
- تقارير محلية

---

### 11. **Media & Attachments** 📎
**الملف المقترح:** `lib/core/local_storage/cache/media_local_cache.dart`

**البيانات:**
- Image thumbnails (الصور المصغرة)
- File metadata (معلومات الملفات)
- Download status (حالة التحميل)

**TTL:**
- Thumbnails: 30 days
- Metadata: 90 days
- Status: Until downloaded

**الفائدة:**
- عرض الصور بسرعة
- توفير مساحة التخزين
- تحسين الأداء

---

## 🏗️ هيكل التطبيق المقترح

```
lib/
├── core/
│   └── local_storage/
│       ├── cache/
│       │   ├── search_local_cache.dart
│       │   ├── user_preferences_cache.dart
│       │   └── media_local_cache.dart
│       └── ...
├── features/
│   ├── chat/
│   │   └── data/
│   │       └── cache/
│   │           └── chat_local_cache.dart
│   ├── dispatcher/
│   │   └── data/
│   │       └── cache/
│   │           ├── passenger_local_cache.dart
│   │           └── dispatcher_local_cache.dart (موجود)
│   ├── vehicles/
│   │   └── data/
│   │       └── cache/
│   │           └── vehicle_local_cache.dart
│   ├── notifications/
│   │   └── data/
│   │       └── cache/
│   │           └── notification_local_cache.dart
│   ├── dashboard/
│   │   └── data/
│   │       └── cache/
│   │           └── dashboard_local_cache.dart
│   ├── stops/
│   │   └── data/
│   │       └── cache/
│   │           └── stop_local_cache.dart
│   ├── trips/
│   │   └── data/
│   │       └── cache/
│   │           └── trip_history_cache.dart
│   └── offline_manager/
│       └── data/
│           └── cache/
│               └── offline_actions_cache.dart
```

---

## 📝 نمط الاستخدام المقترح

### مثال: Chat Local Cache

```dart
class ChatLocalCache {
  final LocalStorageRepository _storage;
  
  static const String _conversationsCollection = 'chat_conversations';
  static const String _messagesCollection = 'chat_messages';
  
  // Save conversations
  Future<Either<Failure, bool>> cacheConversations(
    List<ChatConversation> conversations,
  ) async {
    final json = conversations.map((c) => c.toJson()).toList();
    return _storage.saveCollection(
      collectionName: _conversationsCollection,
      items: json,
      ttl: Duration(days: 7),
    );
  }
  
  // Load cached conversations
  Future<Either<Failure, List<ChatConversation>>> getCachedConversations() async {
    final result = await _storage.loadCollection(_conversationsCollection);
    return result.fold(
      (failure) => Left(failure),
      (items) {
        try {
          final conversations = items
              .map((json) => ChatConversation.fromJson(json))
              .toList();
          return Right(conversations);
        } catch (e) {
          return Left(CacheFailure(message: 'Failed to parse: $e'));
        }
      },
    );
  }
  
  // Save messages for a conversation
  Future<Either<Failure, bool>> cacheMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    final json = messages.map((m) => m.toJson()).toList();
    return _storage.saveCollection(
      collectionName: '${_messagesCollection}_$conversationId',
      items: json,
      ttl: Duration(days: 30),
    );
  }
}
```

---

## 🎯 خطة التنفيذ المقترحة

### المرحلة 1 (أسبوع 1-2)
1. ✅ Chat Local Cache
2. ✅ Passenger Local Cache
3. ✅ Search History Cache

### المرحلة 2 (أسبوع 3-4)
4. ✅ Vehicle Local Cache
5. ✅ Notification Local Cache
6. ✅ User Preferences Cache

### المرحلة 3 (أسبوع 5-6)
7. ✅ Dashboard Cache
8. ✅ Stops Cache
9. ✅ Offline Actions Cache

### المرحلة 4 (أسبوع 7-8)
10. ✅ Trip History Cache
11. ✅ Media Cache
12. ✅ Testing & Optimization

---

## 📊 المقاييس المتوقعة

### تحسين الأداء:
- ⚡ تقليل وقت التحميل الأولي: **60-80%**
- ⚡ تحسين سرعة البحث: **70-90%**
- ⚡ تقليل استهلاك البيانات: **40-60%**

### تحسين تجربة المستخدم:
- ✅ عمل بدون اتصال: **100% للبيانات المخزنة**
- ✅ سرعة الاستجابة: **تحسين 3-5x**
- ✅ استقرار التطبيق: **تحسين 20-30%**

---

## 🔧 ملاحظات التنفيذ

### Best Practices:
1. **استخدم TTL مناسب** - لا تخزن البيانات القديمة
2. **حذف البيانات المنتهية** - استخدم `clearExpired()` دورياً
3. **معالجة الأخطاء** - استخدم `Either<Failure, T>` دائماً
4. **اختبار Offline** - تأكد من عمل التطبيق بدون اتصال
5. **مراقبة الحجم** - استخدم `getStats()` لمراقبة الاستخدام

### Performance Tips:
- استخدم `saveBatch()` للبيانات الكبيرة
- استخدم `loadBatch()` عند الحاجة لعدة مفاتيح
- احذف البيانات القديمة تلقائياً
- استخدم Collections للبيانات المتعلقة

---

## ✅ Checklist للتنفيذ

لكل cache جديد:
- [ ] إنشاء ملف cache class
- [ ] إضافة methods للـ save/load/update/delete
- [ ] تحديد TTL مناسب
- [ ] إضافة error handling
- [ ] إنشاء provider للـ Riverpod
- [ ] إضافة unit tests
- [ ] اختبار offline functionality
- [ ] تحديث documentation

---

**آخر تحديث:** $(date)
**الإصدار:** 1.0.0

