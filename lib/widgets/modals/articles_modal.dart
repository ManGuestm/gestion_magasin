import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import 'add_article_modal.dart';

class ArticlesModal extends StatefulWidget {
  const ArticlesModal({super.key});

  @override
  State<ArticlesModal> createState() => _ArticlesModalState();
}

class _ArticlesModalState extends State<ArticlesModal> {
  List<Article> _articles = [];
  List<Article> _filteredArticles = [];
  List<Depot> _depots = [];
  final TextEditingController _searchController = TextEditingController();
  Article? _selectedArticle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _loadDepots();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          child: Container(
            width: 900,
            height: 600,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white),
            child: Column(
              children: [
                _buildHeader(),
                _buildContent(),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Row(
        children: [
          const Text(
            'Articles',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredArticles.length,
                itemExtent: 18,
                itemBuilder: (context, index) {
                  final article = _filteredArticles[index];
                  final isSelected = _selectedArticle?.designation == article.designation;
                  return GestureDetector(
                    onTap: () => _selectArticle(article),
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue[600] : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 200,
                            padding: const EdgeInsets.only(left: 4),
                            alignment: Alignment.centerLeft,
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey, width: 1),
                                bottom: BorderSide(color: Colors.grey, width: 1),
                              ),
                            ),
                            child: Text(
                              article.designation,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey, width: 1),
                                  bottom: BorderSide(color: Colors.grey, width: 1),
                                ),
                              ),
                              child: FutureBuilder<String>(
                                future: _getAllStocksText(article),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? 'Chargement...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey, width: 1),
                              ),
                            ),
                            child: Text(
                              article.action ?? 'A',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.black,
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
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 25,
      decoration: BoxDecoration(
        color: Colors.orange[300],
      ),
      child: Row(
        children: [
          Container(
            width: 200,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey, width: 1),
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            child: const Text(
              'DESIGNATION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1),
                  bottom: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const Text(
                'STOCKS DISPONIBLES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            width: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            child: const Text(
              'ACTION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        _buildStockSituation(),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildNavButton(Icons.first_page, _goToFirst),
              _buildNavButton(Icons.chevron_left, _goToPrevious),
              _buildNavButton(Icons.chevron_right, _goToNext),
              _buildNavButton(Icons.last_page, _goToLast),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 11),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      isDense: true,
                    ),
                    onChanged: _filterArticles,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: TextButton(
                  onPressed: _showAllArticles,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Afficher tous',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockSituation() {
    if (_selectedArticle == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red[300],
              border: const Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: const Text(
              'SITUATION DE STOCKS DANS CHAQUE DEPOTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            height: 25,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey),
                        bottom: BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: const Text(
                      'DEPOTS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: const Text(
                      'STOCKS DISPONIBLES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView.builder(
              itemCount: _depots.length,
              itemBuilder: (context, index) {
                final depot = _depots[index];
                return Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey),
                              bottom: BorderSide(color: Colors.grey, width: 0.5),
                            ),
                          ),
                          child: Text(
                            depot.depots,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey, width: 0.5),
                            ),
                          ),
                          child: FutureBuilder<DepartData?>(
                            future: _getStockForDepotFuture(depot.depots),
                            builder: (context, snapshot) {
                              return Text(
                                _getStockTextForDepot(snapshot.data),
                                style: const TextStyle(fontSize: 11),
                              );
                            },
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
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        color: Colors.grey[200],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Future<String> _getAllStocksText(Article article) async {
    final db = DatabaseService().database;
    final stocksDepart =
        await (db.select(db.depart)..where((d) => d.designation.equals(article.designation))).get();

    if (stocksDepart.isEmpty) {
      return 'Aucun stock';
    }

    List<String> stockTexts = [];

    for (var stock in stocksDepart) {
      List<String> unitStocks = [];

      // U1
      if (article.u1?.isNotEmpty == true && (stock.stocksu1 ?? 0) > 0) {
        unitStocks.add('${(stock.stocksu1 ?? 0).toStringAsFixed(0)} ${article.u1}');
      }

      // U2
      if (article.u2?.isNotEmpty == true && (stock.stocksu2 ?? 0) > 0) {
        unitStocks.add('${(stock.stocksu2 ?? 0).toStringAsFixed(0)} ${article.u2}');
      }

      // U3
      if (article.u3?.isNotEmpty == true && (stock.stocksu3 ?? 0) > 0) {
        unitStocks.add('${(stock.stocksu3 ?? 0).toStringAsFixed(0)} ${article.u3}');
      }

      if (unitStocks.isNotEmpty) {
        stockTexts.add('${stock.depots}: ${unitStocks.join(", ")}');
      }
    }

    return stockTexts.isEmpty ? 'Stock vide' : stockTexts.join(' | ');
  }

  void _selectArticle(Article article) {
    setState(() {
      _selectedArticle = article;
    });
  }

  Future<void> _loadDepots() async {
    final depots = await DatabaseService().database.getAllDepots();
    setState(() {
      _depots = depots;
    });
  }

  Future<DepartData?> _getStockForDepotFuture(String depotName) async {
    if (_selectedArticle == null) return null;

    return await (DatabaseService().database.select(DatabaseService().database.depart)
          ..where((d) => d.designation.equals(_selectedArticle!.designation))
          ..where((d) => d.depots.equals(depotName)))
        .getSingleOrNull();
  }

  String _getStockTextForDepot(DepartData? depart) {
    if (_selectedArticle == null) return '0';

    List<String> stocks = [];

    // Toujours afficher u1 si défini
    if (_selectedArticle!.u1?.isNotEmpty == true) {
      double stock1 = (depart?.stocksu1 ?? 0.0);
      stocks.add('${stock1.toStringAsFixed(0)} ${_selectedArticle!.u1}');
    }

    // Toujours afficher u2 si défini
    if (_selectedArticle!.u2?.isNotEmpty == true) {
      double stock2 = (depart?.stocksu2 ?? 0.0);
      stocks.add('${stock2.toStringAsFixed(0)} ${_selectedArticle!.u2}');
    }

    // Toujours afficher u3 si défini
    if (_selectedArticle!.u3?.isNotEmpty == true) {
      double stock3 = (depart?.stocksu3 ?? 0.0);
      stocks.add('${stock3.toStringAsFixed(0)} ${_selectedArticle!.u3}');
    }

    return stocks.isEmpty ? '0' : stocks.join(' / ');
  }

  Future<void> _loadArticles() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final articles = await DatabaseService().database.getAllArticles();
      // Trier par ordre croissant de désignation
      articles.sort((a, b) => a.designation.compareTo(b.designation));

      setState(() {
        _articles = articles;
        _filteredArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des articles: $e');
      setState(() {
        _articles = [];
        _filteredArticles = [];
        _isLoading = false;
      });
    }
  }

  void _filterArticles(String query) {
    if (query.length < 2 && query.isNotEmpty) return;

    setState(() {
      if (query.isEmpty) {
        _filteredArticles = _articles;
      } else {
        _filteredArticles = _articles
            .where((article) => article.designation.toLowerCase().contains(query.toLowerCase()))
            .toList();
        // Maintenir le tri après filtrage
        _filteredArticles.sort((a, b) => a.designation.compareTo(b.designation));
      }
    });
  }

  void _showAllArticles() {
    setState(() {
      _filteredArticles = _articles;
      _searchController.clear();
    });
  }

  void _goToFirst() {
    if (_filteredArticles.isNotEmpty) {
      _selectArticle(_filteredArticles.first);
    }
  }

  void _goToPrevious() {
    if (_selectedArticle != null && _filteredArticles.isNotEmpty) {
      final currentIndex =
          _filteredArticles.indexWhere((a) => a.designation == _selectedArticle?.designation);
      if (currentIndex > 0) {
        _selectArticle(_filteredArticles[currentIndex - 1]);
      }
    }
  }

  void _goToNext() {
    if (_selectedArticle != null && _filteredArticles.isNotEmpty) {
      final currentIndex =
          _filteredArticles.indexWhere((a) => a.designation == _selectedArticle?.designation);
      if (currentIndex < _filteredArticles.length - 1) {
        _selectArticle(_filteredArticles[currentIndex + 1]);
      }
    }
  }

  void _goToLast() {
    if (_filteredArticles.isNotEmpty) {
      _selectArticle(_filteredArticles.last);
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'create',
          child: Text('Créer', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'modify',
          child: Text('Modifier', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Supprimer', style: TextStyle(fontSize: 12)),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value);
      }
    });
  }

  void _handleContextMenuAction(String action) {
    switch (action) {
      case 'create':
        _showAddArticleModal();
        break;
      case 'modify':
        if (_selectedArticle != null) {
          _showAddArticleModal(article: _selectedArticle);
        }
        break;
      case 'delete':
        if (_selectedArticle != null) {
          _deleteArticle(_selectedArticle!);
        }
        break;
    }
  }

  void _showAddArticleModal({Article? article}) {
    showDialog(
      context: context,
      builder: (context) => AddArticleModal(article: article),
    ).then((_) => _loadArticles());
  }

  Future<void> _deleteArticle(Article article) async {
    try {
      await DatabaseService().database.deleteArticle(article.designation);
      await _loadArticles();
      if (_selectedArticle?.designation == article.designation) {
        setState(() {
          _selectedArticle = null;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
