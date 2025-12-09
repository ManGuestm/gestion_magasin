import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../database/database_service.dart';

class RestaurerModal extends StatefulWidget {
  const RestaurerModal({super.key});

  @override
  State<RestaurerModal> createState() => _RestaurerModalState();
}

class _RestaurerModalState extends State<RestaurerModal> {
  bool _isRestoring = false;
  String _selectedFilePath = '';
  bool _restoreSuccess = false;

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
                const Icon(Icons.restore, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Restaurer la base de données',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Column(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'ATTENTION',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cette opération remplacera complètement votre base de données actuelle. Toutes les données non sauvegardées seront perdues.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isRestoring) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Restauration en cours...'),
            ] else if (_restoreSuccess) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      'Restauration réussie !',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'L\'application va redémarrer pour appliquer les changements.',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fermer'),
              ),
            ] else ...[
              if (_selectedFilePath.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.file_present, color: Colors.blue),
                      const SizedBox(height: 8),
                      const Text(
                        'Fichier sélectionné :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFilePath.split('\\').last,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectBackupFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Sélectionner fichier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_selectedFilePath.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _performRestore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restaurer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectBackupFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Sélectionner un fichier de sauvegarde',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection du fichier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performRestore() async {
    // Demander confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la restauration'),
        content: const Text(
          'Êtes-vous sûr de vouloir restaurer cette sauvegarde ? '
          'Cette action est irréversible et remplacera toutes vos données actuelles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);

    try {
      final dbService = DatabaseService();
      
      // Fermer la base de données actuelle
      await dbService.closeDatabase();
      
      // Obtenir le chemin de la base de données actuelle
      final dbPath = await dbService.getDatabasePath();
      
      // Copier le fichier de sauvegarde vers l'emplacement de la base de données
      final backupFile = File(_selectedFilePath);
      final currentDbFile = File(dbPath);
      
      // Supprimer l'ancienne base de données
      if (await currentDbFile.exists()) {
        await currentDbFile.delete();
      }
      
      // Copier la sauvegarde
      await backupFile.copy(dbPath);
      
      // Réinitialiser le service de base de données
      await dbService.reinitializeDatabase();
      
      setState(() {
        _isRestoring = false;
        _restoreSuccess = true;
      });
    } catch (e) {
      setState(() => _isRestoring = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la restauration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}