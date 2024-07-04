/// A Dart library providing a Least Recently Used (LRU) cache implementation.
///
/// This library allows for the creation of a cache object that stores a limited
/// number of key-value pairs. When the capacity of the cache is exceeded, the
/// least recently used (accessed or added) entries are automatically removed.
library lru_cache;

export 'src/lru_cache.dart';
