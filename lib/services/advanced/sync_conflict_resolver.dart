import 'package:flutter/material.dart';

enum ConflictResolutionStrategy { serverWins, clientWins, manual, merge }

/// Représente un conflit de synchronisation
class SyncConflict {
  final dynamic id;
  final String table;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> serverVersion;
  final DateTime timestamp;

  SyncConflict({
    required this.id,
    required this.table,
    required this.localVersion,
    required this.serverVersion,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'localVersion': localVersion,
    'serverVersion': serverVersion,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Résultat de synchronisation
class SyncResult {
  final String table;
  final int localChanges;
  final int serverChanges;
  final int conflicts;
  final int resolved;
  final List<SyncConflict> unresolved;
  final DateTime timestamp;

  SyncResult({
    required this.table,
    required this.localChanges,
    required this.serverChanges,
    required this.conflicts,
    required this.resolved,
    required this.unresolved,
    required this.timestamp,
  });

  int get totalChanges => localChanges + serverChanges;
  bool get hasConflicts => conflicts > 0;
  bool get allResolved => resolved == conflicts;
  double get conflictRate => conflicts > 0 ? (conflicts / totalChanges) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'table': table,
    'localChanges': localChanges,
    'serverChanges': serverChanges,
    'conflicts': conflicts,
    'resolved': resolved,
    'unresolved': unresolved.length,
    'totalChanges': totalChanges,
    'conflictRate': conflictRate.toStringAsFixed(2),
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Résolveur de conflits de synchronisation
class SyncConflictResolver {
  static final SyncConflictResolver _instance = SyncConflictResolver._();
  factory SyncConflictResolver() => _instance;
  SyncConflictResolver._();

  ConflictResolutionStrategy _conflictStrategy = ConflictResolutionStrategy.serverWins;
  final List<SyncResult> _syncHistory = [];

  void setConflictStrategy(ConflictResolutionStrategy strategy) {
    _conflictStrategy = strategy;
    debugPrint('🔄 Conflict strategy: ${strategy.name}');
  }

  /// Détecte les conflits entre changements locaux et serveur
  List<SyncConflict> detectConflicts(
    String table,
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> server,
  ) {
    final conflicts = <SyncConflict>[];

    for (final localChange in local) {
      final id = localChange['id'];
      final serverChange = server.firstWhere((s) => s['id'] == id, orElse: () => {});

      if (serverChange.isNotEmpty) {
        final localTimestamp = localChange['updatedAt'] ?? localChange['createdAt'];
        final serverTimestamp = serverChange['updatedAt'] ?? serverChange['createdAt'];

        if (localTimestamp != serverTimestamp) {
          conflicts.add(
            SyncConflict(
              id: id,
              table: table,
              localVersion: localChange,
              serverVersion: serverChange,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    }

    if (conflicts.isNotEmpty) {
      debugPrint('⚠️  Conflits détectés: ${conflicts.length} conflits dans $table');
    }

    return conflicts;
  }

  /// Résout les conflits en utilisant la stratégie définie
  Future<List<SyncConflict>> resolveConflicts(List<SyncConflict> conflicts) async {
    final resolved = <SyncConflict>[];

    for (final conflict in conflicts) {
      final resolution = switch (_conflictStrategy) {
        ConflictResolutionStrategy.serverWins => conflict.serverVersion,
        ConflictResolutionStrategy.clientWins => conflict.localVersion,
        ConflictResolutionStrategy.manual => await _manualResolve(conflict),
        ConflictResolutionStrategy.merge => _mergeVersions(conflict),
      };

      resolved.add(
        SyncConflict(
          id: conflict.id,
          table: conflict.table,
          localVersion: conflict.localVersion,
          serverVersion: resolution,
          timestamp: DateTime.now(),
        ),
      );
    }

    return resolved;
  }

  /// Fusion intelligente de deux versions
  Map<String, dynamic> _mergeVersions(SyncConflict conflict) {
    final merged = {...conflict.serverVersion};

    // Fusionner les champs sans conflit
    for (final key in conflict.localVersion.keys) {
      if (!merged.containsKey(key) || merged[key] == null) {
        merged[key] = conflict.localVersion[key];
      }
    }

    merged['_merged'] = true;
    merged['_mergedAt'] = DateTime.now().toIso8601String();
    merged['_conflictId'] = conflict.id;

    debugPrint('🔀 Fusion intelligente pour ${conflict.id}');
    return merged;
  }

  /// Résolution manuelle (placeholder - à implémenter avec UI si nécessaire)
  Future<Map<String, dynamic>> _manualResolve(SyncConflict conflict) async {
    debugPrint('⚠️  Résolution manuelle nécessaire pour ${conflict.id}');
    // Par défaut: serveur prioritaire
    return conflict.serverVersion;
  }

  /// Synchronisation complète avec détection et résolution de conflits
  Future<SyncResult> syncWithConflictDetection({
    required String table,
    required List<Map<String, dynamic>> localChanges,
    required List<Map<String, dynamic>> serverChanges,
  }) async {
    final conflicts = detectConflicts(table, localChanges, serverChanges);
    final resolved = await resolveConflicts(conflicts);

    final syncResult = SyncResult(
      table: table,
      localChanges: localChanges.length,
      serverChanges: serverChanges.length,
      conflicts: conflicts.length,
      resolved: resolved.length,
      unresolved: conflicts.where((c) => !resolved.any((r) => r.id == c.id)).toList(),
      timestamp: DateTime.now(),
    );

    _syncHistory.add(syncResult);

    if (conflicts.isEmpty) {
      debugPrint('✅ Sync clean: ${syncResult.totalChanges} changes, 0 conflicts');
    } else {
      debugPrint('⚠️  Sync avec conflits: ${syncResult.conflictRate.toStringAsFixed(2)}% conflits');
    }

    return syncResult;
  }

  List<SyncResult> get syncHistory => List.unmodifiable(_syncHistory);

  void clearHistory() {
    _syncHistory.clear();
    debugPrint('🗑️  Historique de sync effacé');
  }
}
