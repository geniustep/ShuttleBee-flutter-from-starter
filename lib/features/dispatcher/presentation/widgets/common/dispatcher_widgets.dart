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

// === Common Widgets ===
export 'dispatcher_app_bar.dart';
export 'dispatcher_action_fab.dart';
export 'dispatcher_footer.dart';
export 'dispatcher_search_field.dart';

// === Headers ===
export '../headers/dispatcher_unified_header.dart';
export '../headers/dispatcher_secondary_header.dart';

// === Passenger Widgets ===
export '../passengers/dispatcher_add_passenger_sheet.dart';
export '../passengers/passenger_quick_actions_sheet.dart';
export '../passengers/change_location_sheet.dart';
export '../passengers/empty_passengers_view.dart';
export '../passengers/passengers_list_section.dart';
export '../passengers/passenger_stats_row.dart';
export '../passengers/passenger_tile.dart';

// === Trip Widgets ===
export '../trips/dispatcher_add_trip_passenger_sheet.dart';
export '../trips/select_trip_for_absence_sheet.dart';
export '../trips/trip_search_bar.dart';
export '../trips/advanced_filter_sheet.dart';
export '../trips/trips_search_bar.dart';
export '../trips/trips_advanced_filter_sheet.dart';
