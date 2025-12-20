import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/database.dart';
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

    // Ajouter les clients WebSocket
    for (final client in _clients) {
      final info = _clientsInfo[client];
      if (info != null) {
        clientsInfo.add({
          'id': index,
          'nom': info['username'] ?? 'Client WebSocket $index',
          'ip': info['ip'] ?? 'Inconnu',
          'connexion': info['connexion'] ?? DateTime.now(),
          'statut': 'Connecté',
          'type': 'WebSocket',
        });
        index++;
      }
    }

    // Ajouter les clients HTTP REST
    final httpClients = _httpServer.getConnectedClientsInfo();
    for (final httpClient in httpClients) {
      final username = httpClient['username'] as String?;
      final displayName = username != null && username.isNotEmpty
          ? username
          : 'Client REST ${httpClient['ip']}';

      clientsInfo.add({
        'id': index,
        'nom': displayName,
        'ip': httpClient['ip'] ?? 'Inconnu',
        'connexion': httpClient['derniere_activite'] ?? DateTime.now(),
        'statut': 'Actif',
        'type': 'HTTP REST',
      });
      index++;
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
    if (origin != null) {
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

    if (host != null) {
      final requestHost = request.requestedUri.host;
      if (!host.startsWith(requestHost)) {
        return false;
      }
    }

    return true;
  }

  /// Validate WebSocket token against active sessions in HTTPServer
  Future<Map<String, dynamic>?> _validateWebSocketToken(String token) async {
    try {
      if (token.isEmpty || token.length < 10) {
        return null;
      }

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

      final user = await _databaseService.database.getUserByCredentials(username, password);

      if (user == null) {
        debugPrint('❌ Authentification échouée pour: $username - Utilisateur/mot de passe invalide');
        return {'success': false, 'error': 'Utilisateur ou mot de passe invalide'};
      }

      if (!user.actif) {
        debugPrint('❌ Authentification échouée pour: $username - Utilisateur inactif');
        return {'success': false, 'error': 'Utilisateur inactif'};
      }

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

  /// Traite les opérations de synchronisation du client
  Future<Map<String, dynamic>> handleSync(Map<String, dynamic> data) async {
    try {
      final operations = data['operations'] as List?;
      if (operations == null || operations.isEmpty) {
        return {'success': true, 'synchronized': 0};
      }

      int synchronized = 0;
      final db = _databaseService.database;

      for (final op in operations) {
        try {
          final table = op['table'] as String?;
          final operationType = op['operation'] as String?;
          final opData = op['data'] as Map<String, dynamic>?;

          if (table == null || operationType == null || opData == null) continue;

          debugPrint('📥 Traitement sync: $operationType sur table $table');

          switch (table) {
            case 'clt':
              await _syncClientOperation(db, operationType, opData);
              break;
            case 'frns':
              await _syncFournisseurOperation(db, operationType, opData);
              break;
            case 'articles':
              await _syncArticleOperation(db, operationType, opData);
              break;
            case 'ventes':
              await _syncVenteOperation(db, operationType, opData);
              break;
            case 'achats':
              await _syncAchatOperation(db, operationType, opData);
              break;
            case 'detventes':
              await _syncDetVenteOperation(db, operationType, opData);
              break;
            case 'detachats':
              await _syncDetAchatOperation(db, operationType, opData);
              break;
            case 'stocks':
              await _syncStockOperation(db, operationType, opData);
              break;
            default:
              debugPrint('⚠️ Table non gérée: $table');
          }
          synchronized++;
        } catch (e) {
          debugPrint('❌ Erreur opération: $e');
        }
      }

      debugPrint('✅ Synchronisation: $synchronized/${operations.length} opérations traitées');
      return {'success': true, 'synchronized': synchronized};
    } catch (e) {
      debugPrint('❌ Erreur sync: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _syncClientOperation(AppDatabase db, String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'INSERT':
        await db.insertClient(
          CltCompanion(
            rsoc: Value(data['rsoc'] ?? ''),
            adr: Value(data['adr']),
            capital: Value(double.tryParse(data['capital']?.toString() ?? '')),
            rcs: Value(data['rcs']),
            nif: Value(data['nif']),
            stat: Value(data['stat']),
            tel: Value(data['tel']),
            port: Value(data['port']),
            email: Value(data['email']),
            site: Value(data['site']),
            fax: Value(data['fax']),
            telex: Value(data['telex']),
            soldes: Value(double.tryParse(data['soldes']?.toString() ?? '')),
            datedernop: Value(DateTime.tryParse(data['datedernop']?.toString() ?? '')),
            delai: Value(int.tryParse(data['delai']?.toString() ?? '')),
            soldesa: Value(double.tryParse(data['soldesa']?.toString() ?? '')),
            action: Value(data['action'] ?? 'A'),
            commercial: Value(data['commercial']),
            plafon: Value(double.tryParse(data['plafon']?.toString() ?? '')),
            taux: Value(double.tryParse(data['taux']?.toString() ?? '')),
            categorie: Value(data['categorie']),
            plafonbl: Value(double.tryParse(data['plafonbl']?.toString() ?? '')),
          ),
        );
        break;
      case 'UPDATE':
        await db.updateClient(
          data['rsoc'],
          CltCompanion(
            adr: Value(data['adr']),
            capital: Value(double.tryParse(data['capital']?.toString() ?? '')),
            rcs: Value(data['rcs']),
            nif: Value(data['nif']),
            stat: Value(data['stat']),
            tel: Value(data['tel']),
            port: Value(data['port']),
            email: Value(data['email']),
            site: Value(data['site']),
            fax: Value(data['fax']),
            telex: Value(data['telex']),
            soldes: Value(double.tryParse(data['soldes']?.toString() ?? '')),
            datedernop: Value(DateTime.tryParse(data['datedernop']?.toString() ?? '')),
            delai: Value(int.tryParse(data['delai']?.toString() ?? '')),
            soldesa: Value(double.tryParse(data['soldesa']?.toString() ?? '')),
            action: Value(data['action'] ?? 'A'),
            commercial: Value(data['commercial']),
            plafon: Value(double.tryParse(data['plafon']?.toString() ?? '')),
            taux: Value(double.tryParse(data['taux']?.toString() ?? '')),
            categorie: Value(data['categorie']),
            plafonbl: Value(double.tryParse(data['plafonbl']?.toString() ?? '')),
          ),
        );
        break;
      case 'DELETE':
        await db.deleteClient(data['rsoc']);
        break;
    }
  }

  Future<void> _syncFournisseurOperation(AppDatabase db, String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'INSERT':
        await db.insertFournisseur(
          FrnsCompanion(
            rsoc: Value(data['rsoc'] ?? ''),
            adr: Value(data['adr']),
            capital: Value(double.tryParse(data['capital']?.toString() ?? '')),
            rcs: Value(data['rcs']),
            nif: Value(data['nif']),
            stat: Value(data['stat']),
            tel: Value(data['tel']),
            port: Value(data['port']),
            email: Value(data['email']),
            site: Value(data['site']),
            fax: Value(data['fax']),
            telex: Value(data['telex']),
            soldes: Value(double.tryParse(data['soldes']?.toString() ?? '')),
            datedernop: Value(DateTime.tryParse(data['datedernop']?.toString() ?? '')),
            delai: Value(int.tryParse(data['delai']?.toString() ?? '')),
            soldesa: Value(double.tryParse(data['soldesa']?.toString() ?? '')),
            action: Value(data['action'] ?? 'A'),
          ),
        );
        break;
      case 'UPDATE':
        await db.updateFournisseur(
          data['rsoc'],
          FrnsCompanion(
            adr: Value(data['adr']),
            capital: Value(double.tryParse(data['capital']?.toString() ?? '')),
            rcs: Value(data['rcs']),
            nif: Value(data['nif']),
            stat: Value(data['stat']),
            tel: Value(data['tel']),
            port: Value(data['port']),
            email: Value(data['email']),
            site: Value(data['site']),
            fax: Value(data['fax']),
            telex: Value(data['telex']),
            soldes: Value(double.tryParse(data['soldes']?.toString() ?? '')),
            datedernop: Value(DateTime.tryParse(data['datedernop']?.toString() ?? '')),
            delai: Value(int.tryParse(data['delai']?.toString() ?? '')),
            soldesa: Value(double.tryParse(data['soldesa']?.toString() ?? '')),
            action: Value(data['action'] ?? 'A'),
          ),
        );
        break;
      case 'DELETE':
        await db.deleteFournisseur(data['rsoc']);
        break;
    }
  }

  Future<void> _syncArticleOperation(AppDatabase db, String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'INSERT':
        await db.insertArticle(
          ArticlesCompanion(
            designation: Value(data['designation'] ?? ''),
            u1: Value(data['u1']),
            u2: Value(data['u2']),
            tu2u1: Value(double.tryParse(data['tu2u1']?.toString() ?? '')),
            u3: Value(data['u3']),
            tu3u2: Value(double.tryParse(data['tu3u2']?.toString() ?? '')),
            pvu1: Value(double.tryParse(data['pvu1']?.toString() ?? '')),
            pvu2: Value(double.tryParse(data['pvu2']?.toString() ?? '')),
            pvu3: Value(double.tryParse(data['pvu3']?.toString() ?? '')),
            stocksu1: Value(double.tryParse(data['stocksu1']?.toString() ?? '')),
            stocksu2: Value(double.tryParse(data['stocksu2']?.toString() ?? '')),
            stocksu3: Value(double.tryParse(data['stocksu3']?.toString() ?? '')),
            sec: Value(data['sec']),
            usec: Value(double.tryParse(data['usec']?.toString() ?? '')),
            cmup: Value(double.tryParse(data['cmup']?.toString() ?? '')),
            dep: Value(data['dep']),
            action: Value(data['action']),
            categorie: Value(data['categorie']),
            classification: Value(data['classification']),
            emb: Value(data['emb']),
          ),
        );
        break;
      case 'UPDATE':
        await db.customUpdate(
          'UPDATE articles SET u1 = ?, u2 = ?, tu2u1 = ?, u3 = ?, tu3u2 = ?, pvu1 = ?, pvu2 = ?, pvu3 = ?, stocksu1 = ?, stocksu2 = ?, stocksu3 = ?, sec = ?, usec = ?, cmup = ?, dep = ?, action = ?, categorie = ?, classification = ?, emb = ? WHERE designation = ?',
          variables: [
            Variable(data['u1']),
            Variable(data['u2']),
            Variable(double.tryParse(data['tu2u1']?.toString() ?? '')),
            Variable(data['u3']),
            Variable(double.tryParse(data['tu3u2']?.toString() ?? '')),
            Variable(double.tryParse(data['pvu1']?.toString() ?? '')),
            Variable(double.tryParse(data['pvu2']?.toString() ?? '')),
            Variable(double.tryParse(data['pvu3']?.toString() ?? '')),
            Variable(double.tryParse(data['stocksu1']?.toString() ?? '')),
            Variable(double.tryParse(data['stocksu2']?.toString() ?? '')),
            Variable(double.tryParse(data['stocksu3']?.toString() ?? '')),
            Variable(data['sec']),
            Variable(double.tryParse(data['usec']?.toString() ?? '')),
            Variable(double.tryParse(data['cmup']?.toString() ?? '')),
            Variable(data['dep']),
            Variable(data['action']),
            Variable(data['categorie']),
            Variable(data['classification']),
            Variable(data['emb']),
            Variable(data['designation']),
          ],
        );
        break;
      case 'DELETE':
        await db.deleteArticle(data['designation']);
        break;
    }
  }

  Future<void> _syncVenteOperation(AppDatabase db, String operation, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'INSERT':
          await db
              .into(db.ventes)
              .insert(
                VentesCompanion(
                  numventes: Value(data['numventes']),
                  nfact: Value(data['nfact']),
                  daty: Value(DateTime.tryParse(data['daty']?.toString() ?? '')),
                  clt: Value(data['clt']),
                  modepai: Value(data['modepai']),
                  echeance: Value(DateTime.tryParse(data['echeance']?.toString() ?? '')),
                  totalttc: Value(double.tryParse(data['totalttc']?.toString() ?? '')),
                  contre: Value(data['contre']),
                  avance: Value(double.tryParse(data['avance']?.toString() ?? '')),
                  bq: Value(data['bq']),
                  regl: Value(double.tryParse(data['regl']?.toString() ?? '')),
                  datrcol: Value(DateTime.tryParse(data['datrcol']?.toString() ?? '')),
                  mregl: Value(data['mregl']),
                  commerc: Value(data['commerc']),
                  remise: Value(double.tryParse(data['remise']?.toString() ?? '')),
                  verification: Value(data['verification'] ?? 'JOURNAL'),
                  type: Value(data['type']),
                  as: Value(data['as']),
                  emb: Value(data['emb']),
                  transp: Value(data['transp']),
                  heure: Value(data['heure']),
                  poste: Value(data['poste']),
                ),
              );
          break;
        case 'UPDATE':
          if (data['numventes'] != null) {
            await db.customUpdate(
              'UPDATE ventes SET nfact = ?, daty = ?, modepai = ?, echeance = ?, totalttc = ?, contre = ?, avance = ?, bq = ?, regl = ?, datrcol = ?, mregl = ?, commerc = ?, remise = ?, verification = ?, type = ?, as = ?, emb = ?, transp = ?, heure = ?, poste = ? WHERE numventes = ?',
              variables: [
                Variable(data['nfact']),
                Variable(DateTime.tryParse(data['daty']?.toString() ?? '')),
                Variable(data['modepai']),
                Variable(DateTime.tryParse(data['echeance']?.toString() ?? '')),
                Variable(double.tryParse(data['totalttc']?.toString() ?? '')),
                Variable(data['contre']),
                Variable(double.tryParse(data['avance']?.toString() ?? '')),
                Variable(data['bq']),
                Variable(double.tryParse(data['regl']?.toString() ?? '')),
                Variable(DateTime.tryParse(data['datrcol']?.toString() ?? '')),
                Variable(data['mregl']),
                Variable(data['commerc']),
                Variable(double.tryParse(data['remise']?.toString() ?? '')),
                Variable(data['verification']),
                Variable(data['type']),
                Variable(data['as']),
                Variable(data['emb']),
                Variable(data['transp']),
                Variable(data['heure']),
                Variable(data['poste']),
                Variable(data['numventes']),
              ],
            );
          }
          break;
        case 'DELETE':
          if (data['numventes'] != null) {
            await db.customUpdate(
              'DELETE FROM ventes WHERE numventes = ?',
              variables: [Variable(data['numventes'])],
            );
          }
          break;
      }
    } catch (e, st) {
      debugPrint('❌ Erreur sync vente: $e\n$st');
      rethrow;
    }
  }

  Future<void> _syncAchatOperation(AppDatabase db, String operation, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'INSERT':
          await db
              .into(db.achats)
              .insert(
                AchatsCompanion(
                  numachats: Value(data['numachats']),
                  nfact: Value(data['nfact']),
                  daty: Value(DateTime.tryParse(data['daty']?.toString() ?? '')),
                  frns: Value(data['frns']),
                  modepai: Value(data['modepai']),
                  echeance: Value(DateTime.tryParse(data['echeance']?.toString() ?? '')),
                  totalttc: Value(double.tryParse(data['totalttc']?.toString() ?? '')),
                  contre: Value(data['contre']),
                  bq: Value(data['bq']),
                  regl: Value(double.tryParse(data['regl']?.toString() ?? '')),
                  datregl: Value(DateTime.tryParse(data['datregl']?.toString() ?? '')),
                  mregl: Value(data['mregl']),
                  verification: Value(data['verification'] ?? 'JOURNAL'),
                  type: Value(data['type']),
                  as: Value(data['as']),
                  emb: Value(data['emb']),
                  transp: Value(data['transp']),
                ),
              );
          break;
        case 'UPDATE':
          if (data['numachats'] != null) {
            await db.customUpdate(
              'UPDATE achats SET nfact = ?, daty = ?, frns = ?, modepai = ?, echeance = ?, totalttc = ?, contre = ?, bq = ?, regl = ?, datregl = ?, mregl = ?, verification = ?, type = ?, as = ?, emb = ?, transp = ? WHERE numachats = ?',
              variables: [
                Variable(data['nfact']),
                Variable(DateTime.tryParse(data['daty']?.toString() ?? '')),
                Variable(data['frns']),
                Variable(data['modepai']),
                Variable(DateTime.tryParse(data['echeance']?.toString() ?? '')),
                Variable(double.tryParse(data['totalttc']?.toString() ?? '')),
                Variable(data['contre']),
                Variable(data['bq']),
                Variable(double.tryParse(data['regl']?.toString() ?? '')),
                Variable(DateTime.tryParse(data['datregl']?.toString() ?? '')),
                Variable(data['mregl']),
                Variable(data['verification']),
                Variable(data['type']),
                Variable(data['as']),
                Variable(data['emb']),
                Variable(data['transp']),
                Variable(data['numachats']),
              ],
            );
          }
          break;
        case 'DELETE':
          if (data['numachats'] != null) {
            await db.customUpdate(
              'DELETE FROM achats WHERE numachats = ?',
              variables: [Variable(data['numachats'])],
            );
          }
          break;
      }
    } catch (e, st) {
      debugPrint('❌ Erreur sync achat: $e\n$st');
      rethrow;
    }
  }

  Future<void> _syncDetVenteOperation(AppDatabase db, String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'INSERT':
        await db
            .into(db.detventes)
            .insert(
              DetventesCompanion(
                numventes: Value(data['numventes']),
                designation: Value(data['designation']),
                unites: Value(data['unites']),
                depots: Value(data['depots']),
                q: Value(double.tryParse(data['q']?.toString() ?? '')),
                pu: Value(double.tryParse(data['pu']?.toString() ?? '')),
                daty: Value(DateTime.tryParse(data['daty']?.toString() ?? '')),
                emb: Value(data['emb']),
                transp: Value(data['transp']),
                qe: Value(double.tryParse(data['qe']?.toString() ?? '')),
                diffPrix: Value(double.tryParse(data['diffPrix']?.toString() ?? '')),
              ),
            );
        break;
      case 'UPDATE':
        if (data['numventes'] != null && data['designation'] != null) {
          await db.customUpdate(
            'UPDATE detventes SET unites = ?, depots = ?, q = ?, pu = ?, daty = ?, emb = ?, transp = ?, qe = ?, diffPrix = ? WHERE numventes = ? AND designation = ?',
            variables: [
              Variable(data['unites']),
              Variable(data['depots']),
              Variable(double.tryParse(data['q']?.toString() ?? '')),
              Variable(double.tryParse(data['pu']?.toString() ?? '')),
              Variable(DateTime.tryParse(data['daty']?.toString() ?? '')),
              Variable(data['emb']),
              Variable(data['transp']),
              Variable(double.tryParse(data['qe']?.toString() ?? '')),
              Variable(double.tryParse(data['diffPrix']?.toString() ?? '')),
              Variable(data['numventes']),
              Variable(data['designation']),
            ],
          );
        }
        break;
      case 'DELETE':
        if (data['numventes'] != null && data['designation'] != null) {
          await db.customUpdate(
            'DELETE FROM detventes WHERE numventes = ? AND designation = ?',
            variables: [Variable(data['numventes']), Variable(data['designation'])],
          );
        }
        break;
    }
  }

  Future<void> _syncDetAchatOperation(AppDatabase db, String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'INSERT':
        await db
            .into(db.detachats)
            .insert(
              DetachatsCompanion(
                numachats: Value(data['numachats']),
                designation: Value(data['designation']),
                unites: Value(data['unites']),
                depots: Value(data['depots']),
                q: Value(double.tryParse(data['q']?.toString() ?? '')),
                pu: Value(double.tryParse(data['pu']?.toString() ?? '')),
                daty: Value(DateTime.tryParse(data['daty']?.toString() ?? '')),
                emb: Value(data['emb']),
                transp: Value(data['transp']),
                qe: Value(double.tryParse(data['qe']?.toString() ?? '')),
              ),
            );
        break;
      case 'UPDATE':
        if (data['numachats'] != null && data['designation'] != null) {
          await db.customUpdate(
            'UPDATE detachats SET unites = ?, depots = ?, q = ?, pu = ?, daty = ?, emb = ?, transp = ?, qe = ? WHERE numachats = ? AND designation = ?',
            variables: [
              Variable(data['unites']),
              Variable(data['depots']),
              Variable(double.tryParse(data['q']?.toString() ?? '')),
              Variable(double.tryParse(data['pu']?.toString() ?? '')),
              Variable(DateTime.tryParse(data['daty']?.toString() ?? '')),
              Variable(data['emb']),
              Variable(data['transp']),
              Variable(double.tryParse(data['qe']?.toString() ?? '')),
              Variable(data['numachats']),
              Variable(data['designation']),
            ],
          );
        }
        break;
      case 'DELETE':
        if (data['numachats'] != null && data['designation'] != null) {
          await db.customUpdate(
            'DELETE FROM detachats WHERE numachats = ? AND designation = ?',
            variables: [Variable(data['numachats']), Variable(data['designation'])],
          );
        }
        break;
    }
  }

  Future<void> _syncStockOperation(AppDatabase db, String operation, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'INSERT':
          await db
              .into(db.stocks)
              .insert(
                StocksCompanion(
                  ref: Value(data['ref'] ?? ''),
                  daty: Value(DateTime.tryParse(data['daty']?.toString() ?? '')),
                  lib: Value(data['lib']),
                  numachats: Value(data['numachats']),
                  nfact: Value(data['nfact']),
                  refart: Value(data['refart']),
                  qe: Value(double.tryParse(data['qe']?.toString() ?? '')),
                  pus: Value(double.tryParse(data['pus']?.toString() ?? '')),
                  entres: Value(double.tryParse(data['entres']?.toString() ?? '')),
                  qs: Value(double.tryParse(data['qs']?.toString() ?? '')),
                  pue: Value(double.tryParse(data['pue']?.toString() ?? '')),
                  sortie: Value(double.tryParse(data['sortie']?.toString() ?? '')),
                  stocksu1: Value(double.tryParse(data['stocksu1']?.toString() ?? '')),
                  numventes: Value(data['numventes']),
                  ue: Value(data['ue']),
                  us: Value(data['us']),
                  stocksu2: Value(double.tryParse(data['stocksu2']?.toString() ?? '')),
                  stocksu3: Value(double.tryParse(data['stocksu3']?.toString() ?? '')),
                  depots: Value(data['depots']),
                  cmup: Value(double.tryParse(data['cmup']?.toString() ?? '')),
                  clt: Value(data['clt']),
                  frns: Value(data['frns']),
                  verification: Value(data['verification']),
                  stkdep: Value(double.tryParse(data['stkdep']?.toString() ?? '')),
                  marq: Value(data['marq']),
                ),
              );
          break;
        case 'UPDATE':
          if (data['ref'] != null) {
            await db.customUpdate(
              'UPDATE stocks SET daty = ?, lib = ?, numachats = ?, nfact = ?, refart = ?, qe = ?, pus = ?, entres = ?, qs = ?, pue = ?, sortie = ?, stocksu1 = ?, numventes = ?, ue = ?, us = ?, stocksu2 = ?, stocksu3 = ?, depots = ?, cmup = ?, clt = ?, frns = ?, verification = ?, stkdep = ?, marq = ? WHERE ref = ?',
              variables: [
                Variable(DateTime.tryParse(data['daty']?.toString() ?? '')),
                Variable(data['lib']),
                Variable(data['numachats']),
                Variable(data['nfact']),
                Variable(data['refart']),
                Variable(double.tryParse(data['qe']?.toString() ?? '')),
                Variable(double.tryParse(data['pus']?.toString() ?? '')),
                Variable(double.tryParse(data['entres']?.toString() ?? '')),
                Variable(double.tryParse(data['qs']?.toString() ?? '')),
                Variable(double.tryParse(data['pue']?.toString() ?? '')),
                Variable(double.tryParse(data['sortie']?.toString() ?? '')),
                Variable(double.tryParse(data['stocksu1']?.toString() ?? '')),
                Variable(data['numventes']),
                Variable(data['ue']),
                Variable(data['us']),
                Variable(double.tryParse(data['stocksu2']?.toString() ?? '')),
                Variable(double.tryParse(data['stocksu3']?.toString() ?? '')),
                Variable(data['depots']),
                Variable(double.tryParse(data['cmup']?.toString() ?? '')),
                Variable(data['clt']),
                Variable(data['frns']),
                Variable(data['verification']),
                Variable(double.tryParse(data['stkdep']?.toString() ?? '')),
                Variable(data['marq']),
                Variable(data['ref']),
              ],
            );
          }
          break;
        case 'DELETE':
          if (data['ref'] != null) {
            await db.customUpdate('DELETE FROM stocks WHERE ref = ?', variables: [Variable(data['ref'])]);
          }
          break;
      }
    } catch (e, st) {
      debugPrint('❌ Erreur sync stock: $e\n$st');
      rethrow;
    }
  }
}
