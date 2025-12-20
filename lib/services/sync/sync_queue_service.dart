import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/enhanced_network_client.dart';

enum SyncOperationType { insert, update, delete }

/// Élément de la queue de synchronisation
class SyncQueueItem {
  final String id;
  final String table;
  final SyncOperationType operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  bool isPending;

  SyncQueueItem({
    required this.id,
    required this.table,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.isPending = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'operation': operation.name,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'isPending': isPending,
  };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
    id: json['id'] as String,
    table: json['table'] as String,
    operation: SyncOperationType.values.firstWhere((e) => e.name == json['operation']),
    data: Map<String, dynamic>.from(json['data'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
    isPending: json['isPending'] as bool? ?? true,
  );
}

/// Service de gestion de la queue de synchronisation pour mode offline
/// Synchronise avec le serveur via HTTP REST
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  late SharedPreferences _prefs;
  final List<SyncQueueItem> _localQueue = [];
  final EnhancedNetworkClient _networkClient = EnhancedNetworkClient.instance;
  final int maxRetries = 3;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadQueueFromStorage();
    await _networkClient.initialize();
    _initialized = true;
  }

  /// Ajoute une opération à la queue
  Future<void> addOperation({
    required String table,
    required SyncOperationType operation,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncQueueItem(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}_${_localQueue.length}',
      table: table,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );

    _localQueue.add(item);
    await _persistQueueToStorage();
    debugPrint('Operation added to queue: ${item.table} ${item.operation.name}');
  }

  /// Récupère les opérations en attente
  Future<List<SyncQueueItem>> getPendingOperations() async {
    return _localQueue.where((i) => i.isPending).toList();
  }

