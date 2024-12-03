import 'dart:collection';

/// An implementation of a Least Recently Used (LRU) Cache.
///
/// This cache holds a fixed maximum number of entries defined by [maxSize].
/// When the cache exceeds this limit, the least recently used entries are evicted.
class LruCache<K, V> {
  final LinkedHashMap<K, V> _map;
  int _size = 0;
  int _maxSize;
  int _putCount = 0;
  int _createCount = 0;
  int _evictionCount = 0;
  int _hitCount = 0;
  int _missCount = 0;

  /// Creates an [LruCache] with a maximum capacity of [maxSize].
  ///
  /// The [maxSize] must be greater than 0.
  LruCache(int maxSize)
      : assert(maxSize > 0, 'maxSize must be greater than 0'),
        _maxSize = maxSize,
        _map = LinkedHashMap<K, V>();

  /// Updates the maximum size of the cache and trims it if necessary.
  ///
  /// The [maxSize] must be greater than 0.
  void resize(int maxSize) {
    assert(maxSize > 0, 'maxSize must be greater than 0');
    _maxSize = maxSize;
    _trimToSize(maxSize);
  }

  /// Retrieves the value associated with the [key].
  ///
  /// - If the value exists in the cache, it is returned and marked as recently used.
  /// - If the value does not exist, [create] is called to generate a new value,
  /// which is then stored in the cache.
  ///
  /// Returns the value if found or created, or `null` if it cannot be created.
  V? get(K key) {
    assert(key != null, 'key must not be null');
    V? mapValue = _map[key];
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
      // Undo the put if there was a conflict
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

  /// Inserts or updates the value for the given [key].
  ///
  /// - If an entry already exists, its value is updated.
  /// - If a new entry is created, the cache is trimmed to fit within the
  /// maximum size.
  ///
  /// Returns the previous value associated with [key], or `null` if none existed.
  V? put(K key, V value) {
    assert(key != null && value != null, 'key and value must not be null');
    _putCount++;
    _size += safeSizeOf(key, value);

    final V? previous = _map[key];
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

  /// Removes entries from the cache until its size is less than or equal
  /// to [maxSize].
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
  ///
  /// If the cache is empty, returns `null`.
  MapEntry<K, V>? _eldest() => _map.entries.firstOrNull;

  /// Removes the entry associated with the given [key].
  ///
  /// Returns the previous value associated with [key], or `null` if no such
  /// entry existed.
  V? remove(K key) {
    assert(key != null, 'key must not be null');
    final V? previous = _map.remove(key);
    if (previous != null) {
      _size -= safeSizeOf(key, previous);
      entryRemoved(false, key, previous, null);
    }
    return previous;
  }

  /// Called when an entry is removed from the cache.
  ///
  /// Override to handle custom removal behavior.
  void entryRemoved(bool evicted, K key, V oldValue, V? newValue) {}

  /// Creates a value for the given [key].
  ///
  /// Override to provide custom behavior when a value is not found in the cache.
  V? create(K key) => null;

  /// Returns the size of the given [key]-[value] pair.
  ///
  /// Override [sizeOf] for custom sizing. This method ensures the size is
  /// non-negative.
  int safeSizeOf(K key, V value) {
    final int result = sizeOf(key, value);
    if (result < 0) {
      throw StateError('Size must be non-negative: $key=$value');
    }
    return result;
  }

  /// Computes the size of a cache entry. Defaults to `1`.
  int sizeOf(K key, V value) => 1;

  /// Evicts all entries from the cache.
  void evictAll() => _trimToSize(-1);

  /// Returns the current size of the cache.
  int size() => _size;

  /// Returns the maximum capacity of the cache.
  int maxSize() => _maxSize;

  /// Returns the total number of cache hits.
  int hitCount() => _hitCount;

  /// Returns the total number of cache misses.
  int missCount() => _missCount;

  /// Returns the total number of values created by [create].
  int createCount() => _createCount;

  /// Returns the total number of values added to the cache.
  int putCount() => _putCount;

  /// Returns the total number of entries evicted.
  int evictionCount() => _evictionCount;

  /// Returns a snapshot of the cache as a [Map].
  Map<K, V> snapshot() => Map<K, V>.from(_map);

  @override
  String toString() {
    final int accesses = _hitCount + _missCount;
    final int hitPercent = accesses != 0 ? (100 * _hitCount ~/ accesses) : 0;
    return 'LruCache[maxSize=$_maxSize,hits=$_hitCount,misses=$_missCount,'
        'hitRate=$hitPercent%]';
  }
}
