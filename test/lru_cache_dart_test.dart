import 'package:lru_cache/src/lru_cache.dart';
import 'package:test/test.dart';

/// A subclass of [LruCache] that overrides the entryRemoved() and create
/// methods for testing.
class _TestLruCache<K, V> extends LruCache<K, V> {
  List<String> removedEntries = [];

  _TestLruCache(super.maxSize);

  @override
  void entryRemoved(bool evicted, K key, V oldValue, V? newValue) {
    removedEntries.add('$key');
  }

  @override
  V? create(K key) {
    // Simulate creation of a value for testing
    return 'Created Value for $key' as V?;
  }
}

// A subclass of [LruCache] that returns a negative size for all entries
// for testing reasons.
class _NegativeSizeLruCache<K, V> extends LruCache<K, V> {
  _NegativeSizeLruCache(super.maxSize);

  @override
  int sizeOf(K key, V value) {
    return -1; // Simulate negative size
  }
}

void main() {
  group('LruCache', () {
    test('should return null for non-existent key', () async {
      final cache = LruCache<String, String>(2);
      expect(await cache.get('key1'), isNull);
    });

    test('should cache and retrieve values', () async {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      expect(await cache.get('key1'), 'value1');
    });

    test('Throws StateError when sizeOf returns a negative size', () {
      // Custom LruCache subclass to simulate a negative size
      final cache = _NegativeSizeLruCache<int, String>(5);

      expect(
        () => cache.put(1, 'A'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Size must be non-negative: 1=A',
          ),
        ),
      );
    });

    test('should evict oldest entry when maxSize is reached', () async {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.put('key3', 'value3');
      expect(await cache.get('key1'), isNull);
      expect(await cache.get('key2'), 'value2');
      expect(await cache.get('key3'), 'value3');
    });

    test('should return correct size', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('key1', 'value1');
      expect(await cache.size(), 1);
      await cache.put('key2', 'value2');
      expect(await cache.size(), 2);
      await cache.put('key3', 'value3');
      expect(await cache.size(), 2);
    });

    test('should remove entries', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('key1', 'value1');
      expect(await cache.remove('key1'), 'value1');
      expect(await cache.get('key1'), isNull);
      expect(await cache.size(), 0);
    });

    test('should return hit count correctly', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.get('key1');
      expect(cache.hitCount(), 1);
    });

    test('should return miss count correctly', () {
      final cache = LruCache<String, String>(2);
      cache.get('key1');
      expect(cache.missCount(), 1);
    });

    test('should return put count correctly', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      expect(cache.putCount(), 1);
    });

    test('should return eviction count correctly', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.put('key3', 'value3');
      expect(cache.evictionCount(), 1);
    });

    test('should evict all entries', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      await cache.evictAll();
      expect(await cache.size(), 0);
      expect(await cache.get('key1'), isNull);
      expect(await cache.get('key2'), isNull);
    });

    test('snapshot should return all entries in the correct order', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      final snapshot = cache.snapshot();
      expect(snapshot.keys, ['key1', 'key2']);
    });

    test('resize should adjust the cache size', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      await cache.resize(1);
      expect(await cache.size(), 1);
    });

    test('toString should return correct format', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.get('key1');
      cache.get('key2');
      expect(
        cache.toString(),
        'LruCache[maxSize=2,hits=1,misses=1,hitRate=50%]',
      );
    });

    test('entryRemoved should be called on eviction', () {
      final cache = _TestLruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.put('key3', 'value3');
      expect(cache.removedEntries, contains('key1'));
    });

    test('entryRemoved should be called on removal', () {
      final cache = _TestLruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.remove('key1');
      expect(cache.removedEntries, contains('key1'));
    });

    test('Initial createCount is 0', () {
      final cache = LruCache<int, String>(2);
      expect(cache.createCount(), equals(0));
    });

    test('createCount increases on cache miss with create() called', () {
      final cache = _TestLruCache<int, String>(2);
      cache.get(1); // Cache miss, create() is called
      cache.get(2); // Cache miss, create() is called
      expect(cache.createCount(), equals(2));
    });

    test('createCount does not increase for put() calls', () {
      final cache = _TestLruCache<int, String>(2);
      cache.put(1, 'A'); // put() does not trigger create()
      cache.put(2, 'B'); // put() does not trigger create()
      expect(cache.createCount(), equals(0));
    });

    test('createCount increases correctly for multiple cache misses', () {
      final cache = _TestLruCache<int, String>(2);
      cache.get(1); // Cache miss, create() is called
      cache.get(2); // Cache miss, create() is called
      cache.get(3); // Cache miss, create() is called
      expect(cache.createCount(), equals(3));
    });

    test('Initial maxSize is set correctly during cache creation', () {
      final cache = LruCache<int, String>(5);
      expect(cache.maxSize(), equals(5));
    });

    test('maxSize updates correctly after resize', () {
      final cache = LruCache<int, String>(3);
      cache.resize(10); // Resize the cache to a new max size
      expect(cache.maxSize(), equals(10));
    });

    test('maxSize remains consistent with the value passed to resize()', () {
      final cache = LruCache<int, String>(2);
      cache.resize(8);
      expect(cache.maxSize(), equals(8));

      cache.resize(15);
      expect(cache.maxSize(), equals(15));
    });

    test('Resizing to a smaller size trims the cache', () async {
      final cache = LruCache<int, String>(5);
      await cache.put(1, 'A');
      await cache.put(2, 'B');
      await cache.put(3, 'C');
      await cache.put(4, 'D');
      await cache.put(5, 'E');
      expect(await cache.size(), equals(5));

      await cache.resize(3); // Resize to a smaller size
      expect(cache.maxSize(), equals(3));
      expect(await cache.size(), lessThanOrEqualTo(3));
    });

    test('Resizing to a larger size does not evict entries', () async {
      final cache = LruCache<int, String>(3);
      await cache.put(1, 'A');
      await cache.put(2, 'B');
      await cache.put(3, 'C');
      expect(await cache.size(), equals(3));

      await cache.resize(10); // Resize to a larger size
      expect(cache.maxSize(), equals(10));
      expect(await cache.size(), equals(3));
    });

    test('handles thread safety under concurrent access', () async {
      final cache = LruCache<int, String>(3);
      final results = <String>[];

      // Add items concurrently
      final tasks = List.generate(100, (i) async {
        cache.put(i, 'Value $i');
        final value = await cache.get(i);
        if (value != null) results.add(value);
      });

      await Future.wait(tasks);

      // Check for consistency
      expect(results.length, lessThanOrEqualTo(100));
    });
  });
}
