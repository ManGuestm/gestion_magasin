import 'package:flutter/material.dart';

import '../../services/network_server.dart';
import '../common/base_modal.dart';

class ClientsConnectesModal extends StatefulWidget {
  const ClientsConnectesModal({super.key});

  @override
  State<ClientsConnectesModal> createState() => _ClientsConnectesModalState();
}

class _ClientsConnectesModalState extends State<ClientsConnectesModal> {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnectedClients();
  }

  void _loadConnectedClients() {
    setState(() => _isLoading = true);

    final server = NetworkServer.instance;
    if (!server.isRunning) {
      setState(() {
        _clients = [];
        _isLoading = false;
      });
      return;
    }

    // Récupérer les vraies informations des clients connectés
    _clients = server.getConnectedClientsInfo();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Clients Connectés',
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.height * 0.7,
      content: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildClientsList()),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.dns, color: Colors.green[700]),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Serveur actif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_clients.length} client(s) connecté(s)', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _loadConnectedClients,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.computer_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun client connecté', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 50,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columns: const [
            DataColumn(
              label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Adresse IP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Connexion', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: _clients.map((client) {
            return DataRow(
              cells: [
                DataCell(
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${client['id']}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      Icon(Icons.computer, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(client['nom'] ?? 'N/A', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      client['ip'] ?? 'N/A',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
                DataCell(Text(_formatDuration(client['connexion'] ?? DateTime.now()))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (client['type'] == 'HTTP REST') ? Colors.orange[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      client['type'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 11,
                        color: (client['type'] == 'HTTP REST') ? Colors.orange[700] : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      client['statut'] ?? 'N/A',
                      style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
    );
  }

  String _formatDuration(DateTime connexion) {
    final now = DateTime.now();
    final diff = now.difference(connexion);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes}min';
    } else {
      return 'Il y a ${diff.inHours}h${diff.inMinutes % 60}min';
    }
  }
}
