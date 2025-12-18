/// Number conversion utilities for Arabic numerals
class NumberConverter {
  NumberConverter._();

  /// Map of Western to Arabic numerals
  static const Map<String, String> _westernToArabic = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  /// Map of Arabic to Western numerals
  static const Map<String, String> _arabicToWestern = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  /// Convert Western numerals (0-9) to Arabic numerals (٠-٩)
  static String toArabicNumerals(String text) {
    if (text.isEmpty) return text;

    String result = text;
    _westernToArabic.forEach((western, arabic) {
      result = result.replaceAll(western, arabic);
    });
    return result;
  }

  /// Convert Arabic numerals (٠-٩) to Western numerals (0-9)
  static String toWesternNumerals(String text) {
    if (text.isEmpty) return text;

    String result = text;
    _arabicToWestern.forEach((arabic, western) {
      result = result.replaceAll(arabic, western);
    });
    return result;
  }

  /// Convert number to string with appropriate numerals based on preference
  static String formatNumber(
    num value, {
    bool useArabicNumerals = false,
    int decimals = 0,
  }) {
    String result;
    if (decimals == 0) {
      result = value.toInt().toString();
    } else {
      result = value.toStringAsFixed(decimals);
    }

    return useArabicNumerals ? toArabicNumerals(result) : result;
  }

  /// Check if a string contains Arabic numerals
  static bool containsArabicNumerals(String text) {
    return _arabicToWestern.keys.any((arabic) => text.contains(arabic));
  }

  /// Check if a string contains Western numerals
  static bool containsWesternNumerals(String text) {
    return _westernToArabic.keys.any((western) => text.contains(western));
  }

  /// Convert numerals in a string based on preference
  /// If useArabicNumerals is true, converts to Arabic (٠-٩)
  /// If false, converts to Western (0-9)
  static String convertNumerals(String text,
      {required bool useArabicNumerals}) {
    return useArabicNumerals ? toArabicNumerals(text) : toWesternNumerals(text);
  }
}
