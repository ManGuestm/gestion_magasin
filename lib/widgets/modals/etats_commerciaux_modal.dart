import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';

class EtatsCommerciauxModal extends StatefulWidget {
  const EtatsCommerciauxModal({super.key});

  @override
  State<EtatsCommerciauxModal> createState() => _EtatsCommerciauxModalState();
}

class _EtatsCommerciauxModalState extends State<EtatsCommerciauxModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<ComData> _commerciaux = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommerciaux();
  }

  Future<void> _loadCommerciaux() async {
    try {
      final commerciaux = await _databaseService.database.getAllCommerciaux();
      setState(() {
        _commerciaux = commerciaux;
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
                      'États Commerciaux',
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
                              color: Colors.blue[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: Center(child: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(flex: 2, child: Center(child: Text('Adresse', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Solde', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Taux %', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _commerciaux.isEmpty
                                ? const Center(child: Text('Aucun commercial trouvé'))
                                : ListView.builder(
                                    itemCount: _commerciaux.length,
                                    itemBuilder: (context, index) {
                                      final commercial = _commerciaux[index];
                                      return Container(
                                        height: 40,
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
                                                  commercial.nom,
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  commercial.adr ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  commercial.tel ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  commercial.email ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(commercial.soldes ?? 0),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: (commercial.soldes ?? 0) > 0 ? Colors.green : Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  '${commercial.taux?.toStringAsFixed(1) ?? '0.0'}%',
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