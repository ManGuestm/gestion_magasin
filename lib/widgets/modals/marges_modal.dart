import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class MargesModal extends StatefulWidget {
  const MargesModal({super.key});

  @override
  State<MargesModal> createState() => _MargesModalState();
}

class _MargesModalState extends State<MargesModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<Vente> _ventes = [];
  List<Article> _articles = [];
  bool _isLoading = true;
  String _selectedType = 'Par Articles';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ventes = await _databaseService.database.getAllVentes();
      final articles = await _databaseService.database.getAllArticles();
      setState(() {
        _ventes = ventes;
        _articles = articles;
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

  Map<String, double> _calculerMargesParArticles() {
    Map<String, double> marges = {};
    for (var article in _articles) {
      // Calcul simplifié de la marge (prix de vente - CMUP)
      double prixVente = article.pvu1 ?? 0;
      double cmup = article.cmup ?? 0;
      double marge = prixVente - cmup;
      if (prixVente > 0) {
        marges[article.designation] = (marge / prixVente) * 100;
      }
    }
    return marges;
  }

  Map<String, double> _calculerMargesParClients() {
    Map<String, double> marges = {};
    Map<String, double> totalVentes = {};
    Map<String, double> totalCouts = {};

    for (var vente in _ventes) {
      String client = vente.clt ?? 'Client inconnu';
      double montant = vente.totalttc ?? 0;
      double cout = (vente.totalnt ?? 0) * 0.7; // Estimation du coût

      totalVentes[client] = (totalVentes[client] ?? 0) + montant;
      totalCouts[client] = (totalCouts[client] ?? 0) + cout;
    }

    totalVentes.forEach((client, vente) {
      double cout = totalCouts[client] ?? 0;
      if (vente > 0) {
        marges[client] = ((vente - cout) / vente) * 100;
      }
    });

    return marges;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> marges =
        _selectedType == 'Par Articles' ? _calculerMargesParArticles() : _calculerMargesParClients();

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
                      'Marges',
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
                  const Text('Type d\'analyse: '),
                  DropdownButton<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'Par Articles', child: Text('Par Articles')),
                      DropdownMenuItem(value: 'Par Clients', child: Text('Par Clients')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value ?? 'Par Articles';
                      });
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
                              color: Colors.purple[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Text(
                                      _selectedType == 'Par Articles' ? 'Article' : 'Client',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Center(
                                    child: Text('Marge %', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const Expanded(
                                  child: Center(
                                    child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: marges.isEmpty
                                ? const Center(child: Text('Aucune donnée de marge disponible'))
                                : ListView.builder(
                                    itemCount: marges.length,
                                    itemBuilder: (context, index) {
                                      final entry = marges.entries.elementAt(index);
                                      final nom = entry.key;
                                      final marge = entry.value;

                                      Color margeColor = Colors.red;
                                      String statut = 'Faible';
                                      if (marge > 30) {
                                        margeColor = Colors.green;
                                        statut = 'Excellente';
                                      } else if (marge > 15) {
                                        margeColor = Colors.orange;
                                        statut = 'Bonne';
                                      }

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
                                              flex: 3,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  nom,
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  '${marge.toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: margeColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: margeColor,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    statut,
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
