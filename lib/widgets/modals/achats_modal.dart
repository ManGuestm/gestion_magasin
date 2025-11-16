import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/cmup_calculator.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';
import '../../utils/stock_converter.dart';
import 'add_fournisseur_modal.dart';
import 'bon_reception_preview.dart';

class AchatsModal extends StatefulWidget {
  const AchatsModal({super.key});

  @override
  State<AchatsModal> createState() => _AchatsModalState();
}

class _AchatsModalState extends State<AchatsModal> {
  final DatabaseService _databaseService = DatabaseService();

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
  final TextEditingController _depotController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _searchAchatsController = TextEditingController();

  // Lists
  List<Frn> _fournisseurs = [];
  List<Article> _articles = [];
  List<Depot> _depots = [];
  List<MpData> _modesPaiement = [];
  final List<Map<String, dynamic>> _lignesAchat = [];

  // Selected values
  String? _selectedFournisseur;
  String? _selectedModePaiement;
  Article? _selectedArticle;
  String? _selectedUnite;
  String? _selectedDepot;
  bool _isExistingPurchase = false;
  int? _selectedRowIndex;
  String _selectedFormat = 'A5';
  SocData? _societe;
  bool _isModifyingArticle = false;
  Map<String, dynamic>? _originalArticleData;
  List<String> _achatsNumbers = [];
  int _currentAchatIndex = -1;
  String _searchAchatsText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAchatsNumbers().then((_) => _initializeForm());
  }

  void _initializeForm() async {
    // Toujours créer un nouveau formulaire par défaut
    final now = DateTime.now();
    _dateController.text = app_date.AppDateUtils.formatDate(now);
    _echeanceController.text = app_date.AppDateUtils.formatDate(now);

    // Générer le prochain numéro d'achat
    final nextNum = await _getNextNumAchats();
    _numAchatsController.text = nextNum;

    // Mode de paiement par défaut "A crédit"
    _selectedModePaiement = 'A crédit';

    _tvaController.text = '0';
    _totalHTController.text = '0';
    _totalTTCController.text = '0';
    _totalFMGController.text = '0';
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
      final depots = await _databaseService.database.getAllDepots();
      final modesPaiement = await _databaseService.database.select(_databaseService.database.mp).get();
      final societe =
          await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();

      setState(() {
        _fournisseurs = fournisseurs;
        _articles = articles;
        _depots = depots;
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
              onPressed: () {
                Navigator.of(context).pop(true);
                Navigator.of(context).pop();
              },
              child: const Text('Oui'),
            ),
          ],
        ),
      );

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

  void _onArticleSelected(Article? article) {
    setState(() {
      _selectedArticle = article;
      if (article != null) {
        // Sélection par défaut de l'unité u1 et du dépôt de l'article
        _selectedUnite = article.u1;
        _selectedDepot = article.dep;
        _uniteController.text = article.u1 ?? '';
        _depotController.text = article.dep ?? '';

        // Calcul du prix basé sur le CMUP
        double prixSuggere = CMUPCalculator.calculerPrixVente(
          article: article,
          unite: article.u1 ?? 'Pce',
          margePercent: 0.0, // Pas de marge pour les achats
        );

        if (prixSuggere == 0.0) {
          _prixController.text = '';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CMUP non défini, veuillez saisir le prix manuellement')),
            );
          }
        } else {
          _prixController.text = NumberUtils.formatNumber(prixSuggere);
        }
        _quantiteController.text = '';
      }
    });
  }

  void _onUniteChanged(String? unite) {
    // Vérification des prérequis : article sélectionné et unité valide
    if (_selectedArticle == null || unite == null) return;

    setState(() {
      // Mise à jour de l'unité sélectionnée
      _selectedUnite = unite;
      _uniteController.text = unite;

      // Calcul du prix basé sur le CMUP pour l'unité sélectionnée
      double prixSuggere = CMUPCalculator.calculerPrixVente(
        article: _selectedArticle!,
        unite: unite,
        margePercent: 0.0, // Pas de marge pour les achats
      );

      if (prixSuggere == 0.0) {
        _prixController.text = '';
      } else {
        _prixController.text = NumberUtils.formatNumber(prixSuggere);
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
      // En mode modification : mettre à jour les stocks
      await _mettreAJourStocksModification();
    }
    _ajouterLigne();
    _resetArticleForm();
  }

  void _annulerAjout() async {
    if (_isModifyingArticle && _originalArticleData != null) {
      // En cas de modification : remettre l'article dans la table
      setState(() {
        _lignesAchat.add(_originalArticleData!);
        _originalArticleData = null;
        _isModifyingArticle = false;
      });
      _calculerTotaux();
    }
    _resetArticleForm();
  }

  void _resetArticleForm() {
    setState(() {
      _selectedArticle = null;
      _selectedUnite = null;
      _selectedDepot = null;
      _isModifyingArticle = false;
      _originalArticleData = null;
      if (_autocompleteController != null) {
        _autocompleteController!.clear();
      }
      _uniteController.clear();
      _depotController.clear();
      _quantiteController.clear();
      _prixController.clear();
    });
  }

  void _chargerLigneArticle(int index) {
    final ligne = _lignesAchat[index];

    // Trouver l'article correspondant
    Article? article = _articles.firstWhere(
      (a) => a.designation == ligne['designation'],
      orElse: () => _articles.first,
    );

    setState(() {
      _selectedArticle = article;
      _selectedUnite = ligne['unites'];
      _selectedDepot = ligne['depot'];
      _isModifyingArticle = true;
      _originalArticleData = Map<String, dynamic>.from(ligne);

      if (_autocompleteController != null) {
        _autocompleteController!.text = ligne['designation'];
      }
      _uniteController.text = ligne['unites'];
      _depotController.text = ligne['depot'];
      _quantiteController.text = ligne['quantite'].toString();
      _prixController.text = NumberUtils.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0);
    });

    // Supprimer la ligne de la table pour éviter les doublons
    _supprimerLigne(index);
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
          _selectedModePaiement = achat.modepai;
          if (achat.echeance != null) {
            _echeanceController.text = app_date.AppDateUtils.formatDate(achat.echeance!);
          }
          _tvaController.text = (achat.tva ?? 0).toString();

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
        _currentAchatIndex = _achatsNumbers.indexOf(numAchats);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Achat N° $numAchats chargé')),
          );
        }
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

        // Mettre à jour l'achat principal (GARDER LE MÊME NUMÉRO)
        await (_databaseService.database.update(_databaseService.database.achats)
              ..where((a) => a.numachats.equals(_numAchatsController.text)))
            .write(AchatsCompanion(
          nfact: Value(_nFactController.text.isEmpty ? null : _nFactController.text),
          daty: Value(dateForDB),
          frns: Value(_selectedFournisseur!),
          modepai: Value(_selectedModePaiement),
          echeance: Value(_echeanceController.text.isEmpty ? null : dateForDB),
          totalnt: Value(double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0.0),
          tva: Value(double.tryParse(_tvaController.text) ?? 0.0),
          totalttc: Value(double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0.0),
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
                  refart: Value(ligne['designation']),
                  qe: Value(ligne['quantite']),
                  entres: Value(ligne['quantite']),
                  ue: Value(ligne['unites']),
                  depots: Value(ligne['depot']),
                  cmup: Value(nouveauCMUP),
                  frns: Value(_selectedFournisseur!),
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

    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(
            'Voulez-vous vraiment contre-passer l\'achat N° ${_numAchatsController.text} ?\n\nCette action supprimera définitivement l\'achat et ajustera les stocks.'),
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

    try {
      await _databaseService.database.transaction(() async {
        // Récupérer les lignes de l'achat à contre-passer
        final lignesAchat = await (_databaseService.database.select(_databaseService.database.detachats)
              ..where((d) => d.numachats.equals(_numAchatsController.text)))
            .get();

        // Recharger les articles pour avoir les stocks actuels
        _articles = await _databaseService.database.getAllArticles();

        // Annuler l'impact sur les stocks avec conversion automatique
        for (var ligne in lignesAchat) {
          Article? article = _articles.firstWhere(
            (a) => a.designation == ligne.designation,
            orElse: () => throw Exception('Article ${ligne.designation} non trouvé'),
          );

          // Ajouter entrée de sortie dans variation des stocks
          await _databaseService.database.into(_databaseService.database.stocks).insert(
                StocksCompanion.insert(
                  ref:
                      'CP-${_numAchatsController.text}-${ligne.designation}-${DateTime.now().millisecondsSinceEpoch}',
                  daty: Value(DateTime.now()),
                  lib: Value('Contre-passement achat ${_numAchatsController.text}'),
                  refart: Value(ligne.designation ?? ''),
                  sortie: Value(ligne.q ?? 0),
                  ue: Value(ligne.unites ?? ''),
                  depots: Value(ligne.depots ?? ''),
                  cmup: Value(article.cmup ?? 0),
                ),
              );

          // Convertir la quantité à annuler en unités optimales
          final conversionAnnulation = StockConverter.convertirQuantiteAchat(
            article: article,
            uniteAchat: ligne.unites ?? article.u3!,
            quantiteAchat: ligne.q ?? 0,
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
                ..where(
                    (d) => d.designation.equals(article.designation) & d.depots.equals(ligne.depots ?? '')))
              .getSingleOrNull();

          if (existingDepart != null) {
            final stocksActuelsDepot = StockConverter.convertirStockOptimal(
              article: article,
              quantiteU1: (existingDepart.stocksu1 ?? 0) - conversionAnnulation['u1']!,
              quantiteU2: (existingDepart.stocksu2 ?? 0) - conversionAnnulation['u2']!,
              quantiteU3: (existingDepart.stocksu3 ?? 0) - conversionAnnulation['u3']!,
            );

            await (_databaseService.database.update(_databaseService.database.depart)
                  ..where(
                      (d) => d.designation.equals(article.designation) & d.depots.equals(ligne.depots ?? '')))
                .write(DepartCompanion(
              stocksu1: Value(stocksActuelsDepot['u1']! >= 0 ? stocksActuelsDepot['u1']! : 0),
              stocksu2: Value(stocksActuelsDepot['u2']! >= 0 ? stocksActuelsDepot['u2']! : 0),
              stocksu3: Value(stocksActuelsDepot['u3']! >= 0 ? stocksActuelsDepot['u3']! : 0),
            ));
          }

          // Recalculer le CMUP après suppression
          await _recalculerCMUPApresAnnulation(article, ligne.q ?? 0, ligne.pu ?? 0);
        }

        // Supprimer les entrées de stock
        await (_databaseService.database.delete(_databaseService.database.stocks)
              ..where((s) => s.numachats.equals(_numAchatsController.text)))
            .go();

        // Supprimer les lignes d'achat
        await (_databaseService.database.delete(_databaseService.database.detachats)
              ..where((d) => d.numachats.equals(_numAchatsController.text)))
            .go();

        // Supprimer l'achat principal
        await (_databaseService.database.delete(_databaseService.database.achats)
              ..where((a) => a.numachats.equals(_numAchatsController.text)))
            .go();
      });

      // Recharger toutes les données pour mettre à jour l'interface
      await _loadAchatsNumbers();
      await _loadData();
      await _creerNouvelAchat();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat contre-passé avec succès')),
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

  Future<void> _mettreAJourStocksModification() async {
    if (_originalArticleData == null || _selectedArticle == null) return;

    try {
      // Quantités originales et nouvelles
      double ancienneQuantite = _originalArticleData!['quantite'] ?? 0.0;
      double nouvelleQuantite = double.tryParse(_quantiteController.text) ?? 0.0;
      double differenceQuantite = nouvelleQuantite - ancienneQuantite;

      String unite = _selectedUnite ?? '';
      String depot = _selectedDepot ?? '';

      // Mettre à jour les stocks par dépôt dans la table Depart
      final existingDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(_selectedArticle!.designation) & d.depots.equals(depot)))
          .getSingleOrNull();

      if (existingDepart != null) {
        // Mettre à jour le stock existant pour ce dépôt
        if (unite == _selectedArticle!.u1) {
          double newStock = (existingDepart.stocksu1 ?? 0) + differenceQuantite;
          await (_databaseService.database.update(_databaseService.database.depart)
                ..where((d) => d.designation.equals(_selectedArticle!.designation) & d.depots.equals(depot)))
              .write(DepartCompanion(
            stocksu1: Value(newStock >= 0 ? newStock : 0),
          ));
        } else if (unite == _selectedArticle!.u2) {
          double newStock = (existingDepart.stocksu2 ?? 0) + differenceQuantite;
          await (_databaseService.database.update(_databaseService.database.depart)
                ..where((d) => d.designation.equals(_selectedArticle!.designation) & d.depots.equals(depot)))
              .write(DepartCompanion(
            stocksu2: Value(newStock >= 0 ? newStock : 0),
          ));
        } else if (unite == _selectedArticle!.u3) {
          double newStock = (existingDepart.stocksu3 ?? 0) + differenceQuantite;
          await (_databaseService.database.update(_databaseService.database.depart)
                ..where((d) => d.designation.equals(_selectedArticle!.designation) & d.depots.equals(depot)))
              .write(DepartCompanion(
            stocksu3: Value(newStock >= 0 ? newStock : 0),
          ));
        }
      } else if (differenceQuantite > 0) {
        // Créer une nouvelle entrée pour ce dépôt si la différence est positive
        await _databaseService.database.into(_databaseService.database.depart).insert(
              DepartCompanion.insert(
                designation: _selectedArticle!.designation,
                depots: depot,
                stocksu1: Value(unite == _selectedArticle!.u1 ? differenceQuantite : 0.0),
                stocksu2: Value(unite == _selectedArticle!.u2 ? differenceQuantite : 0.0),
                stocksu3: Value(unite == _selectedArticle!.u3 ? differenceQuantite : 0.0),
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour des stocks: $e')),
        );
      }
    }
  }

  Future<void> _loadAchatsNumbers() async {
    try {
      final achats = await (_databaseService.database.select(_databaseService.database.achats)
            ..orderBy([(a) => OrderingTerm.asc(a.numachats)]))
          .get();
      setState(() {
        _achatsNumbers = achats.map((a) => a.numachats ?? '').where((n) => n.isNotEmpty).toList();
      });
    } catch (e) {
      // Ignore errors
    }
  }

  void _naviguerAchat(bool suivant) {
    if (_achatsNumbers.isEmpty) return;

    if (_currentAchatIndex == -1) {
      // Trouver l'index actuel
      _currentAchatIndex = _achatsNumbers.indexOf(_numAchatsController.text);
    }

    if (suivant && _currentAchatIndex < _achatsNumbers.length - 1) {
      _currentAchatIndex++;
    } else if (!suivant && _currentAchatIndex > 0) {
      _currentAchatIndex--;
    } else {
      return;
    }

    final numAchat = _achatsNumbers[_currentAchatIndex];
    _numAchatsController.text = numAchat;
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
    });

    // Réinitialiser tous les contrôleurs
    _nFactController.clear();
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

      // Convertir la date au format DateTime pour la base de données
      List<String> dateParts = _dateController.text.split('-');
      DateTime dateForDB =
          DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

      // Insérer l'achat principal
      await _databaseService.database.into(_databaseService.database.achats).insert(
            AchatsCompanion.insert(
              numachats: Value(_numAchatsController.text),
              nfact: Value(_nFactController.text.isEmpty ? null : _nFactController.text),
              daty: Value(dateForDB),
              frns: Value(_selectedFournisseur!),
              modepai: Value(_selectedModePaiement),
              echeance: Value(_echeanceController.text.isEmpty
                  ? null
                  : DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]))),
              totalnt: Value(double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0.0),
              tva: Value(double.tryParse(_tvaController.text) ?? 0.0),
              totalttc: Value(double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0.0),
            ),
          );

      // Insérer les lignes d'achat et mettre à jour les stocks
      for (var ligne in _lignesAchat) {
        await _databaseService.database.into(_databaseService.database.detachats).insert(
              DetachatsCompanion.insert(
                numachats: Value(_numAchatsController.text),
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
          orElse: () => throw Exception('Article non trouvé'),
        );

        // Calculer et mettre à jour le CMUP avec le calculateur amélioré
        double nouveauCMUP = await CMUPCalculator.calculerEtMettreAJourCMUP(
          designation: ligne['designation'],
          uniteAchat: ligne['unites'],
          quantiteAchat: ligne['quantite'],
          prixUnitaireAchat: ligne['prixUnitaire'],
          article: article,
        );

        await _databaseService.database.into(_databaseService.database.stocks).insert(
              StocksCompanion.insert(
                ref:
                    'ACH-${_numAchatsController.text}-${ligne['designation']}-${DateTime.now().millisecondsSinceEpoch}',
                daty: Value(dateForDB),
                lib: Value('Achat ${_numAchatsController.text}'),
                numachats: Value(_numAchatsController.text),
                refart: Value(ligne['designation']),
                qe: Value(ligne['quantite']),
                entres: Value(ligne['quantite']),
                ue: Value(ligne['unites']),
                depots: Value(ligne['depot']),
                cmup: Value(nouveauCMUP),
                frns: Value(_selectedFournisseur!),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat enregistré avec succès')),
        );
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            color: Colors.grey[100],
          ),
          width: 1100,
          height: MediaQuery.of(context).size.height * 0.9,
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
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
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
                          : ListView.builder(
                              itemCount: _getFilteredAchatsNumbers().length,
                              itemBuilder: (context, index) {
                                final numAchat = _getFilteredAchatsNumbers()[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _numAchatsController.text == numAchat ? Colors.blue.shade100 : null,
                                    border:
                                        Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    title: Text('N° $numAchat', style: const TextStyle(fontSize: 11)),
                                    onTap: () => _chargerAchatExistant(numAchat),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _creerNouvelAchat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Nouveau', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Formulaire principal à droite
              Expanded(
                child: Column(
                  children: [
                    // Title bar with close button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 35,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Text(
                                'Achat fournisseurs',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
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
                          Column(
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
                                  initialValue: "Journal",
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Journal',
                                        child: Text('Journal', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(
                                        value: 'Brouillard',
                                        child: Text('Brouillard', style: TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (value) {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 32),
                          // Form fields
                          Expanded(
                            child: Column(
                              children: [
                                // First row
                                Row(
                                  children: [
                                    const Text('N° Achats', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 100,
                                      height: 25,
                                      child: TextField(
                                        textAlign: TextAlign.center,
                                        controller: _numAchatsController,
                                        readOnly: true,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          fillColor: Color(0xFFF5F5F5),
                                          filled: true,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text('Date', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 120,
                                      height: 25,
                                      child: TextField(
                                        controller: _dateController,
                                        readOnly: true,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                            _dateController.text = app_date.AppDateUtils.formatDate(date);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text('N° Facture/ BL', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 150,
                                      height: 25,
                                      child: TextField(
                                        textAlign: TextAlign.center,
                                        controller: _nFactController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Second row
                                Row(
                                  children: [
                                    const Text('Fournisseurs', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 25,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Autocomplete<Frn>(
                                                optionsBuilder: (textEditingValue) {
                                                  if (textEditingValue.text.isEmpty) {
                                                    return _fournisseurs;
                                                  }
                                                  return _fournisseurs.where((frn) {
                                                    return frn.rsoc
                                                        .toLowerCase()
                                                        .contains(textEditingValue.text.toLowerCase());
                                                  });
                                                },
                                                displayStringForOption: (frn) => frn.rsoc,
                                                onSelected: (frn) {
                                                  setState(() {
                                                    _selectedFournisseur = frn.rsoc;
                                                  });
                                                },
                                                fieldViewBuilder:
                                                    (context, controller, focusNode, onEditingComplete) {
                                                  if (_selectedFournisseur != null &&
                                                      controller.text != _selectedFournisseur) {
                                                    controller.text = _selectedFournisseur!;
                                                  }
                                                  return TextField(
                                                    controller: controller,
                                                    focusNode: focusNode,
                                                    onEditingComplete: () async {
                                                      // Vérifier et créer le fournisseur si nécessaire
                                                      await _verifierEtCreerFournisseur(controller.text);
                                                      onEditingComplete();
                                                    },
                                                    onSubmitted: (value) async {
                                                      // Vérifier et créer le fournisseur si nécessaire
                                                      await _verifierEtCreerFournisseur(value);
                                                    },
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    ),
                                                    style: const TextStyle(fontSize: 12),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _selectedFournisseur = value;
                                                      });
                                                    },
                                                  );
                                                },
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
                                  height: 25,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Autocomplete<Article>(
                                          optionsBuilder: (textEditingValue) {
                                            if (textEditingValue.text.isEmpty) {
                                              return const Iterable<Article>.empty();
                                            }
                                            return _articles.where((article) {
                                              return article.designation
                                                  .toLowerCase()
                                                  .contains(textEditingValue.text.toLowerCase());
                                            });
                                          },
                                          displayStringForOption: (article) => article.designation,
                                          onSelected: _onArticleSelected,
                                          fieldViewBuilder:
                                              (context, controller, focusNode, onEditingComplete) {
                                            _autocompleteController = controller;
                                            return TextField(
                                              controller: controller,
                                              focusNode: focusNode,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              ),
                                              style: const TextStyle(fontSize: 12),
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 25,
                                        height: 25,
                                        child: PopupMenuButton<Article>(
                                          icon: const Icon(Icons.arrow_drop_down, size: 16),
                                          itemBuilder: (context) {
                                            return _articles.map((article) {
                                              return PopupMenuItem<Article>(
                                                value: article,
                                                child: Text(article.designation,
                                                    style: const TextStyle(fontSize: 12)),
                                              );
                                            }).toList();
                                          },
                                          onSelected: (article) {
                                            if (_autocompleteController != null) {
                                              _autocompleteController!.text = article.designation;
                                            }
                                            _onArticleSelected(article);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                  height: 25,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _uniteController,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                          onChanged: (value) {
                                            _selectedUnite = value;
                                            _onUniteChanged(value);
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 20,
                                        height: 25,
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(Icons.arrow_drop_down, size: 12),
                                          itemBuilder: (context) {
                                            return _getUnitsForSelectedArticle().map((item) {
                                              return PopupMenuItem<String>(
                                                value: item.value,
                                                child: item.child,
                                              );
                                            }).toList();
                                          },
                                          onSelected: (unite) {
                                            _uniteController.text = unite;
                                            _onUniteChanged(unite);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                  height: 25,
                                  child: TextField(
                                    controller: _quantiteController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
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
                                  height: 25,
                                  child: TextField(
                                    controller: _prixController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
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
                                  height: 25,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _depotController,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedDepot = value;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 25,
                                        height: 25,
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(Icons.arrow_drop_down, size: 12),
                                          itemBuilder: (context) {
                                            return _depots.map((depot) {
                                              return PopupMenuItem<String>(
                                                value: depot.depots,
                                                child:
                                                    Text(depot.depots, style: const TextStyle(fontSize: 12)),
                                              );
                                            }).toList();
                                          },
                                          onSelected: (depot) {
                                            _depotController.text = depot;
                                            setState(() {
                                              _selectedDepot = depot;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isArticleFormValid()) ...[
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: _validerAjout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(60, 25),
                                      ),
                                      child: const Text('Valider', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton(
                                      onPressed: _annulerAjout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(60, 25),
                                      ),
                                      child: const Text('Annuler', style: TextStyle(fontSize: 12)),
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
                                          onSecondaryTapUp: (details) {
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
                                                  child: Text('Modifier', style: TextStyle(fontSize: 12)),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'supprimer_ligne',
                                                  child: Text('Supprimer', style: TextStyle(fontSize: 12)),
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
                                                    onPressed: () => _supprimerLigne(index),
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
                                                      (ligne['quantite'] as double?)?.round().toString() ??
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
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        ),
                                        items: _modesPaiement.where((mp) => mp.mp == 'A crédit').map((mp) {
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
                                        controller: _echeanceController,
                                        textAlign: TextAlign.center,
                                        readOnly: true,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                            _echeanceController.text = app_date.AppDateUtils.formatDate(date);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Text('Echéance (Jours)', style: TextStyle(fontSize: 12)),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 135,
                                      height: 25,
                                      child: TextField(
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                        color: Color(0xFFFFB6C1),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Tooltip(
                            message: 'Achat précédent',
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: ElevatedButton(
                                onPressed: _achatsNumbers.isNotEmpty && _currentAchatIndex > 0
                                    ? () => _naviguerAchat(false)
                                    : null,
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
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Achat suivant',
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: ElevatedButton(
                                onPressed: _achatsNumbers.isNotEmpty &&
                                        _currentAchatIndex < _achatsNumbers.length - 1
                                    ? () => _naviguerAchat(true)
                                    : null,
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
                          const SizedBox(width: 8),
                          if (_isExistingPurchase) ...[
                            ElevatedButton(
                              onPressed: _creerNouvelAchat,
                              style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
                              child: const Text('Créer', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 4),
                          ],
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: _contrePasserAchat,
                            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 30)),
                            child: const Text('Contre Passer', style: TextStyle(fontSize: 12)),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _isExistingPurchase ? _modifierAchat : _validerAchat,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isExistingPurchase ? Colors.blue : Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(60, 30),
                            ),
                            child: Text(_isExistingPurchase ? 'Modifier' : 'Valider',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: _ouvrirApercuBR,
                            style: ElevatedButton.styleFrom(minimumSize: const Size(70, 30)),
                            child: const Text('Aperçu BR', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
                            child: const Text('Fermer', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 4),
                          Container(
                              height: 20,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              decoration:
                                  BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
                              child: Row(
                                children: [
                                  const Text("Format Papier", style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 6),
                                  DropdownButton<String>(
                                    value: _selectedFormat,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'A4', child: Text('A4', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(
                                          value: 'A5', child: Text('A5', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(
                                          value: 'A6', child: Text('A6', style: TextStyle(fontSize: 12))),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFormat = value ?? 'A5';
                                      });
                                    },
                                  ),
                                ],
                              )),
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
    );
  }

  @override
  void dispose() {
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
    _uniteController.dispose();
    _depotController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _totalFMGController.dispose();
    _searchAchatsController.dispose();
    super.dispose();
  }

  List<String> _getFilteredAchatsNumbers() {
    if (_searchAchatsText.isEmpty) {
      return _achatsNumbers;
    }
    return _achatsNumbers.where((numAchat) => numAchat.toLowerCase().contains(_searchAchatsText)).toList();
  }
}
