import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/achat_service.dart';
import '../../utils/cmup_calculator.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';
import '../../utils/stock_converter.dart';
import '../common/article_navigation_autocomplete.dart';
import '../common/enhanced_autocomplete.dart';
import '../common/tab_navigation_widget.dart';
import 'add_fournisseur_modal.dart';
import 'bon_reception_preview.dart';

class AchatsModal extends StatefulWidget {
  const AchatsModal({super.key});

  @override
  State<AchatsModal> createState() => _AchatsModalState();
}

class _AchatsModalState extends State<AchatsModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  final AchatService _achatService = AchatService();

  // Focus nodes
  late final FocusNode _nFactFocusNode;
  late final FocusNode _fournisseurFocusNode;
  late final FocusNode _articleFocusNode;
  late final FocusNode _uniteFocusNode;
  late final FocusNode _quantiteFocusNode;
  late final FocusNode _prixFocusNode;
  late final FocusNode _depotFocusNode;
  late final FocusNode _validerFocusNode;
  late final FocusNode _annulerFocusNode;
  late final FocusNode _keyboardFocusNode;
  late final FocusNode _searchAchatsFocusNode;
  late final FocusNode _echeanceJoursFocusNode;

  // Controllers
  final TextEditingController _numAchatsController = TextEditingController();
  final TextEditingController _nFactController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fournisseurController = TextEditingController();
  final TextEditingController _modePaiementController = TextEditingController();
  final TextEditingController _echeanceController = TextEditingController();
  final TextEditingController _totalHTController = TextEditingController();
  final TextEditingController _tvaController = TextEditingController();
  final TextEditingController _totalTTCController = TextEditingController();
  final TextEditingController _totalFMGController = TextEditingController();
  final TextEditingController _articleSearchController = TextEditingController();
  TextEditingController? _autocompleteController;
  final TextEditingController _uniteController = TextEditingController();
  final TextEditingController _depotController = TextEditingController(text: 'MAG');
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _searchAchatsController = TextEditingController();
  final TextEditingController _echeanceJoursController = TextEditingController();

  // Lists
  List<Frn> _fournisseurs = [];
  List<Article> _articles = [];
  List<String> _depots = [];
  List<MpData> _modesPaiement = [];
  final List<Map<String, dynamic>> _lignesAchat = [];

  // Selected values
  String? _selectedFournisseur;
  String? _selectedModePaiement;
  Article? _selectedArticle;
  String? _selectedUnite;
  String? _selectedDepot = 'MAG';
  bool _isExistingPurchase = false;
  int? _selectedRowIndex;
  String _selectedFormat = 'A6';
  SocData? _societe;
  bool _isModifyingArticle = false;
  Map<String, dynamic>? _originalArticleData;
  List<String> _achatsNumbers = [];
  final Map<String, String> _achatsStatuts = {}; // Nouveau: pour stocker les statuts
  int currentAchatIndex = -1;
  String _searchAchatsText = '';
  String _selectedStatut = 'Brouillard';
  String? _statutAchatActuel;

  List<String> _getBrouillardAchats() {
    return _achatsNumbers.where((numAchat) {
      final statut = _achatsStatuts[numAchat] ?? 'BROUILLARD';
      final matchesSearch = _searchAchatsText.isEmpty || numAchat.toLowerCase().contains(_searchAchatsText);
      return statut == 'BROUILLARD' && matchesSearch;
    }).toList();
  }

  List<String> _getJournalAchats() {
    return _achatsNumbers.where((numAchat) {
      final statut = _achatsStatuts[numAchat] ?? 'BROUILLARD';
      final matchesSearch = _searchAchatsText.isEmpty || numAchat.toLowerCase().contains(_searchAchatsText);
      return statut == 'JOURNAL' && matchesSearch;
    }).toList();
  }

  List<String> _getContrePasseAchats() {
    return _achatsNumbers.where((numAchat) {
      final statut = _achatsStatuts[numAchat] ?? 'BROUILLARD';
      final matchesSearch = _searchAchatsText.isEmpty || numAchat.toLowerCase().contains(_searchAchatsText);
      return statut == 'CONTRE-PASSÉ' && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes with tab navigation
    _nFactFocusNode = createFocusNode();
    _fournisseurFocusNode = createFocusNode();
    _articleFocusNode = createFocusNode();
    _uniteFocusNode = createFocusNode();
    _quantiteFocusNode = createFocusNode();
    _prixFocusNode = createFocusNode();
    _depotFocusNode = createFocusNode();
    _validerFocusNode = createFocusNode();
    _annulerFocusNode = createFocusNode();
    _keyboardFocusNode = createFocusNode();
    _searchAchatsFocusNode = createFocusNode();
    _echeanceJoursFocusNode = createFocusNode();

    // Listeners pour les champs d'échéance
    _dateController.addListener(_onDateChanged);
    _echeanceJoursController.addListener(_onEcheanceJoursChanged);

    _autocompleteController = TextEditingController();
    _loadData();
    _loadAchatsNumbers().then((_) => _initializeForm());

    // Ajouter des listeners pour les focus nodes
    _validerFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _annulerFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    // Focus automatique sur le KeyboardListener pour capturer les raccourcis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  void _onDateChanged() {
    if (_dateController.text.isNotEmpty) {
      _calculerEcheanceDepuisDate();
    }
  }

  void _onEcheanceJoursChanged() {
    if (_echeanceJoursController.text.isNotEmpty) {
      _calculerEcheanceDepuisJours();
    }
  }

  void _calculerEcheanceDepuisDate() {
    try {
      final dateParts = _dateController.text.split('-');
      if (dateParts.length == 3) {
        final dateFacture =
            DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

        final joursEcheance = int.tryParse(_echeanceJoursController.text) ?? 7;
        final dateEcheance = dateFacture.add(Duration(days: joursEcheance));

        setState(() {
          _echeanceController.text = app_date.AppDateUtils.formatDate(dateEcheance);
        });
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
  }

  void _calculerEcheanceDepuisJours() {
    try {
      final dateParts = _dateController.text.split('-');
      if (dateParts.length == 3) {
        final dateFacture =
            DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

        final joursEcheance = int.tryParse(_echeanceJoursController.text) ?? 7;
        final dateEcheance = dateFacture.add(Duration(days: joursEcheance));

        setState(() {
          _echeanceController.text = app_date.AppDateUtils.formatDate(dateEcheance);
        });
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
  }

  void _initializeForm() async {
    // Toujours créer un nouveau formulaire par défaut
    final now = DateTime.now();
    _dateController.text = app_date.AppDateUtils.formatDate(now);

    // Échéance par défaut : 7 jours après la date de facturation
    final echeanceDefaut = now.add(const Duration(days: 7));
    _echeanceController.text = app_date.AppDateUtils.formatDate(echeanceDefaut);
    _echeanceJoursController.text = '7';

    // Générer le prochain numéro d'achat
    final nextNum = await _getNextNumAchats();
    _numAchatsController.text = nextNum;

    // Mode de paiement par défaut "A crédit"
    _selectedModePaiement = 'A crédit';

    // Dépôt par défaut = dernier utilisé
    final lastDepot = await _getLastUsedDepot();
    _selectedDepot = lastDepot;
    _depotController.text = lastDepot;

    _tvaController.text = '0';
    _totalHTController.text = '0';
    _totalTTCController.text = '0';
    _totalFMGController.text = '0';

    // Focus automatique sur N° Facture/BL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nFactFocusNode.requestFocus();
    });
  }

  Future<String> _getLastUsedDepot() async {
    try {
      final lastDetail = await (_databaseService.database.select(_databaseService.database.detachats)
            ..orderBy([(d) => OrderingTerm.desc(d.daty)])
            ..limit(1))
          .getSingleOrNull();
      return lastDetail?.depots ?? 'MAG';
    } catch (e) {
      return 'MAG';
    }
  }

  Future<void> _loadAchatsNumbers() async {
    try {
      final achats = await _databaseService.database.select(_databaseService.database.achats).get();

      setState(() {
        // Inclure tous les achats (y compris contre-passés)
        _achatsNumbers =
            achats.where((a) => (a.numachats ?? '').isNotEmpty).map((a) => a.numachats!).toList();
        _achatsNumbers.sort((a, b) => b.compareTo(a)); // Tri décroissant

        // Charger les statuts
        _achatsStatuts.clear();
        for (var achat in achats) {
          if (achat.numachats != null) {
            if (achat.contre == '1') {
              _achatsStatuts[achat.numachats!] = 'CONTRE-PASSÉ';
            } else {
              _achatsStatuts[achat.numachats!] = achat.verification ?? 'BROUILLARD';
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _achatsNumbers = [];
        _achatsStatuts.clear();
      });
    }
  }

  List<String> _getFilteredAchatsNumbers() {
    return _achatsNumbers.where((numAchat) {
      return _searchAchatsText.isEmpty || numAchat.toLowerCase().contains(_searchAchatsText);
    }).toList();
  }

  Future<String> _getNextNumAchats() async {
    try {
      // Récupérer tous les achats et trouver le plus grand numachats
      final achats = await _databaseService.database.select(_databaseService.database.achats).get();

      if (achats.isEmpty) {
        return '2607';
      }

      // Trouver le plus grand numéro d'achat
      int maxNum = 2606;
      for (var achat in achats) {
        if (achat.numachats != null) {
          final num = int.tryParse(achat.numachats!) ?? 0;
          if (num > maxNum) {
            maxNum = num;
          }
        }
      }

      return (maxNum + 1).toString();
    } catch (e) {
      // En cas d'erreur, commencer à 2607
      return '2607';
    }
  }

  Future<void> _loadData() async {
    try {
      final fournisseurs = await _databaseService.database.getAllFournisseurs();
      final articles = await _databaseService.database.getAllArticles();
      final depots =
          await _databaseService.database.select(_databaseService.database.depots).map((d) => d.depots).get();
      final modesPaiement = await _databaseService.database.select(_databaseService.database.mp).get();
      final societe =
          await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();

      setState(() {
        _fournisseurs = fournisseurs;
        _articles = articles;
        _depots = depots.isNotEmpty ? depots.toSet().toList() : ['MAG'];
        _modesPaiement = modesPaiement;
        _societe = societe;
      });

      // Vérifier si "A crédit" existe
      if (!modesPaiement.any((mp) => mp.mp == 'A crédit')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajouter d\'abord un moyen de paiement')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _verifierEtCreerFournisseur(String nomFournisseur) async {
    if (nomFournisseur.trim().isEmpty) return;

    // Vérifier si le fournisseur existe
    final fournisseurExiste =
        _fournisseurs.any((frn) => frn.rsoc.toLowerCase() == nomFournisseur.toLowerCase());

    if (!fournisseurExiste) {
      // Afficher le modal de confirmation
      final confirmer = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Fournisseur inconnu!!'),
              content: Text('Le fournisseur "$nomFournisseur" n\'existe pas.\n\nVoulez-vous le créer?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Non'),
                ),
                TextButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Oui'),
                ),
              ],
            ),
          ) ??
          true;

      if (confirmer == true) {
        // Ouvrir le modal d'ajout de fournisseur avec le nom pré-rempli
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AddFournisseurModal(nomFournisseur: nomFournisseur),
          );
        }

        // Recharger la liste des fournisseurs
        await _loadData();

        // Chercher le fournisseur créé et le sélectionner
        final nouveauFournisseur = _fournisseurs
            .where(
              (frn) => frn.rsoc.toLowerCase().contains(nomFournisseur.toLowerCase()),
            )
            .firstOrNull;

        if (nouveauFournisseur != null) {
          setState(() {
            _selectedFournisseur = nouveauFournisseur.rsoc;
          });
        }
      } else {
        // Réinitialiser le champ fournisseur
        setState(() {
          _selectedFournisseur = null;
        });
      }
    }
  }

  void _onArticleSelected(Article? article) async {
    if (article == null) return;

    setState(() {
      _selectedArticle = article;
      // Unité u1 par défaut
      _selectedUnite = article.u1;
      // Dépôt de l'article par défaut
      _selectedDepot = article.dep ?? 'MAG';

      // Remplir automatiquement les champs
      // _uniteController.text = article.u1 ?? '';
      _depotController.text = article.dep ?? 'MAG';

      // Ne vider la quantité que si on n'est pas en mode modification
      if (!_isModifyingArticle) {
        _quantiteController.text = '';
      }
    });
  }

  Future<void> _verifierUniteArticle(String unite) async {
    if (_selectedArticle == null) return;

    // Vérifier si l'unité est valide pour cet article
    final unitesValides = [_selectedArticle!.u1, _selectedArticle!.u2, _selectedArticle!.u3]
        .where((u) => u != null && u.isNotEmpty)
        .toList();

    if (!unitesValides.contains(unite)) {
      // Afficher modal d'erreur
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unité invalide'),
          content: Text(
              'L\'unité "$unite" n\'est pas valide pour l\'article "${_selectedArticle!.designation}".\n\nUnités autorisées: ${unitesValides.join(", ")}'),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Remettre l'unité par défaut et focus sur le champ unité
      setState(() {
        _uniteController.text = '';
      });

      // Focus sur le champ unité après fermeture du modal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _uniteFocusNode.requestFocus();
      });
      return;
    }

    _onUniteChanged(unite);
  }

  void _onUniteChanged(String? unite) {
    // Vérification des prérequis : article sélectionné et unité valide
    if (_selectedArticle == null || unite == null) return;

    setState(() {
      // Mise à jour de l'unité sélectionnée
      _selectedUnite = unite;
      _uniteController.text = unite;

      // Calculer le prix selon CMUP avec conversion d'unité
      if ((_selectedArticle!.cmup ?? 0.0) == 0.0) {
        _prixController.text = '0';
      } else {
        // Convertir le CMUP selon l'unité sélectionnée
        // Le CMUP est stocké en unité de base (u3)
        double prixConverti = StockConverter.convertirPrixSelonUnite(
          article: _selectedArticle!,
          uniteSource: _selectedArticle!.u3 ?? 'Dét',
          uniteCible: unite,
          prixSource: _selectedArticle!.cmup!,
        );
        _prixController.text = NumberUtils.formatNumber(prixConverti);
      }

      // Réinitialisation de la quantité pour forcer une nouvelle saisie
      _quantiteController.text = '';
    });
  }

  List<DropdownMenuItem<String>> _getUnitsForSelectedArticle() {
    if (_selectedArticle == null) {
      return const [
        DropdownMenuItem(value: 'Pce', child: Text('Pce', style: TextStyle(fontSize: 12))),
      ];
    }

    List<DropdownMenuItem<String>> units = [];
    if (_selectedArticle!.u1?.isNotEmpty == true) {
      units.add(DropdownMenuItem(
        value: _selectedArticle!.u1,
        child: Text(_selectedArticle!.u1!, style: const TextStyle(fontSize: 12)),
      ));
    }
    if (_selectedArticle!.u2?.isNotEmpty == true) {
      units.add(DropdownMenuItem(
        value: _selectedArticle!.u2,
        child: Text(_selectedArticle!.u2!, style: const TextStyle(fontSize: 12)),
      ));
    }
    if (_selectedArticle!.u3?.isNotEmpty == true) {
      units.add(DropdownMenuItem(
        value: _selectedArticle!.u3,
        child: Text(_selectedArticle!.u3!, style: const TextStyle(fontSize: 12)),
      ));
    }

    return units.isEmpty
        ? [
            const DropdownMenuItem(value: 'Pce', child: Text('Pce', style: TextStyle(fontSize: 12))),
          ]
        : units;
  }

  void _ajouterLigne() {
    if (_selectedArticle == null) return;

    double quantite = double.tryParse(_quantiteController.text) ?? 0.0;
    double prix = NumberUtils.parseFormattedNumber(_prixController.text);
    double montant = quantite * prix;

    String designation = _selectedArticle!.designation;
    String depot = _selectedDepot ?? 'MAG';
    String unite = _selectedUnite ?? 'Pce';

    // Chercher si l'article existe déjà avec la MÊME unité et le même dépôt
    int existingIndex = _lignesAchat.indexWhere((ligne) =>
        ligne['designation'] == designation && ligne['depot'] == depot && ligne['unites'] == unite);

    setState(() {
      if (existingIndex != -1) {
        // Cumuler les quantités si même article, même unité et même dépôt
        double existingQuantite = _lignesAchat[existingIndex]['quantite'] ?? 0.0;
        double newQuantite = existingQuantite + quantite;
        double newMontant = newQuantite * prix;

        _lignesAchat[existingIndex]['quantite'] = newQuantite;
        _lignesAchat[existingIndex]['montant'] = newMontant;
      } else {
        // Ajouter nouvelle ligne pour chaque unité différente
        _lignesAchat.add({
          'designation': designation,
          'unites': unite,
          'quantite': quantite,
          'prixUnitaire': prix,
          'montant': montant,
          'depot': depot,
        });
      }
    });
    _calculerTotaux();
  }

  void _supprimerLigne(int index) {
    setState(() {
      _lignesAchat.removeAt(index);
    });
    _calculerTotaux();
  }

  void _calculerTotaux() {
    double totalHT = 0;
    for (var ligne in _lignesAchat) {
      totalHT += ligne['montant'] ?? 0;
    }

    double tva = double.tryParse(_tvaController.text) ?? 0;
    double totalTTC = totalHT + (totalHT * tva / 100);
    double totalFMG = totalTTC * 5;

    setState(() {
      _totalHTController.text = NumberUtils.formatNumber(totalHT);
      _totalTTCController.text = NumberUtils.formatNumber(totalTTC);
      _totalFMGController.text = NumberUtils.formatNumber(totalFMG);
    });
  }

  bool _isArticleFormValid() {
    return _selectedArticle != null &&
        _quantiteController.text.isNotEmpty &&
        double.tryParse(_quantiteController.text) != null &&
        double.tryParse(_quantiteController.text)! > 0;
  }

  void _validerAjout() async {
    if (_isModifyingArticle && _originalArticleData != null) {
      // En mode modification : supprimer l'ancienne ligne
      final originalIndex = _lignesAchat.indexWhere((ligne) =>
          ligne['designation'] == _originalArticleData!['designation'] &&
          ligne['unites'] == _originalArticleData!['unites'] &&
          ligne['depot'] == _originalArticleData!['depot']);

      if (originalIndex != -1) {
        _supprimerLigne(originalIndex);
      }
    }
    _ajouterLigne();
    _resetArticleForm();
  }

  void _resetArticleForm() async {
    final lastDepot = await _getLastUsedDepot();

    setState(() {
      _selectedArticle = null;
      _selectedUnite = null;
      _selectedDepot = lastDepot;
      _isModifyingArticle = false;
      _originalArticleData = null;
      _uniteController.clear();
      _depotController.text = lastDepot;
      _quantiteController.clear();
      _prixController.clear();
    });

    // Focus automatique sur Désignation Articles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _articleFocusNode.requestFocus();
    });
  }

  void _chargerLigneArticle(int index) {
    final ligne = _lignesAchat[index];

    // Trouver l'article correspondant
    Article? article = _articles
        .where(
          (a) => a.designation == ligne['designation'],
        )
        .firstOrNull;

    setState(() {
      _selectedArticle = article;
      _selectedUnite = ligne['unites'];
      _selectedDepot = ligne['depot'];
      _isModifyingArticle = true;
      _originalArticleData = Map<String, dynamic>.from(ligne);

      _uniteController.text = ligne['unites'];
      _depotController.text = ligne['depot'];
      _quantiteController.text = ligne['quantite'].toString();
      _prixController.text = NumberUtils.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0);
    });

    // Focus sur le champ désignation après chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _articleFocusNode.requestFocus();
    });
  }

  Future<void> _chargerAchatExistant(String numAchats) async {
    if (numAchats.isEmpty) {
      setState(() {
        _isExistingPurchase = false;
      });
      return;
    }

    try {
      // Rechercher l'achat principal
      final achat = await (_databaseService.database.select(_databaseService.database.achats)
            ..where((a) => a.numachats.equals(numAchats)))
          .getSingleOrNull();

      setState(() {
        _isExistingPurchase = achat != null;
        // IMPORTANT: Mettre à jour le numéro d'achat AVANT tout autre traitement
        _numAchatsController.text = numAchats;
      });

      if (achat != null) {
        // Charger les détails de l'achat
        final details = await (_databaseService.database.select(_databaseService.database.detachats)
              ..where((d) => d.numachats.equals(numAchats)))
            .get();

        setState(() {
          // Remplir les champs principaux
          _nFactController.text = achat.nfact ?? '';
          if (achat.daty != null) {
            _dateController.text = app_date.AppDateUtils.formatDate(achat.daty!);
          }
          _selectedFournisseur = achat.frns;
          _fournisseurController.text = achat.frns ?? ''; // Mettre à jour le contrôleur
          _selectedModePaiement = achat.modepai;
          if (achat.echeance != null) {
            _echeanceController.text = app_date.AppDateUtils.formatDate(achat.echeance!);

            // Calculer les jours d'échéance
            if (achat.daty != null) {
              final joursEcheance = achat.echeance!.difference(achat.daty!).inDays;
              _echeanceJoursController.text = joursEcheance.toString();
            }
          } else {
            // Valeurs par défaut si pas d'échéance
            _echeanceJoursController.text = '7';
            if (achat.daty != null) {
              final echeanceDefaut = achat.daty!.add(const Duration(days: 7));
              _echeanceController.text = app_date.AppDateUtils.formatDate(echeanceDefaut);
            }
          }
          _tvaController.text = (achat.tva ?? 0).toString();
          _statutAchatActuel = achat.verification ?? 'BROUILLARD';
          _selectedStatut = _statutAchatActuel == 'JOURNAL' ? 'Journal' : 'Brouillard';

          // Vérifier si l'achat est contre-passé
          final isContrePasse = achat.contre == '1';
          if (isContrePasse) {
            _statutAchatActuel = 'CONTRE-PASSÉ';
          }

          // Remplir les lignes d'achat
          _lignesAchat.clear();
          for (var detail in details) {
            _lignesAchat.add({
              'designation': detail.designation ?? '',
              'unites': detail.unites ?? '',
              'quantite': detail.q ?? 0.0,
              'prixUnitaire': detail.pu ?? 0.0,
              'montant': (detail.q ?? 0.0) * (detail.pu ?? 0.0),
              'depot': detail.depots ?? '',
            });
          }
        });

        _calculerTotaux();

        // Mettre à jour l'index de navigation
        currentAchatIndex = _achatsNumbers.indexOf(numAchats);

        // Donner le focus au champ Désignation Articles après le chargement
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _articleFocusNode.requestFocus();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Achat N° $numAchats non trouvé')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isExistingPurchase = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _modifierAchat() async {
    if (_selectedFournisseur == null || _nFactController.text.isEmpty || _lignesAchat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Veuillez sélectionner un fournisseur, saisir le N° Facture/BL et ajouter des articles')),
      );
      return;
    }

    // Vérifier que nous sommes bien en mode modification d'un achat existant
    if (!_isExistingPurchase || _numAchatsController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun achat sélectionné pour modification')),
        );
      }
      return;
    }

    // Confirmation avant modification
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(
            'Voulez-vous vraiment modifier l\'achat N° ${_numAchatsController.text} ?\n\nCette action mettra à jour les stocks et les CMUP.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _databaseService.database.transaction(() async {
        List<String> dateParts = _dateController.text.split('-');
        DateTime dateForDB =
            DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

        // Récupérer les anciennes lignes pour annuler leur impact sur les stocks
        final anciennesLignes = await (_databaseService.database.select(_databaseService.database.detachats)
              ..where((d) => d.numachats.equals(_numAchatsController.text)))
            .get();

        // Recharger les articles pour avoir les stocks actuels
        _articles = await _databaseService.database.getAllArticles();

        // Annuler l'impact des anciennes lignes avec conversion automatique
        for (var ancienneLigne in anciennesLignes) {
          Article? article = _articles.firstWhere(
            (a) => a.designation == ancienneLigne.designation,
            orElse: () => throw Exception('Article ${ancienneLigne.designation} non trouvé'),
          );

          // Convertir l'ancienne quantité en unités optimales pour annulation
          final conversionAnnulation = StockConverter.convertirQuantiteAchat(
            article: article,
            uniteAchat: ancienneLigne.unites ?? article.u3!,
            quantiteAchat: ancienneLigne.q ?? 0,
          );

          // Annuler les stocks articles avec conversion automatique
          final stocksActuelsArticle = StockConverter.convertirStockOptimal(
            article: article,
            quantiteU1: (article.stocksu1 ?? 0) - conversionAnnulation['u1']!,
            quantiteU2: (article.stocksu2 ?? 0) - conversionAnnulation['u2']!,
            quantiteU3: (article.stocksu3 ?? 0) - conversionAnnulation['u3']!,
          );

          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu1: Value(stocksActuelsArticle['u1']! >= 0 ? stocksActuelsArticle['u1']! : 0),
            stocksu2: Value(stocksActuelsArticle['u2']! >= 0 ? stocksActuelsArticle['u2']! : 0),
            stocksu3: Value(stocksActuelsArticle['u3']! >= 0 ? stocksActuelsArticle['u3']! : 0),
          ));

          // Annuler les stocks par dépôt avec conversion automatique
          final existingDepart = await (_databaseService.database.select(_databaseService.database.depart)
                ..where((d) =>
                    d.designation.equals(article.designation) & d.depots.equals(ancienneLigne.depots ?? '')))
              .getSingleOrNull();

          if (existingDepart != null) {
            final stocksActuelsDepot = StockConverter.convertirStockOptimal(
              article: article,
              quantiteU1: (existingDepart.stocksu1 ?? 0) - conversionAnnulation['u1']!,
              quantiteU2: (existingDepart.stocksu2 ?? 0) - conversionAnnulation['u2']!,
              quantiteU3: (existingDepart.stocksu3 ?? 0) - conversionAnnulation['u3']!,
            );

            await (_databaseService.database.update(_databaseService.database.depart)
                  ..where((d) =>
                      d.designation.equals(article.designation) &
                      d.depots.equals(ancienneLigne.depots ?? '')))
                .write(DepartCompanion(
              stocksu1: Value(stocksActuelsDepot['u1']! >= 0 ? stocksActuelsDepot['u1']! : 0),
              stocksu2: Value(stocksActuelsDepot['u2']! >= 0 ? stocksActuelsDepot['u2']! : 0),
              stocksu3: Value(stocksActuelsDepot['u3']! >= 0 ? stocksActuelsDepot['u3']! : 0),
            ));
          }

          // Recalculer le CMUP après annulation
          await _recalculerCMUPApresAnnulation(article, ancienneLigne.q ?? 0, ancienneLigne.pu ?? 0);
        }

        // Supprimer les anciennes entrées de stock
        await (_databaseService.database.delete(_databaseService.database.stocks)
              ..where((s) => s.numachats.equals(_numAchatsController.text)))
            .go();

        // Supprimer les anciennes lignes
        await (_databaseService.database.delete(_databaseService.database.detachats)
              ..where((d) => d.numachats.equals(_numAchatsController.text)))
            .go();

        // Calculer la date d'échéance
        DateTime? dateEcheance;
        if (_echeanceController.text.isNotEmpty) {
          List<String> echeanceParts = _echeanceController.text.split('-');
          dateEcheance =
              DateTime(int.parse(echeanceParts[2]), int.parse(echeanceParts[1]), int.parse(echeanceParts[0]));
        }

        // Mettre à jour l'achat principal (GARDER LE MÊME NUMÉRO)
        await (_databaseService.database.update(_databaseService.database.achats)
              ..where((a) => a.numachats.equals(_numAchatsController.text)))
            .write(AchatsCompanion(
          nfact: Value(_nFactController.text.isEmpty ? null : _nFactController.text),
          daty: Value(dateForDB),
          frns: Value(_selectedFournisseur!),
          modepai: Value(_selectedModePaiement),
          echeance: Value(dateEcheance),
          totalnt: Value(double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0.0),
          tva: Value(double.tryParse(_tvaController.text) ?? 0.0),
          totalttc: Value(double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0.0),
          verification: Value(_selectedStatut == 'Journal' ? 'JOURNAL' : 'BROUILLARD'),
        ));

        // Recharger les articles pour avoir les stocks mis à jour après annulation
        _articles = await _databaseService.database.getAllArticles();

        // Insérer les nouvelles lignes avec le MÊME numéro d'achat
        for (var ligne in _lignesAchat) {
          await _databaseService.database.into(_databaseService.database.detachats).insert(
                DetachatsCompanion.insert(
                  numachats: Value(_numAchatsController.text), // MÊME NUMÉRO
                  designation: Value(ligne['designation']),
                  unites: Value(ligne['unites']),
                  depots: Value(ligne['depot']),
                  q: Value(ligne['quantite']),
                  pu: Value(ligne['prixUnitaire']),
                  daty: Value(dateForDB),
                ),
              );

          // Mettre à jour le stock et le CMUP dans la table Articles
          Article? article = _articles.firstWhere(
            (a) => a.designation == ligne['designation'],
            orElse: () => throw Exception('Article ${ligne['designation']} non trouvé'),
          );

          // Calculer et mettre à jour le CMUP avec le calculateur amélioré
          double nouveauCMUP = await CMUPCalculator.calculerEtMettreAJourCMUP(
            designation: ligne['designation'],
            uniteAchat: ligne['unites'],
            quantiteAchat: ligne['quantite'],
            prixUnitaireAchat: ligne['prixUnitaire'],
            article: article,
          );

          // Créer nouvelle entrée de stock avec le MÊME numéro d'achat
          await _databaseService.database.into(_databaseService.database.stocks).insert(
                StocksCompanion.insert(
                  ref:
                      'ACH-${_numAchatsController.text}-${ligne['designation']}-${DateTime.now().millisecondsSinceEpoch}',
                  daty: Value(dateForDB),
                  lib: Value('Achat ${_numAchatsController.text} (Modifié)'),
                  numachats: Value(_numAchatsController.text), // MÊME NUMÉRO
                  nfact: Value(_nFactController.text.isEmpty ? null : _nFactController.text),
                  refart: Value(ligne['designation']),
                  qe: Value(ligne['quantite']),
                  entres: Value(ligne['quantite']),
                  ue: Value(ligne['unites']),
                  depots: Value(ligne['depot']),
                  pus: Value(ligne['prixUnitaire']),
                  cmup: Value(nouveauCMUP),
                  frns: Value(_selectedFournisseur!),
                  verification: Value(_selectedStatut == 'Journal' ? 'JOURNAL' : 'BROUILLARD'),
                ),
              );

          // Convertir l'achat en unités optimales
          final conversionAchat = StockConverter.convertirQuantiteAchat(
            article: article,
            uniteAchat: ligne['unites'],
            quantiteAchat: ligne['quantite'],
          );

          // Calculer les nouveaux stocks avec conversion automatique
          final stocksActuels = StockConverter.convertirStockOptimal(
            article: article,
            quantiteU1: (article.stocksu1 ?? 0) + conversionAchat['u1']!,
            quantiteU2: (article.stocksu2 ?? 0) + conversionAchat['u2']!,
            quantiteU3: (article.stocksu3 ?? 0) + conversionAchat['u3']!,
          );

          // Mettre à jour les stocks avec conversion automatique
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu1: Value(stocksActuels['u1']!),
            stocksu2: Value(stocksActuels['u2']!),
            stocksu3: Value(stocksActuels['u3']!),
          ));

          // Mettre à jour les stocks par dépôt avec conversion automatique
          final existingDepart = await (_databaseService.database.select(_databaseService.database.depart)
                ..where((d) => d.designation.equals(article.designation) & d.depots.equals(ligne['depot'])))
              .getSingleOrNull();

          if (existingDepart != null) {
            // Calculer les nouveaux stocks du dépôt avec conversion automatique
            final stocksDepotActuels = StockConverter.convertirStockOptimal(
              article: article,
              quantiteU1: (existingDepart.stocksu1 ?? 0) + conversionAchat['u1']!,
              quantiteU2: (existingDepart.stocksu2 ?? 0) + conversionAchat['u2']!,
              quantiteU3: (existingDepart.stocksu3 ?? 0) + conversionAchat['u3']!,
            );

            await (_databaseService.database.update(_databaseService.database.depart)
                  ..where((d) => d.designation.equals(article.designation) & d.depots.equals(ligne['depot'])))
                .write(DepartCompanion(
              stocksu1: Value(stocksDepotActuels['u1']!),
              stocksu2: Value(stocksDepotActuels['u2']!),
              stocksu3: Value(stocksDepotActuels['u3']!),
            ));
          } else {
            // Créer nouvelle entrée avec conversion automatique
            final stocksDepotInitiaux = StockConverter.convertirStockOptimal(
              article: article,
              quantiteU1: conversionAchat['u1']!,
              quantiteU2: conversionAchat['u2']!,
              quantiteU3: conversionAchat['u3']!,
            );

            await _databaseService.database.into(_databaseService.database.depart).insert(
                  DepartCompanion.insert(
                    designation: article.designation,
                    depots: ligne['depot'],
                    stocksu1: Value(stocksDepotInitiaux['u1']!),
                    stocksu2: Value(stocksDepotInitiaux['u2']!),
                    stocksu3: Value(stocksDepotInitiaux['u3']!),
                  ),
                );
          }
        }
      });

      // Recharger la liste des achats
      await _loadAchatsNumbers();

      // Recharger les données pour mettre à jour l'interface
      await _loadData();

      // Recalculer les totaux avec les nouvelles données
      _calculerTotaux();

      // Mettre à jour l'interface
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat modifié avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification: $e')),
        );
      }
    }
  }

  Future<void> _contrePasserAchat() async {
    if (!_isExistingPurchase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun achat sélectionné à contre-passer')),
      );
      return;
    }

    // Vérifier si l'achat est déjà contre-passé
    final achatActuel = await (_databaseService.database.select(_databaseService.database.achats)
          ..where((a) => a.numachats.equals(_numAchatsController.text)))
        .getSingleOrNull();

    if (mounted) {
      if (achatActuel?.contre == '1') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cet achat est déjà contre-passé')),
        );
        return;
      }
    }

    // Vérifier si l'achat est journalisé
    final isJournalise = achatActuel?.verification == 'JOURNAL';

    // Confirmation avec message adapté
    if (mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmation'),
          content: Text(
              'Voulez-vous vraiment contre-passer l\'achat N° ${_numAchatsController.text} ?\n\n${isJournalise ? "Cet achat journalisé sera marqué comme contre-passé et exclu des listes." : "Cet achat brouillard sera SUPPRIMÉ DÉFINITIVEMENT."}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      // Utiliser le service pour contre-passer l'achat
      if (isJournalise) {
        await _achatService.contrePasserAchatJournal(_numAchatsController.text);
      } else {
        await _achatService.contrePasserAchatBrouillard(_numAchatsController.text);
      }

      // Recharger toutes les données pour mettre à jour l'interface
      await _loadAchatsNumbers();
      await _loadData();

      // Mettre à jour l'interface pour refléter le statut contre-passé
      // Créer un nouvel achat après contre-passement
      if (mounted) {
        await _creerNouvelAchat();
      }

      if (mounted) {
        final message = isJournalise ? 'Achat contre-passé avec succès' : 'Achat supprimé définitivement';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du contre-passement: $e')),
        );
      }
    }
  }

  Future<void> _validerAchatBrouillard() async {
    if (!_isExistingPurchase || _statutAchatActuel != 'BROUILLARD') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun achat en brouillard sélectionné')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation'),
        content: Text(
            'Enregistrer l\'achat N° ${_numAchatsController.text} vers le journal ?\n\nCette action créera les mouvements de stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enregistrer')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _achatService.validerAchatBrouillard(_numAchatsController.text);

      setState(() {
        _statutAchatActuel = 'JOURNAL';
        _achatsStatuts[_numAchatsController.text] = 'JOURNAL';
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat validé avec succès'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la validation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _recalculerCMUPApresAnnulation(
      Article article, double quantiteAnnulee, double prixAnnule) async {
    // Calculer le stock total en unité de base (u3) avec conversion automatique
    double stockActuelU3 = StockConverter.calculerStockTotalU3(
      article: article,
      stockU1: article.stocksu1 ?? 0,
      stockU2: article.stocksu2 ?? 0,
      stockU3: article.stocksu3 ?? 0,
    );

    double cmupActuel = article.cmup ?? 0.0;

    // Convertir la quantité annulée en u3 pour le calcul
    double quantiteAnnuleeU3 = quantiteAnnulee;
    if (article.tu3u2 != null && article.tu2u1 != null) {
      // Supposer que le prix est en u3, ajuster si nécessaire
      quantiteAnnuleeU3 = quantiteAnnulee;
    }

    double valeurTotaleAvant = (stockActuelU3 + quantiteAnnuleeU3) * cmupActuel;
    double valeurARetirer = quantiteAnnuleeU3 * prixAnnule;
    double nouvelleValeur = valeurTotaleAvant - valeurARetirer;
    double nouveauCMUP = stockActuelU3 > 0 ? nouvelleValeur / stockActuelU3 : 0.0;

    // S'assurer que le CMUP ne devient pas négatif
    nouveauCMUP = nouveauCMUP >= 0 ? nouveauCMUP : 0.0;

    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(article.designation)))
        .write(ArticlesCompanion(cmup: Value(nouveauCMUP)));
  }

  Future<String> _getStocksToutesUnites(Article article, String depot) async {
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

  void _naviguerAchat(bool suivant) {
    final filteredNumbers = _getFilteredAchatsNumbers();
    if (filteredNumbers.isEmpty) return;

    int currentIndex = filteredNumbers.indexOf(_numAchatsController.text);
    if (currentIndex == -1) currentIndex = 0;

    if (suivant) {
      currentIndex = (currentIndex + 1) % filteredNumbers.length;
    } else {
      currentIndex = (currentIndex - 1 + filteredNumbers.length) % filteredNumbers.length;
    }

    final numAchat = filteredNumbers[currentIndex];
    _numAchatsController.text = numAchat;
    currentAchatIndex = _achatsNumbers.indexOf(numAchat);
    _chargerAchatExistant(numAchat);
  }

  Future<void> _ouvrirApercuBR() async {
    if (_lignesAchat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun article à afficher')),
      );
      return;
    }

    DateTime dateForPreview = app_date.AppDateUtils.parseDate(_dateController.text);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BonReceptionPreview(
          numAchats: _numAchatsController.text,
          nFact: _nFactController.text.isEmpty ? null : _nFactController.text,
          date: dateForPreview,
          fournisseur: _selectedFournisseur ?? '',
          modePaiement: _selectedModePaiement,
          lignesAchat: _lignesAchat,
          totalHT: double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0.0,
          tva: double.tryParse(_tvaController.text) ?? 0.0,
          totalTTC: double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0.0,
          format: _selectedFormat,
          societe: _societe,
        ),
      ),
    );
  }

  Future<void> _creerNouvelAchat() async {
    setState(() {
      _isExistingPurchase = false;
      _selectedRowIndex = null;
      _lignesAchat.clear();
      _selectedFournisseur = null;
      _selectedModePaiement = null;
      _selectedStatut = 'Brouillard';
      _statutAchatActuel = null;
    });

    // Réinitialiser tous les contrôleurs
    _nFactController.clear();
    _fournisseurController.clear();
    _tvaController.text = '0';
    _totalHTController.text = '0';
    _totalTTCController.text = '0';
    _totalFMGController.text = '0';

    // Mode de paiement par défaut "A crédit"
    _selectedModePaiement = 'A crédit';

    // Échéance par défaut = date actuelle
    final now = DateTime.now();
    _echeanceController.text = app_date.AppDateUtils.formatDate(now);

    _resetArticleForm();

    // Générer un nouveau numéro d'achat SEULEMENT pour un nouvel achat
    final nextNum = await _getNextNumAchats();
    _numAchatsController.text = nextNum;

    // Remettre la date d'aujourd'hui
    _dateController.text = app_date.AppDateUtils.formatDate(now);

    // Focus automatique sur N° Facture/BL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nFactFocusNode.requestFocus();
    });
  }

  Future<void> _validerAchat() async {
    if (_selectedFournisseur == null || _nFactController.text.isEmpty || _lignesAchat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Veuillez sélectionner un fournisseur, saisir le N° Facture/BL et ajouter des articles')),
      );
      return;
    }

    try {
      // Vérifier si le numéro d'achat existe déjà
      final existingAchat = await (_databaseService.database.select(_databaseService.database.achats)
            ..where((a) => a.numachats.equals(_numAchatsController.text)))
          .getSingleOrNull();

      if (existingAchat != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Le N° Achats ${_numAchatsController.text} existe déjà')),
          );
        }
        return;
      }

      // Convertir la date au format DateTime
      List<String> dateParts = _dateController.text.split('-');
      DateTime dateForDB =
          DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

      // Calculer la date d'échéance
      DateTime? echeanceForDB;
      if (_echeanceController.text.isNotEmpty) {
        List<String> echeanceParts = _echeanceController.text.split('-');
        echeanceForDB =
            DateTime(int.parse(echeanceParts[2]), int.parse(echeanceParts[1]), int.parse(echeanceParts[0]));
      }

      double totalHT = double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0.0;
      double tva = double.tryParse(_tvaController.text) ?? 0.0;
      double totalTTC = double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0.0;

      // Préparer les données de l'achat
      final lignesAchatData = _lignesAchat
          .map((ligne) => {
                'designation': ligne['designation'],
                'unite': ligne['unites'],
                'depot': ligne['depot'],
                'quantite': ligne['quantite'],
                'prixUnitaire': ligne['prixUnitaire'],
              })
          .toList();

      // Utiliser AchatService selon le mode
      if (_selectedStatut == 'Journal') {
        await _achatService.traiterAchatJournal(
          numAchats: _numAchatsController.text,
          nFacture: _nFactController.text.isEmpty ? null : _nFactController.text,
          date: dateForDB,
          fournisseur: _selectedFournisseur,
          modePaiement: _selectedModePaiement,
          echeance: echeanceForDB,
          totalHT: totalHT,
          totalTTC: totalTTC,
          tva: tva,
          lignesAchat: lignesAchatData,
        );
      } else {
        await _achatService.traiterAchatBrouillard(
          numAchats: _numAchatsController.text,
          nFacture: _nFactController.text.isEmpty ? null : _nFactController.text,
          date: dateForDB,
          fournisseur: _selectedFournisseur,
          modePaiement: _selectedModePaiement,
          echeance: echeanceForDB,
          totalHT: totalHT,
          totalTTC: totalTTC,
          tva: tva,
          lignesAchat: lignesAchatData,
        );
      }

      // Recharger la liste des achats
      await _loadAchatsNumbers();

      if (mounted) {
        final message = _selectedStatut == 'Journal'
            ? 'Achat enregistré et validé avec succès'
            : 'Achat enregistré en brouillard';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        if (_selectedStatut == 'Journal') {
          Navigator.of(context).pop();
        } else {
          await _creerNouvelAchat();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Erreur lors de l\'enregistrement: $e'),
            duration: const Duration(seconds: 15),
          ),
        );
      }
    }
  }

  void _handleKeyboardShortcut(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      // F3 : Enregistrer brouillard (priorité absolue, fonctionne sans focus)
      if (event.logicalKey == LogicalKeyboardKey.f3) {
        if (_isExistingPurchase && _statutAchatActuel == 'BROUILLARD') {
          _validerAchatBrouillard();
        }
        return; // Empêcher d'autres traitements
      }
      // Ctrl+S : Enregistrer/Modifier
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
        if (_isExistingPurchase && _statutAchatActuel != 'JOURNAL') {
          _modifierAchat();
        } else if (!_isExistingPurchase) {
          _validerAchat();
        }
      }
      // Ctrl+N : Créer nouveau
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
        _creerNouvelAchat();
      }
      // Ctrl+P : Aperçu BR
      else if (isCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyP) {
        _ouvrirApercuBR();
      }
      // Ctrl+Shift+P : Imprimer BR
      else if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyP) {
        if (_lignesAchat.isNotEmpty) {
          _imprimerBonReception();
        }
      }
      // Ctrl+D : Contre-passer
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyD) {
        _contrePasserAchat();
      }
      // Ctrl+F : Focus sur recherche
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchAchatsFocusNode.requestFocus();
      }
      // Ctrl+J : Focus sur Echéance (Jours)
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyJ) {
        _echeanceJoursFocusNode.requestFocus();
      }
      // Ctrl+L : Aller au premier achat Journal
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyL) {
        final journalAchats = _getJournalAchats();
        if (journalAchats.isNotEmpty) {
          _chargerAchatExistant(journalAchats.first);
        }
      }
      // F1 : Achat précédent
      else if (event.logicalKey == LogicalKeyboardKey.f1) {
        if (_achatsNumbers.isNotEmpty) _naviguerAchat(false);
      }
      // F2 : Achat suivant
      else if (event.logicalKey == LogicalKeyboardKey.f2) {
        if (_achatsNumbers.isNotEmpty) _naviguerAchat(true);
      }
    }
  }

  PdfPageFormat get _pdfPageFormat {
    switch (_selectedFormat) {
      case 'A4':
        return PdfPageFormat.a4;
      case 'A6':
        return PdfPageFormat.a6;
      default:
        return PdfPageFormat.a5; // A5
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _handleKeyboardShortcut,
        child: Dialog(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.8,
            minWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.99,
          ),
          backgroundColor: Colors.grey[100],
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              color: Colors.grey[100],
            ),
            child: Row(
              children: [
                // Liste des achats à gauche
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.list, size: 16),
                            SizedBox(width: 8),
                            Text('Liste des achats',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: TextField(
                          controller: _searchAchatsController,
                          focusNode: _searchAchatsFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Rechercher... (Ctrl+F)',
                            prefixIcon: Icon(Icons.search, size: 16),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          style: const TextStyle(fontSize: 11),
                          onChanged: (value) {
                            setState(() {
                              _searchAchatsText = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _achatsNumbers.isEmpty
                            ? const Center(child: Text('Aucun achat', style: TextStyle(fontSize: 11)))
                            : Column(
                                children: [
                                  // Section Brouillard
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_note, size: 14, color: Colors.orange.shade700),
                                        const SizedBox(width: 4),
                                        Text('Brouillard',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade700)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: ListView.builder(
                                      itemCount: _getBrouillardAchats().length,
                                      itemBuilder: (context, index) {
                                        final numAchat = _getBrouillardAchats()[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: _numAchatsController.text == numAchat
                                                ? Colors.orange.shade100
                                                : null,
                                            border: Border(
                                                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            title: Text('N° $numAchat', style: const TextStyle(fontSize: 11)),
                                            onTap: () => _chargerAchatExistant(numAchat),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Section Journal
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Text('Journal (Ctrl + L)',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: ListView.builder(
                                      itemCount: _getJournalAchats().length,
                                      itemBuilder: (context, index) {
                                        final numAchat = _getJournalAchats()[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: _numAchatsController.text == numAchat
                                                ? Colors.green.shade100
                                                : null,
                                            border: Border(
                                                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            title: Text('N° $numAchat', style: const TextStyle(fontSize: 11)),
                                            onTap: () => _chargerAchatExistant(numAchat),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Section Contre-passé
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.block, size: 14, color: Colors.red.shade700),
                                        const SizedBox(width: 4),
                                        Text('Contre-passé',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade700)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: ListView.builder(
                                      itemCount: _getContrePasseAchats().length,
                                      itemBuilder: (context, index) {
                                        final numAchat = _getContrePasseAchats()[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: _numAchatsController.text == numAchat
                                                ? Colors.red.shade100
                                                : null,
                                            border: Border(
                                                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            title: Text('N° $numAchat', style: const TextStyle(fontSize: 11)),
                                            onTap: () => _chargerAchatExistant(numAchat),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                // Formulaire principal à droite
                Expanded(
                  child: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      children: [
                        // Title bar with close button
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
                                      const Text(
                                        'Achat fournisseurs',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (_isExistingPurchase && _statutAchatActuel != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statutAchatActuel == 'JOURNAL'
                                                ? Colors.green
                                                : _statutAchatActuel == 'CONTRE-PASSÉ'
                                                    ? Colors.red
                                                    : Colors.orange,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _statutAchatActuel == 'JOURNAL'
                                                ? 'J'
                                                : _statutAchatActuel == 'CONTRE-PASSÉ'
                                                    ? 'CP'
                                                    : 'B',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              ExcludeFocus(
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Top section with form fields
                        Container(
                          color: const Color(0xFFE6E6FA),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              // Left side with Enregistrement button and Journal dropdown
                              ExcludeFocus(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 120,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                      color: Colors.green,
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
                                        initialValue: _selectedStatut,
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          fillColor: _selectedStatut == 'Journal'
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100,
                                          filled: true,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'Journal',
                                              child: Text('Journal', style: TextStyle(fontSize: 12))),
                                          DropdownMenuItem(
                                              value: 'Brouillard',
                                              child: Text('Brouillard', style: TextStyle(fontSize: 12))),
                                        ],
                                        onChanged: _isExistingPurchase
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _selectedStatut = value ?? 'Brouillard';
                                                });
                                              },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              // Form fields
                              Expanded(
                                child: Column(
                                  children: [
                                    // First row: N°Achats, Date et N° Facture
                                    Row(
                                      children: [
                                        const ExcludeFocus(
                                            child: Text('N° Achats', style: TextStyle(fontSize: 12))),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 100,
                                          height: 25,
                                          child: ExcludeFocus(
                                            child: TextField(
                                              textAlign: TextAlign.center,
                                              controller: _numAchatsController,
                                              readOnly: true,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                fillColor: Color(0xFFF5F5F5),
                                                filled: true,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Expanded(child: SizedBox()),
                                        const ExcludeFocus(
                                            child: Text('Date', style: TextStyle(fontSize: 12))),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 140,
                                          height: 25,
                                          child: ExcludeFocus(
                                            child: TextField(
                                              controller: _dateController,
                                              readOnly: true,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                suffixIcon: Icon(Icons.calendar_today, size: 16),
                                              ),
                                              onTap: () async {
                                                final date = await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2100),
                                                );
                                                if (date != null) {
                                                  _dateController.text =
                                                      app_date.AppDateUtils.formatDate(date);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const ExcludeFocus(
                                            child: Text('N° Facture/ BL', style: TextStyle(fontSize: 12))),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: SizedBox(
                                            width: 150,
                                            height: 25,
                                            child: Focus(
                                              onKeyEvent: (node, event) {
                                                if (event is KeyDownEvent &&
                                                    event.logicalKey == LogicalKeyboardKey.tab) {
                                                  _fournisseurFocusNode.requestFocus();
                                                  return KeyEventResult.handled;
                                                }
                                                return KeyEventResult.ignored;
                                              },
                                              child: TextField(
                                                textAlign: TextAlign.center,
                                                controller: _nFactController,
                                                focusNode: _nFactFocusNode,
                                                enabled: _statutAchatActuel != 'JOURNAL',
                                                onSubmitted: (_) => _fournisseurFocusNode.requestFocus(),
                                                decoration: InputDecoration(
                                                  border: const OutlineInputBorder(),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  fillColor: _statutAchatActuel == 'JOURNAL'
                                                      ? Colors.grey.shade200
                                                      : null,
                                                  filled: _statutAchatActuel == 'JOURNAL',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Second row: Label et champ Formulaire
                                    Row(
                                      children: [
                                        const ExcludeFocus(
                                            child: Text('Fournisseurs', style: TextStyle(fontSize: 12))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SizedBox(
                                            height: 30,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Focus(
                                                    onFocusChange: (hasFocus) {
                                                      if (!hasFocus &&
                                                          _fournisseurController.text.isNotEmpty) {
                                                        _verifierEtCreerFournisseur(
                                                            _fournisseurController.text);
                                                      }
                                                    },
                                                    onKeyEvent: (node, event) {
                                                      if (event is KeyDownEvent &&
                                                          event.logicalKey == LogicalKeyboardKey.tab) {
                                                        final isShiftPressed = HardwareKeyboard
                                                                .instance.logicalKeysPressed
                                                                .contains(LogicalKeyboardKey.shiftLeft) ||
                                                            HardwareKeyboard.instance.logicalKeysPressed
                                                                .contains(LogicalKeyboardKey.shiftRight);

                                                        if (isShiftPressed) {
                                                          _nFactFocusNode.requestFocus();
                                                        } else {
                                                          _articleFocusNode.requestFocus();
                                                        }
                                                        return KeyEventResult.handled;
                                                      }
                                                      return KeyEventResult.ignored;
                                                    },
                                                    child: EnhancedAutocomplete<Frn>(
                                                      controller: _fournisseurController,
                                                      focusNode: _fournisseurFocusNode,
                                                      options: _fournisseurs,
                                                      displayStringForOption: (frn) => frn.rsoc,
                                                      onSelected: (frn) {
                                                        if (_statutAchatActuel != 'JOURNAL') {
                                                          setState(() {
                                                            _selectedFournisseur = frn.rsoc;
                                                          });
                                                          _articleFocusNode.requestFocus();
                                                        }
                                                      },
                                                      onFieldSubmitted: (_) =>
                                                          _articleFocusNode.requestFocus(),
                                                      hintText:
                                                          'Rechercher fournisseur... (← → pour naviguer)',
                                                      decoration: InputDecoration(
                                                        border: const OutlineInputBorder(),
                                                        contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 4, vertical: 2),
                                                        fillColor: _statutAchatActuel == 'JOURNAL'
                                                            ? Colors.grey.shade200
                                                            : null,
                                                        filled: _statutAchatActuel == 'JOURNAL',
                                                      ),
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
                              // Désignation Articles column
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Désignation Articles', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 30,
                                      child: ArticleNavigationAutocomplete(
                                        articles: _articles,
                                        initialArticle: _lignesAchat.isNotEmpty
                                            ? _articles
                                                .where(
                                                    (a) => a.designation == _lignesAchat.last['designation'])
                                                .firstOrNull
                                            : null,
                                        selectedArticle: _selectedArticle, // Ajouter la synchronisation
                                        onArticleChanged: _onArticleSelected,
                                        focusNode: _articleFocusNode,
                                        enabled: _statutAchatActuel != 'JOURNAL',
                                        hintText: 'Rechercher article... (← → pour naviguer)',
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          fillColor:
                                              _statutAchatActuel == 'JOURNAL' ? Colors.grey.shade200 : null,
                                          filled: _statutAchatActuel == 'JOURNAL',
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                        onTabPressed: () => _uniteFocusNode.requestFocus(),
                                        onShiftTabPressed: () => _fournisseurFocusNode.requestFocus(),
                                      ),
                                    ),
                                    // Affichage des unités disponibles et stock
                                    if (_selectedArticle == null) ...[
                                      const SizedBox(height: 19),
                                    ],
                                    if (_selectedArticle != null) ...[
                                      const SizedBox(height: 2),
                                      if (_selectedDepot != null)
                                        FutureBuilder<String>(
                                          future: _getStocksToutesUnites(_selectedArticle!, _selectedDepot!),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                              return Text(
                                                'Stock: ${snapshot.data}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Unités column
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Unités', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 30,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Focus(
                                              onFocusChange: (hasFocus) {
                                                if (!hasFocus &&
                                                    _uniteController.text.isNotEmpty &&
                                                    _selectedArticle != null &&
                                                    _statutAchatActuel != 'JOURNAL') {
                                                  _verifierUniteArticle(_uniteController.text);
                                                }
                                              },
                                              onKeyEvent: (node, event) {
                                                if (event is KeyDownEvent &&
                                                    event.logicalKey == LogicalKeyboardKey.tab) {
                                                  final isShiftPressed = HardwareKeyboard
                                                          .instance.logicalKeysPressed
                                                          .contains(LogicalKeyboardKey.shiftLeft) ||
                                                      HardwareKeyboard.instance.logicalKeysPressed
                                                          .contains(LogicalKeyboardKey.shiftRight);

                                                  if (isShiftPressed) {
                                                    _articleFocusNode.requestFocus();
                                                  } else {
                                                    _quantiteFocusNode.requestFocus();
                                                  }
                                                  return KeyEventResult.handled;
                                                }
                                                return KeyEventResult.ignored;
                                              },
                                              child: EnhancedAutocomplete<String>(
                                                controller: _uniteController,
                                                focusNode: _uniteFocusNode,
                                                enabled: _selectedArticle != null &&
                                                    _statutAchatActuel != 'JOURNAL',
                                                options: _getUnitsForSelectedArticle()
                                                    .map((item) => item.value!)
                                                    .toList(),
                                                displayStringForOption: (unite) => unite,
                                                onSelected: (unite) {
                                                  if (_selectedArticle != null &&
                                                      _statutAchatActuel != 'JOURNAL') {
                                                    _verifierUniteArticle(unite);
                                                    _quantiteFocusNode.requestFocus();
                                                  }
                                                },
                                                onTabPressed: () => _quantiteFocusNode.requestFocus(),
                                                onShiftTabPressed: () => _articleFocusNode.requestFocus(),
                                                onFieldSubmitted: (_) => _quantiteFocusNode.requestFocus(),
                                                hintText: 'Unité...',
                                                decoration: InputDecoration(
                                                  border: const OutlineInputBorder(),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  fillColor: _selectedArticle == null ||
                                                          _statutAchatActuel == 'JOURNAL'
                                                      ? Colors.grey.shade200
                                                      : null,
                                                  filled: _selectedArticle == null ||
                                                      _statutAchatActuel == 'JOURNAL',
                                                ),
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 19),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Quantités column
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Quantités', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 30,
                                      child: Focus(
                                        onKeyEvent: (node, event) {
                                          if (event is KeyDownEvent &&
                                              event.logicalKey == LogicalKeyboardKey.tab) {
                                            final isShiftPressed = HardwareKeyboard
                                                    .instance.logicalKeysPressed
                                                    .contains(LogicalKeyboardKey.shiftLeft) ||
                                                HardwareKeyboard.instance.logicalKeysPressed
                                                    .contains(LogicalKeyboardKey.shiftRight);

                                            if (isShiftPressed) {
                                              _uniteFocusNode.requestFocus();
                                            } else {
                                              _prixFocusNode.requestFocus();
                                            }
                                            return KeyEventResult.handled;
                                          }
                                          return KeyEventResult.ignored;
                                        },
                                        child: TextField(
                                          controller: _quantiteController,
                                          focusNode: _quantiteFocusNode,
                                          readOnly:
                                              _selectedArticle == null || _statutAchatActuel == 'JOURNAL',
                                          onSubmitted: (_) => _prixFocusNode.requestFocus(),
                                          decoration: InputDecoration(
                                            border: const OutlineInputBorder(),
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            fillColor:
                                                _selectedArticle == null || _statutAchatActuel == 'JOURNAL'
                                                    ? Colors.grey.shade200
                                                    : null,
                                            filled:
                                                _selectedArticle == null || _statutAchatActuel == 'JOURNAL',
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 19),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // P.U HT column
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('P.U HT', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 30,
                                      child: Focus(
                                        onKeyEvent: (node, event) {
                                          if (event is KeyDownEvent &&
                                              event.logicalKey == LogicalKeyboardKey.tab) {
                                            final isShiftPressed = HardwareKeyboard
                                                    .instance.logicalKeysPressed
                                                    .contains(LogicalKeyboardKey.shiftLeft) ||
                                                HardwareKeyboard.instance.logicalKeysPressed
                                                    .contains(LogicalKeyboardKey.shiftRight);

                                            if (isShiftPressed) {
                                              _quantiteFocusNode.requestFocus();
                                            } else {
                                              _depotFocusNode.requestFocus();
                                            }
                                            return KeyEventResult.handled;
                                          }
                                          return KeyEventResult.ignored;
                                        },
                                        child: TextField(
                                          controller: _prixController,
                                          focusNode: _prixFocusNode,
                                          readOnly:
                                              _selectedArticle == null || _statutAchatActuel == 'JOURNAL',
                                          onSubmitted: (_) => _depotFocusNode.requestFocus(),
                                          decoration: InputDecoration(
                                            border: const OutlineInputBorder(),
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            fillColor:
                                                _selectedArticle == null || _statutAchatActuel == 'JOURNAL'
                                                    ? Colors.grey.shade200
                                                    : null,
                                            filled:
                                                _selectedArticle == null || _statutAchatActuel == 'JOURNAL',
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 19),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Dépôts column
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Dépôts', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 30,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Focus(
                                              onKeyEvent: (node, event) {
                                                if (event is KeyDownEvent &&
                                                    event.logicalKey == LogicalKeyboardKey.tab) {
                                                  final isShiftPressed = HardwareKeyboard
                                                          .instance.logicalKeysPressed
                                                          .contains(LogicalKeyboardKey.shiftLeft) ||
                                                      HardwareKeyboard.instance.logicalKeysPressed
                                                          .contains(LogicalKeyboardKey.shiftRight);

                                                  if (isShiftPressed) {
                                                    _prixFocusNode.requestFocus();
                                                  } else {
                                                    if (_isArticleFormValid() &&
                                                        _statutAchatActuel != 'JOURNAL') {
                                                      _validerFocusNode.requestFocus();
                                                    } else {
                                                      _nFactFocusNode.requestFocus();
                                                    }
                                                  }
                                                  return KeyEventResult.handled;
                                                }
                                                return KeyEventResult.ignored;
                                              },
                                              child: EnhancedAutocomplete<String>(
                                                controller: _depotController,
                                                focusNode: _depotFocusNode,
                                                options: _depots,
                                                displayStringForOption: (depot) => depot,
                                                onSelected: (depot) {
                                                  if (_statutAchatActuel != 'JOURNAL') {
                                                    setState(() {
                                                      _selectedDepot = depot;
                                                    });
                                                    if (_isArticleFormValid()) {
                                                      _validerFocusNode.requestFocus();
                                                    } else {
                                                      _nFactFocusNode.requestFocus();
                                                    }
                                                  }
                                                },
                                                onTabPressed: () {
                                                  if (_isArticleFormValid() &&
                                                      _statutAchatActuel != 'JOURNAL') {
                                                    _validerFocusNode.requestFocus();
                                                  } else {
                                                    _nFactFocusNode.requestFocus();
                                                  }
                                                },
                                                onShiftTabPressed: () => _prixFocusNode.requestFocus(),
                                                onSubmitted: (_) {
                                                  if (_isArticleFormValid() &&
                                                      _statutAchatActuel != 'JOURNAL') {
                                                    _validerFocusNode.requestFocus();
                                                  } else {
                                                    _nFactFocusNode.requestFocus();
                                                  }
                                                },
                                                hintText: 'Dépôt...',
                                                decoration: InputDecoration(
                                                  border: const OutlineInputBorder(),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  fillColor: _statutAchatActuel == 'JOURNAL'
                                                      ? Colors.grey.shade200
                                                      : null,
                                                  filled: _statutAchatActuel == 'JOURNAL',
                                                ),
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 19),
                                  ],
                                ),
                              ),
                              if (_isArticleFormValid() && _statutAchatActuel != 'JOURNAL') ...[
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            Focus(
                                              focusNode: _validerFocusNode,
                                              onKeyEvent: (node, event) {
                                                if (event is KeyDownEvent) {
                                                  if (event.logicalKey == LogicalKeyboardKey.tab) {
                                                    final isShiftPressed = HardwareKeyboard
                                                            .instance.logicalKeysPressed
                                                            .contains(LogicalKeyboardKey.shiftLeft) ||
                                                        HardwareKeyboard.instance.logicalKeysPressed
                                                            .contains(LogicalKeyboardKey.shiftRight);

                                                    if (isShiftPressed) {
                                                      _depotFocusNode.requestFocus();
                                                    } else {
                                                      _annulerFocusNode.requestFocus();
                                                    }
                                                    return KeyEventResult.handled;
                                                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                                                    if (_validerFocusNode.hasFocus) {
                                                      _validerAjout();
                                                    }
                                                    return KeyEventResult.handled;
                                                  }
                                                }
                                                return KeyEventResult.ignored;
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: _validerFocusNode.hasFocus
                                                      ? Border.all(color: Colors.blue, width: 3)
                                                      : null,
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: _validerFocusNode.hasFocus
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.blue.withValues(alpha: 0.3),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: _validerAjout,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _validerFocusNode.hasFocus
                                                        ? Colors.green[600]
                                                        : Colors.green,
                                                    foregroundColor: Colors.white,
                                                    minimumSize: const Size(60, 35),
                                                    elevation: _validerFocusNode.hasFocus ? 4 : 2,
                                                  ),
                                                  child: Text(
                                                    _validerFocusNode.hasFocus ? 'Ajouter ↵' : 'Ajouter',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: _validerFocusNode.hasFocus
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        Column(
                                          children: [
                                            Focus(
                                              focusNode: _annulerFocusNode,
                                              onKeyEvent: (node, event) {
                                                if (event is KeyDownEvent) {
                                                  if (event.logicalKey == LogicalKeyboardKey.tab) {
                                                    final isShiftPressed = HardwareKeyboard
                                                            .instance.logicalKeysPressed
                                                            .contains(LogicalKeyboardKey.shiftLeft) ||
                                                        HardwareKeyboard.instance.logicalKeysPressed
                                                            .contains(LogicalKeyboardKey.shiftRight);

                                                    if (isShiftPressed) {
                                                      _validerFocusNode.requestFocus();
                                                    } else {
                                                      _nFactFocusNode.requestFocus();
                                                    }
                                                    return KeyEventResult.handled;
                                                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                                                    if (_annulerFocusNode.hasFocus) {
                                                      _resetArticleForm();
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
                                                            color: Colors.blue.withValues(alpha: 0.3),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: _resetArticleForm,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _annulerFocusNode.hasFocus
                                                        ? Colors.orange[600]
                                                        : Colors.orange,
                                                    foregroundColor: Colors.white,
                                                    minimumSize: const Size(60, 35),
                                                    elevation: _annulerFocusNode.hasFocus ? 4 : 2,
                                                  ),
                                                  child: Text(
                                                    _annulerFocusNode.hasFocus ? 'Annuler ↵' : 'Annuler',
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
                                            SizedBox(height: 16),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Articles table
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              color: Colors.white,
                            ),
                            child: Column(
                              children: [
                                // Table header
                                Container(
                                  height: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[300],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: Colors.grey, width: 1),
                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                          ),
                                        ),
                                        child: const Text(
                                          'ACTION',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
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
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                                            'UNITE',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                                            'QUANTITE',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                                            'PRIX UNITAIRE',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey, width: 1),
                                            ),
                                          ),
                                          child: const Text(
                                            'DEPOT',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Table content
                                Expanded(
                                  child: _lignesAchat.isEmpty
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
                                          itemCount: _lignesAchat.length,
                                          itemExtent: 18,
                                          itemBuilder: (context, index) {
                                            final ligne = _lignesAchat[index];
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedRowIndex = index;
                                                });
                                              },
                                              onSecondaryTapUp: _statutAchatActuel == 'JOURNAL'
                                                  ? null
                                                  : (details) {
                                                      showMenu(
                                                        context: context,
                                                        position: RelativeRect.fromLTRB(
                                                          details.globalPosition.dx,
                                                          details.globalPosition.dy,
                                                          details.globalPosition.dx,
                                                          details.globalPosition.dy,
                                                        ),
                                                        items: [
                                                          const PopupMenuItem(
                                                            value: 'modifier_ligne',
                                                            child: Text('Modifier',
                                                                style: TextStyle(fontSize: 12)),
                                                          ),
                                                          const PopupMenuItem(
                                                            value: 'supprimer_ligne',
                                                            child: Text('Supprimer',
                                                                style: TextStyle(fontSize: 12)),
                                                          ),
                                                        ],
                                                      ).then((value) {
                                                        if (value == 'modifier_ligne') {
                                                          _chargerLigneArticle(index);
                                                        } else if (value == 'supprimer_ligne') {
                                                          _supprimerLigne(index);
                                                        }
                                                      });
                                                    },
                                              child: Container(
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: _selectedRowIndex == index
                                                      ? Colors.blue[200]
                                                      : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      alignment: Alignment.center,
                                                      decoration: const BoxDecoration(
                                                        border: Border(
                                                          right: BorderSide(color: Colors.grey, width: 1),
                                                          bottom: BorderSide(color: Colors.grey, width: 1),
                                                        ),
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(Icons.close, size: 12),
                                                        onPressed: _statutAchatActuel == 'JOURNAL'
                                                            ? null
                                                            : () => _supprimerLigne(index),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Container(
                                                        padding: const EdgeInsets.only(left: 4),
                                                        alignment: Alignment.centerLeft,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            right: BorderSide(color: Colors.grey, width: 1),
                                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          ligne['designation'] ?? '',
                                                          style: const TextStyle(fontSize: 11),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
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
                                                          ligne['unites'] ?? '',
                                                          style: const TextStyle(fontSize: 11),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
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
                                                          (ligne['quantite'] as double?)
                                                                  ?.round()
                                                                  .toString() ??
                                                              '0',
                                                          style: const TextStyle(fontSize: 11),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
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
                                                          NumberUtils.formatNumber(
                                                              ligne['prixUnitaire']?.toDouble() ?? 0),
                                                          style: const TextStyle(fontSize: 11),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
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
                                                          NumberUtils.formatNumber(
                                                              ligne['montant']?.toDouble() ?? 0),
                                                          style: const TextStyle(fontSize: 11),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(color: Colors.grey, width: 1),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          ligne['depot'] ?? '',
                                                          style: const TextStyle(fontSize: 11),
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
                        ),

                        // Bottom section
                        Container(
                          color: const Color(0xFFE6E6FA),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // Left side - Payment info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Mode de paiement', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 120,
                                          height: 25,
                                          child: DropdownButtonFormField<String>(
                                            alignment: AlignmentGeometry.center,
                                            initialValue: _selectedModePaiement,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            ),
                                            items:
                                                _modesPaiement.where((mp) => mp.mp == 'A crédit').map((mp) {
                                              return DropdownMenuItem<String>(
                                                alignment: AlignmentGeometry.center,
                                                value: mp.mp,
                                                child: Text(mp.mp, style: const TextStyle(fontSize: 12)),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedModePaiement = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text('Echéance (Date)', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 137,
                                          height: 25,
                                          child: TextField(
                                            cursorHeight: 16,
                                            controller: _echeanceController,
                                            textAlign: TextAlign.center,
                                            readOnly: true,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              suffixIcon: Icon(Icons.calendar_today, size: 16),
                                            ),
                                            onTap: () async {
                                              final date = await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100),
                                              );
                                              if (date != null) {
                                                _echeanceController.text =
                                                    app_date.AppDateUtils.formatDate(date);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text('Echéance (Jours)', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 135,
                                          height: 25,
                                          child: TextField(
                                            style: const TextStyle(fontSize: 14),
                                            cursorHeight: 14,
                                            controller: _echeanceJoursController,
                                            focusNode: _echeanceJoursFocusNode,
                                            textAlign: TextAlign.center,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              hintText: 'Ctrl+J',
                                              hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                              suffixIcon: Icon(Icons.access_time_rounded, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 32),

                              // Right side - Totals
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Total HT', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 100,
                                        height: 25,
                                        child: TextField(
                                          controller: _totalHTController,
                                          textAlign: TextAlign.right,
                                          readOnly: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text('TVA', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 100,
                                        height: 25,
                                        child: TextField(
                                          controller: _tvaController,
                                          textAlign: TextAlign.right,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          ),
                                          onChanged: (value) => _calculerTotaux(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text('Total TTC', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 100,
                                        height: 25,
                                        child: TextField(
                                          controller: _totalTTCController,
                                          textAlign: TextAlign.right,
                                          readOnly: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text('Total en FMG',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 16),
                                      Container(
                                        alignment: Alignment.centerRight,
                                        constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
                                        height: 25,
                                        child: TextField(
                                          controller: _totalFMGController,
                                          textAlign: TextAlign.right,
                                          readOnly: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action buttons
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                            color: Color(0xFFFFB6C1),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: SingleChildScrollView(
                            child: Row(
                              spacing: 4,
                              children: [
                                Tooltip(
                                  message: 'Achat précédent (F1)',
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: ElevatedButton(
                                      onPressed:
                                          _achatsNumbers.isNotEmpty ? () => _naviguerAchat(false) : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(30, 30),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Achat suivant (F2)',
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: ElevatedButton(
                                      onPressed:
                                          _achatsNumbers.isNotEmpty ? () => _naviguerAchat(true) : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(30, 30),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isExistingPurchase) ...[
                                  Tooltip(
                                    message: 'Créer nouveau (Ctrl+N)',
                                    child: ElevatedButton(
                                      onPressed: _creerNouvelAchat,
                                      style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
                                      child: const Text('Créer (Ctrl+N)', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  if (_statutAchatActuel == 'BROUILLARD') ...[
                                    Tooltip(
                                      message: 'Enregistrer brouillard (F3)',
                                      child: ElevatedButton(
                                        onPressed: _validerAchatBrouillard,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(80, 30),
                                        ),
                                        child: const Text('Enregistrer Brouillard (F3)',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ],
                                if (_isExistingPurchase) ...[
                                  Tooltip(
                                    message: 'Contre-passer (Ctrl+D)',
                                    child: ElevatedButton(
                                      onPressed:
                                          _statutAchatActuel == 'CONTRE-PASSÉ' ? null : _contrePasserAchat,
                                      style: ElevatedButton.styleFrom(minimumSize: const Size(80, 30)),
                                      child: const Text('Contre Passer', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                                Tooltip(
                                  message: _isExistingPurchase ? 'Modifier (Ctrl+S)' : 'Enregistrer (Ctrl+S)',
                                  child: ElevatedButton(
                                    onPressed: _isExistingPurchase &&
                                            (_statutAchatActuel == 'JOURNAL' ||
                                                _statutAchatActuel == 'CONTRE-PASSÉ')
                                        ? null
                                        : (_isExistingPurchase ? _modifierAchat : _validerAchat),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isExistingPurchase ? Colors.blue : Colors.green,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(60, 30),
                                    ),
                                    child: Text(
                                        _isExistingPurchase ? 'Modifier(Ctrl+S)' : 'Enregistrer (Ctrl+S)',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  style: ButtonStyle(
                                      padding: WidgetStateProperty.fromMap({
                                    WidgetState.hovered: const EdgeInsets.all(0),
                                    WidgetState.focused: const EdgeInsets.all(0),
                                    WidgetState.pressed: const EdgeInsets.all(0),
                                  })),
                                  menuPadding: EdgeInsets.all(2),
                                  initialValue: _selectedFormat,
                                  onSelected: (String format) {
                                    setState(() {
                                      _selectedFormat = format;
                                    });
                                  },
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
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 60,
                                      minHeight: 18,
                                      maxHeight: 30,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.brown,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.format_size, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(_selectedFormat,
                                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Aperçu BR',
                                  child: ElevatedButton(
                                    onPressed: _lignesAchat.isNotEmpty ? _ouvrirApercuBR : null,
                                    style: ElevatedButton.styleFrom(minimumSize: const Size(70, 30)),
                                    child: const Text('Aperçu BR', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Imprimer BR (Ctrl+P)',
                                  child: ElevatedButton(
                                    onPressed: _lignesAchat.isNotEmpty ? _imprimerBonReception : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(70, 30),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.print, size: 16),
                                        SizedBox(width: 8),
                                        Text(
                                          "Imprimer BR (Ctrl+P)",
                                          style: TextStyle(fontSize: 12),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Tooltip(
                                  message: 'Fermer (Echap)',
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
                                    child: const Text('Fermer', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _imprimerBonReception() async {
    if (_lignesAchat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun article à imprimer')),
      );
      return;
    }

    try {
      final pdf = await _generateBonReceptionPdf();
      final bytes = await pdf.save();

      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;

      if (defaultPrinter != null) {
        await Printing.directPrintPdf(
          printer: defaultPrinter,
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'BR_${_numAchatsController.text}_${_dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'BR_${_numAchatsController.text}_${_dateController.text.replaceAll('/', '-')}.pdf',
          format: _selectedFormat == 'A4'
              ? PdfPageFormat.a4
              : (_selectedFormat == 'A6' ? PdfPageFormat.a6 : PdfPageFormat.a5),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bon de réception envoyé à l\'imprimante par défaut')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'impression: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<pw.Document> _generateBonReceptionPdf() async {
    final pdf = pw.Document();
    final pdfFontSize = _selectedFormat == 'A6' ? 8.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);
    final pdfHeaderFontSize = _selectedFormat == 'A6' ? 8.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);
    final pdfPadding = _selectedFormat == 'A6' ? 8.0 : (_selectedFormat == 'A5' ? 10.0 : 12.0);

    // Calculer le nombre de lignes par page
    final int maxLinesPerPage = _selectedFormat == 'A6' ? 25 : (_selectedFormat == 'A5' ? 30 : 35);
    final int articlePages = (_lignesAchat.length / maxLinesPerPage).ceil().clamp(1, double.infinity).toInt();

    // Calculer l'espace disponible sur la dernière page en lignes équivalentes
    final int lastPageLines = _lignesAchat.isEmpty
        ? 0
        : (_lignesAchat.length % maxLinesPerPage == 0
            ? maxLinesPerPage
            : _lignesAchat.length % maxLinesPerPage);
    final int emptyLinesOnLastPage = maxLinesPerPage - lastPageLines;

    // Estimation de l'espace nécessaire en nombre de lignes équivalentes
    final int totalsEquivalentLines = _selectedFormat == 'A6' ? 8 : (_selectedFormat == 'A5' ? 7 : 6);
    final int signaturesEquivalentLines = _selectedFormat == 'A6' ? 5 : (_selectedFormat == 'A5' ? 4 : 4);

    bool canFitTotalsOnLastPage = emptyLinesOnLastPage >= totalsEquivalentLines;
    bool canFitBothOnLastPage = emptyLinesOnLastPage >= (totalsEquivalentLines + signaturesEquivalentLines);

    int totalPages = articlePages;
    if (!canFitTotalsOnLastPage) {
      totalPages += 1; // Page séparée pour totaux et signatures
    } else if (!canFitBothOnLastPage) {
      totalPages += 1; // Page séparée pour signatures seulement
    }

    // Pages avec articles
    for (int pageIndex = 0; pageIndex < articlePages; pageIndex++) {
      final int startIndex = pageIndex * maxLinesPerPage;
      final int endIndex = (startIndex + maxLinesPerPage).clamp(0, _lignesAchat.length);
      final List<Map<String, dynamic>> pageLines = _lignesAchat.sublist(startIndex, endIndex);
      final bool isLastArticlePage = pageIndex == articlePages - 1;

      pdf.addPage(
        pw.Page(
          pageFormat: _pdfPageFormat,
          margin: const pw.EdgeInsets.all(3),
          build: (context) {
            return pw.Center(
              child: pw.Container(
                alignment: pw.Alignment.topCenter,
                padding: pw.EdgeInsets.all(pdfPadding),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Document title centered
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
                          'BON DE RÉCEPTION',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: pdfHeaderFontSize + 2,
                          ),
                        ),
                      ),
                    ),

                    pw.SizedBox(height: pdfPadding),

                    // Header section with company and document info
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                      ),
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
                                  style:
                                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfFontSize - 1),
                                ),
                                pw.Text(
                                  _societe?.rsoc ?? 'SOCIÉTÉ',
                                  style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                                ),
                                if (_societe?.activites != null)
                                  pw.Text(
                                    _societe!.activites!,
                                    style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                  ),
                                if (_societe?.adr != null)
                                  pw.Text(
                                    _societe!.adr!,
                                    style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                  ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfInfoRow('N° DOCUMENT:', _numAchatsController.text, pdfFontSize),
                                _buildPdfInfoRow('DATE:', _dateController.text, pdfFontSize),
                                _buildPdfInfoRow('N° FACTURE:', _nFactController.text, pdfFontSize),
                                _buildPdfInfoRow('FOURNISSEUR:', _selectedFournisseur ?? "", pdfFontSize),
                                if (totalPages > 1)
                                  _buildPdfInfoRow('PAGE:', '${pageIndex + 1}/$totalPages', pdfFontSize),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: pdfPadding),

                    // Articles table
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 0.5),
                      ),
                      child: pw.Column(
                        children: [
                          // Table header
                          pw.Container(
                            color: PdfColors.grey300,
                            child: pw.Table(
                              border: const pw.TableBorder(
                                horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                              ),
                              columnWidths: const {
                                0: pw.FlexColumnWidth(1),
                                1: pw.FlexColumnWidth(3),
                                2: pw.FlexColumnWidth(1),
                                3: pw.FlexColumnWidth(1),
                                4: pw.FlexColumnWidth(1),
                                5: pw.FlexColumnWidth(1.5),
                                6: pw.FlexColumnWidth(3),
                              },
                              children: [
                                pw.TableRow(
                                  children: [
                                    _buildPdfTableCell('N°', pdfFontSize, isHeader: true),
                                    _buildPdfTableCell('DÉSIGNATION', pdfFontSize, isHeader: true),
                                    _buildPdfTableCell('DÉP', pdfFontSize, isHeader: true),
                                    _buildPdfTableCell('QTÉ', pdfFontSize, isHeader: true),
                                    _buildPdfTableCell('U', pdfFontSize, isHeader: true),
                                    _buildPdfTableCell('PU HT', pdfFontSize, isHeader: true),
                                    _buildPdfTableCell('MONTANT', pdfFontSize, isHeader: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Table data
                          pw.Table(
                            border: const pw.TableBorder(
                              horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                              verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                            ),
                            columnWidths: const {
                              0: pw.FlexColumnWidth(1),
                              1: pw.FlexColumnWidth(3),
                              2: pw.FlexColumnWidth(1),
                              3: pw.FlexColumnWidth(1),
                              4: pw.FlexColumnWidth(1),
                              5: pw.FlexColumnWidth(1.5),
                              6: pw.FlexColumnWidth(3),
                            },
                            children: [
                              ...pageLines.asMap().entries.map((entry) {
                                final globalIndex = startIndex + entry.key + 1;
                                final ligne = entry.value;
                                return pw.TableRow(
                                  children: [
                                    _buildPdfTableCell(globalIndex.toString(), pdfFontSize),
                                    _buildPdfTableCell(ligne['designation'] ?? '', pdfFontSize),
                                    _buildPdfTableCell(ligne['depot'] ?? '', pdfFontSize),
                                    _buildPdfTableCell(
                                        AppFunctions.formatNumber(ligne['quantite']?.toDouble() ?? 0),
                                        pdfFontSize),
                                    _buildPdfTableCell(ligne['unites'] ?? '', pdfFontSize),
                                    _buildPdfTableCell(
                                        AppFunctions.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                        pdfFontSize),
                                    _buildPdfTableCell(
                                        AppFunctions.formatNumber(ligne['montant']?.toDouble() ?? 0),
                                        pdfFontSize,
                                        isAmount: true),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Ajouter totaux sur la dernière page d'articles si possible
                    if (isLastArticlePage && canFitTotalsOnLastPage) ...[
                      pw.SizedBox(height: pdfPadding * 2),
                      _buildTotalsSection(pdfFontSize, pdfPadding),
                    ],

                    // Ajouter signatures sur la dernière page si possible
                    if (isLastArticlePage && canFitBothOnLastPage) ...[
                      pw.SizedBox(height: pdfPadding * 2),
                      _buildSignaturesSection(pdfFontSize, pdfPadding),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Page séparée pour totaux et/ou signatures si nécessaire
    if (!canFitTotalsOnLastPage || (!canFitBothOnLastPage && canFitTotalsOnLastPage)) {
      pdf.addPage(
        pw.Page(
          pageFormat: _pdfPageFormat,
          margin: const pw.EdgeInsets.all(3),
          build: (context) {
            return pw.Center(
              child: pw.Container(
                alignment: pw.Alignment.topCenter,
                padding: pw.EdgeInsets.all(pdfPadding),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Document title centered
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
                          'BON DE RÉCEPTION',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: pdfHeaderFontSize + 2,
                          ),
                        ),
                      ),
                    ),

                    pw.SizedBox(height: pdfPadding),

                    // Header section with company and document info
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                      ),
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
                                  style:
                                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfFontSize - 1),
                                ),
                                pw.Text(
                                  _societe?.rsoc ?? 'SOCIÉTÉ',
                                  style: pw.TextStyle(fontSize: pdfFontSize, fontWeight: pw.FontWeight.bold),
                                ),
                                if (_societe?.activites != null)
                                  pw.Text(
                                    _societe!.activites!,
                                    style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                  ),
                                if (_societe?.adr != null)
                                  pw.Text(
                                    _societe!.adr!,
                                    style: pw.TextStyle(fontSize: pdfFontSize - 1),
                                  ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildPdfInfoRow('N° DOCUMENT:', _numAchatsController.text, pdfFontSize),
                                _buildPdfInfoRow('DATE:', _dateController.text, pdfFontSize),
                                _buildPdfInfoRow('N° FACTURE:', _nFactController.text, pdfFontSize),
                                _buildPdfInfoRow('FOURNISSEUR:', _selectedFournisseur ?? "", pdfFontSize),
                                _buildPdfInfoRow('PAGE:', '$totalPages/$totalPages', pdfFontSize),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: pdfPadding * 2),

                    // Totaux si pas déjà sur la dernière page d'articles
                    if (!canFitTotalsOnLastPage) _buildTotalsSection(pdfFontSize, pdfPadding),

                    pw.SizedBox(height: pdfPadding * 2),

                    // Signatures
                    _buildSignaturesSection(pdfFontSize, pdfPadding),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildTotalsSection(double pdfFontSize, double pdfPadding) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: pw.EdgeInsets.all(pdfPadding / 2),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildPdfTotalRow(
                      'TOTAL HT:',
                      AppFunctions.formatNumber(
                          double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0),
                      pdfFontSize),
                  _buildPdfTotalRow('TVA:',
                      AppFunctions.formatNumber(double.tryParse(_tvaController.text) ?? 0), pdfFontSize),
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
                    ),
                    child: _buildPdfTotalRow(
                        'TOTAL TTC:',
                        AppFunctions.formatNumber(
                            double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0),
                        pdfFontSize,
                        isBold: true),
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
              style: pw.TextStyle(
                fontSize: pdfFontSize - 1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: pdfPadding / 2),
          pw.Row(
            children: [
              pw.Text(
                'Mode de paiement: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: pdfFontSize - 1),
              ),
              pw.Text(
                _selectedModePaiement ?? "",
                style: pw.TextStyle(fontSize: pdfFontSize - 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignaturesSection(double pdfFontSize, double pdfPadding) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: pw.EdgeInsets.all(pdfPadding),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  'FOURNISSEUR',
                  style: pw.TextStyle(
                    fontSize: pdfFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: pdfPadding * 2),
                pw.Container(
                  height: 1,
                  color: PdfColors.black,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                ),
                pw.SizedBox(height: pdfPadding / 2),
                pw.Text(
                  'Nom et signature',
                  style: pw.TextStyle(fontSize: pdfFontSize - 2),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 1,
            height: 60,
            color: PdfColors.black,
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  'RÉCEPTIONNAIRE',
                  style: pw.TextStyle(
                    fontSize: pdfFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: pdfPadding * 2),
                pw.Container(
                  height: 1,
                  color: PdfColors.black,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                ),
                pw.SizedBox(height: pdfPadding / 2),
                pw.Text(
                  'Nom et signature',
                  style: pw.TextStyle(fontSize: pdfFontSize - 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, double fontSize, {bool isHeader = false, bool isAmount = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
          horizontal: _selectedFormat == 'A6' ? 3 : 5, vertical: _selectedFormat == 'A6' ? 2 : 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize - 1,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader
            ? pw.TextAlign.center
            : (isAmount || RegExp(r'^\d+$').hasMatch(text) ? pw.TextAlign.right : pw.TextAlign.left),
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value, double fontSize) {
    return pw.Text(
      "$label $value",
      style: pw.TextStyle(
        fontSize: fontSize - 1,
        fontWeight: pw.FontWeight.normal,
      ),
    );
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
          pw.SizedBox(width: 15),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize - 1,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateController.removeListener(_onDateChanged);
    _echeanceJoursController.removeListener(_onEcheanceJoursChanged);
    _numAchatsController.dispose();
    _nFactController.dispose();
    _dateController.dispose();
    _fournisseurController.dispose();
    _modePaiementController.dispose();
    _echeanceController.dispose();
    _totalHTController.dispose();
    _tvaController.dispose();
    _totalTTCController.dispose();
    _articleSearchController.dispose();
    _autocompleteController?.dispose();
    _uniteController.dispose();
    _depotController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _totalFMGController.dispose();
    _searchAchatsController.dispose();
    _echeanceJoursController.dispose();
    super.dispose();
  }
}
