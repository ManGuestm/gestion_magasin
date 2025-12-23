/// Service de mise en cache des données
/// Remplace le cache manuel et fragile
class CacheService<T> {
  T? _cachedData;
  DateTime? _lastUpdateTime;
  final Duration cacheDuration;

  CacheService({required this.cacheDuration});

  /// Vérifie si le cache est encore valide
  bool get isCacheValid {
    if (_cachedData == null || _lastUpdateTime == null) return false;
    final now = DateTime.now();
    return now.difference(_lastUpdateTime!).inSeconds < cacheDuration.inSeconds;
  }

  /// Obtient les données en cache
  T? get cachedData => isCacheValid ? _cachedData : null;

  /// Met en cache les données
  void cache(T data) {
    _cachedData = data;
    _lastUpdateTime = DateTime.now();
  }

  /// Invalide le cache
  void invalidate() {
    _cachedData = null;
    _lastUpdateTime = null;
  }

  /// Réinitialise le cache
  void reset() {
    invalidate();
  }

  /// Retourne les données en cache ou les charge via le callback
  Future<T> getOrLoad(Future<T> Function() loader) async {
    final cached = cachedData;
    if (cached != null) {
      return cached;
    }

    final data = await loader();
    cache(data);
    return data;
  }

  /// Obtient le temps écoulé depuis la dernière mise à jour
  Duration? get timeSinceLastUpdate {
    if (_lastUpdateTime == null) return null;
    return DateTime.now().difference(_lastUpdateTime!);
  }
}
