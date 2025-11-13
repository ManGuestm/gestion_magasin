import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';

class MouvementsClientsModal extends StatefulWidget {
  const MouvementsClientsModal({super.key});

  @override
  State<MouvementsClientsModal> createState() => _MouvementsClientsModalState();
}

class _MouvementsClientsModalState extends State<MouvementsClientsModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<CltData> _clients = [];
  List<Map<String, dynamic>> _mouvements = [];
  bool _isLoading = true;
  String? _selectedClient;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    _dateDebut = firstDayOfMonth;
    _dateFin = now;
    _dateDebutController.text = app_date.AppDateUtils.formatDate(firstDayOfMonth);
    _dateFinController.text = app_date.AppDateUtils.formatDate(now);
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _databaseService.database.getAllClients();
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _loadMouvements() async {
    if (_selectedClient == null || _dateDebut == null || _dateFin == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les ventes du client dans la période
      final ventes = await (_databaseService.database.select(_databaseService.database.ventes)
            ..where((v) =>
                v.clt.equals(_selectedClient!) &
                v.daty.isBiggerOrEqualValue(_dateDebut!) &
                v.daty.isSmallerOrEqualValue(_dateFin!)))
          .get();

      // Charger les comptes clients (mouvements de compte)
      final comptesClient = await (_databaseService.database.select(_databaseService.database.compteclt)
            ..where((c) =>
                c.clt.equals(_selectedClient!) &
                c.daty.isBiggerOrEqualValue(_dateDebut!) &
                c.daty.isSmallerOrEqualValue(_dateFin!)))
          .get();

      List<Map<String, dynamic>> mouvements = [];

      // Ajouter les ventes
      for (var vente in ventes) {
        mouvements.add({
          'type': 'Vente',
          'date': vente.daty,
          'reference': vente.numventes ?? '',
          'description': 'Vente N° ${vente.numventes ?? ''}',
          'debit': vente.totalttc ?? 0.0,
          'credit': 0.0,
        });
      }

      // Ajouter les mouvements de compte client
      for (var compte in comptesClient) {
        mouvements.add({
          'type': 'Règlement',
          'date': compte.daty,
          'reference': compte.ref,
          'description': compte.lib ?? 'Règlement',
          'debit': compte.entres ?? 0.0,
          'credit': compte.sorties ?? 0.0,
        });
      }

      // Trier par date
      mouvements.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      setState(() {
        _mouvements = mouvements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  double _calculateSolde() {
    double solde = 0.0;
    for (var mouvement in _mouvements) {
      solde += (mouvement['debit'] as double) - (mouvement['credit'] as double);
    }
    return solde;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          color: Colors.grey[100],
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mouvements Clients',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Filter section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Client selection
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Client:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedClient,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              items: _clients.map((client) {
                                return DropdownMenuItem<String>(
                                  value: client.rsoc,
                                  child: Text(client.rsoc, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedClient = value;
                                  _mouvements.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date debut
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date début:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _dateDebutController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                suffixIcon: Icon(Icons.calendar_today, size: 16),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _dateDebut ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _dateDebut = date;
                                    _dateDebutController.text = app_date.AppDateUtils.formatDate(date);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date fin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date fin:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _dateFinController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                suffixIcon: Icon(Icons.calendar_today, size: 16),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _dateFin ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _dateFin = date;
                                    _dateFinController.text = app_date.AppDateUtils.formatDate(date);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Search button
                      ElevatedButton(
                        onPressed: _selectedClient != null ? _loadMouvements : null,
                        child: const Text('Rechercher'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Data table
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
                          // Header
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
                                    child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text('Référence', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Data rows
                          Expanded(
                            child: _mouvements.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Aucun mouvement trouvé',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _mouvements.length,
                                    itemBuilder: (context, index) {
                                      final mouvement = _mouvements[index];
                                      return Container(
                                        height: 35,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                          border: const Border(
                                            bottom: BorderSide(color: Colors.grey, width: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  app_date.AppDateUtils.formatDate(mouvement['date']),
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  mouvement['type'],
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  mouvement['reference'],
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  mouvement['description'],
                                                  style: const TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  mouvement['debit'] > 0
                                                      ? NumberUtils.formatNumber(mouvement['debit'])
                                                      : '',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Text(
                                                  mouvement['credit'] > 0
                                                      ? NumberUtils.formatNumber(mouvement['credit'])
                                                      : '',
                                                  style: const TextStyle(fontSize: 12),
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
                    ),
            ),

            // Summary section
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${_mouvements.length} mouvement(s)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (_mouvements.isNotEmpty)
                    Text(
                      'Solde: ${NumberUtils.formatNumber(_calculateSolde())}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _calculateSolde() >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }
}
