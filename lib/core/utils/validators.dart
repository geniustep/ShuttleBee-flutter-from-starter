/// Form validators
class Validators {
  Validators._();

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }
    return null;
  }

  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validate password with complexity
  static String? passwordComplex(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validate confirm password
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate phone number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    if (!RegExp(r'^\+?[\d\s\-\(\)]{8,}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Validate min length
  static String? minLength(String? value, int length, {String? fieldName}) {
    if (value == null || value.length < length) {
      final field = fieldName ?? 'This field';
      return '$field must be at least $length characters';
    }
    return null;
  }

  /// Validate max length
  static String? maxLength(String? value, int length, {String? fieldName}) {
    if (value != null && value.length > length) {
      final field = fieldName ?? 'This field';
      return '$field must be at most $length characters';
    }
    return null;
  }

  /// Validate number
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (double.tryParse(value) == null) {
      final field = fieldName ?? 'This field';
      return '$field must be a valid number';
    }
    return null;
  }

  /// Validate integer
  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (int.tryParse(value) == null) {
      final field = fieldName ?? 'This field';
      return '$field must be a whole number';
    }
    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      final field = fieldName ?? 'This field';
      return '$field must be a positive number';
    }
    return null;
  }

  /// Validate range
  static String? range(String? value, num min, num max, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final number = double.tryParse(value);
    if (number == null || number < min || number > max) {
      final field = fieldName ?? 'Value';
      return '$field must be between $min and $max';
    }
    return null;
  }

  /// Validate latitude (GPS coordinate)
  /// Latitude must be between -90 and 90
  static String? latitude(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Latitude is optional
    }
    final lat = double.tryParse(value);
    if (lat == null) {
      final field = fieldName ?? 'Latitude';
      return '$field must be a valid number';
    }
    if (lat < -90 || lat > 90) {
      final field = fieldName ?? 'Latitude';
      return '$field must be between -90 and 90';
    }
    return null;
  }

  /// Validate longitude (GPS coordinate)
  /// Longitude must be between -180 and 180
  static String? longitude(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Longitude is optional
    }
    final lng = double.tryParse(value);
    if (lng == null) {
      final field = fieldName ?? 'Longitude';
      return '$field must be a valid number';
    }
    if (lng < -180 || lng > 180) {
      final field = fieldName ?? 'Longitude';
      return '$field must be between -180 and 180';
    }
    return null;
  }

  /// Validate GPS coordinates (latitude and longitude together)
  static String? gpsCoordinates(
    String? latitudeValue,
    String? longitudeValue, {
    String? fieldName,
  }) {
    // If both are empty, that's fine (optional)
    if ((latitudeValue == null || latitudeValue.isEmpty) &&
        (longitudeValue == null || longitudeValue.isEmpty)) {
      return null;
    }

    // If one is provided, both should be provided
    final hasLat = latitudeValue != null && latitudeValue.isNotEmpty;
    final hasLng = longitudeValue != null && longitudeValue.isNotEmpty;

    if (hasLat && !hasLng) {
      return 'Longitude is required when latitude is provided';
    }
    if (hasLng && !hasLat) {
      return 'Latitude is required when longitude is provided';
    }

    // Validate both
    final latError = latitude(latitudeValue, fieldName: 'Latitude');
    if (latError != null) return latError;

    final lngError = longitude(longitudeValue, fieldName: 'Longitude');
    if (lngError != null) return lngError;

    return null;
  }

  /// Combine multiple validators
  static String? combine(
      String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
