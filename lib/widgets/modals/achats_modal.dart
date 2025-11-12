import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeForm();
  }

  void _initializeForm() async {
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    // Générer le prochain numéro d'achat
    final nextNum = await _getNextNumAchats();
    _numAchatsController.text = nextNum;

    _tvaController.text = '0';
    _totalHTController.text = '0';
    _totalTTCController.text = '0';
    _totalFMGController.text = '0';
  }

  Future<String> _getNextNumAchats() async {
    try {
      // Récupérer le dernier numéro d'achat
      final lastAchat = await (_databaseService.database.select(_databaseService.database.achats)
            ..orderBy([(a) => drift.OrderingTerm.desc(a.num)]))
          .getSingleOrNull();

      if (lastAchat?.numachats != null) {
        // Extraire le numéro et l'incrémenter
        final lastNum = int.tryParse(lastAchat!.numachats!) ?? 10000;
        return (lastNum + 1).toString();
      } else {
        // Premier achat
        return '10001';
      }
    } catch (e) {
      // En cas d'erreur, commencer à 10001
      return '10001';
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

  void _onArticleSelected(Article? article) {
    setState(() {
      _selectedArticle = article;
      if (article != null) {
        _selectedUnite = article.u1;
        _selectedDepot = article.dep;
        _uniteController.text = article.u1 ?? '';
        _depotController.text = article.dep ?? '';
        // Utiliser le coût moyen unitaire pondéré pour les achats
        double cmup = article.cmup ?? 0.0;
        if (cmup == 0.0) {
          _prixController.text = '';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CMUP non défini, veuillez saisir le prix manuellement')),
            );
          }
        } else {
          // Pour l'unité 1 (u1), le prix est le CMUP de base
          _prixController.text = cmup.toString();
        }
        _quantiteController.text = '';
      }
    });
  }

  void _onUniteChanged(String? unite) {
    if (_selectedArticle == null || unite == null) return;

    setState(() {
      _selectedUnite = unite;
      _uniteController.text = unite;

      // Calculer le prix selon l'unité et les taux de conversion
      double cmup = _selectedArticle!.cmup ?? 0.0;
      if (cmup == 0.0) {
        _prixController.text = '';
      } else {
        double prixUnitaire = cmup;

        // Ajuster le prix selon l'unité sélectionnée
        if (unite == _selectedArticle!.u2 && _selectedArticle!.tu2u1 != null) {
          // Prix pour unité 2 = CMUP * taux u2/u1
          prixUnitaire = cmup * _selectedArticle!.tu2u1!;
        } else if (unite == _selectedArticle!.u3 &&
            _selectedArticle!.tu3u2 != null &&
            _selectedArticle!.tu2u1 != null) {
          // Prix pour unité 3 = CMUP * taux u3/u2 * taux u2/u1
          prixUnitaire = cmup * _selectedArticle!.tu3u2! * _selectedArticle!.tu2u1!;
        }

        _prixController.text = prixUnitaire.toString();
      }
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
    double prix = double.tryParse(_prixController.text) ?? 0.0;
    double montant = quantite * prix;

    String designation = _selectedArticle!.designation;
    String depot = _selectedDepot ?? 'MAG';
    String unite = _selectedUnite ?? 'Pce';

    // Chercher si l'article existe déjà dans le même dépôt
    int existingIndex =
        _lignesAchat.indexWhere((ligne) => ligne['designation'] == designation && ligne['depot'] == depot);

    setState(() {
      if (existingIndex != -1) {
        // Cumuler les quantités si même article et même dépôt
        double existingQuantite = _lignesAchat[existingIndex]['quantite'] ?? 0.0;
        double newQuantite = existingQuantite + quantite;
        double newMontant = newQuantite * prix;

        _lignesAchat[existingIndex]['quantite'] = newQuantite;
        _lignesAchat[existingIndex]['montant'] = newMontant;
      } else {
        // Ajouter nouvelle ligne si différent dépôt ou nouvel article
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

  String _formatNumber(double number) {
    String integerPart = number.round().toString();

    String formatted = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formatted += ' ';
      }
      formatted += integerPart[i];
    }

    return formatted;
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
      _totalHTController.text = _formatNumber(totalHT);
      _totalTTCController.text = _formatNumber(totalTTC);
      _totalFMGController.text = _formatNumber(totalFMG);
    });
  }

  bool _isArticleFormValid() {
    return _selectedArticle != null &&
        _uniteController.text.isNotEmpty &&
        _quantiteController.text.isNotEmpty &&
        _prixController.text.isNotEmpty &&
        _depotController.text.isNotEmpty;
  }

  void _validerAjout() {
    _ajouterLigne();
    _resetArticleForm();
  }

  void _annulerAjout() {
    _resetArticleForm();
  }

  void _resetArticleForm() {
    setState(() {
      _selectedArticle = null;
      _selectedUnite = null;
      _selectedDepot = null;
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

      if (_autocompleteController != null) {
        _autocompleteController!.text = ligne['designation'];
      }
      _uniteController.text = ligne['unites'];
      _depotController.text = ligne['depot'];
      _quantiteController.text = ligne['quantite'].toString();
      _prixController.text = ligne['prixUnitaire'].toString();
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
            _dateController.text =
                '${achat.daty!.day.toString().padLeft(2, '0')}-${achat.daty!.month.toString().padLeft(2, '0')}-${achat.daty!.year}';
          }
          _selectedFournisseur = achat.frns;
          _selectedModePaiement = achat.modepai;
          if (achat.echeance != null) {
            _echeanceController.text =
                '${achat.echeance!.day.toString().padLeft(2, '0')}-${achat.echeance!.month.toString().padLeft(2, '0')}-${achat.echeance!.year}';
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
    if (_selectedFournisseur == null || _lignesAchat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fournisseur et ajouter des articles')),
      );
      return;
    }

    try {
      List<String> dateParts = _dateController.text.split('-');
      DateTime dateForDB =
          DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

      // Récupérer les anciennes lignes pour annuler leur impact sur les stocks
      final anciennesLignes = await (_databaseService.database.select(_databaseService.database.detachats)
            ..where((d) => d.numachats.equals(_numAchatsController.text)))
          .get();

      // Annuler l'impact des anciennes lignes sur les stocks
      for (var ancienneLigne in anciennesLignes) {
        Article? article = _articles.firstWhere(
          (a) => a.designation == ancienneLigne.designation,
          orElse: () => throw Exception('Article non trouvé'),
        );

        // Déduire les anciennes quantités des stocks
        if (ancienneLigne.unites == article.u1) {
          double newStock = (article.stocksu1 ?? 0) - (ancienneLigne.q ?? 0);
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu1: drift.Value(newStock),
          ));
        } else if (ancienneLigne.unites == article.u2) {
          double newStock = (article.stocksu2 ?? 0) - (ancienneLigne.q ?? 0);
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu2: drift.Value(newStock),
          ));
        } else if (ancienneLigne.unites == article.u3) {
          double newStock = (article.stocksu3 ?? 0) - (ancienneLigne.q ?? 0);
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu3: drift.Value(newStock),
          ));
        }
      }

      // Mettre à jour l'achat principal
      await (_databaseService.database.update(_databaseService.database.achats)
            ..where((a) => a.numachats.equals(_numAchatsController.text)))
          .write(AchatsCompanion(
        nfact: drift.Value(_nFactController.text.isEmpty ? null : _nFactController.text),
        daty: drift.Value(dateForDB),
        frns: drift.Value(_selectedFournisseur!),
        modepai: drift.Value(_selectedModePaiement),
        echeance: drift.Value(_echeanceController.text.isEmpty ? null : dateForDB),
        totalnt: drift.Value(double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0.0),
        tva: drift.Value(double.tryParse(_tvaController.text) ?? 0.0),
        totalttc: drift.Value(double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0.0),
      ));

      // Supprimer les anciennes lignes
      await (_databaseService.database.delete(_databaseService.database.detachats)
            ..where((d) => d.numachats.equals(_numAchatsController.text)))
          .go();

      // Recharger les articles pour avoir les stocks mis à jour
      _articles = await _databaseService.database.getAllArticles();

      // Insérer les nouvelles lignes et mettre à jour les stocks
      for (var ligne in _lignesAchat) {
        await _databaseService.database.into(_databaseService.database.detachats).insert(
              DetachatsCompanion.insert(
                numachats: drift.Value(_numAchatsController.text),
                designation: drift.Value(ligne['designation']),
                unites: drift.Value(ligne['unites']),
                depots: drift.Value(ligne['depot']),
                q: drift.Value(ligne['quantite']),
                pu: drift.Value(ligne['prixUnitaire']),
                daty: drift.Value(dateForDB),
              ),
            );

        // Mettre à jour le stock et le CMUP dans la table Articles
        Article? article = _articles.firstWhere(
          (a) => a.designation == ligne['designation'],
          orElse: () => throw Exception('Article non trouvé'),
        );

        // Calculer le nouveau CMUP
        double nouveauCMUP = await _calculerNouveauCMUP(article, ligne['quantite'], ligne['prixUnitaire']);

        // Mettre à jour les stocks de l'article selon l'unité et le CMUP
        if (ligne['unites'] == article.u1) {
          double newStock = (article.stocksu1 ?? 0) + ligne['quantite'];
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu1: drift.Value(newStock),
            cmup: drift.Value(nouveauCMUP),
          ));
        } else if (ligne['unites'] == article.u2) {
          double newStock = (article.stocksu2 ?? 0) + ligne['quantite'];
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu2: drift.Value(newStock),
            cmup: drift.Value(nouveauCMUP),
          ));
        } else if (ligne['unites'] == article.u3) {
          double newStock = (article.stocksu3 ?? 0) + ligne['quantite'];
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu3: drift.Value(newStock),
            cmup: drift.Value(nouveauCMUP),
          ));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat modifié avec succès')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification: $e')),
        );
      }
    }
  }

  Future<double> _calculerNouveauCMUP(Article article, double nouvelleQuantite, double nouveauPrix) async {
    // Valeur du stock initial = stock actuel * CMUP actuel
    double stockActuel = 0;
    double cmupActuel = article.cmup ?? 0.0;

    // Calculer le stock total actuel (toutes unités confondues en u1)
    stockActuel += article.stocksu1 ?? 0;
    if (article.u2 != null && article.tu2u1 != null) {
      stockActuel += (article.stocksu2 ?? 0) * article.tu2u1!;
    }
    if (article.u3 != null && article.tu3u2 != null && article.tu2u1 != null) {
      stockActuel += (article.stocksu3 ?? 0) * article.tu3u2! * article.tu2u1!;
    }

    double valeurStockInitial = stockActuel * cmupActuel;
    double valeurNouvellesEntrees = nouvelleQuantite * nouveauPrix;

    double quantiteTotale = stockActuel + nouvelleQuantite;

    if (quantiteTotale == 0) return nouveauPrix;

    double cmup = (valeurStockInitial + valeurNouvellesEntrees) / quantiteTotale;
    return cmup.roundToDouble();
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
        content: Text('Voulez-vous vraiment contre-passer l\'achat N° ${_numAchatsController.text} ?'),
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
      // Récupérer les lignes de l'achat à contre-passer
      final lignesAchat = await (_databaseService.database.select(_databaseService.database.detachats)
            ..where((d) => d.numachats.equals(_numAchatsController.text)))
          .get();

      // Annuler l'impact sur les stocks et recalculer les CMUP
      for (var ligne in lignesAchat) {
        Article? article = _articles.firstWhere(
          (a) => a.designation == ligne.designation,
          orElse: () => throw Exception('Article non trouvé'),
        );

        // Déduire les quantités des stocks
        if (ligne.unites == article.u1) {
          double newStock = (article.stocksu1 ?? 0) - (ligne.q ?? 0);
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu1: drift.Value(newStock >= 0 ? newStock : 0),
          ));
        } else if (ligne.unites == article.u2) {
          double newStock = (article.stocksu2 ?? 0) - (ligne.q ?? 0);
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu2: drift.Value(newStock >= 0 ? newStock : 0),
          ));
        } else if (ligne.unites == article.u3) {
          double newStock = (article.stocksu3 ?? 0) - (ligne.q ?? 0);
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu3: drift.Value(newStock >= 0 ? newStock : 0),
          ));
        }

        // Recalculer le CMUP après suppression
        await _recalculerCMUPApresAnnulation(article, ligne.q ?? 0, ligne.pu ?? 0);
      }

      // Supprimer les lignes d'achat
      await (_databaseService.database.delete(_databaseService.database.detachats)
            ..where((d) => d.numachats.equals(_numAchatsController.text)))
          .go();

      // Supprimer l'achat principal
      await (_databaseService.database.delete(_databaseService.database.achats)
            ..where((a) => a.numachats.equals(_numAchatsController.text)))
          .go();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat contre-passé avec succès')),
        );
        Navigator.of(context).pop();
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
    // Calculer le stock total actuel (toutes unités confondues en u1)
    double stockActuel = 0;
    stockActuel += article.stocksu1 ?? 0;
    if (article.u2 != null && article.tu2u1 != null) {
      stockActuel += (article.stocksu2 ?? 0) * article.tu2u1!;
    }
    if (article.u3 != null && article.tu3u2 != null && article.tu2u1 != null) {
      stockActuel += (article.stocksu3 ?? 0) * article.tu3u2! * article.tu2u1!;
    }

    double cmupActuel = article.cmup ?? 0.0;

    // Valeur totale avant annulation
    double valeurTotaleAvant = (stockActuel + quantiteAnnulee) * cmupActuel;

    // Valeur à retirer
    double valeurARetirer = quantiteAnnulee * prixAnnule;

    // Nouvelle valeur et nouveau CMUP
    double nouvelleValeur = valeurTotaleAvant - valeurARetirer;
    double nouveauCMUP = stockActuel > 0 ? nouvelleValeur / stockActuel : 0.0;

    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(article.designation)))
        .write(ArticlesCompanion(
      cmup: drift.Value(nouveauCMUP.roundToDouble()),
    ));
  }

  Future<void> _ouvrirApercuBR() async {
    if (_lignesAchat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun article à afficher')),
      );
      return;
    }

    List<String> dateParts = _dateController.text.split('-');
    DateTime dateForPreview =
        DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

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

  Future<void> _imprimerBR() async {
    if (_lignesAchat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun article à imprimer')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impression du BR N° ${_numAchatsController.text} en format $_selectedFormat')),
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
    _echeanceController.clear();
    _tvaController.text = '0';
    _totalHTController.text = '0';
    _totalTTCController.text = '0';
    _totalFMGController.text = '0';

    _resetArticleForm();

    // Générer un nouveau numéro d'achat
    final nextNum = await _getNextNumAchats();
    _numAchatsController.text = nextNum;

    // Remettre la date d'aujourd'hui
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
  }

  Future<void> _validerAchat() async {
    if (_selectedFournisseur == null || _lignesAchat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fournisseur et ajouter des articles')),
      );
      return;
    }

    try {
      // Convertir la date au format DateTime pour la base de données
      List<String> dateParts = _dateController.text.split('-');
      DateTime dateForDB =
          DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

      // Insérer l'achat principal
      await _databaseService.database.into(_databaseService.database.achats).insert(
            AchatsCompanion.insert(
              numachats: drift.Value(_numAchatsController.text),
              nfact: drift.Value(_nFactController.text.isEmpty ? null : _nFactController.text),
              daty: drift.Value(dateForDB),
              frns: drift.Value(_selectedFournisseur!),
              modepai: drift.Value(_selectedModePaiement),
              echeance: drift.Value(_echeanceController.text.isEmpty
                  ? null
                  : DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]))),
              totalnt: drift.Value(double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0.0),
              tva: drift.Value(double.tryParse(_tvaController.text) ?? 0.0),
              totalttc: drift.Value(double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0.0),
            ),
          );

      // Insérer les lignes d'achat et mettre à jour les stocks
      for (var ligne in _lignesAchat) {
        await _databaseService.database.into(_databaseService.database.detachats).insert(
              DetachatsCompanion.insert(
                numachats: drift.Value(_numAchatsController.text),
                designation: drift.Value(ligne['designation']),
                unites: drift.Value(ligne['unites']),
                depots: drift.Value(ligne['depot']),
                q: drift.Value(ligne['quantite']),
                pu: drift.Value(ligne['prixUnitaire']),
                daty: drift.Value(dateForDB),
              ),
            );

        // Mettre à jour le stock et le CMUP dans la table Articles
        Article? article = _articles.firstWhere(
          (a) => a.designation == ligne['designation'],
          orElse: () => throw Exception('Article non trouvé'),
        );

        // Calculer le nouveau CMUP
        double nouveauCMUP = await _calculerNouveauCMUP(article, ligne['quantite'], ligne['prixUnitaire']);

        // Mettre à jour les stocks de l'article selon l'unité et le CMUP
        if (ligne['unites'] == article.u1) {
          double newStock = (article.stocksu1 ?? 0) + ligne['quantite'];
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu1: drift.Value(newStock),
            cmup: drift.Value(nouveauCMUP),
          ));
        } else if (ligne['unites'] == article.u2) {
          double newStock = (article.stocksu2 ?? 0) + ligne['quantite'];
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu2: drift.Value(newStock),
            cmup: drift.Value(nouveauCMUP),
          ));
        } else if (ligne['unites'] == article.u3) {
          double newStock = (article.stocksu3 ?? 0) + ligne['quantite'];
          await (_databaseService.database.update(_databaseService.database.articles)
                ..where((a) => a.designation.equals(article.designation)))
              .write(ArticlesCompanion(
            stocksu3: drift.Value(newStock),
            cmup: drift.Value(nouveauCMUP),
          ));
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
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }
  }

  Widget _buildSearchDialog() {
    return StatefulBuilder(
      builder: (context, setState) {
        final TextEditingController filterController = TextEditingController();
        String filterText = '';

        return AlertDialog(
          title: const Text('Rechercher un achat', style: TextStyle(fontSize: 14)),
          content: SizedBox(
            width: 400,
            height: 350,
            child: Column(
              children: [
                TextField(
                  controller: filterController,
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par N°, Fournisseur ou Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      filterText = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<Achat>>(
                    future: _databaseService.database.select(_databaseService.database.achats).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final achats = snapshot.data!;
                      final filteredAchats = achats.where((achat) {
                        if (filterText.isEmpty) return true;

                        final numAchats = achat.numachats?.toLowerCase() ?? '';
                        final fournisseur = achat.frns?.toLowerCase() ?? '';
                        final dateStr = achat.daty != null
                            ? '${achat.daty!.day.toString().padLeft(2, '0')}-${achat.daty!.month.toString().padLeft(2, '0')}-${achat.daty!.year}'
                            : '';

                        return numAchats.contains(filterText) ||
                            fournisseur.contains(filterText) ||
                            dateStr.contains(filterText);
                      }).toList();

                      return ListView.builder(
                        itemCount: filteredAchats.length,
                        itemBuilder: (context, index) {
                          final achat = filteredAchats[index];
                          return ListTile(
                            title: Text('N° ${achat.numachats}', style: const TextStyle(fontSize: 12)),
                            subtitle: Text(
                              'Fournisseur: ${achat.frns ?? ""} - Date: ${achat.daty != null ? "${achat.daty!.day.toString().padLeft(2, '0')}-${achat.daty!.month.toString().padLeft(2, '0')}-${achat.daty!.year}" : ""}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            onTap: () {
                              Navigator.of(context).pop(achat.numachats);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        child: SizedBox(
          width: 950,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              // Top section with form fields
              Container(
                color: const Color(0xFFE6E6FA),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // Left side with Enregistrement button and Journal dropdown
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.green,
                          child: const Text(
                            'Enregistrement',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 100,
                          height: 25,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Journal', child: Text('Journal', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Achats', child: Text('Achats', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Caisse', child: Text('Caisse', style: TextStyle(fontSize: 12))),
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
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
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
                              const SizedBox(width: 32),
                              SizedBox(
                                width: 175,
                                height: 25,
                                child: ElevatedButton.icon(
                                  label: const Text("Historiques d'Achat"),
                                  icon: const Icon(Icons.history, size: 16),
                                  onPressed: () async {
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder: (context) => _buildSearchDialog(),
                                    );
                                    if (result != null) {
                                      _numAchatsController.text = result;
                                      _chargerAchatExistant(result);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: const Size(25, 25),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              const Text('Date', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 140,
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
                                      _dateController.text =
                                          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 32),
                              const Text('N° Facture/ BL', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                height: 25,
                                child: TextField(
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
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedFournisseur,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    ),
                                    items: _fournisseurs.map((frn) {
                                      return DropdownMenuItem(
                                        value: frn.rsoc,
                                        child: Text(frn.rsoc, style: const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFournisseur = value;
                                      });
                                    },
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
                                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                      _autocompleteController = controller;
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                          child:
                                              Text(article.designation, style: const TextStyle(fontSize: 12)),
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
                                          child: Text(depot.depots, style: const TextStyle(fontSize: 12)),
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
                                                ligne['quantite']?.toString() ?? '0',
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
                                                ligne['prixUnitaire']?.toString() ?? '0',
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
                                                _formatNumber(ligne['montant']?.toDouble() ?? 0),
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
                                      _echeanceController.text =
                                          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
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
                color: const Color(0xFFFFB6C1),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
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
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: _imprimerBR,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(80, 30)),
                      child: const Text('Imprimer BR', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 100,
                      height: 25,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          hintText: 'Recherche',
                          hintStyle: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isExistingPurchase ? _modifierAchat : _validerAchat,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
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
                    DropdownButton<String>(
                      value: _selectedFormat,
                      items: const [
                        DropdownMenuItem(value: 'A4', child: Text('A4', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'A5', child: Text('A5', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'A6', child: Text('A6', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFormat = value ?? 'A5';
                        });
                      },
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
    super.dispose();
  }
}
