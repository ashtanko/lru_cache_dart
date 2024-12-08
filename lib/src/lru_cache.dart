import 'dart:collection';

import 'package:synchronized/synchronized.dart';

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

  LruCache(int maxSize)
      : assert(maxSize > 0, 'maxSize must be greater than 0'),
        _maxSize = maxSize,
        _map = LinkedHashMap<K, V>();

  Future<void> resize(int maxSize) async {
    assert(maxSize > 0, 'maxSize must be greater than 0');
    await _lock.synchronized(() {
      _maxSize = maxSize;
      _trimToSize(maxSize);
    });
  }

  Future<V?> get(K key) async {
    assert(key != null, 'key must not be null');
    return await _lock.synchronized(() {
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
    });
  }

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

  Future<void> _trimToSize(int maxSize) async {
    await _lock.synchronized(() {
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
    });
  }

  MapEntry<K, V>? _eldest() => _map.entries.firstOrNull;

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

  int safeSizeOf(K key, V value) {
    final int result = sizeOf(key, value);
    if (result < 0) {
      throw StateError('Size must be non-negative: $key=$value');
    }
    return result;
  }

  int sizeOf(K key, V value) => 1;

  Future<void> evictAll() async {
    await _trimToSize(-1);
  }

  Future<int> size() async {
    return await _lock.synchronized(() => _size);
  }

  int maxSize() => _maxSize;

  int hitCount() => _hitCount;

  int missCount() => _missCount;

  int createCount() => _createCount;

  int putCount() => _putCount;

  int evictionCount() => _evictionCount;

  Map<K, V> snapshot() => Map<K, V>.from(_map);

  @override
  String toString() {
    final int accesses = _hitCount + _missCount;
    final int hitPercent = accesses != 0 ? (100 * _hitCount ~/ accesses) : 0;
    return 'LruCache[maxSize=$_maxSize,hits=$_hitCount,misses=$_missCount,'
        'hitRate=$hitPercent%]';
  }
}
