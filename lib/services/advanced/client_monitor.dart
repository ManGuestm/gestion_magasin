import 'package:flutter/material.dart';

/// Métriques de client
class ClientMetrics {
  final String clientId;
  final String username;
  final String ipAddress;
  int requestCount = 0;
  int errorCount = 0;
  final DateTime connectedAt;
  DateTime? lastRequestAt;
  double averageResponseTime = 0.0;
  final List<double> responseTimes = [];

  ClientMetrics({
    required this.clientId,
    required this.username,
    required this.ipAddress,
    required this.connectedAt,
  });

  Duration get connectionDuration => DateTime.now().difference(connectedAt);
  double get errorRate => requestCount > 0 ? (errorCount / requestCount) * 100 : 0;
  bool get isActive => DateTime.now().difference(lastRequestAt ?? connectedAt).inMinutes < 5;
  double get maxResponseTime => responseTimes.isEmpty ? 0 : responseTimes.reduce((a, b) => a > b ? a : b);
  double get minResponseTime => responseTimes.isEmpty ? 0 : responseTimes.reduce((a, b) => a < b ? a : b);

  void recordRequest(double responseTimeMs) {
    requestCount++;
    lastRequestAt = DateTime.now();
    responseTimes.add(responseTimeMs);

    // Garder que les 100 dernières mesures
    if (responseTimes.length > 100) {
      responseTimes.removeAt(0);
    }

    if (responseTimes.isNotEmpty) {
      averageResponseTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
    }
  }

  void recordError() {
    errorCount++;
  }

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'username': username,
    'ipAddress': ipAddress,
    'requestCount': requestCount,
    'errorCount': errorCount,
    'errorRate': errorRate.toStringAsFixed(2),
    'averageResponseTime': averageResponseTime.toStringAsFixed(2),
    'maxResponseTime': maxResponseTime.toStringAsFixed(2),
    'minResponseTime': minResponseTime.toStringAsFixed(2),
    'connectionDuration': connectionDuration.toString(),
    'isActive': isActive,
    'connectedAt': connectedAt.toIso8601String(),
    'lastRequest': lastRequestAt?.toIso8601String(),
  };
}

/// Moniteur de performance des clients
class ClientMonitor {
  static final ClientMonitor _instance = ClientMonitor._();
  factory ClientMonitor() => _instance;
  ClientMonitor._();

  final Map<String, ClientMetrics> _clientMetrics = {};

  void trackClient(String clientId, String username, String ipAddress) {
    _clientMetrics[clientId] = ClientMetrics(
      clientId: clientId,
      username: username,
      ipAddress: ipAddress,
      connectedAt: DateTime.now(),
    );
    debugPrint('📊 Client tracked: $username ($ipAddress)');
  }

  void recordRequest(String clientId, double responseTimeMs) {
    _clientMetrics[clientId]?.recordRequest(responseTimeMs);
  }

  void recordError(String clientId) {
    _clientMetrics[clientId]?.recordError();
  }

  List<Map<String, dynamic>> getMetrics() {
    return _clientMetrics.values.map((m) => m.toJson()).toList();
  }

  Map<String, dynamic>? getClientMetrics(String clientId) {
    return _clientMetrics[clientId]?.toJson();
  }

  ClientMetrics? getClientMetricsObject(String clientId) {
    return _clientMetrics[clientId];
  }

  void removeClient(String clientId) {
    final metrics = _clientMetrics.remove(clientId);
    if (metrics != null) {
      debugPrint('🗑️  Client removed: ${metrics.username} - ${metrics.requestCount} requests');
    }
  }

  Map<String, dynamic> getAggregatedStats() {
    if (_clientMetrics.isEmpty) {
      return {
        'totalClients': 0,
        'activeClients': 0,
        'totalRequests': 0,
        'totalErrors': 0,
        'averageResponseTime': 0.0,
      };
    }

    final totalRequests = _clientMetrics.values.fold<int>(0, (sum, m) => sum + m.requestCount);
    final totalErrors = _clientMetrics.values.fold<int>(0, (sum, m) => sum + m.errorCount);
    final activeClients = _clientMetrics.values.where((m) => m.isActive).length;
    final allResponseTimes = _clientMetrics.values.expand((m) => m.responseTimes).toList();
    final avgResponseTime = allResponseTimes.isEmpty
        ? 0.0
        : allResponseTimes.reduce((a, b) => a + b) / allResponseTimes.length;

    return {
      'totalClients': _clientMetrics.length,
      'activeClients': activeClients,
      'totalRequests': totalRequests,
      'totalErrors': totalErrors,
      'errorRate': totalRequests > 0 ? ((totalErrors / totalRequests) * 100).toStringAsFixed(2) : '0.00',
      'averageResponseTime': avgResponseTime.toStringAsFixed(2),
    };
  }

  void dispose() {
    _clientMetrics.clear();
    debugPrint('🔌 ClientMonitor disposé');
  }
}