  /// Marque une opération comme synchronisée
  Future<void> markAsSynced(String itemId) async {
    final index = _localQueue.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      _localQueue[index].isPending = false;
      await _persistQueueToStorage();
      debugPrint('Operation marked as synced: $itemId');
    }
  }

  /// Retire une opération de la queue
  Future<void> removeOperation(String itemId) async {
    _localQueue.removeWhere((i) => i.id == itemId);
    await _persistQueueToStorage();
    debugPrint('Operation removed from queue: $itemId');
  }

  /// Incrémente le nombre de tentatives
  Future<void> incrementRetry(String itemId) async {
    final index = _localQueue.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      _localQueue[index].retryCount++;
      await _persistQueueToStorage();
    }
  }

  /// Vide la queue
  Future<void> clearQueue() async {
    _localQueue.clear();
    await _persistQueueToStorage();
    debugPrint('Queue cleared');
  }

  /// Retourne le nombre d'opérations en attente
  int get pendingOperations => _localQueue.where((i) => i.isPending).length;

  /// Synchronise la queue avec le serveur distant
  /// Envoie les opérations en attente via HTTP REST
  Future<void> syncWithServer() async {
    if (!_initialized) {
      throw StateError('SyncQueueService not initialized');
    }

    if (!_networkClient.isConnected) {
      debugPrint('⚠️ Serveur indisponible - queue en attente de synchronisation');
      return;
    }

    if (!_networkClient.isAuthenticated) {
      debugPrint('⚠️ Non authentifié - impossible de synchroniser');
      return;
    }

    debugPrint('🔄 Synchronisation en cours ($pendingOperations operations en attente)...');

    final itemsToSync = List<SyncQueueItem>.from(_localQueue.where((i) => i.isPending).toList());

    for (final item in itemsToSync) {
      try {
        await _syncItemWithServer(item);
        await removeOperation(item.id);
        debugPrint('✅ Opération synchronisée: ${item.id}');
      } catch (e) {
        item.retryCount++;
        if (item.retryCount >= maxRetries) {
          debugPrint('❌ Opération échouée après $maxRetries tentatives: ${item.id}');
          await removeOperation(item.id);
        } else {
          debugPrint('⚠️ Tentative ${item.retryCount}/$maxRetries pour ${item.id}: $e');
          await _persistQueueToStorage();
          // Attendre avant la prochaine tentative (backoff exponentiel)
          await Future.delayed(Duration(seconds: 2 * item.retryCount));
        }
      }
    }

    debugPrint('✅ Synchronisation terminée');
  }

  /// Synchronise un item individuel avec le serveur via HTTP
  Future<void> _syncItemWithServer(SyncQueueItem item) async {
    try {
      // Construire la requête SQL
      final (sql, params) = _buildSyncSQL(item);

      debugPrint('📤 Envoi vers serveur: ${item.operation.name.toUpperCase()} ${item.table}');

      // Envoyer via HTTP REST
      if (item.operation == SyncOperationType.insert || item.operation == SyncOperationType.update) {
        // INSERT/UPDATE utilise /api/execute
        await _networkClient.execute(sql, params);
      } else if (item.operation == SyncOperationType.delete) {
        // DELETE utilise /api/execute
        await _networkClient.execute(sql, params);
      }

      // Marquer comme synchronisée
      await markAsSynced(item.id);
    } catch (e) {
      debugPrint('❌ Erreur sync: $e');
      rethrow;
    }
  }

  /// Construit la requête SQL pour une opération de queue
  (String sql, List<dynamic> params) _buildSyncSQL(SyncQueueItem item) {
    switch (item.operation) {
      case SyncOperationType.insert:
        final columns = item.data.keys.join(', ');
        final placeholders = List.filled(item.data.length, '?').join(', ');
        final sql = 'INSERT INTO ${item.table} ($columns) VALUES ($placeholders)';
        final params = item.data.values.toList();
        return (sql, params);

      case SyncOperationType.update:
        final sets = item.data.entries
            .where((e) => e.key != 'id' && e.key != 'rsoc')
            .map((e) => '${e.key} = ?')
            .join(', ');
        // Utiliser 'rsoc' comme primary key (ou 'id' si disponible)
        final primaryKey = item.data.containsKey('rsoc') ? 'rsoc' : 'id';
        final sql = 'UPDATE ${item.table} SET $sets WHERE $primaryKey = ?';
        final params = item.data.entries.where((e) => e.key != primaryKey).map((e) => e.value).toList();
        params.add(item.data[primaryKey]);
        return (sql, params);

      case SyncOperationType.delete:
        final primaryKey = item.data.containsKey('rsoc') ? 'rsoc' : 'id';
        final sql = 'DELETE FROM ${item.table} WHERE $primaryKey = ?';
        final params = [item.data[primaryKey]];
        return (sql, params);
    }
  }

  /// Persiste la queue dans le stockage local
  Future<void> _persistQueueToStorage() async {
    try {
      final jsonList = _localQueue.map((i) => i.toJson()).toList();
      await _prefs.setString('sync_queue', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erreur persistence queue: $e');
    }
  }

  /// Charge la queue depuis le stockage local
  Future<void> _loadQueueFromStorage() async {
    try {
      final queueJson = _prefs.getString('sync_queue');
      if (queueJson != null) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        _localQueue.clear();
        for (final item in decoded) {
          _localQueue.add(SyncQueueItem.fromJson(item as Map<String, dynamic>));
        }
        debugPrint('Queue loaded from storage: ${_localQueue.length} items');
      }
    } catch (e) {
      debugPrint('Erreur chargement queue: $e');
    }
  }

  /// Récupère les changements du serveur
  Future<void> pullChangesFromServer() async {
    if (!_initialized || !_networkClient.isConnected) {
      return;
    }

    try {
      final lastSync = DateTime.now().subtract(const Duration(minutes: 5));
      final changes = await _networkClient.getServerChanges(lastSync);

      if (changes.isEmpty) {
        return;
      }

      debugPrint('📥 Application de ${changes.length} changements du serveur');
      // Les changements sont déjà appliqués par le serveur lors de la synchronisation
    } catch (e) {
      debugPrint('⚠️ Erreur récupération changements: $e');
    }
  }
}
