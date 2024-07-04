import 'dart:collection';

/// A simple LRU (Least Recently Used) Cache implementation.
class LruCache<K, V> {
  final LinkedHashMap<K, V> _map;
  int _size = 0;
  int _maxSize;
  int _putCount = 0;
  int _createCount = 0;
  int _evictionCount = 0;
  int _hitCount = 0;
  int _missCount = 0;

  /// Creates an [LruCache] with the given [maxSize].
  ///
  /// The [maxSize] must be greater than 0.
  LruCache(int maxSize)
      : assert(maxSize > 0, 'maxSize <= 0'),
        _maxSize = maxSize,
        _map = LinkedHashMap<K, V>();

  /// Changes the maximum size of the cache and trims it if necessary.
  void resize(int maxSize) {
    assert(maxSize > 0, 'maxSize <= 0');
    _maxSize = maxSize;
    _trimToSize(maxSize);
  }

  /// Retrieves a value from the cache for the given [key].
  ///
  /// Returns the value if it exists, otherwise returns null.
  V? get(K key) {
    assert(key != null, 'key == null');
    V? mapValue;

    mapValue = _map[key];
    if (mapValue != null) {
      _hitCount++;
      return mapValue;
    }
    _missCount++;

    final V? createdValue = create(key);
    if (createdValue == null) {
      return null;
    }

    _createCount++;
    mapValue = _map.putIfAbsent(key, () => createdValue);
    if (mapValue != null) {
      // There was a conflict so undo that last put
      _map[key] = mapValue;
    } else {
      _size += safeSizeOf(key, createdValue);
    }

    if (mapValue != null) {
      entryRemoved(false, key, createdValue, mapValue);
      return mapValue;
    } else {
      _trimToSize(_maxSize);
      return createdValue;
    }
  }

  /// Puts a value in the cache for the given [key].
  ///
  /// Returns the previous value associated with the [key], or null if there was no mapping for the [key].
  V? put(K key, V value) {
    assert(key != null && value != null, 'key == null || value == null');
    V? previous;

    _putCount++;
    _size += safeSizeOf(key, value);
    previous = _map[key];
    if (previous != null) {
      _size -= safeSizeOf(key, previous);
    }
    _map[key] = value;

    if (previous != null) {
      entryRemoved(false, key, previous, value);
    }
    _trimToSize(_maxSize);
    return previous;
  }

  /// Trims the cache to the specified [maxSize].
  void _trimToSize(int maxSize) {
    while (true) {
      K key;
      V value;

      if (_size < 0 || (_map.isEmpty && _size != 0)) {
        throw StateError(
          '$runtimeType.sizeOf() is reporting inconsistent results!',
        );
      }

      if (_size <= maxSize) {
        break;
      }

      final toEvict = _eldest();
      if (toEvict == null) {
        break;
      }

      key = toEvict.key;
      value = toEvict.value;
      _map.remove(key);
      _size -= safeSizeOf(key, value);
      _evictionCount++;
      entryRemoved(true, key, value, null);
    }
  }

  /// Returns the eldest entry in the cache.
  MapEntry<K, V>? _eldest() {
    return _map.entries.firstOrNull;
  }

  /// Removes a value from the cache for the given [key].
  ///
  /// Returns the previous value associated with the [key], or null if there was no mapping for the [key].
  V? remove(K key) {
    assert(key != null, 'key == null');
    V? previous;

    previous = _map.remove(key);
    if (previous != null) {
      _size -= safeSizeOf(key, previous);
      entryRemoved(false, key, previous, null);
    }
    return previous;
  }

  /// Called when an entry is removed from the cache.
  ///
  /// This method can be overridden to provide custom behavior on entry removal.
  void entryRemoved(bool evicted, K key, V oldValue, V? newValue) {}

  /// Creates a value for the given [key].
  ///
  /// This method can be overridden to provide custom behavior on cache miss.
  V? create(K key) {
    return null;
  }

  /// Returns the size of the entry.
  ///
  /// The default implementation returns 1. Override this method if size is different.
  int safeSizeOf(K key, V value) {
    final int result = sizeOf(key, value);
    if (result < 0) {
      throw StateError('Negative size: $key=$value');
    }
    return result;
  }

  int sizeOf(K key, V value) {
    return 1;
  }

  /// Evicts all entries from the cache.
  void evictAll() {
    _trimToSize(-1); // -1 will evict 0-sized elements
  }

  /// Returns the current size of the cache.
  int size() => _size;

  /// Returns the maximum size of the cache.
  int maxSize() => _maxSize;

  /// Returns the number of cache hits.
  int hitCount() => _hitCount;

  /// Returns the number of cache misses.
  int missCount() => _missCount;

  /// Returns the number of entries created.
  int createCount() => _createCount;

  /// Returns the number of entries put into the cache.
  int putCount() => _putCount;

  /// Returns the number of entries evicted from the cache.
  int evictionCount() => _evictionCount;

  /// Returns a snapshot of the current cache.
  Map<K, V> snapshot() {
    return Map<K, V>.from(_map);
  }

  @override
  String toString() {
    final int accesses = _hitCount + _missCount;
    final int hitPercent = accesses != 0 ? (100 * _hitCount ~/ accesses) : 0;
    return 'LruCache[maxSize=$_maxSize,hits=$_hitCount,misses=$_missCount,'
        'hitRate=$hitPercent%]';
  }
}
