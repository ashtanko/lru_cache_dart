import 'package:lru_cache/lru_cache.dart';

/// Example of a custom cache implementation with size calculation
class ImageCache extends LruCache<String, List<int>> {
  ImageCache(int maxSizeInBytes) : super(maxSizeInBytes);

  @override
  int sizeOf(String key, List<int> value) {
    // Calculate size based on image data length
    return value.length;
  }

  @override
  void entryRemoved(bool evicted, String key, List<int> oldValue, List<int>? newValue) {
    if (evicted) {
      print('Image evicted from cache: $key (${oldValue.length} bytes)');
    } else {
      print('Image replaced in cache: $key');
    }
  }

  @override
  List<int>? create(String key) {
    // Simulate loading image from network
    print('Loading image from network: $key');
    return _loadImageFromNetwork(key);
  }

  List<int> _loadImageFromNetwork(String key) {
    // Simulate network delay
    Future.delayed(Duration(milliseconds: 100));
    // Return dummy image data
    return List.generate(1000, (index) => index % 256);
  }
}

/// Example of a cache with custom value creation
class UserProfileCache extends LruCache<int, Map<String, dynamic>> {
  UserProfileCache(int maxSize) : super(maxSize);

  @override
  Map<String, dynamic>? create(int userId) {
    // Simulate fetching user profile from database
    print('Fetching user profile for ID: $userId');
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
      print('User profile evicted: ${oldValue['name']}');
    }
  }
}

Future<void> main() async {
  print('=== Basic LRU Cache Example ===\n');

  // Create a basic cache with max size of 3
  final basicCache = LruCache<String, String>(3);

  // Add some items
  await basicCache.put('key1', 'value1');
  await basicCache.put('key2', 'value2');
  await basicCache.put('key3', 'value3');

  print('Cache after adding 3 items:');
  print('Size: ${await basicCache.size()}');
  print('Keys: ${await basicCache.keys()}');
  print('Values: ${await basicCache.values()}');

  // Access an item to make it most recently used
  await basicCache.get('key1');

  // Add a fourth item - this will evict the least recently used item
  await basicCache.put('key4', 'value4');

  print('\nCache after adding 4th item:');
  print('Size: ${await basicCache.size()}');
  print('Keys: ${await basicCache.keys()}');
  print('Hit rate: ${basicCache.hitRate().toStringAsFixed(1)}%');

  // Check if items exist
  print('\nChecking if items exist:');
  print('key1 exists: ${await basicCache.containsKey('key1')}');
  print('key2 exists: ${await basicCache.containsKey('key2')}'); // Should be false (evicted)

  print('\n=== Image Cache Example ===\n');

  // Create an image cache with max size of 5000 bytes
  final imageCache = ImageCache(5000);

  // Simulate loading images
  final image1 = await imageCache.get('image1.jpg');
  final image2 = await imageCache.get('image2.jpg');
  final image3 = await imageCache.get('image3.jpg');

  print('Loaded ${image1?.length ?? 0} bytes for image1.jpg');
  print('Loaded ${image2?.length ?? 0} bytes for image2.jpg');
  print('Loaded ${image3?.length ?? 0} bytes for image3.jpg');

  // Access image1 again to make it most recently used
  await imageCache.get('image1.jpg');

  // Add a large image that will cause eviction
  await imageCache.put('large_image.jpg', List.generate(3000, (i) => i % 256));

  print('\nCache statistics:');
  print('Size: ${await imageCache.size()} bytes');
  print('Max size: ${imageCache.maxSize()} bytes');
  print('Hit count: ${imageCache.hitCount()}');
  print('Miss count: ${imageCache.missCount()}');
  print('Eviction count: ${imageCache.evictionCount()}');

  print('\n=== User Profile Cache Example ===\n');

  // Create a user profile cache
  final userCache = UserProfileCache(5);

  // Fetch user profiles (will trigger create method)
  final user1 = await userCache.get(1);
  final user2 = await userCache.get(2);
  final user3 = await userCache.get(3);

  print('User 1: ${user1?['name']}');
  print('User 2: ${user2?['name']}');
  print('User 3: ${user3?['name']}');

  // Access user1 again (cache hit)
  final user1Again = await userCache.get(1);
  print('User 1 again: ${user1Again?['name']}');

  // Add more users to trigger eviction
  for (int i = 4; i <= 8; i++) {
    await userCache.get(i);
  }

  print('\nUser cache statistics:');
  print('Size: ${await userCache.size()}');
  print('Hit rate: ${userCache.hitRate().toStringAsFixed(1)}%');
  print('Create count: ${userCache.createCount()}');

  print('\n=== Cache Resize Example ===\n');

  // Create a cache and demonstrate resizing
  final resizeCache = LruCache<String, String>(2);
  await resizeCache.put('item1', 'value1');
  await resizeCache.put('item2', 'value2');

  print('Before resize:');
  print('Max size: ${resizeCache.maxSize()}');
  print('Current size: ${await resizeCache.size()}');
  print('Items: ${await resizeCache.keys()}');

  // Resize to larger size
  await resizeCache.resize(5);
  await resizeCache.put('item3', 'value3');
  await resizeCache.put('item4', 'value4');

  print('\nAfter resize to larger size:');
  print('Max size: ${resizeCache.maxSize()}');
  print('Current size: ${await resizeCache.size()}');
  print('Items: ${await resizeCache.keys()}');

  // Resize to smaller size (will cause eviction)
  await resizeCache.resize(1);

  print('\nAfter resize to smaller size:');
  print('Max size: ${resizeCache.maxSize()}');
  print('Current size: ${await resizeCache.size()}');
  print('Items: ${await resizeCache.keys()}');

  print('\n=== Performance Example ===\n');

  // Demonstrate cache performance
  final perfCache = LruCache<int, String>(100);
  final stopwatch = Stopwatch()..start();

  // Perform many operations
  for (int i = 0; i < 1000; i++) {
    await perfCache.put(i, 'value$i');
    await perfCache.get(i);
  }

  stopwatch.stop();

  print('Performance test completed in ${stopwatch.elapsedMilliseconds}ms');
  print('Operations: ${perfCache.putCount() + perfCache.hitCount() + perfCache.missCount()}');
  print('Hit rate: ${perfCache.hitRate().toStringAsFixed(1)}%');

  print('\n=== Cache Statistics ===\n');

  // Clear statistics and show final state
  perfCache.clearStats();
  print('After clearing statistics:');
  print('Hit count: ${perfCache.hitCount()}');
  print('Miss count: ${perfCache.missCount()}');
  print('Put count: ${perfCache.putCount()}');
  print('Create count: ${perfCache.createCount()}');
  print('Eviction count: ${perfCache.evictionCount()}');
}