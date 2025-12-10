import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class RelanceClientsModal extends StatefulWidget {
  const RelanceClientsModal({super.key});

  @override
  State<RelanceClientsModal> createState() => _RelanceClientsModalState();
}

class _RelanceClientsModalState extends State<RelanceClientsModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<CltData> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final allClients = await _databaseService.database.getActiveClients();
      // Filtrer les clients avec solde débiteur (à relancer)
      final clientsARelancer = allClients.where((c) => (c.soldes ?? 0) > 0).toList();
      setState(() {
        _clients = clientsARelancer;
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Relance Clients',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Center(
                                        child:
                                            Text('Client', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('Téléphone',
                                            style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Solde dû', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('Délai', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child: Text('Dernière op.',
                                            style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(
                                    child: Center(
                                        child:
                                            Text('Action', style: TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _clients.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                                        SizedBox(height: 16),
                                        Text('Aucun client à relancer'),
                                        Text('Tous les comptes sont à jour',
                                            style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _clients.length,
                                    itemBuilder: (context, index) {
                                      final client = _clients[index];
                                      final retard = client.datedernop != null
                                          ? DateTime.now().difference(client.datedernop!).inDays
                                          : 0;
                                      return Focus(
                                        autofocus: true,
                                        onKeyEvent: (node, event) => handleTabNavigation(event),
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                            border: const Border(
                                                bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: Text(
                                                    client.rsoc,
                                                    style: const TextStyle(fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    client.tel ?? 'N/A',
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(client.soldes ?? 0),
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    '${client.delai ?? 0} j',
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    client.datedernop?.toString().split(' ')[0] ?? 'N/A',
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      // Action de relance
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                            content:
                                                                Text('Relance envoyée à ${client.rsoc}')),
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: retard > (client.delai ?? 0)
                                                          ? Colors.red
                                                          : Colors.orange,
                                                      minimumSize: const Size(60, 25),
                                                    ),
                                                    child: const Text('Relancer',
                                                        style: TextStyle(fontSize: 10)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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
    );
  }
}
