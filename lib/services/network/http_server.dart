import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../network_server.dart';

/// Serveur HTTP pour l'architecture Serveur/Client
/// Expose 5 endpoints REST pour les clients distants
class HTTPServer {
  static final HTTPServer _instance = HTTPServer._internal();
  factory HTTPServer() => _instance;
  HTTPServer._internal();

  HttpServer? _server;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  final DatabaseService _db = DatabaseService();
  final Map<String, _SessionToken> _activeSessions = {};
  final Map<String, Map<String, dynamic>> _connectedClients = {}; // IP -> client info
  static const Duration _sessionTimeout = Duration(hours: 1);
  static const int _maxSessions = 100;

  // TTL-based eviction for connected clients
  static const Duration _clientActivityTimeout = Duration(minutes: 30);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  Timer? _clientCleanupTimer;

  /// Démarrer le serveur HTTP
  Future<bool> start({int port = 8080}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;

      debugPrint('🚀 Serveur HTTP démarré sur port $port');

      // Start client activity cleanup timer (TTL-based eviction)
      _startClientCleanupTimer();

      // Écouter les requêtes
      _server!.listen(
        (request) => _handleRequest(request).catchError((e) {
          debugPrint('❌ Erreur requête: $e');
          try {
            request.response.statusCode = 500;
            request.response.close();
          } catch (_) {}
        }),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Erreur démarrage serveur: $e');
      _isRunning = false;
      return false;
    }
  }

  /// Arrêter le serveur
  Future<void> stop() async {
    if (_server != null) {
      // Cancel client cleanup timer
      _stopClientCleanupTimer();

      await _server!.close();
      _isRunning = false;
      _connectedClients.clear();
      debugPrint('🛑 Serveur arrêté');
    }
  }

  /// Obtenir les clients REST connectés
  List<Map<String, dynamic>> getConnectedClientsInfo() {
    return _connectedClients.values.map((client) => Map<String, dynamic>.from(client)).toList();
  }

