# 🎯 دليل تحسينات المدير - ShuttleBee

## ✨ ما تم تنفيذه

### 1️⃣ **نظام التبديل بين الأدوار** (Role Switcher) 🔄

#### الملفات:
- `lib/core/services/role_switcher_service.dart`
- `lib/core/widgets/role_switcher_widget.dart`

#### الميزات:
✅ **المدير يمكنه التبديل إلى:**
- Manager (الدور الأصلي)
- Dispatcher (عرض المشغل)
- Driver (عرض السائق)
- Passenger (عرض الراكب)

✅ **الـ Dispatcher يمكنه التبديل إلى:**
- Dispatcher (الدور الأصلي)
- Driver (لرؤية تجربة السائق)

#### كيفية الاستخدام:

**1. في AppBar:**
```dart
appBar: AppBar(
  title: const Text('لوحة تحكم المدير'),
  actions: [
    const RoleSwitcherButton(), // زر التبديل
    // ... other actions
  ],
),
```

**2. في الصفحة (كـ Card):**
```dart
Column(
  children: [
    const RoleSwitcherWidget(), // عرض جميع الأدوار المتاحة
    // ... rest of content
  ],
)
```

**3. استخدام الـ Service مباشرة:**
```dart
final roleSwitcher = ref.read(roleSwitcherServiceProvider);

// التبديل لدور معين
await roleSwitcher.setActiveRole(UserRole.dispatcher);

// العودة للدور الأصلي
await roleSwitcher.clearActiveRole();

// التحقق من الصلاحيات
bool canSwitch = roleSwitcher.canSwitchToRole(user, UserRole.driver);

// الحصول على الأدوار المتاحة
List<UserRole> available = roleSwitcher.getAvailableRoles(user);
```

---

### 2️⃣ **تكامل الـ Role Switcher**

#### الخطوات للتفعيل:

