import 'package:flutter/material.dart';

import '../../../constants/app_functions.dart';
import '../../../database/database.dart';

class RapportsTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Article> articles;
  final List<DepartData> stock;
  final List<String> depots;
  final Function() onExport;

  const RapportsTab({
    super.key,
    required this.stats,
    required this.articles,
    required this.stock,
    required this.depots,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRapportsHeader(),
        Expanded(child: _buildRapportsContent()),
      ],
    );
  }

  Widget _buildRapportsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.purple[700]),
          const SizedBox(width: 8),
          const Text('Rapports d\'Inventaire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Exporter Rapport'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRapportsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRapportStatsGrid(),
          const SizedBox(height: 24),
          _buildRapportAnalyse(),
          const SizedBox(height: 24),
          _buildRapportCategories(),
        ],
      ),
    );
  }

  Widget _buildRapportStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vue d\'ensemble', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRapportCard(
                'Total Articles',
                '${stats['totalArticles'] ?? 0}',
                Icons.inventory,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRapportCard(
                'Valeur Stock',
                '${AppFunctions.formatNumber(stats['valeurTotale'] ?? 0)} Ar',
                Icons.monetization_on,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRapportCard(
                'Taux Rupture',
                '${((stats['articlesRupture'] ?? 0) / (stats['totalArticles'] ?? 1) * 100).toStringAsFixed(1)}%',
                Icons.warning,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRapportCard('Dépôts Actifs', '${depots.length - 1}', Icons.store, Colors.orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRapportCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRapportAnalyse() {
    final articlesParDepot = <String, int>{};
    final valeurParDepot = <String, double>{};

    for (final depot in depots.where((d) => d != 'Tous')) {
      final articlesDepot = stock.where((s) => s.depots == depot).length;
      final valeurDepot = stock.where((s) => s.depots == depot).fold(0.0, (sum, s) {
        final article = articles.firstWhere(
          (a) => a.designation == s.designation,
          orElse: () => const Article(designation: '', cmup: 0),
        );
        final stockTotal = (s.stocksu1 ?? 0) + (s.stocksu2 ?? 0) + (s.stocksu3 ?? 0);
        return sum + (stockTotal * (article.cmup ?? 0));
      });
      articlesParDepot[depot] = articlesDepot;
      valeurParDepot[depot] = valeurDepot;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analyse par Dépôt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text('Dépôt', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('Articles', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('Valeur Stock', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('% Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              ...articlesParDepot.entries.map((entry) {
                final depot = entry.key;
                final nbArticles = entry.value;
                final valeur = valeurParDepot[depot] ?? 0;
                final pourcentage = (stats['valeurTotale'] ?? 0) > 0
                    ? (valeur / (stats['valeurTotale'] ?? 1) * 100)
                    : 0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(depot)),
                      Expanded(child: Text('$nbArticles')),
                      Expanded(child: Text('${AppFunctions.formatNumber(valeur)} Ar')),
                      Expanded(child: Text('${pourcentage.toStringAsFixed(1)}%')),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRapportCategories() {
    final articlesParCategorie = <String, int>{};
    final valeurParCategorie = <String, double>{};

    for (final article in articles) {
      final categorie = article.categorie ?? 'Sans catégorie';
      articlesParCategorie[categorie] = (articlesParCategorie[categorie] ?? 0) + 1;

      final stockTotal = (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);
      final valeur = stockTotal * (article.cmup ?? 0);
      valeurParCategorie[categorie] = (valeurParCategorie[categorie] ?? 0) + valeur;
    }

    final categoriesTriees = articlesParCategorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Répartition par Catégorie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('Articles', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('Valeur Stock', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('% Articles', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              ...categoriesTriees.take(10).map((entry) {
                final categorie = entry.key;
                final nbArticles = entry.value;
                final valeur = valeurParCategorie[categorie] ?? 0;
                final pourcentage = (stats['totalArticles'] ?? 0) > 0
                    ? (nbArticles / (stats['totalArticles'] ?? 1) * 100)
                    : 0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(categorie, overflow: TextOverflow.ellipsis)),
                      Expanded(child: Text('$nbArticles')),
                      Expanded(child: Text('${AppFunctions.formatNumber(valeur)} Ar')),
                      Expanded(child: Text('${pourcentage.toStringAsFixed(1)}%')),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
