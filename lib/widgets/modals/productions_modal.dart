import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';

class ProductionsModal extends StatefulWidget {
  const ProductionsModal({super.key});

  @override
  State<ProductionsModal> createState() => _ProductionsModalState();
}

class _ProductionsModalState extends State<ProductionsModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<ProdData> _productions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductions();
  }

  Future<void> _loadProductions() async {
    try {
      // Utiliser une requête SQL directe pour récupérer les productions
      final database = _databaseService.database;
      final productions = await database.customSelect('SELECT * FROM prod ORDER BY soc_daty DESC').get();
      
      setState(() {
        _productions = productions.map((row) => ProdData(
          num: row.data['num'] as int? ?? 0,
          numaprod: row.data['numaprod'] as String?,
          obs: row.data['obs'] as String?,
          socDaty: row.data['soc_daty'] != null ? DateTime.parse(row.data['soc_daty'] as String) : null,
          produits: row.data['produits'] as String?,
          depot: row.data['depot'] as String?,
          cte: row.data['cte'] as String?,
          totalttc: row.data['totalttc'] as double?,
          cmup: row.data['cmup'] as double?,
          verification: row.data['verification'] as String?,
          type: row.data['type'] as String?,
          unite: row.data['unite'] as String?,
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
                      'Productions',
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
                              color: Colors.orange[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(child: Center(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('N° Prod.', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(flex: 2, child: Center(child: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Dépôt', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Total TTC', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _productions.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.precision_manufacturing, size: 64, color: Colors.orange),
                                        SizedBox(height: 16),
                                        Text('Aucune production enregistrée'),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _productions.length,
                                    itemBuilder: (context, index) {
                                      final production = _productions[index];
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
                                                  production.socDaty?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  production.numaprod ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  production.produits ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  production.depot ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(production.totalttc ?? 0),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  production.type ?? 'N/A',
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