# نظام التخطيط الموحد للمنسق (Dispatcher Unified Layout System)

مجموعة من الـ widgets الموحدة لصفحات المنسق في تطبيق ShuttleBee، توفر تجربة مستخدم متناسقة وتدعم التصميم المتجاوب (Responsive Design).

## المكونات الرئيسية

### 1. DispatcherAppBar
هايدر رئيسي موحد مع gradient مخصص للمنسق.

#### الميزات:
- تصميم متجاوب يتكيف مع حجم الشاشة
- دعم العنوان والعنوان الفرعي
- أزرار إجراءات قابلة للتخصيص
- دعم bottom widget (مثل TabBar)
- ظل اختياري

#### مثال الاستخدام:
```dart
DispatcherAppBar(
  title: 'إدارة المجموعات',
  subtitle: 'إجمالي: 25 • نشطة: 20', // اختياري
  actions: [
    const RoleSwitcherButton(),
    IconButton(
      icon: const Icon(Icons.refresh_rounded),
      onPressed: _onRefresh,
    ),
  ],
  bottom: const TabBar(...), // اختياري
)
```

---

### 2. DispatcherSecondaryHeader
هايدر ثانوي للبحث والفلترة والإحصائيات السريعة.

#### الميزات:
- شريط بحث موحد
- أزرار فلترة ديناميكية
- إحصائيات سريعة قابلة للنقر
- تصميم متجاوب
- دعم محتوى مخصص

#### مثال الاستخدام:
```dart
DispatcherSecondaryHeader(
  searchHint: 'ابحث عن مجموعة...',
  searchValue: _searchQuery,
  onSearchChanged: (value) => setState(() => _searchQuery = value),
  onSearchClear: () => setState(() => _searchQuery = ''),
  
  // أزرار الإجراءات
  actions: [
    IconButton(
      icon: const Icon(Icons.tune_rounded),
      onPressed: _openFilters,
      style: IconButton.styleFrom(
        backgroundColor: _hasFilters 
          ? AppColors.dispatcherPrimary 
          : Colors.grey.shade200,
      ),
    ),
  ],
  
  // شرائح الفلترة النشطة
  filters: [
    DispatcherFilterChip(
      label: 'نشطة فقط',
      isSelected: true,
      onTap: () => setState(() => _showActive = false),
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
      badge: '12', // اختياري
    ),
  ],
  
  // إحصائيات سريعة
  stats: [
    DispatcherStatChip(
      icon: Icons.groups_rounded,
      label: 'المجموعات',
      value: '25',
      color: AppColors.dispatcherPrimary,
      onTap: () {}, // اختياري
    ),
  ],
)
```

#### مكونات فرعية:

##### DispatcherFilterChip
شريحة فلترة مع حالة اختيار.

```dart
DispatcherFilterChip(
  label: 'نشطة فقط',
  isSelected: true,
  onTap: () => _toggleFilter(),
  icon: Icons.check_circle_rounded, // اختياري
  color: AppColors.success, // اختياري
  badge: '12', // اختياري - عدد العناصر
)
```

##### DispatcherStatChip
شريحة إحصائية مع أيقونة وقيمة.

```dart
DispatcherStatChip(
  icon: Icons.groups_rounded,
  label: 'المجموعات',
  value: '25',
  color: AppColors.dispatcherPrimary, // اختياري
  onTap: () {}, // اختياري - للتفاعل
)
```

---

### 3. DispatcherFooter
فوتر موحد يحتوي على معلومات وإجراءات وحالة المزامنة.

#### الميزات:
- أزرار إجراءات رئيسية
- معلومات نصية (مثل عدد العناصر)
- مؤشر حالة المزامنة
- تخطيط متجاوب (عمودي للموبايل، أفقي للديسكتوب)
- ظل قابل للتخصيص

#### مثال الاستخدام:
```dart
DispatcherFooter(
  info: 'عرض 20 من 25 مجموعة',
  syncStatus: DispatcherSyncStatus.synced,
  actions: [
    DispatcherFooterAction(
      icon: Icons.add_rounded,
      label: 'إضافة جديد',
      isPrimary: true,
      onPressed: _onAdd,
    ),
    DispatcherFooterAction(
      icon: Icons.clear_all_rounded,
      label: 'مسح الفلاتر',
      onPressed: _onClearFilters,
    ),
  ],
  elevation: 8.0, // اختياري
  showShadow: true, // اختياري
)
```

