import 'package:flutter/material.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, DateTime> _timers = {};
  final Map<String, int> _counters = {};

  void startTimer(String name) {
    _timers[name] = DateTime.now();
  }

  int stopTimer(String name) {
    final start = _timers.remove(name);
    if (start == null) return 0;
    
    final duration = DateTime.now().difference(start).inMilliseconds;
    debugPrint('⏱️ $name: ${duration}ms');
    return duration;
  }

  void incrementCounter(String name) {
    _counters[name] = (_counters[name] ?? 0) + 1;
  }

  int getCounter(String name) => _counters[name] ?? 0;

  void resetCounter(String name) => _counters.remove(name);

  void clearAll() {
    _timers.clear();
    _counters.clear();
  }

  Map<String, dynamic> getStats() {
    return {
      'activeTimers': _timers.keys.toList(),
      'counters': Map.from(_counters),
    };
  }
}