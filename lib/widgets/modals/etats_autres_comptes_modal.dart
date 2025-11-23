import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class EtatsAutresComptesModal extends StatefulWidget {
  const EtatsAutresComptesModal({super.key});

  @override
  State<EtatsAutresComptesModal> createState() => _EtatsAutresComptesModalState();
}

class _EtatsAutresComptesModalState extends State<EtatsAutresComptesModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<AutrescompteData> _comptes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComptes();
  }

  Future<void> _loadComptes() async {
    try {
      final comptes = await _databaseService.database.getAllAutrescomptes();
      setState(() {
        _comptes = comptes;
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
                      'États Autres Comptes',
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
                              color: Colors.teal[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(child: Center(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(flex: 2, child: Center(child: Text('Libellé', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Code', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Compte', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Entrées', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Sorties', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Solde', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _comptes.isEmpty
                                ? const Center(child: Text('Aucun autre compte trouvé'))
                                : ListView.builder(
                                    itemCount: _comptes.length,
                                    itemBuilder: (context, index) {
                                      final compte = _comptes[index];
                                      return Container(
                                        height: 35,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                          border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  compte.daty?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  compte.lib ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  compte.code ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  compte.compte ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(compte.entres ?? 0),
                                                  style: const TextStyle(fontSize: 11, color: Colors.green),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(compte.sortie ?? 0),
                                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(compte.solde ?? 0),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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