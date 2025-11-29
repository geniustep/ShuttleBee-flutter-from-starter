import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

/// General helper functions
class Helpers {
  Helpers._();

  static const _uuid = Uuid();

  /// Generate UUID
  static String generateUuid() => _uuid.v4();

  /// Generate short ID
  static String generateShortId({int length = 8}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Delay execution
  static Future<void> delay(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Get text from clipboard
  static Future<String?> getFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// Hide keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Check if string is valid JSON
  static bool isValidJson(String? str) {
    if (str == null || str.isEmpty) return false;
    try {
      return str.startsWith('{') || str.startsWith('[');
    } catch (_) {
      return false;
    }
  }

  /// Parse boolean from dynamic value
  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  /// Parse int from dynamic value
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parse double from dynamic value
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse DateTime from dynamic value
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Debounce function calls
  static Function(T) debounce<T>(
    void Function(T) fn,
    Duration delay,
  ) {
    Timer? timer;
    return (T arg) {
      timer?.cancel();
      timer = Timer(delay, () => fn(arg));
    };
  }

  /// Throttle function calls
  static Function() throttle(
    VoidCallback fn,
    Duration delay,
  ) {
    DateTime? lastCall;
    return () {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) >= delay) {
        lastCall = now;
        fn();
      }
    };
  }

  /// Get color from hex string
  static Color colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert color to hex string
  static String colorToHex(Color color, {bool includeAlpha = false}) {
    if (includeAlpha) {
      return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
    }
    return '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
  }

  /// Check if running on mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  /// Check if running on tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1200;
  }

  /// Check if running on desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1200;
  }

  /// Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

/// Timer for debounce
class Timer {
  final Duration duration;
  final VoidCallback callback;
  bool _isActive = false;

  Timer(this.duration, this.callback);

  void cancel() {
    _isActive = false;
  }

  static Timer periodic(Duration duration, void Function(Timer) callback) {
    final timer = Timer(duration, () {});
    timer._isActive = true;
    Future.doWhile(() async {
      await Future.delayed(duration);
      if (timer._isActive) {
        callback(timer);
        return true;
      }
      return false;
    });
    return timer;
  }
}
