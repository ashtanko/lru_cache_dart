import 'package:lru_cache/src/lru_cache.dart';
import 'package:test/test.dart';

class _WeightedCache extends LruCache<String, String> {
  _WeightedCache(super.maxSize);

  @override
  int sizeOf(String key, String value) => value.length;
}

void main() {
  group('LruCache additional', () {
    test('reorders on get: most recent is kept, least recent evicted',
        () async {
      final cache = LruCache<int, String>(2);
      await cache.put(1, 'A');
      await cache.put(2, 'B');

      // Access 1 so that 2 becomes least-recent
      expect(await cache.get(1), 'A');

      // Insert 3 -> should evict key 2
      await cache.put(3, 'C');

      expect(await cache.get(2), isNull);
      expect(await cache.get(1), 'A');
      expect(await cache.get(3), 'C');
    });

    test('reorders on put: updating an existing key makes it most recent',
        () async {
      final cache = LruCache<String, String>(2);
      await cache.put('k1', 'v1');
      await cache.put('k2', 'v2');

      // Update k1 -> k2 becomes LRU
      await cache.put('k1', 'v1b');

      // Insert k3 -> should evict k2
      await cache.put('k3', 'v3');

      expect(await cache.get('k2'), isNull);
      expect(await cache.get('k1'), 'v1b');
      expect(await cache.get('k3'), 'v3');
    });

    test('weighted eviction using sizeOf', () async {
      final cache = _WeightedCache(5); // capacity by total length

      await cache.put('a', 'A'); // size 1
      await cache.put('b', 'BB'); // total 3
      await cache.put('c', 'CCC'); // would be 6 -> evict 'a' (LRU) to fit 5

      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), 'BB');
      expect(await cache.get('c'), 'CCC');

      // Access 'b' to make it most recent, then add 'DDDD' (4)
      expect(await cache.get('b'), 'BB'); // now 'c' becomes LRU
      await cache.put(
          'd', 'DDDD'); // total for b(2)+d(4)=6 -> will evict 'c' and then 'b'

      expect(await cache.get('c'), isNull);
      expect(await cache.get('b'), isNull);
      expect(await cache.get('d'), 'DDDD');
    });

    test('remove returns null for missing key', () async {
      final cache = LruCache<String, String>(2);
      expect(await cache.remove('nope'), isNull);
    });

    test('snapshot reflects recency order after gets', () async {
      final cache = LruCache<String, String>(2);
      await cache.put('k1', 'v1');
      await cache.put('k2', 'v2');
      expect(cache.snapshot().keys.toList(), ['k1', 'k2']);

      // Access k1 -> order becomes k2, k1 (k2 is eldest)
      expect(await cache.get('k1'), 'v1');
      expect(cache.snapshot().keys.toList(), ['k2', 'k1']);
    });

    test('toString shows 0% hit rate with no accesses', () {
      final cache = LruCache<int, String>(1);
      expect(
          cache.toString(), 'LruCache[maxSize=1,hits=0,misses=0,hitRate=0%]');
    });
  });
}
