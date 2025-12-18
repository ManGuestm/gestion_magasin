import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/network_database_service.dart';
import 'database.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Constructor for external database
  DatabaseService._external(this._database) : _isInitialized = true; // ✅ Marquer comme initialisé

  static DatabaseService fromPath(String filePath) {
    final externalDb = AppDatabase.fromFile(File(filePath));
    return DatabaseService._external(externalDb);
  }

  AppDatabase? _database;
  NetworkDatabaseService? _networkDb;
  bool _isInitialized = false;

  // Cache pour les données fréquemment accédées
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  AppDatabase get database {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    if (_database == null) {
      throw StateError('Database is null after initialization');
    }
    return _database!;
  }

  bool get isNetworkMode => _isNetworkMode;
  bool _isNetworkMode = false;

  void setNetworkMode(bool enabled) {
    _isNetworkMode = enabled;
  }

  Future<void> initialize() async {
    try {
      // Configurer Drift pour éviter les warnings
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

      // Vérifier le mode réseau
      final config = await _getNetworkConfig();
      final mode = config['mode'];

      if (mode == 'client') {
        _isNetworkMode = true;
        _networkDb = NetworkDatabaseService();
        // En mode client, pas de base locale
        _isInitialized = true;
        return;
      }

      // Initialiser la base de données locale seulement en mode serveur
      if (_database == null) {
        _database = AppDatabase();
        // Créer l'utilisateur administrateur par défaut
        await _database?.createDefaultAdmin();
      }

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<Map<String, dynamic>> _getNetworkConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'mode': prefs.getString('network_mode') ?? 'server',
        'serverIp': prefs.getString('server_ip') ?? '',
        'port': prefs.getString('server_port') ?? '8080',
      };
    } catch (e) {
      return {'mode': 'server'};
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
    _clearCache();
  }

  void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  T? _getFromCache<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key] as T?;
    }
    return null;
  }

  void _setCache<T>(String key, T value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  // Méthodes optimisées avec cache pour les données fréquemment accédées
  Future<List<SocData>> getAllSocCached() async {
    const key = 'all_soc';
    final cached = _getFromCache<List<SocData>>(key);
    if (cached != null) return cached;

    final result = await database.getAllSoc();
    _setCache(key, result);
    return result;
  }

  Future<List<Article>> getAllArticlesCached() async {
    const key = 'all_articles';
    final cached = _getFromCache<List<Article>>(key);
    if (cached != null) return cached;

    final result = await database.getAllArticles();
    result.sort((a, b) => a.designation.compareTo(b.designation));
    _setCache(key, result);
    return result;
  }

  Future<List<CltData>> getAllClientsCached() async {
    const key = 'all_clients';
    final cached = _getFromCache<List<CltData>>(key);
    if (cached != null) return cached;

    final result = await database.getAllClients();
    _setCache(key, result);
    return result;
  }

  Future<List<Frn>> getAllFournisseursCached() async {
    const key = 'all_fournisseurs';
    final cached = _getFromCache<List<Frn>>(key);
    if (cached != null) return cached;

    final result = await database.getAllFournisseurs();
    _setCache(key, result);
    return result;
  }

  Future<List<Depot>> getAllDepotsCached() async {
    const key = 'all_depots';
    final cached = _getFromCache<List<Depot>>(key);
    if (cached != null) return cached;

    final result = await database.getAllDepots();
    _setCache(key, result);
    return result;
  }

  // Méthodes directes sans cache
  Future<List<Article>> getAllArticles() async {
    if (_isNetworkMode && _networkDb != null) {
      final articles = await _networkDb!.getAllArticles();
      articles.sort((a, b) => a.designation.compareTo(b.designation));
      return articles;
    }
    final articles = await database.getAllArticles();
    articles.sort((a, b) => a.designation.compareTo(b.designation));
    return articles;
  }

  Future<List<Frn>> getAllFournisseurs() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getAllFournisseurs();
    }
    return await database.getAllFournisseurs();
  }

  Future<List<CltData>> getAllClients() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getAllClients();
    }
    return await database.getAllClients();
  }

  Future<List<Depot>> getAllDepots() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getAllDepots();
    }
    return await database.getAllDepots();
  }

  Future<List<SocData>> getAllSoc() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getAllSoc();
    }
    return await database.getAllSoc();
  }

  // Authentification via réseau ou local
  Future<User?> authenticateUser(String username, String password) async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getUserByCredentials(username, password);
    }
    return await database.getUserByCredentials(username, password);
  }

  Future<List<String>> getAllModesPaiement() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getAllModesPaiement();
    }
    final result = await database.customSelect('SELECT mp FROM mp ORDER BY mp').get();
    return result.map((row) => row.read<String>('mp')).toList();
  }

  Future<int> getTotalClients() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getTotalClients();
    }
    return await database.getTotalClients();
  }

  Future<int> getTotalArticles() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getTotalArticles();
    }
    return await database.getTotalArticles();
  }

  Future<double> getTotalStockValue() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getTotalStockValue();
    }
    return await database.getTotalStockValue();
  }

  Future<double> getTotalVentes() async {
    if (_isNetworkMode && _networkDb != null) {
      return await _networkDb!.getTotalVentes();
    }
    return await database.getTotalVentes();
  }

  // Invalider le cache lors des modifications
  void invalidateCache(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Méthodes pour la sauvegarde et restauration
  Future<String> getDatabasePath() async {
    return await database.getDatabasePath();
  }

  Future<void> closeDatabase() async {
    await _database?.close();
    _database = null;
    _networkDb = null;
    _isInitialized = false;
    _clearCache();
  }

  Future<void> reinitializeDatabase() async {
    await closeDatabase();
    await initialize();
  }
}
