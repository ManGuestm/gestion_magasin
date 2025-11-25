import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_constants.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../mixins/form_navigation_mixin.dart';
import '../../services/stock_management_service.dart';
import '../../utils/stock_converter.dart';
import '../../widgets/common/base_modal.dart';
import '../common/tab_navigation_widget.dart';
import 'add_article_modal.dart';
import 'historique_stock_modal.dart';
import 'mouvement_stock_modal.dart';

class ArticlesModal extends StatefulWidget {
  const ArticlesModal({super.key});

  @override
  State<ArticlesModal> createState() => _ArticlesModalState();
}

class _ArticlesModalState extends State<ArticlesModal> with FormNavigationMixin, TabNavigationMixin {
  List<Article> _articles = [];
  List<Article> _filteredArticles = [];
  List<Depot> _depots = [];
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus;
  Article? _selectedArticle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchFocus = createFocusNode();
    _loadArticles();
    _loadDepots();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (HardwareKeyboard.instance.isControlPressed) {
            if (event.logicalKey == LogicalKeyboardKey.keyF) {
              _focusSearchField();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
              _copyTableData();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
              _selectAllArticles();
              return KeyEventResult.handled;
            }
          }
        }
        return handleTabNavigation(event);
      },
      child: BaseModal(
        title: 'Articles',
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.8,
        onNew: () => _showAddArticleModal(),
        onDelete: () => _selectedArticle != null ? _deleteArticle(_selectedArticle!) : null,
        onRefresh: _loadArticles,
        content: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          child: Column(
            children: [
              _buildContent(),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredArticles.length,
                itemExtent: 24,
                itemBuilder: (context, index) {
                  final article = _filteredArticles[index];
                  final isSelected = _selectedArticle?.designation == article.designation;
                  return _buildModernRow(article, isSelected, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[200]!, Colors.grey[300]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 1)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('DESIGNATION', flex: 4),
          _buildHeaderCell('STOCKS DISPONIBLES', flex: 5),
          _buildHeaderCell('ACTION', width: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int? flex, double? width}) {
    Widget cell = Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[400]!, width: 1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );

    if (flex != null) {
      return Expanded(flex: flex, child: cell);
    } else {
      return SizedBox(width: width, child: cell);
    }
  }

  Widget _buildModernRow(Article article, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectArticle(article),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
        ),
        child: Row(
          children: [
            _buildDataCell(
              article.designation,
              flex: 4,
              isSelected: isSelected,
              alignment: Alignment.centerLeft,
            ),
            _buildDataCell(
              '',
              flex: 5,
              isSelected: isSelected,
              alignment: Alignment.center,
              child: FutureBuilder<String>(
                future: _getAllStocksText(article),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? AppConstants.loadingMessage,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.blue[800] : Colors.black87,
                  ),
                ),
              ),
            ),
            _buildDataCell(
              article.action ?? 'A',
              width: 80,
              isSelected: isSelected,
              alignment: Alignment.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    int? flex,
    double? width,
    required bool isSelected,
    required Alignment alignment,
    Widget? child,
  }) {
    Widget cell = Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: child ??
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blue[800] : Colors.black87,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
    );

    if (flex != null) {
      return Expanded(flex: flex, child: cell);
    } else {
      return SizedBox(width: width, child: cell);
    }
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
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: const TextStyle(fontSize: 12),
                    onTap: () => updateFocusIndex(_searchFocus),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      isDense: true,
                      hintText: 'Rechercher (Ctrl+F)...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
                      prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey[500]),
                      focusedBorder: OutlineInputBorder(),
                      focusColor: Colors.blue,
                    ),
                    onChanged: _filterArticles,
                    onFieldSubmitted: (_) => _showAllArticles(),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[100]!, Colors.orange[200]!],
                  ),
                  border: Border.all(color: Colors.orange[300]!),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: _showAllArticles,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Afficher tous',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextButton(
                  onPressed: _copyTableData,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Copier (Ctrl+C)',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ],
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
                    style: TextStyle(fontSize: AppConstants.defaultFontSize, color: Colors.black),
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
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Text(
              'SITUATION DE STOCKS DANS CHAQUE DÉPÔT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[300]!],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey[400]!, width: 1),
                      ),
                    ),
                    child: const Text(
                      'DÉPÔTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'STOCKS DISPONIBLES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
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
                  height: 22,
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey[200]!, width: 0.5),
                            ),
                          ),
                          child: Text(
                            depot.depots,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FutureBuilder<DepartData?>(
                            future: _getStockForDepotFuture(depot.depots),
                            builder: (context, snapshot) {
                              return Text(
                                _getStockTextForDepot(snapshot.data),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
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
    try {
      final db = DatabaseService().database;
      final stocksDepart =
          await (db.select(db.depart)..where((d) => d.designation.equals(article.designation))).get();

      if (stocksDepart.isEmpty) {
        return 'Aucun stock';
      }

      List<String> stockTexts = [];
      double totalU1 = 0, totalU2 = 0, totalU3 = 0;

      for (var stock in stocksDepart) {
        final u1 = stock.stocksu1 ?? 0.0;
        final u2 = stock.stocksu2 ?? 0.0;
        final u3 = stock.stocksu3 ?? 0.0;

        totalU1 += u1;
        totalU2 += u2;
        totalU3 += u3;

        // Afficher TOUS les stocks par dépôt (même à 0 pour debug)
        final stockFormate = StockConverter.formaterAffichageStock(
          article: article,
          stockU1: u1,
          stockU2: u2,
          stockU3: u3,
        );

        stockTexts.add('${stock.depots}: $stockFormate');
      }

      // Toujours afficher le total
      final totalFormate = StockConverter.formaterAffichageStock(
        article: article,
        stockU1: totalU1,
        stockU2: totalU2,
        stockU3: totalU3,
      );

      if (stocksDepart.length > 1) {
        return totalFormate;
        // return 'Total: $totalFormate | ${stockTexts.join(' | ')}';
      } else {
        return stockTexts.first;
      }
    } catch (e) {
      return 'Erreur: ${e.toString()}';
    }
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
    if (_selectedArticle == null || depart == null) return '0';

    final u1 = depart.stocksu1 ?? 0.0;
    final u2 = depart.stocksu2 ?? 0.0;
    final u3 = depart.stocksu3 ?? 0.0;

    // Afficher les stocks réels avec formatage approprié
    final stockFormate = StockConverter.formaterAffichageStock(
      article: _selectedArticle!,
      stockU1: u1,
      stockU2: u2,
      stockU3: u3,
    );

    // Retourner 0 si aucun stock, sinon le stock formaté
    return (u1 == 0 && u2 == 0 && u3 == 0) ? '0' : stockFormate;
  }

  Future<void> _loadArticles() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Recharger les articles avec les stocks les plus récents
      final articles = await DatabaseService().database.getAllArticles();

      // Trier par ordre croissant de désignation
      articles.sort((a, b) => a.designation.compareTo(b.designation));

      setState(() {
        _articles = articles;
        _filteredArticles = articles;
        _isLoading = false;
      });

      // Forcer le rafraîchissement de l'affichage si un article est sélectionné
      if (_selectedArticle != null) {
        final updatedArticle = articles.firstWhere(
          (a) => a.designation == _selectedArticle!.designation,
          orElse: () => _selectedArticle!,
        );
        setState(() {
          _selectedArticle = updatedArticle;
        });
      }
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
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'create',
          child: Text('Créer', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem<String>(
          value: 'modify',
          child: Text('Modifier', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Supprimer', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'entree_stock',
          child: Text('Entrée Stock', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem<String>(
          value: 'sortie_stock',
          child: Text('Sortie Stock', style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem<String>(
          value: 'historique_stock',
          child: Text('Historique Stock', style: TextStyle(fontSize: 12)),
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
      case 'entree_stock':
        if (_selectedArticle != null) {
          _showMouvementStock(TypeMouvement.entree);
        }
        break;
      case 'sortie_stock':
        if (_selectedArticle != null) {
          _showMouvementStock(TypeMouvement.sortie);
        }
        break;
      case 'historique_stock':
        if (_selectedArticle != null) {
          _showHistoriqueStock();
        }
        break;
    }
  }

  void _showMouvementStock(TypeMouvement type) {
    showDialog(
      context: context,
      builder: (context) => MouvementStockModal(
        refArticle: _selectedArticle!.designation,
        typeMouvement: type,
      ),
    ).then((result) {
      if (result == true) {
        _loadArticles(); // Recharger pour mettre à jour les stocks
      }
    });
  }

  void _showHistoriqueStock() {
    showDialog(
      context: context,
      builder: (context) => HistoriqueStockModal(
        refArticle: _selectedArticle!.designation,
      ),
    );
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

  void _focusSearchField() {
    if (mounted) {
      FocusScope.of(context).requestFocus(_searchFocus);
    }
  }

  void _selectAllArticles() {
    // Sélectionner tous les articles visibles
    setState(() {
      // Logique de sélection multiple si nécessaire
    });
  }

  Future<void> _copyTableData() async {
    final buffer = StringBuffer();

    // En-têtes
    buffer.writeln('DESIGNATION\tSTOCKS DISPONIBLES\tACTION');

    // Données
    for (final article in _filteredArticles) {
      final stocks = await _getAllStocksText(article);
      buffer.writeln('${article.designation}\t$stocks\t${article.action ?? 'A'}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_filteredArticles.length} articles copiés dans le presse-papiers'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
