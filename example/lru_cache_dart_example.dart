import 'package:lru_cache/lru_cache.dart';

void main() {
  final cache = LruCache<String, String>(2);

  cache.put('key1', 'value1');
  cache.put('key2', 'value2');
  // ignore: avoid_print
  print(cache.get('key1')); // Prints 'value1'
  // ignore: avoid_print
  print(cache.get('key2')); // Prints 'value2'

  cache.put('key3', 'value3');
  // ignore: avoid_print
  print(cache.get('key1')); // Prints 'null' because 'key1' was evicted

  cache.put('key4', 'value4');
  // ignore: avoid_print
  print(cache.get('key2')); // Prints 'null' because 'key2' was evicted
  // ignore: avoid_print
  print(cache.get('key3')); // Prints 'value3'
  // ignore: avoid_print
  print(cache.get('key4')); // Prints 'value4'
  // ignore: avoid_print
  print(cache); // Prints 'LruCache[maxSize=2,hits=4,misses=2,hitRate=66%]'
}
