import 'dart:convert';
import 'dart:io';

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
}
