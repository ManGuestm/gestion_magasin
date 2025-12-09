import 'package:flutter/material.dart';
import '../../../constants/app_functions.dart';
import '../../../database/database.dart';

class StockTab extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic> stats;
  final List<Article> filteredArticles;
  final List<DepartData> stock;
  final String selectedDepot;
  final String selectedCategorie;
  final List<String> depots;
  final List<String> categories;
  final int currentPage;
  final int itemsPerPage;
  final int? hoveredStockIndex;
  final ScrollController scrollController;
  final Function(String) onSearchChanged;
  final Function(String) onDepotChanged;
  final Function(String) onCategorieChanged;
  final Function() onExport;
  final Function(int) onPageChanged;
  final Function(int?) onHoverChanged;

  const StockTab({
    super.key,
    required this.isLoading,
    required this.stats,
    required this.filteredArticles,
    required this.stock,
    required this.selectedDepot,
    required this.selectedCategorie,
    required this.depots,
    required this.categories,
    required this.currentPage,
    required this.itemsPerPage,
    required this.hoveredStockIndex,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onDepotChanged,
    required this.onCategorieChanged,
    required this.onExport,
    required this.onPageChanged,
    required this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsCards(),
        _buildFilters(),
        Expanded(child: _buildStockList()),
      ],
    );
  }

  Widget _buildStatsCards() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Valeur Totale', '${AppFunctions.formatNumber(stats['valeurTotale'] ?? 0)} Ar', Icons.monetization_on, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Articles en Stock', '${stats['articlesEnStock'] ?? 0}', Icons.check_circle, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Ruptures', '${stats['articlesRupture'] ?? 0}', Icons.warning, Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Alertes', '${stats['articlesAlerte'] ?? 0}', Icons.notification_important, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un article...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedDepot,
              decoration: const InputDecoration(labelText: 'Dépôt', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: depots.map((depot) => DropdownMenuItem(value: depot, child: Text(depot))).toList(),
              onChanged: (value) => onDepotChanged(value!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategorie,
              decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => onCategorieChanged(value!),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Exporter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (filteredArticles.isEmpty) return const Center(child: Text('Aucun article trouvé', style: TextStyle(fontSize: 16)));

    return Column(
      children: [
        Expanded(child: _buildVirtualizedStockList()),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildVirtualizedStockList() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredArticles.length);
    final pageArticles = filteredArticles.sublist(startIndex, endIndex);

    return ListView.builder(
      controller: scrollController,
      itemCount: pageArticles.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildStockHeader();
        final article = pageArticles[index - 1];
        return _buildStockListItem(article, index - 1);
      },
    );
  }

  Widget _buildStockHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[100], border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Désignation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Stock U1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Stock U2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Stock U3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('CMUP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Valeur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildStockListItem(Article article, int itemIndex) {
    final depotStock = selectedDepot != 'Tous'
        ? stock.firstWhere((s) => s.designation == article.designation && s.depots == selectedDepot,
            orElse: () => DepartData(designation: article.designation, depots: selectedDepot, stocksu1: 0, stocksu2: 0, stocksu3: 0))
        : null;

    final stockU1 = depotStock?.stocksu1 ?? article.stocksu1 ?? 0;
    final stockU2 = depotStock?.stocksu2 ?? article.stocksu2 ?? 0;
    final stockU3 = depotStock?.stocksu3 ?? article.stocksu3 ?? 0;
    final stockTotal = stockU1 + stockU2 + stockU3;
    final cmup = article.cmup ?? 0;
    final valeur = stockTotal * cmup;

    Color statusColor = Colors.green;
    String status = 'En stock';

    if (stockTotal <= 0) {
      statusColor = Colors.red;
      status = 'Rupture';
    } else if (article.usec != null && stockTotal <= article.usec!) {
      statusColor = Colors.orange;
      status = 'Alerte';
    }

    final isHovered = hoveredStockIndex == itemIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHoverChanged(itemIndex),
      onExit: (_) => onHoverChanged(null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.withValues(alpha: 0.1) : null,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(article.designation, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(article.categorie ?? '', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
            Expanded(child: Text('$stockU1', style: const TextStyle(fontSize: 11))),
            Expanded(child: Text('$stockU2', style: const TextStyle(fontSize: 11))),
            Expanded(child: Text('$stockU3', style: const TextStyle(fontSize: 11))),
            Expanded(child: Text(AppFunctions.formatNumber(cmup), style: const TextStyle(fontSize: 11))),
            Expanded(child: Text('${AppFunctions.formatNumber(valeur)} Ar', style: const TextStyle(fontSize: 11))),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 0.5),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (filteredArticles.length / itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey[100], border: Border(top: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null, icon: const Icon(Icons.chevron_left)),
          Text('Page ${currentPage + 1} sur $totalPages (${filteredArticles.length} articles)', style: const TextStyle(fontSize: 12)),
          IconButton(onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}