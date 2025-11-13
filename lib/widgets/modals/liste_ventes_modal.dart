import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';

class ListeVentesModal extends StatefulWidget {
  const ListeVentesModal({super.key});

  @override
  State<ListeVentesModal> createState() => _ListeVentesModalState();
}

class _ListeVentesModalState extends State<ListeVentesModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<Vente> _ventes = [];
  List<Vente> _ventesFiltered = [];
  bool _isLoading = true;

  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVentes();
  }

  Future<void> _loadVentes() async {
    try {
      final ventes = await _databaseService.database.select(_databaseService.database.ventes).get();
      setState(() {
        _ventes = ventes;
        _ventesFiltered = ventes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _filterVentes(String query) {
    setState(() {
      if (query.isEmpty) {
        _ventesFiltered = _ventes;
      } else {
        _ventesFiltered = _ventes.where((vente) {
          return (vente.numventes?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (vente.clt?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (vente.nfact?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          color: Colors.grey[100],
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Liste des Ventes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Filter section
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _filterController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher (N° Vente, Client, N° BL)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _filterVentes,
              ),
            ),

            // Data table
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
                          // Header
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
                                  flex: 2,
                                  child: Center(
                                    child: Text('N° Vente', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text('N° BL', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Text('Client', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text('Total HT', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text('Total TTC', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Data rows
                          Expanded(
                            child: _ventesFiltered.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Aucune vente trouvée',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _ventesFiltered.length,
                                    itemBuilder: (context, index) {
                                      final vente = _ventesFiltered[index];
                                      return Container(
                                        height: 35,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                          border: const Border(
                                            bottom: BorderSide(color: Colors.grey, width: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  vente.numventes ?? '',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  vente.nfact ?? '',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  vente.daty != null
                                                      ? app_date.AppDateUtils.formatDate(vente.daty!)
                                                      : '',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  vente.clt ?? '',
                                                  style: const TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(vente.totalnt ?? 0),
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(vente.totalttc ?? 0),
                                                  style: const TextStyle(fontSize: 12),
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

            // Summary section
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${_ventesFiltered.length} vente(s)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
}