// ignore_for_file: unused_element, dead_code

import 'package:bridgecore_flutter_starter/core/utils/logger.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger_config.dart';

/// مثال على استخدام نظام الـ Logging الجديد
///
/// هذا الملف للتوضيح فقط - لا يتم تشغيله في التطبيق
class LoggerExample {
  /// مثال 1: استخدام Categories في Network requests
  Future<void> exampleNetworkRequest() async {
    // Before the request
    AppLogger.debug(
      'Fetching user data from API',
      null,
      null,
      LogCategory.network,
    );

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Success
      AppLogger.info(
        'User data fetched successfully',
        null,
        null,
        LogCategory.network,
      );
    } catch (e, stackTrace) {
      // Error
      AppLogger.error(
        'Failed to fetch user data',
        e,
        stackTrace,
        LogCategory.network,
      );
    }
  }

  /// مثال 2: استخدام Categories في Auth
  Future<void> exampleLogin(String email, String password) async {
    AppLogger.info('User attempting to login', null, null, LogCategory.auth);

    try {
      // Simulate login
      await Future.delayed(const Duration(seconds: 1));

      AppLogger.info(
        'Login successful for: $email',
        null,
        null,
        LogCategory.auth,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Login failed',
        e,
        stackTrace,
        LogCategory.auth,
      );
    }
  }

  /// مثال 3: استخدام Categories في GPS/Tracking
  Future<void> exampleGpsTracking() async {
    AppLogger.debug(
      'Starting GPS tracking',
      null,
      null,
      LogCategory.tracking,
    );

    try {
      // Simulate GPS update
      final lat = 31.7917;
      final lng = -7.0926;

      AppLogger.debug(
        'GPS position: $lat, $lng',
        null,
        null,
        LogCategory.tracking,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'GPS tracking error',
        e,
        stackTrace,
        LogCategory.tracking,
      );
    }
  }

  /// مثال 4: استخدام Categories في Database
  Future<void> exampleDatabaseOperation() async {
    AppLogger.debug(
      'Saving to local database',
      null,
      null,
      LogCategory.database,
    );

    try {
      // Simulate DB operation
      await Future.delayed(const Duration(milliseconds: 100));

      AppLogger.info(
        'Data saved successfully',
        null,
        null,
        LogCategory.database,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Database error',
        e,
        stackTrace,
        LogCategory.database,
      );
    }
  }

  /// مثال 5: استخدام Categories في UI
  void exampleUiEvent() {
    AppLogger.debug(
      'Button clicked: Submit Form',
      null,
      null,
      LogCategory.ui,
    );

    AppLogger.debug(
      'Dialog opened: Confirmation',
      null,
      null,
      LogCategory.ui,
    );
  }

  /// مثال 6: استخدام Categories في Sync
  Future<void> exampleSyncOperation() async {
    AppLogger.info(
      'Starting data synchronization',
      null,
      null,
      LogCategory.sync,
    );

    try {
      // Simulate sync
      await Future.delayed(const Duration(seconds: 2));

      AppLogger.info(
        'Sync completed: 150 items synced',
        null,
        null,
        LogCategory.sync,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Sync failed',
        e,
        stackTrace,
        LogCategory.sync,
      );
    }
  }

  /// مثال 7: استخدام Categories في Notifications
  void exampleNotification() {
    AppLogger.info(
      'Push notification received: New trip assigned',
      null,
      null,
      LogCategory.notification,
    );
  }

  /// مثال 8: تغيير إعدادات الـ Logger أثناء runtime
  void exampleChangeLoggerConfig() {
    // طريقة 1: استخدام Presets
    LoggerConfig.minimal(); // Show only important logs
    LoggerConfig.networkOnly(); // Show only network logs
    LoggerConfig.trackingOnly(); // Show only tracking logs

    // طريقة 2: تعطيل/تفعيل Categories يدوياً
    AppLogger.disableCategory(LogCategory.network);
    AppLogger.enableCategory(LogCategory.auth);

    // طريقة 3: عرض الإعدادات الحالية
    LoggerConfig.printConfig();
  }

  /// مثال 9: General logs (بدون category محدد)
  void exampleGeneralLogs() {
    // If you don't specify a category, it defaults to LogCategory.general
    AppLogger.debug('This is a general debug message');
    AppLogger.info('This is a general info message');
    AppLogger.warning('This is a general warning message');
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// كيفية استخدام Logger في الكود الفعلي
/// ════════════════════════════════════════════════════════════════════════════

// في ملف Service:
class MyNetworkService {
  Future<void> fetchData() async {
    AppLogger.debug('Fetching data...', null, null, LogCategory.network);

    try {
      // ... network call ...
      AppLogger.info('Data fetched', null, null, LogCategory.network);
    } catch (e, st) {
      AppLogger.error('Fetch failed', e, st, LogCategory.network);
    }
  }
}

// في ملف Provider/Notifier:
class MyAuthProvider {
  Future<void> login() async {
    AppLogger.info('Login started', null, null, LogCategory.auth);

    // ... login logic ...

    AppLogger.info('Login success', null, null, LogCategory.auth);
  }
}

// في ملف Widget:
class MyWidget {
  void onButtonPressed() {
    AppLogger.debug('Button pressed', null, null, LogCategory.ui);
    // ... handle button press ...
  }
}
