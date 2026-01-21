import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 🖥️ Platform Utilities - أدوات المنصة
/// فئة مساعدة للتعامل مع خصوصيات المنصات المختلفة
class PlatformUtils {
  PlatformUtils._();

  // === Platform Detection ===

  /// هل نعمل على Windows؟
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// هل نعمل على macOS؟
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// هل نعمل على Linux؟
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// هل نعمل على Desktop؟
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// هل نعمل على Android؟
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// هل نعمل على iOS؟
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// هل نعمل على Mobile؟
  static bool get isMobile => isAndroid || isIOS;

  /// هل نعمل على الويب؟
  static bool get isWeb => kIsWeb;

  // === Platform-Specific Features ===

  /// هل تحتاج المنصة لتحميل أولي للبيانات؟
  /// Windows يحتاج تحميل أولي لتحسين الأداء
  static bool get needsInitialDataLoad => isWindows;

  /// هل تدعم المنصة التخزين المؤقت المتقدم؟
  static bool get supportsAdvancedCaching => isDesktop;

  /// هل تدعم المنصة الإشعارات المحلية؟
  static bool get supportsLocalNotifications => !isWeb;

  /// هل تدعم المنصة تتبع الموقع في الخلفية؟
  static bool get supportsBackgroundLocation => isMobile;

  /// هل تدعم المنصة Haptic Feedback؟
  static bool get supportsHapticFeedback => isMobile;

  // === Platform-Specific Configuration ===

  /// الحد الأقصى لعناصر الكاش حسب المنصة
  static int get maxCacheItems {
    if (isDesktop) return 1000;
    if (isMobile) return 500;
    return 200; // Web
  }

  /// مدة صلاحية الكاش بالدقائق حسب المنصة
  static int get cacheDurationMinutes {
    if (isDesktop) return 60;
    if (isMobile) return 30;
    return 15; // Web
  }

  /// حجم الـ batch للتحميل حسب المنصة
  static int get batchLoadSize {
    if (isDesktop) return 100;
    if (isMobile) return 50;
    return 25; // Web
  }

  /// تأخير التحميل الأولي بالمللي ثانية
  static int get initialLoadDelayMs {
    if (isWindows) return 100; // Windows يحتاج تأخير بسيط
    return 0;
  }

  // === Platform Name ===

  /// اسم المنصة الحالية
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  /// اسم المنصة بالعربية
  static String get platformNameArabic {
    if (kIsWeb) return 'ويب';
    if (Platform.isWindows) return 'ويندوز';
    if (Platform.isMacOS) return 'ماك';
    if (Platform.isLinux) return 'لينكس';
    if (Platform.isAndroid) return 'أندرويد';
    if (Platform.isIOS) return 'آيفون';
    return 'غير معروف';
  }
}

/// 📱 Platform-Aware Mixin
/// يمكن استخدامه مع StatefulWidget للتعامل مع خصوصيات المنصة
mixin PlatformAwareMixin<T extends StatefulWidget> on State<T> {
  /// هل نعمل على Desktop؟
  bool get isDesktopPlatform => PlatformUtils.isDesktop;

  /// هل نعمل على Mobile؟
  bool get isMobilePlatform => PlatformUtils.isMobile;

  /// هل نحتاج تحميل أولي؟
  bool get needsInitialLoad => PlatformUtils.needsInitialDataLoad;

  /// تنفيذ كود خاص بالمنصة
  void runPlatformSpecific({
    VoidCallback? onWindows,
    VoidCallback? onMacOS,
    VoidCallback? onLinux,
    VoidCallback? onAndroid,
    VoidCallback? onIOS,
    VoidCallback? onWeb,
    VoidCallback? onDesktop,
    VoidCallback? onMobile,
  }) {
    if (PlatformUtils.isWindows) {
      onWindows?.call();
      onDesktop?.call();
    } else if (PlatformUtils.isMacOS) {
      onMacOS?.call();
      onDesktop?.call();
    } else if (PlatformUtils.isLinux) {
      onLinux?.call();
      onDesktop?.call();
    } else if (PlatformUtils.isAndroid) {
      onAndroid?.call();
      onMobile?.call();
    } else if (PlatformUtils.isIOS) {
      onIOS?.call();
      onMobile?.call();
    } else if (PlatformUtils.isWeb) {
      onWeb?.call();
    }
  }
}


