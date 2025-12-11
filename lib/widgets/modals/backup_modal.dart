import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../common/loading_overlay.dart';

class BackupModal extends StatefulWidget {
  const BackupModal({super.key});

  @override
  State<BackupModal> createState() => _BackupModalState();
}

class _BackupModalState extends State<BackupModal> {
  List<BackupInfo> _backups = [];
  bool _isLoading = false;
  String? _loadingMessage;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Chargement des sauvegardes...';
    });

    try {
      final backups = await BackupService().getBackupList();
      setState(() {
        _backups = backups;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Création de la sauvegarde...';
    });

    try {
      final backupPath = await BackupService().createBackup();
      if (backupPath != null) {
        NotificationService().notifyBackupSuccess(backupPath.split('/').last);
        await _loadBackups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sauvegarde créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Échec de la création de la sauvegarde');
      }
    } catch (e) {
      NotificationService().notifyBackupError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la restauration'),
        content: Text(
          'Êtes-vous sûr de vouloir restaurer la sauvegarde "${backup.name}" ?\n\n'
          'Cette action remplacera toutes les données actuelles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Restauration en cours...';
    });

    try {
      final success = await BackupService().restoreBackup(backup.path);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restauration réussie'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Échec de la restauration');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer la sauvegarde "${backup.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BackupService().deleteBackup(backup.path);
      await _loadBackups();
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result != null && result.files.single.path != null) {
      final backupPath = result.files.single.path!;
      final backupInfo = BackupInfo(
        name: result.files.single.name,
        path: backupPath,
        size: result.files.single.size,
        date: DateTime.now(),
      );
      await _restoreBackup(backupInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: LoadingOverlay(
          isLoading: _isLoading,
          message: _loadingMessage,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildActions(),
              const SizedBox(height: 16),
              Expanded(child: _buildBackupList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.backup, color: Colors.blue),
        const SizedBox(width: 8),
        const Text(
          'Gestion des Sauvegardes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _createBackup,
          icon: const Icon(Icons.add),
          label: const Text('Créer Sauvegarde'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _importBackup,
          icon: const Icon(Icons.upload),
          label: const Text('Importer'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _loadBackups,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
        ),
        const Spacer(),
        Text('${_backups.length} sauvegarde(s)'),
      ],
    );
  }

  Widget _buildBackupList() {
    if (_backups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.backup, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune sauvegarde trouvée'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _backups.length,
      itemBuilder: (context, index) {
        final backup = _backups[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.storage, color: Colors.blue),
            title: Text(backup.name),
            subtitle: Text(
              '${backup.formattedSize} • ${_formatDate(backup.date)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _restoreBackup(backup),
                  icon: const Icon(Icons.restore, color: Colors.orange),
                  tooltip: 'Restaurer',
                ),
                IconButton(
                  onPressed: () => _deleteBackup(backup),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}