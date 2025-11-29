import 'package:intl/intl.dart';

/// Data formatters
class Formatters {
  Formatters._();

  // === Date Formatters ===

  /// Format date to string
  static String date(DateTime? date, {String pattern = 'yyyy-MM-dd'}) {
    if (date == null) return '';
    return DateFormat(pattern).format(date);
  }

  /// Format date for display
  static String displayDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format datetime for display
  static String displayDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// Format time only
  static String time(DateTime? date, {bool use24Hour = false}) {
    if (date == null) return '';
    return DateFormat(use24Hour ? 'HH:mm' : 'hh:mm a').format(date);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String relativeTime(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // === Number Formatters ===

  /// Format number with thousand separator
  static String number(num? value, {int decimals = 0}) {
    if (value == null) return '';
    return NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}')
        .format(value);
  }

  /// Format as currency
  static String currency(num? value, {String symbol = r'$', int decimals = 2}) {
    if (value == null) return '';
    return NumberFormat.currency(symbol: symbol, decimalDigits: decimals)
        .format(value);
  }

  /// Format as percentage
  static String percentage(num? value, {int decimals = 0}) {
    if (value == null) return '';
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format as compact number (1K, 1M, etc.)
  static String compact(num? value) {
    if (value == null) return '';
    return NumberFormat.compact().format(value);
  }

  /// Format file size
  static String fileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${suffixes[i]}';
  }

  // === Text Formatters ===

  /// Format phone number
  static String phone(String? value) {
    if (value == null || value.isEmpty) return '';
    // Remove all non-digit characters
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return value;

    // Format as (XXX) XXX-XXXX
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    // With country code
    if (digits.length == 11) {
      return '+${digits[0]} (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }

    return value;
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
    if (digits.length < 4) return phone;

    return '${'*' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
  }

  /// Truncate text with ellipsis
  static String truncate(String? text, int maxLength,
      {String ellipsis = '...'}) {
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
}
