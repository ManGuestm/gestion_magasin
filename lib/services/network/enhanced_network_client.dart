import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';

import '../auth/auth_token_service.dart';

/// Client réseau amélioré avec authentification et gestion de tokens
class EnhancedNetworkClient {
  static EnhancedNetworkClient? _instance;
  String? _serverUrl;
  bool _isConnected = false;
  final AuthTokenService _tokenService = AuthTokenService();

  static EnhancedNetworkClient get instance => _instance ??= EnhancedNetworkClient._();

  EnhancedNetworkClient._();

  bool get isConnected => _isConnected;
  bool get isAuthenticated => _tokenService.isAuthenticated;
  String? get serverUrl => _serverUrl;

  /// Initialise le service d'authentification
  Future<void> initialize() async {
    await _tokenService.initialize();
  }

  /// Teste la connexion au serveur
  Future<bool> testConnection(String serverIp, int port) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.get(serverIp, port, '/api/health');
      final response = await request.close();
      client.close();

      _isConnected = response.statusCode == 200;
      debugPrint('Connection test: ${_isConnected ? 'OK' : 'FAILED'}');
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      debugPrint('Connection test error: $e');
      return false;
    }
  }

  /// Établit la connexion et s'authentifie
  Future<bool> connect(String serverIp, int port, String username, String password) async {
    try {
      _serverUrl = 'http://$serverIp:$port';

      // Tester la connexion d'abord
      if (!await testConnection(serverIp, port)) {
        throw Exception('Serveur indisponible');
      }

      // S'authentifier
      final token = await _tokenService.authenticate(_serverUrl!, username, password);

      if (token == null) {
        throw Exception('Authentification échouée');
      }

      _isConnected = true;
      debugPrint('Connected to $serverIp:$port as $username');
      return true;
    } catch (e) {
      debugPrint('Erreur connexion: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Effectue une requête authentifiée
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    if (!_isConnected || _serverUrl == null) {
      throw Exception('Non connecté au serveur');
    }

    // Log debugging - tracer la requête
    debugPrint('🔍 Client sending query: $sql');
    if (params != null && params.isNotEmpty) {
      debugPrint('   Params: $params');
    }

    // Rafraîchir le token s'il expire bientôt
    final token = _tokenService.currentToken;
    if (token != null) {
      final minutesBeforeExpiry = token.expiresAt.difference(DateTime.now()).inMinutes;
      if (minutesBeforeExpiry < 5) {
        final refreshed = await _tokenService.refreshToken(_serverUrl!);
        if (!refreshed) {
          throw Exception('Session expirée');
        }
      }
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.postUrl(Uri.parse('$_serverUrl/api/query'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Authorization', 'Bearer ${_tokenService.currentToken!.token}');

      final body = jsonEncode({'sql': sql, 'params': params, 'timestamp': DateTime.now().toIso8601String()});

      request.write(body);
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      client.close();

      if (response.statusCode == 401) {
        await disconnect();
        throw Exception('Session expirée');
      }

      if (response.statusCode != 200) {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Erreur serveur');
      }

      return List<Map<String, dynamic>>.from((data['data'] as List?) ?? []);
    } catch (e) {
      debugPrint('Erreur requête: $e');
      rethrow;
    }
  }

  /// Exécute une commande (INSERT, UPDATE, DELETE)
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    if (!_isConnected || _serverUrl == null) {
      throw Exception('Non connecté au serveur');
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.postUrl(Uri.parse('$_serverUrl/api/execute'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Authorization', 'Bearer ${_tokenService.currentToken!.token}');

      final body = jsonEncode({'sql': sql, 'params': params, 'timestamp': DateTime.now().toIso8601String()});

      request.write(body);
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      client.close();

      if (response.statusCode == 401) {
        await disconnect();
        throw Exception('Session expirée');
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Erreur serveur');
      }

      return data['changes'] as int? ?? 0;
    } catch (e) {
      debugPrint('Erreur exécution: $e');
      rethrow;
    }
  }

  /// Déconnecte et nettoie
  Future<void> disconnect() async {
    await _tokenService.logout();
    _isConnected = false;
    _serverUrl = null;
    debugPrint('Disconnected from server');
  }

  // ============ MÉTHODES MÉTIER POUR MODE CLIENT ============

  /// Récupère tous les clients du serveur
  Future<List<Map<String, dynamic>>> getAllClients() async {
    try {
      final result = await query('SELECT * FROM clt ORDER BY rsoc');
      debugPrint('✅ ${result.length} clients récupérés du serveur');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération clients: $e');
      rethrow;
    }
  }

  /// Récupère tous les articles du serveur
  Future<List<Map<String, dynamic>>> getAllArticles() async {
    try {
      final result = await query('SELECT * FROM articles ORDER BY designation');
      debugPrint('✅ ${result.length} articles récupérés du serveur');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération articles: $e');
      rethrow;
    }
  }

  /// Récupère les articles actifs du serveur
  Future<List<Map<String, dynamic>>> getActiveArticles() async {
    try {
      final result = await query('SELECT * FROM articles WHERE action = ? ORDER BY designation', ['A']);
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération articles actifs: $e');
      rethrow;
    }
  }

  /// Récupère tous les clients actifs du serveur
  Future<List<Map<String, dynamic>>> getActiveClients() async {
    try {
      final result = await query('SELECT * FROM clt WHERE action = ? ORDER BY rsoc', ['A']);
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération clients actifs: $e');
      rethrow;
    }
  }

  /// Récupère tous les fournisseurs du serveur
  Future<List<Map<String, dynamic>>> getAllFournisseurs() async {
    try {
      final result = await query('SELECT * FROM frns ORDER BY rsoc');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération fournisseurs: $e');
      rethrow;
    }
  }

  /// Récupère les fournisseurs actifs du serveur
  Future<List<Map<String, dynamic>>> getActiveFournisseurs() async {
    try {
      final result = await query('SELECT * FROM frns WHERE action = ? ORDER BY rsoc', ['A']);
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération fournisseurs actifs: $e');
      rethrow;
    }
  }

  /// Récupère tous les dépôts du serveur
  Future<List<Map<String, dynamic>>> getAllDepots() async {
    try {
      final result = await query('SELECT * FROM depots ORDER BY depots');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération dépôts: $e');
      rethrow;
    }
  }

  /// Authentifie un utilisateur via le serveur avec vérification de mot de passe
  /// CRITICAL: This method now enforces password verification using bcrypt
  /// to prevent unauthorized access even if username exists
  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    try {
      // Validate input parameters
      if (username.isEmpty || password.isEmpty) {
        debugPrint('❌ Authentification refusée: credentials vides');
        return null;
      }

      // Query user by username and retrieve password hash
      final result = await query(
        'SELECT id, nom, username, role, actif, password FROM users WHERE username = ?',
        [username],
      );
      if (result.isEmpty) {
        debugPrint('⚠️ Tentative authentification: utilisateur $username introuvable');
        return null;
      }

      final userRecord = result.first;
      final passwordHash = userRecord['password'] as String?;

      // SECURITY CHECK: Verify password hash against provided password
      if (passwordHash == null || passwordHash.isEmpty) {
        debugPrint('❌ ERREUR SÉCURITÉ: Utilisateur $username n\'a pas de mot de passe défini');
        return null;
      }

      // Use bcrypt to safely verify the password
      try {
        final passwordMatches = BCrypt.checkpw(password, passwordHash);

        if (!passwordMatches) {
          // Log failed authentication attempt (but not the password)
          debugPrint('❌ Authentification échouée: mot de passe incorrect pour $username');
          return null;
        }
      } catch (e) {
        // Bcrypt hash validation failed
        debugPrint('❌ ERREUR SÉCURITÉ: Impossible de valider le hash pour $username - $e');
        return null;
      }

      // Password verified successfully - return user info WITHOUT the password hash
      debugPrint('✅ Authentification réussie pour $username (role: ${userRecord['role']})');

      // Remove password hash before returning to caller
      userRecord.remove('password');
      return userRecord;
    } catch (e) {
      debugPrint('❌ Erreur authentification réseau: $e');
      rethrow;
    }
  }

  /// Récupère les modes de paiement du serveur
  Future<List<Map<String, dynamic>>> getAllModesPaiement() async {
    try {
      final result = await query('SELECT DISTINCT mp FROM mp ORDER BY mp');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération modes paiement: $e');
      rethrow;
    }
  }

  /// Récupère tous les utilisateurs du serveur (administrateurs uniquement)
  /// Enforce role-based access control - only administrators can retrieve all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      // Verify caller is authenticated
      if (!isAuthenticated) {
        throw Exception('Non authentifié');
      }

      // Get current user's role information
      final currentUsername = _tokenService.username;
      if (currentUsername == null) {
        throw Exception('Utilisateur invalide');
      }

      // Query to verify user role
      final userInfo = await query('SELECT role FROM users WHERE username = ?', [currentUsername]);
      if (userInfo.isEmpty) {
        debugPrint('❌ Tentative accès getAllUsers: utilisateur $currentUsername introuvable');
        throw Exception('Utilisateur introuvable');
      }

      final userRole = userInfo.first['role'] as String?;

      // Check authorization: only admins can retrieve all users
      if (userRole != 'admin' && userRole != 'ADMIN') {
        debugPrint('⚠️ ACCÈS NON AUTORISÉ à getAllUsers: utilisateur=$currentUsername, role=$userRole');
        throw Exception('Accès refusé: Droits administrateur requis (HTTP 403)');
      }

      // User is authorized, proceed with query
      debugPrint('✅ Accès autorisé à getAllUsers pour $currentUsername (role: $userRole)');
      final result = await query('SELECT id, nom, username, role, actif FROM users ORDER BY nom');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération utilisateurs: $e');
      rethrow;
    }
  }

  /// Récupère toutes les ventes du serveur
  Future<List<Map<String, dynamic>>> getAllVentes() async {
    try {
      final result = await query('SELECT * FROM ventes ORDER BY datev DESC');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération ventes: $e');
      rethrow;
    }
  }

  /// Récupère les stocks du serveur
  Future<List<Map<String, dynamic>>> getAllStocks() async {
    try {
      final result = await query('SELECT * FROM stocks ORDER BY article, depot');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération stocks: $e');
      rethrow;
    }
  }

  /// ============ SYNCHRONISATION CLIENT/SERVEUR ============

  /// Synchronise les opérations en attente vers le serveur
  Future<Map<String, dynamic>> syncPendingOperations(List<Map<String, dynamic>> operations) async {
    if (!_isConnected || _serverUrl == null) {
      throw Exception('Non connecté au serveur');
    }

    if (operations.isEmpty) {
      return {'success': true, 'synchronized': 0};
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.postUrl(Uri.parse('$_serverUrl/api/sync'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Authorization', 'Bearer ${_tokenService.currentToken!.token}');

      final body = jsonEncode({'operations': operations, 'timestamp': DateTime.now().toIso8601String()});

      debugPrint('📤 Envoi ${operations.length} opérations au serveur...');
      request.write(body);

      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      client.close();

      if (response.statusCode == 401) {
        await disconnect();
        throw Exception('Session expirée');
      }

      if (response.statusCode != 200) {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Erreur synchronisation');
      }

      final synchronized = data['synchronized'] as int? ?? 0;
      debugPrint('✅ Synchronisation: $synchronized/${operations.length} opérations traitées');

      return data;
    } catch (e) {
      debugPrint('❌ Erreur synchronisation: $e');
      rethrow;
    }
  }

  /// Récupère les changements du serveur depuis une date donnée
  Future<List<Map<String, dynamic>>> getServerChanges(DateTime lastSync) async {
    if (!_isConnected || _serverUrl == null) {
      return [];
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(
        Uri.parse('$_serverUrl/api/changes?since=${lastSync.toIso8601String()}'),
      );
      request.headers.add('Authorization', 'Bearer ${_tokenService.currentToken!.token}');

      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      client.close();

      if (response.statusCode == 401) {
        await disconnect();
        throw Exception('Session expirée');
      }

      if (response.statusCode != 200) {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final changes = (data['changes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (changes.isNotEmpty) {
        debugPrint('📥 ${changes.length} changements récupérés du serveur');
      }

      return changes;
    } catch (e) {
      debugPrint('⚠️ Erreur récupération changements: $e');
      return [];
    }
  }
}
