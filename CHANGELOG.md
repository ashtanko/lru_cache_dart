## 0.1.0

- Implement true LRU ordering: entries are reordered on `get()` and `put()`.
- Fix nested lock usage by trimming under a single synchronized section.
- Update examples and README to use `await` for async methods.
- Minor lint and analyzer cleanups.

## 0.0.2

- Add thread safety to LruCache using synchronization package.

## 0.0.1

- Initial version.
