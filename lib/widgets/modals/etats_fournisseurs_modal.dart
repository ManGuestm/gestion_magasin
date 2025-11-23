import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class EtatsFournisseursModal extends StatefulWidget {
  const EtatsFournisseursModal({super.key});

  @override
  State<EtatsFournisseursModal> createState() => _EtatsFournisseursModalState();
}

class _EtatsFournisseursModalState extends State<EtatsFournisseursModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Frn> _fournisseurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
  }

  Future<void> _loadFournisseurs() async {
    try {
      final fournisseurs = await _databaseService.database.getAllFournisseurs();
      setState(() {
        _fournisseurs = fournisseurs;
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
                      'États Fournisseurs',
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
                                Expanded(flex: 2, child: Center(child: Text('Raison Sociale', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Solde', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Dernière op.', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Délai', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _fournisseurs.isEmpty
                                ? const Center(child: Text('Aucun fournisseur trouvé'))
                                : ListView.builder(
                                    itemCount: _fournisseurs.length,
                                    itemBuilder: (context, index) {
                                      final fournisseur = _fournisseurs[index];
                                      return Container(
                                        height: 35,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                          border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  fournisseur.rsoc,
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  fournisseur.tel ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  fournisseur.email ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(fournisseur.soldes ?? 0),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: (fournisseur.soldes ?? 0) > 0 ? Colors.red : Colors.green,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  fournisseur.datedernop?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  '${fournisseur.delai ?? 0} j',
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