**1. تهيئة Service في main.dart:**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        roleSwitcherServiceProvider.overrideWithValue(
          RoleSwitcherService(prefs),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

**2. تحديث Manager Home Screen:**
```dart
class ManagerHomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير'),
        actions: [
          const RoleSwitcherButton(), // إضافة زر التبديل
          IconButton(...),
        ],
      ),
      body: Column(
        children: [
          const RoleSwitcherWidget(), // عرض الأدوار المتاحة
          // ... rest of content
        ],
      ),
    );
  }
}
```

**3. التحديث التلقائي للـ Navigation:**
عند التبديل للدور، يتم:
- حفظ الدور في SharedPreferences
- تحديث activeRoleProvider
- الانتقال التلقائي للصفحة المناسبة
- عرض إشعار بالتبديل

---

### 3️⃣ **تحسينات Manager Dashboard** 📊

#### الميزات الحالية (موجودة):
✅ إحصائيات شاملة
✅ مقاييس الأداء
✅ استخدام الموارد
✅ Quick Navigation لـ Analytics & Reports

#### التحسينات المقترحة (للتنفيذ):

**A. إضافة Dispatcher Quick Access:**
```dart
Widget _buildDispatcherAccess(BuildContext context, WidgetRef ref) {
  return Card(
    child: ListTile(
      leading: Icon(Icons.dashboard, color: AppColors.primary),
      title: Text('عرض لوحة المشغل'),
      subtitle: Text('انتقل إلى واجهة Dispatcher'),
      trailing: Icon(Icons.arrow_forward),
      onTap: () {
        // Switch role to Dispatcher
        ref.read(roleSwitcherServiceProvider).setActiveRole(UserRole.dispatcher);
        ref.read(activeRoleProvider.notifier).state = UserRole.dispatcher;
        context.go(RoutePaths.dispatcherHome);
      },
    ),
  );
}
```

**B. إضافة Real-time Updates:**
```dart
// Auto-refresh Analytics كل 30 ثانية
Timer.periodic(Duration(seconds: 30), (_) {
  ref.invalidate(managerAnalyticsProvider);
});
```

**C. إضافة Charts (باستخدام fl_chart):**
```dart
import 'package:fl_chart/fl_chart.dart';

Widget _buildTripTrendChart(List<TripData> data) {
  return Container(
    height: 200,
    child: LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: data.map((d) => FlSpot(d.day, d.count)).toList(),
            isCurved: true,
            color: AppColors.primary,
          ),
        ],
      ),
    ),
  );
}
```

---

### 4️⃣ **سيناريوهات الاستخدام**

#### السيناريو 1: المدير يريد رؤية واجهة Dispatcher

```
1. المدير يفتح التطبيق (Manager Home)
2. يضغط على أيقونة Role Switcher في AppBar
3. يظهر Bottom Sheet مع الأدوار المتاحة
4. يختار "مشغل"
5. يتم:
   - حفظ الاختيار
   - الانتقال لـ Dispatcher Home
   - عرض notification "تم التبديل إلى عرض مشغل"
6. يرى المدير كل ما يراه المشغل
7. للعودة: يضغط "العودة" في Role Switcher
8. يعود لـ Manager Home
```

#### السيناريو 2: المدير يريد متابعة رحلة معينة

```
1. من Manager Dashboard
2. Role Switcher → Driver
3. يفتح Driver Home
4. يرى جميع الرحلات
5. يفتح رحلة معينة
6. يرى Live Map و tracking
7. يرى ما يراه السائق بالضبط
8. يمكنه اختبار الميزات
9. يعود للـ Manager View
```

#### السيناريو 3: Dispatcher يريد رؤية تجربة السائق

```
1. Dispatcher Home
2. Role Switcher → Driver
3. يتحقق من سهولة الاستخدام
4. يختبر الميزات
5. يعود لـ Dispatcher
```

---

### 5️⃣ **الميزات المتقدمة المتاحة**

#### A. Role-Based Permissions
```dart
class PermissionService {
  bool canViewAnalytics(User user, UserRole activeRole) {
    // Manager يمكنه رؤية كل شيء
    if (user.role == UserRole.manager) return true;

    // Dispatcher يرى analytics محدودة
    if (activeRole == UserRole.dispatcher) return true;

    return false;
  }

  bool canEditTrip(User user, UserRole activeRole) {
    return user.role == UserRole.manager ||
           activeRole == UserRole.dispatcher;
  }
}
```

#### B. Audit Trail
```dart
// تسجيل تبديل الأدوار
class AuditService {
  void logRoleSwitch(User user, UserRole from, UserRole to) {
    // Log to backend
    api.post('/audit/role-switch', {
      'user_id': user.id,
      'from_role': from.value,
      'to_role': to.value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

#### C. Time-limited Access
```dart
class RoleSwitcherService {
  Future<void> setActiveRole(
    UserRole role,
    {Duration? duration}
  ) async {
    await _prefs.setString(_activeRoleKey, role.value);

    if (duration != null) {
      // Auto-revert after duration
      Timer(duration, () async {
        await clearActiveRole();
      });
    }
  }
}

// Usage:
await roleSwitcher.setActiveRole(
  UserRole.driver,
  duration: Duration(hours: 1), // عودة تلقائية بعد ساعة
);
```

---

### 6️⃣ **التخصيصات المقترحة**

#### A. إضافة Badges للأدوار النشطة
```dart
// في AppBar
Badge(
  isLabelVisible: activeRole != null && activeRole != user.role,
  label: Text(activeRole?.arabicLabel ?? ''),
  child: Icon(Icons.swap_horiz),
)
```

#### B. تغيير لون Theme حسب الدور
```dart
Color getThemeColor(UserRole role) {
  switch (role) {
    case UserRole.manager:
      return Colors.red; // المدير - أحمر
    case UserRole.dispatcher:
      return Colors.blue; // المشغل - أزرق
    case UserRole.driver:
      return Colors.green; // السائق - أخضر
    case UserRole.passenger:
      return Colors.purple; // الراكب - بنفسجي
  }
}
```

#### C. إضافة Watermark
```dart
// عندما يكون في وضع العرض
if (activeRole != null && activeRole != user.role) {
  return Stack(
    children: [
      // Normal content
      child,

      // Watermark
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          padding: EdgeInsets.all(8),
          child: Text(
            'وضع العرض: ${activeRole.arabicLabel}',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ],
  );
}
```

---

### 7️⃣ **الأمان والصلاحيات**

#### التحقق من الصلاحيات:
```dart
class SecurityService {
  // التحقق قبل السماح بالتبديل
  Future<bool> validateRoleSwitch(
    User user,
    UserRole targetRole,
  ) async {
    // 1. التحقق من الصلاحيات المحلية
    if (!roleSwitcher.canSwitchToRole(user, targetRole)) {
      return false;
    }

    // 2. التحقق من الصلاحيات على السيرفر
    final response = await api.post('/auth/validate-role-switch', {
      'target_role': targetRole.value,
    });

    return response['allowed'] == true;
  }

  // منع بعض الإجراءات في وضع العرض
  bool canPerformAction(User user, UserRole activeRole, String action) {
    // في وضع العرض، لا يمكن تعديل البيانات
    if (activeRole != user.role) {
      return action == 'view'; // قراءة فقط
    }

    return true;
  }
}
```

---

### 8️⃣ **الإحصائيات المتقدمة للمدير**

#### المقاييس الحالية:
- ✅ إجمالي الرحلات
- ✅ معدل الإنجاز
- ✅ معدل الإلغاء
- ✅ عدد الركاب
- ✅ معدل الإشغال
- ✅ النسبة في الموعد
- ✅ متوسط التأخير
- ✅ المسافة الكلية
- ✅ تكلفة الوقود

#### المقاييس المقترحة للإضافة:
- 📊 معدل رضا الركاب
- 📊 أداء السائقين (تقييم)
- 📊 تحليل المسارات الأكثر استخداماً
- 📊 معدل الأعطال/الصيانة
- 📊 تكلفة الرحلة الواحدة
- 📊 الإيرادات المتوقعة
- 📊 التوفير في التكاليف

---

### 9️⃣ **التقارير المتاحة**

#### تقارير يومية:
- عدد الرحلات المنفذة
- الركاب المنقولون
- الحوادث/المشاكل
- حالة المركبات

#### تقارير شهرية:
- الأداء الشامل
- التحليلات المالية
- مقارنة بالشهر السابق
- التوصيات

#### تقارير سنوية:
- الملخص السنوي
- Growth trends
- Budget analysis
- Strategic recommendations

---

### 🔟 **Next Steps (الخطوات التالية)**

#### للبدء الفوري:

1. **تهيئة RoleSwitcherService في main.dart**
2. **إضافة RoleSwitcherButton في Manager AppBar**
3. **إضافة RoleSwitcherWidget في Manager Home**
4. **اختبار التبديل بين الأدوار**

#### للتحسينات المتقدمة:

5. **إضافة Charts في Analytics Screen**
6. **تنفيذ Reports Screen**
7. **إضافة Real-time notifications**
8. **تنفيذ Audit Trail**
9. **إضافة Permission System**
10. **Export reports to PDF/Excel**

---

## 🎁 الكود الجاهز

### main.dart Update:
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/role_switcher_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        roleSwitcherServiceProvider.overrideWithValue(
          RoleSwitcherService(prefs),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Manager Home Screen Update:
```dart
// في أعلى الملف
import '../../core/widgets/role_switcher_widget.dart';

// في AppBar
appBar: AppBar(
  title: const Text('لوحة تحكم المدير'),
  actions: [
    const RoleSwitcherButton(), // <-- إضافة
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () => ref.invalidate(managerAnalyticsProvider),
    ),
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => _handleLogout(context, ref),
    ),
  ],
),

// في Body - بعد RefreshIndicator مباشرة
body: RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(managerAnalyticsProvider);
  },
  child: SingleChildScrollView(
    child: Column(
      children: [
        const RoleSwitcherWidget(), // <-- إضافة

        // rest of content...
      ],
    ),
  ),
),
```

---

## ✅ الملخص

تم تنفيذ نظام متقدم للتبديل بين الأدوار يسمح للمدير بـ:
- ✅ التبديل بين جميع الأدوار (Manager, Dispatcher, Driver, Passenger)
- ✅ رؤية ما يراه كل دور بالضبط
- ✅ العودة السريعة للدور الأصلي
- ✅ واجهة سهلة وبديهية
- ✅ حفظ الاختيار في SharedPreferences
- ✅ إشعارات واضحة عند التبديل
- ✅ دعم كامل للأدوار المتعددة

**المدير الآن يمكنه الاطلاع على واجهة Dispatcher (والأدوار الأخرى) بسهولة تامة!** 🎯
