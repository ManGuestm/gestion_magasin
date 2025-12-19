import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/database_service.dart';
import 'audit_service.dart';
import 'network/http_server.dart';

class NetworkServer {
  static NetworkServer? _instance;
  HttpServer? _server;
  final DatabaseService _databaseService = DatabaseService();
  final HTTPServer _httpServer = HTTPServer();
  final AuditService _auditService = AuditService();
  final Set<WebSocket> _clients = {};
  final Map<WebSocket, Map<String, dynamic>> _clientsInfo = {};
  bool _isRunning = false;

  static NetworkServer get instance => _instance ??= NetworkServer._();
  NetworkServer._();

  bool get isRunning => _isRunning;
  int get connectedClientsCount => _clients.length;

  List<Map<String, dynamic>> getConnectedClientsInfo() {
    final clientsInfo = <Map<String, dynamic>>[];
    int index = 1;

    for (final client in _clients) {
      final info = _clientsInfo[client];
      if (info != null) {
        clientsInfo.add({
          'id': index,
          'nom': info['nom'] ?? 'Client $index',
          'ip': info['ip'] ?? 'Inconnu',
          'connexion': info['connexion'] ?? DateTime.now(),
          'statut': 'Connecté',
        });
        index++;
      }
    }

    return clientsInfo;
  }

  Future<bool> start({int port = 8080}) async {
    try {
      // S'assurer que la base est initialisée en mode LOCAL (serveur)
      await _databaseService.initializeLocal();

      // Démarrer le serveur HTTP REST
      final httpStarted = await _httpServer.start(port: port);
      if (!httpStarted) {
        throw Exception('Failed to start HTTP server');
      }

      _isRunning = true;
      debugPrint('✅ Serveur démarré sur port $port');

      return true;
    } catch (e) {
      debugPrint('❌ Erreur démarrage serveur: $e');
      _isRunning = false;
      return false;
    }
  }

  Future<void> stop() async {
    await _httpServer.stop();
    await _server?.close();
    _server = null;
    _isRunning = false;
    _clients.clear();
    _clientsInfo.clear();
    debugPrint('🛑 Serveur arrêté');
  }

