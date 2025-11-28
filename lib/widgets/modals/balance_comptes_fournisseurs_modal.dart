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
      child: Column(
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
                        label: 'Date début',
                        selectedDate: _dateDebut,
                        onDateSelected: (date) {
                          setState(() => _dateDebut = date);
                          _loadBalances();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DatePickerField(
                        label: 'Date fin',
                        selectedDate: _dateFin,
                        onDateSelected: (date) {
                          setState(() => _dateFin = date);
                          _loadBalances();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Fournisseur',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedFournisseur,
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
                    data: _balances,
                    columns: const [
                      DataColumn(label: Text('Fournisseur')),
                      DataColumn(label: Text('NIF')),
                      DataColumn(label: Text('Téléphone')),
                      DataColumn(label: Text('Solde Initial')),
                      DataColumn(label: Text('Total Entrées')),
                      DataColumn(label: Text('Total Sorties')),
                      DataColumn(label: Text('Solde Final')),
                    ],
                    buildRow: (balance) => DataRow(
                      cells: [
                        DataCell(Text(balance['fournisseur'])),
                        DataCell(Text(balance['nif'])),
                        DataCell(Text(balance['telephone'])),
                        DataCell(Text('${_formatNumber(balance['solde_initial'])} Ar')),
                        DataCell(Text('${_formatNumber(balance['total_entrees'])} Ar')),
                        DataCell(Text('${_formatNumber(balance['total_sorties'])} Ar')),
                        DataCell(
                          Text(
                            '${_formatNumber(balance['solde_final'])} Ar',
                            style: TextStyle(
                              color: balance['solde_final'] > 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onRowTap: (balance) => _showBalanceDetails(balance),
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
                _buildTotalCard('Nombre de fournisseurs', '${_balances.length}'),
                _buildTotalCard('Total Entrées', '${_formatNumber(_calculateTotalEntrees())} Ar'),
                _buildTotalCard('Total Sorties', '${_formatNumber(_calculateTotalSorties())} Ar'),
                _buildTotalCard('Solde Global', '${_formatNumber(_calculateSoldeGlobal())} Ar'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showBalanceDetails(Map<String, dynamic> balance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${balance['fournisseur']}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Fournisseur:', balance['fournisseur']),
              _buildDetailRow('NIF:', balance['nif']),
              _buildDetailRow('Téléphone:', balance['telephone']),
              _buildDetailRow('Email:', balance['email']),
              const Divider(),
              _buildDetailRow('Solde initial:', '${_formatNumber(balance['solde_initial'])} Ar'),
              _buildDetailRow('Total entrées:', '${_formatNumber(balance['total_entrees'])} Ar'),
              _buildDetailRow('Total sorties:', '${_formatNumber(balance['total_sorties'])} Ar'),
              _buildDetailRow('Solde final:', '${_formatNumber(balance['solde_final'])} Ar'),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  double _calculateTotalEntrees() {
    return _balances.fold(0.0, (sum, b) => sum + (b['total_entrees'] as double));
  }

  double _calculateTotalSorties() {
    return _balances.fold(0.0, (sum, b) => sum + (b['total_sorties'] as double));
  }

  double _calculateSoldeGlobal() {
    return _balances.fold(0.0, (sum, b) => sum + (b['solde_final'] as double));
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export Excel en cours de développement')),
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}