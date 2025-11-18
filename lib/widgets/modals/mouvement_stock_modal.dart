import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../mixins/form_navigation_mixin.dart';
import '../../services/stock_management_service.dart';
import '../common/base_modal.dart';

class MouvementStockModal extends StatefulWidget {
  final String? refArticle;
  final TypeMouvement? typeMouvement;

  const MouvementStockModal({
    super.key,
    this.refArticle,
    this.typeMouvement,
  });

  @override
  State<MouvementStockModal> createState() => _MouvementStockModalState();
}

class _MouvementStockModalState extends State<MouvementStockModal> with FormNavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _refArticleController = TextEditingController();
  final _depotController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _prixController = TextEditingController();
  final _numeroDocController = TextEditingController();
  final _clientController = TextEditingController();
  final _fournisseurController = TextEditingController();
  final _libelleController = TextEditingController();

  TypeMouvement _typeMouvement = TypeMouvement.entree;
  String? _uniteEntree;
  String? _uniteSortie;
  List<String> _unitesDisponibles = [];
  String? _selectedDepot;
  List<String> _depotsDisponibles = [];
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _chargerDepots();
    if (widget.refArticle != null) {
      _refArticleController.text = widget.refArticle!;
      _chargerUnitesArticle();
    }
    if (widget.typeMouvement != null) {
      _typeMouvement = widget.typeMouvement!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusFirstField();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Mouvement de Stock',
      width: 600,
      height: 550,
      onSave: _enregistrerMouvement,
      content: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTypeMouvement(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: buildFormField(
                      controller: _refArticleController,
                      label: 'Référence Article',
                      autofocus: true,
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                      onChanged: (value) => _chargerUnitesArticle(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDepot,
                      decoration: const InputDecoration(
                        labelText: 'Dépôt',
                        border: OutlineInputBorder(),
                      ),
                      items: _depotsDisponibles.map((depot) {
                        return DropdownMenuItem(value: depot, child: Text(depot));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDepot = value),
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: buildFormField(
                      controller: _quantiteController,
                      label: 'Quantité',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildFormField(
                      controller: _prixController,
                      label: 'Prix Unitaire',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildFormField(
                controller: _numeroDocController,
                label: 'N° Document',
              ),
              const SizedBox(height: 16),

              buildFormField(
                controller: _libelleController,
                label: 'Libellé',
              ),
              const SizedBox(height: 16),
              _buildUnites(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeMouvement() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Type de mouvement:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [TypeMouvement.entree, TypeMouvement.sortie].map((type) {
              return GestureDetector(
                onTap: () => setState(() => _typeMouvement = type),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: _typeMouvement == type ? Colors.blue.shade100 : Colors.white,
                    border: Border.all(
                      color: _typeMouvement == type ? Colors.blue : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type == TypeMouvement.entree ? Icons.add_circle_outline : Icons.remove_circle_outline,
                        color: _typeMouvement == type ? Colors.blue : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTypeLabel(type),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _typeMouvement == type ? Colors.blue.shade700 : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            type == TypeMouvement.entree ? 'Ajouter du stock' : 'Retirer du stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: _typeMouvement == type ? Colors.blue.shade600 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUnites() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _uniteEntree,
            decoration: const InputDecoration(
              labelText: 'Unité Entrée',
              border: OutlineInputBorder(),
            ),
            items: _unitesDisponibles.map((unite) {
              return DropdownMenuItem(value: unite, child: Text(unite));
            }).toList(),
            onChanged: (value) => setState(() => _uniteEntree = value),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _uniteSortie,
            decoration: const InputDecoration(
              labelText: 'Unité Sortie',
              border: OutlineInputBorder(),
            ),
            items: _unitesDisponibles.map((unite) {
              return DropdownMenuItem(value: unite, child: Text(unite));
            }).toList(),
            onChanged: (value) => setState(() => _uniteSortie = value),
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(TypeMouvement type) {
    switch (type) {
      case TypeMouvement.entree:
        return 'Entrée Stock';
      case TypeMouvement.sortie:
        return 'Sortie Stock';
      default:
        return 'Mouvement';
    }
  }

  Future<void> _enregistrerMouvement() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final designation = _refArticleController.text;
      final depot = _selectedDepot ?? '';
      final quantite = double.parse(_quantiteController.text);
      final prix = double.parse(_prixController.text);
      final unite = _uniteEntree ?? '';
      final libelle = _libelleController.text.isEmpty
          ? 'Mouvement ${_getTypeLabel(_typeMouvement)}'
          : _libelleController.text;

      await _databaseService.database.transaction(() async {
        // 1. Enregistrer dans la table stocks (historique)
        await _enregistrerDansStocks(designation, depot, quantite, prix, unite, libelle);

        // 2. Mettre à jour la table fstocks (fiche stock)
        await _mettreAJourFstocks(designation, quantite, unite);

        // 3. Mettre à jour la table articles (stock global)
        await _mettreAJourArticles(designation, quantite, unite);

        // 4. Mettre à jour la table depart (stock par dépôt)
        await _mettreAJourDepart(designation, depot, quantite, unite);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mouvement enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _chargerDepots() async {
    try {
      final depots = await _databaseService.database.getAllDepots();
      setState(() {
        _depotsDisponibles = depots.map((d) => d.depots).toList();
        _selectedDepot = _depotsDisponibles.isNotEmpty ? _depotsDisponibles.first : null;
      });
    } catch (e) {
      setState(() {
        _depotsDisponibles = [];
        _selectedDepot = null;
      });
    }
  }

  Future<void> _chargerUnitesArticle() async {
    if (_refArticleController.text.isEmpty) {
      setState(() {
        _unitesDisponibles = [];
        _uniteEntree = null;
        _uniteSortie = null;
      });
      return;
    }

    try {
      final article = await _databaseService.database.getArticleByDesignation(_refArticleController.text);

      if (article != null) {
        final unites = <String>[];
        if (article.u1?.isNotEmpty == true) unites.add(article.u1!);
        if (article.u2?.isNotEmpty == true) unites.add(article.u2!);
        if (article.u3?.isNotEmpty == true) unites.add(article.u3!);

        setState(() {
          _unitesDisponibles = unites;
          _uniteEntree = unites.isNotEmpty ? unites.first : null;
          _uniteSortie = unites.isNotEmpty ? unites.first : null;
        });
      }
    } catch (e) {
      setState(() {
        _unitesDisponibles = [];
        _uniteEntree = null;
        _uniteSortie = null;
      });
    }
  }

  Future<void> _enregistrerDansStocks(
      String designation, String depot, double quantite, double prix, String unite, String libelle) async {
    final ref = 'MVT${DateTime.now().millisecondsSinceEpoch}';
    final isEntree = _typeMouvement == TypeMouvement.entree;

    await _databaseService.database.into(_databaseService.database.stocks).insert(
          StocksCompanion(
            ref: drift.Value(ref),
            daty: drift.Value(DateTime.now()),
            lib: drift.Value(libelle),
            refart: drift.Value(designation),
            qe: drift.Value(isEntree ? quantite : 0),
            entres: drift.Value(isEntree ? quantite : 0),
            qs: drift.Value(!isEntree ? quantite : 0),
            sortie: drift.Value(!isEntree ? quantite : 0),
            pus: drift.Value(prix),
            ue: drift.Value(unite),
            us: drift.Value(unite),
            depots: drift.Value(depot),

            verification: drift.Value(_getTypeLabel(_typeMouvement)),
          ),
        );
  }

  Future<void> _mettreAJourFstocks(String designation, double quantite, String unite) async {
    final ref = 'FS_${designation}_${DateTime.now().millisecondsSinceEpoch}';
    final isEntree = _typeMouvement == TypeMouvement.entree;

    // Vérifier si une fiche existe déjà
    final ficheExistante = await (_databaseService.database.select(_databaseService.database.fstocks)
          ..where((f) => f.art.equals(designation)))
        .getSingleOrNull();

    if (ficheExistante != null) {
      // Mettre à jour la fiche existante
      final nouvelleQe = (ficheExistante.qe ?? 0) + (isEntree ? quantite : 0);
      final nouvelleQs = (ficheExistante.qs ?? 0) + (!isEntree ? quantite : 0);
      final nouveauQst = nouvelleQe - nouvelleQs;

      await (_databaseService.database.update(_databaseService.database.fstocks)
            ..where((f) => f.ref.equals(ficheExistante.ref)))
          .write(FstocksCompanion(
        qe: drift.Value(nouvelleQe),
        qs: drift.Value(nouvelleQs),
        qst: drift.Value(nouveauQst),
      ));
    } else {
      // Créer une nouvelle fiche
      await _databaseService.database.into(_databaseService.database.fstocks).insert(
            FstocksCompanion(
              ref: drift.Value(ref),
              art: drift.Value(designation),
              qe: drift.Value(isEntree ? quantite : 0),
              qs: drift.Value(!isEntree ? quantite : 0),
              qst: drift.Value(isEntree ? quantite : -quantite),
              ue: drift.Value(unite),
            ),
          );
    }
  }

  Future<void> _mettreAJourArticles(String designation, double quantite, String unite) async {
    final article = await _databaseService.database.getArticleByDesignation(designation);
    if (article == null) return;

    final isEntree = _typeMouvement == TypeMouvement.entree;
    final facteur = isEntree ? 1 : -1;

    double deltaU1 = 0, deltaU2 = 0;

    if (unite == article.u1) {
      deltaU1 = quantite * facteur;
    } else if (unite == article.u2) {
      deltaU2 = quantite * facteur;
    }

    await (_databaseService.database.update(_databaseService.database.articles)
          ..where((a) => a.designation.equals(designation)))
        .write(ArticlesCompanion(
      stocksu1: drift.Value((article.stocksu1 ?? 0) + deltaU1),
      stocksu2: drift.Value((article.stocksu2 ?? 0) + deltaU2),
    ));
  }

  Future<void> _mettreAJourDepart(String designation, String depot, double quantite, String unite) async {
    final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
        .getSingleOrNull();

    final article = await _databaseService.database.getArticleByDesignation(designation);
    if (article == null) return;

    final isEntree = _typeMouvement == TypeMouvement.entree;
    final facteur = isEntree ? 1 : -1;

    double deltaU1 = 0, deltaU2 = 0;

    if (unite == article.u1) {
      deltaU1 = quantite * facteur;
    } else if (unite == article.u2) {
      deltaU2 = quantite * facteur;
    }

    if (stockDepart != null) {
      // Mettre à jour le stock existant
      await (_databaseService.database.update(_databaseService.database.depart)
            ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
          .write(DepartCompanion(
        stocksu1: drift.Value((stockDepart.stocksu1 ?? 0) + deltaU1),
        stocksu2: drift.Value((stockDepart.stocksu2 ?? 0) + deltaU2),
      ));
    } else {
      // Créer une nouvelle entrée
      await _databaseService.database.into(_databaseService.database.depart).insert(
            DepartCompanion(
              designation: drift.Value(designation),
              depots: drift.Value(depot),
              stocksu1: drift.Value(deltaU1),
              stocksu2: drift.Value(deltaU2),
              stocksu3: const drift.Value(0),
            ),
          );
    }
  }

  @override
  void dispose() {
    _refArticleController.dispose();
    _depotController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _numeroDocController.dispose();
    _clientController.dispose();
    _fournisseurController.dispose();
    _libelleController.dispose();
    super.dispose();
  }
}
