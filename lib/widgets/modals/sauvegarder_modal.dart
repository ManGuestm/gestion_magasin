import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../database/database_service.dart';

class SauvegarderModal extends StatefulWidget {
  const SauvegarderModal({super.key});

  @override
  State<SauvegarderModal> createState() => _SauvegarderModalState();
}

class _SauvegarderModalState extends State<SauvegarderModal> {
  bool _isBackingUp = false;
  String _backupPath = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.backup, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Sauvegarder la base de données',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Cette opération va créer une copie de sauvegarde de votre base de données.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isBackingUp) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Sauvegarde en cours...'),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _performBackup,
                    icon: const Icon(Icons.save),
                    label: const Text('Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ],
            if (_backupPath.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text(
                      'Sauvegarde réussie !',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fichier sauvegardé : $_backupPath',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/Backup_pos');

      // Créer le dossier s'il n'existe pas
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}';

      final backupFileName = 'backup_gestion_magasin_$dateStr.db';
      final backupPath = '${backupDir.path}/$backupFileName';

      // Obtenir le chemin de la base de données actuelle
      final dbService = DatabaseService();
      final dbPath = await dbService.getDatabasePath();

      // Copier le fichier de base de données
      final sourceFile = File(dbPath);
      await sourceFile.copy(backupPath);

      setState(() {
        _isBackingUp = false;
        _backupPath = backupPath;
      });
    } catch (e) {
      setState(() => _isBackingUp = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
