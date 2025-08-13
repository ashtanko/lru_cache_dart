# LruCache Dart Package

A high-performance, thread-safe LRU (Least Recently Used) cache implementation for Dart and Flutter applications. This package provides a robust caching solution with automatic eviction policies, customizable size calculations, and comprehensive statistics tracking.

## Features

- **🚀 High Performance**: Optimized implementation using Dart's `LinkedHashMap`
- **🔒 Thread-Safe**: Built-in synchronization for concurrent access
- **📊 Statistics Tracking**: Monitor cache performance with hit rates and operation counts
- **⚙️ Customizable**: Override size calculation and value creation methods
- **🔄 Dynamic Resizing**: Resize cache capacity at runtime
- **📈 Comprehensive API**: Rich set of utility methods for cache management
- **🧪 Well Tested**: Extensive test coverage with edge cases and concurrent scenarios

## Use Cases

- **Image Caching**: Cache network images with size-based eviction
- **API Response Caching**: Store API responses to reduce network calls
- **Database Query Caching**: Cache frequently accessed database results
- **Session Management**: Store user session data with automatic cleanup
- **Resource Management**: Manage memory-intensive resources efficiently

[![Coverage](https://github.com/ashtanko/lru_cache/actions/workflows/coverage.yml/badge.svg)](https://github.com/ashtanko/lru_cache/actions/workflows/coverage.yml)
[![Dart CI](https://github.com/ashtanko/lru_cache/actions/workflows/build.yml/badge.svg)](https://github.com/ashtanko/lru_cache/actions/workflows/build.yml)

[![lru_cache](https://img.shields.io/pub/v/lru_cache?label=lru_cache)](https://pub.dev/packages/lru_cache)

[![CodeFactor](https://www.codefactor.io/repository/github/ashtanko/lru_cache_dart/badge)](https://www.codefactor.io/repository/github/ashtanko/lru_cache_dart)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/a03583ebe6b945c1b2c594b5809e908f)](https://app.codacy.com/gh/ashtanko/lru_cache/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![codecov](https://codecov.io/gh/ashtanko/lru_cache_dart/graph/badge.svg?token=V9O0ALxsV1)](https://codecov.io/gh/ashtanko/lru_cache_dart)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/a03583ebe6b945c1b2c594b5809e908f)](https://app.codacy.com/gh/ashtanko/lru_cache/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_coverage)

## Installation

Add `lru_cache` to your `pubspec.yaml`:

```yaml
dependencies:
  lru_cache: ^0.0.2
```

Then run:
```bash
dart pub get
```

## Quick Start

```dart
import 'package:lru_cache/lru_cache.dart';

void main() async {
  // Create a cache with maximum 100 entries
  final cache = LruCache<String, String>(100);
  
  // Add items to cache
  await cache.put('key1', 'value1');
  await cache.put('key2', 'value2');
  
  // Retrieve items
  final value1 = await cache.get('key1'); // Returns 'value1'
  final value2 = await cache.get('key2'); // Returns 'value2'
  
  // Check cache statistics
  print('Hit rate: ${cache.hitRate()}%');
  print('Cache size: ${await cache.size()}');
}
```

## Basic Usage

```dart
import 'package:lru_cache/lru_cache.dart';

void main() {
  // Create an LruCache with a maximum size of 2
  final cache = LruCache<String, String>(2);

  // Put key-value pairs into the cache
  cache.put('key1', 'value1');
  cache.put('key2', 'value2');

  // Retrieve values from the cache
  print(cache.get('key1')); // Prints 'value1'
  print(cache.get('key2')); // Prints 'value2'

  // Add another key-value pair, evicting the least recently used item
  cache.put('key3', 'value3');
  print(cache.get('key1')); // Prints 'null' because 'key1' was evicted

  // Retrieve the remaining items from the cache
  print(cache.get('key2')); // Prints 'value2'
  print(cache.get('key3')); // Prints 'value3'

  // Display cache statistics
  print(cache.toString()); // Prints 'LruCache[maxSize=2,hits=2,misses=1,hitRate=66%]'
}
```

## Advanced Usage

### Custom Size Calculation

```dart
class ImageCache extends LruCache<String, List<int>> {
  ImageCache(int maxSizeInBytes) : super(maxSizeInBytes);

  @override
  int sizeOf(String key, List<int> value) {
    // Calculate size based on image data length
    return value.length;
  }
}

// Usage
final imageCache = ImageCache(1024 * 1024); // 1MB cache
await imageCache.put('image1.jpg', imageData);
```

### Custom Value Creation

```dart
class UserCache extends LruCache<int, User> {
  UserCache(int maxSize) : super(maxSize);

  @override
  User? create(int userId) {
    // Fetch user from database when not in cache
    return fetchUserFromDatabase(userId);
  }
}

// Usage
final userCache = UserCache(100);
final user = await userCache.get(123); // Automatically fetches if not cached
```

### Cache Statistics

```dart
final cache = LruCache<String, String>(100);

// Monitor cache performance
print('Hit rate: ${cache.hitRate()}%');
print('Hit count: ${cache.hitCount()}');
print('Miss count: ${cache.missCount()}');
print('Eviction count: ${cache.evictionCount()}');

// Clear statistics
cache.clearStats();
```

### Dynamic Resizing

```dart
final cache = LruCache<String, String>(10);

// Add items
await cache.put('key1', 'value1');
await cache.put('key2', 'value2');

// Resize cache
await cache.resize(5); // Reduces size, may evict items
await cache.resize(20); // Increases size, no eviction
```

## API Reference

### Core Methods

- `put(K key, V value)`: Add or update an entry in the cache
- `get(K key)`: Retrieve a value from the cache
- `remove(K key)`: Remove an entry from the cache
- `evictAll()`: Clear all entries from the cache
- `resize(int maxSize)`: Change the maximum size of the cache

### Utility Methods

- `containsKey(K key)`: Check if a key exists in the cache
- `keys()`: Get all keys in LRU order
- `values()`: Get all values in LRU order
- `isEmpty()`: Check if cache is empty
- `isNotEmpty()`: Check if cache has entries
- `size()`: Get current number of entries
- `maxSize()`: Get maximum cache size

### Statistics Methods

- `hitRate()`: Get cache hit rate as percentage
- `hitCount()`: Get number of cache hits
- `missCount()`: Get number of cache misses
- `putCount()`: Get number of put operations
- `createCount()`: Get number of created values
- `evictionCount()`: Get number of evicted entries
- `clearStats()`: Reset all statistics

### Overridable Methods

- `sizeOf(K key, V value)`: Calculate size of an entry (default: 1)
- `create(K key)`: Create a value when key is not found (default: null)
- `entryRemoved(bool evicted, K key, V oldValue, V? newValue)`: Called when entries are removed

## Examples

See the `example/` directory for complete working examples:

- `lru_cache_dart_example.dart`: Basic usage examples
- `advanced_usage_example.dart`: Advanced features and custom implementations
```

## Contributing

Contributions are welcome! Please read the contributing guide to learn how to contribute to the project and set up a development environment.

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
