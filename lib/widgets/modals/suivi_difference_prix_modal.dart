import 'package:flutter/material.dart';

import '../../database/database_service.dart';

class SuiviDifferencePrixModal extends StatefulWidget {
  const SuiviDifferencePrixModal({super.key});

  @override
  State<SuiviDifferencePrixModal> createState() => _SuiviDifferencePrixModalState();
}

class _SuiviDifferencePrixModalState extends State<SuiviDifferencePrixModal> {
  List<Map<String, dynamic>> _differences = [];
  bool _isLoading = true;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _loadDifferences();
  }

  Future<void> _loadDifferences() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService().database;
      final differences = await db.getDifferencesPrixVente(_dateDebut, _dateFin);
      setState(() {
        _differences = differences;
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

  Color _getDifferenceColor(double difference) {
    if (difference > 0) return Colors.orange;
    if (difference < 0) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Suivi de différence de Prix de vente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtres de date
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateDebut ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateDebut = date);
                        _loadDifferences();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date début',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dateDebut?.toString().split(' ')[0] ?? 'Sélectionner',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateFin ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateFin = date);
                        _loadDifferences();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dateFin?.toString().split(' ')[0] ?? 'Sélectionner',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _dateDebut = null;
                      _dateFin = null;
                    });
                    _loadDifferences();
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tableau des différences
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('N° Vente')),
                          DataColumn(label: Text('Article')),
                          DataColumn(label: Text('Prix Standard')),
                          DataColumn(label: Text('Prix Vendu')),
                          DataColumn(label: Text('Différence')),
                          DataColumn(label: Text('Client')),
                        ],
                        rows: _differences.map((diff) {
                          final difference = (diff['prix_vendu'] ?? 0.0) - (diff['prix_standard'] ?? 0.0);
                          return DataRow(
                            cells: [
                              DataCell(Text(diff['date_vente']?.toString().split(' ')[0] ?? '')),
                              DataCell(Text(diff['numero_vente']?.toString() ?? '')),
                              DataCell(Text(diff['nom_article']?.toString() ?? '')),
                              DataCell(Text('${diff['prix_standard']?.toStringAsFixed(2) ?? '0.00'} €')),
                              DataCell(Text('${diff['prix_vendu']?.toStringAsFixed(2) ?? '0.00'} €')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getDifferenceColor(difference).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${difference.toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      color: _getDifferenceColor(difference),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(diff['nom_client']?.toString() ?? '')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
