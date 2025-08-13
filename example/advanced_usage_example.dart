import 'package:lru_cache/lru_cache.dart';

/// Example of a custom cache implementation with size calculation
class ImageCache extends LruCache<String, List<int>> {
  ImageCache(super.maxSizeInBytes);

  @override
  int sizeOf(String key, List<int> value) {
    // Calculate size based on image data length
    return value.length;
  }

  @override
  void entryRemoved(bool evicted, String key, List<int> oldValue, List<int>? newValue) {
    if (evicted) {
      print('Image evicted from cache: $key (${oldValue.length} bytes)'); // ignore: avoid_print
    } else {
      print('Image replaced in cache: $key'); // ignore: avoid_print
    }
  }

  @override
  List<int>? create(String key) {
    // Simulate loading image from network
    print('Loading image from network: $key'); // ignore: avoid_print
    return _loadImageFromNetwork(key);
  }

  List<int> _loadImageFromNetwork(String key) {
    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 100));
    // Return dummy image data
    return List.generate(1000, (index) => index % 256);
  }
}

/// Example of a cache with custom value creation
class UserProfileCache extends LruCache<int, Map<String, dynamic>> {
  UserProfileCache(super.maxSize);

  @override
  Map<String, dynamic>? create(int userId) {
    // Simulate fetching user profile from database
    print('Fetching user profile for ID: $userId'); // ignore: avoid_print
    return {
      'id': userId,
      'name': 'User $userId',
      'email': 'user$userId@example.com',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  void entryRemoved(bool evicted, int key, Map<String, dynamic> oldValue, Map<String, dynamic>? newValue) {
    if (evicted) {
      print('User profile evicted: ${oldValue['name']}'); // ignore: avoid_print
    }
  }
}

Future<void> main() async {
  print('=== Basic LRU Cache Example ===\n'); // ignore: avoid_print

  // Create a basic cache with max size of 3
  final basicCache = LruCache<String, String>(3);

  // Add some items
  await basicCache.put('key1', 'value1');
  await basicCache.put('key2', 'value2');
  await basicCache.put('key3', 'value3');

  print('Cache after adding 3 items:'); // ignore: avoid_print
  print('Size: ${await basicCache.size()}'); // ignore: avoid_print
  print('Keys: ${await basicCache.keys()}'); // ignore: avoid_print
  print('Values: ${await basicCache.values()}'); // ignore: avoid_print

  // Access an item to make it most recently used
  await basicCache.get('key1');

  // Add a fourth item - this will evict the least recently used item
  await basicCache.put('key4', 'value4');

  print('\nCache after adding 4th item:'); // ignore: avoid_print
  print('Size: ${await basicCache.size()}'); // ignore: avoid_print
  print('Keys: ${await basicCache.keys()}'); // ignore: avoid_print
  print('Hit rate: ${basicCache.hitRate().toStringAsFixed(1)}%'); // ignore: avoid_print

  // Check if items exist
  print('\nChecking if items exist:'); // ignore: avoid_print
  print('key1 exists: ${await basicCache.containsKey('key1')}'); // ignore: avoid_print
  print('key2 exists: ${await basicCache.containsKey('key2')}'); // ignore: avoid_print // Should be false (evicted)

  print('\n=== Image Cache Example ===\n'); // ignore: avoid_print

  // Create an image cache with max size of 5000 bytes
  final imageCache = ImageCache(5000);

  // Simulate loading images
  final image1 = await imageCache.get('image1.jpg');
  final image2 = await imageCache.get('image2.jpg');
  final image3 = await imageCache.get('image3.jpg');

  print('Loaded ${image1?.length ?? 0} bytes for image1.jpg'); // ignore: avoid_print
  print('Loaded ${image2?.length ?? 0} bytes for image2.jpg'); // ignore: avoid_print
  print('Loaded ${image3?.length ?? 0} bytes for image3.jpg'); // ignore: avoid_print

  // Access image1 again to make it most recently used
  await imageCache.get('image1.jpg');

  // Add a large image that will cause eviction
  await imageCache.put('large_image.jpg', List.generate(3000, (i) => i % 256));

  print('\nCache statistics:'); // ignore: avoid_print
  print('Size: ${await imageCache.size()} bytes'); // ignore: avoid_print
  print('Max size: ${imageCache.maxSize()} bytes'); // ignore: avoid_print
  print('Hit count: ${imageCache.hitCount()}'); // ignore: avoid_print
  print('Miss count: ${imageCache.missCount()}'); // ignore: avoid_print
  print('Eviction count: ${imageCache.evictionCount()}'); // ignore: avoid_print

  print('\n=== User Profile Cache Example ===\n'); // ignore: avoid_print

  // Create a user profile cache
  final userCache = UserProfileCache(5);

  // Fetch user profiles (will trigger create method)
  final user1 = await userCache.get(1);
  final user2 = await userCache.get(2);
  final user3 = await userCache.get(3);

  print('User 1: ${user1?['name']}'); // ignore: avoid_print
  print('User 2: ${user2?['name']}'); // ignore: avoid_print
  print('User 3: ${user3?['name']}'); // ignore: avoid_print

  // Access user1 again (cache hit)
  final user1Again = await userCache.get(1);
  print('User 1 again: ${user1Again?['name']}'); // ignore: avoid_print

  // Add more users to trigger eviction
  for (int i = 4; i <= 8; i++) {
    await userCache.get(i);
  }

  print('\nUser cache statistics:'); // ignore: avoid_print
  print('Size: ${await userCache.size()}'); // ignore: avoid_print
  print('Hit rate: ${userCache.hitRate().toStringAsFixed(1)}%'); // ignore: avoid_print
  print('Create count: ${userCache.createCount()}'); // ignore: avoid_print

  print('\n=== Cache Resize Example ===\n'); // ignore: avoid_print

  // Create a cache and demonstrate resizing
  final resizeCache = LruCache<String, String>(2);
  await resizeCache.put('item1', 'value1');
  await resizeCache.put('item2', 'value2');

  print('Before resize:'); // ignore: avoid_print
  print('Max size: ${resizeCache.maxSize()}'); // ignore: avoid_print
  print('Current size: ${await resizeCache.size()}'); // ignore: avoid_print
  print('Items: ${await resizeCache.keys()}'); // ignore: avoid_print

  // Resize to larger size
  await resizeCache.resize(5);
  await resizeCache.put('item3', 'value3');
  await resizeCache.put('item4', 'value4');

  print('\nAfter resize to larger size:'); // ignore: avoid_print
  print('Max size: ${resizeCache.maxSize()}'); // ignore: avoid_print
  print('Current size: ${await resizeCache.size()}'); // ignore: avoid_print
  print('Items: ${await resizeCache.keys()}'); // ignore: avoid_print

  // Resize to smaller size (will cause eviction)
  await resizeCache.resize(1);

  print('\nAfter resize to smaller size:'); // ignore: avoid_print
  print('Max size: ${resizeCache.maxSize()}'); // ignore: avoid_print
  print('Current size: ${await resizeCache.size()}'); // ignore: avoid_print
  print('Items: ${await resizeCache.keys()}'); // ignore: avoid_print

  print('\n=== Performance Example ===\n'); // ignore: avoid_print

  // Demonstrate cache performance
  final perfCache = LruCache<int, String>(100);
  final stopwatch = Stopwatch()..start();

  // Perform many operations
  for (int i = 0; i < 1000; i++) {
    await perfCache.put(i, 'value$i');
    await perfCache.get(i);
  }

  stopwatch.stop();

  print('Performance test completed in ${stopwatch.elapsedMilliseconds}ms'); // ignore: avoid_print
  print('Operations: ${perfCache.putCount() + perfCache.hitCount() + perfCache.missCount()}'); // ignore: avoid_print
  print('Hit rate: ${perfCache.hitRate().toStringAsFixed(1)}%'); // ignore: avoid_print

  print('\n=== Cache Statistics ===\n'); // ignore: avoid_print

  // Clear statistics and show final state
  perfCache.clearStats();
  print('After clearing statistics:'); // ignore: avoid_print
  print('Hit count: ${perfCache.hitCount()}'); // ignore: avoid_print
  print('Miss count: ${perfCache.missCount()}'); // ignore: avoid_print
  print('Put count: ${perfCache.putCount()}'); // ignore: avoid_print
  print('Create count: ${perfCache.createCount()}'); // ignore: avoid_print
  print('Eviction count: ${perfCache.evictionCount()}'); // ignore: avoid_print
}
