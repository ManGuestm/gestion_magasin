import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class TableauBordModal extends StatefulWidget {
  const TableauBordModal({super.key});

  @override
  State<TableauBordModal> createState() => _TableauBordModalState();
}

class _TableauBordModalState extends State<TableauBordModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;

  // Données du tableau de bord
  int _nombreVentes = 0;
  int _nombreAchats = 0;
  int _nombreClients = 0;
  int _nombreFournisseurs = 0;
  int _nombreArticles = 0;
  double _caTotal = 0;
  double _achatsTotal = 0;
  double _soldeCaisse = 0;
  double _soldeBanque = 0;

  @override
  void initState() {
    super.initState();
    _loadTableauBord();
  }

  Future<void> _loadTableauBord() async {
    try {
      // Charger toutes les données nécessaires
      final ventes = await _databaseService.database.getAllVentes();
      final achats = await _databaseService.database.getAllAchats();
      final clients = await _databaseService.database.getAllClients();
      final fournisseurs = await _databaseService.database.getAllFournisseurs();
      final articles = await _databaseService.database.getAllArticles();
      final caisses = await _databaseService.database.getAllCaisses();
      final banques = await _databaseService.database.getAllBanques();

      // Calculer les statistiques
      final now = DateTime.now();
      final debutMois = DateTime(now.year, now.month, 1);

      final ventesMois = ventes.where((v) => v.daty != null && v.daty!.isAfter(debutMois)).toList();
      final achatsMois = achats.where((a) => a.daty != null && a.daty!.isAfter(debutMois)).toList();

      setState(() {
        _nombreVentes = ventesMois.length;
        _nombreAchats = achatsMois.length;
        _nombreClients = clients.length;
        _nombreFournisseurs = fournisseurs.length;
        _nombreArticles = articles.length;
        _caTotal = ventesMois.fold(0.0, (sum, v) => sum + (v.totalttc ?? 0));
        _achatsTotal = achatsMois.fold(0.0, (sum, a) => sum + (a.totalttc ?? 0));
        _soldeCaisse = caisses.fold(0.0, (sum, c) => sum + ((c.credit ?? 0) - (c.debit ?? 0)));
        _soldeBanque = banques.fold(0.0, (sum, b) => sum + ((b.credit ?? 0) - (b.debit ?? 0)));
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

  Widget _buildKPI(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
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
                      'Tableau de bord',
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
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vue d\'ensemble - Ce mois',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // KPIs principaux
                          Expanded(
                            flex: 2,
                            child: GridView.count(
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                _buildKPI(
                                  'CA du mois',
                                  NumberUtils.formatNumber(_caTotal),
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                                _buildKPI(
                                  'Achats du mois',
                                  NumberUtils.formatNumber(_achatsTotal),
                                  Icons.shopping_cart,
                                  Colors.red,
                                ),
                                _buildKPI(
                                  'Solde Caisse',
                                  NumberUtils.formatNumber(_soldeCaisse),
                                  Icons.account_balance_wallet,
                                  Colors.blue,
                                ),
                                _buildKPI(
                                  'Solde Banque',
                                  NumberUtils.formatNumber(_soldeBanque),
                                  Icons.account_balance,
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            'Statistiques générales',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Statistiques générales
                          Expanded(
                            flex: 1,
                            child: GridView.count(
                              crossAxisCount: 5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                _buildKPI(
                                  'Ventes ce mois',
                                  _nombreVentes.toString(),
                                  Icons.point_of_sale,
                                  Colors.green,
                                ),
                                _buildKPI(
                                  'Achats ce mois',
                                  _nombreAchats.toString(),
                                  Icons.shopping_bag,
                                  Colors.orange,
                                ),
                                _buildKPI(
                                  'Clients',
                                  _nombreClients.toString(),
                                  Icons.people,
                                  Colors.blue,
                                ),
                                _buildKPI(
                                  'Fournisseurs',
                                  _nombreFournisseurs.toString(),
                                  Icons.business,
                                  Colors.purple,
                                ),
                                _buildKPI(
                                  'Articles',
                                  _nombreArticles.toString(),
                                  Icons.inventory_2,
                                  Colors.teal,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Résumé financier
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Marge brute estimée',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      NumberUtils.formatNumber(_caTotal - _achatsTotal),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: (_caTotal - _achatsTotal) > 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Trésorerie totale',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      NumberUtils.formatNumber(_soldeCaisse + _soldeBanque),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: (_soldeCaisse + _soldeBanque) > 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
