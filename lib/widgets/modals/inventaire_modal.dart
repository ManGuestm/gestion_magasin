import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../models/inventaire_state.dart';
import '../../models/inventaire_stats.dart';
import '../../services/auth_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/stock_converter.dart';
import '../common/loading_overlay.dart';
import 'tabs/inventaire_tab_new.dart';
import 'tabs/mouvements_tab_new.dart';
import 'tabs/rapports_tab_new.dart';
import 'tabs/stock_tab_new.dart';

class InventaireModal extends StatefulWidget {
  const InventaireModal({super.key});

  @override
  State<InventaireModal> createState() => _InventaireModalState();
}

class _InventaireModalState extends State<InventaireModal> with TickerProviderStateMixin, LoadingMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  List<Article> _articles = [];
  List<Article> _filteredArticles = [];
  List<DepartData> stock = [];
  List<String> _depots = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedDepot = 'Tous';
  String _selectedCategorie = 'Toutes';
  List<String> _categories = [];
  Map<String, dynamic> _companyInfo = {};

  // Pagination optimisée
  static const int _itemsPerPage = 25; // Réduit pour de meilleures performances
  int _currentPage = 0;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingPage = false;

  // Inventaire physique avec virtualisation
  final Map<String, Map<String, double>> _inventairePhysique = {};
  final Map<String, TextEditingController> _inventaireControllers = {};
  bool _inventaireMode = false;
  DateTime? _dateInventaire;
  String _selectedDepotInventaire = '';
  int _inventairePage = 0;
  final ScrollController _inventaireScrollController = ScrollController();
  bool _isLoadingInventairePage = false;

  // Cache pour les données filtrées
  List<Article> cachedFilteredArticles = [];
  String _lastSearchQuery = '';
  String _lastSelectedCategorie = '';
  String _lastSelectedDepot = '';

  // Statistiques
  Map<String, dynamic> _stats = {};

  // État de survol
  int? _hoveredStockIndex;
  int? _hoveredInventaireIndex;

  // Recherche d'article pour inventaire
  final String inventaireSearchQuery = '';
  final FocusNode _inventaireSearchFocusNode = FocusNode();

  // Variables pour le tab Mouvements
  List<Stock> _mouvements = [];
  List<Stock> _filteredMouvements = [];
  int _mouvementsPage = 0;
  final ScrollController _mouvementsScrollController = ScrollController();
  DateTime? _dateDebutMouvement;
  DateTime? _dateFinMouvement;
  int? _hoveredMouvementIndex;

  @override
  void initState() {
    super.initState();

    // Vérifier les permissions
    if (_isVendeur()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accès refusé: Les vendeurs ne peuvent pas accéder à l\'inventaire'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }

    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  bool _isVendeur() {
    final authService = AuthService();
    return authService.currentUserRole == 'Vendeur';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _inventaireScrollController.dispose();
    _inventaireSearchFocusNode.dispose();
    _mouvementsScrollController.dispose();
    for (var controller in _inventaireControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Chargement asynchrone par batch pour éviter les blocages
      final articles = await _loadArticlesAsync();
      final stocks = await _loadStocksAsync();
      final companyInfo = await _loadCompanyInfoAsync();

      // Traitement asynchrone des métadonnées
      final metadata = await _processMetadataAsync(articles, stocks);

      if (mounted) {
        setState(() {
          _articles = articles;
          stock = stocks;
          _companyInfo = companyInfo;
          _depots = metadata['depots'] as List<String>;
          _categories = metadata['categories'] as List<String>;
          // Initialiser avec CDA par défaut pour l'inventaire
          if (_selectedDepotInventaire.isEmpty && _depots.isNotEmpty) {
            final depotsWithoutTous = _depots.where((d) => d != 'Tous').toList();
            _selectedDepotInventaire = depotsWithoutTous.contains('CDA') ? 'CDA' : depotsWithoutTous.first;
          }
          _isLoading = false;
        });

        // Calculer les stats et appliquer les filtres en arrière-plan
        _calculateStatsAsync();
        _applyFiltersAsync();
        _loadMouvementsAsync();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur lors du chargement: $e');
      }
    }
  }

  Future<List<Article>> _loadArticlesAsync() async {
    // ✅ Charger TOUS les articles actifs localement (pas de mode-aware)
    // L'inventaire physique doit être complet et immuable, indépendant du mode réseau
    return await _databaseService.database.getActiveArticles();
  }

  Future<List<DepartData>> _loadStocksAsync() async {
    return await _databaseService.database.select(_databaseService.database.depart).get();
  }

  Future<Map<String, dynamic>> _loadCompanyInfoAsync() async {
    try {
      final result = await _databaseService.database.customSelect('SELECT * FROM soc LIMIT 1').get();
      if (result.isNotEmpty) {
        final row = result.first.data;
        return {
          'nom': row['rsoc'] ?? 'GESTION DE MAGASIN',
          'activites': row['activites'] ?? '',
          'adresse': row['adr'] ?? '',
          'tel': row['tel'] ?? '',
          'port': row['port'] ?? '',
          'email': row['email'] ?? '',
          'nif': row['nif'] ?? '',
          'stat': row['stat'] ?? '',
          'rcs': row['rcs'] ?? '',
        };
      }
    } catch (e) {
      // Fallback si erreur
    }
    return {
      'nom': 'GESTION DE MAGASIN',
      'activites': '',
      'adresse': '',
      'tel': '',
      'port': '',
      'email': '',
      'nif': '',
      'stat': '',
      'rcs': '',
    };
  }

  Future<Map<String, List<String>>> _processMetadataAsync(
    List<Article> articles,
    List<DepartData> stocks,
  ) async {
    final depots = <String>{};
    final categories = <String>{};

    // Traitement par batch
    const batchSize = 100;

    for (int i = 0; i < stocks.length; i += batchSize) {
      final batch = stocks.skip(i).take(batchSize);
      for (final stock in batch) {
        depots.add(stock.depots);
      }
      if (i % (batchSize * 5) == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    for (int i = 0; i < articles.length; i += batchSize) {
      final batch = articles.skip(i).take(batchSize);
      for (final article in batch) {
        if (article.categorie != null && article.categorie!.isNotEmpty) {
          categories.add(article.categorie!);
        }
      }
      if (i % (batchSize * 5) == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    return {
      'depots': ['Tous', ...depots.toList()..sort()],
      'categories': ['Toutes', ...categories.toList()..sort()],
    };
  }

  Future<void> _calculateStatsAsync() async {
    final stats = await _calculateStats(_articles, stock);
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  Future<Map<String, dynamic>> _calculateStats(List<Article> articles, List<DepartData> stocks) async {
    double valeurTotale = 0;
    int articlesEnStock = 0;
    int articlesRupture = 0;
    int articlesAlerte = 0;

    // Traitement par batch pour éviter de bloquer l'UI
    const batchSize = 100;
    for (int i = 0; i < articles.length; i += batchSize) {
      final batch = articles.skip(i).take(batchSize);

      for (final article in batch) {
        // Utiliser la conversion d'unités pour le calcul des statistiques
        final stockTotalU3 = StockConverter.calculerStockTotalU3(
          article: article,
          stockU1: article.stocksu1?.toDouble() ?? 0.0,
          stockU2: article.stocksu2?.toDouble() ?? 0.0,
          stockU3: article.stocksu3?.toDouble() ?? 0.0,
        );
        final cmup = article.cmup ?? 0;

        valeurTotale += stockTotalU3 * cmup;

        if (stockTotalU3 > 0) {
          articlesEnStock++;
        } else {
          articlesRupture++;
        }
      }

      // Permettre à l'UI de se rafraîchir
      if (i % (batchSize * 5) == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    return {
      'valeurTotale': valeurTotale,
      'articlesEnStock': articlesEnStock,
      'articlesRupture': articlesRupture,
      'articlesAlerte': articlesAlerte,
      'totalArticles': articles.length,
    };
  }

  void _applyFilters() {
    _applyFiltersAsync();
  }

  Future<void> _applyFiltersAsync() async {
    // Utiliser le cache si les critères n'ont pas changé
    if (_searchQuery == _lastSearchQuery &&
        _selectedCategorie == _lastSelectedCategorie &&
        _selectedDepot == _lastSelectedDepot) {
      return;
    }

    final filteredArticles = <Article>[];
    const batchSize = 200;

    for (int i = 0; i < _articles.length; i += batchSize) {
      final batch = _articles.skip(i).take(batchSize);

      final batchFiltered = batch.where((article) {
        final matchesSearch =
            _searchQuery.isEmpty || article.designation.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategorie = _selectedCategorie == 'Toutes' || article.categorie == _selectedCategorie;

        // Filtrage par dépôt
        bool matchesDepot = true;
        if (_selectedDepot != 'Tous') {
          matchesDepot = stock.any((s) => s.designation == article.designation && s.depots == _selectedDepot);
        }

        return matchesSearch && matchesCategorie && matchesDepot;
      }).toList();

      filteredArticles.addAll(batchFiltered);

      // Pause pour éviter de bloquer l'UI
      if (i % (batchSize * 3) == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    if (mounted) {
      setState(() {
        _filteredArticles = filteredArticles;
        cachedFilteredArticles = List.from(filteredArticles);
        _lastSearchQuery = _searchQuery;
        _lastSelectedCategorie = _selectedCategorie;
        _lastSelectedDepot = _selectedDepot;
        _currentPage = 0;
        _inventairePage = 0;
        hasMoreData = filteredArticles.length > _itemsPerPage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.8,
          minWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.99,
        ),
        backgroundColor: Colors.grey[100],
        child: ScaffoldMessenger(
          key: _scaffoldMessengerKey,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStockTab(),
                      _buildInventaireTab(),
                      _buildMouvementsTab(),
                      _buildRapportsTab(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Gestion d\'Inventaire Professionnel',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_inventaireMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Mode Inventaire',
                    style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue,
        tabs: const [
          Tab(icon: Icon(Icons.storage), text: 'État des Stocks'),
          Tab(icon: Icon(Icons.fact_check), text: 'Inventaire Physique'),
          Tab(icon: Icon(Icons.swap_horiz), text: 'Mouvements'),
          Tab(icon: Icon(Icons.analytics), text: 'Rapports'),
        ],
      ),
    );
  }

  InventaireState _buildInventaireState() {
    return InventaireState.initial().copyWith(
      articles: _articles,
      stocks: stock,
      filteredArticles: _filteredArticles,
      searchQuery: _searchQuery,
      selectedDepot: _selectedDepot,
      selectedCategorie: _selectedCategorie,
      stockPage: _currentPage,
      depots: _depots,
      categories: _categories,
      stats: InventaireStats.fromMap(_stats),
      isLoading: _isLoading,
      hoveredStockIndex: _hoveredStockIndex,
      hoveredInventaireIndex: _hoveredInventaireIndex,
      hoveredMouvementIndex: _hoveredMouvementIndex,
      itemsPerPage: _itemsPerPage,
      inventaireMode: _inventaireMode,
      selectedDepotInventaire: _selectedDepotInventaire,
      inventairePage: _inventairePage,
      mouvementsPage: _mouvementsPage,
    );
  }

  Widget _buildStockTab() {
    return StockTabNew(
      state: _buildInventaireState(),
      stocks: stock,
      onSearchChanged: (value) {
        setState(() => _searchQuery = value);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_searchQuery == value) _applyFilters();
        });
      },
      onDepotChanged: (value) {
        setState(() => _selectedDepot = value);
        _applyFilters();
      },
      onCategorieChanged: (value) {
        setState(() => _selectedCategorie = value);
        _applyFilters();
      },
      onExport: _exportStock,
      onPageChanged: _changePage,
      onHoverChanged: (index) => setState(() => _hoveredStockIndex = index),
    );
  }

  DataRow buildArticleRow(Article article) {
    // Obtenir les stocks spécifiques au dépôt sélectionné
    DepartData? depotStock;
    try {
      depotStock = stock.firstWhere(
        (s) => s.designation == article.designation && s.depots == _selectedDepot,
      );
    } catch (e) {
      depotStock = null;
    }

    // Si pas de répartition par dépôt, utiliser les stocks globaux de l'article
    final stockU1 = depotStock?.stocksu1?.toDouble() ?? article.stocksu1?.toDouble() ?? 0.0;
    final stockU2 = depotStock?.stocksu2?.toDouble() ?? article.stocksu2?.toDouble() ?? 0.0;
    final stockU3 = depotStock?.stocksu3?.toDouble() ?? article.stocksu3?.toDouble() ?? 0.0;

    // Conversion en unité de base (U3) pour le calcul du stock total
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

    return DataRow(
      cells: [
        DataCell(Text(article.designation, style: const TextStyle(fontSize: 12))),
        DataCell(Text(article.categorie ?? '', style: const TextStyle(fontSize: 12))),
        DataCell(
          Text(_formatStockDisplay(article, stockU1, stockU2, stockU3), style: const TextStyle(fontSize: 12)),
        ),
        DataCell(Text('', style: const TextStyle(fontSize: 12))), // Colonne vide
        DataCell(Text('', style: const TextStyle(fontSize: 12))), // Colonne vide
        DataCell(Text(AppFunctions.formatNumber(cmup), style: const TextStyle(fontSize: 12))),
        DataCell(Text('${AppFunctions.formatNumber(valeur)} Ar', style: const TextStyle(fontSize: 12))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _changePage(int newPage) {
    if (_isLoadingPage) return;

    setState(() {
      _isLoadingPage = true;
      _currentPage = newPage;
    });

    // Chargement asynchrone de la nouvelle page
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _isLoadingPage = false);
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      }
    });
  }

  Widget _buildInventaireTab() {
    return InventaireTabNew(
      state: _buildInventaireState(),
      stocks: stock,
      inventaireMode: _inventaireMode,
      dateInventaire: _dateInventaire,
      selectedDepotInventaire: _selectedDepotInventaire,
      inventairePhysique: _inventairePhysique,
      onStartInventaire: _startInventaire,
      onCancelInventaire: _cancelInventaire,
      onSaveInventaire: _saveInventaire,
      onImportInventaire: _importInventaire,
      onDepotChanged: (depot) {
        setState(() => _selectedDepotInventaire = depot);
        _applyFilters();
      },
      onSaisie: (designation, values) {
        setState(() {
          final key = '${designation}_$_selectedDepotInventaire';
          _inventairePhysique[key] = {
            'u1': values['u1'] ?? 0.0,
            'u2': values['u2'] ?? 0.0,
            'u3': values['u3'] ?? 0.0,
          };
        });
      },
      onPageChanged: (page) {
        setState(() => _inventairePage = page);
      },
      onHoverChanged: (index) => setState(() => _hoveredInventaireIndex = index),
      onScrollToArticle: (article) => _scrollToArticle(article),
    );
  }



  Widget _buildVirtualizedInventaireList() {
    final startIndex = _inventairePage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredArticles.length);
    final pageArticles = _filteredArticles.sublist(startIndex, endIndex);

    return ListView.builder(
      controller: _inventaireScrollController,
      itemCount: pageArticles.length + 1, // +1 pour l'en-tête
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildInventaireTableHeader();
        }

        final article = pageArticles[index - 1];
        return _buildInventaireListItem(article);
      },
    );
  }

  Widget _buildInventaireTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(bottom: BorderSide(color: Colors.orange[200]!)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Désignation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 2,
            child: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            flex: 3,
            child: Text('Stocks Disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              'Physique U1',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Physique U2',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Physique U3',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text('Écarts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildInventaireListItem(Article article) {
    // Obtenir les stocks spécifiques au dépôt sélectionné pour l'inventaire
    DepartData? depotStock;
    try {
      depotStock = stock.firstWhere(
        (s) => s.designation == article.designation && s.depots == _selectedDepotInventaire,
      );
    } catch (e) {
      depotStock = null;
    }

    // Si pas de répartition par dépôt, utiliser les stocks globaux de l'article
    final stockU1 = depotStock?.stocksu1?.toDouble() ?? article.stocksu1?.toDouble() ?? 0.0;
    final stockU2 = depotStock?.stocksu2?.toDouble() ?? article.stocksu2?.toDouble() ?? 0.0;
    final stockU3 = depotStock?.stocksu3?.toDouble() ?? article.stocksu3?.toDouble() ?? 0.0;

    // Vérifier quelles unités sont disponibles
    final hasU1 = article.u1 != null && article.u1!.isNotEmpty;
    final hasU2 = article.u2 != null && article.u2!.isNotEmpty;
    final hasU3 = article.u3 != null && article.u3!.isNotEmpty;

    final key = '${article.designation}_$_selectedDepotInventaire';
    final physiqueU1 = _inventairePhysique[key]?['u1'] ?? 0;
    final physiqueU2 = _inventairePhysique[key]?['u2'] ?? 0;
    final physiqueU3 = _inventairePhysique[key]?['u3'] ?? 0;

    // Calculer les écarts en utilisant la conversion d'unité
    final stockTotalU3Theorique = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    final stockTotalU3Physique = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: physiqueU1,
      stockU2: physiqueU2,
      stockU3: physiqueU3,
    );

    final ecartTotalU3 = stockTotalU3Physique - stockTotalU3Theorique;

    // Convertir l'écart vers l'unité optimale pour l'affichage
    final ecartOptimal = StockConverter.convertirStockOptimal(
      article: article,
      quantiteU1: 0.0,
      quantiteU2: 0.0,
      quantiteU3: ecartTotalU3.abs(),
    );

    final ecartFormate = StockConverter.formaterAffichageStock(
      article: article,
      stockU1: ecartOptimal['u1']!,
      stockU2: ecartOptimal['u2']!,
      stockU3: ecartOptimal['u3']!,
    );

    final startIndex = _inventairePage * _itemsPerPage;
    final itemIndex = _filteredArticles.indexOf(article) - startIndex;
    final isHovered = _hoveredInventaireIndex == itemIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredInventaireIndex = itemIndex),
      onExit: (_) => setState(() => _hoveredInventaireIndex = null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.withValues(alpha: 0.1) : null,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                article.designation,
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                article.categorie ?? '',
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _formatStockDisplay(article, stockU1, stockU2, stockU3),
                style: const TextStyle(fontSize: 10),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 30,
                child: TextField(
                  textAlign: TextAlign.center,
                  enabled: hasU1,
                  controller: _getController(
                    '${article.designation}_${_selectedDepotInventaire}_u1',
                    physiqueU1,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    fillColor: hasU1 ? null : Colors.grey[200],
                    filled: !hasU1,
                  ),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  onChanged: hasU1
                      ? (value) {
                          final qty = double.tryParse(value) ?? 0;
                          final key = '${article.designation}_$_selectedDepotInventaire';
                          _inventairePhysique[key] = {..._inventairePhysique[key] ?? {}, 'u1': qty};
                          setState(() {});
                        }
                      : null,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 30,
                child: TextField(
                  textAlign: TextAlign.center,
                  enabled: hasU2,
                  controller: _getController(
                    '${article.designation}_${_selectedDepotInventaire}_u2',
                    physiqueU2,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    fillColor: hasU2 ? null : Colors.grey[200],
                    filled: !hasU2,
                  ),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  onChanged: hasU2
                      ? (value) {
                          final qty = double.tryParse(value) ?? 0;
                          final key = '${article.designation}_$_selectedDepotInventaire';
                          _inventairePhysique[key] = {..._inventairePhysique[key] ?? {}, 'u2': qty};
                          setState(() {});
                        }
                      : null,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 30,
                child: TextField(
                  textAlign: TextAlign.center,
                  enabled: hasU3,
                  controller: _getController(
                    '${article.designation}_${_selectedDepotInventaire}_u3',
                    physiqueU3,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    fillColor: hasU3 ? null : Colors.grey[200],
                    filled: !hasU3,
                  ),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  onChanged: hasU3
                      ? (value) {
                          final qty = double.tryParse(value) ?? 0;
                          final key = '${article.designation}_$_selectedDepotInventaire';
                          _inventairePhysique[key] = {..._inventairePhysique[key] ?? {}, 'u3': qty};
                          setState(() {});
                        }
                      : null,
                ),
              ),
            ),
            Expanded(
              child: Text(
                ecartTotalU3 == 0 ? 'Aucun écart' : '${ecartTotalU3 > 0 ? '+' : ''}$ecartFormate',
                style: TextStyle(
                  fontSize: 10,
                  color: ecartTotalU3 == 0 ? Colors.green : (ecartTotalU3 > 0 ? Colors.blue : Colors.red),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow buildInventaireRow(Article article) {
    // Obtenir les stocks spécifiques au dépôt sélectionné
    DepartData? depotStock;
    try {
      depotStock = stock.firstWhere(
        (s) => s.designation == article.designation && s.depots == _selectedDepotInventaire,
      );
    } catch (e) {
      depotStock = null;
    }

    // Si pas de répartition par dépôt, utiliser les stocks globaux de l'article
    final stockU1 = depotStock?.stocksu1?.toDouble() ?? article.stocksu1?.toDouble() ?? 0.0;
    final stockU2 = depotStock?.stocksu2?.toDouble() ?? article.stocksu2?.toDouble() ?? 0.0;
    final stockU3 = depotStock?.stocksu3?.toDouble() ?? article.stocksu3?.toDouble() ?? 0.0;

    final key = '${article.designation}_$_selectedDepotInventaire';
    final physiqueU1 = _inventairePhysique[key]?['u1'] ?? 0;
    final physiqueU2 = _inventairePhysique[key]?['u2'] ?? 0;
    final physiqueU3 = _inventairePhysique[key]?['u3'] ?? 0;

    final ecartU1 = physiqueU1 - stockU1;
    final ecartU2 = physiqueU2 - stockU2;
    final ecartU3 = physiqueU3 - stockU3;

    return DataRow(
      cells: [
        DataCell(Text(article.designation, style: const TextStyle(fontSize: 11))),
        DataCell(
          Text('${stockU1.toStringAsFixed(1)} ${article.u1 ?? ""}', style: const TextStyle(fontSize: 11)),
        ),
        DataCell(
          Text('${stockU2.toStringAsFixed(1)} ${article.u2 ?? ""}', style: const TextStyle(fontSize: 11)),
        ),
        DataCell(
          Text('${stockU3.toStringAsFixed(1)} ${article.u3 ?? ""}', style: const TextStyle(fontSize: 11)),
        ),
        DataCell(
          SizedBox(
            width: 60,
            height: 25,
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(0),
              ),
              style: const TextStyle(fontSize: 10),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0;
                final key = '${article.designation}_$_selectedDepotInventaire';
                _inventairePhysique[key] = {..._inventairePhysique[key] ?? {}, 'u1': qty};
                setState(() {});
              },
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 60,
            height: ecartU3,
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(0),
              ),
              style: const TextStyle(fontSize: 10),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0;
                final key = '${article.designation}_$_selectedDepotInventaire';
                _inventairePhysique[key] = {..._inventairePhysique[key] ?? {}, 'u2': qty};
                setState(() {});
              },
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 60,
            height: 25,
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(0),
              ),
              style: const TextStyle(fontSize: 10),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0;
                final key = '${article.designation}_$_selectedDepotInventaire';
                _inventairePhysique[key] = {..._inventairePhysique[key] ?? {}, 'u3': qty};
                setState(() {});
              },
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'U1: ${ecartU1.toStringAsFixed(1)} / ',
                style: TextStyle(
                  fontSize: 10,
                  color: ecartU1 == 0 ? Colors.green : (ecartU1 > 0 ? Colors.blue : Colors.red),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'U2: ${ecartU2.toStringAsFixed(1)} / ',
                style: TextStyle(
                  fontSize: 10,
                  color: ecartU2 == 0 ? Colors.green : (ecartU2 > 0 ? Colors.blue : Colors.red),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'U3: ${ecartU3.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 10,
                  color: ecartU3 == 0 ? Colors.green : (ecartU3 > 0 ? Colors.blue : Colors.red),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventairePagination() {
    final totalPages = (_filteredArticles.length / _itemsPerPage).ceil();

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _inventairePage > 0 ? () => _changeInventairePage(_inventairePage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Page ${_inventairePage + 1} sur $totalPages (${_filteredArticles.length} articles)',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            onPressed: _inventairePage < totalPages - 1
                ? () => _changeInventairePage(_inventairePage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _changeInventairePage(int newPage) {
    if (_isLoadingInventairePage) return;

    setState(() {
      _isLoadingInventairePage = true;
      _inventairePage = newPage;
    });

    // Chargement asynchrone de la nouvelle page
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _isLoadingInventairePage = false);
        _inventaireScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _scrollToArticle(Article article) {
    final articleIndex = _filteredArticles.indexWhere((a) => a.designation == article.designation);
    if (articleIndex == -1) return;

    final targetPage = articleIndex ~/ _itemsPerPage;

    if (targetPage != _inventairePage) {
      setState(() {
        _inventairePage = targetPage;
      });
    }

    // Scroll to the specific item within the page
    Future.delayed(const Duration(milliseconds: 100), () {
      final itemIndexInPage = articleIndex % _itemsPerPage;
      const itemHeight = 60.0; // Approximate height of each item
      final targetOffset = (itemIndexInPage + 1) * itemHeight; // +1 for header

      _inventaireScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildMouvementsTab() {
    return MouvementsTabNew(
      state: _buildInventaireState(),
      allMouvements: _filteredMouvements,
      onApplyFilters: _applyMouvementsFilters,
      onDepotChanged: (depot) {
        setState(() => _selectedDepot = depot);
        _applyMouvementsFilters();
      },
      onSearchChanged: (value) {},
      onTypeChanged: (type) {},
      onDateRangeChanged: (range) {},
      onExport: _exportMouvements,
      onPageChanged: (page) {
        setState(() => _mouvementsPage = page);
      },
      onHoverChanged: (index) => setState(() => _hoveredMouvementIndex = index),
    );
  }



  Widget _buildVirtualizedMouvementsList() {
    final startIndex = _mouvementsPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredMouvements.length);
    final pageMouvements = _filteredMouvements.sublist(startIndex, endIndex);

    return ListView.builder(
      controller: _mouvementsScrollController,
      itemCount: pageMouvements.length + 1, // +1 pour l'en-tête
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildMouvementsTableHeader();
        }

        final mouvement = pageMouvements[index - 1];
        return _buildMouvementListItem(mouvement, index - 1);
      },
    );
  }

  Widget _buildMouvementsTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text('Article', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text('Dépôt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text('Entrée', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text('Sortie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Libellé',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMouvementListItem(Stock mouvement, int index) {
    final isHovered = _hoveredMouvementIndex == index;
    final isEntree = (mouvement.qe ?? 0) > 0;
    final isSortie = (mouvement.qs ?? 0) > 0;

    Color typeColor = Colors.grey;
    if (isEntree) typeColor = Colors.green;
    if (isSortie) typeColor = Colors.red;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredMouvementIndex = index),
      onExit: (_) => setState(() => _hoveredMouvementIndex = null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.withValues(alpha: 0.1) : null,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(AppFunctions.formatDate(mouvement.daty), style: const TextStyle(fontSize: 11)),
            ),
            Expanded(
              flex: 3,
              child: Text(
                mouvement.refart ?? '',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text(mouvement.depots ?? '', style: const TextStyle(fontSize: 11))),
            Expanded(
              child: Text(
                isEntree ? '${mouvement.qe ?? 0} ${mouvement.ue ?? 0}' : '',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: isEntree ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Expanded(
              child: Text(
                isSortie ? '${mouvement.qs ?? 0} ${mouvement.us ?? 0}' : '',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: isSortie ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: typeColor, width: 0.5),
                ),
                child: Text(
                  mouvement.verification ?? '',
                  style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                textAlign: TextAlign.center,
                mouvement.lib ?? '',
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMouvementsPagination() {
    final totalPages = (_filteredMouvements.length / _itemsPerPage).ceil();

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _mouvementsPage > 0 ? () => _changeMouvementsPage(_mouvementsPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Page ${_mouvementsPage + 1} sur $totalPages (${_filteredMouvements.length} mouvements)',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            onPressed: _mouvementsPage < totalPages - 1
                ? () => _changeMouvementsPage(_mouvementsPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildRapportsTab() {
    return RapportsTabNew(
      state: _buildInventaireState(),
      stats: _stats,
      onRefreshStats: () async {
        setState(() => _isLoading = true);
        try {
          await _calculateStatsAsync();
        } finally {
          setState(() => _isLoading = false);
        }
      },
      onGenerateExcel: _exportToExcel,
      onGeneratePDF: _exportToPdf,
    );
  }

  void _startInventaire() {
    setState(() {
      _inventaireMode = true;
      _dateInventaire = DateTime.now();
      _inventairePhysique.clear();
    });
  }

  Future<void> _importInventaire() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        dialogTitle: 'Sélectionner un fichier Excel',
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) {
        _showError('Erreur: Chemin de fichier invalide');
        return;
      }

      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        _showError('Le fichier Excel est vide');
        return;
      }

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        _showError('La feuille Excel est vide');
        return;
      }

      int imported = 0;
      int errors = 0;

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.length < 4) continue;

        final designation = row[0]?.value?.toString().trim();
        final u1 = double.tryParse(row[1]?.value?.toString() ?? '0') ?? 0;
        final u2 = double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0;
        final u3 = double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0;

        if (designation == null || designation.isEmpty) continue;

        final article = _articles.where((a) => a.designation == designation).firstOrNull;
        if (article == null) {
          errors++;
          continue;
        }

        final key = '${article.designation}_$_selectedDepotInventaire';
        _inventairePhysique[key] = {'u1': u1, 'u2': u2, 'u3': u3};
        imported++;
      }

      setState(() {
        _inventaireMode = true;
        _dateInventaire = DateTime.now();
      });

      _showSuccess('Import réussi: $imported articles importés${errors > 0 ? ', $errors erreurs' : ''}');
    } catch (e) {
      _showError('Erreur lors de l\'importation: $e');
    }
  }

  void _cancelInventaire() {
    setState(() {
      _inventaireMode = false;
      _dateInventaire = null;
      _inventairePhysique.clear();
    });
  }

  Future<void> _saveInventaire() async {
    try {
      int globalIndex = 0;
      await _databaseService.database.transaction(() async {
        for (final entry in _inventairePhysique.entries) {
          final parts = entry.key.split('_');
          final designation = parts[0];
          final depot = parts[1];
          final quantities = entry.value;

          // Récupérer les stocks actuels
          final article = await _databaseService.database.getArticleByDesignation(designation);
          if (article != null) {
            // Utiliser StockConverter pour optimiser les stocks actuels
            final stocksOptimises = StockConverter.convertirStockOptimal(
              article: article,
              quantiteU1: article.stocksu1 ?? 0,
              quantiteU2: article.stocksu2 ?? 0,
              quantiteU3: article.stocksu3 ?? 0,
            );

            final stockActuelU1 = stocksOptimises['u1']!;

            // Optimiser aussi les nouvelles quantités d'inventaire
            final nouveauxStocksOptimises = StockConverter.convertirStockOptimal(
              article: article,
              quantiteU1: quantities['u1'] ?? 0,
              quantiteU2: quantities['u2'] ?? 0,
              quantiteU3: quantities['u3'] ?? 0,
            );

            final nouveauU1 = nouveauxStocksOptimises['u1']!;
            final nouveauU2 = nouveauxStocksOptimises['u2']!;
            final nouveauU3 = nouveauxStocksOptimises['u3']!;

            // Créer des mouvements "Report à nouveau" pour chaque unité avec écart
            final stockActuelU2 = stocksOptimises['u2']!;
            final stockActuelU3 = stocksOptimises['u3']!;

            final dateTimestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

            if (nouveauU1 != stockActuelU1) {
              final microseconds = DateTime.now().microsecondsSinceEpoch;
              final ref = 'INV${dateTimestamp}_U1_${globalIndex}_$microseconds';
              await _databaseService.database.customStatement(
                'INSERT INTO stocks (ref, daty, lib, refart, qe, qs, depots, verification, ue, us, pue, pus, cmup) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                  ref,
                  dateTimestamp,
                  "Report à nouveau - Inventaire ${AppDateUtils.formatDate(_dateInventaire!)} - $designation ${article.u1 ?? ''}",
                  designation,
                  nouveauU1 > stockActuelU1 ? nouveauU1 - stockActuelU1 : 0,
                  stockActuelU1 > nouveauU1 ? stockActuelU1 - nouveauU1 : 0,
                  depot,
                  'INVENTAIRE',
                  article.u1 ?? '',
                  article.u1 ?? '',
                  article.pvu1 ?? 0,
                  article.pvu1 ?? 0,
                  article.cmup ?? 0,
                ],
              );

              // Insérer dans fstocks pour traçabilité
              final fstockRef = 'FS-INV${dateTimestamp}_${designation}_U1_${globalIndex}_$microseconds';
              await _databaseService.database.customStatement(
                'INSERT INTO fstocks (ref, art, qe, qs, qst, ue) VALUES (?, ?, ?, ?, ?, ?)',
                [
                  fstockRef,
                  designation,
                  nouveauU1 > stockActuelU1 ? nouveauU1 - stockActuelU1 : 0,
                  stockActuelU1 > nouveauU1 ? stockActuelU1 - nouveauU1 : 0,
                  0,
                  article.u1 ?? '',
                ],
              );
              globalIndex++;
              await Future.delayed(const Duration(milliseconds: 1));
            }

            if (nouveauU2 != stockActuelU2) {
              final microseconds = DateTime.now().microsecondsSinceEpoch;
              final ref = 'INV${dateTimestamp}_U2_${globalIndex}_$microseconds';
              await _databaseService.database.customStatement(
                'INSERT INTO stocks (ref, daty, lib, refart, qe, qs, depots, verification, ue, us, pue, pus, cmup) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                  ref,
                  dateTimestamp,
                  'Report à nouveau - Inventaire ${AppDateUtils.formatDate(_dateInventaire!)} - $designation ${article.u2 ?? ''}',
                  designation,
                  nouveauU2 > stockActuelU2 ? nouveauU2 - stockActuelU2 : 0,
                  stockActuelU2 > nouveauU2 ? stockActuelU2 - nouveauU2 : 0,
                  depot,
                  'INVENTAIRE',
                  article.u2 ?? '',
                  article.u2 ?? '',
                  article.pvu2 ?? 0,
                  article.pvu2 ?? 0,
                  article.cmup ?? 0,
                ],
              );

              // Insérer dans fstocks pour traçabilité
              final fstockRef = 'FS-INV${dateTimestamp}_${designation}_U2_${globalIndex}_$microseconds';
              await _databaseService.database.customStatement(
                'INSERT INTO fstocks (ref, art, qe, qs, qst, ue) VALUES (?, ?, ?, ?, ?, ?)',
                [
                  fstockRef,
                  designation,
                  nouveauU2 > stockActuelU2 ? nouveauU2 - stockActuelU2 : 0,
                  stockActuelU2 > nouveauU2 ? stockActuelU2 - nouveauU2 : 0,
                  0,
                  article.u2 ?? '',
                ],
              );
              globalIndex++;
              await Future.delayed(const Duration(milliseconds: 1));
            }

            if (nouveauU3 != stockActuelU3) {
              final microseconds = DateTime.now().microsecondsSinceEpoch;
              final ref = 'INV${dateTimestamp}_U3_${globalIndex}_$microseconds';
              await _databaseService.database.customStatement(
                'INSERT INTO stocks (ref, daty, lib, refart, qe, qs, depots, verification, ue, us, pue, pus, cmup) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                  ref,
                  dateTimestamp,
                  'Report à nouveau - Inventaire ${AppDateUtils.formatDate(_dateInventaire!)} - - $designation ${article.u3 ?? ''}',
                  designation,
                  nouveauU3 > stockActuelU3 ? nouveauU3 - stockActuelU3 : 0,
                  stockActuelU3 > nouveauU3 ? stockActuelU3 - nouveauU3 : 0,
                  depot,
                  'INVENTAIRE',
                  article.u3 ?? '',
                  article.u3 ?? '',
                  article.pvu3 ?? 0,
                  article.pvu3 ?? 0,
                  article.cmup ?? 0,
                ],
              );

              // Insérer dans fstocks pour traçabilité
              final fstockRef = 'FS-INV${dateTimestamp}_${designation}_U3_${globalIndex}_$microseconds';
              await _databaseService.database.customStatement(
                'INSERT INTO fstocks (ref, art, qe, qs, qst, ue) VALUES (?, ?, ?, ?, ?, ?)',
                [
                  fstockRef,
                  designation,
                  nouveauU3 > stockActuelU3 ? nouveauU3 - stockActuelU3 : 0,
                  stockActuelU3 > nouveauU3 ? stockActuelU3 - nouveauU3 : 0,
                  0,
                  article.u3 ?? '',
                ],
              );
              globalIndex++;
              await Future.delayed(const Duration(milliseconds: 1));
            }

            // Mettre à jour les stocks
            await _databaseService.database.customStatement(
              'UPDATE depart SET stocksu1 = ?, stocksu2 = ?, stocksu3 = ? WHERE designation = ? AND depots = ?',
              [nouveauU1, nouveauU2, nouveauU3, designation, depot],
            );

            await _databaseService.database.customStatement(
              'UPDATE articles SET stocksu1 = ?, stocksu2 = ?, stocksu3 = ? WHERE designation = ?',
              [nouveauU1, nouveauU2, nouveauU3, designation],
            );
          }
        }
      });

      _showSuccess('Inventaire sauvegardé avec succès');
      setState(() {
        _inventaireMode = false;
        _dateInventaire = null;
        _inventairePhysique.clear();
      });
      await _loadData();
      await _loadMouvementsAsync();
    } catch (e) {
      _showError('Erreur lors de la sauvegarde: $e');
    }
  }

  void _showError(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: SelectableText(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: SelectableText(message), backgroundColor: Colors.green),
    );
  }

  // Méthodes pour le tab Mouvements
  Future<void> _loadMouvementsAsync() async {
    try {
      final mouvements = await _databaseService.database.getAllStocks();
      if (mounted) {
        setState(() {
          _mouvements = mouvements;
        });
        _applyMouvementsFilters();
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur lors du chargement des mouvements: $e');
      }
    }
  }

  void _applyMouvementsFilters() {
    final filteredMouvements = _mouvements.where((mouvement) {
      // Filtre par dépôt
      final matchesDepot = _selectedDepot == 'Tous' || mouvement.depots == _selectedDepot;

      // Filtre par date avec conversion timestamp
      bool matchesDate = true;
      if (_dateDebutMouvement != null && _dateFinMouvement != null && mouvement.daty != null) {
        try {
          DateTime mouvementDate;
          if (mouvement.daty is int) {
            mouvementDate = DateTime.fromMillisecondsSinceEpoch((mouvement.daty as int) * 1000);
          } else if (mouvement.daty is DateTime) {
            mouvementDate = mouvement.daty as DateTime;
          } else {
            return matchesDepot;
          }

          matchesDate =
              mouvementDate.isAfter(_dateDebutMouvement!.subtract(const Duration(days: 1))) &&
              mouvementDate.isBefore(_dateFinMouvement!.add(const Duration(days: 1)));
        } catch (e) {
          matchesDate = true;
        }
      }

      return matchesDepot && matchesDate;
    }).toList();

    // Trier par date décroissante avec gestion des timestamps
    filteredMouvements.sort((a, b) {
      if (a.daty == null && b.daty == null) return 0;
      if (a.daty == null) return 1;
      if (b.daty == null) return -1;

      try {
        int timestampA = a.daty is int ? a.daty as int : (a.daty as DateTime).millisecondsSinceEpoch ~/ 1000;
        int timestampB = b.daty is int ? b.daty as int : (b.daty as DateTime).millisecondsSinceEpoch ~/ 1000;
        return timestampB.compareTo(timestampA);
      } catch (e) {
        return 0;
      }
    });

    setState(() {
      _filteredMouvements = filteredMouvements;
      _mouvementsPage = 0;
    });
  }

  void _changeMouvementsPage(int newPage) {
    setState(() => _mouvementsPage = newPage);
    _mouvementsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateDebutMouvement != null && _dateFinMouvement != null
          ? DateTimeRange(start: _dateDebutMouvement!, end: _dateFinMouvement!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _dateDebutMouvement = picked.start;
        _dateFinMouvement = picked.end;
      });
      _applyMouvementsFilters();
    }
  }

  void _exportRapports() {
    _showSuccess('Export des rapports en cours - Fonctionnalité à implémenter');
  }

  TextEditingController _getController(String key, double value) {
    if (!_inventaireControllers.containsKey(key)) {
      _inventaireControllers[key] = TextEditingController(text: value > 0 ? value.toString() : '');
    }
    return _inventaireControllers[key]!;
  }

  Future<void> _exportStock() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Format d\'export'),
        content: const Text('Choisissez le format d\'export :'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'excel'), child: const Text('Excel')),
          TextButton(onPressed: () => Navigator.pop(context, 'pdf'), child: const Text('PDF')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );

    if (result == 'excel') {
      await _exportToExcel();
    } else if (result == 'pdf') {
      await _exportToPdf();
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Inventaire'];

      // En-tête professionnel
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        '${_companyInfo['nom']} - INVENTAIRE DES STOCKS',
      );
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        '${_companyInfo['adresse']} - Tél: ${_companyInfo['tel']}',
      );
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'Date: ${AppDateUtils.formatDate(DateTime.now())} - Total articles: ${_filteredArticles.length}',
      );

      // En-têtes de colonnes
      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Article');
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue('Catégorie');
      sheet.cell(CellIndex.indexByString('C5')).value = TextCellValue('Stock U1');
      sheet.cell(CellIndex.indexByString('D5')).value = TextCellValue('Stock U2');
      sheet.cell(CellIndex.indexByString('E5')).value = TextCellValue('Stock U3');
      sheet.cell(CellIndex.indexByString('F5')).value = TextCellValue('CMUP');
      sheet.cell(CellIndex.indexByString('G5')).value = TextCellValue('Valeur');
      sheet.cell(CellIndex.indexByString('H5')).value = TextCellValue('Statut');

      for (int i = 0; i < _filteredArticles.length; i++) {
        final article = _filteredArticles[i];
        final row = i + 6;
        final stockTotal = (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);
        final cmup = article.cmup ?? 0;
        final valeur = stockTotal * cmup;

        String status = 'En stock';
        if (stockTotal <= 0) {
          status = 'Rupture';
        } else if (article.usec != null && stockTotal <= article.usec!) {
          status = 'Alerte';
        }

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(
          article.designation,
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(
          article.categorie ?? '',
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = DoubleCellValue(
          article.stocksu1 ?? 0,
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(
          article.stocksu2 ?? 0,
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(
          article.stocksu3 ?? 0,
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(cmup);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(valeur);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(status);
      }

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}';
      final file = File('${directory.path}/inventaire_$dateStr.xlsx');
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        _showSuccess('Export Excel réussi: ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur export Excel: $e');
      }
    }
  }

  Future<void> _exportToPdf() async {
    try {
      final pdf = pw.Document();
      const itemsPerPage = 40;
      final totalPages = (_filteredArticles.length / itemsPerPage).ceil();

      for (int i = 0; i < _filteredArticles.length; i += itemsPerPage) {
        final endIndex = (i + itemsPerPage).clamp(0, _filteredArticles.length);
        final pageArticles = _filteredArticles.sublist(i, endIndex);
        final currentPage = (i / itemsPerPage).floor() + 1;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'INVENTAIRE DES STOCKS',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'SOCIÉTÉ:',
                                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(
                                    '${_companyInfo['nom']}',
                                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(
                                    '${_companyInfo['adresse']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  pw.Text(
                                    'RCS: ${_companyInfo['rcs']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  pw.Text(
                                    'STAT: ${_companyInfo['stat']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  pw.Text(
                                    'NIF: ${_companyInfo['nif']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  pw.Text(
                                    'Email: ${_companyInfo['email']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  pw.Text(
                                    'Tél: ${_companyInfo['tel']} / ${_companyInfo['port']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    'N° DOC: INV${DateTime.now().millisecondsSinceEpoch}',
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                  pw.Text(
                                    'DATE: ${AppDateUtils.formatDate(DateTime.now())}',
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                  pw.Text(
                                    'PAGE: $currentPage/$totalPages',
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Expanded(
                    child: pw.TableHelper.fromTextArray(
                      headers: [
                        'Article',
                        'Catégorie',
                        'Stock U1',
                        'Stock U2',
                        'Stock U3',
                        'CMUP',
                        'Valeur',
                        'Statut',
                      ],
                      data: pageArticles.map((article) {
                        final stockTotal =
                            (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);
                        final cmup = article.cmup ?? 0;
                        final valeur = stockTotal * cmup;

                        String status = 'En stock';
                        if (stockTotal <= 0) {
                          status = 'Rupture';
                        } else if (article.usec != null && stockTotal <= article.usec!) {
                          status = 'Alerte';
                        }

                        return [
                          article.designation,
                          article.categorie ?? '',
                          '${article.stocksu1 ?? ''} ${article.u1 ?? ''}',
                          '${article.u2 == null ? '' : article.stocksu2} ${article.u2 ?? ''}',
                          '${article.u3 == null ? '' : article.stocksu3} ${article.u3 ?? ''}',
                          '${AppFunctions.formatNumber(cmup)} Ar',
                          '${AppFunctions.formatNumber(valeur)} Ar',
                          status,
                        ];
                      }).toList(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      cellStyle: const pw.TextStyle(fontSize: 8),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      cellHeight: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}';
      final file = File('${directory.path}/inventaire_$dateStr.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        _showSuccess('Export PDF réussi: ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur export PDF: $e');
      }
    }
  }

  Future<void> _exportMouvements() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Format d\'export'),
        content: const Text('Choisissez le format d\'export pour les mouvements :'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'excel'), child: const Text('Excel')),
          TextButton(onPressed: () => Navigator.pop(context, 'pdf'), child: const Text('PDF')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );

    if (result == 'excel') {
      await _exportMouvementsToExcel();
    } else if (result == 'pdf') {
      await _exportMouvementsToPdf();
    }
  }

  Future<void> _exportMouvementsToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Mouvements'];

      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        '${_companyInfo['nom']} - MOUVEMENTS DE STOCK',
      );
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        '${_companyInfo['adresse']} - Tél: ${_companyInfo['tel']}',
      );
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'Date: ${AppDateUtils.formatDate(DateTime.now())} - Total mouvements: ${_filteredMouvements.length}',
      );

      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Date');
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue('Article');
      sheet.cell(CellIndex.indexByString('C5')).value = TextCellValue('Dépôt');
      sheet.cell(CellIndex.indexByString('D5')).value = TextCellValue('Type');
      sheet.cell(CellIndex.indexByString('E5')).value = TextCellValue('Entrées');
      sheet.cell(CellIndex.indexByString('F5')).value = TextCellValue('Sorties');
      sheet.cell(CellIndex.indexByString('G5')).value = TextCellValue('Stock Final');

      for (int i = 0; i < _filteredMouvements.length; i++) {
        final mouvement = _filteredMouvements[i];
        final row = i + 6;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(
          AppDateUtils.formatDate(mouvement.daty ?? DateTime.now()),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(
          mouvement.refart ?? '',
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(
          mouvement.depots ?? '',
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(
          mouvement.verification ?? '',
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(
          mouvement.qe ?? 0,
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(
          mouvement.qs ?? 0,
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(
          (mouvement.qe ?? 0) - (mouvement.qs ?? 0),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}';
      final file = File('${directory.path}/mouvements_$dateStr.xlsx');
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        _showSuccess('Export Excel réussi: ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur export Excel: $e');
      }
    }
  }

  Future<void> _exportMouvementsToPdf() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
              child: pw.Column(
                children: [
                  pw.Text(
                    'MOUVEMENTS DE STOCK',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SOCIÉTÉ:',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              '${_companyInfo['nom']}',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('${_companyInfo['adresse']}', style: const pw.TextStyle(fontSize: 9)),
                            pw.Text('RCS: ${_companyInfo['rcs']}', style: const pw.TextStyle(fontSize: 9)),
                            pw.Text('STAT: ${_companyInfo['stat']}', style: const pw.TextStyle(fontSize: 9)),
                            pw.Text('NIF: ${_companyInfo['nif']}', style: const pw.TextStyle(fontSize: 9)),
                            pw.Text(
                              'Email: ${_companyInfo['email']}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Tél: ${_companyInfo['tel']} / ${_companyInfo['port']}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'N° DOC: MOV${DateTime.now().millisecondsSinceEpoch}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              'DATE: ${AppDateUtils.formatDate(DateTime.now())}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              'PAGE: ${context.pageNumber}/${context.pagesCount}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Article', 'Dépôt', 'Type', 'Entrées', 'Sorties', 'Stock Final'],
                data: _filteredMouvements.map((mouvement) {
                  return [
                    AppDateUtils.formatDate(mouvement.daty ?? DateTime.now()),
                    mouvement.refart ?? '',
                    mouvement.depots ?? '',
                    mouvement.verification ?? '',
                    '${mouvement.qe ?? 0}',
                    '${mouvement.qs ?? 0}',
                    '${(mouvement.qe ?? 0) - (mouvement.qs ?? 0)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 16,
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}';
      final file = File('${directory.path}/mouvements_$dateStr.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        _showSuccess('Export PDF réussi: ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur export PDF: $e');
      }
    }
  }

  String _formatStockDisplay(Article article, double stockU1, double stockU2, double stockU3) {
    // Calculer le stock total en unité de base (U3) DIRECTEMENT
    double stockTotalU3 = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
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
  }
}
