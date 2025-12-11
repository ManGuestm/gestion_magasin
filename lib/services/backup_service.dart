import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_service.dart';
import 'audit_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Timer? _autoBackupTimer;
  bool _isBackupInProgress = false;

  /// Démarre la sauvegarde automatique
  void startAutoBackup({Duration interval = const Duration(hours: 6)}) {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer.periodic(interval, (_) => createBackup());
  }

  /// Arrête la sauvegarde automatique
  void stopAutoBackup() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
  }

  /// Crée une sauvegarde de la base de données
  Future<String?> createBackup({String? customName}) async {
    if (_isBackupInProgress) return null;
    
    try {
      _isBackupInProgress = true;
      
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(appDir.path, 'app_database.db');
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        throw Exception('Base de données introuvable');
      }

      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now();
      final fileName = customName ?? 
          'backup_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.db';
      
      final backupFile = File(path.join(backupDir.path, fileName));
      await dbFile.copy(backupFile.path);

      await AuditService().log(
        userId: 'system',
        userName: 'Système',
        action: AuditAction.backup,
        module: 'Sauvegarde',
        details: 'Sauvegarde créée: $fileName',
      );

      await _cleanOldBackups();
      return backupFile.path;
    } catch (e) {
      debugPrint('Erreur sauvegarde: $e');
      await AuditService().log(
        userId: 'system',
        userName: 'Système',
        action: AuditAction.error,
        module: 'Sauvegarde',
        details: 'Erreur sauvegarde: $e',
      );
      return null;
    } finally {
      _isBackupInProgress = false;
    }
  }

  /// Restaure une sauvegarde
  Future<bool> restoreBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Fichier de sauvegarde introuvable');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(appDir.path, 'app_database.db');
      await DatabaseService().close();
      
      await backupFile.copy(dbPath);
      await DatabaseService().initialize();

      await AuditService().log(
        userId: 'system',
        userName: 'Système',
        action: AuditAction.restore,
        module: 'Sauvegarde',
        details: 'Restauration depuis: ${path.basename(backupPath)}',
      );

      return true;
    } catch (e) {
      debugPrint('Erreur restauration: $e');
      return false;
    }
  }

  /// Liste les sauvegardes disponibles
  Future<List<BackupInfo>> getBackupList() async {
    try {
      final backupDir = await _getBackupDirectory();
      final files = await backupDir.list().where((entity) => 
        entity is File && entity.path.endsWith('.db')).toList();
      
      final backups = <BackupInfo>[];
      for (final file in files) {
        final stat = await file.stat();
        backups.add(BackupInfo(
          name: path.basename(file.path),
          path: file.path,
          size: stat.size,
          date: stat.modified,
        ));
      }
      
      backups.sort((a, b) => b.date.compareTo(a.date));
      return backups;
    } catch (e) {
      debugPrint('Erreur liste sauvegardes: $e');
      return [];
    }
  }

  /// Supprime une sauvegarde
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        await AuditService().log(
          userId: 'system',
          userName: 'Système',
          action: AuditAction.delete,
          module: 'Sauvegarde',
          details: 'Sauvegarde supprimée: ${path.basename(backupPath)}',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur suppression sauvegarde: $e');
      return false;
    }
  }

  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Nettoie les anciennes sauvegardes (garde les 10 plus récentes)
  Future<void> _cleanOldBackups() async {
    try {
      final backups = await getBackupList();
      if (backups.length > 10) {
        final toDelete = backups.skip(10);
        for (final backup in toDelete) {
          await deleteBackup(backup.path);
        }
      }
    } catch (e) {
      debugPrint('Erreur nettoyage sauvegardes: $e');
    }
  }
}

class BackupInfo {
  final String name;
  final String path;
  final int size;
  final DateTime date;

  BackupInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.date,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}