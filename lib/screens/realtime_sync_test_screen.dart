import 'package:flutter/material.dart';
import 'package:gestion_magasin/database/database_service.dart';
import 'package:gestion_magasin/services/realtime_sync_service.dart';

/// Écran de test pour la synchronisation temps réel
class RealtimeSyncTestScreen extends StatefulWidget {
  const RealtimeSyncTestScreen({super.key});

  @override
  State<RealtimeSyncTestScreen> createState() => _RealtimeSyncTestScreenState();
}

class _RealtimeSyncTestScreenState extends State<RealtimeSyncTestScreen> {
  final DatabaseService _db = DatabaseService();
  final RealtimeSyncService _syncService = RealtimeSyncService();
  final List<String> _logs = [];
  int _changeCount = 0;

  @override
  void initState() {
    super.initState();
    _syncService.startListening();
    _syncService.addRefreshCallback(_onDataChanged);
    _addLog('✅ Service de synchronisation démarré');
  }

  @override
  void dispose() {
    _syncService.removeRefreshCallback(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {
      _changeCount++;
      _addLog('🔔 Changement #$_changeCount reçu à ${DateTime.now().toIso8601String()}');
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, message);
      if (_logs.length > 50) _logs.removeLast();
    });
    debugPrint(message);
  }

  Future<void> _testInsert() async {
    try {
      _addLog('📤 Test INSERT en cours...');
      await _db.customStatement(
        'INSERT INTO test_sync (id, data, timestamp) VALUES (?, ?, ?)',
        [DateTime.now().millisecondsSinceEpoch, 'Test data', DateTime.now().toIso8601String()],
      );
      _addLog('✅ INSERT réussi');
    } catch (e) {
      _addLog('❌ Erreur INSERT: $e');
    }
  }

  Future<void> _testUpdate() async {
    try {
      _addLog('📤 Test UPDATE en cours...');
      await _db.customStatement(
        'UPDATE articles SET pvu1 = pvu1 + 1 WHERE designation = ?',
        ['TEST_ARTICLE'],
      );
      _addLog('✅ UPDATE réussi');
    } catch (e) {
      _addLog('❌ Erreur UPDATE: $e');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _changeCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Synchronisation Temps Réel'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Statistiques
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Changements', _changeCount.toString(), Colors.green),
                _buildStat('Logs', _logs.length.toString(), Colors.blue),
                _buildStat('Mode', _db.isNetworkMode ? 'CLIENT' : 'LOCAL', Colors.orange),
              ],
            ),
          ),

          // Boutons de test
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testInsert,
                  icon: const Icon(Icons.add),
                  label: const Text('Test INSERT'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _testUpdate,
                  icon: const Icon(Icons.edit),
                  label: const Text('Test UPDATE'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear),
                  label: const Text('Effacer Logs'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),

          const Divider(),

          // Liste des logs
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun log\n\nEffectuez une action ou attendez une synchronisation',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color color = Colors.black;
                      IconData icon = Icons.info;

                      if (log.contains('✅')) {
                        color = Colors.green;
                        icon = Icons.check_circle;
                      } else if (log.contains('❌')) {
                        color = Colors.red;
                        icon = Icons.error;
                      } else if (log.contains('🔔')) {
                        color = Colors.blue;
                        icon = Icons.notifications;
                      } else if (log.contains('📤')) {
                        color = Colors.orange;
                        icon = Icons.upload;
                      }

                      return ListTile(
                        dense: true,
                        leading: Icon(icon, color: color, size: 20),
                        title: Text(
                          log,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
