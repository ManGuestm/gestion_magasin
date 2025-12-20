import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class ApproximationStocksModal extends StatefulWidget {
  const ApproximationStocksModal({super.key});

  @override
  State<ApproximationStocksModal> createState() => _ApproximationStocksModalState();
}

class _ApproximationStocksModalState extends State<ApproximationStocksModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Article> _articles = [];
  List<Article> _articlesFiltered = [];
  Map<String, Map<String, double>> _stocksParDepot = {};
  bool _isLoading = true;
  String _filterText = '';
  final TextEditingController _filterController = TextEditingController();
  String _selectedDepot = 'Tous les Dépôts';
  List<String> _depots = ['Tous les Dépôts'];

  late final FocusNode _filterFocusNode;

  @override
  void initState() {
    super.initState();

    // Initialize focus nodes with tab navigation
    _filterFocusNode = createFocusNode();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // ✅ Charger TOUS les articles actifs localement pour approximation stocks
      final articles = await _databaseService.database.getActiveArticles();
      final depots = await _databaseService.database.getAllDepots();

      // Charger les stocks par dépôt
      final stocksDepart = await _databaseService.database.select(_databaseService.database.depart).get();

      Map<String, Map<String, double>> stocksMap = {};
      for (var stock in stocksDepart) {
        if (!stocksMap.containsKey(stock.designation)) {
          stocksMap[stock.designation] = {};
        }
        stocksMap[stock.designation]![stock.depots] =
            (stock.stocksu1 ?? 0) + (stock.stocksu2 ?? 0) + (stock.stocksu3 ?? 0);
      }

      setState(() {
        _articles = articles;
        _articlesFiltered = articles;
        _stocksParDepot = stocksMap;
        _depots = ['Tous les Dépôts', ...depots.map((d) => d.depots)];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
      }
    }
  }

  void _filterArticles(String query) {
    setState(() {
      _filterText = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Article> filtered = _articles;

    // Filtre par texte
    if (_filterText.isNotEmpty) {
      filtered = filtered.where((article) {
        return article.designation.toLowerCase().contains(_filterText.toLowerCase());
      }).toList();
    }

    // Filtre par dépôt - ne montrer que les articles qui ont du stock dans ce dépôt
    if (_selectedDepot != 'Tous les Dépôts') {
      filtered = filtered.where((article) {
        return _stocksParDepot[article.designation]?.containsKey(_selectedDepot) == true &&
            (_stocksParDepot[article.designation]![_selectedDepot] ?? 0) > 0;
      }).toList();
    }

    setState(() {
      _articlesFiltered = filtered;
    });
  }

  double _getStockForDepot(Article article, String depot) {
    if (depot == 'Tous les Dépôts') {
      return (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);
    }

    // Retourner le stock du dépôt spécifique depuis la table depart
    return _stocksParDepot[article.designation]?[depot] ?? 0.0;
  }

  double _getValeurStock(Article article) {
    double stockTotal = _getStockForDepot(article, _selectedDepot);
    double cmup = article.cmup ?? 0.0;
    return stockTotal * cmup;
  }

  Color _getStockColor(Article article) {
    double stock = _getStockForDepot(article, _selectedDepot);
    double stockMin = 0.0;

    if (stock <= 0) return Colors.red;
    if (stock <= stockMin) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.grey[100],
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              color: Colors.grey[100],
            ),
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Title bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Approximation des Stocks',
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search field
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _filterController,
                          focusNode: _filterFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Rechercher (Désignation, Référence)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: _filterArticles,
                          onTap: () => updateFocusIndex(_filterFocusNode),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Depot filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedDepot,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          items: _depots.map((depot) {
                            return DropdownMenuItem<String>(
                              value: depot,
                              child: Text(depot, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDepot = value ?? 'Tous les Dépôts';
                              _applyFilters();
                            });
                          },
                        ),
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
                                  color: Colors.purple[100],
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
                                        child: Text(
                                          'Référence',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Center(
                                        child: Text(
                                          'Désignation',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          'Stock Actuel',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          'Stock Min',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          'Valeur Stock',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          'État',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Data rows
                              Expanded(
                                child: _articlesFiltered.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Aucun article trouvé',
                                          style: TextStyle(fontSize: 16, color: Colors.grey),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _articlesFiltered.length,
                                        itemBuilder: (context, index) {
                                          final article = _articlesFiltered[index];
                                          final stockActuel = _getStockForDepot(article, _selectedDepot);
                                          final valeurStock = _getValeurStock(article);
                                          final stockColor = _getStockColor(article);

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
                                                      article.designation.length > 8
                                                          ? article.designation.substring(0, 8)
                                                          : article.designation,
                                                      style: const TextStyle(fontSize: 11),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 4,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                                    child: Text(
                                                      article.designation,
                                                      style: const TextStyle(fontSize: 11),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Text(
                                                      NumberUtils.formatNumber(stockActuel),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: stockColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Text('0', style: TextStyle(fontSize: 11)),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Text(
                                                      NumberUtils.formatNumber(valeurStock),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                    child: Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: stockColor,
                                                        shape: BoxShape.circle,
                                                      ),
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

                // Legend and summary section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(Colors.red, 'Stock épuisé'),
                          const SizedBox(width: 20),
                          _buildLegendItem(Colors.orange, 'Stock faible'),
                          const SizedBox(width: 20),
                          _buildLegendItem(Colors.green, 'Stock normal'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: ${_articlesFiltered.length} article(s)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Valeur totale: ${NumberUtils.formatNumber(_articlesFiltered.fold(0.0, (sum, article) => sum + _getValeurStock(article)))}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
}
