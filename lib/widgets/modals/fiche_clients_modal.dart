import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/base_modal.dart';
import '../common/data_table_widget.dart';

class FicheClientsModal extends StatefulWidget {
  const FicheClientsModal({super.key});

  @override
  State<FicheClientsModal> createState() => _FicheClientsModalState();
}

class _FicheClientsModalState extends State<FicheClientsModal> {
  List<CltData> _clients = [];
  List<CltData> _filteredClients = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final clients = await DatabaseService().getActiveClientsWithModeAwareness();
      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _clients
          .where(
            (client) =>
                client.rsoc.toLowerCase().contains(query) ||
                (client.nif?.toLowerCase().contains(query) ?? false) ||
                (client.tel?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    });
  }

  String _formatNumber(double? number) {
    if (number == null) return '0';
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Fiche Clients',
      width: 1200,
      height: 700,
      content: Column(
        children: [
          // En-tête avec statistiques
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Statistiques rapides
                Row(
                  children: [
                    _buildStatCard(
                      'Total Clients',
                      _filteredClients.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Débiteurs',
                      _filteredClients.where((c) => (c.soldes ?? 0) > 0).length.toString(),
                      Icons.trending_up,
                      Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Créditeurs',
                      _filteredClients.where((c) => (c.soldes ?? 0) < 0).length.toString(),
                      Icons.trending_down,
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Solde Total',
                      '${_formatNumber(_filteredClients.fold<double>(0.0, (sum, c) => sum + (c.soldes ?? 0.0)))} Ar',
                      Icons.account_balance_wallet,
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Barre de recherche améliorée
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Rechercher par nom, NIF ou téléphone...',
                            prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterClients();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadClients,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tableau des clients
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                          Text('Chargement des clients...'),
                        ],
                      ),
                    )
                  : _filteredClients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun client trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essayez de modifier vos critères de recherche',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : DataTableWidget<CltData>(
                      itemHeight: 30,
                      headers: const ['Raison Sociale', 'NIF', 'Téléphone', 'Email', 'Solde', 'Commercial'],
                      items: _filteredClients,
                      rowBuilder: (client, isSelected) => [
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: (client.soldes ?? 0) < 0 ? Colors.red : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  client.rsoc,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            client.nif ?? '-',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              if (client.tel != null && client.tel!.isNotEmpty) ...[
                                Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  client.tel ?? '-',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              if (client.email != null && client.email!.isNotEmpty) ...[
                                Icon(Icons.email, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  client.email ?? '-',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              '${_formatNumber(client.soldes)} Ar',
                              style: TextStyle(
                                fontSize: 11,
                                color: (client.soldes ?? 0) > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              client.commercial ?? '-',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                      ],
                      onItemSelected: (client) => _showClientDetails(client),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(CltData client) {
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
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person, color: Colors.blue.shade600, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client.rsoc, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (client.soldes ?? 0) > 0
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (client.soldes ?? 0) > 0 ? 'Débiteur' : 'Créditeur',
                            style: TextStyle(
                              fontSize: 12,
                              color: (client.soldes ?? 0) > 0 ? Colors.red.shade700 : Colors.green.shade700,
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

              // Informations
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('NIF:', client.nif ?? ''),
                    _buildDetailRow('Téléphone:', client.tel ?? ''),
                    _buildDetailRow('Email:', client.email ?? ''),
                    _buildDetailRow('Adresse:', client.adr ?? ''),
                    _buildDetailRow('Commercial:', client.commercial ?? ''),
                    _buildDetailRow('Catégorie:', client.categorie ?? ''),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Solde
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (client.soldes ?? 0) > 0
                        ? [Colors.red.shade50, Colors.red.shade100]
                        : [Colors.green.shade50, Colors.green.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Solde du compte',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatNumber(client.soldes)} Ar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: (client.soldes ?? 0) > 0 ? Colors.red.shade700 : Colors.green.shade700,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
}
