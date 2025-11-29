import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bridgecore_flutter_starter/core/cache/cache_manager.dart';

void main() {
  late CacheManager cacheManager;
  late Directory tempDir;

  setUpAll(() async {
    // Initialize Hive with a temporary directory for tests
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    // Clean up: close all boxes and delete temp directory
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    cacheManager = CacheManager();
  });

  group('CacheManager', () {
    test('should return data from memory cache when available', () async {
      // Arrange
      const key = 'test_key';
      const testData = {'data': 'test'};
      await cacheManager.set(key, testData);

      // Act
      final result = await cacheManager.get<Map<String, dynamic>>(key);

      // Assert
      expect(result, equals(testData));
    });

    test('should invalidate cache when requested', () async {
      // Arrange
      const key = 'test_key';
      const testData = {'data': 'test'};
      await cacheManager.set(key, testData);

      // Act
      await cacheManager.invalidate(key);
      final result = await cacheManager.get(key);

      // Assert
      expect(result, isNull);
    });

    test('should clear all caches', () async {
      // Arrange
      await cacheManager.set('key1', 'value1');
      await cacheManager.set('key2', 'value2');

      // Act
      await cacheManager.clearAll();
      final result1 = await cacheManager.get('key1');
      final result2 = await cacheManager.get('key2');

      // Assert
      expect(result1, isNull);
      expect(result2, isNull);
    });
  });
}
