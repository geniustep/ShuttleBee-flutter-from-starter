/// Unified Dispatcher Widgets - مكونات المنسق الموحدة
///
/// مجموعة من الـ widgets الموحدة لصفحات المنسق في تطبيق ShuttleBee
/// تدعم التصميم المتجاوب وتوفر تجربة مستخدم متناسقة
///
/// ## الاستخدام:
/// ```dart
/// import 'package:your_app/features/dispatcher/presentation/widgets/dispatcher_widgets.dart';
/// ```
///
/// ## المكونات الرئيسية:
/// - [DispatcherUnifiedHeader]: هيدر موحد ومستجيب لجميع الأجهزة
/// - [DispatcherActionFAB]: FAB للأزرار الرئيسية (يظهر على الهاتف فقط)
/// - [DispatcherFooter]: فوتر مع أزرار (يظهر على Tablet/Desktop فقط)
/// - [DispatcherSecondaryHeader]: هيدر ثانوي للبحث والفلاتر (deprecated)
///
/// راجع README.md للحصول على أمثلة كاملة للاستخدام

library;

// === المكونات الجديدة الموحدة ===
export 'dispatcher_unified_header.dart';
export 'dispatcher_action_fab.dart';

// === المكونات الأساسية ===
export 'dispatcher_app_bar.dart';
export 'dispatcher_secondary_header.dart';
export 'dispatcher_footer.dart';
export 'dispatcher_search_field.dart';
