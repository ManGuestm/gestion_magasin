import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class TransfertMarchandisesModal extends StatefulWidget {
  const TransfertMarchandisesModal({super.key});

  @override
  State<TransfertMarchandisesModal> createState() => _TransfertMarchandisesModalState();
}

class _TransfertMarchandisesModalState extends State<TransfertMarchandisesModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<TransfData> _transferts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransferts();
  }

  Future<void> _loadTransferts() async {
    try {
      // Utiliser une requête SQL directe pour récupérer les transferts
      final database = _databaseService.database;
      final transferts = await database.customSelect('SELECT * FROM transf ORDER BY daty DESC').get();
      
      setState(() {
        _transferts = transferts.map((row) => TransfData(
          num: row.data['num'] as int? ?? 0,
          numtransf: row.data['numtransf'] as String?,
          daty: row.data['daty'] != null ? DateTime.parse(row.data['daty'] as String) : null,
          de: row.data['de'] as String?,
          au: row.data['au'] as String?,
          contre: row.data['contre'] as String?,
        )).toList();
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
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
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
                      'Transfert de Marchandises',
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
                      child: _transferts.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.swap_horiz, size: 64, color: Colors.blue),
                                  SizedBox(height: 16),
                                  Text('Aucun transfert enregistré'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _transferts.length,
                              itemBuilder: (context, index) {
                                final transfert = _transferts[index];
                                return ListTile(
                                  leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                                  title: Text('N° ${transfert.numtransf ?? 'N/A'}'),
                                  subtitle: Text(
                                    'De: ${transfert.de ?? 'N/A'} vers ${transfert.au ?? 'N/A'}\n'
                                    'Date: ${transfert.daty?.toString().split(' ')[0] ?? 'N/A'}',
                                  ),
                                  trailing: transfert.contre != null
                                      ? Chip(
                                          label: Text(transfert.contre!),
                                          backgroundColor: Colors.blue[100],
                                        )
                                      : null,
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