import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/database_service.dart';
import 'network/http_server.dart';

class NetworkServer {
  static NetworkServer? _instance;
  HttpServer? _server;
  final DatabaseService _databaseService = DatabaseService();
  final HTTPServer _httpServer = HTTPServer();
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

        case '/api/query':
          if (method == 'POST') {
            final body = await utf8.decoder.bind(request).join();
            final data = jsonDecode(body);
            response = await executeQuery(data);
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
    final socket = await WebSocketTransformer.upgrade(request);
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'Inconnu';

    _clients.add(socket);
    _clientsInfo[socket] = {'ip': clientIp, 'connexion': DateTime.now(), 'nom': 'Client ${_clients.length}'};

    debugPrint('Client WebSocket connecté depuis $clientIp (${_clients.length} clients)');

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
        _clients.remove(socket);
        _clientsInfo.remove(socket);
        debugPrint('Client WebSocket déconnecté (${_clients.length} clients)');
      },
      onError: (error) {
        _clients.remove(socket);
        _clientsInfo.remove(socket);
        debugPrint('Erreur WebSocket: $error');
      },
    );
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

        case 'auth':
          final username = data['username'] as String;
          final password = data['password'] as String;
          final user = await _databaseService.database.getUserByCredentials(username, password);
          return {
            'success': true,
            'data': user != null
                ? [
                    {
                      'id': user.id,
                      'nom': user.nom,
                      'username': user.username,
                      'motDePasse': user.motDePasse,
                      'role': user.role,
                      'actif': user.actif ? 1 : 0,
                      'dateCreation': user.dateCreation.toIso8601String(),
                    },
                  ]
                : [],
          };

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
