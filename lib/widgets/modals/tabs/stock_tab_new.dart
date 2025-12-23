import 'package:flutter/material.dart';

import '../../../constants/app_functions.dart';
import '../../../database/database.dart';
import '../../../models/inventaire_state.dart';
import '../../../utils/stock_converter.dart';

/// Widget autonome pour l'affichage du tab Stock (État des Stocks)
///
/// Responsabilités:
/// - Afficher table articles avec stocks
/// - Filtrer par recherche/dépôt/catégorie
/// - Gérer pagination
/// - Afficher statistiques
/// - Exporter données
///
/// Utilise InventaireState pour immutabilité et callbacks pour mutations.
class StockTabNew extends StatefulWidget {
  // === DONNÉES ===
  final InventaireState state;
  final List<DepartData> stocks;

  // === CALLBACKS ===
  final Function(String) onSearchChanged;
  final Function(String) onDepotChanged;
  final Function(String) onCategorieChanged;
  final Function(int) onPageChanged;
  final Function() onExport;
  final Function(int?) onHoverChanged;

  const StockTabNew({
    super.key,
    required this.state,
    required this.stocks,
    required this.onSearchChanged,
    required this.onDepotChanged,
    required this.onCategorieChanged,
    required this.onPageChanged,
    required this.onExport,
    required this.onHoverChanged,
  });

  @override
  State<StockTabNew> createState() => _StockTabNewState();
}

class _StockTabNewState extends State<StockTabNew> {
  final ScrollController _scrollController = ScrollController();
  int? _hoveredIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildStockList()),
      ],
    );
  }

  /// En-tête avec filtres et statistiques
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Ligne 1: Filtres
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher article...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.state.selectedDepot,
                  decoration: InputDecoration(
                    labelText: 'Dépôt',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: widget.state.depots
                      .map((depot) => DropdownMenuItem(value: depot, child: Text(depot)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.onDepotChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.state.selectedCategorie,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: widget.state.categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.onCategorieChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: widget.onExport,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exporter'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ligne 2: Statistiques
          _buildStatsRow(),
        ],
      ),
    );
  }

  /// Affichage statistiques
  Widget _buildStatsRow() {
    final stats = widget.state.stats;
    return Row(
      children: [
        _buildStatBox('Articles en Stock', '${stats.articlesEnStock}', Colors.green),
        const SizedBox(width: 16),
        _buildStatBox('Articles en Rupture', '${stats.articlesRupture}', Colors.red),
        const SizedBox(width: 16),
        _buildStatBox('Articles en Alerte', '${stats.articlesAlerte}', Colors.orange),
        const SizedBox(width: 16),
        _buildStatBox('Valeur Totale', '${AppFunctions.formatNumber(stats.valeurTotale)} Ar', Colors.blue),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(stats.santeColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(stats.santeColor)),
          ),
          child: Text(
            'Santé: ${stats.sante}',
            style: TextStyle(color: Color(stats.santeColor), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Boîte statistique individuelle
  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// Liste articles (virtualisée avec pagination)
  Widget _buildStockList() {
    if (widget.state.filteredArticles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun article trouvé'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: _buildVirtualizedStockList()),
        _buildStockPagination(),
      ],
    );
  }

  /// ListView virtualisée des articles par page
  Widget _buildVirtualizedStockList() {
    final pageItems = widget.state.stockPageItems;

    return ListView.builder(
      controller: _scrollController,
      itemCount: pageItems.length + 1, // +1 pour en-tête
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStockTableHeader();
        }
        final article = pageItems[index - 1];
        return _buildArticleRow(article, index - 1);
      },
    );
  }

  /// En-tête de tableau (colonnes)
  Widget _buildStockTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Article', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Text('CMUP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Text('Valeur', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Ligne article avec hover effect
  Widget _buildArticleRow(Article article, int index) {
    // Obtenir les stocks spécifiques au dépôt sélectionné
    DepartData? depotStock;
    try {
      depotStock = widget.stocks.firstWhere(
        (s) => s.designation == article.designation && s.depots == widget.state.selectedDepot,
      );
    } catch (e) {
      depotStock = null;
    }

    // Si pas de répartition par dépôt, utiliser les stocks globaux
    final stockU1 = depotStock?.stocksu1?.toDouble() ?? article.stocksu1?.toDouble() ?? 0.0;
    final stockU2 = depotStock?.stocksu2?.toDouble() ?? article.stocksu2?.toDouble() ?? 0.0;
    final stockU3 = depotStock?.stocksu3?.toDouble() ?? article.stocksu3?.toDouble() ?? 0.0;

    // Conversion en unité de base (U3)
    final stockTotalU3 = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    final cmup = article.cmup ?? 0;
    final valeur = stockTotalU3 * cmup;

    Color statusColor = Colors.green;
    String status = 'En stock';

    if (stockTotalU3 <= 0) {
      statusColor = Colors.red;
      status = 'Rupture';
    } else if (article.usec != null && stockTotalU3 <= article.usec!) {
      statusColor = Colors.orange;
      status = 'Alerte';
    }

    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hoveredIndex = index;
          widget.onHoverChanged(index);
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredIndex = null;
          widget.onHoverChanged(null);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                article.designation,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                article.categorie ?? '',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                _formatStockDisplay(article, stockU1, stockU2, stockU3),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(AppFunctions.formatNumber(cmup), style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Text('${AppFunctions.formatNumber(valeur)} Ar', style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pagination buttons
  Widget _buildStockPagination() {
    final totalPages = widget.state.totalStockPages;
    final currentPage = widget.state.stockPage;

    if (totalPages <= 1) return const SizedBox.shrink();

    // Calculer la plage de pages à afficher (max 10)
    const maxVisiblePages = 10;
    int startPage = (currentPage ~/ maxVisiblePages) * maxVisiblePages;
    int endPage = (startPage + maxVisiblePages).clamp(0, totalPages);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 0 ? () => widget.onPageChanged(0) : null,
            icon: const Icon(Icons.first_page),
            tooltip: 'Aller au début',
          ),
          ElevatedButton(
            onPressed: currentPage > 0 ? () => widget.onPageChanged(currentPage - 1) : null,
            child: const Text('Précédent'),
          ),
          const SizedBox(width: 8),
          ...List.generate(endPage - startPage, (index) {
            final pageIndex = startPage + index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => widget.onPageChanged(pageIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pageIndex == currentPage ? Colors.blue : Colors.grey[300],
                  foregroundColor: pageIndex == currentPage ? Colors.white : Colors.black,
                ),
                child: Text('${pageIndex + 1}'),
              ),
            );
          }),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: currentPage < totalPages - 1 ? () => widget.onPageChanged(currentPage + 1) : null,
            child: const Text('Suivant'),
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () => widget.onPageChanged(totalPages - 1) : null,
            icon: const Icon(Icons.last_page),
            tooltip: 'Aller à la fin',
          ),
        ],
      ),
    );
  }

  /// Formater l'affichage du stock
  String _formatStockDisplay(Article article, double stockU1, double stockU2, double stockU3) {
    double stockTotalU3 = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    final stocksOptimaux = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: 0.0,
      quantiteU2: 0.0,
      quantiteU3: stockTotalU3,
    );

    return StockConverter.formaterAffichageStock(
      article: article,
      stockU1: stocksOptimaux['u1']!,
      stockU2: stocksOptimaux['u2']!,
      stockU3: stocksOptimaux['u3']!,
    );
  }
}
