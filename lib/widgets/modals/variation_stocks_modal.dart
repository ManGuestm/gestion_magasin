import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';

class VariationStocksModal extends StatefulWidget {
  const VariationStocksModal({super.key});

  @override
  State<VariationStocksModal> createState() => _VariationStocksModalState();
}

class _VariationStocksModalState extends State<VariationStocksModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<Stock> mouvements = [];
  List<Map<String, dynamic>> _mouvementsAvecStock = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Aujourd\'hui';

  @override
  void initState() {
    super.initState();
    _loadMouvements();
  }

  Future<void> _loadMouvements() async {
    try {
      final allStocks = await _databaseService.database.getAllStocks();
      List<Stock> filteredStocks = [];

      final now = DateTime.now();
      switch (_selectedPeriod) {
        case 'Aujourd\'hui':
          filteredStocks = allStocks
              .where((s) =>
                  s.daty != null &&
                  s.daty!.year == now.year &&
                  s.daty!.month == now.month &&
                  s.daty!.day == now.day)
              .toList();
          break;
        case 'Cette semaine':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          filteredStocks = allStocks.where((s) => s.daty != null && s.daty!.isAfter(startOfWeek)).toList();
          break;
        case 'Ce mois':
          filteredStocks = allStocks
              .where((s) => s.daty != null && s.daty!.year == now.year && s.daty!.month == now.month)
              .toList();
          break;
        default:
          filteredStocks = allStocks;
      }

      // Trier par date et calculer le stock cumulé
      filteredStocks.sort((a, b) => (a.daty ?? DateTime.now()).compareTo(b.daty ?? DateTime.now()));

      Map<String, double> stocksParArticle = {};
      List<Map<String, dynamic>> mouvementsAvecStock = [];

      for (var mouvement in filteredStocks) {
        String cle = '${mouvement.refart}_${mouvement.depots}';
        double stockActuel = stocksParArticle[cle] ?? 0.0;

        double entree = mouvement.entres ?? 0.0;
        double sortie = mouvement.sortie ?? 0.0;
        double nouveauStock = stockActuel + entree - sortie;

        stocksParArticle[cle] = nouveauStock;

        mouvementsAvecStock.add({
          'mouvement': mouvement,
          'stockDisponible': nouveauStock,
        });
      }

      setState(() {
        mouvements = filteredStocks;
        _mouvementsAvecStock = mouvementsAvecStock;
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
                      'Variation des stocks',
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
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Période: '),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    items: const [
                      DropdownMenuItem(value: 'Aujourd\'hui', child: Text('Aujourd\'hui')),
                      DropdownMenuItem(value: 'Cette semaine', child: Text('Cette semaine')),
                      DropdownMenuItem(value: 'Ce mois', child: Text('Ce mois')),
                      DropdownMenuItem(value: 'Tout', child: Text('Tout')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value ?? 'Aujourd\'hui';
                        _isLoading = true;
                      });
                      _loadMouvements();
                    },
                  ),
                ],
              ),
            ),
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
                                        child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    flex: 2,
                                    child: Center(
                                        child:
                                            Text('Article', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('Dépôt', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Entrées', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Sorties', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('Stock Dispo.',
                                            style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('CMUP', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _mouvementsAvecStock.isEmpty
                                ? const Center(child: Text('Aucun mouvement de stock pour cette période'))
                                : ListView.builder(
                                    itemCount: _mouvementsAvecStock.length,
                                    itemBuilder: (context, index) {
                                      final item = _mouvementsAvecStock[index];
                                      final mouvement = item['mouvement'] as Stock;
                                      final stockDisponible = item['stockDisponible'] as double;

                                      return Container(
                                        height: 35,
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
                                                  mouvement.daty?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  mouvement.refart ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  mouvement.depots ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(mouvement.entres ?? 0),
                                                  style: const TextStyle(fontSize: 11, color: Colors.green),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(mouvement.sortie ?? 0),
                                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  '${NumberUtils.formatNumber(stockDisponible)} ${mouvement.ue ?? ''}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: stockDisponible < 0 ? Colors.red : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(mouvement.cmup ?? 0),
                                                  style: const TextStyle(fontSize: 11),
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
