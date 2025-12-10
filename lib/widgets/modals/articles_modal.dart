import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_constants.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/stock_management_service.dart';
import '../../utils/stock_converter.dart';
import '../common/article_navigation_autocomplete.dart';
import '../common/tab_navigation_widget.dart';
import 'add_article_modal.dart';
import 'historique_stock_modal.dart';
import 'mouvement_stock_modal.dart';

class ArticlesModal extends StatefulWidget {
  const ArticlesModal({super.key});

  @override
  State<ArticlesModal> createState() => _ArticlesModalState();
}

class _ArticlesModalState extends State<ArticlesModal> with TabNavigationMixin {
  List<Article> _articles = [];
  List<Article> _filteredArticles = [];
  List<Depot> _depots = [];
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus;
  late final FocusNode _keyboardFocusNode;
  Article? _selectedArticle;
  bool _isLoading = false;
  String? _sortColumn;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchFocus = createFocusNode();
    _keyboardFocusNode = createFocusNode();
    _loadArticles();
    _loadDepots();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyboardShortcut,
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: AppConstants.defaultModalWidth,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildModernHeader(),
                Expanded(
                  child: GestureDetector(
                    onSecondaryTapDown: AuthService().currentUserRole == 'Vendeur'
                        ? null
                        : (details) => _showContextMenu(context, details.globalPosition),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSearchCard(),
                          const SizedBox(height: 12),
                          _buildArticlesCard(),
                          const SizedBox(height: 12),
                          _buildStockSituation(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[700]!]),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Articles',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Gérer et consulter vos articles',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildHeaderButton(Icons.add, 'Nouveau', () => _showAddArticleModal()),
        const SizedBox(width: 8),
        _buildHeaderButton(Icons.refresh, 'Actualiser', _loadArticles),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.blue[600], size: 20),
            const SizedBox(width: 8),
            const Text('Rechercher:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ArticleNavigationAutocomplete(
                  articles: _articles,
                  selectedArticle: _selectedArticle,
                  onArticleChanged: (article) {
                    if (article != null) {
                      _selectArticle(article);
                    }
                  },
                  focusNode: _searchFocus,
                  hintText: 'Tapez le nom de l\'article...',
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'Tapez le nom de l\'article...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showAllArticles,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tout afficher'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[700],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesCard() {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildArticlesHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredArticles.length,
                itemExtent: 32,
                itemBuilder: (context, index) {
                  final article = _filteredArticles[index];
                  final isSelected = _selectedArticle?.designation == article.designation;
                  return _buildArticleRow(article, isSelected, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesHeader() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.blue[100]!]),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Row(
        children: [
          _buildSortableHeaderCell('DESIGNATION', 'designation', flex: 4),
          _buildSortableHeaderCell('STOCKS DISPONIBLES', 'stocks', flex: 5),
          _buildSortableHeaderCell('ACTION', 'action', width: 100),
        ],
      ),
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
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[700]!]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Text(
              'SITUATION DE STOCKS DANS CHAQUE DÉPÔT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.grey[200]!, Colors.grey[300]!]),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey[400]!, width: 1)),
                    ),
                    child: const Text(
                      'DÉPÔTS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'STOCKS DISPONIBLES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
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
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                          ),
                          child: Text(
                            depot.depots,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
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
                                style: const TextStyle(fontSize: 11, color: Colors.black87),
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

  Widget _buildSortableHeaderCell(String text, String column, {int? flex, double? width}) {
    Widget cell = GestureDetector(
      onTap: () => _sortBy(column),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[400]!, width: 1)),
          color: _sortColumn == column ? Colors.blue[50] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _sortColumn == column ? Colors.blue[800] : Colors.black87,
              ),
            ),
            if (_sortColumn == column)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Colors.blue[800],
              ),
          ],
        ),
      ),
    );

    if (flex != null) {
      return Expanded(flex: flex, child: cell);
    } else {
      return SizedBox(width: width, child: cell);
    }
  }

  Future<String> _getAllStocksText(Article article) async {
    try {
      final db = DatabaseService().database;
      final stocksDepart = await (db.select(
        db.depart,
      )..where((d) => d.designation.equals(article.designation))).get();

      if (stocksDepart.isEmpty) {
        return 'Aucun stock';
      }

      double totalU1 = 0, totalU2 = 0, totalU3 = 0;

      for (var stock in stocksDepart) {
        totalU1 += stock.stocksu1 ?? 0.0;
        totalU2 += stock.stocksu2 ?? 0.0;
        totalU3 += stock.stocksu3 ?? 0.0;
      }

      // Calculer le stock total en unité de base (U3) DIRECTEMENT
      double stockTotalU3 = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: totalU1,
        stockU2: totalU2,
        stockU3: totalU3,
      );

      // Convertir le stock total vers les unités optimales
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

    if (u1 == 0 && u2 == 0 && u3 == 0) return '0';

    // Calculer le stock total en unité de base (U3) DIRECTEMENT
    double stockTotalU3 = StockConverter.calculerStockTotalU3(
      article: _selectedArticle!,
      stockU1: u1,
      stockU2: u2,
      stockU3: u3,
    );

    // Convertir le stock total vers les unités optimales
    final stocksOptimaux = StockConverter.convertirStockOptimal(
      article: _selectedArticle!,
      quantiteU1: 0.0,
      quantiteU2: 0.0,
      quantiteU3: stockTotalU3,
    );

    return StockConverter.formaterAffichageStock(
      article: _selectedArticle!,
      stockU1: stocksOptimaux['u1']!,
      stockU2: stocksOptimaux['u2']!,
      stockU3: stocksOptimaux['u3']!,
    );
  }

  Widget _buildArticleRow(Article article, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _selectArticle(article),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : (index % 2 == 0 ? Colors.white : Colors.grey[25]),
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
                  style: TextStyle(fontSize: 12, color: isSelected ? Colors.blue[800] : Colors.black87),
                ),
              ),
            ),
            _buildStatusCell(article.action ?? 'A', isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status, bool isSelected) {
    final isActive = status == 'A';
    return Container(
      width: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[100] : Colors.red[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.green[300]! : Colors.red[300]!),
        ),
        child: Text(
          isActive ? 'Actif' : 'Inactif',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.green[700] : Colors.red[700],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child:
          child ??
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _buildNavButton(Icons.first_page, _goToFirst, 'Premier'),
          const SizedBox(width: 8),
          _buildNavButton(Icons.chevron_left, _goToPrevious, 'Précédent'),
          const SizedBox(width: 8),
          _buildNavButton(Icons.chevron_right, _goToNext, 'Suivant'),
          const SizedBox(width: 8),
          _buildNavButton(Icons.last_page, _goToLast, 'Dernier'),
          const Spacer(),
          if (_selectedArticle != null) ...[
            ElevatedButton.icon(
              onPressed: () => _showAddArticleModal(article: _selectedArticle),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[700],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _deleteArticle(_selectedArticle!),
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[700],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
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
        PopupMenuItem<String>(
          value: 'toggle_status',
          child: Text(
            _selectedArticle?.action == 'A' ? 'Désactiver' : 'Activer',
            style: const TextStyle(fontSize: 12),
          ),
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
      case 'toggle_status':
        if (_selectedArticle != null) {
          _toggleArticleStatus(_selectedArticle!);
        }
        break;
    }
  }

  void _showMouvementStock(TypeMouvement type) {
    showDialog(
      context: context,
      builder: (context) =>
          MouvementStockModal(refArticle: _selectedArticle!.designation, typeMouvement: type),
    ).then((result) {
      if (result == true) {
        _loadArticles(); // Recharger pour mettre à jour les stocks
      }
    });
  }

  void _showHistoriqueStock() {
    showDialog(
      context: context,
      builder: (context) => HistoriqueStockModal(refArticle: _selectedArticle!.designation),
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

  Future<void> _toggleArticleStatus(Article article) async {
    try {
      final newStatus = article.action == 'A' ? 'I' : 'A';
      await DatabaseService().database.updateArticle(
        ArticlesCompanion(designation: Value(article.designation), action: Value(newStatus)),
      );
      await _loadArticles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Article ${newStatus == 'A' ? 'activé' : 'désactivé'} avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du changement de statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du changement de statut'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[100],
          foregroundColor: Colors.blue[700],
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(36, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Icon(icon, size: 16),
      ),
    );
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

  Future<void> _loadArticles() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final articles = await DatabaseService().database.getAllArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      debugPrint('Erreur lors du chargement des articles: $e');
      setState(() {
        _articles = [];
        _filteredArticles = [];
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    List<Article> filtered = _articles;

    // Appliquer le tri
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        dynamic aValue, bValue;
        switch (_sortColumn) {
          case 'designation':
            aValue = a.designation;
            bValue = b.designation;
            break;
          case 'action':
            aValue = a.action ?? 'A';
            bValue = b.action ?? 'A';
            break;
          default:
            return 0;
        }

        int result = aValue.toString().compareTo(bValue.toString());
        return _sortAscending ? result : -result;
      });
    }

    setState(() {
      _filteredArticles = filtered;
    });
  }

  void _sortBy(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
    _applyFilter();
  }

  void _showAllArticles() {
    setState(() {
      _selectedArticle = null;
    });
    _applyFilter();
  }

  void _goToFirst() {
    if (_filteredArticles.isNotEmpty) {
      _selectArticle(_filteredArticles.first);
    }
  }

  void _goToPrevious() {
    if (_selectedArticle != null && _filteredArticles.isNotEmpty) {
      final currentIndex = _filteredArticles.indexWhere(
        (a) => a.designation == _selectedArticle?.designation,
      );
      if (currentIndex > 0) {
        _selectArticle(_filteredArticles[currentIndex - 1]);
      }
    }
  }

  void _goToNext() {
    if (_selectedArticle != null && _filteredArticles.isNotEmpty) {
      final currentIndex = _filteredArticles.indexWhere(
        (a) => a.designation == _selectedArticle?.designation,
      );
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

  void _handleKeyboardShortcut(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;

      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocus.requestFocus();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyC) {
        _copyTableData();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
        _showAddArticleModal();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyM) {
        if (_selectedArticle != null) {
          _showAddArticleModal(article: _selectedArticle);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.delete) {
        if (_selectedArticle != null) {
          _deleteArticle(_selectedArticle!);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }
}
