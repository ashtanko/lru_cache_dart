# LruCache - High-Performance LRU Cache for Dart

A blazingly fast, thread-safe LRU (Least Recently Used) cache implementation for Dart and Flutter applications. Perfect for caching API responses, images, database queries, and any data that needs automatic eviction based on usage patterns.

## 🚀 Key Features

- **⚡ High Performance**: Optimized using Dart's `LinkedHashMap` for O(1) operations
- **🔒 Thread-Safe**: Built-in synchronization for concurrent access
- **📊 Rich Statistics**: Monitor cache performance with hit rates and operation counts
- **⚙️ Highly Customizable**: Override size calculation and value creation methods
- **🔄 Dynamic Resizing**: Resize cache capacity at runtime
- **📈 Comprehensive API**: Rich set of utility methods for cache management
- **🧪 Well Tested**: Extensive test coverage with edge cases and concurrent scenarios

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  lru_cache: ^0.0.3
```

## 🎯 Quick Start

```dart
import 'package:lru_cache/lru_cache.dart';

void main() async {
  // Create a cache with maximum 100 entries
  final cache = LruCache<String, String>(100);
  
  // Add items to cache
  await cache.put('user:123', '{"name": "John", "email": "john@example.com"}');
  await cache.put('user:456', '{"name": "Jane", "email": "jane@example.com"}');
  
  // Retrieve items
  final userData = await cache.get('user:123');
  print(userData); // {"name": "John", "email": "john@example.com"}
  
  // Check cache performance
  print('Hit rate: ${cache.hitRate()}%'); // 100.0%
}
```

## 🔧 Advanced Usage

### Custom Size Calculation

Perfect for caching images or large objects where you want to limit memory usage:

```dart
class ImageCache extends LruCache<String, List<int>> {
  ImageCache(int maxSizeInBytes) : super(maxSizeInBytes);

  @override
  int sizeOf(String key, List<int> value) {
    return value.length; // Size in bytes
  }
}

// Usage: 10MB image cache
final imageCache = ImageCache(10 * 1024 * 1024);
await imageCache.put('profile.jpg', imageBytes);
```

### Automatic Value Creation

Create values on-demand when they're not in the cache:

```dart
class UserCache extends LruCache<int, User> {
  UserCache(int maxSize) : super(maxSize);

  @override
  User? create(int userId) {
    // Fetch from database when not cached
    return fetchUserFromDatabase(userId);
  }
}

// Usage: Automatically fetches user if not cached
final userCache = UserCache(1000);
final user = await userCache.get(123); // Fetches from DB if needed
```

### Cache Statistics

Monitor your cache performance:

```dart
final cache = LruCache<String, String>(100);

// After some operations...
print('Hit rate: ${cache.hitRate()}%');        // 85.2%
print('Hit count: ${cache.hitCount()}');       // 1234
print('Miss count: ${cache.missCount()}');     // 215
print('Eviction count: ${cache.evictionCount()}'); // 45

// Reset statistics
cache.clearStats();
```

### Dynamic Resizing

Adjust cache size based on application needs:

```dart
final cache = LruCache<String, String>(100);

// Add items...
await cache.put('key1', 'value1');
await cache.put('key2', 'value2');

// Resize based on memory pressure
await cache.resize(50);  // Reduce size, may evict items
await cache.resize(200); // Increase size, no eviction
```

## 📊 Performance Benchmarks

Our cache is optimized for high-performance scenarios:

- **10,000 operations**: ~500ms
- **Concurrent access**: Thread-safe with minimal overhead
- **Large caches**: Efficient memory usage
- **Frequent evictions**: Optimized eviction algorithm

## 🎨 Real-World Examples

### API Response Caching

```dart
class ApiCache extends LruCache<String, ApiResponse> {
  ApiCache(int maxSize) : super(maxSize);

  @override
  ApiResponse? create(String endpoint) async {
    // Fetch from API when not cached
    return await http.get(endpoint);
  }
}

final apiCache = ApiCache(100);
final response = await apiCache.get('/api/users'); // Cached or fetched
```

### Session Management

```dart
class SessionCache extends LruCache<String, UserSession> {
  SessionCache(int maxSize) : super(maxSize);

  @override
  void entryRemoved(bool evicted, String key, UserSession oldValue, UserSession? newValue) {
    if (evicted) {
      // Clean up session resources
      oldValue.cleanup();
    }
  }
}

final sessionCache = SessionCache(1000);
await sessionCache.put('session:abc123', userSession);
```

## 🔍 API Reference

### Core Methods

| Method | Description |
|--------|-------------|
| `put(K key, V value)` | Add or update an entry |
| `get(K key)` | Retrieve a value |
| `remove(K key)` | Remove an entry |
| `evictAll()` | Clear all entries |
| `resize(int maxSize)` | Change cache size |

### Utility Methods

| Method | Description |
|--------|-------------|
| `containsKey(K key)` | Check if key exists |
| `keys()` | Get all keys (LRU order) |
| `values()` | Get all values (LRU order) |
| `isEmpty()` | Check if cache is empty |
| `size()` | Get current entry count |

### Statistics Methods

| Method | Description |
|--------|-------------|
| `hitRate()` | Get hit rate percentage |
| `hitCount()` | Get number of cache hits |
| `missCount()` | Get number of cache misses |
| `evictionCount()` | Get number of evicted entries |
| `clearStats()` | Reset all statistics |

## 🧪 Testing

The package includes comprehensive tests:

```bash
dart test
```

Tests cover:
- ✅ Basic operations
- ✅ Edge cases
- ✅ Concurrent access
- ✅ Performance benchmarks
- ✅ Custom implementations

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines for details.

## 📄 License

MIT License - see LICENSE file for details.

## 🔗 Links

- [GitHub Repository](https://github.com/ashtanko/lru_cache)
- [API Documentation](https://pub.dev/documentation/lru_cache)
- [Issue Tracker](https://github.com/ashtanko/lru_cache/issues)

---

**Ready to boost your app's performance?** Start caching with LruCache today! 🚀