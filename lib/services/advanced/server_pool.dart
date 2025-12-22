import 'dart:io';
import 'package:flutter/material.dart';

/// Nœud serveur dans le pool
class ServerNode {
  final String id;
  final String ip;
  final int port;
  bool isHealthy = true;
  DateTime? lastHealthCheck;
  int failureCount = 0;
  int successCount = 0;

  ServerNode({required this.id, required this.ip, required this.port});

  String get address => '$ip:$port';
  String get url => 'http://$address';

  Duration get uptime {
    if (lastHealthCheck == null) return Duration.zero;
    return DateTime.now().difference(lastHealthCheck!);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'address': address,
    'isHealthy': isHealthy,
    'failureCount': failureCount,
    'successCount': successCount,
    'uptime': uptime.toString(),
    'lastHealthCheck': lastHealthCheck?.toIso8601String(),
  };
}

/// Configuration du pool de serveurs
class ServerPoolConfig {
  final List<ServerNode> nodes;
  final Duration healthCheckInterval;
  final int maxRetries;
  final int maxFailureBeforeRemoval;

  ServerPoolConfig({
    required this.nodes,
    this.healthCheckInterval = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.maxFailureBeforeRemoval = 5,
  });

  Map<String, dynamic> toJson() => {
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'healthCheckInterval': healthCheckInterval.toString(),
    'maxRetries': maxRetries,
    'maxFailureBeforeRemoval': maxFailureBeforeRemoval,
  };
}

/// Gestionnaire de pool de serveurs avec load balancing et failover
class ServerPool {
  final ServerPoolConfig config;
  late ServerNode _activeServer;
  int _roundRobinIndex = 0;

  ServerPool(this.config) {
    if (config.nodes.isEmpty) {
      throw ArgumentError('Le pool de serveurs doit contenir au moins un serveur');
    }
    _activeServer = config.nodes.first;
    debugPrint('🖥️  ServerPool initialized with ${config.nodes.length} nodes');
  }

  ServerNode get activeServer => _activeServer;

  List<ServerNode> get healthyServers => config.nodes.where((n) => n.isHealthy).toList();

  /// Obtient le serveur le plus sain (round-robin)
  ServerNode getHealthyServer() {
    final healthy = healthyServers;

    if (healthy.isEmpty) {
      debugPrint('⚠️  Tous les serveurs sont down - utilisation du premier');
      _activeServer = config.nodes.first;
      return _activeServer;
    }

    // Round-robin parmi les serveurs sains
    _roundRobinIndex = (_roundRobinIndex + 1) % healthy.length;
    _activeServer = healthy[_roundRobinIndex];
    return _activeServer;
  }

  /// Basculer vers un autre serveur en cas de panne
  bool failover() {
    final currentIndex = config.nodes.indexOf(_activeServer);
    final nextIndex = (currentIndex + 1) % config.nodes.length;

    _activeServer = config.nodes[nextIndex];
    debugPrint('🔄 Failover vers ${_activeServer.address}');

    return true;
  }

  /// Vérifie la santé d'un serveur
  Future<bool> healthCheck(ServerNode node) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.get(node.ip, node.port, '/api/health');
      final response = await request.close();
      client.close();

      if (response.statusCode == 200) {
        node.isHealthy = true;
        node.failureCount = 0;
        node.successCount++;
        node.lastHealthCheck = DateTime.now();
        debugPrint('✅ ${node.address} - Healthy (succès: ${node.successCount})');
        return true;
      }
    } catch (e) {
      debugPrint('❌ ${node.address} - Unhealthy: $e');
    }

    node.isHealthy = false;
    node.failureCount++;
    node.lastHealthCheck = DateTime.now();

    if (node.failureCount >= config.maxFailureBeforeRemoval) {
      debugPrint('🚫 ${node.address} - Désactivé après ${node.failureCount} échecs');
    }

    return false;
  }

  /// Lance un health check sur tous les serveurs
  Future<void> healthCheckAll() async {
    final futures = config.nodes.map((node) => healthCheck(node));
    await Future.wait(futures);
  }

  /// Obtient les statistiques du pool
  Map<String, dynamic> getStats() {
    return {
      'totalNodes': config.nodes.length,
      'healthyNodes': healthyServers.length,
      'activeServer': _activeServer.toJson(),
      'nodes': config.nodes.map((n) => n.toJson()).toList(),
    };
  }
}
