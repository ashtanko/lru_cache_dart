## LruCache Dart Package

`lru_cache` is a Dart package that provides a simple and efficient implementation of an LRU (Least Recently Used) cache. This package uses Dart's built-in `LinkedHashMap` to maintain the order of elements based on their access history, making it suitable for scenarios where you want to limit the number of cached items and evict the least recently used items when the cache reaches its maximum capacity.

[![Coverage](https://github.com/ashtanko/lru_cache/actions/workflows/coverage.yml/badge.svg)](https://github.com/ashtanko/lru_cache/actions/workflows/coverage.yml)
[![Dart CI](https://github.com/ashtanko/lru_cache/actions/workflows/build.yml/badge.svg)](https://github.com/ashtanko/lru_cache/actions/workflows/build.yml)
[![lru_cache](https://img.shields.io/pub/v/lru_cache?label=lru_cache)](https://pub.dev/packages/lru_cache)

### Features

- **LRU (Least Recently Used) Cache**: Keeps track of the most recently accessed items and evicts the least recently used items when the cache reaches its maximum size.
- **Customizable Size Calculation**: Override `sizeOf` to control capacity by an arbitrary weight (e.g., bytes) instead of entry count.
- **Thread-safe Operations**: Uses synchronization to ensure thread safety when accessing and modifying the cache.

## Getting started 🎉

Add to your `pubspec.yaml`:

```yaml
dependencies:
  lru_cache: ^0.1.0
```

Import the package:

```dart
import 'package:lru_cache/lru_cache.dart';
```

## Usage
Here's an example of how to use the `LruCache` class:

```dart
import 'package:lru_cache/lru_cache.dart';

Future<void> main() async {
  // Create an LruCache with a maximum size of 2
  final cache = LruCache<String, String>(2);

  // Put key-value pairs into the cache
  await cache.put('key1', 'value1');
  await cache.put('key2', 'value2');

  // Retrieve values from the cache
  print(await cache.get('key1')); // Prints 'value1'
  print(await cache.get('key2')); // Prints 'value2'

  // Add another key-value pair, evicting the least recently used item
  await cache.put('key3', 'value3');
  print(await cache.get('key1')); // Prints 'null' because 'key1' was evicted

  // Retrieve the remaining items from the cache
  print(await cache.get('key2')); // Prints 'value2'
  print(await cache.get('key3')); // Prints 'value3'

  // Display cache statistics
  print(cache.toString()); // LruCache[maxSize=2,hits=2,misses=1,hitRate=66%]
}
```

### Weighted capacity with sizeOf

You can override `sizeOf` to count capacity by a custom weight. For example, keep total string length under a limit:

```dart
class WeightedCache extends LruCache<String, String> {
  WeightedCache(super.maxSize);
  @override
  int sizeOf(String key, String value) => value.length;
}

final cache = WeightedCache(5);
await cache.put('a', 'A');   // total 1
await cache.put('b', 'BB');  // total 3
await cache.put('c', 'CCC'); // would be 6 -> evicts LRU entries to fit 5
```

### API overview

- `Future<V?> get(K key)`: Returns value or null; reorders entry as most recent.
- `Future<V?> put(K key, V value)`: Adds or replaces; reorders as most recent.
- `Future<V?> remove(K key)`: Removes and returns previous value if any.
- `Future<void> resize(int maxSize)`: Changes capacity and trims if needed.
- `Future<void> evictAll()`: Removes all entries.
- `int maxSize()`, `Future<int> size()`: Capacity and current weighted size.
- Stats: `hitCount()`, `missCount()`, `createCount()`, `putCount()`, `evictionCount()`.
- Hooks for subclassing: `V? create(K key)`, `void entryRemoved(...)`, `int sizeOf(...)`.

### Thread-safety

All mutating operations are synchronized. Avoid calling back into the same cache from `create` or `entryRemoved` to prevent re-entrancy.

## Contributing

Contributions are welcome! Please open issues and pull requests on GitHub.

## License

```plain
MIT License

Copyright (c) 2024 Oleksii Shtanko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
