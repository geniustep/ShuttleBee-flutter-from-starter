import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences service for simple key-value storage
class PrefsService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // لا تظهر stack frames للرسائل العادية
      errorMethodCount: 5, // عدد محدود من stack frames للأخطاء
      lineLength: 80,
      colors: true,
      printEmojis: false,
      excludeBox: {
        Level.debug: true,
        Level.info: true,
      },
    ),
  );
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _logger.d('SharedPreferences initialized');
  }

  /// Get SharedPreferences instance
  static SharedPreferences get instance {
    if (_prefs == null) {
      throw StateError('PrefsService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // === String ===
  String? getString(String key) => _prefs?.getString(key);

  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  // === Int ===
  int? getInt(String key) => _prefs?.getInt(key);

  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  // === Double ===
  double? getDouble(String key) => _prefs?.getDouble(key);

  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  // === Bool ===
  bool? getBool(String key) => _prefs?.getBool(key);

  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  // === String List ===
  List<String>? getStringList(String key) => _prefs?.getStringList(key);

  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  // === Remove ===
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  // === Clear ===
  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // === Contains ===
  bool containsKey(String key) => _prefs?.containsKey(key) ?? false;

  // === Get All Keys ===
  Set<String> getKeys() => _prefs?.getKeys() ?? {};
}
