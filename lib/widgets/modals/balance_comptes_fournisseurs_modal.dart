import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_service.dart';
import '../../database/database.dart';
import '../common/base_modal.dart';
import '../common/data_table_widget.dart';
import '../common/date_picker_field.dart';

class BalanceComptesFournisseursModal extends StatefulWidget {
  const BalanceComptesFournisseursModal({super.key});

  @override
  State<BalanceComptesFournisseursModal> createState() => _BalanceComptesFournisseursModalState();
}

class _BalanceComptesFournisseursModalState extends State<BalanceComptesFournisseursModal> {
  List<Map<String, dynamic>> _balances = [];
  bool _isLoading = false;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _selectedFournisseur;
  List<Frn> _fournisseurs = [];
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
    _loadBalances();
  }

  Future<void> _loadFournisseurs() async {
    try {
      final fournisseurs = await DatabaseService().database.getAllFournisseurs();
      setState(() => _fournisseurs = fournisseurs);
    } catch (e) {
      debugPrint('Erreur chargement fournisseurs: $e');
    }
  }

  Future<void> _loadBalances() async {
    setState(() => _isLoading = true);
    try {
      final balances = await _calculateBalances();
      setState(() {
        _balances = balances;
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

  Future<List<Map<String, dynamic>>> _calculateBalances() async {
    final db = DatabaseService().database;
    List<Map<String, dynamic>> balances = [];

    // Récupérer tous les fournisseurs ou le fournisseur sélectionné
    List<Frn> fournisseursToProcess = _selectedFournisseur != null
        ? _fournisseurs.where((f) => f.rsoc == _selectedFournisseur).toList()
        : _fournisseurs;

    for (final fournisseur in fournisseursToProcess) {
      // Calculer les mouvements du compte fournisseur
      String whereClause = 'WHERE frns = ?';
      List<dynamic> params = [fournisseur.rsoc];

      if (_dateDebut != null) {
        whereClause += ' AND daty >= ?';
        params.add(_dateDebut!.toIso8601String());
      }

      if (_dateFin != null) {
        whereClause += ' AND daty <= ?';
        params.add(_dateFin!.toIso8601String());
      }

      final result = await db.customSelect(
        '''
        SELECT 
          frns,
          COALESCE(SUM(entres), 0) as total_entrees,
          COALESCE(SUM(sortie), 0) as total_sorties,
          COALESCE(SUM(entres - sortie), 0) as solde
        FROM comptefrns 
        $whereClause
        GROUP BY frns
        ''',
        variables: params.map((p) => Variable(p)).toList(),
      ).getSingleOrNull();

      double totalEntrees = result?.read<double>('total_entrees') ?? 0.0;
      double totalSorties = result?.read<double>('total_sorties') ?? 0.0;
      double solde = result?.read<double>('solde') ?? 0.0;

      // Si aucun mouvement trouvé, utiliser le solde initial du fournisseur
      if (result == null) {
        solde = fournisseur.soldes ?? 0.0;
      }

      balances.add({
        'fournisseur': fournisseur.rsoc,
        'solde_initial': fournisseur.soldes ?? 0.0,
        'total_entrees': totalEntrees,
        'total_sorties': totalSorties,
        'solde_final': solde,
        'nif': fournisseur.nif ?? '',
        'telephone': fournisseur.tel ?? '',
        'email': fournisseur.email ?? '',
      });
    }

    // Trier par solde décroissant
    balances.sort((a, b) => (b['solde_final'] as double).compareTo(a['solde_final'] as double));

    return balances;
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Balance des Comptes Fournisseurs',
      width: 1200,
      height: 700,
      content: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: const Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DatePickerField(
                        controller: _dateDebutController,
                        label: 'Date début',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DatePickerField(
                        controller: _dateFinController,
                        label: 'Date fin',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Fournisseur',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedFournisseur,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tous les fournisseurs'),
                          ),
                          ..._fournisseurs.map((f) => DropdownMenuItem<String>(
                            value: f.rsoc,
                            child: Text(f.rsoc),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedFournisseur = value);
                          _loadBalances();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadBalances,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _exportToExcel,
                      icon: const Icon(Icons.file_download),
                      label: const Text('Exporter'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tableau des balances
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DataTableWidget<Map<String, dynamic>>(
                    headers: const [
                      'Fournisseur',
                      'NIF',
                      'Téléphone',
                      'Solde Initial',
                      'Total Entrées',
                      'Total Sorties',
                      'Solde Final',
                    ],
                    items: _balances,
                    rowBuilder: (balance, isSelected) => [
                      Expanded(child: Text(balance['fournisseur'], style: TextStyle(fontSize: 11))),
                      Expanded(child: Text(balance['nif'], style: TextStyle(fontSize: 11))),
                      Expanded(child: Text(balance['telephone'], style: TextStyle(fontSize: 11))),
                      Expanded(child: Text('${_formatNumber(balance['solde_initial'])} Ar', style: TextStyle(fontSize: 11))),
                      Expanded(child: Text('${_formatNumber(balance['total_entrees'])} Ar', style: TextStyle(fontSize: 11))),
                      Expanded(child: Text('${_formatNumber(balance['total_sorties'])} Ar', style: TextStyle(fontSize: 11))),
                      Expanded(
                        child: Text(
                          '${_formatNumber(balance['solde_final'])} Ar',
                          style: TextStyle(
                            fontSize: 11,
                            color: balance['solde_final'] > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    onItemSelected: (balance) => _showBalanceDetails(balance),
                  ),
          ),

          // Totaux
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: const Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Total Soldes: ${_formatNumber(_balances.fold(0.0, (sum, b) => sum + b['solde_final']))} Ar',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Nombre de fournisseurs: ${_balances.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    return NumberFormat('#,##0.00', 'fr_FR').format(number);
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export Excel non implémenté')),
    );
  }

  void _showBalanceDetails(Map<String, dynamic> balance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${balance['fournisseur']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NIF: ${balance['nif']}'),
            Text('Téléphone: ${balance['telephone']}'),
            Text('Email: ${balance['email']}'),
            const Divider(),
            Text('Solde initial: ${_formatNumber(balance['solde_initial'])} Ar'),
            Text('Total entrées: ${_formatNumber(balance['total_entrees'])} Ar'),
            Text('Total sorties: ${_formatNumber(balance['total_sorties'])} Ar'),
            Text(
              'Solde final: ${_formatNumber(balance['solde_final'])} Ar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: balance['solde_final'] > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}