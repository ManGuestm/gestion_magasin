import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class NetworkClient {
  static NetworkClient? _instance;
  WebSocket? _socket;
  String? _serverUrl;
  bool _isConnected = false;
  String? _authToken;
  String? _currentUsername;
  final Map<String, dynamic> _cache = {};
  final Set<Function(Map<String, dynamic>)> _changeListeners = {};

  static NetworkClient get instance => _instance ??= NetworkClient._();
  NetworkClient._();

  bool get isConnected => _isConnected;

  Future<bool> testConnection(String serverIp, int port) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      final request = await client.get(serverIp, port, '/api/health');
      final response = await request.close();

      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> connect(String serverIp, int port, [String? username, String? password]) async {
    try {
      _serverUrl = 'http://$serverIp:$port';
      debugPrint('🌐 Tentative de connexion CLIENT à $_serverUrl');

      // Test connexion HTTP avec timeout
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.get(serverIp, port, '/api/health');
      final response = await request.close();

      if (response.statusCode != 200) {
        client.close();
        throw Exception('Serveur non accessible (HTTP ${response.statusCode})');
      }

      debugPrint('✅ Test HTTP réussi');

      // Authentification si credentials fournis
      if (username != null && password != null) {
        debugPrint('🔐 Authentification CLIENT avec utilisateur: $username');
        final authResult = await authenticate(username, password);
        if (authResult == null) {
          throw Exception('❌ Authentification échouée - Utilisateur/mot de passe invalide');
        }
        _currentUsername = username;
        _authToken = authResult['token'] ?? authResult['id']?.toString();
        debugPrint('✅ Authentification réussie - Token obtenu');
      }

      // Connexion WebSocket pour temps réel
      _socket = await WebSocket.connect('ws://$serverIp:$port/ws').timeout(const Duration(seconds: 10));
      _isConnected = true;

      _socket!.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'data_change') {
              _handleDataChange(data['change']);
            }
          } catch (e) {
            debugPrint('Erreur message WebSocket: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          debugPrint('Connexion WebSocket fermée');
        },
        onError: (error) {
          _isConnected = false;
          debugPrint('Erreur WebSocket: $error');
        },
      );

      client.close();
      debugPrint('✅ CLIENT connecté et authentifié au serveur $_serverUrl');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur connexion CLIENT: $e');
      _isConnected = false;
      _authToken = null;
      _currentUsername = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _isConnected = false;
    _cache.clear();
    _changeListeners.clear();
    debugPrint('Déconnecté du serveur');
  }

  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    if (!_isConnected) throw Exception('Non connecté au serveur');

    // Vérifier cache pour SELECT
    if (sql.trim().toUpperCase().startsWith('SELECT')) {
      final cacheKey = '$sql${params?.join(',')}';
      if (_cache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(_cache[cacheKey]);
      }
    }

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$_serverUrl/api/query'));
      request.headers.contentType = ContentType.json;

      // Ajouter token d'authentification si présent
      if (_authToken != null) {
        request.headers.add('Authorization', 'Bearer $_authToken');
      }

      final body = jsonEncode({'type': 'select', 'query': sql, 'params': params});

      request.write(body);
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      final data = jsonDecode(responseBody);

      client.close();

      if (data['success'] == true) {
        final result = List<Map<String, dynamic>>.from(data['data']);

        // Cache pour SELECT
        if (sql.trim().toUpperCase().startsWith('SELECT')) {
          final cacheKey = '$sql${params?.join(',')}';
          _cache[cacheKey] = result;
        }

        return result;
      } else {
        throw Exception(data['error'] ?? 'Erreur requête');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<void> execute(String sql, [List<dynamic>? params]) async {
    if (!_isConnected) throw Exception('Non connecté au serveur');

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$_serverUrl/api/query'));
      request.headers.contentType = ContentType.json;

      // Ajouter token d'authentification si présent
      if (_authToken != null) {
        request.headers.add('Authorization', 'Bearer $_authToken');
      }

      String type = 'update';
      if (sql.trim().toUpperCase().startsWith('INSERT')) {
        type = 'insert';
      } else if (sql.trim().toUpperCase().startsWith('DELETE')) {
        type = 'delete';
      }

      final body = jsonEncode({'type': type, 'query': sql, 'params': params});

      request.write(body);
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      final data = jsonDecode(responseBody);

      client.close();

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Erreur exécution');
      }

      // Invalider cache
      _invalidateCache();
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<void> transaction(List<Map<String, dynamic>> queries) async {
    if (!_isConnected) throw Exception('Non connecté au serveur');

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$_serverUrl/api/query'));
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({'type': 'transaction', 'queries': queries});

      request.write(body);
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      final data = jsonDecode(responseBody);

      client.close();

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Erreur transaction');
      }

      _invalidateCache();
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  void addChangeListener(Function(Map<String, dynamic>) listener) {
    _changeListeners.add(listener);
  }

  void removeChangeListener(Function(Map<String, dynamic>) listener) {
    _changeListeners.remove(listener);
  }

  void _handleDataChange(Map<String, dynamic> change) {
    _invalidateCache();
    for (final listener in _changeListeners) {
      try {
        listener(change);
      } catch (e) {
        debugPrint('Erreur listener: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> authenticate(String username, String password) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$_serverUrl/api/auth'));
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({'username': username, 'password': password});

      debugPrint('🔐 Envoi authentification au serveur...');
      request.write(body);
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      final data = jsonDecode(responseBody);

      client.close();

      if (data['success'] == true && data['data'] != null) {
        debugPrint('✅ Authentification serveur réussie pour: $username');
        return data['data'];
      } else {
        debugPrint('❌ Authentification serveur échouée: ${data['error']}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur authentification réseau: $e');
      rethrow;
    }
  }

  String? get authToken => _authToken;
  String? get currentUsername => _currentUsername;

  void _invalidateCache() {
    _cache.clear();
  }
}