#### حالات المزامنة:
```dart
enum DispatcherSyncStatus {
  synced,    // متزامن ✓
  syncing,   // جاري المزامنة ⟳
  offline,   // غير متصل ✗
}
```

---

## مثال كامل

راجع ملف `dispatcher_layout_example.dart` للحصول على مثال شامل يوضح جميع المكونات معاً.

```dart
Scaffold(
  backgroundColor: const Color(0xFFF8FAFC),
  
  // الهايدر الرئيسي
  appBar: DispatcherAppBar(
    title: 'إدارة المجموعات',
    subtitle: 'إجمالي: 25 • نشطة: 20',
    actions: [...],
  ),
  
  body: Column(
    children: [
      // الهايدر الثانوي
      DispatcherSecondaryHeader(
        searchHint: '...',
        searchValue: _searchQuery,
        onSearchChanged: _onSearch,
        filters: [...],
        stats: [...],
      ),
      
      // المحتوى
      Expanded(child: _buildContent()),
    ],
  ),
  
  // الفوتر
  bottomNavigationBar: DispatcherFooter(
    info: 'عرض 20 من 25',
    syncStatus: DispatcherSyncStatus.synced,
    actions: [...],
  ),
)
```

---

## التصميم المتجاوب (Responsive Design)

جميع المكونات تدعم التصميم المتجاوب تلقائياً باستخدام `ResponsiveUtils`:

### نقاط التوقف (Breakpoints):
- **Mobile**: < 600px
- **Tablet**: 600px - 1200px
- **Desktop**: > 1200px

### التكيف التلقائي:
- أحجام الخطوط
- المسافات (Padding & Spacing)
- أحجام الأيقونات
- تخطيط الفوتر (عمودي/أفقي)
- عرض العناصر

### استخدام ResponsiveUtils:
```dart
// في أي widget
context.responsive(
  mobile: 12.0,
  tablet: 16.0,
  desktop: 20.0,
)

// أو
context.isMobile  // true/false
context.isTablet  // true/false
context.isDesktop // true/false
```

---

## الألوان المخصصة للمنسق

```dart
// الألوان الأساسية
AppColors.dispatcherPrimary        // #8B5CF6 (Purple 500)
AppColors.dispatcherPrimaryDark    // #6D28D9 (Purple 700)
AppColors.dispatcherPrimaryLight   // #A78BFA (Purple 400)
AppColors.dispatcherBackground     // #FAF5FF (Purple 50)

// Gradient
AppColors.dispatcherGradient       // Purple gradient
```

---

## نصائح الاستخدام

### 1. الاتساق
استخدم هذه المكونات في جميع صفحات المنسق للحفاظ على الاتساق.

### 2. التخصيص
يمكنك تخصيص الألوان والأيقونات حسب الحاجة، لكن حافظ على البنية العامة.

### 3. الأداء
- استخدم `const` حيثما أمكن
- تجنب إعادة بناء المكونات غير الضرورية
- استخدم `maybeWhen` بدلاً من `when` عند عدم الحاجة لجميع الحالات

### 4. إمكانية الوصول
- أضف `tooltip` لجميع الأزرار
- استخدم `HapticFeedback` للتفاعل اللمسي
- تأكد من التباين الكافي للألوان

---

## التحديثات المستقبلية

- [ ] دعم Dark Mode
- [ ] رسوم متحركة محسّنة
- [ ] دعم RTL أفضل
- [ ] مكونات إضافية (Tabs، Chips، Cards)

---

## المساهمة

عند إضافة مكونات جديدة:
1. اتبع نمط التصميم الحالي
2. أضف دعم Responsive Design
3. وثّق الاستخدام مع أمثلة
4. اختبر على جميع أحجام الشاشات

---

## الدعم

للأسئلة أو المشاكل، راجع:
- `/lib/features/dispatcher/presentation/widgets/dispatcher_layout_example.dart`
- `/lib/core/utils/responsive_utils.dart`
- `/lib/core/theme/app_colors.dart`
