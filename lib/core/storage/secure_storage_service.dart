import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Secure storage service for sensitive data
class SecureStorageService {
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
  static FlutterSecureStorage? _storage;

  /// Android options
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  /// iOS options
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  /// Initialize secure storage
  static Future<void> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    _logger.d('SecureStorage initialized');
  }

  /// Get storage instance
  /// Automatically initializes if not already initialized
  static FlutterSecureStorage get instance {
    if (_storage == null) {
      // Auto-initialize if not already done
      _logger.w('⚠️ SecureStorage not initialized, auto-initializing...');
      _storage = const FlutterSecureStorage(
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      _logger.d('✅ SecureStorage auto-initialized successfully');
    }
    return _storage!;
  }

  /// Read a value
  Future<String?> read(String key) async {
    try {
      return await instance.read(key: key);
    } catch (e) {
      _logger.e('Error reading from secure storage', error: e);
      return null;
    }
  }

  /// Write a value
  Future<void> write(String key, String value) async {
    try {
      await instance.write(key: key, value: value);
    } catch (e) {
      _logger.e('Error writing to secure storage', error: e);
      rethrow;
    }
  }

  /// Delete a value
  Future<void> delete(String key) async {
    try {
      await instance.delete(key: key);
    } catch (e) {
      _logger.e('Error deleting from secure storage', error: e);
      rethrow;
    }
  }

  /// Delete all values
  Future<void> deleteAll() async {
    try {
      await instance.deleteAll();
      _logger.d('All secure storage data deleted');
    } catch (e) {
      _logger.e('Error deleting all secure storage data', error: e);
      rethrow;
    }
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      return await instance.containsKey(key: key);
    } catch (e) {
      _logger.e('Error checking key in secure storage', error: e);
      return false;
    }
  }

  /// Read all values
  Future<Map<String, String>> readAll() async {
    try {
      return await instance.readAll();
    } catch (e) {
      _logger.e('Error reading all from secure storage', error: e);
      return {};
    }
  }
}
