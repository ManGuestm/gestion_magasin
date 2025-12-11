import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum AuditAction {
  login,
  logout,
  create,
  update,
  delete,
  export,
  print,
  backup,
  restore,
  error
}

class AuditLog {
  final DateTime timestamp;
  final String userId;
  final String userName;
  final AuditAction action;
  final String module;
  final String details;
  final String? ipAddress;

  AuditLog({
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    required this.details,
    this.ipAddress,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'userName': userName,
    'action': action.name,
    'module': module,
    'details': details,
    'ipAddress': ipAddress,
  };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    timestamp: DateTime.parse(json['timestamp']),
    userId: json['userId'],
    userName: json['userName'],
    action: AuditAction.values.firstWhere((e) => e.name == json['action']),
    module: json['module'],
    details: json['details'],
    ipAddress: json['ipAddress'],
  );
}

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  static const String _logFileName = 'audit_logs.jsonl';
  File? _logFile;

  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/$_logFileName');
      
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Erreur initialisation audit: $e');
    }
  }

  Future<void> log({
    required String userId,
    required String userName,
    required AuditAction action,
    required String module,
    required String details,
    String? ipAddress,
  }) async {
    try {
      final auditLog = AuditLog(
        timestamp: DateTime.now(),
        userId: userId,
        userName: userName,
        action: action,
        module: module,
        details: details,
        ipAddress: ipAddress,
      );

      if (_logFile != null) {
        await _logFile!.writeAsString(
          '${jsonEncode(auditLog.toJson())}\n',
          mode: FileMode.append,
        );
      }

      // En mode debug, afficher aussi dans la console
      if (kDebugMode) {
        debugPrint('AUDIT: ${auditLog.action.name} - $module - $details');
      }
    } catch (e) {
      debugPrint('Erreur écriture audit: $e');
    }
  }

  Future<List<AuditLog>> getLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    AuditAction? action,
    String? module,
  }) async {
    try {
      if (_logFile == null || !await _logFile!.exists()) {
        return [];
      }

      final lines = await _logFile!.readAsLines();
      final logs = <AuditLog>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final log = AuditLog.fromJson(jsonDecode(line));
          
          // Filtres
          if (startDate != null && log.timestamp.isBefore(startDate)) continue;
          if (endDate != null && log.timestamp.isAfter(endDate)) continue;
          if (userId != null && log.userId != userId) continue;
          if (action != null && log.action != action) continue;
          if (module != null && log.module != module) continue;
          
          logs.add(log);
        } catch (e) {
          debugPrint('Erreur parsing log: $e');
        }
      }

      return logs..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Erreur lecture logs: $e');
      return [];
    }
  }

  Future<void> clearOldLogs({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final logs = await getLogs(startDate: cutoffDate);
      
      if (_logFile != null) {
        await _logFile!.writeAsString('');
        for (final log in logs) {
          await _logFile!.writeAsString(
            '${jsonEncode(log.toJson())}\n',
            mode: FileMode.append,
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur nettoyage logs: $e');
    }
  }
}