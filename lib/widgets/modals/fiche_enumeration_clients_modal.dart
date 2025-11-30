import 'package:flutter/material.dart';
import '../../database/database_service.dart';
import '../../database/database.dart';
import '../common/base_modal.dart';

class FicheEnumerationClientsModal extends StatefulWidget {
  const FicheEnumerationClientsModal({super.key});

  @override
  State<FicheEnumerationClientsModal> createState() => _FicheEnumerationClientsModalState();
}

class _FicheEnumerationClientsModalState extends State<FicheEnumerationClientsModal> {
  List<CltData> _clients = [];
  bool _isLoading = false;
  String _sortBy = 'rsoc';
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final clients = await DatabaseService().database.getAllClients();
      setState(() {
        _clients = clients;
        _sortClients();
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

  void _sortClients() {
    _clients.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'rsoc':
          comparison = a.rsoc.compareTo(b.rsoc);
          break;
        case 'nif':
          comparison = (a.nif ?? '').compareTo(b.nif ?? '');
          break;
        case 'soldes':
          comparison = (a.soldes ?? 0).compareTo(b.soldes ?? 0);
          break;
        default:
          comparison = a.rsoc.compareTo(b.rsoc);
      }
      return _ascending ? comparison : -comparison;
    });
  }

  void _changeSorting(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _ascending = !_ascending;
      } else {
        _sortBy = sortBy;
        _ascending = true;
      }
      _sortClients();
    });
  }

  String _formatNumber(double? number) {
    if (number == null) return '0';
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Fiche d\'Énumération Clients',
      width: 1000,
      height: 700,
      content: Column(
        children: [
          // Options de tri
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: const Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                const Text('Trier par: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Nom'),
                  selected: _sortBy == 'rsoc',
                  onSelected: (_) => _changeSorting('rsoc'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('NIF'),
                  selected: _sortBy == 'nif',
                  onSelected: (_) => _changeSorting('nif'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Solde'),
                  selected: _sortBy == 'soldes',
                  onSelected: (_) => _changeSorting('soldes'),
                ),
                const Spacer(),
                Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadClients,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                ),
              ],
            ),
          ),

          // Liste énumérée
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            client.rsoc,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (client.nif != null && client.nif!.isNotEmpty)
                                Text('NIF: ${client.nif}'),
                              if (client.tel != null && client.tel!.isNotEmpty)
                                Text('Tél: ${client.tel}'),
                              if (client.commercial != null && client.commercial!.isNotEmpty)
                                Text('Commercial: ${client.commercial}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_formatNumber(client.soldes)} Ar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: (client.soldes ?? 0) > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                              Text(
                                (client.soldes ?? 0) > 0 ? 'Débiteur' : 'Créditeur',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showClientSummary(client, index + 1),
                        ),
                      );
                    },
                  ),
          ),

          // Statistiques
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: const Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Total Clients', _clients.length.toString(), Colors.blue),
                _buildStatCard(
                  'Débiteurs',
                  _clients.where((c) => (c.soldes ?? 0) > 0).length.toString(),
                  Colors.red,
                ),
                _buildStatCard(
                  'Créditeurs',
                  _clients.where((c) => (c.soldes ?? 0) < 0).length.toString(),
                  Colors.green,
                ),
                _buildStatCard(
                  'Solde Total',
                  '${_formatNumber(_clients.fold<double>(0.0, (sum, c) => sum + (c.soldes ?? 0)))} Ar',
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showClientSummary(CltData client, int position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Client #$position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              client.rsoc,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (client.nif != null) Text('NIF: ${client.nif}'),
            if (client.tel != null) Text('Téléphone: ${client.tel}'),
            if (client.email != null) Text('Email: ${client.email}'),
            if (client.adr != null) Text('Adresse: ${client.adr}'),
            if (client.commercial != null) Text('Commercial: ${client.commercial}'),
            const Divider(),
            Text(
              'Solde: ${_formatNumber(client.soldes)} Ar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: (client.soldes ?? 0) > 0 ? Colors.red : Colors.green,
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