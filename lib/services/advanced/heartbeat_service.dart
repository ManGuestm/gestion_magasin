import 'dart:async';

import 'package:flutter/material.dart';

/// Service de vérification de la santé de la connexion
class HeartbeatService {
  static final HeartbeatService _instance = HeartbeatService._();
  factory HeartbeatService() => _instance;
  HeartbeatService._();

  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _heartbeatTimeout = Duration(seconds: 45);
  static const int _maxConsecutiveFailures = 3;

  int _consecutiveFailures = 0;
  bool _isHealthy = true;
  DateTime? _lastHealthCheck;

  final Set<Function(bool)> _statusListeners = {};
  final Set<VoidCallback> _connectionLostListeners = {};

  void addStatusListener(Function(bool) listener) => _statusListeners.add(listener);
  void removeStatusListener(Function(bool) listener) => _statusListeners.remove(listener);

  void addConnectionLostListener(VoidCallback listener) => _connectionLostListeners.add(listener);
  void removeConnectionLostListener(VoidCallback listener) => _connectionLostListeners.remove(listener);

  bool get isHealthy => _isHealthy;
  int get consecutiveFailures => _consecutiveFailures;
  DateTime? get lastHealthCheck => _lastHealthCheck;

  void startHeartbeat({
    required Future<bool> Function() checkConnection,
    required VoidCallback onConnectionLost,
  }) {
    // Éviter les multiples démarrages
    if (_heartbeatTimer != null) return;

    debugPrint('❤️  Heartbeat service démarré');

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      try {
        _timeoutTimer = Timer(_heartbeatTimeout, () {
          debugPrint('❌ Heartbeat timeout - Serveur ne répond pas');
          _handleHealthCheckFailure(onConnectionLost);
        });

        final isAlive = await checkConnection();
        _timeoutTimer?.cancel();

        if (isAlive) {
          _handleHealthCheckSuccess();
        } else {
          _handleHealthCheckFailure(onConnectionLost);
        }
      } catch (e) {
        _timeoutTimer?.cancel();
        debugPrint('❌ Heartbeat error: $e');
        _handleHealthCheckFailure(onConnectionLost);
      }
    });

    // Premier check immédiat
    _performHealthCheck(checkConnection, onConnectionLost);
  }

  Future<void> _performHealthCheck(
    Future<bool> Function() checkConnection,
    VoidCallback onConnectionLost,
  ) async {
    try {
      _timeoutTimer = Timer(_heartbeatTimeout, () {
        _handleHealthCheckFailure(onConnectionLost);
      });

      final isAlive = await checkConnection();
      _timeoutTimer?.cancel();

      if (isAlive) {
        _handleHealthCheckSuccess();
      } else {
        _handleHealthCheckFailure(onConnectionLost);
      }
    } catch (e) {
      _timeoutTimer?.cancel();
      _handleHealthCheckFailure(onConnectionLost);
    }
  }

  void _handleHealthCheckSuccess() {
    _lastHealthCheck = DateTime.now();
    _consecutiveFailures = 0;

    if (!_isHealthy) {
      _isHealthy = true;
      debugPrint('✅ Heartbeat OK - Serveur récupéré');
      _notifyStatusChange(true);
    }
  }

  void _handleHealthCheckFailure(VoidCallback onConnectionLost) {
    _lastHealthCheck = DateTime.now();
    _consecutiveFailures++;

    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      if (_isHealthy) {
        _isHealthy = false;
        debugPrint('❌ Heartbeat failed $_consecutiveFailures times - Connection lost');
        _notifyStatusChange(false);
        onConnectionLost();
        _notifyConnectionLost();
      }
    }
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _timeoutTimer?.cancel();
    _heartbeatTimer = null;
    _consecutiveFailures = 0;
    debugPrint('⏹️  Heartbeat service arrêté');
  }

  void _notifyStatusChange(bool isConnected) {
    for (final listener in _statusListeners) {
      try {
        listener(isConnected);
      } catch (e) {
        debugPrint('❌ Error in status listener: $e');
      }
    }
  }

  void _notifyConnectionLost() {
    for (final listener in _connectionLostListeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('❌ Error in connection lost listener: $e');
      }
    }
  }

  void dispose() {
    stopHeartbeat();
    _statusListeners.clear();
    _connectionLostListeners.clear();
  }
}
