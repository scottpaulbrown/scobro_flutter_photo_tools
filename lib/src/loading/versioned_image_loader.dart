import 'dart:typed_data';

/// Fetches the bytes of the photo [id] at [version]; null when there is no
/// photo.
typedef PhotoBytesFetcher = Future<Uint8List?> Function(
  String id,
  String version,
);

/// An in-memory cache of photos keyed by id **and** version.
///
/// Made for photos behind cookie or token auth, which `Image.network` can't
/// send on every platform: you fetch with your own HTTP client in [fetch],
/// and the loader keeps the bytes. A changed version (say, after an upload)
/// is a new key, so it's fetched again; an unchanged one is served from
/// memory. Concurrent requests for the same key share one fetch, and the
/// least recently used entries are dropped past [maxEntries].
///
/// Show the photos with `VersionedMemoryImage` or `PhotoAvatar`.
class VersionedImageLoader {
  /// Creates a [VersionedImageLoader].
  VersionedImageLoader({required this.fetch, this.maxEntries = 100})
      : assert(maxEntries > 0, 'maxEntries must be positive');

  /// Fetches a photo's bytes.
  final PhotoBytesFetcher fetch;

  /// How many photos are kept in memory.
  final int maxEntries;

  final _cache = <(String, String), Uint8List?>{};
  final _inFlight = <(String, String), Future<Uint8List?>>{};

  /// How many photos are cached.
  int get length => _cache.length;

  /// The photo's bytes: from memory when cached, otherwise fetched.
  ///
  /// Null when [fetch] returns null (no photo, which is cached) or throws
  /// (not cached, so the next call tries again).
  Future<Uint8List?> load(String id, String version) {
    final key = (id, version);
    if (_cache.containsKey(key)) {
      final bytes = _cache.remove(key);
      _cache[key] = bytes; // Most recently used goes to the end.
      return Future.value(bytes);
    }
    final pending = _inFlight[key];
    if (pending != null) return pending;
    final future = _inFlight[key] = _fetch(key);
    future.whenComplete(() => _inFlight.remove(key)).ignore();
    return future;
  }

  /// Whether the photo is cached, so [peek] answers without fetching.
  bool contains(String id, String version) => _cache.containsKey((id, version));

  /// The cached bytes, without fetching or touching the LRU order; null when
  /// not cached (or cached as "no photo").
  Uint8List? peek(String id, String version) => _cache[(id, version)];

  Future<Uint8List?> _fetch((String, String) key) async {
    try {
      final bytes = await fetch(key.$1, key.$2);
      _cache[key] = bytes;
      while (_cache.length > maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Drops every cached version of [id].
  void evict(String id) => _cache.removeWhere((key, _) => key.$1 == id);

  /// Drops everything.
  void clear() => _cache.clear();
}