  /// Start periodic cleanup timer for inactive clients (TTL-based eviction)
  void _startClientCleanupTimer() {
    if (_clientCleanupTimer != null) {
      return; // Timer already running
    }

    _clientCleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _evictInactiveClients();
    });

    debugPrint('⏱️ Cleanup timer démarré: exécution toutes les ${_cleanupInterval.inMinutes} minutes');
  }

  /// Stop the client cleanup timer
  void _stopClientCleanupTimer() {
    if (_clientCleanupTimer != null) {
      _clientCleanupTimer!.cancel();
      _clientCleanupTimer = null;
      debugPrint('⏱️ Cleanup timer annulé');
    }
  }

  /// Remove inactive clients from the map (TTL-based eviction with safe removal)
  /// Collects keys to remove first, then removes them to avoid concurrent modification
  void _evictInactiveClients() {
    if (_connectedClients.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final keysToRemove = <String>[];

    // Collect all keys whose last activity is older than the timeout threshold
    for (final entry in _connectedClients.entries) {
      final lastActivity = entry.value['derniere_activite'] as DateTime?;
      if (lastActivity != null) {
        final timeSinceLastActivity = now.difference(lastActivity);
        if (timeSinceLastActivity > _clientActivityTimeout) {
          keysToRemove.add(entry.key);
        }
      }
    }

    // Perform removals safely (no concurrent modification issues)
    if (keysToRemove.isNotEmpty) {
      for (final key in keysToRemove) {
        final removedClient = _connectedClients.remove(key);
        if (removedClient != null) {
          debugPrint(
            '🧹 Client inactif supprimé: IP=$key, dernière_activité=${removedClient['derniere_activite']}, '
            'timeout=${_clientActivityTimeout.inMinutes}min',
          );
        }
      }
      debugPrint(
        '♻️ Cleanup: ${keysToRemove.length} clients inactifs supprimés, ${_connectedClients.length} clients actifs restants',
      );
    }
  }

  /// Traiter une requête HTTP
  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'Inconnu';

    // Enregistrer le client actif
    _connectedClients[clientIp] = {
      'ip': clientIp,
      'derniere_activite': DateTime.now(),
      'methode': method,
      'endpoint': path,
    };

    // Ajouter headers CORS
    _addCorsHeaders(request);

    // OPTIONS preflight
    if (method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    debugPrint('→ $method $path');

    try {
      request.response.headers.contentType = ContentType.json;

      // Router les endpoints
      switch (path) {
        case '/api/health':
          if (method == 'GET') {
            await _handleHealth(request);
          } else {
            _sendError(request, 405, 'Method not allowed');
          }
          break;

        case '/api/authenticate':
          if (method == 'POST') {
            await _handleAuthenticate(request);
          } else {
            _sendError(request, 405, 'Method not allowed');
          }
          break;

        case '/api/refresh-token':
          if (method == 'POST') {
            await _handleRefreshToken(request);
          } else {
            _sendError(request, 405, 'Method not allowed');
          }
          break;

        case '/api/query':
          if (method == 'POST') {
            await _handleQuery(request);
          } else {
            _sendError(request, 405, 'Method not allowed');
          }
          break;

        case '/api/execute':
          if (method == 'POST') {
            await _handleExecute(request);
          } else {
            _sendError(request, 405, 'Method not allowed');
          }
          break;

        case '/api/sync':
          if (method == 'POST') {
            await _handleSync(request);
          } else {
            _sendError(request, 405, 'Method not allowed');
          }
          break;

        case '/api/changes':
          if (method == 'GET') {
            await _handleChanges(request);
          } else {
            _sendError(request, 405, 'Method not allowed');
          }
          break;

        default:
          _sendError(request, 404, 'Endpoint not found');
      }
    } catch (e) {
      debugPrint('❌ Erreur serveur: $e');
      _sendError(request, 500, 'Server error: $e');
    }
  }

  // ==================== ENDPOINTS ====================

  /// GET /api/health - Test de connexion
  Future<void> _handleHealth(HttpRequest request) async {
    request.response.statusCode = 200;
    _sendJson(request, {
      'status': 'ok',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '2.0',
      'activeSessions': _activeSessions.length,
    });
  }

  /// POST /api/authenticate - Authentification et émission de token
  Future<void> _handleAuthenticate(HttpRequest request) async {
    try {
      final body = await _readBody(request);
      final data = jsonDecode(body) as Map<String, dynamic>;

      final username = data['username'] as String?;
      final password = data['password'] as String?;

      // Validation
      if (username == null || password == null) {
        return _sendError(request, 400, 'Missing username or password');
      }

      if (username.isEmpty || password.isEmpty) {
        return _sendError(request, 400, 'Username and password cannot be empty');
      }

      // Vérifier credentials
      if (!await _validateCredentials(username, password)) {
        debugPrint('❌ Authentification échouée: $username');
        return _sendError(request, 401, 'Invalid credentials');
      }

      // Vérifier limite de sessions
      _cleanupExpiredSessions();
      if (_activeSessions.length >= _maxSessions) {
        return _sendError(request, 503, 'Server at capacity');
      }

      // Générer token
      final token = _generateToken();
      final expiresAt = DateTime.now().add(_sessionTimeout);

      _activeSessions[token] = _SessionToken(
        username: username,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );

      request.response.statusCode = 200;
      _sendJson(request, {
        'success': true,
        'data': {
          'token': token,
          'expiresAt': expiresAt.toIso8601String(),
          'userId': 'user_${username.hashCode}',
          'username': username,
        },
      });

      debugPrint('✅ Authentification réussie: $username');
    } catch (e) {
      _sendError(request, 400, 'Bad request: $e');
    }
  }

  /// POST /api/refresh-token - Rafraîchir un token
  Future<void> _handleRefreshToken(HttpRequest request) async {
    try {
      final authHeader = request.headers.value('Authorization');
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return _sendError(request, 401, 'Missing or invalid Authorization header');
      }

      final token = authHeader.substring(7);
      final session = _activeSessions[token];

      if (session == null) {
        return _sendError(request, 401, 'Token not found');
      }

      if (session.isExpired) {
        _activeSessions.remove(token);
        return _sendError(request, 401, 'Token expired');
      }

      // Générer nouveau token
      final newToken = _generateToken();
      final expiresAt = DateTime.now().add(_sessionTimeout);

      _activeSessions.remove(token);
      _activeSessions[newToken] = _SessionToken(
        username: session.username,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );

      request.response.statusCode = 200;
      _sendJson(request, {
        'success': true,
        'data': {'token': newToken, 'expiresAt': expiresAt.toIso8601String()},
      });

      debugPrint('🔄 Token rafraîchi pour ${session.username}');
    } catch (e) {
      _sendError(request, 400, 'Bad request: $e');
    }
  }

  /// POST /api/query - Exécuter une requête SELECT (lecture seule)
  Future<void> _handleQuery(HttpRequest request) async {
    try {
      final session = await _validateSession(request);
      if (session == null) {
        return _sendError(request, 401, 'Unauthorized');
      }

      final clientIp = request.connectionInfo?.remoteAddress.address ?? 'Inconnu';

      // Enregistrer/mettre à jour le username du client
      if (_connectedClients.containsKey(clientIp)) {
        _connectedClients[clientIp]!['username'] = session.username;
      }

      final body = await _readBody(request);
      final data = jsonDecode(body) as Map<String, dynamic>;

      final sql = data['sql'] as String?;
      final params = data['params'] as List?;

      if (sql == null || sql.isEmpty) {
        return _sendError(request, 400, 'Missing or empty SQL');
      }

      // Sécurité: vérifier que c'est une requête SELECT
      if (!sql.trim().toUpperCase().startsWith('SELECT')) {
        return _sendError(request, 403, 'Only SELECT queries are allowed');
      }

      debugPrint('📖 Query: $sql with params: $params');

      // Exécuter la requête
      try {
        final result = await _db.customSelect(sql, params?.cast<dynamic>());

        request.response.statusCode = 200;
        _sendJson(request, {'success': true, 'data': result, 'rowCount': result.length});

        debugPrint('✅ Query réussie: ${result.length} lignes');
      } catch (e) {
        debugPrint('❌ Erreur SQL: $e');
        debugPrint('   SQL reçue: $sql');
        debugPrint('   Params: $params');
        debugPrint('   Session: ${session.username}');
        return _sendError(request, 400, 'SQL error: $e');
      }
    } catch (e) {
      _sendError(request, 400, 'Bad request: $e');
    }
  }

  /// POST /api/execute - Exécuter INSERT/UPDATE/DELETE
  Future<void> _handleExecute(HttpRequest request) async {
    try {
      final session = await _validateSession(request);
      if (session == null) {
        return _sendError(request, 401, 'Unauthorized');
      }

      final body = await _readBody(request);
      final data = jsonDecode(body) as Map<String, dynamic>;

      final sql = data['sql'] as String?;
      final params = data['params'] as List?;

      if (sql == null || sql.isEmpty) {
        return _sendError(request, 400, 'Missing or empty SQL');
      }

      final sqlUpper = sql.trim().toUpperCase();

      // Sécurité: vérifier que c'est INSERT/UPDATE/DELETE
      if (!sqlUpper.startsWith('INSERT') &&
          !sqlUpper.startsWith('UPDATE') &&
          !sqlUpper.startsWith('DELETE')) {
        return _sendError(request, 403, 'Only INSERT/UPDATE/DELETE queries are allowed');
      }

      debugPrint('✏️ Execute: $sql with params: $params by ${session.username}');

      try {
        // Exécuter l'instruction
        await _db.customStatement(sql, params?.cast<dynamic>());

        request.response.statusCode = 200;
        _sendJson(request, {'success': true, 'message': 'Query executed successfully'});

        debugPrint('✅ Execute réussie pour ${session.username}');
      } catch (e) {
        debugPrint('❌ Erreur SQL: $e');
        return _sendError(request, 400, 'SQL error: $e');
      }
    } catch (e) {
      _sendError(request, 400, 'Bad request: $e');
    }
  }

  // ==================== HELPERS ====================

  Future<String> _readBody(HttpRequest request) async {
    try {
      return await utf8.decoder.bind(request).join();
    } catch (e) {
      throw Exception('Failed to read request body: $e');
    }
  }

  Future<_SessionToken?> _validateSession(HttpRequest request) async {
    final authHeader = request.headers.value('Authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }

    final token = authHeader.substring(7);
    final session = _activeSessions[token];

    if (session == null || session.isExpired) {
      _activeSessions.remove(token);
      return null;
    }

    return session;
  }

  /// Public method to validate token for WebSocket connections
  /// Returns session data if token is valid, null otherwise
  Future<Map<String, dynamic>?> validateWebSocketToken(String token) async {
    try {
      final session = _activeSessions[token];

      if (session == null || session.isExpired) {
        _activeSessions.remove(token);
        return null;
      }

      return {
        'username': session.username,
        'token': token,
        'expiresAt': session.expiresAt.toIso8601String(),
        'remainingTime': session.remainingTime.inSeconds,
      };
    } catch (e) {
      debugPrint('Erreur validation token WebSocket: $e');
      return null;
    }
  }

  Future<bool> _validateCredentials(String username, String password) async {
    try {
      final user = await _db.getUserByCredentials(username, password);
      return user != null && user.actif;
    } catch (e) {
      debugPrint('❌ Erreur validation credentials: $e');
      return false;
    }
  }

  String _generateToken() {
    // EN PROD: utiliser jwt signing
    final random = DateTime.now().millisecondsSinceEpoch;
    final hash = random.toString().codeUnits.fold<int>(0, (a, b) => a ^ b);
    return base64Url.encode(utf8.encode('token_${random}_$hash')).replaceAll('=', '');
  }

  /// POST /api/sync - Synchroniser les opérations du client
  Future<void> _handleSync(HttpRequest request) async {
    try {
      final session = await _validateSession(request);
      if (session == null) {
        return _sendError(request, 401, 'Unauthorized');
      }

      final clientIp = request.connectionInfo?.remoteAddress.address ?? 'Inconnu';

      // Enregistrer/mettre à jour le username du client
      if (_connectedClients.containsKey(clientIp)) {
        _connectedClients[clientIp]!['username'] = session.username;
      }

      final body = await _readBody(request);
      final data = jsonDecode(body) as Map<String, dynamic>;

      debugPrint('📤 Sync reçue de ${session.username} (${data['operations']?.length ?? 0} opérations)');

      // Appeler le serveur pour traiter la synchronisation
      final result = await NetworkServer.instance.handleSync(data);

      request.response.statusCode = 200;
      _sendJson(request, result);
    } catch (e) {
      debugPrint('❌ Erreur sync: $e');
      _sendError(request, 400, 'Sync error: $e');
    }
  }

  /// GET /api/changes - Récupérer les changements depuis un timestamp
  /// Query params: ?since=ISO8601_DATETIME
  Future<void> _handleChanges(HttpRequest request) async {
    try {
      final session = await _validateSession(request);
      if (session == null) {
        return _sendError(request, 401, 'Unauthorized');
      }

      final clientIp = request.connectionInfo?.remoteAddress.address ?? 'Inconnu';

      // Enregistrer/mettre à jour le username du client
      if (_connectedClients.containsKey(clientIp)) {
        _connectedClients[clientIp]!['username'] = session.username;
      }

      // Extraire le paramètre 'since'
      final sinceParam = request.uri.queryParameters['since'];
      DateTime? lastSync;

      if (sinceParam != null && sinceParam.isNotEmpty) {
        try {
          lastSync = DateTime.parse(sinceParam);
        } catch (e) {
          return _sendError(request, 400, 'Invalid since parameter. Use ISO8601 format');
        }
      }

      debugPrint('📥 Requête changements depuis ${lastSync?.toIso8601String() ?? 'début'}');

      // Récupérer les changements depuis le dernier sync
      // Pour l'instant, retourner une liste vide (implémentation future avec audit trail)
      final changes = <Map<String, dynamic>>[];

      request.response.statusCode = 200;
      _sendJson(request, {
        'success': true,
        'data': {'changes': changes, 'lastSync': DateTime.now().toIso8601String(), 'count': changes.length},
      });

      debugPrint('✅ ${changes.length} changements envoyés');
    } catch (e) {
      debugPrint('❌ Erreur changements: $e');
      _sendError(request, 400, 'Changes error: $e');
    }
  }

  void _cleanupExpiredSessions() {
    final now = DateTime.now();
    _activeSessions.removeWhere((_, session) => session.expiresAt.isBefore(now));
  }

  void _addCorsHeaders(HttpRequest request) {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    request.response.headers.add('Access-Control-Max-Age', '86400');
  }

  void _sendJson(HttpRequest request, Map<String, dynamic> data) {
    request.response.write(jsonEncode(data));
    request.response.close();
  }

  void _sendError(HttpRequest request, int statusCode, String message) {
    request.response.statusCode = statusCode;
    _sendJson(request, {'success': false, 'error': message, 'timestamp': DateTime.now().toIso8601String()});
  }
}

/// Représente une session utilisateur active
class _SessionToken {
  final String username;
  final DateTime expiresAt;
  final DateTime createdAt;

  _SessionToken({required this.username, required this.expiresAt, required this.createdAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remainingTime => expiresAt.difference(DateTime.now());
}
