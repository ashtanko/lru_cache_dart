import 'dart:collection';

import 'package:synchronized/synchronized.dart';

/// A thread-safe Least Recently Used (LRU) cache implementation.
///
/// This cache maintains a fixed maximum size and automatically evicts the least
/// recently used entries when the cache reaches its capacity. The cache is
/// thread-safe and uses synchronization to ensure consistency under concurrent
/// access.
///
/// Example usage:
/// ```dart
/// final cache = LruCache<String, String>(maxSize: 100);
///
/// // Add items to cache
/// await cache.put('key1', 'value1');
///
/// // Retrieve items
/// final value = await cache.get('key1');
///
/// // Check if key exists
/// final exists = await cache.containsKey('key1');
///
/// // Get cache statistics
/// print('Hit rate: ${cache.hitRate()}%');
/// ```
///
/// The cache provides several statistics:
/// - Hit count: Number of successful retrievals
/// - Miss count: Number of failed retrievals
/// - Hit rate: Percentage of successful retrievals
/// - Eviction count: Number of entries evicted due to size limits
///
/// Type parameters:
/// - [K]: The type of keys stored in the cache
/// - [V]: The type of values stored in the cache
class LruCache<K, V> {
  final LinkedHashMap<K, V> _map;
  final Lock _lock = Lock();

  int _size = 0;
  int _maxSize;
  int _putCount = 0;
  int _createCount = 0;
  int _evictionCount = 0;
  int _hitCount = 0;
  int _missCount = 0;

  /// Creates a new LRU cache with the specified maximum size.
  ///
  /// The [maxSize] parameter determines the maximum number of entries that can
  /// be stored in the cache. When this limit is reached, the least recently
  /// used entries will be automatically evicted.
  ///
  /// Throws an [AssertionError] if [maxSize] is not positive.
  ///
  /// Example:
  /// ```dart
  /// final cache = LruCache<String, String>(100);
  /// ```
  LruCache(int maxSize)
      : assert(maxSize > 0, 'maxSize must be greater than 0'),
        _maxSize = maxSize,
        _map = LinkedHashMap<K, V>();

  /// Resizes the cache to the specified [maxSize].
  /// If the new [maxSize] is smaller than the current size of the cache,
  /// the least recently used entries will be evicted until the size of the
  /// cache is less than or equal to the new [maxSize].
  Future<void> resize(int maxSize) async {
    assert(maxSize > 0, 'maxSize must be greater than 0');
    await _lock.synchronized(() {
      _maxSize = maxSize;
      _trimToSize(maxSize);
    });
  }

  /// Returns the value associated with the [key] or `null` if the [key] is not
  /// in the cache.
  /// If the [key] is in the cache, it is marked as the most recently used.
  /// If the [key] is not in the cache, the [create] method is called to create
  /// a value for the [key]. If the [create] method returns `null`, `null` is
  /// returned.
  Future<V?> get(K key) async {
    assert(key != null, 'key must not be null');
    return await _lock.synchronized(() {
      final V? mapValue = _map[key];
      if (mapValue != null) {
        _hitCount++;
        // Move to end to mark as most recently used
        _map.remove(key);
        _map[key] = mapValue;
        return mapValue;
      }
      _missCount++;
      final V? createdValue = create(key);
      if (createdValue == null) {
        return null;
      }

      _createCount++;
      _map[key] = createdValue;
      _size += safeSizeOf(key, createdValue);
      _trimToSize(_maxSize);
      return createdValue;
    });
  }

  /// Associates the [key] with the [value] in the cache.
  ///
  /// If the [key] already exists in the cache, the existing value is replaced
  /// with the new [value] and the previous value is returned. The key becomes
  /// the most recently used.
  ///
  /// If the [key] does not exist, the [value] is added to the cache. If this
  /// causes the cache to exceed its maximum size, the least recently used
  /// entries are automatically evicted.
  ///
  /// This method is thread-safe and will block other operations until complete.
  ///
  /// Returns the previous value associated with [key], or `null` if there was
  /// no previous value.
  ///
  /// Throws an [AssertionError] if [key] or [value] is `null`.
  ///
  /// Example:
  /// ```dart
  /// final cache = LruCache<String, String>(2);
  ///
  /// // Add new entry
  /// final previous = await cache.put('key1', 'value1');
  /// print(previous); // null
  ///
  /// // Replace existing entry
  /// final previous = await cache.put('key1', 'new_value');
  /// print(previous); // 'value1'
  /// ```
  Future<V?> put(K key, V value) async {
    assert(key != null && value != null, 'key and value must not be null');
    return await _lock.synchronized(() {
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
    });
  }

