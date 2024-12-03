## LruCache Dart Package

`lru_cache` is a Dart package that provides a simple and efficient implementation of an LRU (Least Recently Used) cache. This package uses Dart's built-in `LinkedHashMap` to maintain the order of elements based on their access history, making it suitable for scenarios where you want to limit the number of cached items and evict the least recently used items when the cache reaches its maximum capacity.

[![Coverage](https://github.com/ashtanko/lru_cache/actions/workflows/coverage.yml/badge.svg)](https://github.com/ashtanko/lru_cache/actions/workflows/coverage.yml)
[![Dart CI](https://github.com/ashtanko/lru_cache/actions/workflows/build.yml/badge.svg)](https://github.com/ashtanko/lru_cache/actions/workflows/build.yml)

[![lru_cache](https://img.shields.io/pub/v/lru_cache?label=lru_cache)](https://pub.dev/packages/lru_cache)

[![CodeFactor](https://www.codefactor.io/repository/github/ashtanko/lru_cache_dart/badge)](https://www.codefactor.io/repository/github/ashtanko/lru_cache_dart)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/a03583ebe6b945c1b2c594b5809e908f)](https://app.codacy.com/gh/ashtanko/lru_cache/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![codecov](https://codecov.io/gh/ashtanko/lru_cache/graph/badge.svg?token=V9O0ALxsV1)](https://codecov.io/gh/ashtanko/lru_cache)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/a03583ebe6b945c1b2c594b5809e908f)](https://app.codacy.com/gh/ashtanko/lru_cache/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_coverage)

### Features

- **LRU (Least Recently Used) Cache**: Keeps track of the most recently accessed items and evicts the least recently used items when the cache reaches its maximum size.

- **Customizable Size Calculation**: Allows customization of how the size of cached items is calculated through a `sizeOf` method, which can be overridden to fit specific use cases.

- **Thread-safe Operations**: Uses synchronized methods to ensure thread safety when accessing and modifying the cache, making it safe for concurrent use.

## Getting started 🎉

To use `lru_cache` in your Dart project, add it to your `pubspec.yaml`:

```dart
dependencies:
  lru_cache: ^latest_version
```

## Usage
Here's an example of how to use the LruCache class:

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
