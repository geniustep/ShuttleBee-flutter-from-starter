/// Error Translator - ShuttleBee
///
/// يترجم رسائل الأخطاء التقنية إلى رسائل مفهومة للمستخدم
class ErrorTranslator {
  /// ترجمة رسالة الخطأ إلى العربية
  static String translate(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    // Network errors
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('internet')) {
      return 'خطأ في الاتصال بالإنترنت. يرجى التحقق من الاتصال';
    }

    // Timeout errors
    if (lowerError.contains('timeout') ||
        lowerError.contains('time out') ||
        lowerError.contains('timed out')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
    }

    // Authentication errors
    if (lowerError.contains('unauthorized') ||
        lowerError.contains('401') ||
        lowerError.contains('unauthenticated')) {
      return 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى';
    }

    // Missing Odoo Credentials (token doesn't have tenant info)
    if (lowerError.contains('missing odoo credentials') ||
        lowerError.contains('tenant jwt token')) {
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الخروج وإعادة تسجيل الدخول';
    }

    // Permission errors
    if (lowerError.contains('forbidden') ||
        lowerError.contains('403') ||
        lowerError.contains('permission')) {
      return 'ليس لديك صلاحية للقيام بهذا الإجراء';
    }

    // Not found errors
    if (lowerError.contains('not found') ||
        lowerError.contains('404') ||
        lowerError.contains('does not exist')) {
      return 'لم يتم العثور على البيانات المطلوبة';
    }

    // Server errors
    if (lowerError.contains('server') ||
        lowerError.contains('500') ||
        lowerError.contains('502') ||
        lowerError.contains('503')) {
      return 'خطأ في الخادم. يرجى المحاولة لاحقاً';
    }

    // Validation errors
    if (lowerError.contains('invalid') || lowerError.contains('validation')) {
      return 'البيانات المدخلة غير صحيحة';
    }

    // Database errors
    if (lowerError.contains('database') ||
        lowerError.contains('query') ||
        lowerError.contains('sql')) {
      return 'خطأ في قاعدة البيانات. يرجى المحاولة لاحقاً';
    }

    // Parse errors
    if (lowerError.contains('parse') ||
        lowerError.contains('format') ||
        lowerError.contains('json')) {
      return 'خطأ في معالجة البيانات';
    }

    // Cache errors
    if (lowerError.contains('cache')) {
      return 'خطأ في التخزين المؤقت';
    }

    // File errors
    if (lowerError.contains('file') || lowerError.contains('storage')) {
      return 'خطأ في الوصول إلى الملفات';
    }

    // Location errors
    if (lowerError.contains('location') ||
        lowerError.contains('gps') ||
        lowerError.contains('position')) {
      return 'خطأ في تحديد الموقع. يرجى تفعيل خدمات الموقع';
    }

    // Default error message
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
  }

  /// ترجمة رسالة خطأ Repository
  static String translateFailure(String failureMessage) {
    // Check if it's already a translated message
    if (failureMessage.contains('خطأ') ||
        failureMessage.contains('يرجى') ||
        failureMessage.contains('لم يتم')) {
      return failureMessage;
    }

    return translate(failureMessage);
  }

  /// ترجمة رسالة خطأ مع سياق إضافي
  static String translateWithContext(
    String errorMessage, {
    String? context,
  }) {
    final translated = translate(errorMessage);

    if (context != null && context.isNotEmpty) {
      return '$context: $translated';
    }

    return translated;
  }

  /// الحصول على رسالة خطأ لحالة معينة
  static String getMessageForState(String state) {
    switch (state.toLowerCase()) {
      case 'loading':
        return 'جاري التحميل...';
      case 'empty':
        return 'لا توجد بيانات';
      case 'offline':
        return 'أنت غير متصل بالإنترنت';
      case 'no_data':
        return 'لا توجد بيانات متاحة';
      case 'no_trips':
        return 'لا توجد رحلات';
      case 'no_passengers':
        return 'لا يوجد ركاب';
      case 'no_vehicles':
        return 'لا توجد مركبات';
      case 'session_expired':
        return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
      case 'credentials_error':
        return 'انتهت صلاحية الجلسة. يرجى تسجيل الخروج وإعادة تسجيل الدخول';
      default:
        return 'لا توجد بيانات';
    }
  }

  /// التحقق مما إذا كان الخطأ يتطلب إعادة تسجيل الدخول (من رسالة الخطأ الأصلية)
  static bool requiresReLogin(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();
    return lowerError.contains('missing odoo credentials') ||
        lowerError.contains('tenant jwt token') ||
        lowerError.contains('session expired') ||
        lowerError.contains('unauthorized') ||
        lowerError.contains('401');
  }

  /// التحقق مما إذا كان الخطأ يتطلب إعادة تسجيل الدخول (من رسالة الخطأ المترجمة)
  /// يتحقق من الرسائل العربية والإنجليزية
  static bool requiresReLoginFromMessage(String message) {
    final lowerMessage = message.toLowerCase();

    // Check Arabic messages
    if (message.contains('انتهت صلاحية الجلسة') ||
        message.contains('انتهت الجلسة') ||
        message.contains('تسجيل الخروج وإعادة تسجيل الدخول') ||
        message.contains('تسجيل الدخول مرة أخرى')) {
      return true;
    }

    // Check English messages
    return lowerMessage.contains('missing odoo credentials') ||
        lowerMessage.contains('tenant jwt token') ||
        lowerMessage.contains('session expired') ||
        lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('please login') ||
        lowerMessage.contains('401');
  }
}
