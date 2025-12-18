import 'package:intl/intl.dart';
import 'number_converter.dart';

/// Date format types
enum DateFormatType {
  short, // dd/MM/yyyy
  medium, // dd MMM yyyy
  long, // dd MMMM yyyy
  full, // EEEE, dd MMMM yyyy
}

/// Data formatters with Arabic numeral support
class Formatters {
  Formatters._();

  /// Should use Arabic numerals (set by app preference)
  static bool _useArabicNumerals = false;

  /// Current date format type
  static DateFormatType _dateFormatType = DateFormatType.medium;

  /// Current locale for date formatting (to keep month names in correct language)
  static String _locale = 'en';

  /// Set numeral preference
  static void setNumeralPreference(bool useArabicNumerals) {
    _useArabicNumerals = useArabicNumerals;
  }

  /// Set date format preference
  static void setDateFormatPreference(DateFormatType format) {
    _dateFormatType = format;
  }

  /// Set locale for date formatting
  static void setLocale(String locale) {
    _locale = locale;
  }

  /// Get current date format pattern based on preference
  static String get _datePattern {
    switch (_dateFormatType) {
      case DateFormatType.short:
        return 'dd/MM/yyyy';
      case DateFormatType.medium:
        return 'dd MMM yyyy';
      case DateFormatType.long:
        return 'dd MMMM yyyy';
      case DateFormatType.full:
        return 'EEEE, dd MMMM yyyy';
    }
  }

  /// Convert formatted string to use appropriate numerals
  /// Arabic numerals only apply when the locale is Arabic AND user prefers Arabic numerals
  static String _applyNumeralFormat(String text) {
    if (_locale == 'ar') {
      // For Arabic locale, check user preference
      if (_useArabicNumerals) {
        // User wants Arabic numerals - convert any Western to Arabic
        return NumberConverter.toArabicNumerals(text);
      } else {
        // User wants Western numerals - convert any Arabic to Western
        // This is needed because DateFormat with 'ar' locale returns Arabic numerals by default
        return NumberConverter.toWesternNumerals(text);
      }
    }
    return text;
  }

  // === Date Formatters ===

  /// Format date to string
  static String date(DateTime? date, {String? pattern}) {
    if (date == null) return '';
    final effectivePattern = pattern ?? _datePattern;
    final formatted = DateFormat(effectivePattern, _locale).format(date);
    return _applyNumeralFormat(formatted);
  }

  /// Format date for display (uses user preference)
  static String displayDate(DateTime? date) {
    if (date == null) return '';
    final formatted = DateFormat(_datePattern, _locale).format(date);
    return _applyNumeralFormat(formatted);
  }

  /// Format datetime for display (uses user preference for date)
  static String displayDateTime(DateTime? date) {
    if (date == null) return '';
    final datePattern = _datePattern;
    final formatted = DateFormat('$datePattern, hh:mm a', _locale).format(date);
    return _applyNumeralFormat(formatted);
  }

  /// Format time only
  static String time(DateTime? date, {bool use24Hour = false}) {
    if (date == null) return '';
    final formatted =
        DateFormat(use24Hour ? 'HH:mm' : 'hh:mm a', _locale).format(date);
    return _applyNumeralFormat(formatted);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String relativeTime(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    String result;
    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      result = '$years year${years > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      result = '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 0) {
      result = '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      result = '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      result = '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      result = 'Just now';
    }

    return _applyNumeralFormat(result);
  }

  // === Number Formatters ===

  /// Format number with thousand separator
  static String number(num? value, {int decimals = 0}) {
    if (value == null) return '';
    final formatted =
        NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}')
            .format(value);
    return _applyNumeralFormat(formatted);
  }

  /// Format as currency
  static String currency(num? value, {String symbol = r'$', int decimals = 2}) {
    if (value == null) return '';
    final formatted =
        NumberFormat.currency(symbol: symbol, decimalDigits: decimals)
            .format(value);
    return _applyNumeralFormat(formatted);
  }

  /// Format as percentage
  static String percentage(num? value, {int decimals = 0}) {
    if (value == null) return '';
    final formatted = '${value.toStringAsFixed(decimals)}%';
    return _applyNumeralFormat(formatted);
  }

  /// Format as compact number (1K, 1M, etc.)
  static String compact(num? value) {
    if (value == null) return '';
    final formatted = NumberFormat.compact().format(value);
    return _applyNumeralFormat(formatted);
  }

  /// Format file size
  static String fileSize(int? bytes) {
    if (bytes == null || bytes == 0) {
      return _applyNumeralFormat('0 B');
    }

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    final formatted =
        '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${suffixes[i]}';
    return _applyNumeralFormat(formatted);
  }

  // === Text Formatters ===

  /// Format phone number
  static String phone(String? value) {
    if (value == null || value.isEmpty) return '';
    // Remove all non-digit characters
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return _applyNumeralFormat(value);
    }

    String formatted;
    // Format as (XXX) XXX-XXXX
    if (digits.length == 10) {
      formatted =
          '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    // With country code
    else if (digits.length == 11) {
      formatted =
          '+${digits[0]} (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    } else {
      formatted = value;
    }

    return _applyNumeralFormat(formatted);
  }

  /// Mask email
  static String maskEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) {
      return '$name***@$domain';
    }

    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  /// Mask phone number
  static String maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) {
      return _applyNumeralFormat(phone);
    }

    final formatted =
        '${'*' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
    return _applyNumeralFormat(formatted);
  }

  /// Truncate text with ellipsis
  static String truncate(
    String? text,
    int maxLength, {
    String ellipsis = '...',
  }) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Format name (First Last)
  static String name(String? firstName, String? lastName) {
    final parts = <String>[];
    if (firstName?.isNotEmpty ?? false) parts.add(firstName!);
    if (lastName?.isNotEmpty ?? false) parts.add(lastName!);
    return parts.join(' ');
  }

  /// Get initials from name
  static String initials(String? name, {int count = 2}) {
    if (name == null || name.isEmpty) return '';
    final parts = name.trim().split(' ');
    final initials = parts
        .where((p) => p.isNotEmpty)
        .take(count)
        .map((p) => p[0].toUpperCase())
        .join();
    return initials;
  }

  /// Format a simple integer or string containing numbers
  /// This applies Arabic/Western numeral preference based on settings
  /// Use this for displaying counts, IDs, or any numeric values in the UI
  static String formatSimple(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    return _applyNumeralFormat(text);
  }
}
