import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/database_service.dart';

class NetworkServer {
  static NetworkServer? _instance;
  HttpServer? _server;
  final DatabaseService _databaseService = DatabaseService();
  final Set<WebSocket> _clients = {};
  bool _isRunning = false;

  static NetworkServer get instance => _instance ??= NetworkServer._();
  NetworkServer._();

  bool get isRunning => _isRunning;

  Future<bool> start({int port = 8080}) async {
    try {
      await _databaseService.initialize();
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;

      debugPrint('Serveur démarré sur port $port');

      _server!.listen((HttpRequest request) async {
        await _handleRequest(request);
      });

      return true;
    } catch (e) {
      debugPrint('Erreur démarrage serveur: $e');
      return false;
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _isRunning = false;
    _clients.clear();
    debugPrint('Serveur arrêté');
  }

  Future<void> _handleRequest(HttpRequest request) async {
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
            response = await _executeQuery(data);
          } else {
            response = {'error': 'Method not allowed'};
            request.response.statusCode = 405;
          }
          break;

        case '/ws':
          await _handleWebSocket(request);
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

  Future<void> _handleWebSocket(HttpRequest request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    _clients.add(socket);
    debugPrint('Client WebSocket connecté (${_clients.length} clients)');

    socket.listen(
      (message) async {
        try {
          final data = jsonDecode(message);
          final response = await _executeQuery(data);
          socket.add(jsonEncode(response));
        } catch (e) {
          socket.add(jsonEncode({'error': e.toString()}));
        }
      },
      onDone: () {
        _clients.remove(socket);
        debugPrint('Client WebSocket déconnecté (${_clients.length} clients)');
      },
      onError: (error) {
        _clients.remove(socket);
        debugPrint('Erreur WebSocket: $error');
      },
    );
  }

  Future<Map<String, dynamic>> _executeQuery(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String;
      final query = data['query'] as String?;
      final params = data['params'] as List?;

      switch (type) {
        case 'select':
          final result = await _databaseService.database.customSelect(query!, variables: params?.map((p) => Variable(p)).toList() ?? []).get();
          return {
            'success': true,
            'data': result.map((row) => row.data).toList(),
          };

        case 'insert':
        case 'update':
        case 'delete':
          await _databaseService.database.customStatement(query!, params?.map((p) => Variable(p)).toList() ?? []);
          _broadcastChange({'type': type, 'query': query, 'params': params});
          return {'success': true};

        case 'transaction':
          final queries = data['queries'] as List;
          await _databaseService.database.transaction(() async {
            for (final q in queries) {
              await _databaseService.database.customStatement(q['query'], q['params']?.map((p) => Variable(p)).toList() ?? []);
            }
          });
          _broadcastChange({'type': 'transaction', 'queries': queries});
          return {'success': true};

        default:
          return {'error': 'Type de requête non supporté: $type'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  void _broadcastChange(Map<String, dynamic> change) {
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