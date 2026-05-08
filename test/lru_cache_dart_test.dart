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

class _RemovedEvent<K, V> {
  final bool evicted;
  final K key;
  final V oldValue;
  final V? newValue;

  _RemovedEvent(this.evicted, this.key, this.oldValue, this.newValue);
}

// A subclass that records every entryRemoved invocation in full so tests
// can assert the (evicted, key, oldValue, newValue) tuple.
class _RecordingLruCache<K, V> extends LruCache<K, V> {
  final List<_RemovedEvent<K, V>> events = [];

  _RecordingLruCache(super.maxSize);

  @override
  void entryRemoved(bool evicted, K key, V oldValue, V? newValue) {
    events.add(_RemovedEvent<K, V>(evicted, key, oldValue, newValue));
  }
}

class _ZeroSizeLruCache<K, V> extends LruCache<K, V> {
  _ZeroSizeLruCache(super.maxSize);

  @override
  int sizeOf(K key, V value) => 0;
}

class _LargeSizeLruCache<K, V> extends LruCache<K, V> {
  final int reportedSize;

  _LargeSizeLruCache(super.maxSize, this.reportedSize);

  @override
  int sizeOf(K key, V value) => reportedSize;
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

    test('get() promotes an entry to most-recently-used', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      // Touch key1 so key2 becomes the eldest.
      await cache.get('key1');
      await cache.put('key3', 'value3');
      expect(await cache.get('key1'), 'value1');
      expect(await cache.get('key2'), isNull);
      expect(await cache.get('key3'), 'value3');
    });

    test('snapshot key order reflects access order after get()', () async {
      final cache = LruCache<String, String>(3);
      await cache.put('a', '1');
      await cache.put('b', '2');
      await cache.put('c', '3');
      await cache.get('a');
      expect(cache.snapshot().keys.toList(), ['b', 'c', 'a']);
    });

    test(
      'get() on miss with create() returning non-null caches and returns it',
      () async {
        final cache = _TestLruCache<int, String>(2);
        expect(await cache.get(1), 'Created Value for 1');
        // Follow-up get() must be a hit (no second create()).
        expect(await cache.get(1), 'Created Value for 1');
        expect(cache.createCount(), 1);
        expect(cache.hitCount(), 1);
      },
    );

    test(
      'default create() returns null and createCount stays 0 on miss',
      () async {
        final cache = LruCache<int, String>(2);
        expect(await cache.get(1), isNull);
        expect(cache.createCount(), 0);
        expect(cache.missCount(), 1);
      },
    );

    test(
      'get() that creates a value triggers _trimToSize when over capacity',
      () async {
        final cache = _TestLruCache<int, String>(2);
        await cache.put(1, 'A');
        await cache.put(2, 'B');
        // Miss: create() inserts a third entry; eldest must be evicted.
        // Check via snapshot — calling get(1) would re-create via _TestLruCache.
        await cache.get(3);
        expect(await cache.size(), 2);
        expect(cache.snapshot().containsKey(1), isFalse);
        expect(cache.snapshot().containsKey(3), isTrue);
        expect(cache.evictionCount(), 1);
      },
    );

    test('put() returns null for a new key', () async {
      final cache = LruCache<String, String>(2);
      expect(await cache.put('key1', 'value1'), isNull);
    });

    test('put() returns the previous value when replacing', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('key1', 'value1');
      expect(await cache.put('key1', 'value2'), 'value1');
    });

    test('replacing a key keeps size correct', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('key1', 'value1');
      await cache.put('key1', 'value2');
      expect(await cache.size(), 1);
      expect(await cache.get('key1'), 'value2');
    });

    test(
      'replacement fires entryRemoved with evicted=false and newValue set',
      () async {
        final cache = _RecordingLruCache<String, String>(2);
        await cache.put('key1', 'value1');
        await cache.put('key1', 'value2');
        expect(cache.events.length, 1);
        final ev = cache.events.single;
        expect(ev.evicted, isFalse);
        expect(ev.key, 'key1');
        expect(ev.oldValue, 'value1');
        expect(ev.newValue, 'value2');
      },
    );

    test('eviction sets evicted=true and newValue=null', () async {
      final cache = _RecordingLruCache<String, String>(2);
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      await cache.put('key3', 'value3');
      final evictions = cache.events.where((e) => e.evicted).toList();
      expect(evictions.length, 1);
      expect(evictions.single.key, 'key1');
      expect(evictions.single.oldValue, 'value1');
      expect(evictions.single.newValue, isNull);
    });

    test('explicit remove() sets evicted=false and newValue=null', () async {
      final cache = _RecordingLruCache<String, String>(2);
      await cache.put('key1', 'value1');
      await cache.remove('key1');
      expect(cache.events.length, 1);
      final ev = cache.events.single;
      expect(ev.evicted, isFalse);
      expect(ev.key, 'key1');
      expect(ev.oldValue, 'value1');
      expect(ev.newValue, isNull);
    });

    test(
      'evictAll() fires entryRemoved for every entry with evicted=true',
      () async {
        final cache = _RecordingLruCache<String, String>(3);
        await cache.put('key1', 'value1');
        await cache.put('key2', 'value2');
        await cache.put('key3', 'value3');
        await cache.evictAll();
        expect(cache.events.length, 3);
        expect(cache.events.every((e) => e.evicted), isTrue);
        expect(cache.events.every((e) => e.newValue == null), isTrue);
        expect(cache.events.map((e) => e.key).toSet(), {
          'key1',
          'key2',
          'key3',
        });
      },
    );

    test(
      'remove() on a non-existent key returns null and does not fire hook',
      () async {
        final cache = _RecordingLruCache<String, String>(2);
        expect(await cache.remove('missing'), isNull);
        expect(cache.events, isEmpty);
      },
    );

    test('entries with sizeOf == 0 do not consume capacity', () async {
      final cache = _ZeroSizeLruCache<int, String>(2);
      for (var i = 0; i < 10; i++) {
        await cache.put(i, 'v$i');
      }
      expect(await cache.size(), 0);
      expect(cache.evictionCount(), 0);
      expect(cache.snapshot().length, 10);
    });

    test('a single entry larger than maxSize is evicted on insert', () async {
      final cache = _LargeSizeLruCache<int, String>(2, 5);
      await cache.put(1, 'A');
      expect(await cache.size(), 0);
      expect(cache.evictionCount(), 1);
      expect(await cache.get(1), isNull);
    });

    test('toString() with zero accesses reports hitRate=0%', () {
      final cache = LruCache<String, String>(2);
      expect(
        cache.toString(),
        'LruCache[maxSize=2,hits=0,misses=0,hitRate=0%]',
      );
    });

    test('LruCache(0) throws AssertionError', () {
      expect(() => LruCache<int, int>(0), throwsA(isA<AssertionError>()));
    });

    test('LruCache(-1) throws AssertionError', () {
      expect(() => LruCache<int, int>(-1), throwsA(isA<AssertionError>()));
    });

    test('resize(0) throws AssertionError', () {
      final cache = LruCache<int, int>(2);
      expect(() => cache.resize(0), throwsA(isA<AssertionError>()));
    });

    test('mutating the returned snapshot does not affect the cache', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      final snapshot = cache.snapshot();
      snapshot.clear();
      expect(await cache.size(), 2);
      expect(await cache.get('key1'), 'value1');
      expect(await cache.get('key2'), 'value2');
    });

    test('handles thread safety under concurrent access', () async {
      final cache = LruCache<int, String>(3);

      final tasks = List.generate(100, (i) async {
        await cache.put(i, 'Value $i');
        await cache.get(i);
      });

      await Future.wait(tasks);

      final size = await cache.size();
      expect(size, lessThanOrEqualTo(cache.maxSize()));
      expect(cache.snapshot().length, size);
      expect(cache.putCount(), 100);
      expect(cache.hitCount() + cache.missCount(), 100);
    });
  });
}
