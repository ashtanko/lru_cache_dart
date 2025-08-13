import 'package:lru_cache/src/lru_cache.dart';
import 'package:test/test.dart';

void main() {
  group('LruCache Benchmark Tests', () {
    test('should handle high-frequency operations efficiently', () async {
      final cache = LruCache<int, String>(100);
      final stopwatch = Stopwatch()..start();

      // Perform 10,000 operations
      for (int i = 0; i < 10000; i++) {
        await cache.put(i, 'value$i');
        await cache.get(i);
      }

      stopwatch.stop();

      print('High-frequency operations benchmark:');
      print(
          '  Operations: ${cache.putCount() + cache.hitCount() + cache.missCount()}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '  Operations per second: ${(20000 / stopwatch.elapsedMilliseconds * 1000).round()}');
      print('  Hit rate: ${cache.hitRate().toStringAsFixed(1)}%');

      expect(stopwatch.elapsedMilliseconds,
          lessThan(5000)); // Should complete within 5 seconds
      expect(cache.hitCount(), 10000);
      expect(cache.putCount(), 10000);
    });

    test('should handle frequent evictions efficiently', () async {
      final cache = LruCache<int, String>(10);
      final stopwatch = Stopwatch()..start();

      // Add 1000 items to a cache of size 10 (will cause many evictions)
      for (int i = 0; i < 1000; i++) {
        await cache.put(i, 'value$i');
      }

      stopwatch.stop();

      print('Frequent evictions benchmark:');
      print('  Operations: ${cache.putCount()}');
      print('  Evictions: ${cache.evictionCount()}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '  Operations per second: ${(1000 / stopwatch.elapsedMilliseconds * 1000).round()}');

      expect(stopwatch.elapsedMilliseconds,
          lessThan(1000)); // Should complete within 1 second
      expect(await cache.size(), 10);
      expect(cache.evictionCount(), 990);
    });

    test('should handle concurrent access efficiently', () async {
      final cache = LruCache<int, String>(50);
      final stopwatch = Stopwatch()..start();

      // Pre-populate cache
      for (int i = 0; i < 50; i++) {
        await cache.put(i, 'value$i');
      }

      // Perform concurrent operations
      final futures = <Future<void>>[];
      for (int i = 0; i < 1000; i++) {
        futures.add(cache.get(i % 50));
        futures.add(cache.put(i % 100, 'new_value$i'));
      }

      await Future.wait(futures);
      stopwatch.stop();

      print('Concurrent access benchmark:');
      print('  Concurrent operations: ${futures.length}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '  Operations per second: ${(futures.length / stopwatch.elapsedMilliseconds * 1000).round()}');
      print('  Hit rate: ${cache.hitRate().toStringAsFixed(1)}%');

      expect(stopwatch.elapsedMilliseconds,
          lessThan(3000)); // Should complete within 3 seconds
      expect(await cache.size(), lessThanOrEqualTo(50));
    });

    test('should handle large cache sizes efficiently', () async {
      final cache = LruCache<int, String>(10000);
      final stopwatch = Stopwatch()..start();

      // Fill a large cache
      for (int i = 0; i < 10000; i++) {
        await cache.put(i, 'value$i');
      }

      stopwatch.stop();

      print('Large cache benchmark:');
      print('  Cache size: 10,000 entries');
      print('  Operations: ${cache.putCount()}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '  Operations per second: ${(10000 / stopwatch.elapsedMilliseconds * 1000).round()}');

      expect(stopwatch.elapsedMilliseconds,
          lessThan(2000)); // Should complete within 2 seconds
      expect(await cache.size(), 10000);
    });

    test('should handle mixed operations efficiently', () async {
      final cache = LruCache<int, String>(100);
      final stopwatch = Stopwatch()..start();

      // Mix of different operations
      for (int i = 0; i < 5000; i++) {
        switch (i % 4) {
          case 0:
            await cache.put(i, 'value$i');
            break;
          case 1:
            await cache.get(i);
            break;
          case 2:
            await cache.containsKey(i);
            break;
          case 3:
            await cache.remove(i);
            break;
        }
      }

      stopwatch.stop();

      print('Mixed operations benchmark:');
      print('  Operations: 5,000');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '  Operations per second: ${(5000 / stopwatch.elapsedMilliseconds * 1000).round()}');
      print('  Final cache size: ${await cache.size()}');

      expect(stopwatch.elapsedMilliseconds,
          lessThan(3000)); // Should complete within 3 seconds
    });

    test('should handle string operations efficiently', () async {
      final cache = LruCache<String, String>(100);
      final stopwatch = Stopwatch()..start();

      // Use string keys and values
      for (int i = 0; i < 1000; i++) {
        final key = 'key_${i.toString().padLeft(4, '0')}';
        final value =
            'value_${i.toString().padLeft(4, '0')}_with_some_additional_text';
        await cache.put(key, value);
        await cache.get(key);
      }

      stopwatch.stop();

      print('String operations benchmark:');
      print('  Operations: 2,000');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '  Operations per second: ${(2000 / stopwatch.elapsedMilliseconds * 1000).round()}');
      print('  Hit rate: ${cache.hitRate().toStringAsFixed(1)}%');

      expect(stopwatch.elapsedMilliseconds,
          lessThan(2000)); // Should complete within 2 seconds
      expect(cache.hitCount(), 1000);
    });
  });
}
