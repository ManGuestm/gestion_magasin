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
  final int _pageSize = 100;
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
                              child: Text(
                                _buildStockText(article),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
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
                          child: Text(
                            _getStockForDepot(depot.depots),
                            style: const TextStyle(fontSize: 11),
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

  String _buildStockText(Article article) {
    List<String> stocks = [];
    if (article.stocksu1 != null && article.u1 != null) {
      stocks.add('${article.stocksu1!.toStringAsFixed(2)} ${article.u1}');
    }
    if (article.stocksu2 != null && article.u2 != null) {
      stocks.add('${article.stocksu2!.toStringAsFixed(2)} ${article.u2}');
    }
    if (article.stocksu3 != null && article.u3 != null) {
      stocks.add('${article.stocksu3!.toStringAsFixed(2)} ${article.u3}');
    }
    return stocks.join(' / ');
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

  String _getStockForDepot(String depotName) {
    if (_selectedArticle == null) return '.00 Cm / .00 Pqt / .00';

    // For now, return the article's general stock info
    // In a real app, you'd query stock by depot
    List<String> stocks = [];
    if (_selectedArticle!.stocksu1 != null && _selectedArticle!.u1 != null) {
      stocks.add('${_selectedArticle!.stocksu1!.toStringAsFixed(2)} ${_selectedArticle!.u1}');
    }
    if (_selectedArticle!.stocksu2 != null && _selectedArticle!.u2 != null) {
      stocks.add('${_selectedArticle!.stocksu2!.toStringAsFixed(2)} ${_selectedArticle!.u2}');
    }
    if (_selectedArticle!.stocksu3 != null && _selectedArticle!.u3 != null) {
      stocks.add('${_selectedArticle!.stocksu3!.toStringAsFixed(2)} ${_selectedArticle!.u3}');
    }

    return stocks.isEmpty ? '.00 Cm / .00 Pqt / .00' : stocks.join(' / ');
  }

  Future<void> _loadArticles() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final articles = await DatabaseService().database.getAllArticles();
    setState(() {
      _articles = articles;
      _filteredArticles = articles.take(_pageSize).toList();
      _isLoading = false;
    });
  }

  void _filterArticles(String query) {
    if (query.length < 2 && query.isNotEmpty) return;

    setState(() {
      if (query.isEmpty) {
        _filteredArticles = _articles.take(_pageSize).toList();
      } else {
        final filtered = _articles
            .where((article) => article.designation.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _filteredArticles = filtered.take(_pageSize).toList();
      }
    });
  }

  void _showAllArticles() {
    setState(() {
      _filteredArticles = _articles.take(_pageSize).toList();
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
