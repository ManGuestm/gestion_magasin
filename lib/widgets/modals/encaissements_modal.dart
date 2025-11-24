import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class EncaissementsModal extends StatefulWidget {
  const EncaissementsModal({super.key});

  @override
  State<EncaissementsModal> createState() => _EncaissementsModalState();
}

class _EncaissementsModalState extends State<EncaissementsModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<CaisseData> _encaissements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEncaissements();
  }

  Future<void> _loadEncaissements() async {
    try {
      final caisses = await _databaseService.database.getAllCaisses();
      final encaissements = caisses.where((c) => (c.debit ?? 0) > 0).toList();
      encaissements.sort((a, b) => (b.daty ?? DateTime(0)).compareTo(a.daty ?? DateTime(0)));
      setState(() {
        _encaissements = encaissements;
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

  String _formatNumber(double number) {
    return NumberFormat('#,##0.00', 'fr_FR').format(number);
  }

  double get _totalEncaissements {
    return _encaissements.fold(0.0, (sum, item) => sum + (item.debit ?? 0));
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'vente':
        return Colors.blue.shade600;
      case 'reg. client':
        return Colors.orange.shade600;
      case 'autre revenu':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _ajouterRevenu() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AjouterRevenuDialog(),
    );

    if (result != null) {
      try {
        final nextRef = await _getNextRef();
        await _databaseService.database.into(_databaseService.database.caisse).insert(
              CaisseCompanion.insert(
                ref: nextRef,
                daty: drift.Value(result['date']),
                lib: drift.Value(result['libelle']),
                debit: drift.Value(result['montant']),
                credit: const drift.Value(0.0),
                type: drift.Value(result['type']),
                verification: const drift.Value('JOURNAL'),
              ),
            );
        _loadEncaissements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Revenu ajouté avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<String> _getNextRef() async {
    final caisses = await _databaseService.database.getAllCaisses();
    int maxNum = 0;
    for (var caisse in caisses) {
      final num = int.tryParse(caisse.ref.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (num > maxNum) maxNum = num;
    }
    return 'ENC${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(bottom: BorderSide(color: Colors.green.shade200)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Journal des Encaissements',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_encaissements.length} entrées',
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _ajouterRevenu,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter Revenu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _encaissements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun encaissement trouvé',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // En-têtes du tableau
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 3,
                                      child: Text('Libellé', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Montant',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.right)),
                                ],
                              ),
                            ),
                            // Lignes du tableau
                            Expanded(
                              child: ListView.builder(
                                itemCount: _encaissements.length,
                                itemBuilder: (context, index) {
                                  final encaissement = _encaissements[index];
                                  final isEven = index % 2 == 0;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isEven ? Colors.white : Colors.grey.shade50,
                                      border:
                                          Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            encaissement.daty != null
                                                ? DateFormat('dd/MM/yyyy').format(encaissement.daty!)
                                                : 'N/A',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            encaissement.lib ?? 'N/A',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getTypeColor(encaissement.type),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              encaissement.type ?? 'N/A',
                                              style: const TextStyle(fontSize: 11, color: Colors.white),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${_formatNumber(encaissement.debit ?? 0)} Ar',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Total
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border(top: BorderSide(color: Colors.green.shade200, width: 2)),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Total des Encaissements',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    '${_formatNumber(_totalEncaissements)} Ar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AjouterRevenuDialog extends StatefulWidget {
  @override
  State<_AjouterRevenuDialog> createState() => _AjouterRevenuDialogState();
}

class _AjouterRevenuDialogState extends State<_AjouterRevenuDialog> {
  final _libelleController = TextEditingController();
  final _montantController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Autres encaissements';

  final List<String> _types = ['Autres encaissements', 'Repport à nouveau'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un Revenu'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _libelleController,
              decoration: const InputDecoration(
                labelText: 'Libellé',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Catégories',
                border: OutlineInputBorder(),
              ),
              items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montantController,
              decoration: const InputDecoration(
                labelText: 'Montant',
                border: OutlineInputBorder(),
                suffixText: 'Ar',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_libelleController.text.isNotEmpty && _montantController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'libelle': _libelleController.text,
                'type': _selectedType,
                'montant': double.tryParse(_montantController.text) ?? 0.0,
                'date': _selectedDate,
              });
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
