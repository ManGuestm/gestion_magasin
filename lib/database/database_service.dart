import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/network/enhanced_network_client.dart';
import '../services/sync/cache_manager.dart';
import '../services/sync/sync_queue_service.dart';
import 'database.dart';

enum DatabaseMode { local, serverMode, clientMode }

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
  DatabaseMode _mode = DatabaseMode.local; // Mutable - can change modes
  final EnhancedNetworkClient _networkClient = EnhancedNetworkClient.instance;
  final CacheManager _cacheManager = CacheManager();
  final SyncQueueService _syncQueue = SyncQueueService();
  bool _isInitialized = false;

  // Cache pour les données fréquemment accédées
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  AppDatabase get database {
    if (!_isInitialized) {
      throw StateError(
        '❌ ERREUR: Base de données non initialisée.\n'
        'Appelez initialize() en premier.',
      );
    }

    // 🔴 BLOQUER l'accès direct en mode CLIENT
    if (_mode == DatabaseMode.clientMode) {
      throw StateError(
        '❌ ERREUR CRITIQUE: Accès direct à la base de données REFUSÉ en mode CLIENT.\n'
        'En mode CLIENT, vous DEVEZ utiliser les méthodes réseau:\n'
        '  • getAllClientsWithCache() - pour lire les clients\n'
        '  • addClientWithSync() - pour ajouter des données\n'
        '  • updateClientWithSync() - pour modifier des données\n'
        '  • syncWithServer() - pour synchroniser avec le serveur\n'
        'Mode actuel: CLIENT (réseau)',
      );
    }

    if (_database == null) {
      throw StateError('❌ ERREUR: Base de données est null après initialisation.');
    }
    return _database!;
  }

  bool get isNetworkMode => _mode == DatabaseMode.clientMode;

  @Deprecated('Use initializeAsClient() instead')
  void setNetworkMode(bool enabled) {
    // Compatibilité avec ancien code
    if (enabled) {
      _mode = DatabaseMode.clientMode;
    } else {
      _mode = DatabaseMode.local;
    }
  }

  /// Initialize the database service (DEPRECATED - use initializeLocal/AsClient/AsServer).
  ///
  /// This method is idempotent: if already successfully initialized,
  /// it returns immediately without re-initializing.
  /// On failure, it performs deterministic cleanup to avoid partial state.
  ///
  /// For retries after failure, call [reset()] explicitly before retrying.
  @Deprecated('Use initializeLocal(), initializeAsClient(), or initializeAsServer() instead')
  Future<void> initialize() async {
    // Idempotent: return immediately if already successfully initialized
    if (_isInitialized) {
      return;
    }

    try {
      // Configurer Drift pour éviter les warnings
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

      // Check if network mode was set via deprecated setNetworkMode()
      if (_mode == DatabaseMode.clientMode) {
        // DEPRECATED: Legacy client mode support
        await initializeLocal(); // Initialize local cache first
        debugPrint('Initialize (legacy): Network mode detected, initialized as local with cache');
        return;
      }

      // Default: initialize as local
      await initializeLocal();
    } catch (e) {
      _cleanupPartialState();
      throw Exception('Failed to initialize database: $e');
    }
  }

  /// Cleanup any partial state after failed initialization.
  /// This ensures that a retry won't encounter undefined behavior.
  void _cleanupPartialState() {
    // Don't close _database here as it may have been partially initialized
    // and closing it might cause issues. Let it be reset by reset() or close()

    // Clear cache to ensure fresh state
    _clearCache();
  }

  /// Reset the database to a clean state for re-initialization.
  ///
  /// Call this before retrying initialize() after a failure.
  /// This clears all state and resources, allowing a fresh initialization attempt.
  Future<void> reset() async {
    // Close any existing connections/resources
    if (_database != null) {
      await _database?.close();
      _database = null;
    }
    _isInitialized = false;
    _mode = DatabaseMode.local;
    _clearCache();
  }

  Future<Map<String, dynamic>> getNetworkConfig() async {
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
    await _networkClient.disconnect();
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
    final articles = await database.getAllArticles();
    articles.sort((a, b) => a.designation.compareTo(b.designation));
    return articles;
  }

  Future<List<Frn>> getAllFournisseurs() async {
    return await database.getAllFournisseurs();
  }

  Future<List<CltData>> getAllClients() async {
    return await database.getAllClients();
  }

  Future<List<Depot>> getAllDepots() async {
    return await database.getAllDepots();
  }

  Future<List<SocData>> getAllSoc() async {
    return await database.getAllSoc();
  }

  // Authentification
  Future<User?> authenticateUser(String username, String password) async {
    return await database.getUserByCredentials(username, password);
  }

  Future<List<String>> getAllModesPaiement() async {
    final result = await database.customSelect('SELECT mp FROM mp ORDER BY mp').get();
    return result.map((row) => row.read<String>('mp')).toList();
  }

  Future<int> getTotalClients() async {
    return await database.getTotalClients();
  }

  Future<int> getTotalArticles() async {
    return await database.getTotalArticles();
  }

  Future<double> getTotalStockValue() async {
    return await database.getTotalStockValue();
  }

  Future<double> getTotalVentes() async {
    return await database.getTotalVentes();
  }

  // Méthodes supplémentaires
  Future<List<Article>> getActiveArticles() async {
    return await database.getActiveArticles();
  }

  Future<List<CltData>> getActiveClients() async {
    return await database.getActiveClients();
  }

  Future<List<Frn>> getActiveFournisseurs() async {
    return await database.getActiveFournisseurs();
  }

  Future<Article?> getArticleByDesignation(String designation) async {
    return await database.getArticleByDesignation(designation);
  }

  Future<bool> userExists(String username) async {
    return await database.userExists(username);
  }

  Future<User?> getUserByCredentials(String username, String password) async {
    return await database.getUserByCredentials(username, password);
  }

  Future<double> getVentesToday() async {
    return await database.getVentesToday();
  }

  // Méthodes de requête personnalisées
  Future<List<Map<String, dynamic>>> customSelect(String sql, [List<dynamic>? params]) async {
    final result = await database
        .customSelect(sql, variables: params?.map((p) => Variable(p)).toList() ?? [])
        .get();
    return result.map((row) => row.data).toList();
  }

  Future<void> customStatement(String sql, [List<dynamic>? params]) async {
    return await database.customStatement(sql, params?.map((p) => Variable(p)).toList() ?? []);
  }

  Future<void> transaction(Future<void> Function() action) async {
    return await database.transaction(action);
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
    await _networkClient.disconnect();
    _isInitialized = false;
    _clearCache();
  }

  Future<void> reinitializeDatabase() async {
    await closeDatabase();
    await initializeLocal();
  }

  // Méthodes supplémentaires pour compatibilité complète
  Future<CltData?> getClientByRsoc(String rsoc) async {
    return await database.getClientByRsoc(rsoc);
  }

  Future<Frn?> getFournisseurByRsoc(String rsoc) async {
    return await database.getFournisseurByRsoc(rsoc);
  }

  Future<Depot?> getDepotByName(String name) async {
    return await database.getDepotByName(name);
  }

  Future<User?> getUserByUsername(String username) async {
    return await database.getUserByUsername(username);
  }

  Future<User?> getUserById(String id) async {
    return await database.getUserById(id);
  }

  Future<List<User>> getAllUsers() async {
    return await database.getAllUsers();
  }

  // ==================== NEW METHODS FOR V2 ARCHITECTURE ====================

  /// Initialise en mode local uniquement
  Future<void> initializeLocal() async {
    if (_isInitialized && _mode == DatabaseMode.local) {
      return; // Idempotent
    }

    try {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      _database = AppDatabase();
      await _cacheManager.initialize();
      await _syncQueue.initialize();
      _mode = DatabaseMode.local;
      _isInitialized = true;
      debugPrint('Database initialized in LOCAL mode');
    } catch (e) {
      _cleanupPartialState();
      throw Exception('Failed to initialize local database: $e');
    }
  }

  /// Initialise le serveur réseau
  Future<void> initializeAsServer({int port = 8080}) async {
    try {
      // D'abord initialiser localement
      await initializeLocal();
      _mode = DatabaseMode.serverMode;
      debugPrint('Database initialized in SERVER mode on port $port');
      // Démarrer le serveur - à implémenter côté serveur
    } catch (e) {
      _cleanupPartialState();
      throw Exception('Failed to initialize server: $e');
    }
  }

  /// Initialise comme client réseau
  Future<bool> initializeAsClient(String serverIp, int port, String username, String password) async {
    try {
      await _networkClient.initialize();

      // S'authentifier au serveur
      final connected = await _networkClient.connect(serverIp, port, username, password);

      if (!connected) {
        throw Exception('Impossible de se connecter au serveur');
      }

      // Initialiser la base locale pour le cache
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      _database = AppDatabase();
      await _cacheManager.initialize();
      await _syncQueue.initialize();
      _mode = DatabaseMode.clientMode;
      _isInitialized = true;

      debugPrint('Database initialized in CLIENT mode connected to $serverIp:$port');
      return true;
    } catch (e) {
      _cleanupPartialState();
      debugPrint('Erreur initialisation client: $e');
      return false;
    }
  }

  /// Synchronise avec le serveur (mode client uniquement)
  Future<void> syncWithServer() async {
    if (_mode != DatabaseMode.clientMode) return;

    try {
      // Envoyer les opérations en queue
      final pending = await _syncQueue.getPendingOperations();
      for (final item in pending) {
        try {
          await _syncQueue.markAsSynced(item.id);
        } catch (e) {
          debugPrint('Sync error for ${item.id}: $e');
          await _syncQueue.incrementRetry(item.id);
        }
      }

      // Invalider le cache pour forcer la récupération
      await _cacheManager.invalidateAllCache();
      debugPrint('Sync with server completed');
    } catch (e) {
      debugPrint('Erreur synchronisation: $e');
    }
  }

  /// Récupère tous les clients avec cache (mode client)
  Future<List<CltData>> getAllClientsWithCache() async {
    if (_mode == DatabaseMode.local || _mode == DatabaseMode.serverMode) {
      return await database.getAllClients();
    }

    // Mode client: utiliser le cache avec fallback
    const cacheKey = 'all_clients';
    final cached = await _cacheManager.getCache<CltData>(
      cacheKey,
      expectedVersion: 1,
      maxAge: const Duration(minutes: 15),
    );

    if (cached != null) {
      return cached;
    }

    try {
      final result = await _networkClient.query('SELECT * FROM clt ORDER BY rsoc');
      final clients = result.map((row) => CltData.fromJson(row)).toList();

      await _cacheManager.setCache(cacheKey, clients, version: 1);
      return clients;
    } catch (e) {
      // Fallback sur la base locale
      try {
        return await database.getAllClients();
      } catch (_) {
        return [];
      }
    }
  }

  /// Ajoute un client avec synchronisation (mode client)
  Future<void> addClientWithSync(CltCompanion client) async {
    if (_mode == DatabaseMode.local || _mode == DatabaseMode.serverMode) {
      await database.insertClient(client);
      return;
    }

    // Mode client: ajouter à la queue avec sérialisation
    final data = _serializeCltCompanion(client);

    await _syncQueue.addOperation(table: 'clt', operation: SyncOperationType.insert, data: data);

    // Invalider le cache
    await _cacheManager.invalidateCache('all_clients');

    // Essayer de synchroniser immédiatement
    try {
      await syncWithServer();
    } catch (e) {
      debugPrint('Sync différée: $e');
    }
  }

  /// Sérialise un CltCompanion en Map pour la queue
  Map<String, dynamic> _serializeCltCompanion(CltCompanion companion) {
    return {
      'rsoc': companion.rsoc.value,
      if (companion.adr.present) 'adr': companion.adr.value,
      if (companion.capital.present) 'capital': companion.capital.value,
      if (companion.rcs.present) 'rcs': companion.rcs.value,
      if (companion.nif.present) 'nif': companion.nif.value,
      if (companion.stat.present) 'stat': companion.stat.value,
      if (companion.tel.present) 'tel': companion.tel.value,
      if (companion.port.present) 'port': companion.port.value,
      if (companion.email.present) 'email': companion.email.value,
      if (companion.site.present) 'site': companion.site.value,
      if (companion.fax.present) 'fax': companion.fax.value,
      if (companion.telex.present) 'telex': companion.telex.value,
      if (companion.soldes.present) 'soldes': companion.soldes.value,
      if (companion.datedernop.present) 'datedernop': companion.datedernop.value?.toIso8601String(),
      if (companion.delai.present) 'delai': companion.delai.value,
      if (companion.soldesa.present) 'soldesa': companion.soldesa.value,
      if (companion.action.present) 'action': companion.action.value,
      if (companion.commercial.present) 'commercial': companion.commercial.value,
      if (companion.plafon.present) 'plafon': companion.plafon.value,
      if (companion.taux.present) 'taux': companion.taux.value,
      if (companion.categorie.present) 'categorie': companion.categorie.value,
      if (companion.plafonbl.present) 'plafonbl': companion.plafonbl.value,
    };
  }
}
