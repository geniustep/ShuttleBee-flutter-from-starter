import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../constants/storage_keys.dart';

/// Hive local storage service
class HiveService {
  static final Logger _logger = Logger();
  static bool _initialized = false;

  /// Initialize Hive service
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      _initialized = true;
      _logger.d('Hive service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Hive', error: e);
      rethrow;
    }
  }

  /// Open a box
  Future<Box<T>> openBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox<T>(name);
    }
    return Hive.box<T>(name);
  }

  /// Get a value from box
  Future<T?> getValue<T>(String boxName, String key) async {
    final box = await openBox<T>(boxName);
    return box.get(key);
  }

  /// Put a value in box
  Future<void> putValue<T>(String boxName, String key, T value) async {
    final box = await openBox<T>(boxName);
    await box.put(key, value);
  }

  /// Delete a value from box
  Future<void> deleteValue(String boxName, String key) async {
    final box = await openBox(boxName);
    await box.delete(key);
  }

  /// Get all values from box
  Future<List<T>> getAllValues<T>(String boxName) async {
    final box = await openBox<T>(boxName);
    return box.values.toList();
  }

  /// Clear a box
  Future<void> clearBox(String boxName) async {
    final box = await openBox(boxName);
    await box.clear();
  }

  /// Close a box
  Future<void> closeBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
  }

  /// Close all boxes
  Future<void> closeAllBoxes() async {
    await Hive.close();
  }

  /// Delete a box from disk
  Future<void> deleteBox(String boxName) async {
    await closeBox(boxName);
    await Hive.deleteBoxFromDisk(boxName);
  }

  /// Clear all app data
  Future<void> clearAllData() async {
    await clearBox(StorageKeys.userBox);
    await clearBox(StorageKeys.settingsBox);
    await clearBox(StorageKeys.cacheBox);
    await clearBox(StorageKeys.syncQueueBox);
    _logger.d('All Hive data cleared');
  }
}
