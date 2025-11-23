import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class DecaissementsModal extends StatefulWidget {
  const DecaissementsModal({super.key});

  @override
  State<DecaissementsModal> createState() => _DecaissementsModalState();
}

class _DecaissementsModalState extends State<DecaissementsModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<CaisseData> _decaissements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDecaissements();
  }

  Future<void> _loadDecaissements() async {
    try {
      final caisses = await _databaseService.database.getAllCaisses();
      final decaissements = caisses.where((c) => (c.debit ?? 0) > 0).toList();
      setState(() {
        _decaissements = decaissements;
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
                      'Décaissements',
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
                      child: _decaissements.isEmpty
                          ? const Center(
                              child: Text('Aucun décaissement trouvé'),
                            )
                          : ListView.builder(
                              itemCount: _decaissements.length,
                              itemBuilder: (context, index) {
                                final decaissement = _decaissements[index];
                                return Focus(
                                  autofocus: true,
                                  onKeyEvent: (node, event) => handleTabNavigation(event),
                                  child: ListTile(
                                    title: Text(decaissement.lib ?? 'N/A'),
                                    subtitle:
                                        Text('Date: ${decaissement.daty?.toString().split(' ')[0] ?? 'N/A'}'),
                                    trailing: Text(
                                      '${decaissement.debit?.toStringAsFixed(2) ?? '0.00'} Ar',
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
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
