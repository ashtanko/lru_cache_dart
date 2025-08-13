## 0.0.3

- **BREAKING**: Fixed LRU ordering bug in `get()` method - now properly moves accessed items to most recently used position
- **NEW**: Added comprehensive utility methods: `hitRate()`, `containsKey()`, `keys()`, `values()`, `isEmpty()`, `isNotEmpty()`, `clearStats()`
- **NEW**: Added extensive test coverage with edge cases, concurrent access, and performance tests
- **NEW**: Added advanced usage examples demonstrating custom implementations
- **IMPROVED**: Enhanced API documentation with comprehensive examples and usage patterns
- **IMPROVED**: Better README with feature overview, use cases, and API reference
- **FIXED**: Improved thread safety and consistency in concurrent scenarios
- **FIXED**: Better error handling and validation

## 0.0.2

- Add thread safety to LruCache using synchronization package.

## 0.0.1

- Initial version.
