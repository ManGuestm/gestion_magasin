import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  late SharedPreferences _prefs;
  final List<SyncQueueItem> _localQueue = [];
  final int maxRetries = 3;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadQueueFromStorage();
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
}
