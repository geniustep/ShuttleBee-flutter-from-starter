import 'package:flutter/material.dart';

/// App localizations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  /// Localization delegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Get current instance
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Check if RTL
  bool get isRtl => locale.languageCode == 'ar';

  /// Translations map
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // General
      'app_name': 'BridgeCore Starter',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'search': 'Search',
      'retry': 'Retry',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',

      // Auth
      'login': 'Login',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'username': 'Username',
      'server_url': 'Server URL',
      'database': 'Database',
      'remember_me': 'Remember me',
      'forgot_password': 'Forgot password?',
      'login_success': 'Login successful',
      'login_failed': 'Login failed',
      'invalid_credentials': 'Invalid username or password',
      'logout_confirm': 'Are you sure you want to logout?',
      'select_company': 'Select Company',

      // Home
      'home': 'Home',
      'dashboard': 'Dashboard',
      'welcome': 'Welcome',
      'quick_actions': 'Quick Actions',
      'recent_activities': 'Recent Activities',

      // Settings
      'settings': 'Settings',
      'profile': 'Profile',
      'appearance': 'Appearance',
      'language': 'Language',
      'theme': 'Theme',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'system_default': 'System Default',
      'notifications_settings': 'Notification Settings',
      'privacy_security': 'Privacy & Security',
      'about': 'About',
      'version': 'Version',

      // Offline
      'offline': 'Offline',
      'online': 'Online',
      'offline_mode': 'Offline Mode',
      'sync': 'Sync',
      'syncing': 'Syncing...',
      'sync_complete': 'Sync complete',
      'sync_failed': 'Sync failed',
      'pending_operations': 'Pending Operations',
      'no_pending_operations': 'No pending operations',
      'last_sync': 'Last sync',
      'offline_banner': "You're working offline",

      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications',
      'mark_all_read': 'Mark all as read',

      // Search
      'search_placeholder': 'Search...',
      'no_results': 'No results found',
      'recent_searches': 'Recent Searches',

      // Errors
      'error_generic': 'Something went wrong',
      'error_network': 'Network error',
      'error_server': 'Server error',
      'error_timeout': 'Connection timed out',
      'error_no_connection': 'No internet connection',

      // Empty States
      'empty_data': 'No data available',
      'empty_list': 'The list is empty',
    },
    'ar': {
      // General
      'app_name': 'بريدج كور',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'close': 'إغلاق',
      'search': 'بحث',
      'retry': 'إعادة المحاولة',
      'yes': 'نعم',
      'no': 'لا',
      'ok': 'حسناً',

      // Auth
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'username': 'اسم المستخدم',
      'server_url': 'عنوان الخادم',
      'database': 'قاعدة البيانات',
      'remember_me': 'تذكرني',
      'forgot_password': 'نسيت كلمة المرور؟',
      'login_success': 'تم تسجيل الدخول بنجاح',
      'login_failed': 'فشل تسجيل الدخول',
      'invalid_credentials': 'اسم المستخدم أو كلمة المرور غير صحيحة',
      'logout_confirm': 'هل أنت متأكد من تسجيل الخروج؟',
      'select_company': 'اختر الشركة',

      // Home
      'home': 'الرئيسية',
      'dashboard': 'لوحة التحكم',
      'welcome': 'مرحباً',
      'quick_actions': 'إجراءات سريعة',
      'recent_activities': 'الأنشطة الأخيرة',

      // Settings
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'appearance': 'المظهر',
      'language': 'اللغة',
      'theme': 'السمة',
      'light_mode': 'الوضع الفاتح',
      'dark_mode': 'الوضع الداكن',
      'system_default': 'الإعداد الافتراضي',
      'notifications_settings': 'إعدادات الإشعارات',
      'privacy_security': 'الخصوصية والأمان',
      'about': 'حول',
      'version': 'الإصدار',

      // Offline
      'offline': 'غير متصل',
      'online': 'متصل',
      'offline_mode': 'وضع عدم الاتصال',
      'sync': 'مزامنة',
      'syncing': 'جاري المزامنة...',
      'sync_complete': 'تمت المزامنة',
      'sync_failed': 'فشلت المزامنة',
      'pending_operations': 'العمليات المعلقة',
      'no_pending_operations': 'لا توجد عمليات معلقة',
      'last_sync': 'آخر مزامنة',
      'offline_banner': 'أنت تعمل بدون اتصال',

      // Notifications
      'notifications': 'الإشعارات',
      'no_notifications': 'لا توجد إشعارات',
      'mark_all_read': 'تحديد الكل كمقروء',

      // Search
      'search_placeholder': 'بحث...',
      'no_results': 'لم يتم العثور على نتائج',
      'recent_searches': 'عمليات البحث الأخيرة',

      // Errors
      'error_generic': 'حدث خطأ ما',
      'error_network': 'خطأ في الشبكة',
      'error_server': 'خطأ في الخادم',
      'error_timeout': 'انتهت مهلة الاتصال',
      'error_no_connection': 'لا يوجد اتصال بالإنترنت',

      // Empty States
      'empty_data': 'لا توجد بيانات',
      'empty_list': 'القائمة فارغة',
    },
  };

  /// Get translation
  String translate(String key) {
    return _translations[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters
  String get appName => translate('app_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get close => translate('close');
  String get search => translate('search');
  String get retry => translate('retry');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get login => translate('login');
  String get logout => translate('logout');
  String get email => translate('email');
  String get password => translate('password');
  String get username => translate('username');
  String get serverUrl => translate('server_url');
  String get database => translate('database');
  String get rememberMe => translate('remember_me');
  String get home => translate('home');
  String get dashboard => translate('dashboard');
  String get settings => translate('settings');
  String get profile => translate('profile');
  String get notifications => translate('notifications');
  String get offline => translate('offline');
  String get online => translate('online');
  String get sync => translate('sync');
}

/// Localization delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension for easy access
extension LocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
