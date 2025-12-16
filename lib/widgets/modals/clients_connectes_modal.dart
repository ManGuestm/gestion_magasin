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
      width: 700,
      height: 500,
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
                const Text(
                  'Serveur actif',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_clients.length} client(s) connecté(s)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
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
            Text(
              'Aucun client connecté',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Adresse IP', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Connexion', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _clients.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final client = _clients[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.computer, color: Colors.green[700], size: 20),
                  ),
                  title: Row(
                    children: [
                      Expanded(flex: 1, child: Text('${client['id']}')),
                      Expanded(flex: 2, child: Text(client['nom'])),
                      Expanded(flex: 2, child: Text(client['ip'])),
                      Expanded(flex: 2, child: Text(_formatDuration(client['connexion']))),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            client['statut'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
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