  /// Evicts the least recently used entries until the size of the cache is
  /// less than or equal to the [maxSize].
  /// If the [maxSize] is less than 0, all entries are evicted.
  /// This method is called by [put] and [resize] after adding or updating
  /// an entry.
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

  MapEntry<K, V>? _eldest() => _map.entries.firstOrNull;

  /// Removes the [key] and its associated value from the cache.
  /// Returns the value associated with the [key] or `null` if the [key] is not
  /// in the cache.
  /// If the [key] is in the cache, the entry is removed and the size of the
  /// cache is adjusted.
  Future<V?> remove(K key) async {
    assert(key != null, 'key must not be null');
    return await _lock.synchronized(() {
      final V? previous = _map.remove(key);
      if (previous != null) {
        _size -= safeSizeOf(key, previous);
        entryRemoved(false, key, previous, null);
      }
      return previous;
    });
  }

  void entryRemoved(bool evicted, K key, V oldValue, V? newValue) {}

  V? create(K key) => null;

  /// Returns the size of the [value] for the [key].
  /// The default implementation returns `1` for all entries.
  /// Subclasses can override this method to return the actual size of the
  /// [value].
  /// The size must be non-negative.
  /// If the size is negative, a [StateError] is thrown.
  /// If the size is zero, the entry is evicted from the cache.
  /// If the size is greater than the [maxSize], the entry is evicted from the
  /// cache.
  int safeSizeOf(K key, V value) {
    final int result = sizeOf(key, value);
    if (result < 0) {
      throw StateError('Size must be non-negative: $key=$value');
    }
    return result;
  }

  /// Returns the size of the [value] for the [key].
  int sizeOf(K key, V value) => 1;

  /// Removes all entries from the cache.
  Future<void> evictAll() async {
    await _lock.synchronized(() {
      _trimToSize(-1);
    });
  }

  /// Returns the number of entries in the cache.
  Future<int> size() async {
    return await _lock.synchronized(() => _size);
  }

  /// Returns the maximum size of the cache.
  int maxSize() => _maxSize;

  /// Returns the number of times an entry has been accessed.
  int hitCount() => _hitCount;

  /// Returns the number of times an entry has been accessed.
  int missCount() => _missCount;

  /// Returns the number of times an entry has been created.
  int createCount() => _createCount;

  /// Returns the number of times an entry has been added to the cache.
  int putCount() => _putCount;

  /// Returns the number of times an entry has been evicted.
  int evictionCount() => _evictionCount;

  /// Returns a snapshot of the cache.
  Map<K, V> snapshot() => Map<K, V>.from(_map);

  /// Returns the current hit rate as a percentage.
  double hitRate() {
    final int accesses = _hitCount + _missCount;
    return accesses != 0 ? (100.0 * _hitCount / accesses) : 0.0;
  }

  /// Returns whether the cache contains the specified [key].
  Future<bool> containsKey(K key) async {
    assert(key != null, 'key must not be null');
    return await _lock.synchronized(() => _map.containsKey(key));
  }

  /// Returns all keys in the cache in order of least recently used to most recently used.
  Future<List<K>> keys() async {
    return await _lock.synchronized(() => _map.keys.toList());
  }

  /// Returns all values in the cache in order of least recently used to most recently used.
  Future<List<V>> values() async {
    return await _lock.synchronized(() => _map.values.toList());
  }

  /// Returns whether the cache is empty.
  Future<bool> isEmpty() async {
    return await _lock.synchronized(() => _map.isEmpty);
  }

  /// Returns whether the cache is not empty.
  Future<bool> isNotEmpty() async {
    return await _lock.synchronized(() => _map.isNotEmpty);
  }

  /// Clears all statistics (hit count, miss count, etc.).
  void clearStats() {
    _hitCount = 0;
    _missCount = 0;
    _createCount = 0;
    _putCount = 0;
    _evictionCount = 0;
  }

  @override
  String toString() {
    final int accesses = _hitCount + _missCount;
    final int hitPercent = accesses != 0 ? (100 * _hitCount ~/ accesses) : 0;
    return 'LruCache[maxSize=$_maxSize,hits=$_hitCount,misses=$_missCount,'
        'hitRate=$hitPercent%]';
  }
}
