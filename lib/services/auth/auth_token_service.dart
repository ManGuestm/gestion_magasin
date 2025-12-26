import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audit_service.dart';

/// Token JWT authentifié
class AuthToken {
  final String token;
  final DateTime expiresAt;
  final String userId;
  final String username;

  AuthToken({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.username,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  Map<String, dynamic> toJson() => {
    'token': token,
    'expiresAt': expiresAt.toIso8601String(),
    'userId': userId,
    'username': username,
  };

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
    token: json['token'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    userId: json['userId'] as String,
    username: json['username'] as String,
  );
}

/// Service de gestion des tokens JWT
class AuthTokenService {
  static final AuthTokenService _instance = AuthTokenService._internal();
  factory AuthTokenService() => _instance;
  AuthTokenService._internal();

  AuthToken? _currentToken;
  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _restoreToken();
    _initialized = true;
  }

  /// Authentifie et obtient un token
  Future<AuthToken?> authenticate(
    String serverUrl,
    String username,
    String password,
  ) async {
    try {
      await _logToAudit('AUTH_TOKEN: Tentative authentification pour $username sur $serverUrl');
      
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$serverUrl/api/authenticate');
      await _logToAudit('AUTH_TOKEN: URI: $uri');
      
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'username': username,
        'password': password,
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      client.close();

      await _logToAudit('AUTH_TOKEN: Réponse HTTP status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        debugPrint('Auth failed: ${response.statusCode}');
        await _logToAudit('AUTH_TOKEN: ❌ Authentification échouée - Status: ${response.statusCode}, Body: $responseBody');
        return null;
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (data['success'] != true) {
        debugPrint('Auth failed: ${data['error']}');
        await _logToAudit('AUTH_TOKEN: ❌ Authentification échouée - Erreur: ${data['error']}');
        return null;
      }

      final tokenData = data['data'] as Map<String, dynamic>;
      _currentToken = AuthToken(
        token: tokenData['token'] as String,
        expiresAt: DateTime.parse(tokenData['expiresAt'] as String),
        userId: tokenData['userId'] as String,
        username: tokenData['username'] as String,
      );

      await _saveToken(_currentToken!);
      debugPrint('Authentication successful for $username');
      await _logToAudit('AUTH_TOKEN: ✅ Authentification réussie pour $username');
      return _currentToken;
    } catch (e) {
      debugPrint('Erreur authentification: $e');
      await _logToAudit('AUTH_TOKEN: ❌ Exception - Type: ${e.runtimeType}, Message: $e');
      return null;
    }
  }

  /// Rafraîchit le token
  Future<bool> refreshToken(String serverUrl) async {
    if (_currentToken == null) {
      debugPrint('No token to refresh');
      return false;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$serverUrl/api/refresh-token');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.add('Authorization', 'Bearer ${_currentToken!.token}');

      request.write('{}');
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      client.close();

      if (response.statusCode != 200) {
        await logout();
        return false;
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (data['success'] != true) {
        await logout();
        return false;
      }

      final tokenData = data['data'] as Map<String, dynamic>;
      _currentToken = AuthToken(
        token: tokenData['token'] as String,
        expiresAt: DateTime.parse(tokenData['expiresAt'] as String),
        userId: _currentToken!.userId,
        username: _currentToken!.username,
      );

      await _saveToken(_currentToken!);
      debugPrint('Token refreshed successfully');
      return true;
    } catch (e) {
      debugPrint('Erreur refresh token: $e');
      return false;
    }
  }

  AuthToken? get currentToken => _currentToken;
  bool get isAuthenticated => _currentToken?.isValid ?? false;
  String? get userId => _currentToken?.userId;
  String? get username => _currentToken?.username;

  Future<void> logout() async {
    _currentToken = null;
    await _prefs.remove('auth_token');
    debugPrint('User logged out');
  }

  Future<void> _saveToken(AuthToken token) async {
    try {
      await _prefs.setString('auth_token', jsonEncode(token.toJson()));
    } catch (e) {
      debugPrint('Erreur sauvegarde token: $e');
    }
  }

  Future<void> _restoreToken() async {
    try {
      final tokenJson = _prefs.getString('auth_token');
      if (tokenJson != null) {
        _currentToken = AuthToken.fromJson(jsonDecode(tokenJson));
        if (_currentToken!.isExpired) {
          await logout();
        } else {
          debugPrint('Token restored for ${_currentToken!.username}');
        }
      }
    } catch (e) {
      debugPrint('Erreur restauration token: $e');
      await logout();
    }
  }

  /// Helper pour logger dans audit_logs.jsonl
  Future<void> _logToAudit(String message) async {
    try {
      final auditService = AuditService();
      await auditService.log(
        userId: 'system',
        userName: 'system',
        action: AuditAction.login,
        module: 'AUTH_TOKEN_SERVICE',
        details: message,
      );
    } catch (e) {
      debugPrint('⚠️ Erreur log audit: $e');
    }
  }
}
