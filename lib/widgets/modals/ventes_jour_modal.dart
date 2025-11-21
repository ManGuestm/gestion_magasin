import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database_service.dart';

class VentesJourModal extends StatefulWidget {
  const VentesJourModal({super.key});

  @override
  State<VentesJourModal> createState() => _VentesJourModalState();
}

class _VentesJourModalState extends State<VentesJourModal> {
  List<Map<String, dynamic>> _ventesJour = [];
  bool _isLoading = true;
  double _totalJour = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVentesJour();
  }

  Future<void> _loadVentesJour() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService().database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await db.customSelect('''
        SELECT 
          v.numventes,
          v.nfact,
          v.clt,
          v.daty,
          v.totalttc,
          v.commerc,
          v.modepai,
          v.verification
        FROM ventes v
        WHERE v.daty >= ? AND v.daty < ?
        ORDER BY v.daty DESC
      ''', variables: [
        Variable.withDateTime(startOfDay),
        Variable.withDateTime(endOfDay),
      ]).get();

      final ventes = result
          .map((row) => {
                'numventes': row.readNullable<String>('numventes'),
                'nfact': row.readNullable<String>('nfact'),
                'client': row.readNullable<String>('clt'),
                'date': row.readNullable<String>('daty'),
                'total': row.readNullable<double>('totalttc') ?? 0.0,
                'commerc': row.readNullable<String>('commerc'),
                'modepai': row.readNullable<String>('modepai'),
                'verification': row.readNullable<String>('verification'),
              })
          .toList();

      final total = ventes.fold<double>(0.0, (sum, vente) => sum + (vente['total'] as double));

      setState(() {
        _ventesJour = ventes;
        _totalJour = total;
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
                  'Ventes du Jour',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Résumé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total des ventes: ${_ventesJour.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Montant total: ${_formatNumber(_totalJour)} Ar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste des ventes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _ventesJour.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune vente effectuée aujourd\'hui',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 12,
                              columns: const [
                                DataColumn(label: Text('N° Vente')),
                                DataColumn(label: Text('Facture')),
                                DataColumn(label: Text('Client')),
                                DataColumn(label: Text('Heure')),
                                DataColumn(label: Text('Montant')),
                                DataColumn(label: Text('Mode')),
                                DataColumn(label: Text('Commercial')),
                                DataColumn(label: Text('Statut')),
                              ],
                              rows: _ventesJour.map((vente) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(vente['numventes']?.toString() ?? '')),
                                    DataCell(Text(vente['nfact']?.toString() ?? '')),
                                    DataCell(Text(vente['client']?.toString() ?? 'Client')),
                                    DataCell(Text(_formatTime(vente['date']))),
                                    DataCell(
                                      Text(
                                        '${_formatNumber(vente['total'])} Ar',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(vente['modepai']?.toString() ?? '')),
                                    DataCell(Text(vente['commerc']?.toString() ?? '')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              _getStatusColor(vente['verification']).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          vente['verification']?.toString() ?? 'BROUILLARD',
                                          style: TextStyle(
                                            color: _getStatusColor(vente['verification']),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'JOURNAL':
        return Colors.green;
      case 'BROUILLARD':
        return Colors.orange;
      case 'CONTRE_PASSE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  String _formatTime(dynamic dateValue) {
    if (dateValue == null) return '';

    DateTime date;
    if (dateValue is String) {
      try {
        date = DateTime.parse(dateValue);
      } catch (e) {
        return '';
      }
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      return '';
    }

    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
