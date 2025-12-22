import 'dart:async';

import 'package:flutter/material.dart';

/// Données de session client
class SessionData {
  final String id;
  final String userId;
  final String username;
  final String token;
  final DateTime createdAt;
  DateTime lastActivity;
  final Map<String, dynamic> metadata;

  SessionData({
    required this.id,
    required this.userId,
    required this.username,
    required this.token,
    required this.createdAt,
    required this.lastActivity,
    required this.metadata,
  });

  Duration get duration => DateTime.now().difference(createdAt);
  bool get isExpired => DateTime.now().difference(lastActivity) > const Duration(hours: 1);

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'username': username,
    'createdAt': createdAt.toIso8601String(),
    'lastActivity': lastActivity.toIso8601String(),
    'duration': duration.toString(),
    'isExpired': isExpired,
    'metadata': metadata,
  };
}

/// Gestionnaire de sessions client avancé
class SessionManager {
  static final SessionManager _instance = SessionManager._();
  factory SessionManager() => _instance;
  SessionManager._();

  final Map<String, SessionData> _activeSessions = {};
  final Map<String, List<SessionData>> _userSessions = {};
  Timer? _sessionCleanupTimer;
  static const Duration _sessionTimeout = Duration(hours: 1);
  static const Duration _cleanupInterval = Duration(minutes: 5);

  void startCleanupTimer() {
    _sessionCleanupTimer = Timer.periodic(_cleanupInterval, (_) => _cleanupExpiredSessions());
    debugPrint('⏱️  Session cleanup timer démarré');
  }

  Future<String> createSession(String userId, String username, String token) async {
    final sessionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

    final session = SessionData(
      id: sessionId,
      userId: userId,
      username: username,
      token: token,
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      metadata: {'device': 'Desktop', 'platform': 'Windows', 'appVersion': '1.0.0'},
    );

    _activeSessions[sessionId] = session;
    _userSessions.putIfAbsent(userId, () => []).add(session);

    debugPrint('📱 Session créée: $sessionId pour $username');
    return sessionId;
  }

  void updateActivity(String sessionId) {
    if (_activeSessions.containsKey(sessionId)) {
      _activeSessions[sessionId]!.lastActivity = DateTime.now();
    }
  }

  Future<void> _cleanupExpiredSessions() async {
    final now = DateTime.now();
    final expired = _activeSessions.entries
        .where((e) => now.difference(e.value.lastActivity) > _sessionTimeout)
        .map((e) => e.key)
        .toList();

    for (final sessionId in expired) {
      final session = _activeSessions.remove(sessionId);
      if (session != null) {
        _userSessions[session.userId]?.remove(session);
        debugPrint('🗑️  Session expirée: $sessionId (${session.username})');
      }
    }
  }

  SessionData? getSession(String sessionId) => _activeSessions[sessionId];

  List<SessionData> getSessionsByUser(String userId) => _userSessions[userId] ?? [];

  List<Map<String, dynamic>> getAllActiveSessions() {
    return _activeSessions.values.map((s) => s.toJson()).toList();
  }

  int get activeSessionsCount => _activeSessions.length;

  Future<bool> validateSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) return false;

    updateActivity(sessionId);
    return !session.isExpired;
  }

  void closeSession(String sessionId) {
    final session = _activeSessions.remove(sessionId);
    if (session != null) {
      _userSessions[session.userId]?.remove(session);
      debugPrint('👋 Session fermée: $sessionId');
    }
  }

  void dispose() {
    _sessionCleanupTimer?.cancel();
    _activeSessions.clear();
    _userSessions.clear();
    debugPrint('🔌 SessionManager disposé');
  }
}
