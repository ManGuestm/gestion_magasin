import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class DecaissementsModal extends StatefulWidget {
  const DecaissementsModal({super.key});

  @override
  State<DecaissementsModal> createState() => _DecaissementsModalState();
}

class _DecaissementsModalState extends State<DecaissementsModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<CaisseData> _decaissements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDecaissements();
  }

  Future<void> _loadDecaissements() async {
    try {
      final caisses = await _databaseService.database.getAllCaisses();
      final decaissements = caisses.where((c) => (c.debit ?? 0) > 0).toList();
      decaissements.sort((a, b) => (b.daty ?? DateTime(0)).compareTo(a.daty ?? DateTime(0)));
      setState(() {
        _decaissements = decaissements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 15),
          ),
        );
      }
    }
  }

  double get _totalDecaissements {
    return _decaissements.fold(0.0, (sum, item) => sum + (item.debit ?? 0));
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'achat':
        return Colors.purple.shade600;
      case 'paiement fournisseur':
      case 'reg. fournisseur':
        return Colors.orange.shade600;
      case 'autre dépense':
        return Colors.red.shade600;
      case 'salaire':
        return Colors.blue.shade600;
      case 'charge':
        return Colors.brown.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _ajouterDepense() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AjouterDepenseDialog(),
    );

    if (result != null) {
      try {
        final nextRef = await _getNextRef();
        await _databaseService.database.into(_databaseService.database.caisse).insert(
              CaisseCompanion.insert(
                ref: nextRef,
                daty: drift.Value(result['daty']),
                lib: drift.Value(result['libelle']),
                debit: drift.Value(result['montant']),
                credit: const drift.Value(0.0),
                type: drift.Value(result['type']),
                verification: const drift.Value('JOURNAL'),
              ),
            );
        _loadDecaissements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dépense ajoutée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: SelectableText('Erreur: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 15),
            ),
          );
        }
      }
    }
  }

  Future<String> _getNextRef() async {
    final caisses = await _databaseService.database.getAllCaisses();
    int maxNum = 0;
    for (var caisse in caisses) {
      if (caisse.ref.startsWith('DEC')) {
        final numStr = caisse.ref.replaceAll(RegExp(r'[^0-9]'), '');
        if (numStr.isNotEmpty) {
          final num = int.tryParse(numStr) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
    }
    return 'DEC${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.7,
          maxHeight: MediaQuery.of(context).size.height * 0.95,
          minWidth: MediaQuery.of(context).size.width * 0.6,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border(bottom: BorderSide(color: Colors.red.shade200)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.money_off, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Journal des Décaissements',
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
                      Spacer(),
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_decaissements.length} décaissé(s)',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _ajouterDepense,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter Dépense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
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
                  : _decaissements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun décaissement trouvé',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Table avec bordures
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // En-tête du tableau
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        border: Border(
                                          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(7),
                                          topRight: Radius.circular(7),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Date',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'Libellé',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Type',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Montant',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Lignes du tableau
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _decaissements.length,
                                        itemBuilder: (context, index) {
                                          final decaissement = _decaissements[index];
                                          final isLast = index == _decaissements.length - 1;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                              border: isLast
                                                  ? null
                                                  : Border(
                                                      bottom: BorderSide(
                                                        color: Colors.grey.shade300,
                                                        width: 0.5,
                                                      ),
                                                    ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    decaissement.daty != null
                                                        ? DateFormat('dd/MM/yyyy').format(decaissement.daty!)
                                                        : 'N/A',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    decaissement.lib ?? 'N/A',
                                                    style: const TextStyle(fontSize: 13),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 4),
                                                      child: Text(
                                                        decaissement.type ?? 'N/A',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: _getTypeColor(decaissement.type),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    '${AppFunctions.formatNumber(decaissement.debit ?? 0)} Ar',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.red,
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
                                  ],
                                ),
                              ),
                            ),
                            // Total
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade300, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.money_off, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Total des Décaissements',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${AppFunctions.formatNumber(_totalDecaissements)} Ar',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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

class _AjouterDepenseDialog extends StatefulWidget {
  @override
  State<_AjouterDepenseDialog> createState() => _AjouterDepenseDialogState();
}

class _AjouterDepenseDialogState extends State<_AjouterDepenseDialog> {
  final _libelleController = TextEditingController();
  final _montantController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Paiement Fournisseur';

  final List<String> _types = [
    'Autre dépense',
    'Achat',
    'Paiement Fournisseur',
    'Salaire',
    'Charge',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une Dépense'),
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
                labelText: 'Type',
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
                'daty': _selectedDate,
              });
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
