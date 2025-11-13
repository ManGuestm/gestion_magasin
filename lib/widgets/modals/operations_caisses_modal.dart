import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';

class OperationsCaissesModal extends StatefulWidget {
  const OperationsCaissesModal({super.key});

  @override
  State<OperationsCaissesModal> createState() => _OperationsCaissesModalState();
}

class _OperationsCaissesModalState extends State<OperationsCaissesModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<CaisseData> _operations = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Aujourd\'hui';

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  Future<void> _loadOperations() async {
    try {
      final allCaisses = await _databaseService.database.getAllCaisses();
      List<CaisseData> filteredOperations = [];
      
      final now = DateTime.now();
      switch (_selectedPeriod) {
        case 'Aujourd\'hui':
          filteredOperations = allCaisses.where((c) => 
            c.daty != null && 
            c.daty!.year == now.year && 
            c.daty!.month == now.month && 
            c.daty!.day == now.day
          ).toList();
          break;
        case 'Cette semaine':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          filteredOperations = allCaisses.where((c) => 
            c.daty != null && c.daty!.isAfter(startOfWeek)
          ).toList();
          break;
        case 'Ce mois':
          filteredOperations = allCaisses.where((c) => 
            c.daty != null && 
            c.daty!.year == now.year && 
            c.daty!.month == now.month
          ).toList();
          break;
        default:
          filteredOperations = allCaisses;
      }
      
      setState(() {
        _operations = filteredOperations;
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

  double _getTotalDebit() => _operations.fold(0.0, (sum, op) => sum + (op.debit ?? 0));
  double _getTotalCredit() => _operations.fold(0.0, (sum, op) => sum + (op.credit ?? 0));
  double _getSoldeActuel() => _getTotalCredit() - _getTotalDebit();

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
                      'Opérations Caisses',
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                          _loadOperations();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Débits: ${NumberUtils.formatNumber(_getTotalDebit())}', 
                               style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Crédits: ${NumberUtils.formatNumber(_getTotalCredit())}', 
                               style: const TextStyle(fontSize: 12, color: Colors.green)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Solde: ${NumberUtils.formatNumber(_getSoldeActuel())}', 
                               style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
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
                              color: Colors.orange[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(child: Center(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(flex: 2, child: Center(child: Text('Libellé', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('Solde', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _operations.isEmpty
                                ? const Center(child: Text('Aucune opération pour cette période'))
                                : ListView.builder(
                                    itemCount: _operations.length,
                                    itemBuilder: (context, index) {
                                      final operation = _operations[index];
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
                                                  operation.daty?.toString().split(' ')[0] ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  operation.lib ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  operation.type ?? 'N/A',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(operation.debit ?? 0),
                                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(operation.credit ?? 0),
                                                  style: const TextStyle(fontSize: 11, color: Colors.green),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  NumberUtils.formatNumber(operation.soldes ?? 0),
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