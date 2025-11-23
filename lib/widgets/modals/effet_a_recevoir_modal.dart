import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class EffetARecevoirModal extends StatefulWidget {
  const EffetARecevoirModal({super.key});

  @override
  State<EffetARecevoirModal> createState() => _EffetARecevoirModalState();
}

class _EffetARecevoirModalState extends State<EffetARecevoirModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Effet> _effets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEffets();
  }

  Future<void> _loadEffets() async {
    try {
      // Utiliser une requête SQL directe pour récupérer les effets
      final database = _databaseService.database;
      await database.customSelect('SELECT * FROM effets ORDER BY datechq DESC').get();

      final effetsData = await _databaseService.database.select(_databaseService.database.effets).get();
      setState(() {
        _effets = effetsData;
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

  Color _getStatutColor(String? action) {
    switch (action?.toLowerCase()) {
      case 'encaissé':
        return Colors.green;
      case 'échu':
        return Colors.red;
      case 'en cours':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
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
                      'Effet à recevoir',
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
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('N° Effet', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    flex: 2,
                                    child: Center(
                                        child: Text('Tiré', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Banque', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Montant', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('Date effet',
                                            style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Échéance', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _effets.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long, size: 64, color: Colors.green),
                                        SizedBox(height: 16),
                                        Text('Aucun effet à recevoir'),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _effets.length,
                                    itemBuilder: (context, index) {
                                      final effet = _effets[index];
                                      return Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                          border: const Border(
                                              bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  effet.ncheq ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  effet.tire ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  effet.bqtire ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(effet.montant ?? 0),
                                                  style: const TextStyle(
                                                      fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  effet.datechq?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  effet.daterecep?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getStatutColor(effet.action),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    effet.action ?? 'En cours',
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
