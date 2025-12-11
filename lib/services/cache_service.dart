import 'dart:convert';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry(this.data, this.timestamp, this.ttl);

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};
  static const Duration _defaultTTL = Duration(minutes: 5);

  /// Met en cache des données
  void put<T>(String key, T data, {Duration? ttl}) {
    _cache[key] = CacheEntry(data, DateTime.now(), ttl ?? _defaultTTL);
    _cleanExpiredEntries();
  }

  /// Récupère des données du cache
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// Vérifie si une clé existe et n'est pas expirée
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Supprime une entrée du cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Vide le cache
  void clear() {
    _cache.clear();
  }

  /// Invalide le cache pour un pattern de clés
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Nettoie les entrées expirées
  void _cleanExpiredEntries() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Statistiques du cache
  Map<String, dynamic> getStats() {
    _cleanExpiredEntries();
    return {
      'totalEntries': _cache.length,
      'memoryUsage': _estimateMemoryUsage(),
      'hitRate': _calculateHitRate(),
    };
  }

  int _hitCount = 0;
  int _missCount = 0;

  void _recordHit() => _hitCount++;
  void _recordMiss() => _missCount++;

  double _calculateHitRate() {
    final total = _hitCount + _missCount;
    return total > 0 ? _hitCount / total : 0.0;
  }

  int _estimateMemoryUsage() {
    int size = 0;
    for (final entry in _cache.values) {
      try {
        size += jsonEncode(entry.data).length;
      } catch (e) {
        size += 100; // Estimation pour les objets non-sérialisables
      }
    }
    return size;
  }
}

/// Extension pour faciliter l'utilisation du cache
extension CacheExtension on CacheService {
  /// Cache avec fonction de récupération
  Future<T> getOrSet<T>(String key, Future<T> Function() fetcher, {Duration? ttl}) async {
    final cached = get<T>(key);
    if (cached != null) {
      _recordHit();
      return cached;
    }

    _recordMiss();
    final data = await fetcher();
    put(key, data, ttl: ttl);
    return data;
  }
}
