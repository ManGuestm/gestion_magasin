import 'dart:collection';

import 'package:flutter/material.dart';

/// Configuration du rate limiting
class RateLimitConfig {
  final int requestsPerMinute;
  final int burst;
  final Duration windowSize;

  RateLimitConfig({
    this.requestsPerMinute = 60,
    this.burst = 10,
    this.windowSize = const Duration(minutes: 1),
  });

  Map<String, dynamic> toJson() => {
    'requestsPerMinute': requestsPerMinute,
    'burst': burst,
    'windowSize': windowSize.toString(),
  };
}

/// Rate limiter pour un client
class RateLimiter {
  final String clientId;
  final RateLimitConfig config;
  final Queue<DateTime> _requestTimestamps = Queue();
  bool _isBurstActive = false;

  RateLimiter(this.clientId, this.config);

  bool allowRequest() {
    final now = DateTime.now();
    final cutoff = now.subtract(config.windowSize);

    // Nettoyer les anciennes requêtes
    while (_requestTimestamps.isNotEmpty && _requestTimestamps.first.isBefore(cutoff)) {
      _requestTimestamps.removeFirst();
    }

    if (_requestTimestamps.length < config.requestsPerMinute) {
      _requestTimestamps.add(now);
      return true;
    }

    // Vérifier si burst est disponible
    if (!_isBurstActive && _requestTimestamps.length < (config.requestsPerMinute + config.burst)) {
      _requestTimestamps.add(now);
      _isBurstActive = true;
      debugPrint('⚡ Burst mode activé pour $clientId');
      return true;
    }

    debugPrint('⛔ Rate limit atteint pour $clientId');
    return false;
  }

  int get remainingRequests {
    final remaining = config.requestsPerMinute - _requestTimestamps.length;
    return remaining > 0 ? remaining : 0;
  }

  int get remainingBurst {
    final burstRemaining = (config.requestsPerMinute + config.burst) - _requestTimestamps.length;
    return burstRemaining > 0 ? burstRemaining : 0;
  }

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'requestCount': _requestTimestamps.length,
    'remainingRequests': remainingRequests,
    'remainingBurst': remainingBurst,
    'isBurstActive': _isBurstActive,
  };
}

/// Pool de rate limiters
class RateLimiterPool {
  static final RateLimiterPool _instance = RateLimiterPool._();
  factory RateLimiterPool() => _instance;
  RateLimiterPool._();

  final Map<String, RateLimiter> _limiters = {};
  final Map<String, RateLimitConfig> _clientConfigs = {};
  late RateLimitConfig _defaultConfig;

  void initialize({RateLimitConfig? defaultConfig}) {
    _defaultConfig = defaultConfig ?? RateLimitConfig();
    debugPrint('🚦 RateLimiterPool initialized with default config');
  }

  bool checkLimit(String clientId) {
    final limiter = _limiters.putIfAbsent(
      clientId,
      () => RateLimiter(clientId, _clientConfigs[clientId] ?? _defaultConfig),
    );
    return limiter.allowRequest();
  }

  int getRemainingRequests(String clientId) {
    return _limiters[clientId]?.remainingRequests ?? _defaultConfig.requestsPerMinute;
  }

  int getRemainingBurst(String clientId) {
    return _limiters[clientId]?.remainingBurst ?? _defaultConfig.burst;
  }

  void setClientConfig(String clientId, RateLimitConfig config) {
    _clientConfigs[clientId] = config;
    _limiters.remove(clientId); // Réinitialiser le limiter
    debugPrint('⚙️  Config personnalisée pour $clientId');
  }

  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{
      'totalClients': _limiters.length,
      'limiters': _limiters.values.map((l) => l.toJson()).toList(),
    };
    return stats;
  }

  void resetClient(String clientId) {
    _limiters.remove(clientId);
    debugPrint('🔄 Rate limiter reset pour $clientId');
  }

  void dispose() {
    _limiters.clear();
    _clientConfigs.clear();
    debugPrint('🔌 RateLimiterPool disposé');
  }
}
