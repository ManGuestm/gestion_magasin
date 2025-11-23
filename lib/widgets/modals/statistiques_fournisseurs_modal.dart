import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

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
  DateTime _dateDebut = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateFin = DateTime.now();
  bool _isLoading = false;
  String _sortColumn = 'totalAchats';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadStatistiques();
  }

  Future<void> _loadStatistiques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Requête pour récupérer les statistiques d'achats par fournisseur
      const query = '''
        SELECT 
          a.frns as fournisseur,
          COUNT(DISTINCT a.numachats) as nombreAchats,
          SUM(a.totalnt) as totalHT,
          SUM(a.totalttc) as totalTTC,
          AVG(a.totalttc) as moyenneAchat,
          MIN(a.daty) as premierAchat,
          MAX(a.daty) as dernierAchat,
          SUM(CASE WHEN a.daty >= ? THEN a.totalttc ELSE 0 END) as totalPeriode
        FROM achats a
        WHERE a.daty BETWEEN ? AND ?
        GROUP BY a.frns
        ORDER BY totalTTC DESC
      ''';

      final result = await _databaseService.database.customSelect(
        query,
        variables: [
          Variable(_dateDebut.subtract(const Duration(days: 365)).toIso8601String()),
          Variable(_dateDebut.toIso8601String()),
          Variable(_dateFin.toIso8601String()),
        ],
      ).get();

      final statistiques = result
          .map((row) => {
                'fournisseur': row.read<String>('fournisseur'),
                'nombreAchats': row.read<int>('nombreAchats'),
                'totalHT': row.read<double>('totalHT'),
                'totalTTC': row.read<double>('totalTTC'),
                'moyenneAchat': row.read<double>('moyenneAchat'),
                'premierAchat': row.read<String?>('premierAchat'),
                'dernierAchat': row.read<String?>('dernierAchat'),
                'totalPeriode': row.read<double>('totalPeriode'),
              })
          .toList();

      setState(() {
        _statistiques = statistiques;
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Statistiques Fournisseurs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                  _buildSummaryCard('CA Moyen',
                      _statistiques.isNotEmpty ? _totalGeneral / _statistiques.length : 0, Colors.purple),
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
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                              border: Border(
                                                bottom: BorderSide(color: Colors.grey.shade200),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                _buildDataCell(stat['fournisseur'] ?? '', 200),
                                                _buildDataCell(stat['nombreAchats'].toString(), 100,
                                                    isNumber: true),
                                                _buildDataCell(
                                                    NumberUtils.formatNumber(stat['totalHT'] as double), 120,
                                                    isNumber: true),
                                                _buildDataCell(
                                                    NumberUtils.formatNumber(stat['totalTTC'] as double), 120,
                                                    isNumber: true),
                                                _buildDataCell(
                                                    NumberUtils.formatNumber(stat['moyenneAchat'] as double),
                                                    120,
                                                    isNumber: true),
                                                _buildDataCell(
                                                    stat['premierAchat'] != null
                                                        ? app_date.AppDateUtils.formatDate(
                                                            DateTime.parse(stat['premierAchat']))
                                                        : '',
                                                    120),
                                                _buildDataCell(
                                                    stat['dernierAchat'] != null
                                                        ? app_date.AppDateUtils.formatDate(
                                                            DateTime.parse(stat['dernierAchat']))
                                                        : '',
                                                    120),
                                                _buildDataCell('${pourcentage.toStringAsFixed(1)}%', 100,
                                                    isNumber: true),
                                              ],
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title.contains('Nb') || title.contains('Total Achats')
                  ? value.toInt().toString()
                  : NumberUtils.formatNumber(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool isNumber = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        textAlign: isNumber ? TextAlign.right : TextAlign.left,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
