import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class ComptesFournisseursModal extends StatefulWidget {
  const ComptesFournisseursModal({super.key});

  @override
  State<ComptesFournisseursModal> createState() => _ComptesFournisseursModalState();
}

class _ComptesFournisseursModalState extends State<ComptesFournisseursModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();

  List<Comptefrn> _comptes = [];
  List<Frn> _fournisseurs = [];
  String? _selectedFournisseur;
  DateTime _dateDebut = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fournisseurs = await _databaseService.database.getAllFournisseurs();
      final comptes = await _databaseService.database.getAllComptefrns();

      setState(() {
        _fournisseurs = fournisseurs;
        _comptes = comptes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  List<Comptefrn> get _filteredComptes {
    var filtered = _comptes.where((compte) {
      final dateOk = compte.daty != null &&
          compte.daty!.isAfter(_dateDebut.subtract(const Duration(days: 1))) &&
          compte.daty!.isBefore(_dateFin.add(const Duration(days: 1)));

      final fournisseurOk = _selectedFournisseur == null || compte.frns == _selectedFournisseur;

      return dateOk && fournisseurOk;
    }).toList();

    filtered.sort((a, b) => (b.daty ?? DateTime.now()).compareTo(a.daty ?? DateTime.now()));
    return filtered;
  }

  double get _soldeTotal {
    return _filteredComptes.fold(0.0, (sum, compte) => sum + (compte.solde ?? 0));
  }

  double get _totalEntrees {
    return _filteredComptes.fold(0.0, (sum, compte) => sum + (compte.entres ?? 0));
  }

  double get _totalSorties {
    return _filteredComptes.fold(0.0, (sum, compte) => sum + (compte.sortie ?? 0));
  }

  Future<void> _selectDate(bool isDebut) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : _dateFin,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = date;
        } else {
          _dateFin = date;
        }
      });
    }
  }

  Future<void> _exportData() async {
    // TODO: Implémenter l'export CSV/Excel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export en cours de développement')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: 1200,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Comptes Fournisseurs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Filtres
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  // Sélection fournisseur
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedFournisseur,
                      decoration: const InputDecoration(
                        labelText: 'Fournisseur',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tous les fournisseurs'),
                        ),
                        ..._fournisseurs.map((frn) => DropdownMenuItem<String>(
                              value: frn.rsoc,
                              child: Text(frn.rsoc),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFournisseur = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Date début
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date début',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(app_date.AppDateUtils.formatDate(_dateDebut)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Date fin
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date fin',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(app_date.AppDateUtils.formatDate(_dateFin)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Bouton export
                  ElevatedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.download),
                    label: const Text('Exporter'),
                  ),
                ],
              ),
            ),

            // Résumé
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard('Total Entrées', _totalEntrees, Colors.green),
                  _buildSummaryCard('Total Sorties', _totalSorties, Colors.red),
                  _buildSummaryCard('Solde Total', _soldeTotal, Colors.blue),
                  _buildSummaryCard('Nb Opérations', _filteredComptes.length.toDouble(), Colors.orange),
                ],
              ),
            ),

            // Table des comptes
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    // En-tête du tableau
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 2,
                              child: Text('Fournisseur', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 2, child: Text('Libellé', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 1,
                              child: Text('N° Achat', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 1, child: Text('Entrées', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 1, child: Text('Sorties', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 1, child: Text('Solde', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),

                    // Contenu du tableau
                    Expanded(
                      child: _filteredComptes.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucune opération trouvée',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredComptes.length,
                              itemBuilder: (context, index) {
                                final compte = _filteredComptes[index];
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          compte.daty != null
                                              ? app_date.AppDateUtils.formatDate(compte.daty!)
                                              : '',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          compte.frns ?? '',
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          compte.lib ?? '',
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          compte.numachats ?? '',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          NumberUtils.formatNumber(compte.entres ?? 0),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: (compte.entres ?? 0) > 0 ? Colors.green : Colors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          NumberUtils.formatNumber(compte.sortie ?? 0),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: (compte.sortie ?? 0) > 0 ? Colors.red : Colors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          NumberUtils.formatNumber(compte.solde ?? 0),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: (compte.solde ?? 0) >= 0 ? Colors.green : Colors.red,
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
          ],
        ),
      ),
    ),);
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title == 'Nb Opérations' ? value.toInt().toString() : NumberUtils.formatNumber(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
