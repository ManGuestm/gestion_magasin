// export 'ventes_modal/ventes_modal.dart';

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../constants/app_functions.dart';
import '../../constants/client_categories.dart';
import '../../constants/vente_types.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/vente_service.dart';
import '../../utils/stock_converter.dart';
import '../../widgets/common/article_navigation_autocomplete.dart';
import '../../widgets/common/enhanced_autocomplete.dart';
import '../../widgets/common/mode_paiement_dropdown.dart';
import '../common/tab_navigation_widget.dart';
import 'bon_livraison_preview.dart';
import 'facture_preview.dart';

class VentesModal extends StatefulWidget {
  final bool tousDepots;

  const VentesModal({super.key, required this.tousDepots});

  @override
  State<VentesModal> createState() => _VentesModalState();
}

class _VentesModalState extends State<VentesModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  final VenteService _venteService = VenteService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Focus node pour les raccourcis globaux
  late final FocusNode _globalShortcutsFocusNode;

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
  final TextEditingController _nouveauSoldeController = TextEditingController();
  final TextEditingController _echeanceController = TextEditingController();
  TextEditingController? _autocompleteController;
  final TextEditingController _depotController = TextEditingController();
  final TextEditingController _uniteController = TextEditingController();
  final TextEditingController _searchVentesController = TextEditingController();
  final TextEditingController _searchArticleController = TextEditingController();

  // Lists
  List<Article> _articles = [];
  List<CltData> _clients = [];
  List<Depot> _depots = [];
  final List<Map<String, dynamic>> _lignesVente = [];
  // Ajouter une propriété pour stocker le Future
  Future<List<Map<String, dynamic>>>? _ventesFuture;

  List<Map<String, dynamic>>? _cachedVentes;
  DateTime? _lastVentesLoad;
  static const _cacheDuration = Duration(seconds: 30);

  // Selected values
  Article? _selectedArticle;
  String? _selectedUnite;
  String? _selectedDepot;
  String? _selectedModePaiement = 'A crédit';
  String? _selectedClient;
  // String? _selectedCommercial;
  int? _selectedRowIndex;
  bool _isExistingPurchase = false;
  bool _isModifyingLine = false;
  int? _modifyingLineIndex;
  Map<String, dynamic>? originalLineData;
  String _defaultDepot = 'MAG';
  bool _showCreditMode = true;

  String _searchVentesText = '';

  // Right sidebar state
  bool _isRightSidebarCollapsed = false;
  Article? _searchedArticle;

  // Stock management
  double _stockDisponible = 0.0;
  bool _stockInsuffisant = false;
  String _uniteAffichage = '';

  // Client balance
  double _soldeAnterieur = 0.0;
  final TextEditingController _soldeAnterieurController = TextEditingController();

  // Client validation
  bool get _isClientSelected => _selectedClient != null && _selectedClient!.isNotEmpty;

  // Paper format
  String _selectedFormat = 'A6';

  // Workflow validation
  String _selectedVerification = 'BROUILLARD';
  StatutVente _statutVente = StatutVente.brouillard;
  StatutVente? _statutVenteActuelle;

  // Focus nodes for tab navigation
  late final FocusNode _clientFocusNode;
  late final FocusNode _designationFocusNode;
  late final FocusNode _depotFocusNode;
  late final FocusNode _uniteFocusNode;
  late final FocusNode _quantiteFocusNode;
  late final FocusNode _prixFocusNode;
  late final FocusNode _ajouterFocusNode;
  late final FocusNode _annulerFocusNode;
  late final FocusNode _montantRecuFocusNode;
  late final FocusNode _montantARendreFocusNode;
  late final FocusNode _searchArticleFocusNode;
  final FocusNode _keyboardFocusNode = FocusNode();

  // Timer pour maintenir le focus global
  Timer? _globalFocusTimer;

  @override
  void initState() {
    super.initState();

    // Initialiser le focus node pour les raccourcis globaux
    _globalShortcutsFocusNode = FocusNode(
      debugLabel: 'GlobalShortcutsFocusNode',
      canRequestFocus: true,
      skipTraversal: true, // Ne pas être inclus dans la navigation Tab
    );

    // Initialize focus nodes with tab navigation
    _clientFocusNode = createFocusNode();
    _designationFocusNode = createFocusNode();
    _depotFocusNode = createFocusNode();
    _uniteFocusNode = createFocusNode();
    _quantiteFocusNode = createFocusNode();
    _prixFocusNode = createFocusNode();
    _ajouterFocusNode = createFocusNode();
    _annulerFocusNode = createFocusNode();
    _montantRecuFocusNode = createFocusNode();
    _montantARendreFocusNode = createFocusNode();
    _searchArticleFocusNode = createFocusNode();

    // Charger les données de manière optimisée
    _initializeAsync();

    _searchVentesController.addListener(() {
      setState(() {
        _searchVentesText = _searchVentesController.text.toLowerCase();
      });
    });

    _searchArticleController.addListener(() {
      _onSearchArticleChanged(_searchArticleController.text);
    });

    _depotFocusNode.addListener(() {
      if (_depotFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_depotFocusNode.hasFocus) {
            _depotFocusNode.requestFocus();
          }
        });
      }
    });

    // Ajouter des listeners pour les focus nodes
    _ajouterFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _annulerFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    // Position cursor in client field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Donner le focus au nœud global pour les raccourcis
      _globalShortcutsFocusNode.requestFocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        _clientFocusNode.requestFocus();
      });
      // Maintenir le focus après la construction du FutureBuilder
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _clientFocusNode.requestFocus();
        }
      });
    });
    // Créer le Future une seule fois
    _ventesFuture = _getVentesAvecStatut();

    // S'assurer que les raccourcis globaux restent actifs
    _globalFocusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Vérifier périodiquement si le focus global est perdu
      if (!_globalShortcutsFocusNode.hasFocus && !_globalShortcutsFocusNode.hasPrimaryFocus) {
        _ensureGlobalShortcutsFocus();
      }
    });
  }

  void _reloadVentesList() {
    setState(() {
      _invalidateVentesCache();
      _ventesFuture = _getVentesAvecStatut(); // Recréer le Future
    });
  }

  // Nouvelle méthode pour initialisation asynchrone optimisée
  Future<void> _initializeAsync() async {
    // Charger en parallèle pour gagner du temps
    await Future.wait([_loadData(), _loadDefaultDepot()]);

    _initializeForm();

    // Maintenir le focus sur le champ Client après le chargement
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _clientFocusNode.requestFocus();
        // S'assurer que le focus global reste actif pour les raccourcis
        _ensureGlobalShortcutsFocus();
      }
    });
  }

  // Méthode pour s'assurer que les raccourcis globaux restent actifs
  void _ensureGlobalShortcutsFocus() {
    if (!_globalShortcutsFocusNode.hasFocus) {
      // Donner temporairement le focus au nœud global puis revenir au champ actuel
      final currentFocus = FocusScope.of(context).focusedChild;
      _globalShortcutsFocusNode.requestFocus();
      Future.delayed(const Duration(milliseconds: 50), () {
        currentFocus?.requestFocus();
      });
    }
  }

  // Remplacer la méthode _getVentesAvecStatut() par :
  Future<List<Map<String, dynamic>>> _getVentesAvecStatut() async {
    // Vérifier si le cache est encore valide
    final now = DateTime.now();
    if (_cachedVentes != null &&
        _lastVentesLoad != null &&
        now.difference(_lastVentesLoad!) < _cacheDuration) {
      return _cachedVentes!;
    }

    try {
      // Code existant - récupérer les ventes journalées
      var queryVentes = _databaseService.database.select(_databaseService.database.ventes)
        ..orderBy([(v) => drift.OrderingTerm.desc(v.daty)]);

      if (_isVendeur()) {
        final authService = AuthService();
        final currentUser = authService.currentUser?.nom ?? '';
        queryVentes = queryVentes..where((v) => v.commerc.equals(currentUser));
      }

      final ventesJournal = await queryVentes.get();

      List<Map<String, dynamic>> result = ventesJournal
          .map(
            (v) => {
              'numventes': v.numventes ?? '',
              'verification': v.verification ?? 'JOURNAL',
              'daty': v.daty,
              'contre': v.contre ?? '',
              'nfact': v.nfact ?? '',
            },
          )
          .where((v) => (v['numventes'] as String).isNotEmpty)
          .toList();

      // Filtrer par N° Fact/BL si dépôt MAG seulement
      if (!widget.tousDepots) {
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

      // Trier par numéro de vente décroissant
      result.sort((a, b) {
        final numA = int.tryParse(a['numventes'] ?? '0') ?? 0;
        final numB = int.tryParse(b['numventes'] ?? '0') ?? 0;
        return numA.compareTo(numB);
      });

      // Mettre à jour le cache
      _cachedVentes = result;
      _lastVentesLoad = now;

      return result;
    } catch (e) {
      debugPrint('Erreur lors du chargement des ventes: $e');
      return [];
    }
  }

  // Ajouter une méthode pour invalider le cache quand nécessaire :
  void _invalidateVentesCache() {
    _cachedVentes = null;
    _lastVentesLoad = null;
  }

  bool _peutValiderBrouillard() {
    if (!_isExistingPurchase || _numVentesController.text.isEmpty) return false;

    // Empêcher les vendeurs de valider vers le journal
    if (_isVendeur()) return false;

    // Vérifier si la vente actuelle est en brouillard
    return _isVenteBrouillard();
  }

  bool _isVenteBrouillard() {
    // Cette méthode sera mise à jour lors du chargement de la vente
    return _statutVenteActuelle == StatutVente.brouillard;
  }

  Future<bool> _isVenteContrePassee() async {
    if (!_isExistingPurchase || _numVentesController.text.isEmpty) return false;

    try {
      final vente = await (_databaseService.database.select(
        _databaseService.database.ventes,
      )..where((v) => v.numventes.equals(_numVentesController.text))).getSingleOrNull();

      return vente?.contre == '1';
    } catch (e) {
      return false;
    }
  }

  Future<void> _sauvegarderModificationsBrouillard() async {
    if (!_isExistingPurchase || _numVentesController.text.isEmpty) return;

    double totalHT = 0;
    for (var ligne in _lignesVente) {
      totalHT += ligne['montant'] ?? 0;
    }

    double remise = double.tryParse(_remiseController.text) ?? 0;
    double totalApresRemise = totalHT - (totalHT * remise / 100);
    double totalTTC = totalApresRemise;
    double avance = double.tryParse(_avanceController.text) ?? 0;

    await _databaseService.database.transaction(() async {
      // Supprimer toutes les anciennes lignes
      await (_databaseService.database.delete(
        _databaseService.database.detventes,
      )..where((d) => d.numventes.equals(_numVentesController.text))).go();

      // Mettre à jour la vente principale
      await (_databaseService.database.update(
        _databaseService.database.ventes,
      )..where((v) => v.numventes.equals(_numVentesController.text))).write(
        VentesCompanion(
          nfact: drift.Value(_nFactureController.text),
          clt: drift.Value(_selectedClient ?? ''),
          modepai: drift.Value(_selectedModePaiement ?? 'A crédit'),
          totalttc: drift.Value(totalTTC),
          avance: drift.Value(avance),
          remise: drift.Value(remise),
          heure: drift.Value(_heureController.text),
        ),
      );

      // Insérer les nouvelles lignes
      for (var ligne in _lignesVente) {
        await _databaseService.database
            .into(_databaseService.database.detventes)
            .insert(
              DetventesCompanion.insert(
                numventes: drift.Value(_numVentesController.text),
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

  Future<void> _validerBrouillardVersJournal() async {
    if (!_isExistingPurchase || _numVentesController.text.isEmpty) return;

    // Vérifier s'il y a des articles avec stock insuffisant selon le type de dépôt
    bool hasStockInsuffisant = await _verifierStockPourValidation();

    if (hasStockInsuffisant) {
      if (!widget.tousDepots) {
        // MAG uniquement: bloquer la validation si stock insuffisant
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.8,
                right: 20,
                left: MediaQuery.of(context).size.width * 0.75,
              ),
              content: const SelectableText(
                'Impossible de valider: certains articles ont un stock insuffisant dans le dépôt MAG',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      // Pour tous dépôts: permettre la validation même avec stock insuffisant
    }

    final confirm = mounted
        ? await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Validation vers Journal'),
              content: Text(
                'Voulez-vous valider la vente N° ${_numVentesController.text} vers le journal ?\n\n'
                'Cette action créera les mouvements de stock et mettra à jour les quantités.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  autofocus: true,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          )
        : null;

    if (confirm != true) return;

    try {
      // Sauvegarder d'abord les modifications actuelles
      await _sauvegarderModificationsBrouillard();

      await _venteService.validerVenteBrouillardVersJournal(
        numVentes: _numVentesController.text,
        nFacture: _nFactureController.text,
        client: _selectedClient,
        modePaiement: _selectedModePaiement,
        totalTTC: double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0,
        avance: double.tryParse(_avanceController.text) ?? 0,
        remise: double.tryParse(_remiseController.text) ?? 0,
      );

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            content: const SelectableText('Vente validée vers le journal avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // RELEVANT: Recharger la liste des ventes immédiatement
        _reloadVentesList();

        // Recharger la vente pour afficher le nouveau statut
        await _chargerVenteExistante(_numVentesController.text);

        // Mettre à jour le statut d'enregistrement
        setState(() {
          _selectedVerification = 'JOURNAL';
          _statutVente = StatutVente.journal;
        });

        // Réactiver les raccourcis globaux
        _ensureGlobalShortcutsFocus();
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            behavior: SnackBarBehavior.floating,
            content: SelectableText('Erreur lors de la validation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _chargerVenteExistante(String numVentes) async {
    if (numVentes.isEmpty) {
      setState(() {
        _isExistingPurchase = false;
      });
      return;
    }

    try {
      // Vérifier d'abord si c'est une vente journalée
      final vente = await (_databaseService.database.select(
        _databaseService.database.ventes,
      )..where((v) => v.numventes.equals(numVentes))).getSingleOrNull();

      if (vente != null) {
        // Vente journalée
        final details = await (_databaseService.database.select(
          _databaseService.database.detventes,
        )..where((d) => d.numventes.equals(numVentes))).get();

        setState(() {
          _isExistingPurchase = true;
          _selectedVerification = vente.verification ?? 'JOURNAL';
          _statutVenteActuelle = vente.verification == 'BROUILLARD'
              ? StatutVente.brouillard
              : StatutVente.journal;

          _nFactureController.text = vente.nfact ?? '';
          if (vente.daty != null) {
            _dateController.text =
                '${vente.daty!.day.toString().padLeft(2, '0')}/${vente.daty!.month.toString().padLeft(2, '0')}/${vente.daty!.year}';
          }
          _clientController.text = vente.clt ?? '';
          _selectedClient = vente.clt;
          _selectedModePaiement = vente.modepai ?? 'A crédit';
          _heureController.text = vente.heure ?? '';

          if (vente.clt != null && vente.clt!.isNotEmpty) {
            final client = _clients.where((c) => c.rsoc == vente.clt).firstOrNull;
            if (client != null) {
              _showCreditMode = _shouldShowCreditMode(client);
            }
          }
          _chargerSoldeClient(vente.clt);
          _remiseController.text = (vente.remise ?? 0).toString();
          _avanceController.text = (vente.avance ?? 0).toString();

          _lignesVente.clear();
          for (var detail in details) {
            // Calculer la différence de prix unitaire à partir de la différence totale stockée
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
              'diffPrix': diffPrixUnitaire, // Différence unitaire
            });
          }
        });
      } else {
        setState(() {
          _isExistingPurchase = false;
        });
        return;
      }

      _calculerTotaux();

      // Ne pas changer le focus lors du chargement d'une vente existante
      // Le focus reste sur le champ client par défaut
    } catch (e) {
      setState(() {
        _isExistingPurchase = false;
      });
    }
  }

  List<CltData> _filterClientsByRole(List<CltData> allClients) {
    // Pour tous les autres cas, retourner tous les clients
    return allClients;
  }

  bool _isVendeur() {
    final authService = AuthService();
    return authService.currentUserRole == 'Vendeur';
  }

  bool _shouldShowCreditMode(CltData? client) {
    if (client == null) return true;
    return client.categorie == null || client.categorie == ClientCategory.tousDepots.label;
  }

  bool _shouldFocusOnClient() {
    // Pour vente dépôt seulement (MAG) et utilisateur vendeur
    return !widget.tousDepots && _isVendeur();
  }

  @override
  void dispose() {
    _globalFocusTimer?.cancel();
    _globalShortcutsFocusNode.dispose();
    _autocompleteController?.dispose();
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
    _nouveauSoldeController.dispose();
    _echeanceController.dispose();
    _depotController.dispose();
    _uniteController.dispose();
    _searchVentesController.dispose();
    _searchArticleController.dispose();
    _soldeAnterieurController.dispose();
    _montantRecuFocusNode.dispose();
    _montantARendreFocusNode.dispose();
    _searchArticleFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
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

  Future<String> _getNextNumBL() async {
    try {
      final prefix = widget.tousDepots ? 'DEP' : 'MAG';
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
      final prefix = widget.tousDepots ? 'DEP' : 'MAG';
      return '${prefix}0001';
    }
  }

  void _initializeForm() async {
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _heureController.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final nextNumVentes = await _getNextNumVentes();
    _numVentesController.text = nextNumVentes;
    _nFactureController.text = await _getNextNumBL();
    _remiseController.text = '0';
    _totalTTCController.text = '0';
    _avanceController.text = '0';
    _resteController.text = '0';
    _nouveauSoldeController.text = '0';
    _selectedVerification = 'BROUILLARD';

    // Focus sur client après initialisation
    Future.delayed(const Duration(milliseconds: 100), () {
      _clientFocusNode.requestFocus();
    });
  }

  Future<void> _loadData() async {
    try {
      final articles = await _databaseService.database.getActiveArticles();
      final allClients = await _databaseService.database.getActiveClients();
      final depots = await _databaseService.database.getAllDepots();
      await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();

      // Filtrer les clients selon le rôle et le mode de vente
      final filteredClients = _filterClientsByRole(allClients);

      setState(() {
        _articles = articles;
        _clients = filteredClients;
        _depots = depots;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
      }
    }
  }

  void _onArticleSelected(Article? article) async {
    if (!_isClientSelected) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.8,
            right: 20,
            left: MediaQuery.of(context).size.width * 0.75,
          ),
          content: const Text('Veuillez d\'abord sélectionner un client'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedArticle = article;
      if (article != null) {
        // Ne vider la quantité que si on n'est pas en mode modification
        if (!_isModifyingLine) {
          _quantiteController.text = '';
        }
        _montantController.text = '';
        _uniteAffichage = _formaterUniteAffichage(article);
        // Vider le champ unité seulement si ce n'est pas une modification de ligne existante
        if (_selectedUnite == null) {
          _uniteController.clear();
        }
      }
    });

    // Ne vérifier le stock que si on n'est pas en mode modification
    if (article != null && !_isModifyingLine) {
      await _verifierStockEtBasculer(article);
    }
  }

  void _onSearchArticleChanged(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _searchedArticle = null;
      });
      return;
    }

    try {
      final article = _articles
          .where((a) => a.designation.toLowerCase().contains(text.toLowerCase()))
          .firstOrNull;

      setState(() {
        _searchedArticle = article;
      });
    } catch (e) {
      setState(() {
        _searchedArticle = null;
      });
    }
  }

  List<DropdownMenuItem<String>> _getUnitsForSelectedArticle() {
    if (_selectedArticle == null) {
      return const [
        DropdownMenuItem(
          value: '',
          child: Text('', style: TextStyle(fontSize: 12)),
        ),
      ];
    }

    List<DropdownMenuItem<String>> units = [];
    if (_selectedArticle!.u1?.isNotEmpty == true) {
      units.add(
        DropdownMenuItem(
          value: _selectedArticle!.u1,
          child: Text(_selectedArticle!.u1!, style: const TextStyle(fontSize: 12)),
        ),
      );
    }
    if (_selectedArticle!.u2?.isNotEmpty == true) {
      units.add(
        DropdownMenuItem(
          value: _selectedArticle!.u2,
          child: Text(_selectedArticle!.u2!, style: const TextStyle(fontSize: 12)),
        ),
      );
    }
    if (_selectedArticle!.u3?.isNotEmpty == true) {
      units.add(
        DropdownMenuItem(
          value: _selectedArticle!.u3,
          child: Text(_selectedArticle!.u3!, style: const TextStyle(fontSize: 12)),
        ),
      );
    }

    return units.isEmpty
        ? [
            const DropdownMenuItem(
              value: '',
              child: Text('', style: TextStyle(fontSize: 12)),
            ),
          ]
        : units;
  }

  Future<void> _verifierUniteArticle(String unite) async {
    if (_selectedArticle == null || unite.trim().isEmpty) return;

    // Vérifier si l'unité est valide pour cet article
    final unitesValides = [
      _selectedArticle!.u1,
      _selectedArticle!.u2,
      _selectedArticle!.u3,
    ].where((u) => u != null && u.isNotEmpty).toList();

    if (!unitesValides.contains(unite.trim())) {
      // Afficher modal d'erreur
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Unité invalide'),
            content: Text(
              'L\'unité "${unite.trim()}" n\'est pas valide pour l\'article "${_selectedArticle!.designation}".\n\nUnités autorisées: ${unitesValides.join(", ")}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                autofocus: true,
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // Remettre l'unité par défaut et réinitialiser le champ
      setState(() {
        _selectedUnite = _selectedArticle!.u1;
      });

      // Réinitialiser le champ unité et repositionner le curseur
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _uniteFocusNode.requestFocus();
        }
      });
      return;
    }

    _onUniteChanged(unite.trim());
  }

  void _onUniteChanged(String? unite) async {
    if (!_isClientSelected || _selectedArticle == null || unite == null) return;

    setState(() {
      _selectedUnite = unite;
      _calculerPrixPourUnite(_selectedArticle!, unite);
    });
    _isModifyingLine ? null : await _verifierStock(_selectedArticle!);
  }

  Future<void> _verifierDepot(String depot) async {
    if (depot.trim().isEmpty) return;

    // Vérifier si le dépôt existe dans la base de données
    final depotExiste = _depots.any((d) => d.depots == depot.trim());

    if (!depotExiste) {
      // Afficher modal d'erreur
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Dépôt invalide'),
            content: Text(
              'Le dépôt "${depot.trim()}" n\'existe pas.\n\n'
              'Dépôts disponibles: ${_depots.map((d) => d.depots).join(", ")}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                autofocus: true,
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // Remettre le dépôt par défaut
      setState(() {
        _selectedDepot = _defaultDepot;
        _depotController.text = _defaultDepot;
      });

      // Repositionner le curseur dans le champ dépôt
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _depotFocusNode.requestFocus();
        }
      });
      return;
    }

    _onDepotChanged(depot.trim());
  }

  void _onDepotChanged(String? depot) async {
    if (_selectedArticle == null || depot == null) return;

    setState(() {
      _selectedDepot = depot;
    });

    _isModifyingLine ? null : await _verifierStockEtBasculer(_selectedArticle!);

    // Vérifier la quantité après changement de dépôt
    if (_quantiteController.text.isNotEmpty) {
      _validerQuantite(_quantiteController.text);
    }
  }

  Future<void> _verifierStockEtBasculer(Article article) async {
    try {
      String depot = _selectedDepot ?? 'MAG';

      // Utiliser exactement la même logique que le modal articles
      final stockDepart = await (_databaseService.database.select(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).getSingleOrNull();

      // Calculer le stock total disponible en unité de base DIRECTEMENT
      double stockTotalU3 = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockDepart?.stocksu1 ?? 0.0,
        stockU2: stockDepart?.stocksu2 ?? 0.0,
        stockU3: stockDepart?.stocksu3 ?? 0.0,
      );

      // Calculer le stock disponible pour l'unité sélectionnée
      double stockPourUniteSelectionnee = _calculerStockPourUnite(
        article,
        _selectedUnite ?? article.u1!,
        stockTotalU3,
      );

      setState(() {
        _stockDisponible = stockPourUniteSelectionnee;
        _stockInsuffisant = stockTotalU3 <= 0;

        // Recalculer le prix pour l'unité sélectionnée seulement si le champ prix est vide
        if (_prixController.text.isEmpty) {
          _calculerPrixPourUnite(article, _selectedUnite ?? article.u1!);
        }
      });

      if (_stockInsuffisant) {
        await _gererStockInsuffisant(article, depot);
      } else {
        // Réinitialiser le mode si le stock redevient suffisant
        if (_statutVente == StatutVente.brouillard &&
            !_lignesVente.any((l) => l['stockInsuffisant'] == true)) {
          setState(() {
            _statutVente = StatutVente.journal;
          });
        }
      }
    } catch (e) {
      setState(() {
        _stockDisponible = 0.0;
        _stockInsuffisant = true;
      });
    }
  }

  Future<void> _verifierStock(Article article) async {
    try {
      String depot = _selectedDepot ?? 'MAG';
      String unite = _selectedUnite ?? (article.u1 ?? '');

      // Utiliser exactement la même logique que le modal articles
      final stockDepart = await (_databaseService.database.select(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).getSingleOrNull();

      // Calculer le stock total disponible en unité de base DIRECTEMENT
      double stockTotalU3 = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockDepart?.stocksu1 ?? 0.0,
        stockU2: stockDepart?.stocksu2 ?? 0.0,
        stockU3: stockDepart?.stocksu3 ?? 0.0,
      );

      // Calculer le stock disponible pour l'unité sélectionnée
      double stockPourUniteSelectionnee = _calculerStockPourUnite(article, unite, stockTotalU3);

      setState(() {
        _stockDisponible = stockPourUniteSelectionnee;
        _stockInsuffisant = stockTotalU3 <= 0;
      });
    } catch (e) {
      setState(() {
        _stockDisponible = 0.0;
        _stockInsuffisant = true;
      });
    }
  }

  void _calculerPrixPourUnite(Article article, String unite) async {
    final prixStandard = await _getPrixVenteStandard(article, unite);
    setState(() {
      _prixController.text = prixStandard > 0 ? AppFunctions.formatNumber(prixStandard) : '';
    });
  }

  // Calcule le stock total en unité de base (u3) - utilise StockConverter
  double _calculerStockTotalEnU3(Article article, double stockU1, double stockU2, double stockU3) {
    return StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );
  }

  // Calcule le stock disponible pour une unité donnée
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

  // Obtient les stocks de toutes les unités pour un article et dépôt donnés
  Future<String> _getStocksToutesUnites(Article article, String depot) async {
    try {
      final stockDepart = await (_databaseService.database.select(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot))).getSingleOrNull();

      // Calculer le stock total en unité de base (U3)
      double stockTotalU3 = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockDepart?.stocksu1 ?? 0.0,
        stockU2: stockDepart?.stocksu2 ?? 0.0,
        stockU3: stockDepart?.stocksu3 ?? 0.0,
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
      return '';
    }
  }

  Future<void> _gererStockInsuffisant(Article article, String depotActuel) async {
    // Vérifier les stocks dans les autres dépôts
    await _verifierStocksAutresDepots(article, depotActuel);

    // Ne plus afficher le modal automatiquement pour ne pas perturber la navigation
    // L'utilisateur peut maintenant ajouter directement l'article même avec stock insuffisant
  }

  Future<List<Map<String, dynamic>>> _verifierStocksAutresDepots(Article article, String depotActuel) async {
    final autresStocks = <Map<String, dynamic>>[];

    try {
      final tousStocksDepart = await (_databaseService.database.select(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(article.designation) & d.depots.isNotValue(depotActuel))).get();

      for (var stock in tousStocksDepart) {
        // Convertir les stocks en format optimal AVANT les calculs
        final stocksOptimaux = StockConverter.convertirStockOptimal(
          article: article,
          quantiteU1: stock.stocksu1 ?? 0.0,
          quantiteU2: stock.stocksu2 ?? 0.0,
          quantiteU3: stock.stocksu3 ?? 0.0,
        );

        double stockTotalU3 = _calculerStockTotalEnU3(
          article,
          stocksOptimaux['u1']!,
          stocksOptimaux['u2']!,
          stocksOptimaux['u3']!,
        );

        if (stockTotalU3 > 0) {
          double stockPourUnite = _calculerStockPourUnite(
            article,
            _selectedUnite ?? (article.u1 ?? ''),
            stockTotalU3,
          );
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

  Future<void> _loadDefaultDepot() async {
    if (!widget.tousDepots) {
      // Pour vente MAG seulement, forcer le dépôt MAG
      setState(() {
        _defaultDepot = 'MAG';
        _selectedDepot = 'MAG';
        _depotController.text = 'MAG';
      });
      return;
    }

    try {
      final derniereVente =
          await (_databaseService.database.select(_databaseService.database.detventes)
                ..orderBy([(d) => drift.OrderingTerm.desc(d.daty)])
                ..limit(1))
              .getSingleOrNull();

      setState(() {
        _defaultDepot = derniereVente?.depots ?? 'MAG';
        _selectedDepot = _defaultDepot;
        _depotController.text = _defaultDepot;
      });
    } catch (e) {
      setState(() {
        _defaultDepot = 'MAG';
        _selectedDepot = 'MAG';
        _depotController.text = 'MAG';
      });
    }
  }

  Future<bool> _verifierStockPourValidation() async {
    if (!_isExistingPurchase || _numVentesController.text.isEmpty) return false;

    try {
      final details = await (_databaseService.database.select(
        _databaseService.database.detventes,
      )..where((d) => d.numventes.equals(_numVentesController.text))).get();

      for (var detail in details) {
        if (detail.designation != null && detail.depots != null && detail.q != null) {
          // Trouver l'article correspondant
          final article = _articles.where((a) => a.designation == detail.designation).firstOrNull;
          if (article == null) continue;

          // Vérifier le stock actuel
          final stockDepart =
              await (_databaseService.database.select(_databaseService.database.depart)..where(
                    (d) => d.designation.equals(detail.designation!) & d.depots.equals(detail.depots!),
                  ))
                  .getSingleOrNull();

          if (stockDepart != null) {
            // Calculer le stock total disponible
            double stockTotalU3 = StockConverter.calculerStockTotalU3(
              article: article,
              stockU1: stockDepart.stocksu1 ?? 0.0,
              stockU2: stockDepart.stocksu2 ?? 0.0,
              stockU3: stockDepart.stocksu3 ?? 0.0,
            );

            // Calculer le stock pour l'unité de vente
            double stockPourUnite = _calculerStockPourUnite(article, detail.unites ?? '', stockTotalU3);

            // Si la quantité vendue dépasse le stock disponible
            if (detail.q! > stockPourUnite) {
              // Pour MAG uniquement: considérer comme problématique
              if (!widget.tousDepots) {
                return true; // Stock insuffisant détecté pour MAG
              }
              // Pour tous dépôts: autoriser même avec stock insuffisant
            }
          }
        }
      }

      return false; // Tous les stocks sont suffisants ou autorisés
    } catch (e) {
      return !widget.tousDepots; // En cas d'erreur, bloquer seulement pour MAG
    }
  }

  Future<void> _importerLignesVente() async {
    // Empêcher l'accès aux vendeurs
    if (_isVendeur()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accès refusé: Les vendeurs ne peuvent pas importer des lignes de vente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final choix = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer lignes de vente'),
        content: const Text('Choisissez la source d\'importation :'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('base_actuelle'),
            child: const Text('Base actuelle'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('base_externe'),
            child: const Text('Base externe'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ],
      ),
    );

    if (choix == 'base_actuelle') {
      await _importerDepuisBaseActuelle();
    } else if (choix == 'base_externe') {
      await _importerDepuisBaseExterne();
    }
  }

  Future<void> _importerDepuisBaseActuelle() async {
    // Récupérer toutes les ventes avec leurs détails
    final ventesAvecDetails = <Map<String, dynamic>>[];

    // Utiliser le Future existant pour récupérer les ventes
    final ventes = await _getVentesAvecStatut();

    for (final vente in ventes) {
      final details = await (_databaseService.database.select(
        _databaseService.database.detventes,
      )..where((d) => d.numventes.equals(vente['numventes']))).get();

      if (details.isNotEmpty) {
        ventesAvecDetails.add({
          'numVente': vente['numventes'],
          'statut': vente['verification'] ?? 'JOURNAL',
          'nbLignes': details.length,
          'nfact': vente['nfact'] ?? '',
        });
      }
    }

    if (ventesAvecDetails.isEmpty && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune vente avec des lignes trouvée')));
      return;
    }

    // Afficher la liste des ventes pour sélection
    final selectedVente = mounted
        ? await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sélectionner une vente'),
              content: SizedBox(
                width: 300,
                height: 400,
                child: ListView.builder(
                  itemCount: ventesAvecDetails.length,
                  itemBuilder: (context, index) {
                    final vente = ventesAvecDetails[index];
                    return ListTile(
                      title: Text('N° ${vente['numVente']}'),
                      subtitle: Text('${vente['nbLignes']} lignes - ${vente['statut']} - ${vente['nfact']}'),
                      onTap: () => Navigator.of(context).pop(vente['numVente']),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
              ],
            ),
          )
        : null;

    if (selectedVente != null) {
      await _copierLignesVente(selectedVente);
    }
  }

  Future<void> _copierLignesVente(String numVenteSource) async {
    try {
      final details = await (_databaseService.database.select(
        _databaseService.database.detventes,
      )..where((d) => d.numventes.equals(numVenteSource))).get();

      if (details.isEmpty && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Aucune ligne trouvée pour cette vente')));
        return;
      }

      // Vérifier si des articles existent encore
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
            'diffPrix': (detail.diffPrix ?? 0.0) / (detail.q ?? 1.0), // Différence unitaire
          });
        }
      }

      if (lignesValides.isEmpty && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Aucun article de cette vente n\'existe plus')));
        return;
      }

      // Confirmation avant importation
      final confirm = mounted
          ? await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmation'),
                content: Text(
                  'Importer ${lignesValides.length} lignes de la vente N° $numVenteSource ?\n\nCela remplacera les lignes actuelles.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Importer')),
                ],
              ),
            )
          : null;

      if (confirm == true) {
        setState(() {
          _lignesVente.clear();
          _lignesVente.addAll(lignesValides);
        });
        _calculerTotaux();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${lignesValides.length} lignes importées avec succès')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'importation: $e')));
      }
    }
  }

  Future<void> _importerDepuisBaseExterne() async {
    try {
      // Sélectionner le fichier de base de données
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
        dialogTitle: 'Sélectionner une base de données',
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Erreur: Chemin de fichier invalide')));
        }
        return;
      }

      // Ouvrir la base externe
      final externalDbService = DatabaseService.fromPath(filePath);
      await externalDbService.initialize();

      // Récupérer les ventes de la base externe
      final ventesExternes = await externalDbService.database.select(externalDbService.database.ventes).get();

      if (ventesExternes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Aucune vente trouvée dans la base externe')));
        }
        return;
      }

      // Afficher la liste des ventes pour sélection
      final selectedVente = mounted
          ? await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sélectionner une vente'),
                content: SizedBox(
                  width: 300,
                  height: 400,
                  child: ListView.builder(
                    itemCount: ventesExternes.length,
                    itemBuilder: (context, index) {
                      final vente = ventesExternes[index];
                      return ListTile(
                        title: Text('N° ${vente.numventes ?? "Sans numéro"}'),
                        subtitle: Text('${vente.clt ?? ""} - ${vente.nfact ?? ""}'),
                        onTap: () => Navigator.of(context).pop(vente.numventes),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
                ],
              ),
            )
          : null;

      if (selectedVente != null) {
        await _copierLignesVenteExterne(externalDbService, selectedVente);
      }

      // Fermer la base externe
      await externalDbService.database.close();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'importation: $e')));
      }
    }
  }

  Future<void> _copierLignesVenteExterne(DatabaseService externalDb, String numVenteSource) async {
    try {
      final details = await (externalDb.database.select(
        externalDb.database.detventes,
      )..where((d) => d.numventes.equals(numVenteSource))).get();

      if (details.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Aucune ligne trouvée pour cette vente')));
        }
        return;
      }

      // Vérifier si des articles existent dans la base actuelle
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
            'diffPrix': (detail.diffPrix ?? 0.0) / (detail.q ?? 1.0), // Différence unitaire
          });
        }
      }

      if (lignesValides.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun article de cette vente n\'existe dans la base actuelle')),
          );
        }
        return;
      }

      // Confirmation avant importation
      final confirm = mounted
          ? await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmation'),
                content: Text(
                  'Importer ${lignesValides.length} lignes de la vente N° $numVenteSource ?\n\nCela remplacera les lignes actuelles.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Importer')),
                ],
              ),
            )
          : null;

      if (confirm == true) {
        setState(() {
          _lignesVente.clear();
          _lignesVente.addAll(lignesValides);
        });
        _calculerTotaux();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${lignesValides.length} lignes importées avec succès')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'importation: $e')));
      }
    }
  }

  void _validerQuantite(String value) async {
    if (!_isClientSelected || _selectedArticle == null) return;

    double quantite = double.tryParse(value) ?? 0.0;

    // Si stock insuffisant, afficher modal d'avertissement
    if (quantite > _stockDisponible) {
      // Pour les vendeurs, empêcher complètement la vente avec stock insuffisant
      if (_isVendeur()) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Stock insuffisant'),
            content: Text(
              'Impossible de vendre ${quantite.toStringAsFixed(0)} ${_selectedUnite ?? ''} de "${_selectedArticle!.designation}".\n\n'
              'Stock disponible: ${_stockDisponible.toStringAsFixed(0)} ${_selectedUnite ?? ''}.\n\n'
              'Les vendeurs ne peuvent pas vendre avec un stock insuffisant.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                autofocus: true,
                child: const Text('OK'),
              ),
            ],
          ),
        );
        // Remettre la quantité à la valeur du stock disponible
        _quantiteController.text = _stockDisponible > 0 ? _stockDisponible.toStringAsFixed(0) : '';
        return;
      }

      // Pour les autres utilisateurs, permettre avec confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stock insuffisant'),
          content: Text(
            'Attention: Vous allez vendre ${quantite.toStringAsFixed(0)} ${_selectedUnite ?? ''} de "${_selectedArticle!.designation}" '
            'mais le stock disponible est de ${_stockDisponible.toStringAsFixed(0)} ${_selectedUnite ?? ''}.\n\n'
            'Voulez-vous continuer ?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              autofocus: true,
              child: const Text('Continuer'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        // Remettre la quantité à la valeur du stock disponible
        _quantiteController.text = _stockDisponible > 0 ? _stockDisponible.toStringAsFixed(0) : '';
        return;
      }

      // Forcer le mode brouillard
      setState(() {
        _statutVente = StatutVente.brouillard;
      });
    }

    _calculerMontant();
    setState(() {}); // Trigger rebuild to show/hide add button
  }

  bool _isQuantiteInsuffisante() {
    if (_selectedArticle == null) return false;
    double quantite = double.tryParse(_quantiteController.text) ?? 0.0;
    return quantite > _stockDisponible;
  }

  String _formaterUniteAffichage(Article article) {
    final unites = <String>[];
    if (article.u1?.isNotEmpty == true) unites.add(article.u1!);
    if (article.u2?.isNotEmpty == true) unites.add(article.u2!);
    if (article.u3?.isNotEmpty == true) unites.add(article.u3!);
    return unites.join(' / ');
  }

  Article? _getLastAddedArticle() {
    if (_lignesVente.isEmpty) return null;
    final lastDesignation = _lignesVente.last['designation'] as String?;
    if (lastDesignation == null) return null;
    return _articles.where((a) => a.designation == lastDesignation).firstOrNull;
  }

  String _calculateRemiseAmount() {
    double totalTTC = double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0;
    double remise = double.tryParse(_remiseController.text) ?? 0;
    double remiseAmount = totalTTC * remise / 100;
    return AppFunctions.formatNumber(remiseAmount);
  }

  double _calculateTotalDiffPrix() {
    double total = 0.0;
    for (var ligne in _lignesVente) {
      total += (ligne['diffPrix'] ?? 0.0) * (ligne['quantite'] ?? 0.0);
    }
    return total;
  }

  Future<double> _getPrixVenteStandard(Article article, String unite) async {
    // Retourner le prix selon l'unité
    if (unite == article.u1) {
      return article.pvu1 ?? 0.0;
    } else if (unite == article.u2) {
      return article.pvu2 ?? 0.0;
    } else if (unite == article.u3) {
      return article.pvu3 ?? 0.0;
    }
    return 0.0;
  }

  void _calculerMontant() {
    double quantite = double.tryParse(_quantiteController.text) ?? 0.0;
    double prix = double.tryParse(_prixController.text.replaceAll(' ', '')) ?? 0.0;
    double montant = quantite * prix;
    _montantController.text = montant > 0 ? AppFunctions.formatNumber(montant) : '';
  }

  void _calculerTotaux() {
    double totalHT = 0;
    for (var ligne in _lignesVente) {
      totalHT += ligne['montant'] ?? 0;
    }

    double remise = double.tryParse(_remiseController.text) ?? 0;
    double totalTTC = totalHT - (totalHT * remise / 100);
    double avance = double.tryParse(_avanceController.text) ?? 0;
    double reste = totalTTC - avance;

    double nouveauSolde = _soldeAnterieur;
    if (_selectedModePaiement == 'A crédit') {
      nouveauSolde += reste;
    }

    setState(() {
      _totalTTCController.text = AppFunctions.formatNumber(totalTTC);
      _resteController.text = AppFunctions.formatNumber(reste);
      _nouveauSoldeController.text = AppFunctions.formatNumber(nouveauSolde);
    });
  }

  Future<bool> _verifierPrixVente(double prixVente, double prixAchat, String unite) async {
    if (prixVente == 0) {
      // Prix = 0 : Modal cadeau
      final continuer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Vente gratuite'),
          content: const Text(
            'Le prix de vente est de 0 Ar.\n\nVoulez-vous offrir cet article comme cadeau ?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              autofocus: true,
              child: const Text('Cadeau'),
            ),
          ],
        ),
      );
      return continuer ?? false;
    } else if (prixVente < prixAchat) {
      // Prix de vente < Prix d'achat : Modal confirmation
      final continuer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Prix de vente inférieur au coût'),
          content: Text(
            'Prix de vente: ${AppFunctions.formatNumber(prixVente)} Ar/$unite\n'
            'Prix d\'achat (CMUP): ${AppFunctions.formatNumber(prixAchat)} Ar/$unite\n\n'
            'Le prix de vente est inférieur au prix d\'achat.\n\n'
            'Êtes-vous sûr de continuer cette opération ?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              autofocus: true,
              child: const Text('Continuer quand même'),
            ),
          ],
        ),
      );
      return continuer ?? false;
    }
    return true; // Prix normal, continuer
  }

  Future<double> _getPrixAchatPourUnite(Article article, String unite) async {
    double cmup = article.cmup ?? 0.0;
    if (cmup == 0.0) return 0.0;

    // Le CMUP est stocké en unité de base (u3), convertir vers l'unité demandée
    if (unite == article.u1 && article.tu2u1 != null && article.tu3u2 != null) {
      // Prix u1 = CMUP × (tu2u1 × tu3u2)
      return cmup * (article.tu2u1! * article.tu3u2!);
    } else if (unite == article.u2 && article.tu3u2 != null) {
      // Prix u2 = CMUP × tu3u2
      return cmup * article.tu3u2!;
    } else if (unite == article.u3) {
      // Prix u3 = CMUP directement
      return cmup;
    }
    return cmup; // Par défaut
  }

  void _ajouterLigne() async {
    if (_selectedArticle == null) return;

    double quantite = double.tryParse(_quantiteController.text) ?? 0.0;
    double prix = double.tryParse(_prixController.text.replaceAll(' ', '')) ?? 0.0;
    String unite = _selectedUnite ?? (_selectedArticle!.u1 ?? '');
    String depot = _selectedDepot ?? _defaultDepot;

    // Vérifier les prix avant de continuer
    final prixAchat = await _getPrixAchatPourUnite(_selectedArticle!, unite);
    final prixValide = await _verifierPrixVente(prix, prixAchat, unite);
    if (!prixValide) return;

    // Vérifier stock selon le type de dépôt
    if (quantite > _stockDisponible) {
      // Pour les vendeurs, empêcher complètement la vente avec stock insuffisant
      if (_isVendeur() && mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vente impossible'),
            content: Text(
              'Stock insuffisant pour "${_selectedArticle!.designation}".\n\n'
              'Stock disponible: ${_stockDisponible.toStringAsFixed(0)} $unite\n'
              'Quantité demandée: ${quantite.toStringAsFixed(0)} $unite\n\n'
              'Les vendeurs ne peuvent pas vendre avec un stock insuffisant.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                autofocus: true,
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Pour les autres utilisateurs, utiliser la logique existante
      final validation = await _venteService.verifierStockSelonDepot(
        designation: _selectedArticle!.designation,
        depot: depot,
        unite: unite,
        quantite: quantite,
        tousDepots: widget.tousDepots,
      );

      if (!validation['autorise'] && mounted) {
        if (validation['typeDialog'] == 'confirmation') {
          // Tous dépôts: dialog de confirmation
          final continuer = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Stock insuffisant'),
              content: Text(
                'Stock disponible: ${_stockDisponible.toStringAsFixed(0)} $unite\nQuantité demandée: ${quantite.toStringAsFixed(0)} $unite\n\nVoulez-vous continuer quand même ?',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  autofocus: true,
                  child: const Text('Continuer quand même'),
                ),
              ],
            ),
          );
          if (continuer != true) return;
        } else if (validation['typeDialog'] == 'restriction') {
          // MAG uniquement: dialog de restriction
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vente impossible'),
              content: Text(
                'Stock insuffisant dans le dépôt MAG\n\nStock disponible: ${_stockDisponible.toStringAsFixed(0)} $unite\nQuantité demandée: ${quantite.toStringAsFixed(0)} $unite\n\nLa vente avec stock insuffisant n\'est autorisée que pour "Tous dépôts".',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  autofocus: true,
                  child: const Text('Annuler'),
                ),
              ],
            ),
          );
          return;
        }
      }
    }

    double montant = quantite * prix;

    // Si stock insuffisant, forcer le mode brouillard
    if (quantite > _stockDisponible) {
      setState(() {
        _statutVente = StatutVente.brouillard;
      });
    }

    // Calculer la différence de prix
    final prixVenteStandard = await _getPrixVenteStandard(_selectedArticle!, unite);
    final diffPrix = prix - prixVenteStandard;

    // Sauvegarder le dépôt utilisé comme nouveau défaut
    _defaultDepot = depot;

    setState(() {
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
    });

    _calculerTotaux();

    // Sauvegarder automatiquement si c'est une vente brouillard existante
    if (_isExistingPurchase && _isVenteBrouillard()) {
      await _sauvegarderModificationsBrouillard();
    }

    _resetArticleForm();
  }

  Future<void> _chargerLigneArticle(int index) async {
    debugPrint('=== DÉBUT _chargerLigneArticle - Index: $index ===');

    // Ajuster l'index si on restaure une ligne précédente
    int adjustedIndex = index;

    // Si on est déjà en train de modifier une ligne, la restaurer d'abord
    if (_isModifyingLine && _modifyingLineIndex != null && originalLineData != null) {
      debugPrint('Restauration ligne précédente - Index: $_modifyingLineIndex');
      setState(() {
        _lignesVente.insert(_modifyingLineIndex!, Map<String, dynamic>.from(originalLineData!));
      });
      _calculerTotaux();

      // Ajuster l'index si la ligne restaurée est avant la ligne à modifier
      if (_modifyingLineIndex! <= index) {
        adjustedIndex = index + 1;
        debugPrint('Index ajusté: $adjustedIndex');
      }
    }

    final ligne = _lignesVente[adjustedIndex];
    debugPrint('Ligne à modifier: $ligne');

    // Trouver l'article correspondant
    Article? article;
    try {
      article = _articles.firstWhere((a) => a.designation == ligne['designation']);
    } catch (e) {
      if (_articles.isNotEmpty) {
        article = _articles.first;
      } else {
        return;
      }
    }

    // Sauvegarder les données originales AVANT toute modification
    final originalData = Map<String, dynamic>.from(ligne);

    // Sauvegarder la quantité originale pour la préserver
    final quantiteOriginale = ligne['quantite'].toString();
    debugPrint('Quantité originale: $quantiteOriginale');

    setState(() {
      _selectedArticle = article;
      _selectedUnite = ligne['unites'];
      _selectedDepot = ligne['depot'];
      _isModifyingLine = true;
      _modifyingLineIndex = adjustedIndex;
      originalLineData = originalData;
      _uniteAffichage = _formaterUniteAffichage(article!);
    });
    debugPrint('setState terminé - Variables mises à jour');

    // Remplir les contrôleurs IMMÉDIATEMENT après setState
    _depotController.text = ligne['depot'];
    _uniteController.text = ligne['unites'];
    _quantiteController.text = quantiteOriginale;
    _prixController.text = AppFunctions.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0);
    debugPrint('Contrôleurs remplis - Quantité: ${_quantiteController.text}');

    // Vérifier le stock APRES avoir rempli les contrôleurs
    debugPrint('AVANT _verifierStockEtBasculer - Quantité: ${_quantiteController.text}');
    await _verifierStockEtBasculer(article);
    debugPrint('APRÈS _verifierStockEtBasculer - Quantité: ${_quantiteController.text}');

    // CRITIQUE: Toujours restaurer la quantité originale après la vérification du stock
    // car la vérification peut vider le champ quantité
    _quantiteController.text = quantiteOriginale;
    debugPrint('Quantité restaurée: ${_quantiteController.text}');

    // Supprimer la ligne après un délai
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _isModifyingLine && _modifyingLineIndex == adjustedIndex) {
        debugPrint('Suppression ligne - Index: $adjustedIndex, Quantité avant: ${_quantiteController.text}');
        setState(() {
          _lignesVente.removeAt(adjustedIndex);
        });
        _calculerTotaux();
        debugPrint('Ligne supprimée - Quantité après: ${_quantiteController.text}');
      }
    });

    // Focus sur le champ quantité pour modification rapide
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        debugPrint('Focus sur quantité - Valeur actuelle: ${_quantiteController.text}');
        _quantiteFocusNode.requestFocus();
      }
    });

    debugPrint('=== FIN _chargerLigneArticle ===');
  }

  Future<void> _chargerSoldeClient(String? client) async {
    if (client == null || client.isEmpty) {
      setState(() {
        _soldeAnterieur = 0.0;
        _soldeAnterieurController.text = '0';
      });
      return;
    }

    try {
      double solde = await _databaseService.database.calculerSoldeClient(client);

      // Si on charge une vente existante, exclure cette vente du solde
      if (_isExistingPurchase && _numVentesController.text.isNotEmpty) {
        final venteActuelle = await (_databaseService.database.select(
          _databaseService.database.ventes,
        )..where((v) => v.numventes.equals(_numVentesController.text))).getSingleOrNull();

        if (venteActuelle != null && venteActuelle.modepai == 'A crédit') {
          double montantVenteActuelle = (venteActuelle.totalttc ?? 0) - (venteActuelle.avance ?? 0);
          solde -= montantVenteActuelle; // Exclure cette vente du solde antérieur
        }
      }

      setState(() {
        _soldeAnterieur = solde;
        _soldeAnterieurController.text = AppFunctions.formatNumber(solde);
      });
      _calculerTotaux();
    } catch (e) {
      setState(() {
        _soldeAnterieur = 0.0;
        _soldeAnterieurController.text = '0';
      });
    }
  }

  void _resetArticleForm() {
    setState(() {
      _selectedArticle = null;
      _selectedUnite = null;
      _selectedDepot = _defaultDepot; // Conserver le dernier dépôt utilisé
      if (_autocompleteController != null) {
        _autocompleteController!.clear();
      }
      _quantiteController.clear();
      _prixController.clear();
      _montantController.clear();
      _depotController.text = _defaultDepot; // Remplir avec le dernier dépôt utilisé
      _uniteController.clear(); // Vider le champ unité
      _stockDisponible = 0.0;
      _stockInsuffisant = false;
      _uniteAffichage = '';
      _isModifyingLine = false;
      _modifyingLineIndex = null;
      originalLineData = null;
    });

    // Retourner le focus au champ désignation pour une nouvelle saisie
    Future.delayed(const Duration(milliseconds: 100), () {
      _designationFocusNode.requestFocus();
      // Maintenir les raccourcis globaux actifs
      _ensureGlobalShortcutsFocus();
    });
  }

  void _annulerModificationLigne() {
    if (_isModifyingLine && _modifyingLineIndex != null && originalLineData != null) {
      // Restaurer la ligne originale avec les données sauvegardées
      setState(() {
        _lignesVente.insert(_modifyingLineIndex!, Map<String, dynamic>.from(originalLineData!));
      });

      _calculerTotaux();
    }

    _resetArticleForm();
  }

  void _supprimerLigne(int index) async {
    setState(() {
      _lignesVente.removeAt(index);
    });
    _calculerTotaux();

    // Sauvegarder automatiquement si c'est une vente brouillard existante
    if (_isExistingPurchase && _isVenteBrouillard()) {
      await _sauvegarderModificationsBrouillard();
    }
  }

  bool _shouldShowAddButton() {
    if (_isModifyingLine) {
      // En mode modification, afficher les boutons si on a un article sélectionné
      return _isClientSelected && _selectedArticle != null;
    }
    // En mode normal, vérifier tous les champs
    return _isClientSelected && _selectedArticle != null && _quantiteController.text.isNotEmpty;
  }

  void _showContextMenu(BuildContext context, TapDownDetails details, int index) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx + 1,
        details.globalPosition.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'modifier',
          child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Modifier')]),
        ),
        const PopupMenuItem(
          value: 'supprimer',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'modifier') {
        _chargerLigneArticle(index);
      } else if (value == 'supprimer') {
        _supprimerLigne(index);
      }
    });
  }

  Future<void> _validerVente() async {
    if (_lignesVente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun article ajouté')));
      return;
    }

    // Vérifier les stocks avant validation selon le type de dépôt
    if (_selectedVerification == 'JOURNAL') {
      for (final ligne in _lignesVente) {
        final stockDisponible = await _venteService.verifierDisponibiliteStock(
          designation: ligne['designation'],
          depot: ligne['depot'],
          unite: ligne['unites'],
          quantite: ligne['quantite'],
        );

        if (!stockDisponible && !widget.tousDepots) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Stock insuffisant pour certains articles'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    }

    if (mounted) {
      // Afficher le modal de confirmation
      final confirmer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la validation'),
          content: Text(
            'Êtes-vous sûr de vouloir valider cette vente?\n\nN° Vente: ${_numVentesController.text}\nClient: ${_selectedClient ?? "Aucun"}\nTotal TTC: ${_totalTTCController.text}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );

      if (confirmer != true) return;
    }

    try {
      // Préparer les données de la vente
      final currentUser = AuthService().currentUser;
      final commercialName = currentUser?.nom ?? '';

      final lignesVenteData = _lignesVente
          .map(
            (ligne) => {
              'designation': ligne['designation'],
              'unite': ligne['unites'],
              'depot': ligne['depot'],
              'quantite': ligne['quantite'],
              'prixUnitaire': ligne['prixUnitaire'],
              'diffPrix': ligne['diffPrix'],
            },
          )
          .toList();

      // Traiter la vente avec le service selon le mode
      if (_selectedVerification == 'BROUILLARD') {
        await _venteService.enregistrerVenteBrouillard(
          numVentes: _numVentesController.text,
          nFacture: _nFactureController.text.isEmpty ? null : _nFactureController.text,
          date: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
          client: _selectedClient,
          modePaiement: _selectedModePaiement,
          totalTTC: double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0,
          avance: double.tryParse(_avanceController.text) ?? 0,
          commercial: commercialName,
          remise: double.tryParse(_remiseController.text) ?? 0,
          lignesVente: lignesVenteData,
          heure: _heureController.text,
        );
      } else {
        await _venteService.enregistrerVenteDirecteJournal(
          numVentes: _numVentesController.text,
          nFacture: _nFactureController.text.isEmpty ? null : _nFactureController.text,
          date: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
          client: _selectedClient,
          modePaiement: _selectedModePaiement,
          totalTTC: double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0,
          avance: double.tryParse(_avanceController.text) ?? 0,
          commercial: commercialName,
          remise: double.tryParse(_remiseController.text) ?? 0,
          lignesVente: lignesVenteData,
          heure: _heureController.text,
        );
      }

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            behavior: SnackBarBehavior.floating,
            content: const Text('Vente enregistrée en brouillon'),
            backgroundColor: Colors.green,
          ),
        );

        // RELEVANT: Recharger la liste des ventes immédiatement
        _reloadVentesList();

        // Réinitialiser le formulaire
        _reinitialiserFormulaire();

        // Réactiver les raccourcis globaux
        _ensureGlobalShortcutsFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la validation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _reinitialiserFormulaire() {
    setState(() {
      _isExistingPurchase = false;
      _selectedRowIndex = null;
      _lignesVente.clear();
      _clientController.clear();
      _selectedClient = null;
      _statutVenteActuelle = null;
      _selectedVerification = 'BROUILLARD';
      _statutVente = StatutVente.brouillard;
      _showCreditMode = _shouldShowCreditMode(null);
      if (_autocompleteController != null) {
        _autocompleteController!.clear();
      }
    });

    _remiseController.text = '0';
    _totalTTCController.text = '0';
    _avanceController.text = '0';
    _resteController.text = '0';
    _nouveauSoldeController.text = '0';

    _resetArticleForm();
    _initializeForm();
    _chargerSoldeClient(null);
  }

  Future<void> _modifierVente() async {
    if (_selectedClient == null || _lignesVente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client et ajouter des articles')),
      );
      return;
    }

    if (!_isExistingPurchase || _numVentesController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune vente sélectionnée pour modification')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment modifier la vente Brouillard N° ${_numVentesController.text} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      double totalHT = 0;
      for (var ligne in _lignesVente) {
        totalHT += ligne['montant'] ?? 0;
      }

      double remise = double.tryParse(_remiseController.text) ?? 0;

      double totalTTC = totalHT - (totalHT * remise / 100);
      double avance = double.tryParse(_avanceController.text) ?? 0;

      await _databaseService.database.transaction(() async {
        // Supprimer toutes les anciennes lignes
        await (_databaseService.database.delete(
          _databaseService.database.detventes,
        )..where((d) => d.numventes.equals(_numVentesController.text))).go();

        // Mettre à jour la vente principale
        await (_databaseService.database.update(
          _databaseService.database.ventes,
        )..where((v) => v.numventes.equals(_numVentesController.text))).write(
          VentesCompanion(
            nfact: drift.Value(_nFactureController.text),
            daty: drift.Value(DateTime.now()),
            clt: drift.Value(_selectedClient ?? ''),
            modepai: drift.Value(_selectedModePaiement ?? 'A crédit'),
            totalttc: drift.Value(totalTTC),
            avance: drift.Value(avance),
            remise: drift.Value(remise),
            heure: drift.Value(_heureController.text),
          ),
        );

        // Insérer les nouvelles lignes
        for (var ligne in _lignesVente) {
          await _databaseService.database
              .into(_databaseService.database.detventes)
              .insert(
                DetventesCompanion.insert(
                  numventes: drift.Value(_numVentesController.text),
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

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            content: const Text('Vente brouillard modifiée avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // RELEVANT: Recharger la liste des ventes immédiatement
        _reloadVentesList();

        // Réactiver les raccourcis globaux
        _ensureGlobalShortcutsFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _creerNouvelleVente() async {
    // Recharger la liste des ventes pour s'assurer qu'elle est à jour
    _reloadVentesList();

    setState(() {
      _isExistingPurchase = false;
      _selectedRowIndex = null;
      _lignesVente.clear();
      _clientController.clear();
      _selectedClient = null;
      _statutVenteActuelle = null;
      _selectedVerification = 'BROUILLARD';
      _statutVente = StatutVente.brouillard;
      _showCreditMode = _shouldShowCreditMode(null);
      if (_autocompleteController != null) {
        _autocompleteController!.clear();
      }
    });

    _remiseController.text = '0';
    _totalTTCController.text = '0';
    _avanceController.text = '0';
    _resteController.text = '0';
    _nouveauSoldeController.text = '0';

    _resetArticleForm();
    _initializeForm();
    _chargerSoldeClient(null);
  }

  Future<void> _contrePasserVente() async {
    if (!_isExistingPurchase) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune vente sélectionnée à contre-passer')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(
          'Voulez-vous vraiment contre-passer la vente N° ${_numVentesController.text} ?\n\nLes stocks seront restaurés et les comptes ajustés.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _venteService.contrePasserVente(_numVentesController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente contre-passée avec succès'), backgroundColor: Colors.green),
        );

        // RELEVANT: Recharger la liste des ventes immédiatement
        _reloadVentesList();

        await _chargerVenteExistante(_numVentesController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _contrePasserVenteBrouillard() async {
    if (!_isExistingPurchase || !_isVenteBrouillard()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune vente brouillard sélectionnée')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contre-passer vente brouillard'),
        content: Text(
          'Voulez-vous vraiment contre-passer la vente brouillard N° ${_numVentesController.text} ?\n\n'
          'Cette action va :\n'
          '• Ajuster les stocks (restauration)\n'
          '• Supprimer définitivement la vente\n'
          '• Les comptes clients seront ajustés (vente brouillard non comptabilisée)',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _venteService.contrePasserVenteBrouillard(_numVentesController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vente brouillard supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger la liste des ventes
        _reloadVentesList();

        // Créer une nouvelle vente
        _creerNouvelleVente();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _apercuFacture() async {
    if (_lignesVente.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucun article à afficher dans la facture')));
      return;
    }

    try {
      final societe = await (_databaseService.database.select(
        _databaseService.database.soc,
      )).getSingleOrNull();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => FacturePreview(
            numVente: _numVentesController.text,
            nFacture: _nFactureController.text,
            date: _dateController.text,
            client: _selectedClient ?? '',
            lignesVente: _lignesVente,
            remise: double.tryParse(_remiseController.text) ?? 0,
            totalTTC: double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0,
            format: _selectedFormat,
            societe: societe,
            modePaiement: _selectedModePaiement ?? 'A crédit',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ouverture de l\'aperçu: $e')));
      }
    }
  }

  Future<void> _imprimerFacture() async {
    if (_lignesVente.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.8,
            right: 20,
            left: MediaQuery.of(context).size.width * 0.75,
          ),
          content: const Text('Aucun article à imprimer'),
        ),
      );
      return;
    }

    try {
      final societe = await (_databaseService.database.select(
        _databaseService.database.soc,
      )).getSingleOrNull();
      final pdf = await _generateFacturePdf(societe);
      final bytes = await pdf.save();

      // Obtenir la liste des imprimantes et trouver celle par défaut
      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;

      if (defaultPrinter != null) {
        await Printing.directPrintPdf(
          printer: defaultPrinter,
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Facture_${_nFactureController.text}_${_dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      } else {
        // Fallback vers la boîte de dialogue si aucune imprimante par défaut
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Facture_${_nFactureController.text}_${_dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      }

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            content: const Text('Facture envoyée à l\'imprimante par défaut'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            content: Text('Erreur d\'impression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfTotalRow(String label, String value, double fontSize, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize - 1,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize - 1,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _generateFacturePdf(SocData? societe) async {
    final pdf = pw.Document();
    final pdfFontSize = _selectedFormat == 'A6' ? 9.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);
    final pdfHeaderFontSize = _selectedFormat == 'A6' ? 8.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);
    final pdfPadding = _selectedFormat == 'A6' ? 8.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);
    final pageFormat = _selectedFormat == 'A4'
        ? PdfPageFormat.a4
        : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(3),
        build: (context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(pdfPadding),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(vertical: pdfPadding / 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 2),
                        bottom: pw.BorderSide(color: PdfColors.black, width: 2),
                      ),
                    ),
                    child: pw.Text(
                      'FACTURE',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfHeaderFontSize + 2),
                    ),
                  ),
                ),
                pw.SizedBox(height: pdfPadding),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  padding: pw.EdgeInsets.all(pdfPadding / 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SOCIÉTÉ:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfFontSize - 1),
                            ),
                            pw.Text(
                              societe?.rsoc ?? 'SOCIÉTÉ',
                              style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                            if (societe?.adr != null)
                              pw.Text(societe!.adr!, style: pw.TextStyle(fontSize: pdfFontSize - 1)),
                            if (societe?.activites != null)
                              pw.Text(societe!.activites!, style: pw.TextStyle(fontSize: pdfFontSize - 1)),
                            if (societe?.adr != null)
                              pw.Text(societe!.adr!, style: pw.TextStyle(fontSize: pdfFontSize - 1)),
                            if (societe?.rcs != null)
                              pw.Text(
                                'RCS: ${societe!.rcs!}',
                                style: pw.TextStyle(fontSize: pdfFontSize - 2),
                              ),
                            if (societe?.nif != null)
                              pw.Text(
                                'NIF: ${societe!.nif!}',
                                style: pw.TextStyle(fontSize: pdfFontSize - 2),
                              ),
                            if (societe?.stat != null)
                              pw.Text(
                                'STAT: ${societe!.stat!}',
                                style: pw.TextStyle(fontSize: pdfFontSize - 2),
                              ),
                            if (societe?.cif != null)
                              pw.Text(
                                'CIF: ${societe!.cif!}',
                                style: pw.TextStyle(fontSize: pdfFontSize - 2),
                              ),
                            if (societe?.email != null)
                              pw.Text(
                                'Email: ${societe!.email!}',
                                style: pw.TextStyle(fontSize: pdfFontSize - 2),
                              ),
                            if (societe?.port != null)
                              pw.Text(
                                'Tél: ${societe!.port!}',
                                style: pw.TextStyle(fontSize: pdfFontSize - 2),
                              ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'N° FACTURE: ${_nFactureController.text}',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'DATE: ${_dateController.text}',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'CLIENT: ${_selectedClient ?? ""}',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'MODE DE PAIEMENT: ${_selectedModePaiement ?? ""}',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: pdfPadding),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  child: pw.Table(
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                      verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              'DÉSIGNATION',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              'QTÉ',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              'PU HT',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              'MONTANT',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      ..._lignesVente.map(
                        (ligne) => pw.TableRow(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                ligne['designation'] ?? '',
                                style: pw.TextStyle(fontSize: pdfFontSize - 1),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                AppFunctions.formatNumber(ligne['quantite']?.toDouble() ?? 0),
                                style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                AppFunctions.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                AppFunctions.formatNumber(ligne['montant']?.toDouble() ?? 0),
                                style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: pdfPadding),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  padding: pw.EdgeInsets.all(pdfPadding / 2),
                  child: pw.Row(
                    children: [
                      pw.Spacer(),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'TOTAL TTC: ${AppFunctions.formatNumber(double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0)}',
                            style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Totals section
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  padding: pw.EdgeInsets.all(pdfPadding / 2),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Spacer(),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              if ((double.tryParse(_remiseController.text) ?? 0) > 0)
                                _buildPdfTotalRow(
                                  'REMISE:',
                                  AppFunctions.formatNumber(
                                    double.tryParse(_remiseController.text.replaceAll(' ', '')) ?? 0,
                                  ),
                                  pdfFontSize,
                                ),
                              pw.Container(
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
                                ),
                                child: _buildPdfTotalRow(
                                  'TOTAL TTC:',
                                  AppFunctions.formatNumber(
                                    double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0,
                                  ),
                                  pdfFontSize,
                                  isBold: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: pdfPadding / 2),
                      pw.Container(
                        width: double.infinity,
                        padding: pw.EdgeInsets.all(pdfPadding / 2),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 0.5),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Arrêté à la somme de ${AppFunctions.numberToWords((double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0).round())} Ariary',
                          style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: pdfPadding * 2),

                // Signatures section
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  padding: pw.EdgeInsets.all(pdfPadding),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'CLIENT',
                              style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: pdfPadding * 2),
                            pw.Container(
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                            ),
                            pw.SizedBox(height: pdfPadding / 2),
                            pw.Text('Nom et signature', style: pw.TextStyle(fontSize: pdfFontSize - 2)),
                          ],
                        ),
                      ),
                      pw.Container(width: 1, height: 60, color: PdfColors.black),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'VENDEUR',
                              style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: pdfPadding * 2),
                            pw.Container(
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                            ),
                            pw.SizedBox(height: pdfPadding / 2),
                            pw.Text('Nom et signature', style: pw.TextStyle(fontSize: pdfFontSize - 2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  // Dans la méthode _generateFacturePdf, ajouter une méthode similaire pour le BL
  Future<pw.Document> _generateBLPdf(SocData? societe) async {
    final pdf = pw.Document();
    final pdfFontSize = _selectedFormat == 'A6' ? 9.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);
    final pdfHeaderFontSize = _selectedFormat == 'A6' ? 8.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);
    final pdfPadding = _selectedFormat == 'A6' ? 8.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);
    final pageFormat = _selectedFormat == 'A4'
        ? PdfPageFormat.a4
        : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(3),
        build: (context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(pdfPadding),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(vertical: pdfPadding / 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 2),
                        bottom: pw.BorderSide(color: PdfColors.black, width: 2),
                      ),
                    ),
                    child: pw.Text(
                      'BON DE LIVRAISON',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfHeaderFontSize + 2),
                    ),
                  ),
                ),
                pw.SizedBox(height: pdfPadding),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  padding: pw.EdgeInsets.all(pdfPadding / 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SOCIÉTÉ:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfFontSize - 1),
                            ),
                            pw.Text(
                              societe?.rsoc ?? 'SOCIÉTÉ',
                              style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                            if (societe?.adr != null)
                              pw.Text(societe!.adr!, style: pw.TextStyle(fontSize: pdfFontSize - 1)),
                            if (societe?.activites != null)
                              pw.Text(societe!.activites!, style: pw.TextStyle(fontSize: pdfFontSize - 1)),
                            if (societe?.port != null)
                              pw.Text(
                                'Tél: ${societe!.port!}',
                                style: pw.TextStyle(fontSize: pdfFontSize - 2),
                              ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'N° BL: ${_nFactureController.text}',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'DATE: ${_dateController.text}',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'CLIENT: ${_selectedClient ?? ""}',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: pdfPadding),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  child: pw.Table(
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                      verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              'DÉSIGNATION',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              'UNITÉ',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              'QUANTITÉ',
                              style: pw.TextStyle(fontSize: pdfFontSize - 1, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          if (widget.tousDepots)
                            pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                'DÉPÔT',
                                style: pw.TextStyle(
                                  fontSize: pdfFontSize - 1,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                      ..._lignesVente.map(
                        (ligne) => pw.TableRow(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                ligne['designation'] ?? '',
                                style: pw.TextStyle(fontSize: pdfFontSize - 1),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                ligne['unites'] ?? '',
                                style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                AppFunctions.formatNumber(ligne['quantite']?.toDouble() ?? 0),
                                style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            if (widget.tousDepots)
                              pw.Container(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text(
                                  ligne['depot'] ?? '',
                                  style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: pdfPadding * 2),
                // Signatures section
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  padding: pw.EdgeInsets.all(pdfPadding),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'CLIENT',
                              style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: pdfPadding * 2),
                            pw.Container(
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                            ),
                            pw.SizedBox(height: pdfPadding / 2),
                            pw.Text('Nom et signature', style: pw.TextStyle(fontSize: pdfFontSize - 2)),
                          ],
                        ),
                      ),
                      pw.Container(width: 1, height: 60, color: PdfColors.black),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'LIVREUR',
                              style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: pdfPadding * 2),
                            pw.Container(
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                            ),
                            pw.SizedBox(height: pdfPadding / 2),
                            pw.Text('Nom et signature', style: pw.TextStyle(fontSize: pdfFontSize - 2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  // Ajouter la méthode pour imprimer le BL
  Future<void> _imprimerBL() async {
    if (_lignesVente.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.8,
            right: 20,
            left: MediaQuery.of(context).size.width * 0.75,
          ),
          content: const Text('Aucun article à imprimer'),
        ),
      );
      return;
    }

    try {
      final societe = await (_databaseService.database.select(
        _databaseService.database.soc,
      )).getSingleOrNull();
      final pdf = await _generateBLPdf(societe);
      final bytes = await pdf.save();

      // Obtenir la liste des imprimantes et trouver celle par défaut
      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;

      if (defaultPrinter != null) {
        await Printing.directPrintPdf(
          printer: defaultPrinter,
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'BL_${_nFactureController.text}_${_dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      } else {
        // Fallback vers la boîte de dialogue si aucune imprimante par défaut
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'BL_${_nFactureController.text}_${_dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      }

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            content: const Text('Bon de livraison envoyé à l\'imprimante par défaut'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              right: 20,
              left: MediaQuery.of(context).size.width * 0.75,
            ),
            content: Text('Erreur d\'impression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _apercuBL() async {
    if (_lignesVente.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Aucun article à afficher dans le bon de livraison')));
      }
      return;
    }

    try {
      final societe = await (_databaseService.database.select(
        _databaseService.database.soc,
      )).getSingleOrNull();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => BonLivraisonPreview(
            numVente: _numVentesController.text,
            nFacture: _nFactureController.text,
            date: _dateController.text,
            client: _selectedClient ?? '',
            lignesVente: _lignesVente,
            remise: double.tryParse(_remiseController.text) ?? 0,
            totalTTC: double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0,
            format: _selectedFormat,
            societe: societe,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ouverture de l\'aperçu: $e')));
      }
    }
  }

  Future<void> _verifierEtCreerClient(String nomClient) async {
    if (nomClient.trim().isEmpty) return;

    // Vérifier si le client existe
    final clientExiste = _clients.any((client) => client.rsoc.toLowerCase() == nomClient.toLowerCase());

    if (!clientExiste) {
      // Afficher le modal de confirmation
      final confirmer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Client inconnu!!'),
          content: Text('Le client "$nomClient" n\'existe pas.\n\nVoulez-vous le créer?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Non')),
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Oui'),
            ),
          ],
        ),
      );

      if (confirmer == true) {
        // Créer directement le client avec le nom saisi
        try {
          await _databaseService.database
              .into(_databaseService.database.clt)
              .insert(
                CltCompanion.insert(
                  rsoc: nomClient,
                  categorie: drift.Value(
                    widget.tousDepots ? ClientCategory.tousDepots.label : ClientCategory.magasin.label,
                  ),
                  commercial: drift.Value(AuthService().currentUser?.nom ?? ''),
                  taux: const drift.Value(0),
                  soldes: const drift.Value(0),
                  soldesa: const drift.Value(0),
                  action: const drift.Value("A"),
                  plafon: const drift.Value(9000000000.0),
                  plafonbl: const drift.Value(9000000000.0),
                ),
              );

          // Recharger la liste des clients
          await _loadData();

          setState(() {
            _selectedClient = nomClient;
            _clientController.text = nomClient;
            _showCreditMode = widget.tousDepots;
            if ((!_showCreditMode || _isVendeur()) && _selectedModePaiement == 'A crédit') {
              _selectedModePaiement = 'Espèces';
            }
          });
          _chargerSoldeClient(nomClient);

          // Positionner le curseur selon le type d'utilisateur
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_shouldFocusOnClient()) {
              _clientFocusNode.requestFocus();
            } else {
              _designationFocusNode.requestFocus();
            }
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la création du client: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Réinitialiser le champ client
        setState(() {
          _selectedClient = null;
          _clientController.clear();
        });
      }
    } else {
      // Client existe, le sélectionner
      final client = _clients.firstWhere((client) => client.rsoc.toLowerCase() == nomClient.toLowerCase());
      setState(() {
        _selectedClient = client.rsoc;
        _clientController.text = client.rsoc;
        // Déterminer si on affiche le mode crédit selon la catégorie
        _showCreditMode = _shouldShowCreditMode(client);
        // Ajuster le mode de paiement si nécessaire
        if ((!_showCreditMode || _isVendeur()) && _selectedModePaiement == 'A crédit') {
          _selectedModePaiement = 'Espèces';
        }
      });
      _chargerSoldeClient(client.rsoc);
    }
  }

  Widget _buildVentesListByStatus(String statut) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ventesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}', style: const TextStyle(fontSize: 11, color: Colors.red)),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('Aucune donnée', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
            child: Text(message, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: filteredVentes.length,
          itemBuilder: (context, index) {
            final vente = filteredVentes[index];
            final numVente = vente['numventes'];
            final isSelected = numVente == _numVentesController.text;
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
                  _numVentesController.text = numVente;
                  _chargerVenteExistante(numVente);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriceRow(String? unite, double? prix) {
    if (unite == null || unite.isEmpty || prix == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: _selectedUnite == unite ? Colors.green[100] : Colors.grey[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _selectedUnite == unite ? Colors.green[300]! : Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '1 $unite:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: _selectedUnite == unite ? FontWeight.w500 : FontWeight.normal,
              color: _selectedUnite == unite ? Colors.green[700] : Colors.black87,
            ),
          ),
          Text(
            "${AppFunctions.formatNumber(prix)} Ar",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _selectedUnite == unite ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionRow(String? u1, String? u2, double? taux) {
    if (taux == null || taux == 0 || u1 == null || u1.isEmpty || u2 == null || u2.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('1 ($u1) :', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
          Text(
            "$taux $u2",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange[700]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          // Raccourcis globaux avec Ctrl
          SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveIntent(),
          SingleActivator(LogicalKeyboardKey.keyN, control: true): NewSaleIntent(),
          SingleActivator(LogicalKeyboardKey.keyD, control: true): CancelSaleIntent(),
          SingleActivator(LogicalKeyboardKey.keyP, control: true): PrintInvoiceIntent(),
          SingleActivator(LogicalKeyboardKey.keyF, control: true): SearchArticleIntent(),
          SingleActivator(LogicalKeyboardKey.keyJ, control: true): LastJournalIntent(),

          // Raccourcis avec Ctrl+Shift
          SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true): PrintBLIntent(),

          SingleActivator(LogicalKeyboardKey.keyX, control: true, shift: true): LastCanceledIntent(),

          // Raccourcis simples
          SingleActivator(LogicalKeyboardKey.escape): CloseIntent(),
          SingleActivator(LogicalKeyboardKey.f3): ValidateIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            SaveIntent: CallbackAction<SaveIntent>(
              onInvoke: (intent) {
                if (_peutValiderBrouillard()) {
                  _sauvegarderModificationsBrouillard();
                } else if (_lignesVente.isNotEmpty) {
                  _validerVente();
                }
                return null;
              },
            ),
            NewSaleIntent: CallbackAction<NewSaleIntent>(
              onInvoke: (intent) {
                _creerNouvelleVente();
                return null;
              },
            ),
            CancelSaleIntent: CallbackAction<CancelSaleIntent>(
              onInvoke: (intent) {
                if (_isExistingPurchase) {
                  _contrePasserVente();
                }
                return null;
              },
            ),
            PrintInvoiceIntent: CallbackAction<PrintInvoiceIntent>(
              onInvoke: (intent) {
                if (_lignesVente.isNotEmpty) {
                  _imprimerFacture();
                }
                return null;
              },
            ),
            PrintBLIntent: CallbackAction<PrintBLIntent>(
              onInvoke: (intent) {
                if (_lignesVente.isNotEmpty) {
                  _imprimerBL();
                }
                return null;
              },
            ),
            SearchArticleIntent: CallbackAction<SearchArticleIntent>(
              onInvoke: (intent) {
                _searchArticleFocusNode.requestFocus();
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (_searchArticleController.text.isNotEmpty) {
                    _searchArticleController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _searchArticleController.text.length,
                    );
                  }
                });
                return null;
              },
            ),
            LastJournalIntent: CallbackAction<LastJournalIntent>(
              onInvoke: (intent) {
                _ventesFuture?.then((ventes) {
                  final journals = ventes
                      .where((v) => v['verification'] == 'JOURNAL' && v['contre'] != '1')
                      .toList();
                  if (journals.isNotEmpty) {
                    final dernierJournal = journals.first;
                    _chargerVenteExistante(dernierJournal['numventes']);
                  }
                });
                return null;
              },
            ),
            LastCanceledIntent: CallbackAction<LastCanceledIntent>(
              onInvoke: (intent) {
                _ventesFuture?.then((ventes) {
                  final contrePassees = ventes
                      .where((v) => v['verification'] == 'JOURNAL' && v['contre'] == '1')
                      .toList();
                  if (contrePassees.isNotEmpty) {
                    final derniereCP = contrePassees.first;
                    _chargerVenteExistante(derniereCP['numventes']);
                  }
                });
                return null;
              },
            ),
            CloseIntent: CallbackAction<CloseIntent>(
              onInvoke: (intent) {
                Navigator.of(context).pop();
                return null;
              },
            ),
            ValidateIntent: CallbackAction<ValidateIntent>(
              onInvoke: (intent) {
                if (_peutValiderBrouillard()) {
                  _validerBrouillardVersJournal();
                }
                return null;
              },
            ),
          },
          child: FocusScope(
            autofocus: true,
            child: Focus(
              focusNode: _globalShortcutsFocusNode,
              canRequestFocus: true,
              descendantsAreFocusable: true,
              onKeyEvent: (node, event) {
                // Gérer la navigation Tab personnalisée
                final tabResult = handleTabNavigation(event);
                return tabResult == KeyEventResult.handled ? KeyEventResult.handled : KeyEventResult.ignored;
              },
              child: Dialog(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.7,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  minWidth: MediaQuery.of(context).size.width * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.99,
                ),
                backgroundColor: Colors.grey[100],
                child: ScaffoldMessenger(
                  key: _scaffoldMessengerKey,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        color: Colors.grey[100],
                      ),
                      child: Column(
                        children: [
                          // Title bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            height: 35,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Row(
                                      children: [
                                        Text(
                                          'VENTES (${widget.tousDepots ? 'Tous dépôts' : 'Dépôt MAG'})',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        if (_isExistingPurchase && _statutVenteActuelle != null) ...[
                                          const SizedBox(width: 16),
                                          FutureBuilder<bool>(
                                            future: _isVenteContrePassee(),
                                            builder: (context, snapshot) {
                                              final isContrePassee = snapshot.data ?? false;
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: _statutVenteActuelle == StatutVente.brouillard
                                                      ? Colors.orange
                                                      : (isContrePassee ? Colors.red : Colors.green),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                child: Text(
                                                  _statutVenteActuelle == StatutVente.brouillard
                                                      ? 'BROUILLARD'
                                                      : (isContrePassee ? 'CP' : 'JOURNALÉ'),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
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

                          // Main content with sidebar
                          Expanded(
                            child: Row(
                              children: [
                                // Left sidebar - Sales list
                                Container(
                                  width: 250,
                                  decoration: const BoxDecoration(
                                    border: Border(right: BorderSide(color: Colors.grey, width: 1)),
                                    color: Colors.white,
                                  ),
                                  child: _isVendeur()
                                      ? // Vendeur: Simple list without tabs
                                        Column(
                                          children: [
                                            // Search field
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              child: TextField(
                                                controller: _searchVentesController,
                                                decoration: const InputDecoration(
                                                  hintText: 'Rechercher vente...',
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  prefixIcon: Icon(Icons.search, size: 16),
                                                ),
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            // Header
                                            Container(
                                              height: 35,
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(color: Colors.grey, width: 1),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.pending, size: 12, color: Colors.orange),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Mes Ventes en attente',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Sales list
                                            Expanded(child: _buildVentesListByStatus('BROUILLARD')),
                                          ],
                                        )
                                      : // Other users: Three columns layout
                                        Column(
                                          children: [
                                            // Search field
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              child: TextField(
                                                controller: _searchVentesController,
                                                decoration: const InputDecoration(
                                                  hintText: 'Rechercher vente...',
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  prefixIcon: Icon(Icons.search, size: 16),
                                                ),
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            // Three columns layout
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  // Brouillard column
                                                  Expanded(
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          height: 35,
                                                          decoration: const BoxDecoration(
                                                            border: Border(
                                                              bottom: BorderSide(
                                                                color: Colors.grey,
                                                                width: 1,
                                                              ),
                                                              right: BorderSide(color: Colors.grey, width: 1),
                                                            ),
                                                          ),
                                                          child: const Center(
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(
                                                                  Icons.pending,
                                                                  size: 12,
                                                                  color: Colors.orange,
                                                                ),
                                                                SizedBox(width: 4),
                                                                Text(
                                                                  'Brouillard',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.orange,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Container(
                                                            decoration: const BoxDecoration(
                                                              border: Border(
                                                                right: BorderSide(
                                                                  color: Colors.grey,
                                                                  width: 1,
                                                                ),
                                                              ),
                                                            ),
                                                            child: _buildVentesListByStatus('BROUILLARD'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Journal column
                                                  Expanded(
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          height: 35,
                                                          decoration: const BoxDecoration(
                                                            border: Border(
                                                              bottom: BorderSide(
                                                                color: Colors.grey,
                                                                width: 1,
                                                              ),
                                                              right: BorderSide(color: Colors.grey, width: 1),
                                                            ),
                                                          ),
                                                          child: const Center(
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(
                                                                  Icons.check_circle,
                                                                  size: 12,
                                                                  color: Colors.green,
                                                                ),
                                                                SizedBox(width: 4),
                                                                Text(
                                                                  'Journal (Ctrl+J)',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.green,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Container(
                                                            decoration: const BoxDecoration(
                                                              border: Border(
                                                                right: BorderSide(
                                                                  color: Colors.grey,
                                                                  width: 1,
                                                                ),
                                                              ),
                                                            ),
                                                            child: _buildVentesListByStatus('JOURNAL'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Contre-passé column
                                                  Expanded(
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          height: 35,
                                                          decoration: const BoxDecoration(
                                                            border: Border(
                                                              bottom: BorderSide(
                                                                color: Colors.grey,
                                                                width: 1,
                                                              ),
                                                            ),
                                                          ),
                                                          child: const Center(
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(
                                                                  Icons.cancel,
                                                                  size: 12,
                                                                  color: Colors.red,
                                                                ),
                                                                SizedBox(width: 4),
                                                                Text(
                                                                  'Contre-passé (Ctrl+Shift+X)',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.red,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: _buildVentesListByStatus('CONTRE_PASSE'),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),

                                // center Content - Main form
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Top section
                                      Container(
                                        color: const Color(0xFFE6E6FA),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: 120,
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 1,
                                                      ),
                                                      color: _selectedVerification == 'JOURNAL'
                                                          ? Colors.green
                                                          : Colors.orange,
                                                      child: const Text(
                                                        'Enregistrement',
                                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    SizedBox(
                                                      width: 120,
                                                      height: 25,
                                                      child: DropdownButtonFormField<String>(
                                                        initialValue: _selectedVerification,
                                                        decoration: const InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          contentPadding: EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 2,
                                                          ),
                                                        ),
                                                        items: const [
                                                          DropdownMenuItem(
                                                            value: 'BROUILLARD',
                                                            child: Text(
                                                              'Brouillard',
                                                              style: TextStyle(fontSize: 12),
                                                            ),
                                                          ),
                                                          DropdownMenuItem(
                                                            value: 'JOURNAL',
                                                            child: Text(
                                                              'Journal',
                                                              style: TextStyle(fontSize: 12),
                                                            ),
                                                          ),
                                                        ],
                                                        onChanged: _isExistingPurchase
                                                            ? null
                                                            : (value) {
                                                                if (value != null) {
                                                                  setState(() {
                                                                    _selectedVerification = value;
                                                                    _statutVente = value == 'JOURNAL'
                                                                        ? StatutVente.journal
                                                                        : StatutVente.brouillard;
                                                                  });
                                                                }
                                                              },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Wrap(
                                                    spacing: 8,
                                                    runSpacing: 4,
                                                    children: [
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text(
                                                            'N° ventes',
                                                            style: TextStyle(fontSize: 12),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          SizedBox(
                                                            width: 80,
                                                            height: 25,
                                                            child: TextField(
                                                              controller: _numVentesController,
                                                              textAlign: TextAlign.center,
                                                              decoration: const InputDecoration(
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                                fillColor: Color(0xFFF5F5F5),
                                                                filled: true,
                                                              ),
                                                              readOnly: true,
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text('Date', style: TextStyle(fontSize: 12)),
                                                          const SizedBox(width: 4),
                                                          SizedBox(
                                                            width: 100,
                                                            height: 25,
                                                            child: TextField(
                                                              controller: _dateController,
                                                              textAlign: TextAlign.center,
                                                              decoration: const InputDecoration(
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                              ),
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text(
                                                            'N° Facture/ BL',
                                                            style: TextStyle(fontSize: 12),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          SizedBox(
                                                            width: 80,
                                                            height: 25,
                                                            child: TextField(
                                                              controller: _nFactureController,
                                                              textAlign: TextAlign.center,
                                                              decoration: const InputDecoration(
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                              ),
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text('Heure', style: TextStyle(fontSize: 12)),
                                                          const SizedBox(width: 4),
                                                          SizedBox(
                                                            width: 80,
                                                            height: 25,
                                                            child: TextField(
                                                              controller: _heureController,
                                                              textAlign: TextAlign.center,
                                                              decoration: const InputDecoration(
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                              ),
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Text('Clients', style: TextStyle(fontSize: 12)),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: SizedBox(
                                                    height: 25,
                                                    child: Focus(
                                                      onKeyEvent: (node, event) {
                                                        if (event is KeyDownEvent &&
                                                            event.logicalKey == LogicalKeyboardKey.tab) {
                                                          final isShiftPressed =
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftLeft) ||
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftRight);

                                                          if (isShiftPressed) {
                                                            // Pas de champ précédent, rester sur le client
                                                            return KeyEventResult.ignored;
                                                          } else {
                                                            _designationFocusNode.requestFocus();
                                                            return KeyEventResult.handled;
                                                          }
                                                        }
                                                        return KeyEventResult.ignored;
                                                      },
                                                      child: EnhancedAutocomplete<CltData>(
                                                        options: _clients,
                                                        displayStringForOption: (client) => client.rsoc,
                                                        onSelected: (client) {
                                                          setState(() {
                                                            _selectedClient = client.rsoc;
                                                            _clientController.text = client.rsoc;
                                                            _showCreditMode = _shouldShowCreditMode(client);
                                                            if ((!_showCreditMode || _isVendeur()) &&
                                                                _selectedModePaiement == 'A crédit') {
                                                              _selectedModePaiement = 'Espèces';
                                                            }
                                                          });
                                                          _chargerSoldeClient(client.rsoc);
                                                          // Navigate to next field on selection
                                                          _designationFocusNode.requestFocus();
                                                        },
                                                        controller: _clientController,
                                                        focusNode: _clientFocusNode,
                                                        hintText: 'Rechercher un client...',
                                                        decoration: const InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          contentPadding: EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 2,
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: Colors.blue,
                                                              width: 2,
                                                            ),
                                                          ),
                                                        ),
                                                        style: const TextStyle(fontSize: 12),
                                                        onSubmitted: (value) async {
                                                          await _verifierEtCreerClient(value);
                                                          _designationFocusNode.requestFocus();
                                                        },
                                                        onTabPressed: () async {
                                                          final currentText = _clientController.text.trim();
                                                          if (currentText.isNotEmpty) {
                                                            await _verifierEtCreerClient(currentText);
                                                          }
                                                          _designationFocusNode.requestFocus();
                                                        },
                                                        onShiftTabPressed: () =>
                                                            _clientFocusNode.requestFocus(),
                                                        enabled: _selectedVerification != 'JOURNAL',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Article selection section
                                      Container(
                                        color: const Color(0xFFE6E6FA),
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            //Désignation Articles, champ autocomplete avec navigation au clavier
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Désignation Articles',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  SizedBox(
                                                    height: 25,
                                                    child: Focus(
                                                      onKeyEvent: (node, event) {
                                                        if (event is KeyDownEvent &&
                                                            event.logicalKey == LogicalKeyboardKey.tab) {
                                                          final isShiftPressed =
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftLeft) ||
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftRight);

                                                          if (isShiftPressed) {
                                                            _clientFocusNode.requestFocus();
                                                          } else {
                                                            widget.tousDepots
                                                                ? _depotFocusNode.requestFocus()
                                                                : _uniteFocusNode.requestFocus();
                                                          }
                                                          return KeyEventResult.handled;
                                                        }
                                                        return KeyEventResult.ignored;
                                                      },
                                                      child: ArticleNavigationAutocomplete(
                                                        articles: _articles,
                                                        initialArticle: _getLastAddedArticle(),
                                                        selectedArticle:
                                                            _selectedArticle, // Add synchronization
                                                        onArticleChanged: (article) {
                                                          _onArticleSelected(article);
                                                        },
                                                        focusNode: _designationFocusNode,
                                                        hintText: _isClientSelected
                                                            ? 'Rechercher un article... (← → pour naviguer)'
                                                            : 'Sélectionnez d\'abord un client',
                                                        decoration: InputDecoration(
                                                          border: const OutlineInputBorder(),
                                                          contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 2,
                                                          ),
                                                          focusedBorder: const OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: Colors.blue,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          fillColor: _isClientSelected
                                                              ? null
                                                              : Colors.grey[200],
                                                          filled: !_isClientSelected,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: _isClientSelected
                                                              ? Colors.black
                                                              : Colors.grey,
                                                        ),
                                                        onTabPressed: () => widget.tousDepots
                                                            ? _depotFocusNode.requestFocus()
                                                            : _uniteFocusNode.requestFocus(),
                                                        onShiftTabPressed: () =>
                                                            _clientFocusNode.requestFocus(),
                                                        onNextArticleSet: () {
                                                          // Vider le champ unité seulement si on n'est pas en mode modification
                                                          if (!_isModifyingLine) {
                                                            setState(() {
                                                              _selectedUnite = null;
                                                              _uniteController.clear();
                                                            });
                                                          }
                                                        },
                                                        enabled: _isClientSelected,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (_selectedArticle != null) const SizedBox(height: 16),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Dépôts autocomplete
                                            if (widget.tousDepots) ...[
                                              Expanded(
                                                flex: 1,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Dépôts', style: TextStyle(fontSize: 12)),
                                                    const SizedBox(height: 4),
                                                    SizedBox(
                                                      height: 25,
                                                      child: Focus(
                                                        onKeyEvent: (node, event) {
                                                          if (event is KeyDownEvent &&
                                                              event.logicalKey == LogicalKeyboardKey.tab) {
                                                            final isShiftPressed =
                                                                HardwareKeyboard.instance.logicalKeysPressed
                                                                    .contains(LogicalKeyboardKey.shiftLeft) ||
                                                                HardwareKeyboard.instance.logicalKeysPressed
                                                                    .contains(LogicalKeyboardKey.shiftRight);

                                                            if (isShiftPressed) {
                                                              _designationFocusNode.requestFocus();
                                                            } else {
                                                              _uniteFocusNode.requestFocus();
                                                            }
                                                            return KeyEventResult.handled;
                                                          }
                                                          return KeyEventResult.ignored;
                                                        },
                                                        child: EnhancedAutocomplete<String>(
                                                          options: _depots
                                                              .map((depot) => depot.depots)
                                                              .toList(),
                                                          displayStringForOption: (depot) => depot,
                                                          controller: _depotController,
                                                          focusNode: _depotFocusNode,
                                                          onSelected: (depot) {
                                                            _onDepotChanged(depot);
                                                            _uniteFocusNode.requestFocus();
                                                          },
                                                          onSubmitted: (value) async {
                                                            await _verifierDepot(value);
                                                            _uniteFocusNode.requestFocus();
                                                          },
                                                          onTabPressed: () async {
                                                            await _verifierDepot(_depotController.text);
                                                            _uniteFocusNode.requestFocus();
                                                          },
                                                          onShiftTabPressed: () =>
                                                              _designationFocusNode.requestFocus(),
                                                          onFocusLost: (value) async {
                                                            await _verifierDepot(value);
                                                          },
                                                          hintText: 'Dépôt...',
                                                          decoration: InputDecoration(
                                                            border: const OutlineInputBorder(),
                                                            contentPadding: const EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 2,
                                                            ),
                                                            focusedBorder: const OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                color: Colors.blue,
                                                                width: 2,
                                                              ),
                                                            ),
                                                            fillColor: _isClientSelected
                                                                ? null
                                                                : Colors.grey[200],
                                                            filled: !_isClientSelected,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: _isClientSelected
                                                                ? Colors.black
                                                                : Colors.grey,
                                                          ),
                                                          enabled: _isClientSelected,
                                                        ),
                                                      ),
                                                    ),
                                                    if (_selectedArticle != null) const SizedBox(height: 19),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            //Unités disponible de l'article
                                            Expanded(
                                              flex: 1,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Unités', style: TextStyle(fontSize: 12)),
                                                  const SizedBox(height: 3),
                                                  SizedBox(
                                                    height: 25,
                                                    child: Focus(
                                                      onKeyEvent: (node, event) {
                                                        if (event is KeyDownEvent &&
                                                            event.logicalKey == LogicalKeyboardKey.tab) {
                                                          final isShiftPressed =
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftLeft) ||
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftRight);

                                                          if (isShiftPressed) {
                                                            widget.tousDepots
                                                                ? _depotFocusNode.requestFocus()
                                                                : _designationFocusNode.requestFocus();
                                                          } else {
                                                            _quantiteFocusNode.requestFocus();
                                                          }
                                                          return KeyEventResult.handled;
                                                        }
                                                        return KeyEventResult.ignored;
                                                      },
                                                      child: EnhancedAutocomplete<String>(
                                                        options: _selectedArticle != null
                                                            ? _getUnitsForSelectedArticle()
                                                                  .map((item) => item.value!)
                                                                  .toList()
                                                            : [''],
                                                        displayStringForOption: (unit) => unit,
                                                        controller: _uniteController,
                                                        onSelected: (unit) {
                                                          if (_selectedArticle != null) {
                                                            _verifierUniteArticle(unit);
                                                          }
                                                          _quantiteFocusNode.requestFocus();
                                                        },
                                                        focusNode: _uniteFocusNode,
                                                        hintText: 'Unité...',
                                                        decoration: InputDecoration(
                                                          border: const OutlineInputBorder(),
                                                          contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 2,
                                                          ),
                                                          fillColor: _isClientSelected
                                                              ? null
                                                              : Colors.grey[200],
                                                          filled: !_isClientSelected,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: _isClientSelected
                                                              ? Colors.black
                                                              : Colors.grey,
                                                        ),
                                                        onSubmitted: (value) {
                                                          if (_selectedArticle != null && value.isNotEmpty) {
                                                            _verifierUniteArticle(value);
                                                          }
                                                          _quantiteFocusNode.requestFocus();
                                                        },
                                                        onTabPressed: () => _quantiteFocusNode.requestFocus(),
                                                        onShiftTabPressed: () => widget.tousDepots
                                                            ? _depotFocusNode.requestFocus()
                                                            : _designationFocusNode.requestFocus(),
                                                        onFocusLost: (value) {
                                                          if (_selectedArticle != null && value.isNotEmpty) {
                                                            _verifierUniteArticle(value);
                                                          }
                                                        },
                                                        enabled: _isClientSelected,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_selectedArticle != null && _uniteAffichage.isNotEmpty)
                                                    Text(
                                                      _uniteAffichage,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.blue,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            //Quantités avec stock disponible en rouge si insuffisant
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Quantités', style: TextStyle(fontSize: 12)),
                                                  const SizedBox(height: 4),
                                                  SizedBox(
                                                    height: 25,
                                                    child: Focus(
                                                      onKeyEvent: (node, event) {
                                                        if (event is KeyDownEvent &&
                                                            event.logicalKey == LogicalKeyboardKey.tab) {
                                                          final isShiftPressed =
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftLeft) ||
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftRight);

                                                          if (isShiftPressed) {
                                                            _uniteFocusNode.requestFocus();
                                                          } else {
                                                            _validerQuantite(_quantiteController.text);
                                                            _prixFocusNode.requestFocus();
                                                          }
                                                          return KeyEventResult.handled;
                                                        }
                                                        return KeyEventResult.ignored;
                                                      },
                                                      child: TextField(
                                                        controller: _quantiteController,
                                                        focusNode: _quantiteFocusNode,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter.allow(
                                                            RegExp(r'^\d*\.?\d*'),
                                                          ),
                                                        ],
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: _isQuantiteInsuffisante()
                                                                  ? Colors.red
                                                                  : Colors.grey,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: _isQuantiteInsuffisante()
                                                                  ? Colors.red
                                                                  : Colors.grey,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 2,
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: _isQuantiteInsuffisante()
                                                                  ? Colors.red
                                                                  : Colors.blue,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          fillColor: _isClientSelected
                                                              ? null
                                                              : Colors.grey[200],
                                                          filled: !_isClientSelected,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: !_isClientSelected
                                                              ? Colors.grey
                                                              : _isQuantiteInsuffisante()
                                                              ? Colors.red
                                                              : Colors.black,
                                                        ),
                                                        onChanged: (value) {
                                                          setState(() {}); // Refresh to update color
                                                        },
                                                        // ENTER/TAB in Quantités goes to Prix
                                                        onSubmitted: (value) {
                                                          _prixFocusNode.requestFocus();
                                                        },
                                                        readOnly:
                                                            _selectedVerification == 'JOURNAL' ||
                                                            !_isClientSelected,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_selectedArticle != null && _selectedDepot != null)
                                                    FutureBuilder<String>(
                                                      future: _getStocksToutesUnites(
                                                        _selectedArticle!,
                                                        _selectedDepot!,
                                                      ),
                                                      builder: (context, snapshot) {
                                                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                                          return Text(
                                                            '${snapshot.data}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: _stockInsuffisant
                                                                  ? Colors.red
                                                                  : Colors.green[700],
                                                            ),
                                                          );
                                                        }
                                                        return const SizedBox.shrink();
                                                      },
                                                    ),
                                                  if (_selectedArticle != null && _selectedUnite == "")
                                                    const SizedBox(height: 16),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            //Prix de vente unitaire HT de l'article
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('P.U HT', style: TextStyle(fontSize: 12)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  SizedBox(
                                                    height: 25,
                                                    child: Focus(
                                                      onKeyEvent: (node, event) {
                                                        if (event is KeyDownEvent &&
                                                            event.logicalKey == LogicalKeyboardKey.tab) {
                                                          final isShiftPressed =
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftLeft) ||
                                                              HardwareKeyboard.instance.logicalKeysPressed
                                                                  .contains(LogicalKeyboardKey.shiftRight);

                                                          if (isShiftPressed) {
                                                            _quantiteFocusNode.requestFocus();
                                                          } else {
                                                            _ajouterFocusNode.requestFocus();
                                                          }
                                                          return KeyEventResult.handled;
                                                        }
                                                        return KeyEventResult.ignored;
                                                      },
                                                      child: TextField(
                                                        controller: _prixController,
                                                        focusNode: _prixFocusNode,
                                                        decoration: InputDecoration(
                                                          border: const OutlineInputBorder(),
                                                          contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 2,
                                                          ),
                                                          focusedBorder: const OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: Colors.blue,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          fillColor: _isClientSelected
                                                              ? null
                                                              : Colors.grey[200],
                                                          filled: !_isClientSelected,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: _isClientSelected
                                                              ? Colors.black
                                                              : Colors.grey,
                                                        ),
                                                        // onChanged: (value) => _calculerMontant(),
                                                        // ENTER in Prix goes to Ajouter
                                                        onSubmitted: (value) =>
                                                            _ajouterFocusNode.requestFocus(),
                                                        readOnly:
                                                            _selectedVerification == 'JOURNAL' ||
                                                            !_isClientSelected,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_selectedArticle != null) const SizedBox(height: 16),
                                                ],
                                              ),
                                            ),

                                            //Bouton Ajouter et Annuler
                                            if (_shouldShowAddButton()) ...[
                                              const SizedBox(width: 8),
                                              Column(
                                                children: [
                                                  const SizedBox(height: 16),
                                                  Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          // AJOUTER/MODIFIER BUTTON
                                                          Focus(
                                                            focusNode: _ajouterFocusNode,
                                                            onKeyEvent: (node, event) {
                                                              if (event is KeyDownEvent) {
                                                                if (event.logicalKey ==
                                                                    LogicalKeyboardKey.tab) {
                                                                  final isShiftPressed =
                                                                      HardwareKeyboard
                                                                          .instance
                                                                          .logicalKeysPressed
                                                                          .contains(
                                                                            LogicalKeyboardKey.shiftLeft,
                                                                          ) ||
                                                                      HardwareKeyboard
                                                                          .instance
                                                                          .logicalKeysPressed
                                                                          .contains(
                                                                            LogicalKeyboardKey.shiftRight,
                                                                          );

                                                                  if (isShiftPressed) {
                                                                    _prixFocusNode.requestFocus();
                                                                  } else {
                                                                    _annulerFocusNode.requestFocus();
                                                                  }
                                                                  return KeyEventResult.handled;
                                                                } else if (event.logicalKey ==
                                                                    LogicalKeyboardKey.enter) {
                                                                  if (_ajouterFocusNode.hasFocus &&
                                                                      _isClientSelected) {
                                                                    _ajouterLigne();
                                                                  }
                                                                  return KeyEventResult.handled;
                                                                }
                                                              }
                                                              return KeyEventResult.ignored;
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                border: _ajouterFocusNode.hasFocus
                                                                    ? Border.all(color: Colors.blue, width: 3)
                                                                    : null,
                                                                borderRadius: BorderRadius.circular(4),
                                                                boxShadow: _ajouterFocusNode.hasFocus
                                                                    ? [
                                                                        BoxShadow(
                                                                          color: Colors.blue.withValues(
                                                                            alpha: 0.3,
                                                                          ),
                                                                          blurRadius: 4,
                                                                          spreadRadius: 1,
                                                                        ),
                                                                      ]
                                                                    : null,
                                                              ),
                                                              child: ElevatedButton(
                                                                onPressed: _isClientSelected
                                                                    ? _ajouterLigne
                                                                    : null,
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: _ajouterFocusNode.hasFocus
                                                                      ? Colors.green[600]
                                                                      : (_isClientSelected
                                                                            ? Colors.green
                                                                            : Colors.grey),
                                                                  foregroundColor: Colors.white,
                                                                  minimumSize: const Size(60, 35),
                                                                  elevation: _ajouterFocusNode.hasFocus
                                                                      ? 4
                                                                      : 2,
                                                                ),
                                                                child: Text(
                                                                  _ajouterFocusNode.hasFocus
                                                                      ? (_isModifyingLine
                                                                            ? 'Modifier ↵'
                                                                            : 'Ajouter ↵')
                                                                      : (_isModifyingLine
                                                                            ? 'Modifier'
                                                                            : 'Ajouter'),
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: _ajouterFocusNode.hasFocus
                                                                        ? FontWeight.bold
                                                                        : FontWeight.normal,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          // ANNULER BUTTON
                                                          Focus(
                                                            focusNode: _annulerFocusNode,
                                                            onKeyEvent: (node, event) {
                                                              if (event is KeyDownEvent) {
                                                                if (event.logicalKey ==
                                                                    LogicalKeyboardKey.tab) {
                                                                  final isShiftPressed =
                                                                      HardwareKeyboard
                                                                          .instance
                                                                          .logicalKeysPressed
                                                                          .contains(
                                                                            LogicalKeyboardKey.shiftLeft,
                                                                          ) ||
                                                                      HardwareKeyboard
                                                                          .instance
                                                                          .logicalKeysPressed
                                                                          .contains(
                                                                            LogicalKeyboardKey.shiftRight,
                                                                          );

                                                                  if (isShiftPressed) {
                                                                    _ajouterFocusNode.requestFocus();
                                                                  } else {
                                                                    _clientFocusNode.requestFocus();
                                                                  }
                                                                  return KeyEventResult.handled;
                                                                } else if (event.logicalKey ==
                                                                    LogicalKeyboardKey.enter) {
                                                                  if (_annulerFocusNode.hasFocus &&
                                                                      _isClientSelected) {
                                                                    _isModifyingLine
                                                                        ? _annulerModificationLigne()
                                                                        : _resetArticleForm();
                                                                  }
                                                                  return KeyEventResult.handled;
                                                                }
                                                              }
                                                              return KeyEventResult.ignored;
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                border: _annulerFocusNode.hasFocus
                                                                    ? Border.all(color: Colors.blue, width: 3)
                                                                    : null,
                                                                borderRadius: BorderRadius.circular(4),
                                                                boxShadow: _annulerFocusNode.hasFocus
                                                                    ? [
                                                                        BoxShadow(
                                                                          color: Colors.blue.withValues(
                                                                            alpha: 0.3,
                                                                          ),
                                                                          blurRadius: 4,
                                                                          spreadRadius: 1,
                                                                        ),
                                                                      ]
                                                                    : null,
                                                              ),
                                                              child: ElevatedButton(
                                                                onPressed: _isClientSelected
                                                                    ? (_isModifyingLine
                                                                          ? _annulerModificationLigne
                                                                          : _resetArticleForm)
                                                                    : null,
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: _annulerFocusNode.hasFocus
                                                                      ? Colors.orange[600]
                                                                      : (_isClientSelected
                                                                            ? Colors.orange
                                                                            : Colors.grey),
                                                                  foregroundColor: Colors.white,
                                                                  minimumSize: const Size(60, 35),
                                                                  elevation: _annulerFocusNode.hasFocus
                                                                      ? 4
                                                                      : 2,
                                                                ),
                                                                child: Text(
                                                                  _annulerFocusNode.hasFocus
                                                                      ? 'Annuler ↵'
                                                                      : 'Annuler',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: _annulerFocusNode.hasFocus
                                                                        ? FontWeight.bold
                                                                        : FontWeight.normal,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (_selectedArticle != null)
                                                        const SizedBox(height: 16),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Articles table: // Lignes de vente list section
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey, width: 1),
                                            color: Colors.white,
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                height: 25,
                                                decoration: BoxDecoration(color: Colors.orange[300]),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 30,
                                                      alignment: Alignment.center,
                                                      decoration: const BoxDecoration(
                                                        border: Border(
                                                          right: BorderSide(color: Colors.grey, width: 1),
                                                          bottom: BorderSide(color: Colors.grey, width: 1),
                                                        ),
                                                      ),
                                                      child: const Icon(Icons.delete, size: 12),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            right: BorderSide(color: Colors.grey, width: 1),
                                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'DESIGNATION',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            right: BorderSide(color: Colors.grey, width: 1),
                                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'UNITES',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            right: BorderSide(color: Colors.grey, width: 1),
                                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'QUANTITES',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            right: BorderSide(color: Colors.grey, width: 1),
                                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'PRIX UNITAIRE (HT)',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            right: BorderSide(color: Colors.grey, width: 1),
                                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'MONTANT',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (widget.tousDepots)
                                                      Expanded(
                                                        flex: 1,
                                                        child: Container(
                                                          alignment: Alignment.center,
                                                          decoration: const BoxDecoration(
                                                            border: Border(
                                                              bottom: BorderSide(
                                                                color: Colors.grey,
                                                                width: 1,
                                                              ),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'DEPOTS',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: _lignesVente.isEmpty
                                                    ? const Center(
                                                        child: Text(
                                                          'Aucun article ajouté',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.grey,
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                      )
                                                    : ListView.builder(
                                                        itemCount: _lignesVente.length,
                                                        itemExtent: 18,
                                                        itemBuilder: (context, index) {
                                                          final ligne = _lignesVente[index];
                                                          return MouseRegion(
                                                            onEnter: (_) {
                                                              setState(() {
                                                                _selectedRowIndex = index;
                                                              });
                                                            },
                                                            onExit: (_) {
                                                              setState(() {
                                                                _selectedRowIndex = index;
                                                              });
                                                            },
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  _selectedRowIndex = index;
                                                                });
                                                              },
                                                              onSecondaryTapDown:
                                                                  _selectedVerification == 'JOURNAL'
                                                                  ? null
                                                                  : (details) => _showContextMenu(
                                                                      context,
                                                                      details,
                                                                      index,
                                                                    ),
                                                              child: Container(
                                                                height: 18,
                                                                decoration: BoxDecoration(
                                                                  color: _selectedRowIndex == index
                                                                      ? Colors.blue[200]
                                                                      : (index % 2 == 0
                                                                            ? Colors.white
                                                                            : Colors.grey[50]),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      width: 30,
                                                                      alignment: Alignment.center,
                                                                      decoration: const BoxDecoration(
                                                                        border: Border(
                                                                          right: BorderSide(
                                                                            color: Colors.grey,
                                                                            width: 1,
                                                                          ),
                                                                          bottom: BorderSide(
                                                                            color: Colors.grey,
                                                                            width: 1,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      child: IconButton(
                                                                        icon: const Icon(
                                                                          Icons.close,
                                                                          size: 12,
                                                                        ),
                                                                        onPressed: () =>
                                                                            _supprimerLigne(index),
                                                                        padding: EdgeInsets.zero,
                                                                        constraints: const BoxConstraints(),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      flex: 3,
                                                                      child: Container(
                                                                        padding: const EdgeInsets.only(
                                                                          left: 4,
                                                                        ),
                                                                        alignment: Alignment.centerLeft,
                                                                        decoration: const BoxDecoration(
                                                                          border: Border(
                                                                            right: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                            bottom: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          ligne['designation'] ?? '',
                                                                          style: const TextStyle(
                                                                            fontSize: 11,
                                                                          ),
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      flex: 1,
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal: 4,
                                                                        ),
                                                                        alignment: Alignment.center,
                                                                        decoration: const BoxDecoration(
                                                                          border: Border(
                                                                            right: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                            bottom: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          ligne['unites'] ?? '',
                                                                          style: const TextStyle(
                                                                            fontSize: 11,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      flex: 1,
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal: 4,
                                                                        ),
                                                                        alignment: Alignment.center,
                                                                        decoration: const BoxDecoration(
                                                                          border: Border(
                                                                            right: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                            bottom: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          (ligne['quantite'] as double?)
                                                                                  ?.round()
                                                                                  .toString() ??
                                                                              '0',
                                                                          style: const TextStyle(
                                                                            fontSize: 11,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      flex: 2,
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal: 4,
                                                                        ),
                                                                        alignment: Alignment.center,
                                                                        decoration: const BoxDecoration(
                                                                          border: Border(
                                                                            right: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                            bottom: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          AppFunctions.formatNumber(
                                                                            ligne['prixUnitaire']
                                                                                    ?.toDouble() ??
                                                                                0,
                                                                          ),
                                                                          style: const TextStyle(
                                                                            fontSize: 11,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      flex: 2,
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal: 4,
                                                                        ),
                                                                        alignment: Alignment.center,
                                                                        decoration: BoxDecoration(
                                                                          border: Border(
                                                                            right: widget.tousDepots
                                                                                ? const BorderSide(
                                                                                    color: Colors.grey,
                                                                                    width: 1,
                                                                                  )
                                                                                : BorderSide.none,
                                                                            bottom: const BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 1,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          AppFunctions.formatNumber(
                                                                            ligne['montant']?.toDouble() ?? 0,
                                                                          ),
                                                                          style: const TextStyle(
                                                                            fontSize: 11,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    if (widget.tousDepots)
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child: Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal: 4,
                                                                          ),
                                                                          alignment: Alignment.center,
                                                                          decoration: const BoxDecoration(
                                                                            border: Border(
                                                                              bottom: BorderSide(
                                                                                color: Colors.grey,
                                                                                width: 1,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          child: Text(
                                                                            ligne['depot'] ?? '',
                                                                            style: const TextStyle(
                                                                              fontSize: 11,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Bottom section - Invoice-style totals and payment
                                      Container(
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Left side - Payment details
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'MODE DE PAIEMENT',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    SizedBox(
                                                      height: 25,
                                                      width: double.infinity,
                                                      child: ModePaiementDropdown(
                                                        selectedMode: _selectedModePaiement,
                                                        showCreditMode: _showCreditMode && !_isVendeur(),
                                                        tousDepots: widget.tousDepots,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _selectedModePaiement = value;
                                                          });
                                                          _calculerTotaux();
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if (_showCreditMode &&
                                                        !_isVendeur() &&
                                                        widget.tousDepots) ...[
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          const Text(
                                                            'Solde antérieur:',
                                                            style: TextStyle(fontSize: 12),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: SizedBox(
                                                              height: 25,
                                                              child: TextField(
                                                                controller: _soldeAnterieurController,
                                                                decoration: const InputDecoration(
                                                                  border: OutlineInputBorder(),
                                                                  contentPadding: EdgeInsets.symmetric(
                                                                    horizontal: 8,
                                                                    vertical: 4,
                                                                  ),
                                                                  fillColor: Color(0xFFF5F5F5),
                                                                  filled: true,
                                                                ),
                                                                style: const TextStyle(fontSize: 12),
                                                                textAlign: TextAlign.right,
                                                                readOnly: true,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            _selectedModePaiement == 'A crédit'
                                                                ? 'Solde dû client:'
                                                                : 'Nouveau solde:',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: _selectedModePaiement == 'A crédit'
                                                                  ? Colors.red
                                                                  : Colors.black,
                                                              fontWeight: _selectedModePaiement == 'A crédit'
                                                                  ? FontWeight.w500
                                                                  : FontWeight.normal,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: SizedBox(
                                                              height: 25,
                                                              child: TextField(
                                                                controller: _nouveauSoldeController,
                                                                decoration: InputDecoration(
                                                                  border: const OutlineInputBorder(),
                                                                  contentPadding: const EdgeInsets.symmetric(
                                                                    horizontal: 8,
                                                                    vertical: 4,
                                                                  ),
                                                                  fillColor:
                                                                      _selectedModePaiement == 'A crédit'
                                                                      ? Colors.red.shade50
                                                                      : const Color(0xFFF5F5F5),
                                                                  filled: true,
                                                                ),
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: _selectedModePaiement == 'A crédit'
                                                                      ? Colors.red
                                                                      : Colors.black,
                                                                  fontWeight:
                                                                      _selectedModePaiement == 'A crédit'
                                                                      ? FontWeight.w500
                                                                      : FontWeight.normal,
                                                                ),
                                                                readOnly: true,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Right side - Invoice totals
                                            if (!_isVendeur())
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey.shade300),
                                                    borderRadius: BorderRadius.circular(4),
                                                    color: Colors.grey.shade50,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      const Text(
                                                        'RÉCAPITULATIF FACTURE',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),

                                                      const SizedBox(height: 8),
                                                      // Remise
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Remise:',
                                                                style: TextStyle(fontSize: 12),
                                                              ),
                                                              const SizedBox(width: 4),
                                                              SizedBox(
                                                                width: 50,
                                                                height: 25,
                                                                child: TextField(
                                                                  controller: _remiseController,
                                                                  decoration: const InputDecoration(
                                                                    border: OutlineInputBorder(),
                                                                    contentPadding: EdgeInsets.symmetric(
                                                                      horizontal: 4,
                                                                      vertical: 2,
                                                                    ),
                                                                    suffixText: '%',
                                                                  ),
                                                                  style: const TextStyle(fontSize: 12),
                                                                  textAlign: TextAlign.center,
                                                                  onChanged: (value) => _calculerTotaux(),
                                                                  readOnly:
                                                                      _selectedVerification == 'JOURNAL',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            width: 100,
                                                            height: 25,
                                                            child: TextField(
                                                              controller: TextEditingController(
                                                                text: _calculateRemiseAmount(),
                                                              ),
                                                              decoration: const InputDecoration(
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                                fillColor: Colors.white,
                                                                filled: true,
                                                              ),
                                                              style: const TextStyle(fontSize: 12),
                                                              textAlign: TextAlign.right,
                                                              readOnly: true,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(height: 16),
                                                      // Total TTC
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          const Text(
                                                            'TOTAL TTC:',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 100,
                                                            height: 30,
                                                            child: TextField(
                                                              controller: _totalTTCController,
                                                              decoration: const InputDecoration(
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 2,
                                                                ),
                                                              ),
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.blue,
                                                              ),
                                                              textAlign: TextAlign.right,
                                                              readOnly: true,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Action buttons
                                      Container(
                                        width: double.infinity,
                                        decoration: const BoxDecoration(color: Color(0xFFFFB6C1)),
                                        padding: const EdgeInsets.all(8),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          alignment: WrapAlignment.end,
                                          children: [
                                            //Bouton Nouvel vente
                                            if (_isExistingPurchase) ...[
                                              Tooltip(
                                                message: 'Créer nouveau (Ctrl+N)',
                                                child: ElevatedButton(
                                                  onPressed: _creerNouvelleVente,
                                                  style: ElevatedButton.styleFrom(
                                                    minimumSize: const Size(60, 30),
                                                  ),
                                                  child: const Text(
                                                    'Créer (Ctrl+N)',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                              if (_peutValiderBrouillard()) ...[
                                                Tooltip(
                                                  message: 'Valider la vente (F3)',
                                                  child: ElevatedButton(
                                                    onPressed: _validerBrouillardVersJournal,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green,
                                                      foregroundColor: Colors.white,
                                                      minimumSize: const Size(80, 30),
                                                    ),
                                                    child: const Text(
                                                      'Valider la vente(F3)',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                                // Bouton Contre-passer vente brouillard
                                                Tooltip(
                                                  message: 'Contre-passer vente brouillard',
                                                  child: ElevatedButton(
                                                    onPressed: _contrePasserVenteBrouillard,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      foregroundColor: Colors.white,
                                                      minimumSize: const Size(80, 30),
                                                    ),
                                                    child: const Text(
                                                      'Supprimer Brouillard',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                            // Bouton Importation
                                            if (!_isExistingPurchase)
                                              Tooltip(
                                                message: 'Importer lignes d\'achat',
                                                child: ElevatedButton(
                                                  onPressed: _importerLignesVente,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange,
                                                    foregroundColor: Colors.white,
                                                    minimumSize: const Size(60, 30),
                                                  ),
                                                  child: const Text(
                                                    'Importer lignes',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                            if (!_peutValiderBrouillard()) ...[
                                              //Bouton Contre passer
                                              if (_isExistingPurchase) ...[
                                                FutureBuilder<bool>(
                                                  future: _isVenteContrePassee(),
                                                  builder: (context, snapshot) {
                                                    final isContrePassee = snapshot.data ?? false;
                                                    return Tooltip(
                                                      message: isContrePassee
                                                          ? 'Vente déjà contre-passée'
                                                          : 'Contre-passer (Ctrl+D)',
                                                      child: ElevatedButton(
                                                        onPressed: isContrePassee ? null : _contrePasserVente,
                                                        style: ElevatedButton.styleFrom(
                                                          minimumSize: const Size(80, 30),
                                                          backgroundColor: isContrePassee
                                                              ? Colors.grey
                                                              : null,
                                                        ),
                                                        child: const Text(
                                                          'Contre Passer (Ctrl+D)',
                                                          style: TextStyle(fontSize: 12),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ],

                                            //Bouton Modifier/ Enregistrer
                                            Tooltip(
                                              message: _isExistingPurchase
                                                  ? 'Modifier (Ctrl+S)'
                                                  : 'Enregistrer (Ctrl+S)',
                                              child: ElevatedButton(
                                                onPressed: _selectedVerification == 'JOURNAL'
                                                    ? null
                                                    : (_isExistingPurchase ? _modifierVente : _validerVente),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _isExistingPurchase
                                                      ? Colors.blue
                                                      : Colors.green,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: const Size(60, 30),
                                                ),
                                                child: Text(
                                                  _isExistingPurchase
                                                      ? 'Modifier (Ctrl+S)'
                                                      : 'Enregistrer (Ctrl+S)',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),

                                            //Popup menu format papier d'impression
                                            PopupMenuButton<String>(
                                              style: const ButtonStyle(
                                                padding: WidgetStateProperty.fromMap({
                                                  WidgetState.hovered: EdgeInsets.all(0),
                                                  WidgetState.focused: EdgeInsets.all(0),
                                                  WidgetState.pressed: EdgeInsets.all(0),
                                                }),
                                              ),
                                              menuPadding: const EdgeInsets.all(2),
                                              initialValue: _selectedFormat,
                                              itemBuilder: (BuildContext context) => [
                                                const PopupMenuItem(
                                                  value: 'A4',
                                                  child: Text('Format A4', style: TextStyle(fontSize: 12)),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'A5',
                                                  child: Text('Format A5', style: TextStyle(fontSize: 12)),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'A6',
                                                  child: Text('Format A6', style: TextStyle(fontSize: 12)),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                if (value == 'facture') {
                                                  _apercuFacture();
                                                } else if (value == 'bl') {
                                                  _apercuBL();
                                                } else {
                                                  setState(() {
                                                    _selectedFormat = value;
                                                  });
                                                }
                                              },
                                              child: Container(
                                                constraints: const BoxConstraints(
                                                  minWidth: 60,
                                                  minHeight: 18,
                                                  maxHeight: 30,
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.print, color: Colors.white, size: 16),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _selectedFormat,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            //Bouton d'impression facture
                                            FutureBuilder<bool>(
                                              future: _isVenteContrePassee(),
                                              builder: (context, snapshot) {
                                                final isContrePassee = snapshot.data ?? false;
                                                return Tooltip(
                                                  message: 'Imprimer Facture (Ctrl+P)',
                                                  child: ElevatedButton(
                                                    onPressed: isContrePassee ? null : _imprimerFacture,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _selectedVerification != 'JOURNAL'
                                                          ? Colors.grey
                                                          : Colors.teal,
                                                      foregroundColor: Colors.white,
                                                      minimumSize: const Size(60, 30),
                                                    ),
                                                    child: const Text(
                                                      'Imprimer Facture (Ctrl+P)',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            // Bouton d'Aperçu Facture
                                            FutureBuilder<bool>(
                                              future: _isVenteContrePassee(),
                                              builder: (context, snapshot) {
                                                final isContrePassee = snapshot.data ?? false;
                                                return Tooltip(
                                                  message: 'Aperçu Facture',
                                                  child: ElevatedButton(
                                                    onPressed: isContrePassee ? null : _apercuFacture,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _selectedVerification != 'JOURNAL'
                                                          ? Colors.grey
                                                          : Colors.orange,
                                                      foregroundColor: Colors.white,
                                                      minimumSize: const Size(60, 30),
                                                    ),
                                                    child: const Text(
                                                      'Aperçu Facture',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            // Bouton d'impression BL
                                            FutureBuilder<bool>(
                                              future: _isVenteContrePassee(),
                                              builder: (context, snapshot) {
                                                final isContrePassee = snapshot.data ?? false;
                                                return Tooltip(
                                                  message: 'Imprimer Bon de Livraison (Ctrl+Shift+P)',
                                                  child: ElevatedButton(
                                                    onPressed: isContrePassee ? null : _imprimerBL,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _selectedVerification != 'JOURNAL'
                                                          ? Colors.grey
                                                          : Colors.teal,
                                                      foregroundColor: Colors.white,
                                                      minimumSize: const Size(60, 30),
                                                    ),
                                                    child: const Text(
                                                      'Imprimer BL (Ctrl+Shift+P)',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            //Bouton aperçus BL
                                            FutureBuilder<bool>(
                                              future: _isVenteContrePassee(),
                                              builder: (context, snapshot) {
                                                final isContrePassee = snapshot.data ?? false;
                                                return Tooltip(
                                                  message: 'Aperçu Bon de Livraison',
                                                  child: ElevatedButton(
                                                    onPressed: isContrePassee ? null : _apercuBL,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _selectedVerification != 'JOURNAL'
                                                          ? Colors.grey
                                                          : Colors.orange,
                                                      foregroundColor: Colors.white,
                                                      minimumSize: const Size(60, 30),
                                                    ),
                                                    child: const Text(
                                                      'Aperçu BL',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),

                                            //Bouton de fermeture du modal de vente
                                            Tooltip(
                                              message: 'Fermer (Echap)',
                                              child: ElevatedButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize: const Size(60, 30),
                                                ),
                                                child: const Text('Fermer', style: TextStyle(fontSize: 12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right sidebar - Article details
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _isRightSidebarCollapsed ? 40 : 280,
                                  decoration: const BoxDecoration(
                                    border: Border(left: BorderSide(color: Colors.grey, width: 1)),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    children: [
                                      // Header with toggle button
                                      Container(
                                        height: 35,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          border: const Border(
                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            if (!_isRightSidebarCollapsed) ...[
                                              const Expanded(
                                                child: Text(
                                                  'Détails Article',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _isRightSidebarCollapsed = !_isRightSidebarCollapsed;
                                                });
                                              },
                                              icon: Icon(
                                                _isRightSidebarCollapsed
                                                    ? Icons.chevron_left
                                                    : Icons.chevron_right,
                                                size: 16,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Content
                                      if (!_isRightSidebarCollapsed)
                                        Expanded(
                                          child: Column(
                                            children: [
                                              // Champ de recherche d'article
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                child: EnhancedAutocomplete<Article>(
                                                  options: _articles,
                                                  displayStringForOption: (article) => article.designation,
                                                  onSelected: (article) {
                                                    setState(() {
                                                      _searchedArticle = article;
                                                    });
                                                  },
                                                  hintText: 'Nom de l\'article...',
                                                  controller: _searchArticleController,
                                                  focusNode: _searchArticleFocusNode,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Rechercher article',
                                                    labelStyle: TextStyle(fontSize: 12),
                                                    border: OutlineInputBorder(),
                                                    contentPadding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12,
                                                    ),
                                                    isDense: true,
                                                  ),
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                              // Détails de l'article
                                              Expanded(
                                                child: _searchedArticle == null
                                                    ? const Center(
                                                        child: Text(
                                                          'Saisissez le nom d\'un article\npour voir ses détails',
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                                        ),
                                                      )
                                                    : SingleChildScrollView(
                                                        padding: const EdgeInsets.all(8),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            // Article name
                                                            Container(
                                                              width: double.infinity,
                                                              padding: const EdgeInsets.all(8),
                                                              decoration: BoxDecoration(
                                                                color: Colors.blue[50],
                                                                borderRadius: BorderRadius.circular(4),
                                                                border: Border.all(color: Colors.blue[200]!),
                                                              ),
                                                              child: Text(
                                                                _searchedArticle!.designation,
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 12),
                                                            // Prix de vente
                                                            const Text(
                                                              'PRIX DE VENTE',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.green,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            _buildPriceRow(
                                                              _searchedArticle!.u1,
                                                              _searchedArticle!.pvu1,
                                                            ),
                                                            _buildPriceRow(
                                                              _searchedArticle!.u2,
                                                              _searchedArticle!.pvu2,
                                                            ),
                                                            _buildPriceRow(
                                                              _searchedArticle!.u3,
                                                              _searchedArticle!.pvu3,
                                                            ),
                                                            const SizedBox(height: 12),
                                                            // Conversions
                                                            const Text(
                                                              'CONVERSIONS',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.orange,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),

                                                            _buildConversionRow(
                                                              _searchedArticle!.u1,
                                                              _searchedArticle!.u2,
                                                              _searchedArticle!.tu2u1,
                                                            ),
                                                            _buildConversionRow(
                                                              _searchedArticle!.u2,
                                                              _searchedArticle!.u3,
                                                              _searchedArticle!.tu3u2,
                                                            ),
                                                            const SizedBox(height: 12),
                                                            // Prix d'achat
                                                            const Text(
                                                              'PRIX D\'ACHAT',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.red,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Container(
                                                              width: double.infinity,
                                                              padding: const EdgeInsets.all(6),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red[50],
                                                                borderRadius: BorderRadius.circular(4),
                                                                border: Border.all(color: Colors.red[200]!),
                                                              ),
                                                              child: Text(
                                                                'CMUP: ${AppFunctions.formatNumber(_searchedArticle!.cmup ?? 0)}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.red[700],
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                              ),

                                              // Section Différences de prix
                                              if (_lignesVente.isNotEmpty) ...[
                                                const SizedBox(height: 16),
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.orange.shade200),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Différences de prix',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.orange.shade700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Liste des différences par ligne
                                                      ...(_lignesVente
                                                          .where((ligne) => (ligne['diffPrix'] ?? 0) != 0)
                                                          .map(
                                                            (ligne) => Padding(
                                                              padding: const EdgeInsets.symmetric(
                                                                vertical: 2,
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: Text(
                                                                          ligne['designation'] ?? '',
                                                                          style: const TextStyle(
                                                                            fontSize: 11,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        AppFunctions.formatNumber(
                                                                          (ligne['diffPrix'] ?? 0) *
                                                                              (ligne['quantite'] ?? 0),
                                                                        ),
                                                                        style: TextStyle(
                                                                          fontSize: 11,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: (ligne['diffPrix'] ?? 0) >= 0
                                                                              ? Colors.green
                                                                              : Colors.red,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(
                                                                      left: 8,
                                                                      top: 1,
                                                                    ),
                                                                    child: Text(
                                                                      '${AppFunctions.formatNumber(ligne['quantite'] ?? 0)} ${ligne['unites'] ?? ''} x ${AppFunctions.formatNumber(ligne['diffPrix'] ?? 0)} Ar',
                                                                      style: TextStyle(
                                                                        fontSize: 10,
                                                                        color: Colors.grey[600],
                                                                        fontStyle: FontStyle.italic,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          )),
                                                      if (_lignesVente.any(
                                                        (ligne) => (ligne['diffPrix'] ?? 0) != 0,
                                                      )) ...[
                                                        const Divider(height: 12),
                                                        Row(
                                                          children: [
                                                            const Expanded(
                                                              child: Text(
                                                                'Total Différence:',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              AppFunctions.formatNumber(
                                                                _calculateTotalDiffPrix(),
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: _calculateTotalDiffPrix() >= 0
                                                                    ? Colors.green
                                                                    : Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Définir les classes Intent
class SaveIntent extends Intent {
  const SaveIntent();
}

class NewSaleIntent extends Intent {
  const NewSaleIntent();
}

class CancelSaleIntent extends Intent {
  const CancelSaleIntent();
}

class CloseIntent extends Intent {
  const CloseIntent();
}

class ValidateIntent extends Intent {
  const ValidateIntent();
}

class PrintInvoiceIntent extends Intent {
  const PrintInvoiceIntent();
}

class PrintBLIntent extends Intent {
  const PrintBLIntent();
}

class SearchArticleIntent extends Intent {
  const SearchArticleIntent();
}

class LastJournalIntent extends Intent {
  const LastJournalIntent();
}

class LastCanceledIntent extends Intent {
  const LastCanceledIntent();
}
