import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/base_modal.dart';
import '../common/data_table_widget.dart';
import '../common/date_picker_field.dart';

class BalanceComptesClientsModal extends StatefulWidget {
  const BalanceComptesClientsModal({super.key});

  @override
  State<BalanceComptesClientsModal> createState() => _BalanceComptesClientsModalState();
}

class _BalanceComptesClientsModalState extends State<BalanceComptesClientsModal> {
  List<Map<String, dynamic>> _balances = [];
  bool _isLoading = false;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _selectedClient;
  List<CltData> _clients = [];
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadBalances();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await DatabaseService().database.getActiveClients();
      setState(() => _clients = clients);
    } catch (e) {
      debugPrint('Erreur chargement clients: $e');
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _calculateBalances() async {
    final db = DatabaseService().database;
    List<Map<String, dynamic>> balances = [];

    List<CltData> clientsToProcess = _selectedClient != null
        ? _clients.where((c) => c.rsoc == _selectedClient).toList()
        : _clients;

    for (final client in clientsToProcess) {
      String whereClause = 'WHERE clt = ?';
      List<dynamic> params = [client.rsoc];

      if (_dateDebut != null) {
        whereClause += ' AND daty >= ?';
        params.add(_dateDebut!.toIso8601String());
      }

      if (_dateFin != null) {
        whereClause += ' AND daty <= ?';
        params.add(_dateFin!.toIso8601String());
      }

      final result = await db.customSelect('''
        SELECT 
          clt,
          COALESCE(SUM(entres), 0) as total_entrees,
          COALESCE(SUM(sorties), 0) as total_sorties,
          COALESCE(SUM(entres - sorties), 0) as solde
        FROM compteclt 
        $whereClause
        GROUP BY clt
        ''', variables: params.map((p) => Variable(p)).toList()).getSingleOrNull();

      double totalEntrees = result?.read<double>('total_entrees') ?? 0.0;
      double totalSorties = result?.read<double>('total_sorties') ?? 0.0;
      double solde = result?.read<double>('solde') ?? 0.0;

      if (result == null) {
        solde = client.soldes ?? 0.0;
      }

      balances.add({
        'client': client.rsoc,
        'solde_initial': client.soldes ?? 0.0,
        'total_entrees': totalEntrees,
        'total_sorties': totalSorties,
        'solde_final': solde,
        'nif': client.nif ?? '',
        'telephone': client.tel ?? '',
        'email': client.email ?? '',
      });
    }

    balances.sort((a, b) => (b['solde_final'] as double).compareTo(a['solde_final'] as double));
    return balances;
  }

  String _formatNumber(double number) {
    return NumberFormat('#,##0.00', 'fr_FR').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Balance des Comptes Clients',
      width: 1200,
      height: 700,
      content: Column(
        children: [
          // En-tête avec statistiques
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Statistiques rapides
                Row(
                  children: [
                    _buildStatCard('Clients', _balances.length.toString(), Icons.people, Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Débiteurs',
                      _balances.where((b) => b['solde_final'] > 0).length.toString(),
                      Icons.trending_up,
                      Colors.red,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Créditeurs',
                      _balances.where((b) => b['solde_final'] < 0).length.toString(),
                      Icons.trending_down,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Solde Total',
                      '${_formatNumber(_balances.fold(0.0, (sum, b) => sum + b['solde_final']))} Ar',
                      Icons.account_balance,
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filtres
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.filter_list, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Filtres',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DatePickerField(controller: _dateDebutController, label: 'Date début'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DatePickerField(controller: _dateFinController, label: 'Date fin'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Client spécifique',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
                              ),
                              initialValue: _selectedClient,
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('Tous les clients')),
                                ..._clients.map(
                                  (c) => DropdownMenuItem<String>(value: c.rsoc, child: Text(c.rsoc)),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedClient = value);
                                _loadBalances();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loadBalances,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tableau des balances
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Calcul des balances...'),
                        ],
                      ),
                    )
                  : _balances.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune balance trouvée',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Modifiez les filtres pour voir les données',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : DataTableWidget<Map<String, dynamic>>(
                      headers: const [
                        'Client',
                        'NIF',
                        'Téléphone',
                        'Solde Initial',
                        'Total Entrées',
                        'Total Sorties',
                        'Solde Final',
                      ],
                      items: _balances,
                      rowBuilder: (balance, isSelected) => [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: balance['solde_final'] > 0 ? Colors.red : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  balance['client'],
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            balance['nif'] ?? '-',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              if (balance['telephone'] != null && balance['telephone'].isNotEmpty) ...[
                                Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  balance['telephone'] ?? '-',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${_formatNumber(balance['solde_initial'])} Ar',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${_formatNumber(balance['total_entrees'])} Ar',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${_formatNumber(balance['total_sorties'])} Ar',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: balance['solde_final'] > 0
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_formatNumber(balance['solde_final'])} Ar',
                              style: TextStyle(
                                fontSize: 11,
                                color: balance['solde_final'] > 0
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                      onItemSelected: (balance) => _showBalanceDetails(balance),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBalanceDetails(Map<String, dynamic> balance) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.account_balance_wallet, color: Colors.green.shade600, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance['client'],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: balance['solde_final'] > 0
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            balance['solde_final'] > 0 ? 'Débiteur' : 'Créditeur',
                            style: TextStyle(
                              fontSize: 12,
                              color: balance['solde_final'] > 0 ? Colors.red.shade700 : Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),

              // Informations client
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('NIF:', balance['nif'] ?? ''),
                    _buildDetailRow('Téléphone:', balance['telephone'] ?? ''),
                    _buildDetailRow('Email:', balance['email'] ?? ''),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mouvements financiers
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Mouvements du compte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMovementCard(
                            'Solde Initial',
                            '${_formatNumber(balance['solde_initial'])} Ar',
                            Icons.account_balance,
                            Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMovementCard(
                            'Entrées',
                            '${_formatNumber(balance['total_entrees'])} Ar',
                            Icons.add_circle,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMovementCard(
                            'Sorties',
                            '${_formatNumber(balance['total_sorties'])} Ar',
                            Icons.remove_circle,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Solde final
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: balance['solde_final'] > 0
                        ? [Colors.red.shade50, Colors.red.shade100]
                        : [Colors.green.shade50, Colors.green.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Solde final',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatNumber(balance['solde_final'])} Ar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: balance['solde_final'] > 0 ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
