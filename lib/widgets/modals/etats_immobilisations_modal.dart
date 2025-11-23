import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class EtatsImmobilisationsModal extends StatefulWidget {
  const EtatsImmobilisationsModal({super.key});

  @override
  State<EtatsImmobilisationsModal> createState() => _EtatsImmobilisationsModalState();
}

class _EtatsImmobilisationsModalState extends State<EtatsImmobilisationsModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<EmbData> _immobilisations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImmobilisations();
  }

  Future<void> _loadImmobilisations() async {
    try {
      final database = _databaseService.database;
      final immobilisations = await database.customSelect('SELECT * FROM emb ORDER BY daty DESC').get();

      setState(() {
        _immobilisations = immobilisations
            .map((row) => EmbData(
                  designation: row.data['designation'] as String,
                  vo: row.data['vo'] as double?,
                  action: row.data['action'] as String?,
                  categorie: row.data['categorie'] as String?,
                  amt: row.data['amt'] as double?,
                  daty: row.data['daty'] != null ? DateTime.parse(row.data['daty'] as String) : null,
                  description: row.data['description'] as String?,
                  taux: row.data['taux'] as double?,
                ))
            .toList();
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
                      'États Immobilisations',
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
                              color: Colors.brown[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Center(
                                        child: Text('Désignation',
                                            style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('Catégorie',
                                            style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('Date acq.',
                                            style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('V.O.', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Amort.', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Taux %', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Action', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _immobilisations.isEmpty
                                ? const Center(child: Text('Aucune immobilisation trouvée'))
                                : ListView.builder(
                                    itemCount: _immobilisations.length,
                                    itemBuilder: (context, index) {
                                      final immobilisation = _immobilisations[index];
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
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  immobilisation.designation,
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  immobilisation.categorie ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  immobilisation.daty?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(immobilisation.vo ?? 0),
                                                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(immobilisation.amt ?? 0),
                                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  '${immobilisation.taux?.toStringAsFixed(1) ?? '0.0'}%',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  immobilisation.action ?? 'N/A',
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
