import 'package:lru_cache/src/lru_cache.dart';
import 'package:test/test.dart';

/// A test implementation that tracks removed entries
class TestLruCache<K, V> extends LruCache<K, V> {
  final List<String> removedEntries = [];
  final List<String> createdEntries = [];

  TestLruCache(int maxSize) : super(maxSize);

  @override
  void entryRemoved(bool evicted, K key, V oldValue, V? newValue) {
    removedEntries.add('${evicted ? 'evicted' : 'removed'}:$key=$oldValue');
  }

  @override
  V? create(K key) {
    final value = 'Created Value for $key' as V?;
    if (value != null) {
      createdEntries.add('$key=$value');
    }
    return value;
  }
}

/// A test implementation with custom size calculation
class CustomSizeLruCache<K, V> extends LruCache<K, V> {
  CustomSizeLruCache(int maxSize) : super(maxSize);

  @override
  int sizeOf(K key, V value) {
    if (value is String) {
      return value.length;
    }
    return 1;
  }
}

void main() {
  group('LruCache Comprehensive Tests', () {
    group('Basic Operations', () {
      test('should handle null key assertion', () {
        final cache = LruCache<String, String>(1);
        expect(() => cache.get(null as String), throwsAssertionError);
        expect(() => cache.put(null as String, 'value'), throwsAssertionError);
        expect(() => cache.remove(null as String), throwsAssertionError);
        expect(() => cache.containsKey(null as String), throwsAssertionError);
      });

      test('should handle null value assertion', () {
        final cache = LruCache<String, String>(1);
        expect(() => cache.put('key', null as String), throwsAssertionError);
      });

      test('should handle zero maxSize assertion', () {
        expect(() => LruCache<String, String>(0), throwsAssertionError);
        expect(() => LruCache<String, String>(-1), throwsAssertionError);
      });

      test('should handle single entry cache', () async {
        final cache = LruCache<String, String>(1);
        
        await cache.put('key1', 'value1');
        expect(await cache.get('key1'), 'value1');
        expect(await cache.size(), 1);
        
        await cache.put('key2', 'value2');
        expect(await cache.get('key1'), isNull);
        expect(await cache.get('key2'), 'value2');
        expect(await cache.size(), 1);
      });

      test('should maintain LRU order correctly', () async {
        final cache = LruCache<String, String>(3);
        
        // Add three items
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        await cache.put('key3', 'value3');
        
        // Access key1 to make it most recently used
        await cache.get('key1');
        
        // Add a fourth item - key2 should be evicted (least recently used)
        await cache.put('key4', 'value4');
        
        expect(await cache.get('key1'), 'value1');
        expect(await cache.get('key2'), isNull); // Should be evicted
        expect(await cache.get('key3'), 'value3');
        expect(await cache.get('key4'), 'value4');
      });
    });

    group('Utility Methods', () {
      test('should return correct hit rate', () async {
        final cache = LruCache<String, String>(2);
        
        // No accesses yet
        expect(cache.hitRate(), 0.0);
        
        // One miss
        await cache.get('key1');
        expect(cache.hitRate(), 0.0);
        
        // One hit
        await cache.put('key1', 'value1');
        await cache.get('key1');
        expect(cache.hitRate(), 50.0);
        
        // Two hits, one miss
        await cache.get('key1');
        await cache.get('key2');
        expect(cache.hitRate(), closeTo(66.67, 0.01));
      });

      test('should check if key exists', () async {
        final cache = LruCache<String, String>(2);
        
        expect(await cache.containsKey('key1'), false);
        
        await cache.put('key1', 'value1');
        expect(await cache.containsKey('key1'), true);
        
        await cache.remove('key1');
        expect(await cache.containsKey('key1'), false);
      });

      test('should return keys in LRU order', () async {
        final cache = LruCache<String, String>(3);
        
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        await cache.put('key3', 'value3');
        
        // Access key1 to make it most recently used
        await cache.get('key1');
        
        final keys = await cache.keys();
        expect(keys, ['key2', 'key3', 'key1']); // LRU to MRU order
      });

      test('should return values in LRU order', () async {
        final cache = LruCache<String, String>(3);
        
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        await cache.put('key3', 'value3');
        
        // Access key1 to make it most recently used
        await cache.get('key1');
        
        final values = await cache.values();
        expect(values, ['value2', 'value3', 'value1']); // LRU to MRU order
      });

      test('should check if cache is empty', () async {
        final cache = LruCache<String, String>(2);
        
        expect(await cache.isEmpty(), true);
        expect(await cache.isNotEmpty(), false);
        
        await cache.put('key1', 'value1');
        expect(await cache.isEmpty(), false);
        expect(await cache.isNotEmpty(), true);
        
        await cache.evictAll();
        expect(await cache.isEmpty(), true);
        expect(await cache.isNotEmpty(), false);
      });

      test('should clear statistics', () {
        final cache = LruCache<String, String>(2);
        
        cache.put('key1', 'value1');
        cache.get('key1');
        cache.get('key2');
        
        expect(cache.hitCount(), 1);
        expect(cache.missCount(), 1);
        expect(cache.putCount(), 1);
        
        cache.clearStats();
        
        expect(cache.hitCount(), 0);
        expect(cache.missCount(), 0);
        expect(cache.putCount(), 0);
        expect(cache.createCount(), 0);
        expect(cache.evictionCount(), 0);
      });
    });

    group('Resize Operations', () {
      test('should resize to larger size without eviction', () async {
        final cache = LruCache<String, String>(2);
        
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        expect(await cache.size(), 2);
        
        await cache.resize(5);
        expect(cache.maxSize(), 5);
        expect(await cache.size(), 2);
        expect(await cache.get('key1'), 'value1');
        expect(await cache.get('key2'), 'value2');
      });

      test('should resize to smaller size with eviction', () async {
        final cache = LruCache<String, String>(5);
        
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        await cache.put('key3', 'value3');
        await cache.put('key4', 'value4');
        await cache.put('key5', 'value5');
        expect(await cache.size(), 5);
        
        await cache.resize(2);
        expect(cache.maxSize(), 2);
        expect(await cache.size(), 2);
        
        // Only the most recently used items should remain
        expect(await cache.get('key1'), isNull);
        expect(await cache.get('key2'), isNull);
        expect(await cache.get('key3'), isNull);
        expect(await cache.get('key4'), 'value4');
        expect(await cache.get('key5'), 'value5');
      });

      test('should handle resize to zero', () async {
        final cache = LruCache<String, String>(3);
        
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        expect(await cache.size(), 2);
        
        await cache.resize(0);
        expect(cache.maxSize(), 0);
        expect(await cache.size(), 0);
        expect(await cache.get('key1'), isNull);
        expect(await cache.get('key2'), isNull);
      });
    });

    group('Custom Size Calculation', () {
      test('should use custom size calculation', () async {
        final cache = CustomSizeLruCache<String, String>(10);
        
        await cache.put('key1', 'short');
        await cache.put('key2', 'longer_value');
        await cache.put('key3', 'very_long_value_here');
        
        expect(await cache.size(), 5 + 12 + 20); // Sum of string lengths
        
        // Adding another long value should evict the shortest one
        await cache.put('key4', 'another_long_value');
        expect(await cache.get('key1'), isNull); // 'short' should be evicted
        expect(await cache.get('key2'), 'longer_value');
        expect(await cache.get('key3'), 'very_long_value_here');
        expect(await cache.get('key4'), 'another_long_value');
      });

      test('should handle zero size entries', () async {
        final cache = CustomSizeLruCache<String, String>(5);
        
        await cache.put('key1', ''); // Empty string has size 0
        expect(await cache.size(), 0);
        
        await cache.put('key2', 'test');
        expect(await cache.size(), 4);
        
        // Zero size entries should still be evicted when needed
        await cache.put('key3', 'long_value');
        await cache.put('key4', 'another_long_value');
        
        expect(await cache.get('key1'), isNull); // Should be evicted
        expect(await cache.get('key2'), isNull); // Should be evicted
      });
    });

    group('Entry Removal Callbacks', () {
      test('should call entryRemoved on eviction', () async {
        final cache = TestLruCache<String, String>(2);
        
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        await cache.put('key3', 'value3'); // Should evict key1
        
        expect(cache.removedEntries, contains('evicted:key1=value1'));
      });

      test('should call entryRemoved on replacement', () async {
        final cache = TestLruCache<String, String>(2);
        
        await cache.put('key1', 'value1');
        await cache.put('key1', 'new_value'); // Replace existing value
        
        expect(cache.removedEntries, contains('removed:key1=value1'));
      });

      test('should call entryRemoved on manual removal', () async {
        final cache = TestLruCache<String, String>(2);
        
        await cache.put('key1', 'value1');
        await cache.remove('key1');
        
        expect(cache.removedEntries, contains('removed:key1=value1'));
      });

      test('should call entryRemoved on evictAll', () async {
        final cache = TestLruCache<String, String>(3);
        
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        await cache.evictAll();
        
        expect(cache.removedEntries, contains('evicted:key1=value1'));
        expect(cache.removedEntries, contains('evicted:key2=value2'));
      });
    });

    group('Create Method', () {
      test('should call create method on cache miss', () async {
        final cache = TestLruCache<String, String>(2);
        
        final value = await cache.get('key1');
        expect(value, 'Created Value for key1');
        expect(cache.createdEntries, contains('key1=Created Value for key1'));
        expect(cache.createCount(), 1);
      });

      test('should not call create method on cache hit', () async {
        final cache = TestLruCache<String, String>(2);
        
        await cache.put('key1', 'value1');
        final value = await cache.get('key1');
        expect(value, 'value1');
        expect(cache.createdEntries, isEmpty);
        expect(cache.createCount(), 0);
      });

      test('should handle create method returning null', () async {
        final cache = LruCache<String, String>(2);
        
        final value = await cache.get('key1');
        expect(value, isNull);
        expect(cache.createCount(), 0);
      });
    });

    group('Concurrent Access', () {
      test('should handle concurrent puts', () async {
        final cache = LruCache<int, String>(10);
        final futures = <Future<void>>[];
        
        for (int i = 0; i < 100; i++) {
          futures.add(cache.put(i, 'value$i'));
        }
        
        await Future.wait(futures);
        
        expect(await cache.size(), 10); // Should not exceed max size
        expect(cache.putCount(), 100);
      });

      test('should handle concurrent gets', () async {
        final cache = LruCache<int, String>(5);
        
        // Pre-populate cache
        for (int i = 0; i < 5; i++) {
          await cache.put(i, 'value$i');
        }
        
        final futures = <Future<String?>>[];
        for (int i = 0; i < 100; i++) {
          futures.add(cache.get(i % 5));
        }
        
        final results = await Future.wait(futures);
        
        // Should have some hits and some misses
        expect(cache.hitCount(), greaterThan(0));
        expect(cache.missCount(), greaterThan(0));
        expect(results.length, 100);
      });

      test('should handle mixed concurrent operations', () async {
        final cache = LruCache<int, String>(5);
        final futures = <Future<void>>[];
        
        // Mix of puts, gets, and removes
        for (int i = 0; i < 50; i++) {
          futures.add(cache.put(i, 'value$i'));
          futures.add(cache.get(i));
          if (i % 3 == 0) {
            futures.add(cache.remove(i));
          }
        }
        
        await Future.wait(futures);
        
        // Cache should be in a consistent state
        expect(await cache.size(), lessThanOrEqualTo(5));
        expect(cache.putCount(), 50);
      });
    });

    group('Edge Cases', () {
      test('should handle very large maxSize', () async {
        final cache = LruCache<String, String>(1000000);
        
        for (int i = 0; i < 1000; i++) {
          await cache.put('key$i', 'value$i');
        }
        
        expect(await cache.size(), 1000);
        expect(await cache.get('key0'), 'value0');
        expect(await cache.get('key999'), 'value999');
      });

      test('should handle rapid resize operations', () async {
        final cache = LruCache<String, String>(10);
        
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        
        // Rapid resize operations
        await cache.resize(1);
        await cache.resize(5);
        await cache.resize(2);
        await cache.resize(10);
        
        expect(cache.maxSize(), 10);
        expect(await cache.size(), lessThanOrEqualTo(10));
      });

      test('should handle empty string keys and values', () async {
        final cache = LruCache<String, String>(2);
        
        await cache.put('', 'empty_key');
        await cache.put('key', '');
        
        expect(await cache.get(''), 'empty_key');
        expect(await cache.get('key'), '');
        expect(await cache.containsKey(''), true);
        expect(await cache.containsKey('key'), true);
      });

      test('should handle special characters in keys and values', () async {
        final cache = LruCache<String, String>(2);
        
        await cache.put('key\n', 'value\n');
        await cache.put('key\t', 'value\t');
        await cache.put('key\r', 'value\r');
        
        expect(await cache.get('key\n'), 'value\n');
        expect(await cache.get('key\t'), 'value\t');
        expect(await cache.get('key\r'), isNull); // Should be evicted
      });
    });

    group('Performance Tests', () {
      test('should handle many operations efficiently', () async {
        final cache = LruCache<int, String>(100);
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 10000; i++) {
          await cache.put(i, 'value$i');
          await cache.get(i);
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
        expect(cache.putCount(), 10000);
        expect(cache.hitCount(), 10000);
      });

      test('should handle frequent evictions efficiently', () async {
        final cache = LruCache<int, String>(10);
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          await cache.put(i, 'value$i');
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
        expect(await cache.size(), 10);
        expect(cache.evictionCount(), 990);
      });
    });
  });
}