import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../constants/app_functions.dart';
import '../../../constants/client_categories.dart';
import '../../../database/database.dart';
import '../../../database/database_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/vente_service.dart';
import '../../../utils/stock_converter.dart';
import '../../common/tab_navigation_widget.dart';
import 'ventes_pdf_generator.dart';

enum StatutVente { brouillard, journal }

class VentesController with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final VenteService _venteService = VenteService();
  final VentesPdfGenerator _pdfGenerator = VentesPdfGenerator();
  
  // Contrôleurs
  final TextEditingController numVentesController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController nFactureController = TextEditingController();
  final TextEditingController heureController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
  final TextEditingController prixController = TextEditingController();
  final TextEditingController montantController = TextEditingController();
  final TextEditingController remiseController = TextEditingController();
  final TextEditingController totalTTCController = TextEditingController();
  final TextEditingController avanceController = TextEditingController();
  final TextEditingController nouveauSoldeController = TextEditingController();
  TextEditingController? autocompleteController;
  final TextEditingController depotController = TextEditingController();
  final TextEditingController uniteController = TextEditingController();
  final TextEditingController searchVentesController = TextEditingController();
  final TextEditingController searchArticleController = TextEditingController();
  final TextEditingController soldeAnterieurController = TextEditingController();
  
  // Focus nodes
  late final FocusNode clientFocusNode;
  late final FocusNode designationFocusNode;
  late final FocusNode depotFocusNode;
  late final FocusNode uniteFocusNode;
  late final FocusNode quantiteFocusNode;
  late final FocusNode prixFocusNode;
  late final FocusNode ajouterFocusNode;
  late final FocusNode annulerFocusNode;
  late final FocusNode searchArticleFocusNode;
  final FocusNode keyboardFocusNode = FocusNode();
  
  // Listes de données
  List<Article> _articles = [];
  List<CltData> _clients = [];
  List<Depot> _depots = [];
  final List<Map<String, dynamic>> _lignesVente = [];
  
  // États
  Article? _selectedArticle;
  String? _selectedUnite;
  String? _selectedDepot;
  String? _selectedModePaiement = 'A crédit';
  String? _selectedClient;
  int? _selectedRowIndex;
  bool _isExistingPurchase = false;
  bool _isModifyingLine = false;
  int? _modifyingLineIndex;
  Map<String, dynamic>? originalLineData;
  String _defaultDepot = 'MAG';
  bool _showCreditMode = true;
  bool _tousDepots = false;
  
  // Recherche
  String _searchVentesText = '';
  Article? _searchedArticle;
  
  // Stock
  double _stockDisponible = 0.0;
  bool _stockInsuffisant = false;
  String _uniteAffichage = '';
  
  // Solde client
  double _soldeAnterieur = 0.0;
  
  // Format papier
  String _selectedFormat = 'A6';
  final ValueNotifier<String> selectedFormatNotifier = ValueNotifier('A6');
  
  // Workflow
  String _selectedVerification = 'BROUILLARD';
  StatutVente _statutVente = StatutVente.brouillard;
  StatutVente? _statutVenteActuelle;
  
  // Sidebar
  final ValueNotifier<bool> _isRightSidebarCollapsed = ValueNotifier(false);
  
  // Cache ventes
  Future<List<Map<String, dynamic>>>? _ventesFuture;
  List<Map<String, dynamic>>? _cachedVentes;
  DateTime? _lastVentesLoad;
  static const _cacheDuration = Duration(seconds: 30);
  
  // Getters
  List<Article> get articles => _articles;
  List<CltData> get clients => _clients;
  List<Depot> get depots => _depots;
  List<Map<String, dynamic>> get lignesVente => _lignesVente;
  Article? get selectedArticle => _selectedArticle;
  String? get selectedUnite => _selectedUnite;
  String? get selectedDepot => _selectedDepot;
  String? get selectedModePaiement => _selectedModePaiement;
  String? get selectedClient => _selectedClient;
  bool get isExistingPurchase => _isExistingPurchase;
  bool get isModifyingLine => _isModifyingLine;
  bool get showCreditMode => _showCreditMode;
  String get selectedVerification => _selectedVerification;
  String get selectedFormat => _selectedFormat;
  StatutVente? get statutVenteActuelle => _statutVenteActuelle;
  bool get isRightSidebarCollapsed => _isRightSidebarCollapsed.value;
  ValueNotifier<bool> get isRightSidebarCollapsedNotifier => _isRightSidebarCollapsed;
  Article? get searchedArticle => _searchedArticle;
  double get stockDisponible => _stockDisponible;
  bool get stockInsuffisant => _stockInsuffisant;
  
  bool get isClientSelected => _selectedClient != null && _selectedClient!.isNotEmpty;
  
  Future<void> initialize(bool tousDepots) async {
    _tousDepots = tousDepots;
    
    // Initialiser les focus nodes
    clientFocusNode = FocusNode();
    designationFocusNode = FocusNode();
    depotFocusNode = FocusNode();
    uniteFocusNode = FocusNode();
    quantiteFocusNode = FocusNode();
    prixFocusNode = FocusNode();
    ajouterFocusNode = FocusNode();
    annulerFocusNode = FocusNode();
    searchArticleFocusNode = FocusNode();
    
    // Charger les données
    await _loadData();
    await _loadDefaultDepot(tousDepots);
    await _initializeForm(tousDepots);
    
    // Configurer les listeners
    searchVentesController.addListener(() {
      _searchVentesText = searchVentesController.text.toLowerCase();
      notifyListeners();
    });
    
    searchArticleController.addListener(() {
      _onSearchArticleChanged(searchArticleController.text);
    });
    
    // Focus initial
    Future.delayed(const Duration(milliseconds: 200), () {
      clientFocusNode.requestFocus();
    });
    
    // Charger les ventes
    _ventesFuture = _getVentesAvecStatut(tousDepots);
  }
  
  void dispose() {
    autocompleteController?.dispose();
    numVentesController.dispose();
    dateController.dispose();
    nFactureController.dispose();
    heureController.dispose();
    clientController.dispose();
    quantiteController.dispose();
    prixController.dispose();
    montantController.dispose();
    remiseController.dispose();
    totalTTCController.dispose();
    avanceController.dispose();
    nouveauSoldeController.dispose();
    depotController.dispose();
    uniteController.dispose();
    searchVentesController.dispose();
    searchArticleController.dispose();
    soldeAnterieurController.dispose();
    keyboardFocusNode.dispose();
    
    clientFocusNode.dispose();
    designationFocusNode.dispose();
    depotFocusNode.dispose();
    uniteFocusNode.dispose();
    quantiteFocusNode.dispose();
    prixFocusNode.dispose();
    ajouterFocusNode.dispose();
    annulerFocusNode.dispose();
    searchArticleFocusNode.dispose();
    
    super.dispose();
  }
  
  // Méthodes de gestion d'état
  void setSelectedFormat(String format) {
    _selectedFormat = format;
    selectedFormatNotifier.value = format;
    notifyListeners();
  }
  
  void setSearchedArticle(Article? article) {
    _searchedArticle = article;
    notifyListeners();
  }
  
  void toggleRightSidebar() {
    _isRightSidebarCollapsed.value = !_isRightSidebarCollapsed.value;
  }
  
  void setSelectedModePaiement(String? value) {
    if (value != null) {
      _selectedModePaiement = value;
      if (value != 'Espèces') {
        // Réinitialiser les champs espèces si nécessaire
      }
      notifyListeners();
    }
    calculerTotaux();
  }
  
  void setSelectedVerification(String value) {
    _selectedVerification = value;
    _statutVente = value == 'JOURNAL' ? StatutVente.journal : StatutVente.brouillard;
    notifyListeners();
  }
  
  // ============ MÉTHODES DE LOGIQUE MÉTIER ============
  
  Future<void> _loadData() async {
    try {
      final articles = await _databaseService.database.getAllArticles();
      final allClients = await _databaseService.database.getAllClients();
      final depots = await _databaseService.database.getAllDepots();
      
      // Filtrer les clients selon le rôle
      final filteredClients = _filterClientsByRole(allClients);
      
      _articles = articles;
      _clients = filteredClients;
      _depots = depots;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
    }
  }
  
  List<CltData> _filterClientsByRole(List<CltData> allClients) {
    final authService = AuthService();
    if (authService.currentUserRole == 'Vendeur') {
      // Pour les vendeurs, ne montrer que leurs clients
      return allClients
          .where((client) => client.commercial == authService.currentUser?.nom)
          .toList();
    }
    return allClients;
  }
  
  Future<void> _loadDefaultDepot(bool tousDepots) async {
    if (!tousDepots) {
      // Pour vente MAG seulement, forcer le dépôt MAG
      _defaultDepot = 'MAG';
      _selectedDepot = 'MAG';
      depotController.text = 'MAG';
      notifyListeners();
      return;
    }

    try {
      final derniereVente = await (_databaseService.database.select(_databaseService.database.detventes)
            ..orderBy([(d) => drift.OrderingTerm.desc(d.daty)])
            ..limit(1))
          .getSingleOrNull();

      _defaultDepot = derniereVente?.depots ?? 'MAG';
      _selectedDepot = _defaultDepot;
      depotController.text = _defaultDepot;
      notifyListeners();
    } catch (e) {
      _defaultDepot = 'MAG';
      _selectedDepot = 'MAG';
      depotController.text = 'MAG';
      notifyListeners();
    }
  }
  
  Future<void> _initializeForm(bool tousDepots) async {
    final now = DateTime.now();
    dateController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    heureController.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final nextNumVentes = await _getNextNumVentes();
    numVentesController.text = nextNumVentes;
    nFactureController.text = await _getNextNumBL(tousDepots);

    remiseController.text = '0';
    avanceController.text = '0';
    nouveauSoldeController.text = '0';
    totalTTCController.text = '0';
    _selectedVerification = 'BROUILLARD';

    notifyListeners();
  }
  
  Future<String> _getNextNumVentes() async {
    try {
      final ventes = await _databaseService.database.select(_databaseService.database.ventes).get();
      if (ventes.isEmpty) return '2607';

      int maxNum = 2606;
      for (var vente in ventes) {
        if (vente.numventes != null) {
          final num = int.tryParse(vente.numventes!) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
      return (maxNum + 1).toString();
    } catch (e) {
      return '2607';
    }
  }
  
  Future<String> _getNextNumBL(bool tousDepots) async {
    try {
      final prefix = tousDepots ? 'DEP' : 'MAG';
      final ventes = await _databaseService.database.select(_databaseService.database.ventes).get();

      int maxNum = 0;
      for (var vente in ventes) {
        if (vente.nfact != null && vente.nfact!.startsWith(prefix)) {
          final numStr = vente.nfact!.substring(3);
          final num = int.tryParse(numStr) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
      return '$prefix${(maxNum + 1).toString().padLeft(4, '0')}';
    } catch (e) {
      final prefix = tousDepots ? 'DEP' : 'MAG';
      return '${prefix}0001';
    }
  }
  
  // ============ GESTION DES VENTES ============
  
  Future<void> chargerVenteExistante(String numVentes) async {
    if (numVentes.isEmpty) {
      _isExistingPurchase = false;
      notifyListeners();
      return;
    }

    try {
      final vente = await (_databaseService.database.select(_databaseService.database.ventes)
            ..where((v) => v.numventes.equals(numVentes)))
          .getSingleOrNull();

      if (vente != null) {
        final details = await (_databaseService.database.select(_databaseService.database.detventes)
              ..where((d) => d.numventes.equals(numVentes)))
            .get();

        _isExistingPurchase = true;
        _selectedVerification = vente.verification ?? 'JOURNAL';
        _statutVenteActuelle =
            vente.verification == 'BROUILLARD' ? StatutVente.brouillard : StatutVente.journal;

        nFactureController.text = vente.nfact ?? '';
        if (vente.daty != null) {
          dateController.text =
              '${vente.daty!.day.toString().padLeft(2, '0')}/${vente.daty!.month.toString().padLeft(2, '0')}/${vente.daty!.year}';
        }
        clientController.text = vente.clt ?? '';
        _selectedClient = vente.clt;
        _selectedModePaiement = vente.modepai ?? 'A crédit';
        heureController.text = vente.heure ?? '';

        if (vente.clt != null && vente.clt!.isNotEmpty) {
          final client = _clients.where((c) => c.rsoc == vente.clt).firstOrNull;
          if (client != null) {
            _showCreditMode = _shouldShowCreditMode(client);
          }
        }
        await _chargerSoldeClient(vente.clt);
        remiseController.text = (vente.remise ?? 0).toString();
        avanceController.text = (vente.avance ?? 0).toString();

        _lignesVente.clear();
        for (var detail in details) {
          double diffPrixUnitaire = 0.0;
          if ((detail.q ?? 0.0) > 0) {
            diffPrixUnitaire = (detail.diffPrix ?? 0.0) / (detail.q ?? 1.0);
          }

          _lignesVente.add({
            'designation': detail.designation ?? '',
            'unites': detail.unites ?? '',
            'quantite': detail.q ?? 0.0,
            'prixUnitaire': detail.pu ?? 0.0,
            'montant': (detail.q ?? 0.0) * (detail.pu ?? 0.0),
            'depot': detail.depots ?? '',
            'diffPrix': diffPrixUnitaire,
          });
        }

        notifyListeners();
        calculerTotaux();

        Future.delayed(const Duration(milliseconds: 100), () {
          designationFocusNode.requestFocus();
        });
      } else {
        _isExistingPurchase = false;
        notifyListeners();
      }
    } catch (e) {
      _isExistingPurchase = false;
      notifyListeners();
      debugPrint('Erreur lors du chargement de la vente: $e');
    }
  }
  
  bool _shouldShowCreditMode(CltData? client) {
    if (client == null) return true;
    return client.categorie == null || client.categorie == ClientCategory.tousDepots.label;
  }
  
  bool isVendeur() {
    final authService = AuthService();
    return authService.currentUserRole == 'Vendeur';
  }
  
  // ============ GESTION DES ARTICLES ============
  
  Future<void> onArticleSelected(Article? article) async {
    if (!isClientSelected) {
      return;
    }

    _selectedArticle = article;
    if (article != null) {
      if (!_isModifyingLine) {
        quantiteController.text = '';
      }
      montantController.text = '';
      _uniteAffichage = _formaterUniteAffichage(article);
      if (_selectedUnite == null) {
        uniteController.clear();
      }
    }

    notifyListeners();

    if (article != null && !_isModifyingLine) {
      await _verifierStockEtBasculer(article);
    }
  }
  
  void _onSearchArticleChanged(String text) async {
    if (text.trim().isEmpty) {
      _searchedArticle = null;
      notifyListeners();
      return;
    }

    try {
      final article =
          _articles.where((a) => a.designation.toLowerCase().contains(text.toLowerCase())).firstOrNull;

      _searchedArticle = article;
      notifyListeners();
    } catch (e) {
      _searchedArticle = null;
      notifyListeners();
    }
  }
  
  Future<void> verifierUniteArticle(String unite) async {
    if (_selectedArticle == null || unite.trim().isEmpty) return;

    final unitesValides = [_selectedArticle!.u1, _selectedArticle!.u2, _selectedArticle!.u3]
        .where((u) => u != null && u.isNotEmpty)
        .toList();

    if (!unitesValides.contains(unite.trim())) {
      _selectedUnite = _selectedArticle!.u1;
      notifyListeners();
      return;
    }

    onUniteChanged(unite.trim());
  }
  
  void onUniteChanged(String? unite) async {
    if (!isClientSelected || _selectedArticle == null || unite == null) return;

    _selectedUnite = unite;
    await _calculerPrixPourUnite(_selectedArticle!, unite);
    if (!_isModifyingLine) {
      await _verifierStock(_selectedArticle!);
    }
    notifyListeners();
  }
  
  Future<void> verifierDepot(String depot) async {
    if (depot.trim().isEmpty) return;

    final depotExiste = _depots.any((d) => d.depots == depot.trim());

    if (!depotExiste) {
      _selectedDepot = _defaultDepot;
      depotController.text = _defaultDepot;
      notifyListeners();
      return;
    }

    onDepotChanged(depot.trim());
  }
  
  void onDepotChanged(String? depot) async {
    if (_selectedArticle == null || depot == null) return;

    _selectedDepot = depot;
    notifyListeners();

    if (!_isModifyingLine) {
      await _verifierStockEtBasculer(_selectedArticle!);
    }

    if (quantiteController.text.isNotEmpty) {
      validerQuantite(quantiteController.text);
    }
  }
  
  Future<void> _verifierStockEtBasculer(Article article) async {
    try {
      String depot = _selectedDepot ?? 'MAG';

      final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .getSingleOrNull();

      double stockTotalU3 = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockDepart?.stocksu1 ?? 0.0,
        stockU2: stockDepart?.stocksu2 ?? 0.0,
        stockU3: stockDepart?.stocksu3 ?? 0.0,
      );

      double stockPourUniteSelectionnee =
          _calculerStockPourUnite(article, _selectedUnite ?? article.u1!, stockTotalU3);

      _stockDisponible = stockPourUniteSelectionnee;
      _stockInsuffisant = stockTotalU3 <= 0;

      if (prixController.text.isEmpty) {
        await _calculerPrixPourUnite(article, _selectedUnite ?? article.u1!);
      }

      notifyListeners();

      if (_stockInsuffisant) {
        await _gererStockInsuffisant(article, depot);
      }
    } catch (e) {
      _stockDisponible = 0.0;
      _stockInsuffisant = true;
      notifyListeners();
    }
  }
  
  Future<void> _verifierStock(Article article) async {
    try {
      String depot = _selectedDepot ?? 'MAG';
      String unite = _selectedUnite ?? (article.u1 ?? '');

      final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .getSingleOrNull();

      double stockTotalU3 = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockDepart?.stocksu1 ?? 0.0,
        stockU2: stockDepart?.stocksu2 ?? 0.0,
        stockU3: stockDepart?.stocksu3 ?? 0.0,
      );

      double stockPourUniteSelectionnee = _calculerStockPourUnite(article, unite, stockTotalU3);

      _stockDisponible = stockPourUniteSelectionnee;
      _stockInsuffisant = stockTotalU3 <= 0;
      notifyListeners();
    } catch (e) {
      _stockDisponible = 0.0;
      _stockInsuffisant = true;
      notifyListeners();
    }
  }
  
  Future<void> _calculerPrixPourUnite(Article article, String unite) async {
    final prixStandard = await _getPrixVenteStandard(article, unite);
    prixController.text = prixStandard > 0 ? AppFunctions.formatNumber(prixStandard) : '';
    notifyListeners();
  }
  
  double _calculerStockPourUnite(Article article, String unite, double stockTotalU3) {
    if (stockTotalU3 <= 0) return 0.0;

    if (unite == article.u3) {
      return stockTotalU3;
    } else if (unite == article.u2 && article.tu3u2 != null) {
      return stockTotalU3 / article.tu3u2!;
    } else if (unite == article.u1 && article.tu2u1 != null && article.tu3u2 != null) {
      return stockTotalU3 / (article.tu2u1! * article.tu3u2!);
    }

    return 0.0;
  }
  
  Future<String> getStocksToutesUnites(Article article, String depot) async {
    try {
      final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .getSingleOrNull();

      double stockTotalU3 = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockDepart?.stocksu1 ?? 0.0,
        stockU2: stockDepart?.stocksu2 ?? 0.0,
        stockU3: stockDepart?.stocksu3 ?? 0.0,
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
    } catch (e) {
      return '';
    }
  }
  
  Future<void> _gererStockInsuffisant(Article article, String depotActuel) async {
    await _verifierStocksAutresDepots(article, depotActuel);
  }
  
  Future<List<Map<String, dynamic>>> _verifierStocksAutresDepots(Article article, String depotActuel) async {
    final autresStocks = <Map<String, dynamic>>[];

    try {
      final tousStocksDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.isNotValue(depotActuel)))
          .get();

      for (var stock in tousStocksDepart) {
        final stocksOptimaux = StockConverter.convertirStockOptimal(
          article: article,
          quantiteU1: stock.stocksu1 ?? 0.0,
          quantiteU2: stock.stocksu2 ?? 0.0,
          quantiteU3: stock.stocksu3 ?? 0.0,
        );

        double stockTotalU3 = _calculerStockTotalEnU3(
            article, stocksOptimaux['u1']!, stocksOptimaux['u2']!, stocksOptimaux['u3']!);

        if (stockTotalU3 > 0) {
          double stockPourUnite =
              _calculerStockPourUnite(article, _selectedUnite ?? (article.u1 ?? ''), stockTotalU3);
          autresStocks.add({
            'depot': stock.depots,
            'stockDisponible': stockPourUnite,
            'unite': _selectedUnite ?? (article.u1 ?? ''),
          });
        }
      }
    } catch (e) {
      // Ignore errors
    }

    return autresStocks;
  }
  
  double _calculerStockTotalEnU3(Article article, double stockU1, double stockU2, double stockU3) {
    return StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );
  }
  
  Future<double> _getPrixVenteStandard(Article article, String unite) async {
    if (unite == article.u1) {
      return article.pvu1 ?? 0.0;
    } else if (unite == article.u2) {
      return article.pvu2 ?? 0.0;
    } else if (unite == article.u3) {
      return article.pvu3 ?? 0.0;
    }
    return 0.0;
  }
  
  Future<double> _getPrixAchatPourUnite(Article article, String unite) async {
    double cmup = article.cmup ?? 0.0;
    if (cmup == 0.0) return 0.0;

    if (unite == article.u1 && article.tu2u1 != null && article.tu3u2 != null) {
      return cmup * (article.tu2u1! * article.tu3u2!);
    } else if (unite == article.u2 && article.tu3u2 != null) {
      return cmup * article.tu3u2!;
    } else if (unite == article.u3) {
      return cmup;
    }
    return cmup;
  }
  
  // ============ GESTION DES LIGNES DE VENTE ============
  
  void validerQuantite(String value) async {
    if (!isClientSelected || _selectedArticle == null) return;

    double quantite = double.tryParse(value) ?? 0.0;

    if (quantite > _stockDisponible) {
      setState(() {
        _statutVente = StatutVente.brouillard;
      });
    }

    calculerMontant();
    notifyListeners();
  }
  
  void calculerMontant() {
    double quantite = double.tryParse(quantiteController.text) ?? 0.0;
    double prix = double.tryParse(prixController.text.replaceAll(' ', '')) ?? 0.0;
    double montant = quantite * prix;
    montantController.text = montant > 0 ? AppFunctions.formatNumber(montant) : '';
    notifyListeners();
  }
  
  bool isQuantiteInsuffisante() {
    if (_selectedArticle == null) return false;
    double quantite = double.tryParse(quantiteController.text) ?? 0.0;
    return quantite > _stockDisponible;
  }
  
  String _formaterUniteAffichage(Article article) {
    final unites = <String>[];
    if (article.u1?.isNotEmpty == true) unites.add(article.u1!);
    if (article.u2?.isNotEmpty == true) unites.add(article.u2!);
    if (article.u3?.isNotEmpty == true) unites.add(article.u3!);
    return unites.join(' / ');
  }
  
  Article? getLastAddedArticle() {
    if (_lignesVente.isEmpty) return null;
    final lastDesignation = _lignesVente.last['designation'] as String?;
    if (lastDesignation == null) return null;
    return _articles.where((a) => a.designation == lastDesignation).firstOrNull;
  }
  
  List<String> getUnitsForSelectedArticle() {
    if (_selectedArticle == null) {
      return [''];
    }

    final units = <String>[];
    if (_selectedArticle!.u1?.isNotEmpty == true) {
      units.add(_selectedArticle!.u1!);
    }
    if (_selectedArticle!.u2?.isNotEmpty == true) {
      units.add(_selectedArticle!.u2!);
    }
    if (_selectedArticle!.u3?.isNotEmpty == true) {
      units.add(_selectedArticle!.u3!);
    }

    return units.isEmpty ? [''] : units;
  }
  
  // ============ AJOUT ET MODIFICATION DE LIGNES ============
  
  Future<void> ajouterLigne() async {
    if (_selectedArticle == null) return;

    double quantite = double.tryParse(quantiteController.text) ?? 0.0;
    double prix = double.tryParse(prixController.text.replaceAll(' ', '')) ?? 0.0;
    String unite = _selectedUnite ?? (_selectedArticle!.u1 ?? '');
    String depot = _selectedDepot ?? _defaultDepot;

    final prixAchat = await _getPrixAchatPourUnite(_selectedArticle!, unite);
    final prixValide = await _verifierPrixVente(prix, prixAchat, unite);
    if (!prixValide) return;

    if (quantite > _stockDisponible) {
      final validation = await _venteService.verifierStockSelonDepot(
        designation: _selectedArticle!.designation,
        depot: depot,
        unite: unite,
        quantite: quantite,
        tousDepots: _tousDepots,
      );

      if (!validation['autorise']) {
        return;
      }
    }

    double montant = quantite * prix;

    if (quantite > _stockDisponible) {
      setState(() {
        _statutVente = StatutVente.brouillard;
      });
    }

    final prixVenteStandard = await _getPrixVenteStandard(_selectedArticle!, unite);
    final diffPrix = prix - prixVenteStandard;

    _defaultDepot = depot;

    _lignesVente.add({
      'designation': _selectedArticle!.designation,
      'unites': unite,
      'quantite': quantite,
      'prixUnitaire': prix,
      'montant': montant,
      'depot': depot,
      'article': _selectedArticle,
      'stockInsuffisant': quantite > _stockDisponible,
      'diffPrix': diffPrix,
    });
    _isModifyingLine = false;
    _modifyingLineIndex = null;
    originalLineData = null;

    notifyListeners();
    calculerTotaux();

    if (_isExistingPurchase && _isVenteBrouillard()) {
      await _sauvegarderModificationsBrouillard();
    }

    resetArticleForm();
  }
  
  Future<bool> _verifierPrixVente(double prixVente, double prixAchat, String unite) async {
    if (prixVente == 0) {
      return true;
    } else if (prixVente < prixAchat) {
      return true;
    }
    return true;
  }
  
  Future<void> chargerLigneArticle(int index) async {
    int adjustedIndex = index;

    if (_isModifyingLine && _modifyingLineIndex != null && originalLineData != null) {
      _lignesVente.insert(_modifyingLineIndex!, Map<String, dynamic>.from(originalLineData!));
      calculerTotaux();

      if (_modifyingLineIndex! <= index) {
        adjustedIndex = index + 1;
      }
    }

    final ligne = _lignesVente[adjustedIndex];

    Article? article;
    try {
      article = _articles.firstWhere(
        (a) => a.designation == ligne['designation'],
      );
    } catch (e) {
      if (_articles.isNotEmpty) {
        article = _articles.first;
      } else {
        return;
      }
    }

    final originalData = Map<String, dynamic>.from(ligne);
    final quantiteOriginale = ligne['quantite'].toString();

    _selectedArticle = article;
    _selectedUnite = ligne['unites'];
    _selectedDepot = ligne['depot'];
    _isModifyingLine = true;
    _modifyingLineIndex = adjustedIndex;
    originalLineData = originalData;
    _uniteAffichage = _formaterUniteAffichage(article);

    depotController.text = ligne['depot'];
    uniteController.text = ligne['unites'];
    quantiteController.text = quantiteOriginale;
    prixController.text = AppFunctions.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0);

    await _verifierStockEtBasculer(article);
    quantiteController.text = quantiteOriginale;

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_isModifyingLine && _modifyingLineIndex == adjustedIndex) {
        _lignesVente.removeAt(adjustedIndex);
        calculerTotaux();
        notifyListeners();
      }
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      quantiteFocusNode.requestFocus();
    });
  }
  
  void annulerModificationLigne() {
    if (_isModifyingLine && _modifyingLineIndex != null && originalLineData != null) {
      _lignesVente.insert(_modifyingLineIndex!, Map<String, dynamic>.from(originalLineData!));
      calculerTotaux();
      notifyListeners();
    }

    resetArticleForm();
  }
  
  void supprimerLigne(int index) async {
    _lignesVente.removeAt(index);
    calculerTotaux();
    notifyListeners();

    if (_isExistingPurchase && _isVenteBrouillard()) {
      await _sauvegarderModificationsBrouillard();
    }
  }
  
  bool shouldShowAddButton() {
    if (_isModifyingLine) {
      return isClientSelected && _selectedArticle != null;
    }
    return isClientSelected && _selectedArticle != null && quantiteController.text.isNotEmpty;
  }
  
  void resetArticleForm() {
    _selectedArticle = null;
    _selectedUnite = null;
    _selectedDepot = _defaultDepot;
    if (autocompleteController != null) {
      autocompleteController!.clear();
    }
    quantiteController.clear();
    prixController.clear();
    montantController.clear();
    depotController.text = _defaultDepot;
    uniteController.clear();
    _stockDisponible = 0.0;
    _stockInsuffisant = false;
    _uniteAffichage = '';
    _isModifyingLine = false;
    _modifyingLineIndex = null;
    originalLineData = null;

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 100), () {
      designationFocusNode.requestFocus();
    });
  }
  
  // ============ CALCUL DES TOTAUX ============
  
  void calculerTotaux() {
    double totalHT = 0;
    for (var ligne in _lignesVente) {
      totalHT += ligne['montant'] ?? 0;
    }

    double remise = double.tryParse(remiseController.text) ?? 0;
    double totalApresRemise = totalHT - (totalHT * remise / 100);
    double totalTTC = totalApresRemise;
    double avance = double.tryParse(avanceController.text) ?? 0;
    double reste = totalTTC - avance;

    double nouveauSolde = _soldeAnterieur;
    if (_selectedModePaiement == 'A crédit') {
      nouveauSolde += reste;
    }

    totalTTCController.text = AppFunctions.formatNumber(totalTTC);
    nouveauSoldeController.text = AppFunctions.formatNumber(nouveauSolde);
    
    notifyListeners();
  }
  
  String calculateRemiseAmount() {
    double totalHT = 0;
    for (var ligne in _lignesVente) {
      totalHT += ligne['montant'] ?? 0;
    }
    double remise = double.tryParse(remiseController.text) ?? 0;
    double remiseAmount = totalHT * remise / 100;
    return AppFunctions.formatNumber(remiseAmount);
  }
  
  double calculateTotalDiffPrix() {
    double total = 0.0;
    for (var ligne in _lignesVente) {
      total += (ligne['diffPrix'] ?? 0.0) * (ligne['quantite'] ?? 0.0);
    }
    return total;
  }
  
  // ============ GESTION DU SOLDE CLIENT ============
  
  Future<void> _chargerSoldeClient(String? client) async {
    if (client == null || client.isEmpty) {
      _soldeAnterieur = 0.0;
      soldeAnterieurController.text = '0';
      notifyListeners();
      return;
    }

    try {
      double solde = await _databaseService.database.calculerSoldeClient(client);

      if (_isExistingPurchase && numVentesController.text.isNotEmpty) {
        final venteActuelle = await (_databaseService.database.select(_databaseService.database.ventes)
              ..where((v) => v.numventes.equals(numVentesController.text)))
            .getSingleOrNull();

        if (venteActuelle != null && venteActuelle.modepai == 'A crédit') {
          double montantVenteActuelle = (venteActuelle.totalttc ?? 0) - (venteActuelle.avance ?? 0);
          solde -= montantVenteActuelle;
        }
      }

      _soldeAnterieur = solde;
      soldeAnterieurController.text = AppFunctions.formatNumber(solde);
      notifyListeners();
      calculerTotaux();
    } catch (e) {
      _soldeAnterieur = 0.0;
      soldeAnterieurController.text = '0';
      notifyListeners();
    }
  }
  
  // ============ VALIDATION ET ENREGISTREMENT ============
  
  Future<void> validerVente() async {
    if (_lignesVente.isEmpty) {
      return;
    }

    if (_selectedVerification == 'JOURNAL') {
      for (final ligne in _lignesVente) {
        final stockDisponible = await _venteService.verifierDisponibiliteStock(
          designation: ligne['designation'],
          depot: ligne['depot'],
          unite: ligne['unites'],
          quantite: ligne['quantite'],
        );

        if (!stockDisponible && !_tousDepots) {
          return;
        }
      }
    }

    try {
      final currentUser = AuthService().currentUser;
      final commercialName = currentUser?.nom ?? '';

      final lignesVenteData = _lignesVente
          .map((ligne) => {
                'designation': ligne['designation'],
                'unite': ligne['unites'],
                'depot': ligne['depot'],
                'quantite': ligne['quantite'],
                'prixUnitaire': ligne['prixUnitaire'],
                'diffPrix': ligne['diffPrix'],
              })
          .toList();

      if (_selectedVerification == 'BROUILLARD') {
        await _venteService.enregistrerVenteBrouillard(
          numVentes: numVentesController.text,
          nFacture: nFactureController.text.isEmpty ? null : nFactureController.text,
          date: DateTime.tryParse(dateController.text) ?? DateTime.now(),
          client: _selectedClient,
          modePaiement: _selectedModePaiement,
          totalHT: 0,
          totalTTC: double.tryParse(totalTTCController.text.replaceAll(' ', '')) ?? 0,
          tva: 0,
          avance: double.tryParse(avanceController.text) ?? 0,
          commercial: commercialName,
          commission: 0,
          remise: double.tryParse(remiseController.text) ?? 0,
          lignesVente: lignesVenteData,
          heure: heureController.text,
        );
      } else {
        await _venteService.enregistrerVenteDirecteJournal(
          numVentes: numVentesController.text,
          nFacture: nFactureController.text.isEmpty ? null : nFactureController.text,
          date: DateTime.tryParse(dateController.text) ?? DateTime.now(),
          client: _selectedClient,
          modePaiement: _selectedModePaiement,
          totalHT: 0,
          totalTTC: double.tryParse(totalTTCController.text.replaceAll(' ', '')) ?? 0,
          tva: 0,
          avance: double.tryParse(avanceController.text) ?? 0,
          commercial: commercialName,
          commission: 0,
          remise: double.tryParse(remiseController.text) ?? 0,
          lignesVente: lignesVenteData,
          heure: heureController.text,
        );
      }

      _reloadVentesList();
      reinitialiserFormulaire();
    } catch (e) {
      debugPrint('Erreur lors de la validation: $e');
    }
  }
  
  Future<void> modifierVente() async {
    if (_selectedClient == null || _lignesVente.isEmpty) {
      return;
    }

    if (!_isExistingPurchase || numVentesController.text.isEmpty) {
      return;
    }

    try {
      double totalHT = 0;
      for (var ligne in _lignesVente) {
        totalHT += ligne['montant'] ?? 0;
      }

      double remise = double.tryParse(remiseController.text) ?? 0;
      double totalApresRemise = totalHT - (totalHT * remise / 100);
      double totalTTC = totalApresRemise;
      double avance = double.tryParse(avanceController.text) ?? 0;

      await _databaseService.database.transaction(() async {
        await (_databaseService.database.delete(_databaseService.database.detventes)
              ..where((d) => d.numventes.equals(numVentesController.text)))
            .go();

        await (_databaseService.database.update(_databaseService.database.ventes)
              ..where((v) => v.numventes.equals(numVentesController.text)))
            .write(VentesCompanion(
          nfact: drift.Value(nFactureController.text),
          daty: drift.Value(DateTime.now()),
          clt: drift.Value(_selectedClient ?? ''),
          modepai: drift.Value(_selectedModePaiement ?? 'A crédit'),
          totalnt: drift.Value(totalApresRemise),
          totalttc: drift.Value(totalTTC),
          avance: drift.Value(avance),
          remise: drift.Value(remise),
          heure: drift.Value(heureController.text),
        ));

        for (var ligne in _lignesVente) {
          await _databaseService.database.into(_databaseService.database.detventes).insert(
                DetventesCompanion.insert(
                  numventes: drift.Value(numVentesController.text),
                  designation: drift.Value(ligne['designation']),
                  unites: drift.Value(ligne['unites']),
                  depots: drift.Value(ligne['depot']),
                  q: drift.Value(ligne['quantite']),
                  pu: drift.Value(ligne['prixUnitaire']),
                  daty: drift.Value(DateTime.now()),
                  diffPrix: drift.Value(ligne['diffPrix'] ?? 0.0),
                ),
              );
        }
      });

      _reloadVentesList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la modification: $e');
    }
  }
  
  void reinitialiserFormulaire() {
    _isExistingPurchase = false;
    _selectedRowIndex = null;
    _lignesVente.clear();
    clientController.clear();
    _selectedClient = null;
    _statutVenteActuelle = null;
    _selectedVerification = 'BROUILLARD';
    _statutVente = StatutVente.brouillard;
    _showCreditMode = _shouldShowCreditMode(null);
    if (autocompleteController != null) {
      autocompleteController!.clear();
    }

    remiseController.text = '0';
    totalTTCController.text = '0';
    avanceController.text = '0';
    nouveauSoldeController.text = '0';

    resetArticleForm();
    _initializeForm(_tousDepots);
    _chargerSoldeClient(null);
    notifyListeners();
  }
  
  void creerNouvelleVente() {
    _reloadVentesList();

    _isExistingPurchase = false;
    _selectedRowIndex = null;
    _lignesVente.clear();
    clientController.clear();
    _selectedClient = null;
    _statutVenteActuelle = null;
    _selectedVerification = 'BROUILLARD';
    _statutVente = StatutVente.brouillard;
    _showCreditMode = _shouldShowCreditMode(null);
    if (autocompleteController != null) {
      autocompleteController!.clear();
    }

    remiseController.text = '0';
    totalTTCController.text = '0';
    avanceController.text = '0';
    nouveauSoldeController.text = '0';

    resetArticleForm();
    _initializeForm(_tousDepots);
    _chargerSoldeClient(null);
    notifyListeners();
  }
  
  // ============ GESTION BROUILLARD/JOURNAL ============
  
  bool peutValiderBrouillard() {
    if (!_isExistingPurchase || numVentesController.text.isEmpty) return false;
    return _isVenteBrouillard();
  }
  
  bool _isVenteBrouillard() {
    return _statutVenteActuelle == StatutVente.brouillard;
  }
  
  Future<bool> isVenteContrePassee() async {
    if (!_isExistingPurchase || numVentesController.text.isEmpty) return false;

    try {
      final vente = await (_databaseService.database.select(_databaseService.database.ventes)
            ..where((v) => v.numventes.equals(numVentesController.text)))
          .getSingleOrNull();

      return vente?.contre == '1';
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _sauvegarderModificationsBrouillard() async {
    if (!_isExistingPurchase || numVentesController.text.isEmpty) return;

    double totalHT = 0;
    for (var ligne in _lignesVente) {
      totalHT += ligne['montant'] ?? 0;
    }

    double remise = double.tryParse(remiseController.text) ?? 0;
    double totalApresRemise = totalHT - (totalHT * remise / 100);
    double totalTTC = totalApresRemise;
    double avance = double.tryParse(avanceController.text) ?? 0;

    await _databaseService.database.transaction(() async {
      await (_databaseService.database.delete(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(numVentesController.text)))
          .go();

      await (_databaseService.database.update(_databaseService.database.ventes)
            ..where((v) => v.numventes.equals(numVentesController.text)))
          .write(VentesCompanion(
        nfact: drift.Value(nFactureController.text),
        clt: drift.Value(_selectedClient ?? ''),
        modepai: drift.Value(_selectedModePaiement ?? 'A crédit'),
        totalnt: drift.Value(totalApresRemise),
        totalttc: drift.Value(totalTTC),
        avance: drift.Value(avance),
        remise: drift.Value(remise),
        heure: drift.Value(heureController.text),
      ));

      for (var ligne in _lignesVente) {
        await _databaseService.database.into(_databaseService.database.detventes).insert(
              DetventesCompanion.insert(
                numventes: drift.Value(numVentesController.text),
                designation: drift.Value(ligne['designation']),
                unites: drift.Value(ligne['unites']),
                depots: drift.Value(ligne['depot']),
                q: drift.Value(ligne['quantite']),
                pu: drift.Value(ligne['prixUnitaire']),
                daty: drift.Value(DateTime.now()),
                diffPrix: drift.Value((ligne['diffPrix'] ?? 0.0) * ligne['quantite']),
              ),
            );
      }
    });
  }
  
  Future<void> validerBrouillardVersJournal() async {
    if (!_isExistingPurchase || numVentesController.text.isEmpty) return;

    bool hasStockInsuffisant = await _verifierStockPourValidation();

    if (hasStockInsuffisant) {
      if (!_tousDepots) {
        return;
      }
    }

    try {
      await _sauvegarderModificationsBrouillard();

      await _venteService.validerVenteBrouillardVersJournal(
        numVentes: numVentesController.text,
        nFacture: nFactureController.text,
        client: _selectedClient,
        modePaiement: _selectedModePaiement,
        totalHT: 0,
        totalTTC: double.tryParse(totalTTCController.text.replaceAll(' ', '')) ?? 0,
        tva: 0,
        avance: double.tryParse(avanceController.text) ?? 0,
        remise: double.tryParse(remiseController.text) ?? 0,
        commission: 0,
      );

      _reloadVentesList();
      await chargerVenteExistante(numVentesController.text);

      setState(() {
        _selectedVerification = 'JOURNAL';
        _statutVente = StatutVente.journal;
      });
    } catch (e) {
      debugPrint('Erreur lors de la validation: $e');
    }
  }
  
  Future<bool> _verifierStockPourValidation() async {
    if (!_isExistingPurchase || numVentesController.text.isEmpty) return false;

    try {
      final details = await (_databaseService.database.select(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(numVentesController.text)))
          .get();

      for (var detail in details) {
        if (detail.designation != null && detail.depots != null && detail.q != null) {
          final article = _articles.where((a) => a.designation == detail.designation).firstOrNull;
          if (article == null) continue;

          final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
                ..where((d) => d.designation.equals(detail.designation!) & d.depots.equals(detail.depots!)))
              .getSingleOrNull();

          if (stockDepart != null) {
            double stockTotalU3 = StockConverter.calculerStockTotalU3(
              article: article,
              stockU1: stockDepart.stocksu1 ?? 0.0,
              stockU2: stockDepart.stocksu2 ?? 0.0,
              stockU3: stockDepart.stocksu3 ?? 0.0,
            );

            double stockPourUnite = _calculerStockPourUnite(article, detail.unites ?? '', stockTotalU3);

            if (detail.q! > stockPourUnite) {
              if (!_tousDepots) {
                return true;
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      return !_tousDepots;
    }
  }
  
  // ============ CONTRE-PASSATION ============
  
  Future<void> contrePasserVente() async {
    if (!_isExistingPurchase) {
      return;
    }

    try {
      await _venteService.contrePasserVente(numVentesController.text);

      _reloadVentesList();
      await chargerVenteExistante(numVentesController.text);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la contre-passation: $e');
    }
  }
  
  Future<void> contrePasserVenteBrouillard() async {
    if (!_isExistingPurchase || !_isVenteBrouillard()) {
      return;
    }

    try {
      await _venteService.contrePasserVenteBrouillard(numVentesController.text);

      _reloadVentesList();
      creerNouvelleVente();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la contre-passation brouillard: $e');
    }
  }
  
  // ============ IMPORTATION ============
  
  Future<void> importerLignesVente() async {
    final choix = 'base_actuelle'; // À implémenter avec un dialogue

    if (choix == 'base_actuelle') {
      await _importerDepuisBaseActuelle();
    } else if (choix == 'base_externe') {
      await _importerDepuisBaseExterne();
    }
  }
  
  Future<void> _importerDepuisBaseActuelle() async {
    final ventes = await _getVentesAvecStatut(_tousDepots);
    final ventesAvecDetails = <Map<String, dynamic>>[];

    for (final vente in ventes) {
      final details = await (_databaseService.database.select(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(vente['numventes'])))
          .get();

      if (details.isNotEmpty) {
        ventesAvecDetails.add({
          'numVente': vente['numventes'],
          'statut': vente['verification'] ?? 'JOURNAL',
          'nbLignes': details.length,
          'nfact': vente['nfact'] ?? '',
        });
      }
    }

    if (ventesAvecDetails.isEmpty) {
      return;
    }

    final selectedVente = ventesAvecDetails.first['numVente']; // À implémenter avec un dialogue
    if (selectedVente != null) {
      await _copierLignesVente(selectedVente);
    }
  }
  
  Future<void> _copierLignesVente(String numVenteSource) async {
    try {
      final details = await (_databaseService.database.select(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(numVenteSource)))
          .get();

      if (details.isEmpty) {
        return;
      }

      final lignesValides = <Map<String, dynamic>>[];
      for (final detail in details) {
        final articleExiste = _articles.any((a) => a.designation == detail.designation);
        if (articleExiste) {
          lignesValides.add({
            'designation': detail.designation ?? '',
            'unites': detail.unites ?? '',
            'quantite': detail.q ?? 0.0,
            'prixUnitaire': detail.pu ?? 0.0,
            'montant': (detail.q ?? 0.0) * (detail.pu ?? 0.0),
            'depot': detail.depots ?? 'MAG',
            'diffPrix': (detail.diffPrix ?? 0.0) / (detail.q ?? 1.0),
          });
        }
      }

      if (lignesValides.isEmpty) {
        return;
      }

      _lignesVente.clear();
      _lignesVente.addAll(lignesValides);
      notifyListeners();
      calculerTotaux();
    } catch (e) {
      debugPrint('Erreur lors de l\'importation: $e');
    }
  }
  
  Future<void> _importerDepuisBaseExterne() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
        dialogTitle: 'Sélectionner une base de données',
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) {
        return;
      }

      final externalDbService = DatabaseService.fromPath(filePath);
      await externalDbService.initialize();

      final ventesExternes = await externalDbService.database.select(externalDbService.database.ventes).get();

      if (ventesExternes.isEmpty) {
        return;
      }

      final selectedVente = ventesExternes.first.numventes; // À implémenter avec un dialogue
      if (selectedVente != null) {
        await _copierLignesVenteExterne(externalDbService, selectedVente);
      }

      await externalDbService.database.close();
    } catch (e) {
      debugPrint('Erreur lors de l\'importation: $e');
    }
  }
  
  Future<void> _copierLignesVenteExterne(DatabaseService externalDb, String numVenteSource) async {
    try {
      final details = await (externalDb.database.select(externalDb.database.detventes)
            ..where((d) => d.numventes.equals(numVenteSource)))
          .get();

      if (details.isEmpty) {
        return;
      }

      final lignesValides = <Map<String, dynamic>>[];
      for (final detail in details) {
        final articleExiste = _articles.any((a) => a.designation == detail.designation);
        if (articleExiste) {
          lignesValides.add({
            'designation': detail.designation ?? '',
            'unites': detail.unites ?? '',
            'quantite': detail.q ?? 0.0,
            'prixUnitaire': detail.pu ?? 0.0,
            'montant': (detail.q ?? 0.0) * (detail.pu ?? 0.0),
            'depot': detail.depots ?? 'MAG',
            'diffPrix': (detail.diffPrix ?? 0.0) / (detail.q ?? 1.0),
          });
        }
      }

      if (lignesValides.isEmpty) {
        return;
      }

      _lignesVente.clear();
      _lignesVente.addAll(lignesValides);
      notifyListeners();
      calculerTotaux();
    } catch (e) {
      debugPrint('Erreur lors de l\'importation: $e');
    }
  }
  
  // ============ GESTION DES CLIENTS ============
  
  Future<void> verifierEtCreerClient(String nomClient) async {
    if (nomClient.trim().isEmpty) return;

    final clientExiste = _clients.any((client) => client.rsoc.toLowerCase() == nomClient.toLowerCase());

    if (!clientExiste) {
      try {
        await _databaseService.database.into(_databaseService.database.clt).insert(
              CltCompanion.insert(
                rsoc: nomClient,
                categorie: drift.Value(
                    _tousDepots ? ClientCategory.tousDepots.label : ClientCategory.magasin.label),
                commercial: drift.Value(AuthService().currentUser?.nom ?? ''),
                taux: drift.Value(0),
                soldes: drift.Value(0),
                soldesa: drift.Value(0),
                action: drift.Value("A"),
                plafon: drift.Value(9000000000.0),
                plafonbl: drift.Value(9000000000.0),
              ),
            );

        await _loadData();

        _selectedClient = nomClient;
        clientController.text = nomClient;
        _showCreditMode = _tousDepots;
        if ((!_showCreditMode || isVendeur()) && _selectedModePaiement == 'A crédit') {
          _selectedModePaiement = 'Espèces';
        }
        
        notifyListeners();
        await _chargerSoldeClient(nomClient);

        Future.delayed(const Duration(milliseconds: 100), () {
          if (_shouldFocusOnClient()) {
            clientFocusNode.requestFocus();
          } else {
            designationFocusNode.requestFocus();
          }
        });
      } catch (e) {
        debugPrint('Erreur lors de la création du client: $e');
      }
    } else {
      final client = _clients.firstWhere(
        (client) => client.rsoc.toLowerCase() == nomClient.toLowerCase(),
      );
      _selectedClient = client.rsoc;
      clientController.text = client.rsoc;
      _showCreditMode = _shouldShowCreditMode(client);
      if ((!_showCreditMode || isVendeur()) && _selectedModePaiement == 'A crédit') {
        _selectedModePaiement = 'Espèces';
      }
      
      notifyListeners();
      await _chargerSoldeClient(client.rsoc);
    }
  }
  
  bool _shouldFocusOnClient() {
    return !_tousDepots && isVendeur();
  }
  
  // ============ IMPRESSION ET PDF ============
  
  Future<void> imprimerFacture() async {
    if (_lignesVente.isEmpty) {
      return;
    }

    try {
      final societe =
          await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();
      final pdf = await _pdfGenerator.generateFacturePdf(
        numVente: numVentesController.text,
        nFacture: nFactureController.text,
        date: dateController.text,
        client: _selectedClient ?? '',
        lignesVente: _lignesVente,
        totalTTC: double.tryParse(totalTTCController.text.replaceAll(' ', '')) ?? 0,
        remise: double.tryParse(remiseController.text) ?? 0,
        selectedFormat: _selectedFormat,
        societe: societe,
        modePaiement: _selectedModePaiement ?? 'A crédit',
      );
      final bytes = await pdf.save();

      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;

      if (defaultPrinter != null) {
        await Printing.directPrintPdf(
          printer: defaultPrinter,
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Facture_${nFactureController.text}_${dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Facture_${nFactureController.text}_${dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      }
    } catch (e) {
      debugPrint('Erreur d\'impression: $e');
    }
  }
  
  Future<void> apercuFacture() async {
    if (_lignesVente.isEmpty) {
      return;
    }

    try {
      final societe =
          await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();
      // À implémenter avec un dialogue d'aperçu
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture de l\'aperçu: $e');
    }
  }
  
  Future<void> imprimerBL() async {
    if (_lignesVente.isEmpty) {
      return;
    }

    try {
      final societe =
          await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();
      final pdf = await _pdfGenerator.generateBLPdf(
        numVente: numVentesController.text,
        nFacture: nFactureController.text,
        date: dateController.text,
        client: _selectedClient ?? '',
        lignesVente: _lignesVente,
        selectedFormat: _selectedFormat,
        societe: societe,
        tousDepots: _tousDepots,
      );
      final bytes = await pdf.save();

      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;

      if (defaultPrinter != null) {
        await Printing.directPrintPdf(
          printer: defaultPrinter,
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'BL_${nFactureController.text}_${dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'BL_${nFactureController.text}_${dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      }
    } catch (e) {
      debugPrint('Erreur d\'impression: $e');
    }
  }
  
  Future<void> apercuBL() async {
    if (_lignesVente.isEmpty) {
      return;
    }

    try {
      final societe =
          await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();
      // À implémenter avec un dialogue d'aperçu
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture de l\'aperçu: $e');
    }
  }
  
  // ============ GESTION DES VENTES (LISTE) ============
  
  Future<List<Map<String, dynamic>>> _getVentesAvecStatut(bool tousDepots) async {
    final now = DateTime.now();
    if (_cachedVentes != null &&
        _lastVentesLoad != null &&
        now.difference(_lastVentesLoad!) < _cacheDuration) {
      return _cachedVentes!;
    }

    try {
      var queryVentes = _databaseService.database.select(_databaseService.database.ventes)
        ..orderBy([(v) => drift.OrderingTerm.desc(v.daty)]);

      if (isVendeur()) {
        final authService = AuthService();
        final currentUser = authService.currentUser?.nom ?? '';
        queryVentes = queryVentes..where((v) => v.commerc.equals(currentUser));
      }

      final ventesJournal = await queryVentes.get();

      List<Map<String, dynamic>> result = ventesJournal
          .map((v) => {
                'numventes': v.numventes ?? '',
                'verification': v.verification ?? 'JOURNAL',
                'daty': v.daty,
                'contre': v.contre ?? '',
                'nfact': v.nfact ?? '',
              })
          .where((v) => (v['numventes'] as String).isNotEmpty)
          .toList();

      if (!tousDepots) {
        result = result.where((v) {
          final nfact = v['nfact'] as String? ?? '';
          return nfact.startsWith('MAG');
        }).toList();
      } else {
        result = result.where((v) {
          final nfact = v['nfact'] as String? ?? '';
          return nfact.startsWith('DEP');
        }).toList();
      }

      result.sort((a, b) => (b['daty'] ?? DateTime(0)).compareTo(a['daty'] ?? DateTime(0)));

      _cachedVentes = result;
      _lastVentesLoad = now;

      return result;
    } catch (e) {
      debugPrint('Erreur lors du chargement des ventes: $e');
      return [];
    }
  }
  
  void _reloadVentesList() {
    _invalidateVentesCache();
    _ventesFuture = _getVentesAvecStatut(_tousDepots);
    notifyListeners();
  }
  
  void _invalidateVentesCache() {
    _cachedVentes = null;
    _lastVentesLoad = null;
  }
  
  Widget buildVentesListByStatus(String statut, BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ventesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'Aucune donnée',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          );
        }

        List<Map<String, dynamic>> ventes;
        if (statut == 'CONTRE_PASSE') {
          ventes = snapshot.data!
              .where((v) => (v['verification'] ?? 'JOURNAL') == 'JOURNAL' && (v['contre'] ?? '') == '1')
              .toList();
        } else {
          ventes = snapshot.data!
              .where((v) => (v['verification'] ?? 'JOURNAL') == statut && (v['contre'] ?? '') != '1')
              .toList();
        }

        final filteredVentes = _searchVentesText.isEmpty
            ? ventes
            : ventes.where((v) => v['numventes'].toLowerCase().contains(_searchVentesText)).toList();

        if (filteredVentes.isEmpty) {
          String message;
          switch (statut) {
            case 'BROUILLARD':
              message = 'Aucune vente en brouillard';
              break;
            case 'CONTRE_PASSE':
              message = 'Aucune vente contre-passée';
              break;
            default:
              message = 'Aucune vente validée';
          }
          return Center(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredVentes.length,
          itemBuilder: (context, index) {
            final vente = filteredVentes[index];
            final numVente = vente['numventes'];
            final isSelected = numVente == numVentesController.text;
            final isBrouillard = statut == 'BROUILLARD';
            final isContrePassee = statut == 'CONTRE_PASSE';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: isSelected ? Border.all(color: Colors.blue[300]!, width: 1) : null,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(
                  'Vente N° $numVente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue[800] : Colors.black87,
                  ),
                ),
                subtitle: isBrouillard
                    ? Text(
                        'En attente de validation',
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? Colors.orange[700] : Colors.orange,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      )
                    : isContrePassee
                        ? Text(
                            'Contre-passée',
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected ? Colors.red[700] : Colors.red,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            ),
                          )
                        : null,
                onTap: () {
                  numVentesController.text = numVente;
                  chargerVenteExistante(numVente);
                },
              ),
            );
          },
        );
      },
    );
  }
  
  // ============ RACCOURCIS CLAVIER ============
  
  void handleKeyboardShortcut(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
        if (peutValiderBrouillard()) {
          _sauvegarderModificationsBrouillard();
        } else if (_lignesVente.isNotEmpty) {
          modifierVente();
        }
      } else if (isCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyR) {
        // Focus sur montant reçu
      } else if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyR) {
        // Focus sur monnaie à rendre
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyT) {
        // Focus sur TVA
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyJ) {
        _ventesFuture?.then((ventes) {
          final journals = ventes.where((v) => v['verification'] == 'JOURNAL' && v['contre'] != '1').toList();
          if (journals.isNotEmpty) {
            final dernierJournal = journals.first;
            chargerVenteExistante(dernierJournal['numventes']);
          }
        });
      } else if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyX) {
        _ventesFuture?.then((ventes) {
          final contrePassees =
              ventes.where((v) => v['verification'] == 'JOURNAL' && v['contre'] == '1').toList();
          if (contrePassees.isNotEmpty) {
            final derniereCP = contrePassees.first;
            chargerVenteExistante(derniereCP['numventes']);
          }
        });
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
        searchArticleFocusNode.requestFocus();
        Future.delayed(const Duration(milliseconds: 50), () {
          searchArticleController.selection =
              TextSelection(baseOffset: 0, extentOffset: searchArticleController.text.length);
        });
      } else if (isCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyP) {
        if (_lignesVente.isNotEmpty) {
          imprimerFacture();
        }
      } else if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyP) {
        if (_lignesVente.isNotEmpty) {
          imprimerBL();
        }
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
        creerNouvelleVente();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyD) {
        if (_isExistingPurchase) {
          contrePasserVente();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.f3) {
        if (peutValiderBrouillard()) {
          validerBrouillardVersJournal();
        }
      }

      final tabResult = handleTabNavigation(event);
      if (tabResult == KeyEventResult.handled) {
        return;
      }
    }
  }
  
  // ============ MÉTHODES AUXILIAIRES ============
  
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}