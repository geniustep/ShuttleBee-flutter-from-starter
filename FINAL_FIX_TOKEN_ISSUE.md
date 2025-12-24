# الحل النهائي لمشكلة التوكن - ShuttleBee

## 🔴 المشكلة الأصلية

التطبيق كان يستمر في العمل ويدخل للصفحة الرئيسية حتى عندما **لا يوجد توكن BridgeCore صالح**، مما يؤدي إلى:

1. عرض الصفحة الرئيسية بدون بيانات
2. فشل جميع استدعاءات API مع خطأ:
   ```
   [TokenManager] ! No tokens found
   Missing Odoo credentials. Either use a tenant JWT token...
   ```

---

## 🔍 السبب الجذري

من تحليل الـ logs:

```
🔐 [_checkAuthStatus] BridgeCore auth state: TokenAuthState.unauthenticated
🔍 [_checkAuthStatus] userId: 15, sessionId: exists, serverUrl: ...
📦 [_checkAuthStatus] Found legacy session, migrating...
```

**السبب:**
- التطبيق يجد `userId` و `sessionId` من جلسة قديمة (legacy session) محفوظة في `SharedPreferences`
- لكن **لا توجد توكنات BridgeCore صالحة** في `FlutterSecureStorage`
- الكود القديم كان يعتبر وجود `userId` + `sessionId` كافياً لاستعادة الجلسة
- **المشكلة:** لا يمكن استدعاء API بدون توكن BridgeCore صالح!

---

## ✅ الحل المطبق

### التعديل الرئيسي في `auth_provider.dart`

تم تعديل حالة `TokenState.none` لمنع استعادة الجلسة القديمة بدون توكن صالح:

**قبل الإصلاح:**
```dart
case TokenState.none:
  // No tokens - check legacy session
  if (userId != null && sessionId != null && serverUrl != null) {
    print('📦 [_checkAuthStatus] Found legacy session, migrating...');
    await _restoreAuthenticatedSession(  // ❌ خطأ! لا يوجد توكن
      userId: userId,
      sessionId: sessionId,
      serverUrl: serverUrl,
      tokenState: TokenState.valid,  // ❌ يُعتبر صالح خطأً
    );
  }
  break;
```

**بعد الإصلاح:**
```dart
case TokenState.none:
  // No BridgeCore tokens - legacy session is invalid without proper tokens
  // CRITICAL: We must NOT restore session without valid BridgeCore tokens
  print('❌ [_checkAuthStatus] No BridgeCore tokens found');
  if (userId != null || sessionId != null) {
    print('🧹 [_checkAuthStatus] Clearing legacy session data without valid tokens');
    await _clearSession();  // ✅ مسح الجلسة القديمة
  }
  print('➡️  [_checkAuthStatus] Redirecting to login');
  state = const AsyncValue.data(AuthState());  // ✅ حالة غير مصادق
  break;
```

---

## 🎯 النتيجة

### قبل الإصلاح:
```
بدء التطبيق
    ↓
SplashScreen
    ↓
يجد userId + sessionId قديم
    ↓
❌ يعتبرها جلسة صالحة
    ↓
يذهب للرئيسية
    ↓
❌ كل API calls تفشل (No tokens found)
```

### بعد الإصلاح:
```
بدء التطبيق
    ↓
SplashScreen
    ↓
يجد userId + sessionId قديم
    ↓
✅ يتحقق من BridgeCore tokens
    ↓
لا يوجد توكن صالح
    ↓
✅ يمسح الجلسة القديمة
    ↓
✅ يذهب لصفحة تسجيل الدخول
```

---

## 📊 سيناريوهات الاختبار

### ✅ سيناريو 1: مستخدم جديد (بدون أي بيانات)
```
Input:  لا توكن، لا userId، لا sessionId
Output: ✅ صفحة تسجيل الدخول
```

### ✅ سيناريو 2: جلسة قديمة بدون توكن BridgeCore (المشكلة الأصلية)
```
Input:  userId + sessionId موجودين لكن لا توكن BridgeCore
Output: ✅ مسح الجلسة → صفحة تسجيل الدخول
Logs:   ❌ [_checkAuthStatus] No BridgeCore tokens found
        🧹 [_checkAuthStatus] Clearing legacy session data
        ➡️  [_checkAuthStatus] Redirecting to login
```

### ✅ سيناريو 3: توكن صالح
```
Input:  userId + sessionId + BridgeCore token صالح
Output: ✅ الصفحة الرئيسية
```

### ✅ سيناريو 4: توكن منتهي لكن refresh token صالح
```
Input:  Access token منتهي + refresh token صالح
Output: ✅ تحديث تلقائي → الصفحة الرئيسية
```

---

## 🧪 كيفية الاختبار

### 1. حذف البيانات وإعادة التشغيل
```bash
# على Android
flutter run
# ثم اضغط على زر "Clear Data" من إعدادات التطبيق

# أو
flutter clean
flutter pub get
flutter run
```

### 2. مراقبة الـ Logs
ابحث عن هذه الرسائل:

**✅ الحالة الصحيحة (بدون توكن):**
```
🔐 [_checkAuthStatus] BridgeCore auth state: TokenAuthState.unauthenticated
❌ [_checkAuthStatus] No BridgeCore tokens found
🧹 [_checkAuthStatus] Clearing legacy session data without valid tokens
➡️  [_checkAuthStatus] Redirecting to login
```

**✅ الحالة الصحيحة (مع توكن صالح):**
```
🔐 [_checkAuthStatus] BridgeCore auth state: TokenAuthState.authenticated
✅ [_checkAuthStatus] Token is a valid tenant token
✅ [_restoreSession] Auth state set (tokenState: TokenState.valid)
🚀 [SplashScreen] Navigating to: /dispatcher
```

### 3. التحقق من السلوك
```
1. افتح التطبيق لأول مرة
2. النتيجة المتوقعة:
   - ✅ SplashScreen يظهر
   - ✅ بعد 2 ثانية ينتقل لصفحة تسجيل الدخول
   - ✅ لا توجد أخطاء في Console
   - ✅ لا رسالة "[TokenManager] ! No tokens found"
```

---

## 📝 الملفات المعدلة

| الملف | التعديل | السبب |
|------|---------|-------|
| `auth_provider.dart` (السطور 179-189) | تعديل حالة `TokenState.none` | منع استعادة جلسة قديمة بدون توكن |
| `auth_provider.dart` (السطور 86-113) | إضافة `try-catch` للتحقق من التوكن | معالجة أخطاء التحقق |
| `splash_screen.dart` (السطور 91-98) | إضافة فحص `invalidToken` | عرض رسالة واضحة للمستخدم |

---

## 🔑 النقاط المهمة

### 1. التفريق بين نوعي الجلسات:
- **Legacy Session**: userId + sessionId المحفوظين في `SharedPreferences`
- **BridgeCore Session**: Access Token + Refresh Token في `FlutterSecureStorage`

**القاعدة:** لا يمكن العمل بدون BridgeCore tokens صالحة!

### 2. تسلسل التحقق:
```
1. فحص BridgeCore auth state
2. إذا كان unauthenticated → فحص legacy session
3. إذا وجد legacy session لكن لا توكن → مسح كل شيء
4. التوجيه لصفحة الدخول
```

### 3. متى يتم مسح الجلسة:
- ✅ عند `TokenState.none` مع وجود بيانات قديمة
- ✅ عند `TokenState.expired` (كل التوكنات منتهية)
- ✅ عند فشل التحقق من صلاحية التوكن
- ✅ عند تسجيل الخروج اليدوي

---

## 🚀 الخطوات التالية (اختياري)

### 1. تحسين رسائل الخطأ للمستخدم
```dart
// في SplashScreen
if (auth.tokenState == TokenState.none && auth.user == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('انتهت صلاحية جلستك. يرجى تسجيل الدخول مجدداً'),
      backgroundColor: Colors.orange,
    ),
  );
}
```

### 2. إضافة زر "تسجيل خروج" في Developer Settings
```dart
ElevatedButton(
  onPressed: () async {
    await ref.read(authStateProvider.notifier).logout();
    context.go('/login');
  },
  child: Text('تسجيل الخروج + مسح البيانات'),
)
```

### 3. Migration Script للمستخدمين الحاليين
```dart
// تشغيل مرة واحدة عند التحديث
Future<void> migrateOldSessions() async {
  final hasOldData = await _prefs.containsKey(StorageKeys.userId);
  final hasNewTokens = await BridgeCore.instance.auth.isLoggedIn;

  if (hasOldData && !hasNewTokens) {
    print('🔄 Migrating old session...');
    await _clearSession();
    print('✅ Migration complete - please login again');
  }
}
```

---

## 📞 استكشاف الأخطاء

### المشكلة: لا يزال يذهب للرئيسية
**الحل:**
1. امسح بيانات التطبيق بالكامل
2. تأكد من تشغيل آخر نسخة من الكود
3. تحقق من الـ logs: `flutter logs | grep checkAuthStatus`

### المشكلة: يعلق على SplashScreen
**الحل:**
1. تحقق من اتصال الإنترنت
2. تحقق من صحة `ODOO_URL` في `.env`
3. راجع الـ logs للأخطاء

### المشكلة: يطلب تسجيل دخول بعد كل إغلاق
**الحل:**
1. تأكد من اختيار "تذكرني" عند الدخول
2. تحقق من أن التوكنات تُحفظ بشكل صحيح
3. تحقق من صلاحيات التطبيق للتخزين

---

## ✨ الخلاصة

الإصلاح يضمن:

✅ **عدم الدخول للرئيسية بدون توكن صالح**
✅ **مسح الجلسات القديمة غير الصالحة تلقائياً**
✅ **توجيه واضح لصفحة تسجيل الدخول**
✅ **رسائل واضحة في الـ logs للتتبع**
✅ **تجربة مستخدم محسنة**

---

**تم التحديث:** 2025-12-21
**الإصدار:** 1.0.1
**الحالة:** ✅ تم الاختبار والتأكيد
