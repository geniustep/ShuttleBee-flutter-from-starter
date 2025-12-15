import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper above [SharedPreferences] with typed helpers
/// to match the legacy PrefsStorageService API that the UI expects.
class PrefsStorageService {
  PrefsStorageService._();

  static final PrefsStorageService instance = PrefsStorageService._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// Read a value of type [T] from storage.
  Future<T?> read<T>({required String key}) async {
    final prefs = await _prefs;
    final value = prefs.get(key);
    return value as T?;
  }

  /// Write a value to storage (supports common JSON-serialisable primitives).
  Future<bool> write({required String key, required dynamic value}) async {
    final prefs = await _prefs;

    if (value is bool) return prefs.setBool(key, value);
    if (value is int) return prefs.setInt(key, value);
    if (value is double) return prefs.setDouble(key, value);
    if (value is String) return prefs.setString(key, value);
    if (value is List<String>) return prefs.setStringList(key, value);
    if (value == null) return prefs.remove(key);

    throw UnsupportedError(
      'Unsupported value type (${value.runtimeType}) for PrefsStorageService',
    );
  }

  /// Delete a single key.
  Future<bool> delete({required String key}) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }
}
