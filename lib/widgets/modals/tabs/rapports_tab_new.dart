import 'package:flutter/material.dart';

import '../../../database/database.dart';
import '../../../models/inventaire_state.dart';

/// Widget autonome pour l'affichage du tab Rapports (Analyses)
///
/// Responsabilités:
/// - Afficher statistiques d'inventaire
/// - Afficher articles en rupture/alerte
/// - Afficher tendances de stock
/// - Générer rapports PDF/Excel
/// - Visualiser KPIs principaux
///
/// Utilise InventaireState pour immutabilité et callbacks pour mutations.
class RapportsTabNew extends StatefulWidget {
  // === DONNÉES ===
  final InventaireState state;
  final Map<String, dynamic> stats;

  // === CALLBACKS ===
  final Function() onGeneratePDF;
  final Function() onGenerateExcel;
  final Function() onRefreshStats;

  const RapportsTabNew({
    super.key,
    required this.state,
    required this.stats,
    required this.onGeneratePDF,
    required this.onGenerateExcel,
    required this.onRefreshStats,
  });

  @override
  State<RapportsTabNew> createState() => _RapportsTabNewState();
}

class _RapportsTabNewState extends State<RapportsTabNew> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatsGrid(),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildArticlesEnRuptureSection(),
                    const SizedBox(width: 48),
                    _buildArticlesEnAlerteSection(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// En-tête avec titre et boutons d'export
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment, color: Colors.purple[700]),
          const SizedBox(width: 8),
          const Text('Rapports & Statistiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: widget.onGeneratePDF,
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: widget.onGenerateExcel,
            icon: const Icon(Icons.table_chart, size: 16),
            label: const Text('Excel'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: widget.onRefreshStats,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Grille de statistiques principales (KPIs)
  Widget _buildStatsGrid() {
    final stats = widget.stats;
    final valeurTotaleDynamic = stats['valeurTotale'];
    final valeurTotale = valeurTotaleDynamic is num ? (valeurTotaleDynamic).toDouble() : 0.0;
    final articlesEnStock = (stats['articlesEnStock'] as int?) ?? 0;
    final articlesRupture = (stats['articlesRupture'] as int?) ?? 0;
    final articlesAlerte = (stats['articlesAlerte'] as int?) ?? 0;
    final totalArticles = (stats['totalArticles'] as int?) ?? widget.state.articles.length;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Valeur Totale Stock',
          value: '${(valeurTotale / 1000).toStringAsFixed(1)}K',
          icon: Icons.attach_money,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Articles en Stock',
          value: '$articlesEnStock',
          icon: Icons.check_circle,
          color: Colors.green,
          subtitle: '${((articlesEnStock / totalArticles) * 100).toStringAsFixed(1)}%',
        ),
        _buildStatCard(
          title: 'Articles en Rupture',
          value: '$articlesRupture',
          icon: Icons.cancel,
          color: Colors.red,
          subtitle: '${((articlesRupture / totalArticles) * 100).toStringAsFixed(1)}%',
        ),
        _buildStatCard(
          title: 'Articles en Alerte',
          value: '$articlesAlerte',
          icon: Icons.warning,
          color: Colors.orange,
          subtitle: '${((articlesAlerte / totalArticles) * 100).toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  /// Carte statistique individuelle
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 11, color: color)),
            ],
          ],
        ),
      ),
    );
  }

  /// Section articles en rupture
  Widget _buildArticlesEnRuptureSection() {
    final ruptures = widget.state.articles.where((a) {
      final stockTotal = (a.stocksu1 ?? 0) + (a.stocksu2 ?? 0) + (a.stocksu3 ?? 0);
      return stockTotal == 0;
    }).toList();

    return Expanded(
      child: _buildArticlesSection(
        title: 'Articles en Rupture (${ruptures.length})',
        articles: ruptures,
        color: Colors.red,
        icon: Icons.cancel,
      ),
    );
  }

  /// Section articles en alerte
  Widget _buildArticlesEnAlerteSection() {
    final alertes = widget.state.articles.where((a) {
      final stockTotal = (a.stocksu1 ?? 0) + (a.stocksu2 ?? 0) + (a.stocksu3 ?? 0);
      final stockAlerte = (a.usec ?? 10).toInt();
      return stockTotal > 0 && stockTotal <= stockAlerte;
    }).toList();

    return Expanded(
      child: _buildArticlesSection(
        title: 'Articles en Alerte Stock (${alertes.length})',
        articles: alertes,
        color: Colors.orange,
        icon: Icons.warning,
      ),
    );
  }

  /// Panneau générique pour liste d'articles
  Widget _buildArticlesSection({
    required String title,
    required List<Article> articles,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          if (articles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Aucun article', style: TextStyle(color: Colors.grey[600])),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Article', style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Catégorie', style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Stock U1', style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Stock U2', style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Stock U3', style: TextStyle(fontSize: 11))),
                  DataColumn(label: Text('Alerte', style: TextStyle(fontSize: 11))),
                ],
                rows: articles.take(20).map((article) {
                  return DataRow(
                    cells: [
                      DataCell(Text(article.designation, style: const TextStyle(fontSize: 10))),
                      DataCell(Text(article.categorie ?? '', style: const TextStyle(fontSize: 10))),
                      DataCell(
                        Text((article.stocksu1 ?? 0).toString(), style: const TextStyle(fontSize: 10)),
                      ),
                      DataCell(
                        Text((article.stocksu2 ?? 0).toString(), style: const TextStyle(fontSize: 10)),
                      ),
                      DataCell(
                        Text((article.stocksu3 ?? 0).toString(), style: const TextStyle(fontSize: 10)),
                      ),
                      DataCell(
                        Text((article.usec ?? 10).toInt().toString(), style: const TextStyle(fontSize: 10)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          if (articles.length > 20)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Et ${articles.length - 20} autres articles...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
