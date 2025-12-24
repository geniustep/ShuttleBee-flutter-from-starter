import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter_starter/core/local_storage/data/mobile_local_storage_impl.dart';
import 'package:bridgecore_flutter_starter/core/local_storage/domain/local_storage_repository.dart';

void main() {
  late LocalStorageRepository storage;

  setUpAll(() async {
    storage = MobileLocalStorageImpl();
    await storage.initialize();
  });

  tearDownAll(() async {
    await storage.close();
  });

  group('Mobile Local Storage -', () {
    test('initialize should succeed', () async {
      final result = await storage.initialize();
      expect(result.isRight(), true);
    });

    test('save and load data', () async {
      final testData = {'name': 'Test', 'value': 123};

      // Save
      final saveResult = await storage.save(
        key: 'test_key',
        data: testData,
        ttl: Duration(hours: 1),
      );
      expect(saveResult.isRight(), true);

      // Load
      final loadResult = await storage.load('test_key');
      loadResult.fold(
        (failure) => fail('Load failed: ${failure.message}'),
        (data) {
          expect(data, isNotNull);
          expect(data!['name'], 'Test');
          expect(data['value'], 123);
        },
      );
    });

    test('expired data should be deleted', () async {
      // Save with very short TTL
      await storage.save(
        key: 'expire_test',
        data: {'test': 'data'},
        ttl: Duration(milliseconds: 100),
      );

      // Wait for expiration
      await Future.delayed(Duration(milliseconds: 200));

      // Try to load
      final result = await storage.load('expire_test');
      result.fold(
        (failure) => fail('Unexpected failure'),
        (data) => expect(data, isNull), // Should be null (expired)
      );
    });

    test('save and load collection', () async {
      final items = [
        {'id': 1, 'name': 'Item 1'},
        {'id': 2, 'name': 'Item 2'},
        {'id': 3, 'name': 'Item 3'},
      ];

      // Save collection
      final saveResult = await storage.saveCollection(
        collectionName: 'test_collection',
        items: items,
        ttl: Duration(hours: 1),
      );
      expect(saveResult.isRight(), true);

      // Load collection
      final loadResult = await storage.loadCollection('test_collection');
      loadResult.fold(
        (failure) => fail('Load failed: ${failure.message}'),
        (loadedItems) {
          expect(loadedItems.length, 3);
          expect(loadedItems[0]['name'], 'Item 1');
        },
      );
    });

    test('query collection with filters', () async {
      final items = [
        {'id': 1, 'status': 'active', 'name': 'A'},
        {'id': 2, 'status': 'inactive', 'name': 'B'},
        {'id': 3, 'status': 'active', 'name': 'C'},
      ];

      await storage.saveCollection(
        collectionName: 'query_test',
        items: items,
      );

      // Query active items
      final result = await storage.queryCollection(
        collectionName: 'query_test',
        filters: {'status': 'active'},
      );

      result.fold(
        (failure) => fail('Query failed'),
        (filtered) {
          expect(filtered.length, 2);
          expect(filtered.every((item) => item['status'] == 'active'), true);
        },
      );
    });

    test('get stats', () async {
      final stats = await storage.getStats();
      stats.fold(
        (failure) => fail('Stats failed'),
        (data) {
          expect(data['platform'], 'mobile');
          expect(data['storage_type'], 'hive');
          expect(data.containsKey('cache_entries'), true);
        },
      );
    });

    test('health check', () async {
      final health = await storage.healthCheck();
      health.fold(
        (failure) => fail('Health check failed'),
        (isHealthy) => expect(isHealthy, true),
      );
    });

    test('clear expired entries', () async {
      // Save some expired data
      await storage.save(
        key: 'expired1',
        data: {'test': '1'},
        ttl: Duration(milliseconds: 50),
      );

      await Future.delayed(Duration(milliseconds: 100));

      final result = await storage.clearExpired();
      result.fold(
        (failure) => fail('Clear failed'),
        (count) => expect(count, greaterThan(0)),
      );
    });

    test('delete specific key', () async {
      await storage.save(key: 'delete_test', data: {'test': 'data'});

      final deleteResult = await storage.delete('delete_test');
      expect(deleteResult.isRight(), true);

      final loadResult = await storage.load('delete_test');
      loadResult.fold(
        (_) {},
        (data) => expect(data, isNull),
      );
    });
  });
}
