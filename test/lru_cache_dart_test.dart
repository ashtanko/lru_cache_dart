import 'package:lru_cache/src/lru_cache.dart';
import 'package:test/test.dart';

class TestLruCache<K, V> extends LruCache<K, V> {
  List<String> removedEntries = [];

  TestLruCache(super.maxSize);

  @override
  void entryRemoved(bool evicted, K key, V oldValue, V? newValue) {
    removedEntries.add('$key');
  }
}

void main() {
  group('LruCache', () {
    test('should return null for non-existent key', () {
      final cache = LruCache<String, String>(2);
      expect(cache.get('key1'), isNull);
    });

    test('should cache and retrieve values', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      expect(cache.get('key1'), 'value1');
    });

    test('should evict oldest entry when maxSize is reached', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.put('key3', 'value3');
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), 'value2');
      expect(cache.get('key3'), 'value3');
    });

    test('should return correct size', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      expect(cache.size(), 1);
      cache.put('key2', 'value2');
      expect(cache.size(), 2);
      cache.put('key3', 'value3');
      expect(cache.size(), 2);
    });

    test('should remove entries', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      expect(cache.remove('key1'), 'value1');
      expect(cache.get('key1'), isNull);
      expect(cache.size(), 0);
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

    test('should evict all entries', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.evictAll();
      expect(cache.size(), 0);
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
    });

    test('snapshot should return all entries in the correct order', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      final snapshot = cache.snapshot();
      expect(snapshot.keys, ['key1', 'key2']);
    });

    test('resize should adjust the cache size', () {
      final cache = LruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.resize(1);
      expect(cache.size(), 1);
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
      final cache = TestLruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.put('key3', 'value3');
      expect(cache.removedEntries, contains('key1'));
    });

    test('entryRemoved should be called on removal', () {
      final cache = TestLruCache<String, String>(2);
      cache.put('key1', 'value1');
      cache.remove('key1');
      expect(cache.removedEntries, contains('key1'));
    });
  });
}
