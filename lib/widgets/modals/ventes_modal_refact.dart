import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/vente_types.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/price_calculation_service.dart';
import '../../services/vente_client_service.dart';
import '../common/tab_navigation_widget.dart';
import 'sales_lines_list_widget.dart';
import 'ventes_actions_widget.dart';
import 'ventes_header_widget.dart';
import 'ventes_intents.dart';
import 'ventes_line_input_widget.dart';
import 'ventes_list_widget.dart';

/// Modal de gestion des ventes - Version refactorisée
class VentesModal extends StatefulWidget {
  final bool tousDepots;

  const VentesModal({super.key, required this.tousDepots});

  @override
  State<VentesModal> createState() => _VentesModalRefactoredState();
}

class _VentesModalRefactoredState extends State<VentesModal> with TabNavigationMixin {
  // Services
  final DatabaseService _databaseService = DatabaseService();
  final VenteClientService _clientService = VenteClientService();
  final PriceCalculationService _priceService = PriceCalculationService();

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Focus nodes
  late final FocusNode _globalShortcutsFocusNode;
  late final FocusNode _clientFocusNode;
  late final FocusNode _designationFocusNode;
  late final FocusNode _depotFocusNode;
  late final FocusNode _uniteFocusNode;
  late final FocusNode _quantiteFocusNode;
  late final FocusNode _prixFocusNode;
  late final FocusNode _ajouterFocusNode;
  late final FocusNode _annulerFocusNode;

  // Controllers
  final TextEditingController _numVentesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nFactureController = TextEditingController();
  final TextEditingController _heureController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _remiseController = TextEditingController();
  final TextEditingController _totalTTCController = TextEditingController();
  final TextEditingController _avanceController = TextEditingController();
  final TextEditingController _resteController = TextEditingController();
  final TextEditingController _depotController = TextEditingController();
  final TextEditingController _uniteController = TextEditingController();
  final TextEditingController _searchVentesController = TextEditingController();

  // Data
  List<Article> _articles = [];
  List<Depot> _depots = [];
  final List<Map<String, dynamic>> _lignesVente = [];
  Future<List<Map<String, dynamic>>>? _ventesFuture;

  // State
  Article? _selectedArticle;
  String? _selectedUnite;
  String? _selectedDepot;
  bool _isExistingPurchase = false;
  bool _isModifyingLine = false;
  String _defaultDepot = 'MAG';
  String _searchVentesText = '';
  final double _stockDisponible = 0.0;
  final String _uniteAffichage = '';
  StatutVente? _statutVenteActuelle;

