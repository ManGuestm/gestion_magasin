import 'dart:async';

import 'package:flutter/material.dart';

import 'sync_queue_service.dart';

/// Service de synchronisation périodique Client/Serveur
/// Synchronise automatiquement les opérations en attente toutes les 10 secondes
class SyncTimerService {
  static final SyncTimerService _instance = SyncTimerService._internal();
  factory SyncTimerService() => _instance;
  SyncTimerService._internal();

  Timer? _syncTimer;
  final SyncQueueService _syncQueue = SyncQueueService();
  static const Duration _syncInterval = Duration(seconds: 10);
  bool _isRunning = false;

  /// Démarre la synchronisation périodique
  void startPeriodicSync() {
    if (_syncTimer != null) {
      debugPrint('⏱️ Synchronisation périodique déjà active');
      return;
    }

    debugPrint('⏱️ Démarrage de la synchronisation périodique (toutes les ${_syncInterval.inSeconds}s)');

    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      if (_isRunning) return; // Éviter les exécutions concurrentes

      _isRunning = true;
      try {
        await _syncQueue.syncWithServer();
        await _syncQueue.pullChangesFromServer();
      } catch (e) {
        debugPrint('⚠️ Erreur sync périodique: $e');
      } finally {
        _isRunning = false;
      }
    });
  }

  /// Arrête la synchronisation périodique
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('⏱️ Synchronisation périodique arrêtée');
  }

  /// Force une synchronisation immédiate
  Future<void> syncNow() async {
    if (_isRunning) {
      debugPrint('⏱️ Synchronisation déjà en cours');
      return;
    }

    _isRunning = true;
    try {
      debugPrint('🔄 Force synchronisation immédiate...');
      await _syncQueue.syncWithServer();
      await _syncQueue.pullChangesFromServer();
    } catch (e) {
      debugPrint('❌ Erreur synchronisation immédiate: $e');
    } finally {
      _isRunning = false;
    }
  }

  /// Nettoie et arrête le service
  void dispose() {
    stopPeriodicSync();
  }

  bool get isRunning => _isRunning;
}
