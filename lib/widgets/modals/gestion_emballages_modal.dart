import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';

class GestionEmballagesModal extends StatefulWidget {
  const GestionEmballagesModal({super.key});

  @override
  State<GestionEmballagesModal> createState() => _GestionEmballagesModalState();
}

class _GestionEmballagesModalState extends State<GestionEmballagesModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<EmblcltData> _emballages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmballages();
  }

  Future<void> _loadEmballages() async {
    try {
      // Utiliser une requête SQL directe pour récupérer les emballages clients
      final database = _databaseService.database;
      final emballages = await database.customSelect('SELECT * FROM emblclt ORDER BY daty DESC').get();
      
      setState(() {
        _emballages = emballages.map((row) => EmblcltData(
          num: row.data['num'] as int? ?? 0,
          numventes: row.data['numventes'] as String?,
          nfact: row.data['nfact'] as String?,
          daty: row.data['daty'] != null ? DateTime.parse(row.data['daty'] as String) : null,
          clt: row.data['clt'] as String?,
          emb: row.data['emb'] as String?,
          q: row.data['q'] as double?,
          verification: row.data['verification'] as String?,
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
        width: MediaQuery.of(context).size.width * 0.9,
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
                      'Gestion Emballages',
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
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(child: Center(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('N° Vente', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(flex: 2, child: Center(child: Text('Client', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Emballage', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Quantité', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _emballages.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inventory, size: 64, color: Colors.green),
                                        SizedBox(height: 16),
                                        Text('Aucun emballage enregistré'),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _emballages.length,
                                    itemBuilder: (context, index) {
                                      final emballage = _emballages[index];
                                      return Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                          border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  emballage.daty?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  emballage.numventes ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  emballage.clt ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  emballage.emb ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(emballage.q ?? 0),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: emballage.verification == 'OK' ? Colors.green : Colors.orange,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    emballage.verification ?? 'En cours',
                                                    style: const TextStyle(fontSize: 9, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}