/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// Default language code
  static const String defaultLanguage = 'en';

  /// Supported languages
  static const List<String> supportedLanguages = ['en', 'ar'];

  /// Default country code
  static const String defaultCountry = 'US';

  /// Date format patterns
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayTimeFormat = 'hh:mm a';
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';

  /// Currency format
  static const String currencySymbol = r'$';
  static const int currencyDecimalPlaces = 2;

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Search debounce duration
  static const Duration searchDebounce = Duration(milliseconds: 500);

  /// Toast duration
  static const Duration toastDuration = Duration(seconds: 3);

  /// Minimum password length
  static const int minPasswordLength = 8;

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
