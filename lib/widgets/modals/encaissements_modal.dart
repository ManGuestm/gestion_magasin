import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class EncaissementsModal extends StatefulWidget {
  const EncaissementsModal({super.key});

  @override
  State<EncaissementsModal> createState() => _EncaissementsModalState();
}

class _EncaissementsModalState extends State<EncaissementsModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<CaisseData> _encaissements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEncaissements();
  }

  Future<void> _loadEncaissements() async {
    try {
      final caisses = await _databaseService.database.getAllCaisses();
      final encaissements = caisses.where((c) => (c.credit ?? 0) > 0).toList();
      setState(() {
        _encaissements = encaissements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Encaissements',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _encaissements.isEmpty
                          ? const Center(
                              child: Text('Aucun encaissement trouvé'),
                            )
                          : ListView.builder(
                              itemCount: _encaissements.length,
                              itemBuilder: (context, index) {
                                final encaissement = _encaissements[index];
                                return ListTile(
                                  title: Text(encaissement.lib ?? 'N/A'),
                                  subtitle: Text('Date: ${encaissement.daty?.toString().split(' ')[0] ?? 'N/A'}'),
                                  trailing: Text(
                                    '${encaissement.credit?.toStringAsFixed(2) ?? '0.00'} Ar',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}