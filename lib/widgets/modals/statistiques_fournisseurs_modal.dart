import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class StatistiquesFournisseursModal extends StatefulWidget {
  const StatistiquesFournisseursModal({super.key});

  @override
  State<StatistiquesFournisseursModal> createState() => _StatistiquesFournisseursModalState();
}

class _StatistiquesFournisseursModalState extends State<StatistiquesFournisseursModal>
    with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();

  List<Map<String, dynamic>> _statistiques = [];
  DateTime _dateDebut = DateTime.now().subtract(const Duration(days: 365)); // 1 an
  DateTime _dateFin = DateTime.now().add(const Duration(days: 1)); // Demain
  bool _isLoading = false;
  String _sortColumn = 'totalAchats';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Vérifier s'il y a des données, sinon créer des données de test
    final achats = await _databaseService.database.getAllAchats();
    final fournisseurs = await _databaseService.database.getActiveFournisseurs();

    if (achats.isEmpty || fournisseurs.isEmpty) {
      await _createTestData();
    }

    await _loadStatistiques();
  }

  Future<void> _createTestData() async {
    try {
      // Créer quelques fournisseurs de test
      final testFournisseurs = [
        {'rsoc': 'Fournisseur A', 'tel': '0123456789', 'email': 'contact@fourn-a.com'},
        {'rsoc': 'Fournisseur B', 'tel': '0987654321', 'email': 'info@fourn-b.com'},
        {'rsoc': 'Fournisseur C', 'tel': '0555666777', 'email': 'admin@fourn-c.com'},
      ];

      for (var frn in testFournisseurs) {
        await _databaseService.database.insertFournisseur(
          FrnsCompanion(
            rsoc: Value(frn['rsoc']!),
            tel: Value(frn['tel']),
            email: Value(frn['email']),
            soldes: const Value(0.0),
          ),
        );
      }

      // Créer quelques achats de test
      final testAchats = [
        {
          'numachats': 'ACH001',
          'frns': 'Fournisseur A',
          'totalttc': 150000.0,
          'totalnt': 125000.0,
          'daty': DateTime.now().subtract(const Duration(days: 15)),
        },
        {
          'numachats': 'ACH002',
          'frns': 'Fournisseur B',
          'totalttc': 250000.0,
          'totalnt': 208333.0,
          'daty': DateTime.now().subtract(const Duration(days: 10)),
        },
        {
          'numachats': 'ACH003',
          'frns': 'Fournisseur A',
          'totalttc': 75000.0,
          'totalnt': 62500.0,
          'daty': DateTime.now().subtract(const Duration(days: 5)),
        },
        {
          'numachats': 'ACH004',
          'frns': 'Fournisseur C',
          'totalttc': 180000.0,
          'totalnt': 150000.0,
          'daty': DateTime.now().subtract(const Duration(days: 3)),
        },
      ];

      for (var achat in testAchats) {
        await _databaseService.database.insertAchat(
          AchatsCompanion(
            numachats: Value(achat['numachats'] as String),
            frns: Value(achat['frns'] as String),
            totalttc: Value(achat['totalttc'] as double),
            daty: Value(achat['daty'] as DateTime),
            verification: const Value('JOURNAL'),
          ),
        );
      }

      debugPrint('Données de test créées avec succès');
    } catch (e) {
      debugPrint('Erreur création données de test: $e');
    }
  }

  Future<void> _loadStatistiques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: vérifier s'il y a des achats dans la base
      final totalAchats = await _databaseService.database.getAllAchats();
      debugPrint('Total achats dans la base: ${totalAchats.length}');

      // Debug: vérifier s'il y a des fournisseurs
      final totalFournisseurs = await _databaseService.database.getActiveFournisseurs();
      debugPrint('Total fournisseurs dans la base: ${totalFournisseurs.length}');

      final statistiques = await _databaseService.database.getStatistiquesFournisseurs(
        dateDebut: _dateDebut,
        dateFin: _dateFin,
      );

      debugPrint('Statistiques trouvées: ${statistiques.length}');
      debugPrint('Période: ${_dateDebut.toString()} à ${_dateFin.toString()}');

      // Si pas de données, essayer sans filtre de date
      if (statistiques.isEmpty) {
        final statsAll = await _databaseService.database.getStatistiquesFournisseurs();
        debugPrint('Statistiques sans filtre de date: ${statsAll.length}');

        setState(() {
          _statistiques = statsAll
              .map(
                (stat) => {
                  'fournisseur': stat['fournisseur'],
                  'nombreAchats': stat['nombre_achats'],
                  'totalHT': stat['montant_total'] * 0.8,
                  'totalTTC': stat['montant_total'],
                  'moyenneAchat': stat['montant_moyen'],
                  'premierAchat': stat['premier_achat'],
                  'dernierAchat': stat['dernier_achat'],
                  'totalPeriode': stat['montant_total'],
                },
              )
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _statistiques = statistiques
              .map(
                (stat) => {
                  'fournisseur': stat['fournisseur'],
                  'nombreAchats': stat['nombre_achats'],
                  'totalHT': stat['montant_total'] * 0.8,
                  'totalTTC': stat['montant_total'],
                  'moyenneAchat': stat['montant_moyen'],
                  'premierAchat': stat['premier_achat'],
                  'dernierAchat': stat['dernier_achat'],
                  'totalPeriode': stat['montant_total'],
                },
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement statistiques: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
      }
    }
  }

  void _sortData(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }

      _statistiques.sort((a, b) {
        dynamic aValue = a[column];
        dynamic bValue = b[column];

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? -1 : 1;
        if (bValue == null) return _sortAscending ? 1 : -1;

        int comparison = aValue.compareTo(bValue);
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  Future<void> _selectDate(bool isDebut) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : _dateFin,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = date;
        } else {
          _dateFin = date;
        }
      });
      await _loadStatistiques();
    }
  }

  double get _totalGeneral {
    return _statistiques.fold(0.0, (sum, stat) => sum + (stat['totalTTC'] as double));
  }

  int get _totalAchats {
    return _statistiques.fold(0, (sum, stat) => sum + (stat['nombreAchats'] as int));
  }

  Widget _buildSortableHeader(String title, String column, {double? width}) {
    return InkWell(
      onTap: () => _sortData(column),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            Icon(
              _sortColumn == column
                  ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : Icons.sort,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: 1200,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[100]),
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Statistiques Fournisseurs',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Filtres
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  // Date début
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date début',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(app_date.AppDateUtils.formatDate(_dateDebut)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Date fin
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date fin',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(app_date.AppDateUtils.formatDate(_dateFin)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Bouton actualiser
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadStatistiques,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                  ),
                ],
              ),
            ),

            // Résumé
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.purple.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard('Nb Fournisseurs', _statistiques.length.toDouble(), Colors.blue),
                  _buildSummaryCard('Total Achats', _totalAchats.toDouble(), Colors.orange),
                  _buildSummaryCard('CA Total', _totalGeneral, Colors.green),
                  _buildSummaryCard(
                    'CA Moyen',
                    _statistiques.isNotEmpty ? _totalGeneral / _statistiques.length : 0,
                    Colors.purple,
                  ),
                ],
              ),
            ),

            // Table des statistiques
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    // En-tête du tableau
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortableHeader('Fournisseur', 'fournisseur', width: 200),
                          _buildSortableHeader('Nb Achats', 'nombreAchats', width: 100),
                          _buildSortableHeader('Total HT', 'totalHT', width: 120),
                          _buildSortableHeader('Total TTC', 'totalTTC', width: 120),
                          _buildSortableHeader('Moyenne', 'moyenneAchat', width: 120),
                          _buildSortableHeader('Premier Achat', 'premierAchat', width: 120),
                          _buildSortableHeader('Dernier Achat', 'dernierAchat', width: 120),
                          _buildSortableHeader('% du CA', 'pourcentage', width: 100),
                        ],
                      ),
                    ),

                    // Contenu du tableau
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _statistiques.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucune donnée trouvée',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Column(
                                  children: _statistiques.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final stat = entry.value;
                                    final pourcentage = _totalGeneral > 0
                                        ? (stat['totalTTC'] as double) / _totalGeneral * 100
                                        : 0.0;

                                    return Focus(
                                      autofocus: true,
                                      onKeyEvent: (node, event) => handleTabNavigation(event),
                                      child: InkWell(
                                        onTap: () => _showFournisseurDetails(stat['fournisseur']),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildDataCell(stat['fournisseur'] ?? '', 200),
                                              _buildDataCell(
                                                stat['nombreAchats'].toString(),
                                                100,
                                                isNumber: true,
                                              ),
                                              _buildDataCell(
                                                NumberUtils.formatNumber(stat['totalHT'] as double),
                                                120,
                                                isNumber: true,
                                              ),
                                              _buildDataCell(
                                                NumberUtils.formatNumber(stat['totalTTC'] as double),
                                                120,
                                                isNumber: true,
                                              ),
                                              _buildDataCell(
                                                NumberUtils.formatNumber(stat['moyenneAchat'] as double),
                                                120,
                                                isNumber: true,
                                              ),
                                              _buildDataCell(
                                                stat['premierAchat'] != null
                                                    ? _formatDateFromTimestamp(stat['premierAchat'])
                                                    : '',
                                                120,
                                              ),
                                              _buildDataCell(
                                                stat['dernierAchat'] != null
                                                    ? _formatDateFromTimestamp(stat['dernierAchat'])
                                                    : '',
                                                120,
                                              ),
                                              _buildDataCell(
                                                '${pourcentage.toStringAsFixed(1)}%',
                                                100,
                                                isNumber: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
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

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              title.contains('Nb') || title.contains('Total Achats')
                  ? value.toInt().toString()
                  : NumberUtils.formatNumber(value),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateFromTimestamp(dynamic dateValue) {
    try {
      if (dateValue == null) return '';

      // Si c'est déjà une chaîne de date ISO
      if (dateValue is String && dateValue.contains('-')) {
        return app_date.AppDateUtils.formatDate(DateTime.parse(dateValue));
      }

      // Si c'est un timestamp Unix (en secondes)
      int timestamp;
      if (dateValue is String) {
        timestamp = int.parse(dateValue);
      } else if (dateValue is int) {
        timestamp = dateValue;
      } else {
        return '';
      }

      // Convertir le timestamp Unix en DateTime
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return app_date.AppDateUtils.formatDate(date);
    } catch (e) {
      debugPrint('Erreur formatage date: $e pour valeur: $dateValue');
      return '';
    }
  }

  Future<void> _showFournisseurDetails(String fournisseur) async {
    try {
      final achats = await _databaseService.database
          .customSelect(
            'SELECT * FROM achats WHERE frns = ? ORDER BY daty DESC',
            variables: [Variable(fournisseur)],
          )
          .get();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: 900,
            height: 600,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Détails Achats - $fournisseur',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: achats.length,
                    itemBuilder: (context, index) {
                      final achat = achats[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ExpansionTile(
                          title: Text('Achat N° ${achat.read<String?>('numachats') ?? 'N/A'}'),
                          subtitle: Text(
                            'Date: ${_formatDateFromTimestamp(achat.readNullable<String>('daty'))} - '
                            'Total: ${NumberUtils.formatNumber(achat.read<double?>('totalttc') ?? 0)} Ar',
                          ),
                          children: [
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _getAchatDetails(achat.read<String?>('numachats') ?? ''),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final details = snapshot.data ?? [];
                                if (details.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Aucun détail disponible'),
                                  );
                                }

                                return Column(
                                  children: details
                                      .map(
                                        (detail) => ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.inventory_2, size: 16),
                                          title: Text(detail['designation'] ?? 'Article inconnu'),
                                          subtitle: Text(
                                            'Qté: ${detail['q'] ?? 0} ${detail['unites'] ?? ''} - '
                                            'PU: ${NumberUtils.formatNumber(detail['pu'] ?? 0)} Ar',
                                          ),
                                          trailing: Text(
                                            '${NumberUtils.formatNumber((detail['q'] ?? 0) * (detail['pu'] ?? 0))} Ar',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
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
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<List<Map<String, dynamic>>> _getAchatDetails(String numAchats) async {
    try {
      final details = await _databaseService.database
          .customSelect('SELECT * FROM detachats WHERE numachats = ?', variables: [Variable(numAchats)])
          .get();

      return details
          .map(
            (row) => {
              'designation': row.readNullable<String>('designation'),
              'unites': row.readNullable<String>('unites'),
              'q': row.readNullable<double>('q'),
              'pu': row.readNullable<double>('pu'),
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildDataCell(String text, double width, {bool isNumber = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        textAlign: isNumber ? TextAlign.right : TextAlign.left,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