  Timer? _globalFocusTimer;

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
    _initializeAsync();
    _setupListeners();
  }

  void _initializeFocusNodes() {
    _globalShortcutsFocusNode = FocusNode(debugLabel: 'GlobalShortcuts', skipTraversal: true);
    _clientFocusNode = createFocusNode();
    _designationFocusNode = createFocusNode();
    _depotFocusNode = createFocusNode();
    _uniteFocusNode = createFocusNode();
    _quantiteFocusNode = createFocusNode();
    _prixFocusNode = createFocusNode();
    _ajouterFocusNode = createFocusNode();
    _annulerFocusNode = createFocusNode();
  }

  void _setupListeners() {
    _searchVentesController.addListener(() {
      setState(() => _searchVentesText = _searchVentesController.text.toLowerCase());
    });

    _globalFocusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_globalShortcutsFocusNode.hasFocus) {
        _ensureGlobalShortcutsFocus();
      }
    });
  }

  Future<void> _initializeAsync() async {
    await Future.wait([_loadData(), _loadDefaultDepot()]);
    _initializeForm();
    _ventesFuture = _getVentesAvecStatut();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _clientFocusNode.requestFocus();
        _ensureGlobalShortcutsFocus();
      }
    });
  }

  void _ensureGlobalShortcutsFocus() {
    if (!_globalShortcutsFocusNode.hasFocus) {
      final currentFocus = FocusScope.of(context).focusedChild;
      _globalShortcutsFocusNode.requestFocus();
      Future.delayed(const Duration(milliseconds: 50), () => currentFocus?.requestFocus());
    }
  }

  Future<List<Map<String, dynamic>>> _getVentesAvecStatut() async {
    // Implémentation simplifiée - à compléter selon besoins
    return [];
  }

  Future<void> _loadData() async {
    try {
      final articles = await _databaseService.database.getActiveArticles();
      final allClients = await _databaseService.database.getActiveClients();
      final depots = await _databaseService.database.getAllDepots();

      final filteredClients = _clientService.filterClientsByRole(allClients, widget.tousDepots);
      filteredClients.sort((a, b) => a.rsoc.toLowerCase().compareTo(b.rsoc.toLowerCase()));

      setState(() {
        _articles = articles;
        _depots = depots;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement: $e')));
      }
    }
  }

  Future<void> _loadDefaultDepot() async {
    setState(() {
      _defaultDepot = widget.tousDepots ? 'DEP' : 'MAG';
      _selectedDepot = _defaultDepot;
      _depotController.text = _defaultDepot;
    });
  }

  void _initializeForm() async {
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _heureController.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _numVentesController.text = await _getNextNumVentes();
    _nFactureController.text = await _getNextNumBL();
    _remiseController.text = '0';
    _totalTTCController.text = '0';
    _avanceController.text = '0';
    _resteController.text = '0';
  }

  Future<String> _getNextNumVentes() async {
    // Implémentation simplifiée
    return '2607';
  }

  Future<String> _getNextNumBL() async {
    final prefix = widget.tousDepots ? 'DEP' : 'MAG';
    return '${prefix}0001';
  }

  void _calculerTotaux() {
    double totalHT = _priceService.calculateTotalHT(_lignesVente);
    double remise = double.tryParse(_remiseController.text) ?? 0;
    double totalTTC = _priceService.calculateTotalTTC(totalHT, remise);
    double avance = double.tryParse(_avanceController.text) ?? 0;
    double reste = _priceService.calculateReste(totalTTC, avance);

    setState(() {
      _totalTTCController.text = totalTTC.toStringAsFixed(2);
      _resteController.text = reste.toStringAsFixed(2);
    });
  }

  bool _isVendeur() => AuthService().currentUserRole == 'Vendeur';

  bool _peutValiderBrouillard() {
    return _isExistingPurchase && !_isVendeur() && _statutVenteActuelle == StatutVente.brouillard;
  }

  @override
  void dispose() {
    _globalFocusTimer?.cancel();
    _globalShortcutsFocusNode.dispose();
    _clientFocusNode.dispose();
    _designationFocusNode.dispose();
    _depotFocusNode.dispose();
    _uniteFocusNode.dispose();
    _quantiteFocusNode.dispose();
    _prixFocusNode.dispose();
    _ajouterFocusNode.dispose();
    _annulerFocusNode.dispose();
    _numVentesController.dispose();
    _dateController.dispose();
    _nFactureController.dispose();
    _heureController.dispose();
    _clientController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _montantController.dispose();
    _remiseController.dispose();
    _totalTTCController.dispose();
    _avanceController.dispose();
    _resteController.dispose();
    _depotController.dispose();
    _uniteController.dispose();
    _searchVentesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, control: true): NewSaleIntent(),
        SingleActivator(LogicalKeyboardKey.escape): CloseIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => _validerVente()),
          NewSaleIntent: CallbackAction<NewSaleIntent>(onInvoke: (_) => _creerNouvelleVente()),
          CloseIntent: CallbackAction<CloseIntent>(onInvoke: (_) => Navigator.of(context).pop()),
        },
        child: Dialog(
          child: ScaffoldMessenger(
            key: _scaffoldMessengerKey,
            child: Scaffold(
              body: Column(
                children: [
                  _buildTitleBar(),
                  Expanded(
                    child: Row(
                      children: [
                        _buildLeftSidebar(),
                        Expanded(child: _buildMainContent()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 35,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'VENTES (${widget.tousDepots ? 'Tous dépôts' : 'Dépôt MAG'})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchVentesController,
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 16),
              ),
            ),
          ),
          Expanded(
            child: VentesListWidget(
              ventesFuture: _ventesFuture,
              searchText: _searchVentesText,
              currentNumVente: _numVentesController.text,
              isVendeur: _isVendeur(),
              onVenteSelected: (numVente) {
                // Charger la vente sélectionnée
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        VentesHeaderWidget(
          numVentesController: _numVentesController,
          dateController: _dateController,
          nFactureController: _nFactureController,
          heureController: _heureController,
          isExistingPurchase: _isExistingPurchase,
        ),
        VentesLineInputWidget(
          selectedArticle: _selectedArticle,
          selectedUnite: _selectedUnite,
          selectedDepot: _selectedDepot,
          quantiteController: _quantiteController,
          prixController: _prixController,
          montantController: _montantController,
          depotController: _depotController,
          uniteController: _uniteController,
          designationFocusNode: _designationFocusNode,
          depotFocusNode: _depotFocusNode,
          uniteFocusNode: _uniteFocusNode,
          quantiteFocusNode: _quantiteFocusNode,
          prixFocusNode: _prixFocusNode,
          ajouterFocusNode: _ajouterFocusNode,
          annulerFocusNode: _annulerFocusNode,
          articles: _articles,
          depots: _depots,
          onArticleSelected: (article) => setState(() => _selectedArticle = article),
          onUniteChanged: (unite) => setState(() => _selectedUnite = unite),
          onDepotChanged: (depot) => setState(() => _selectedDepot = depot),
          onAjouter: _ajouterLigne,
          onAnnuler: _annulerModificationLigne,
          showAddButton: true,
          isModifyingLine: _isModifyingLine,
          uniteAffichage: _uniteAffichage,
          stockDisponible: _stockDisponible,
        ),
        Expanded(
          child: SalesLinesListWidget(
            lignesVente: _lignesVente,
            onEditLine: (index) =>
                () => _chargerLigneArticle(index),
            onDeleteLine: (index) =>
                () => _supprimerLigne(index),
            isVendeur: _isVendeur(),
          ),
        ),
        VentesActionsWidget(
          isExistingPurchase: _isExistingPurchase,
          peutValiderBrouillard: _peutValiderBrouillard(),
          isVendeur: _isVendeur(),
          onNouvelle: _creerNouvelleVente,
          onValider: _validerVente,
          onValiderBrouillard: () {},
          onContrePasser: () {},
          onImprimerFacture: () {},
          onImprimerBL: () {},
          onApercuFacture: () {},
          onApercuBL: () {},
        ),
      ],
    );
  }

  void _ajouterLigne() {
    // Implémentation simplifiée
    _calculerTotaux();
  }

  void _chargerLigneArticle(int index) {
    if (index < 0 || index >= _lignesVente.length) return;

    final ligne = _lignesVente[index];
    final article = _articles.where((a) => a.designation == ligne['designation']).firstOrNull;

    setState(() {
      _selectedArticle = article;
      _selectedUnite = ligne['unites'];
      _selectedDepot = ligne['depot'];
      _isModifyingLine = true;

      _depotController.text = ligne['depot'];
      _uniteController.text = ligne['unites'];
      _quantiteController.text = ligne['quantite'].toString();
      _prixController.text = ligne['prixUnitaire'].toString();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _quantiteFocusNode.requestFocus();
    });
  }

  void _supprimerLigne(int index) {
    if (index < 0 || index >= _lignesVente.length) return;

    setState(() {
      _lignesVente.removeAt(index);
    });
    _calculerTotaux();
  }

  void _annulerModificationLigne() {
    setState(() {
      _isModifyingLine = false;
    });
  }

  Future<void> _validerVente() async {
    // Implémentation simplifiée
  }

  void _creerNouvelleVente() {
    setState(() {
      _isExistingPurchase = false;
      _lignesVente.clear();
    });
    _initializeForm();
  }
}
