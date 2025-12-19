import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Métadonnées du cache avec versioning
class CacheMetadata {
  final int version;
  final DateTime timestamp;
  final String hash;

  CacheMetadata({
    required this.version,
    required this.timestamp,
    required this.hash,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'hash': hash,
  };

  factory CacheMetadata.fromJson(Map<String, dynamic> json) =>
      CacheMetadata(
        version: json['version'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        hash: json['hash'] as String,
      );
}

/// Service de gestion du cache avec versioning et invalidation
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  late SharedPreferences _prefs;
  final Map<String, CacheMetadata> _metadata = {};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadMetadata();
    _initialized = true;
  }

  /// Sauvegarde les données avec versioning
  Future<void> setCache<T>(
    String key,
    List<T> data, {
    required int version,
  }) async {
    try {
      final jsonString = jsonEncode(data);
      final hash = _generateHash(jsonString);

      await _prefs.setString('cache_$key', jsonString);

      _metadata[key] = CacheMetadata(
        version: version,
        timestamp: DateTime.now(),
        hash: hash,
      );

      await _saveMetadata();
      debugPrint('Cache saved: $key (v$version)');
    } catch (e) {
      debugPrint('Erreur cache: $e');
    }
  }

  /// Récupère les données avec validation
  Future<List<T>?> getCache<T>(
    String key, {
    required int expectedVersion,
    required Duration maxAge,
  }) async {
    try {
      final metadata = _metadata[key];

      // Valider la version
      if (metadata == null || metadata.version != expectedVersion) {
        debugPrint('Cache miss: version mismatch for $key');
        await invalidateCache(key);
        return null;
      }

      // Valider l'âge
      final age = DateTime.now().difference(metadata.timestamp);
      if (age > maxAge) {
        debugPrint('Cache miss: expired for $key');
        await invalidateCache(key);
        return null;
      }

      final jsonString = _prefs.getString('cache_$key');
      if (jsonString == null) return null;

      return (jsonDecode(jsonString) as List).cast<T>();
    } catch (e) {
      debugPrint('Erreur lecture cache: $e');
      return null;
    }
  }

  /// Invalide le cache pour une clé
  Future<void> invalidateCache(String key) async {
    try {
      await _prefs.remove('cache_$key');
      _metadata.remove(key);
      await _saveMetadata();
      debugPrint('Cache invalidated: $key');
    } catch (e) {
      debugPrint('Erreur invalidation cache: $e');
    }
  }

  /// Invalide tout le cache
  Future<void> invalidateAllCache() async {
    try {
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await _prefs.remove(key);
        }
      }
      _metadata.clear();
      await _saveMetadata();
      debugPrint('All cache invalidated');
    } catch (e) {
      debugPrint('Erreur invalidation cache: $e');
    }
  }

  void _loadMetadata() {
    try {
      final metadataJson = _prefs.getString('cache_metadata');
      if (metadataJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(metadataJson);
        decoded.forEach((key, value) {
          _metadata[key] = CacheMetadata.fromJson(value as Map<String, dynamic>);
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement metadata cache: $e');
    }
  }

  Future<void> _saveMetadata() async {
    try {
      final metadataJson = jsonEncode(
        _metadata.map((k, v) => MapEntry(k, v.toJson())),
      );
      await _prefs.setString('cache_metadata', metadataJson);
    } catch (e) {
      debugPrint('Erreur sauvegarde metadata cache: $e');
    }
  }

  String _generateHash(String data) {
    return data.hashCode.toString();
  }
}