  Future<void> handleRequest(HttpRequest request) async {
    try {
      // CORS headers
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      final path = request.uri.path;
      final method = request.method;

      Map<String, dynamic> response;

      switch (path) {
        case '/api/health':
          response = {'status': 'ok', 'timestamp': DateTime.now().toIso8601String()};
          break;

        case '/api/auth':
          if (method == 'POST') {
            final body = await utf8.decoder.bind(request).join();
            final data = jsonDecode(body);
            response = await authenticateUser(data);
          } else {
            response = {'error': 'Method not allowed'};
            request.response.statusCode = 405;
          }
          break;

        case '/api/query':
          if (method == 'POST') {
            // Vérifier authentification via Bearer token
            final authHeader = request.headers.value('Authorization');
            if (authHeader == null || !authHeader.startsWith('Bearer ')) {
              debugPrint('❌ Requête /api/query sans token d\'authentification');
              response = {'success': false, 'error': 'Authentification requise'};
              request.response.statusCode = 401;
            } else {
              final token = authHeader.substring(7);
              debugPrint('🔐 Requête authentifiée avec token: ${token.substring(0, 10)}...');
              final body = await utf8.decoder.bind(request).join();
              final data = jsonDecode(body);
              response = await executeQuery(data);
            }
          } else {
            response = {'error': 'Method not allowed'};
            request.response.statusCode = 405;
          }
          break;

        case '/ws':
          await handleWebSocket(request);
          return;

        default:
          response = {'error': 'Not found'};
          request.response.statusCode = 404;
      }

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    } catch (e) {
      debugPrint('Erreur requête: $e');
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> handleWebSocket(HttpRequest request) async {
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'Inconnu';

    // Step 1: CSRF Mitigation - Validate Origin/Host headers
    final origin = request.headers.value('Origin');
    final host = request.headers.value('Host');
    if (!_validateOriginHost(request, origin, host)) {
      debugPrint('🚫 CSRF Attack detected from $clientIp - Invalid Origin/Host');
      await _auditService.log(
        userId: 'unknown',
        userName: 'unknown',
        action: AuditAction.error,
        module: 'WebSocket',
        details: 'Tentative de connexion WebSocket avec Origin/Host invalide',
        ipAddress: clientIp,
      );
      request.response.statusCode = 403;
      request.response.write(jsonEncode({'error': 'Forbidden - Invalid Origin'}));
      await request.response.close();
      return;
    }

    // Step 2: Extract and validate authentication token from Authorization header
    final authHeader = request.headers.value('Authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      debugPrint('🚫 WebSocket connection rejected from $clientIp - Missing/Invalid Authorization header');
      await _auditService.log(
        userId: 'unknown',
        userName: 'unknown',
        action: AuditAction.error,
        module: 'WebSocket',
        details: 'Tentative de connexion WebSocket sans token d\'authentification valide',
        ipAddress: clientIp,
      );
      request.response.statusCode = 401;
      request.response.write(jsonEncode({'error': 'Unauthorized - Missing auth token'}));
      await request.response.close();
      return;
    }

    // Step 3: Validate session token
    final token = authHeader.substring(7);
    final sessionValid = await _validateWebSocketToken(token);

    if (sessionValid == null) {
      debugPrint('🚫 WebSocket connection rejected from $clientIp - Invalid/Expired token');
      await _auditService.log(
        userId: 'unknown',
        userName: 'unknown',
        action: AuditAction.error,
        module: 'WebSocket',
        details: 'Tentative de connexion WebSocket avec token expiré ou invalide',
        ipAddress: clientIp,
      );
      request.response.statusCode = 401;
      request.response.write(jsonEncode({'error': 'Unauthorized - Token expired or invalid'}));
      await request.response.close();
      return;
    }

    // Step 4: All validation passed - Upgrade WebSocket connection
    try {
      final socket = await WebSocketTransformer.upgrade(request);

      _clients.add(socket);
      _clientsInfo[socket] = {
        'ip': clientIp,
        'connexion': DateTime.now(),
        'nom': 'Client ${_clients.length}',
        'username': sessionValid['username'],
        'token': token,
      };

      debugPrint(
        '✅ Client WebSocket authentifié connecté depuis $clientIp - User: ${sessionValid['username']} (${_clients.length} clients)',
      );

      await _auditService.log(
        userId: sessionValid['username'],
        userName: sessionValid['username'],
        action: AuditAction.login,
        module: 'WebSocket',
        details: 'Connexion WebSocket établie avec succès',
        ipAddress: clientIp,
      );

      socket.listen(
        (message) async {
          try {
            final data = jsonDecode(message);
            final response = await executeQuery(data);
            socket.add(jsonEncode(response));
          } catch (e) {
            socket.add(jsonEncode({'error': e.toString()}));
          }
        },
        onDone: () {
          final username = _clientsInfo[socket]?['username'] ?? 'unknown';
          _clients.remove(socket);
          _clientsInfo.remove(socket);
          debugPrint('✅ Client WebSocket déconnecté - User: $username (${_clients.length} clients)');
        },
        onError: (error) {
          final username = _clientsInfo[socket]?['username'] ?? 'unknown';
          _clients.remove(socket);
          _clientsInfo.remove(socket);
          debugPrint('❌ Erreur WebSocket: $error - User: $username');
        },
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'upgrade WebSocket: $e');
      await _auditService.log(
        userId: sessionValid['username'],
        userName: sessionValid['username'],
        action: AuditAction.error,
        module: 'WebSocket',
        details: 'Erreur lors de l\'upgrade de la connexion WebSocket: $e',
        ipAddress: clientIp,
      );
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'error': 'Internal server error'}));
      await request.response.close();
    }
  }

  /// Validate Origin and Host headers to prevent CSRF attacks
  bool _validateOriginHost(HttpRequest request, String? origin, String? host) {
    // If Origin is provided, validate it (common in browsers)
    if (origin != null) {
      // In production, compare against allowed origins
      // For now, we allow same-origin requests
      final requestHost = request.requestedUri.host;
      try {
        final originUri = Uri.parse(origin);
        if (originUri.host != requestHost) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }

    // Host header should match request
    if (host != null) {
      final requestHost = request.requestedUri.host;
      if (!host.startsWith(requestHost)) {
        return false;
      }
    }

    return true;
  }

  /// Validate WebSocket token against active sessions in HTTPServer
  /// Returns session data if valid, null otherwise
  Future<Map<String, dynamic>?> _validateWebSocketToken(String token) async {
    try {
      if (token.isEmpty || token.length < 10) {
        return null;
      }

      // Use HTTPServer's public validation method for consistency
      final sessionData = await _httpServer.validateWebSocketToken(token);
      return sessionData;
    } catch (e) {
      debugPrint('Erreur validation token WebSocket: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> authenticateUser(Map<String, dynamic> data) async {
    try {
      final username = data['username'] as String?;
      final password = data['password'] as String?;

      if (username == null || password == null || username.isEmpty || password.isEmpty) {
        debugPrint('❌ Authentification échouée: credentials manquants');
        return {'success': false, 'error': 'Username et password requis'};
      }

      debugPrint('🔐 Authentification du CLIENT: $username');

      // Vérifier les credentials contre la table users du serveur
      final user = await _databaseService.database.getUserByCredentials(username, password);

      if (user == null) {
        debugPrint('❌ Authentification échouée pour: $username - Utilisateur/mot de passe invalide');
        return {'success': false, 'error': 'Utilisateur ou mot de passe invalide'};
      }

      if (!user.actif) {
        debugPrint('❌ Authentification échouée pour: $username - Utilisateur inactif');
        return {'success': false, 'error': 'Utilisateur inactif'};
      }

      // Générer token (simple: UUID-based)
      final token = '${user.id}_${DateTime.now().millisecondsSinceEpoch}_${username.hashCode}';

      debugPrint('✅ Authentification réussie pour CLIENT: $username');

      return {
        'success': true,
        'data': {
          'id': user.id,
          'nom': user.nom,
          'username': user.username,
          'role': user.role,
          'actif': user.actif ? 1 : 0,
          'token': token,
          'dateCreation': user.dateCreation.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('❌ Erreur authentification: $e');
      return {'success': false, 'error': 'Erreur serveur: $e'};
    }
  }

  Future<Map<String, dynamic>> executeQuery(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String;
      final query = data['query'] as String?;
      final params = data['params'] as List?;

      // S'assurer que le serveur n'est PAS en mode réseau
      if (_databaseService.isNetworkMode) {
        return {'error': 'Le serveur ne peut pas être en mode client réseau'};
      }

      switch (type) {
        case 'select':
          final result = await _databaseService.database
              .customSelect(query!, variables: params?.map((p) => Variable(p)).toList() ?? [])
              .get();
          return {'success': true, 'data': result.map((row) => row.data).toList()};

        case 'insert':
        case 'update':
        case 'delete':
          await _databaseService.database.customStatement(
            query!,
            params?.map((p) => Variable(p)).toList() ?? [],
          );
          broadcastChange({'type': type, 'query': query, 'params': params});
          return {'success': true};

        case 'transaction':
          final queries = data['queries'] as List;
          await _databaseService.database.transaction(() async {
            for (final q in queries) {
              await _databaseService.database.customStatement(
                q['query'],
                q['params']?.map((p) => Variable(p)).toList() ?? [],
              );
            }
          });
          broadcastChange({'type': 'transaction', 'queries': queries});
          return {'success': true};

        default:
          return {'error': 'Type de requête non supporté: $type'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  void broadcastChange(Map<String, dynamic> change) {
    final message = jsonEncode({
      'type': 'data_change',
      'change': change,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _clients.removeWhere((client) {
      try {
        client.add(message);
        return false;
      } catch (e) {
        return true;
      }
    });
  }
}
