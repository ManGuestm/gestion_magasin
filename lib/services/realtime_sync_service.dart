import 'package:flutter/material.dart';

import '../database/database_service.dart';
import 'network_client.dart';

/// Service de synchronisation temps réel pour les clients
class RealtimeSyncService {
  static final RealtimeSyncService _instance = RealtimeSyncService._();
  factory RealtimeSyncService() => _instance;
  RealtimeSyncService._();

  final NetworkClient _client = NetworkClient.instance;
  final DatabaseService _db = DatabaseService();
  final Set<VoidCallback> _refreshCallbacks = {};
  bool _isListening = false;

  /// Démarre l'écoute des changements du serveur
  void startListening() {
    if (_isListening) return;

    _client.addChangeListener(_onServerChange);
    _isListening = true;
    debugPrint('🎧 Écoute des changements serveur activée');
  }

  /// Arrête l'écoute
  void stopListening() {
    if (!_isListening) return;

    _client.removeChangeListener(_onServerChange);
    _isListening = false;
    debugPrint('🔇 Écoute des changements serveur désactivée');
  }

  /// Ajoute un callback de rafraîchissement
  void addRefreshCallback(VoidCallback callback) {
    _refreshCallbacks.add(callback);
  }

  /// Retire un callback
  void removeRefreshCallback(VoidCallback callback) {
    _refreshCallbacks.remove(callback);
  }

  /// Gère les changements reçus du serveur
  void _onServerChange(Map<String, dynamic> change) {
    final type = change['type'] as String?;
    debugPrint('📥 Changement reçu du serveur: $type');

    // Invalider le cache
    _db.invalidateCache('all_');

    // Notifier tous les écrans pour rafraîchir
    for (final callback in _refreshCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Erreur callback refresh: $e');
      }
    }

    debugPrint('✅ ${_refreshCallbacks.length} écrans notifiés');
  }

  /// Nettoie les ressources
  void dispose() {
    stopListening();
    _refreshCallbacks.clear();
  }
}
