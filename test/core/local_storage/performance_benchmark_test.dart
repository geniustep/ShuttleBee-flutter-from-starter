import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter_starter/core/local_storage/data/mobile_local_storage_impl.dart';
import 'package:bridgecore_flutter_starter/core/local_storage/data/windows_local_storage_impl.dart';
import 'package:bridgecore_flutter_starter/core/local_storage/domain/local_storage_repository.dart';

void main() {
  group('Performance Benchmarks -', () {
    late LocalStorageRepository mobileStorage;
    late LocalStorageRepository windowsStorage;

    setUpAll(() async {
      mobileStorage = MobileLocalStorageImpl();
      windowsStorage = WindowsLocalStorageImpl();

      await mobileStorage.initialize();
      await windowsStorage.initialize();
    });

    tearDownAll(() async {
      await mobileStorage.close();
      await windowsStorage.close();
    });

    test('Mobile: Save 100 items benchmark', () async {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        await mobileStorage.save(
          key: 'mobile_item_$i',
          data: {'id': i, 'name': 'Item $i', 'value': i * 10},
          ttl: const Duration(hours: 1),
        );
      }

      stopwatch.stop();
      print('Mobile: Saved 100 items in ${stopwatch.elapsedMilliseconds}ms');

      // Should be fast (< 100ms on modern devices)
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('Windows: Save 100 items benchmark', () async {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        await windowsStorage.save(
          key: 'windows_item_$i',
          data: {'id': i, 'name': 'Item $i', 'value': i * 10},
          ttl: const Duration(hours: 1),
        );
      }

      stopwatch.stop();
      print('Windows: Saved 100 items in ${stopwatch.elapsedMilliseconds}ms');

      // Windows should be faster (< 60ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(150));
    });

    test('Mobile: Load 100 items benchmark', () async {
      // First save items
      for (var i = 0; i < 100; i++) {
        await mobileStorage.save(
          key: 'load_test_$i',
          data: {'id': i, 'data': 'test'},
          ttl: const Duration(hours: 1),
        );
      }

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        await mobileStorage.load('load_test_$i');
      }

      stopwatch.stop();
      print('Mobile: Loaded 100 items in ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(150));
    });

    test('Mobile: Save collection of 500 items', () async {
      final items = List.generate(
        500,
        (i) => {'id': i, 'name': 'Item $i', 'status': 'active'},
      );

      final stopwatch = Stopwatch()..start();

      await mobileStorage.saveCollection(
        collectionName: 'large_collection',
        items: items,
        ttl: const Duration(hours: 2),
      );

      stopwatch.stop();
      print('Mobile: Saved 500 items collection in ${stopwatch.elapsedMilliseconds}ms');

      // Should handle max collection size efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });

    test('Windows: Save collection of 2000 items', () async {
      final items = List.generate(
        2000,
        (i) => {'id': i, 'name': 'Item $i', 'status': 'active'},
      );

      final stopwatch = Stopwatch()..start();

      await windowsStorage.saveCollection(
        collectionName: 'large_collection_windows',
        items: items,
        ttl: const Duration(hours: 2),
      );

      stopwatch.stop();
      print('Windows: Saved 2000 items collection in ${stopwatch.elapsedMilliseconds}ms');

      // Windows should handle larger collections
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('Mobile: Query 1000 items with filters', () async {
      final items = List.generate(
        1000,
        (i) => {
          'id': i,
          'status': i % 2 == 0 ? 'active' : 'inactive',
          'category': i % 3 == 0 ? 'A' : 'B',
        },
      );

      await mobileStorage.saveCollection(
        collectionName: 'query_benchmark',
        items: items,
      );

      final stopwatch = Stopwatch()..start();

      await mobileStorage.queryCollection(
        collectionName: 'query_benchmark',
        filters: {'status': 'active'},
        sortBy: 'id',
        limit: 100,
      );

      stopwatch.stop();
      print('Mobile: Queried 1000 items in ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('Clear 100 expired entries', () async {
      // Save 100 entries with short TTL
      for (var i = 0; i < 100; i++) {
        await mobileStorage.save(
          key: 'expire_bench_$i',
          data: {'id': i},
          ttl: const Duration(milliseconds: 50),
        );
      }

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      final stopwatch = Stopwatch()..start();
      await mobileStorage.clearExpired();
      stopwatch.stop();

      print('Cleared 100 expired entries in ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Batch operations performance', () async {
      final items = <String, Map<String, dynamic>>{};
      for (var i = 0; i < 100; i++) {
        items['batch_$i'] = {'id': i, 'data': 'test'};
      }

      final stopwatch = Stopwatch()..start();

      await mobileStorage.saveBatch(
        items: items,
        ttl: const Duration(hours: 1),
      );

      stopwatch.stop();
      print('Batch saved 100 items in ${stopwatch.elapsedMilliseconds}ms');

      // Batch should be faster than individual saves
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('Platform comparison: Mobile vs Windows save speed', () async {
      const itemCount = 50;

      // Mobile
      final mobileStopwatch = Stopwatch()..start();
      for (var i = 0; i < itemCount; i++) {
        await mobileStorage.save(
          key: 'compare_m_$i',
          data: {'test': 'data'},
        );
      }
      mobileStopwatch.stop();

      // Windows
      final windowsStopwatch = Stopwatch()..start();
      for (var i = 0; i < itemCount; i++) {
        await windowsStorage.save(
          key: 'compare_w_$i',
          data: {'test': 'data'},
        );
      }
      windowsStopwatch.stop();

      print('Platform Comparison ($itemCount items):');
      print('  Mobile:  ${mobileStopwatch.elapsedMilliseconds}ms');
      print('  Windows: ${windowsStopwatch.elapsedMilliseconds}ms');
      print('  Difference: ${(mobileStopwatch.elapsedMilliseconds - windowsStopwatch.elapsedMilliseconds).abs()}ms');

      // Both should be reasonably fast
      expect(mobileStopwatch.elapsedMilliseconds, lessThan(200));
      expect(windowsStopwatch.elapsedMilliseconds, lessThan(150));
    });

    test('Memory usage estimate', () async {
      // Save 100 items and check stats
      for (var i = 0; i < 100; i++) {
        await mobileStorage.save(
          key: 'memory_test_$i',
          data: {
            'id': i,
            'name': 'Item $i',
            'description': 'Test data ' * 10, // ~100 bytes
          },
        );
      }

      final stats = await mobileStorage.getStats();
      stats.fold(
        (failure) => fail('Stats failed'),
        (data) {
          print('Cache Stats:');
          print('  Entries: ${data['cache_entries']}');
          print('  Size: ${data['total_size_mb']} MB');
          print('  Max: ${data['max_cache_mb']} MB');

          expect(data['cache_entries'], greaterThan(0));
        },
      );
    });
  });
}
