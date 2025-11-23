import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class StatistiquesVentesModal extends StatefulWidget {
  const StatistiquesVentesModal({super.key});

  @override
  State<StatistiquesVentesModal> createState() => _StatistiquesVentesModalState();
}

class _StatistiquesVentesModalState extends State<StatistiquesVentesModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Vente> _ventes = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Ce mois';

  @override
  void initState() {
    super.initState();
    _loadVentes();
  }

  Future<void> _loadVentes() async {
    try {
      final allVentes = await _databaseService.database.getAllVentes();
      List<Vente> filteredVentes = [];

      final now = DateTime.now();
      switch (_selectedPeriod) {
        case 'Aujourd\'hui':
          filteredVentes = allVentes
              .where((v) =>
                  v.daty != null &&
                  v.daty!.year == now.year &&
                  v.daty!.month == now.month &&
                  v.daty!.day == now.day)
              .toList();
          break;
        case 'Cette semaine':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          filteredVentes = allVentes.where((v) => v.daty != null && v.daty!.isAfter(startOfWeek)).toList();
          break;
        case 'Ce mois':
          filteredVentes = allVentes
              .where((v) => v.daty != null && v.daty!.year == now.year && v.daty!.month == now.month)
              .toList();
          break;
        default:
          filteredVentes = allVentes;
      }

      setState(() {
        _ventes = filteredVentes;
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

  double _getTotalCA() => _ventes.fold(0.0, (sum, v) => sum + (v.totalttc ?? 0));
  int _getNombreVentes() => _ventes.length;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
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
                        'Statistiques de ventes',
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
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Période: '),
                        DropdownButton<String>(
                          value: _selectedPeriod,
                          items: const [
                            DropdownMenuItem(value: 'Aujourd\'hui', child: Text('Aujourd\'hui')),
                            DropdownMenuItem(value: 'Cette semaine', child: Text('Cette semaine')),
                            DropdownMenuItem(value: 'Ce mois', child: Text('Ce mois')),
                            DropdownMenuItem(value: 'Tout', child: Text('Tout')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriod = value ?? 'Ce mois';
                              _isLoading = true;
                            });
                            _loadVentes();
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Ventes: ${_getNombreVentes()}',
                              style: const TextStyle(fontSize: 12, color: Colors.blue)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('CA: ${NumberUtils.formatNumber(_getTotalCA())}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                                color: Colors.green[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                      child: Center(
                                          child:
                                              Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('N° Vente',
                                              style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      flex: 2,
                                      child: Center(
                                          child:
                                              Text('Client', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Total HT',
                                              style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('TVA', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Total TTC',
                                              style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Commercial',
                                              style: TextStyle(fontWeight: FontWeight.bold)))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _ventes.isEmpty
                                  ? const Center(child: Text('Aucune vente pour cette période'))
                                  : ListView.builder(
                                      itemCount: _ventes.length,
                                      itemBuilder: (context, index) {
                                        final vente = _ventes[index];
                                        return Container(
                                          height: 35,
                                          decoration: BoxDecoration(
                                            color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                            border: const Border(
                                                bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    vente.daty?.toString().split(' ')[0] ?? 'N/A',
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    vente.numventes ?? 'N/A',
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: Text(
                                                    vente.clt ?? 'N/A',
                                                    style: const TextStyle(fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(vente.totalnt ?? 0),
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(vente.tva ?? 0),
                                                    style:
                                                        const TextStyle(fontSize: 11, color: Colors.orange),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    NumberUtils.formatNumber(vente.totalttc ?? 0),
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    vente.commerc ?? 'N/A',
                                                    style: const TextStyle(fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }
}
