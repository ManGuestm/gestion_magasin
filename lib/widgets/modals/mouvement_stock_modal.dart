import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

import '../../services/stock_management_service.dart';
import '../common/base_modal.dart';
import '../common/tab_navigation_widget.dart';

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

class _MouvementStockModalState extends State<MouvementStockModal>
    with TabNavigationMixin {
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

  Future<void> _chargerDepots() async {
    try {
      final depots = await _databaseService.database.getAllDepots();
      setState(() {
        _depotsDisponibles = depots.map((d) => d.depots).toList();
      });
    } catch (e) {
      debugPrint('Erreur chargement dépôts: $e');
    }
  }

  Future<void> _chargerUnitesArticle() async {
    if (_refArticleController.text.isEmpty) return;

    try {
      final article = await _databaseService.database.getArticleByDesignation(_refArticleController.text);
      if (article != null) {
        final unites = <String>[];
        if (article.u1?.isNotEmpty == true) unites.add(article.u1!);
        if (article.u2?.isNotEmpty == true) unites.add(article.u2!);
        if (article.u3?.isNotEmpty == true) unites.add(article.u3!);

        setState(() {
          _unitesDisponibles = unites;
          if (unites.isNotEmpty) {
            _uniteEntree = unites.first;
            _uniteSortie = unites.first;
          }
          // Calculer le prix unitaire basé sur le CMUP
          _calculerPrixUnitaire(article);
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement unités: $e');
    }
  }

  void _calculerPrixUnitaire(Article article) {
    final cmup = article.cmup ?? 0.0;
    if (cmup > 0) {
      _prixController.text = cmup.toStringAsFixed(2);
    }
  }

  Future<void> _enregistrerMouvement() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un dépôt')),
      );
      return;
    }

    try {
      final ref = 'MVT${DateTime.now().millisecondsSinceEpoch}';
      final quantite = double.parse(_quantiteController.text);
      final prix = double.parse(_prixController.text);
      final designation = _refArticleController.text;
      final depot = _selectedDepot!;

      await _databaseService.database.transaction(() async {
        // 1. Créer le mouvement de stock
        final stockCompanion = StocksCompanion.insert(
          ref: ref,
          daty: Value(DateTime.now()),
          lib: Value(_libelleController.text.isEmpty
              ? '${_typeMouvement == TypeMouvement.entree ? "Entrée" : "Sortie"} - $designation'
              : _libelleController.text),
          refart: Value(designation),
          depots: Value(depot),
          qe: Value(_typeMouvement == TypeMouvement.entree ? quantite : 0),
          entres: Value(_typeMouvement == TypeMouvement.entree ? quantite : 0),
          qs: Value(_typeMouvement == TypeMouvement.sortie ? quantite : 0),
          sortie: Value(_typeMouvement == TypeMouvement.sortie ? quantite : 0),
          pus: Value(prix),
          ue: Value(_uniteEntree ?? _unitesDisponibles.first),
          us: Value(_uniteSortie ?? _unitesDisponibles.first),
          numachats: Value(_numeroDocController.text.isEmpty ? null : _numeroDocController.text),
          numventes: Value(_numeroDocController.text.isEmpty ? null : _numeroDocController.text),
          clt: Value(_clientController.text.isEmpty ? null : _clientController.text),
          frns: Value(_fournisseurController.text.isEmpty ? null : _fournisseurController.text),
          verification: Value(_typeMouvement == TypeMouvement.entree ? 'ENTREE' : 'SORTIE'),
        );

        await _databaseService.database.insertStock(stockCompanion);

        // 2. Mettre à jour le stock par dépôt (table depart)
        await _mettreAJourStockDepart(designation, depot, quantite);

        // 3. Mettre à jour le stock global (table articles)
        await _mettreAJourStockArticle(designation, quantite, prix);

        // 4. Mettre à jour les fiches stocks si nécessaire
        await _mettreAJourFicheStock(designation, quantite);
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mouvement validé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _mettreAJourStockDepart(String designation, String depot, double quantite) async {
    // Récupérer le stock actuel
    final stockActuel = await _databaseService.database.customSelect(
        'SELECT * FROM depart WHERE designation = ? AND depots = ?',
        variables: [Variable(designation), Variable(depot)]).getSingleOrNull();

    if (stockActuel == null) {
      // Créer nouveau stock
      await _databaseService.database.customStatement(
          'INSERT INTO depart (designation, depots, stocksu1, stocksu2, stocksu3) VALUES (?, ?, ?, 0, 0)',
          [designation, depot, _typeMouvement == TypeMouvement.entree ? quantite : -quantite]);
    } else {
      // Mettre à jour stock existant
      final stockU1Actuel = stockActuel.read<double?>('stocksu1') ?? 0;
      final nouveauStock =
          _typeMouvement == TypeMouvement.entree ? stockU1Actuel + quantite : stockU1Actuel - quantite;

      await _databaseService.database.customStatement(
          'UPDATE depart SET stocksu1 = ? WHERE designation = ? AND depots = ?',
          [nouveauStock, designation, depot]);
    }
  }

  Future<void> _mettreAJourStockArticle(String designation, double quantite, double prix) async {
    // Récupérer l'article
    final article = await _databaseService.database.getArticleByDesignation(designation);
    if (article == null) return;

    // Calculer le nouveau stock global
    final stockActuel = article.stocksu1 ?? 0;
    final nouveauStock =
        _typeMouvement == TypeMouvement.entree ? stockActuel + quantite : stockActuel - quantite;

    // Calculer le nouveau CMUP si c'est une entrée
    double? nouveauCmup;
    if (_typeMouvement == TypeMouvement.entree) {
      final ancienneValeur = stockActuel * (article.cmup ?? 0);
      final nouvelleValeur = quantite * prix;
      final quantiteTotale = stockActuel + quantite;

      if (quantiteTotale > 0) {
        nouveauCmup = (ancienneValeur + nouvelleValeur) / quantiteTotale;
      }
    }

    // Mettre à jour l'article
    await _databaseService.database.customStatement(
        'UPDATE articles SET stocksu1 = ?, cmup = ? WHERE designation = ?',
        [nouveauStock, nouveauCmup ?? article.cmup, designation]);
  }

  Future<void> _mettreAJourFicheStock(String designation, double quantite) async {
    // Vérifier si une fiche stock existe
    final ficheStock = await _databaseService.database.customSelect('SELECT * FROM fstocks WHERE art = ?',
        variables: [Variable(designation)]).getSingleOrNull();

    if (ficheStock != null) {
      // Mettre à jour la fiche stock existante
      final qeActuel = ficheStock.read<double?>('qe') ?? 0;
      final qsActuel = ficheStock.read<double?>('qs') ?? 0;
      final qstActuel = ficheStock.read<double?>('qst') ?? 0;

      if (_typeMouvement == TypeMouvement.entree) {
        await _databaseService.database.customStatement('UPDATE fstocks SET qe = ?, qst = ? WHERE art = ?',
            [qeActuel + quantite, qstActuel + quantite, designation]);
      } else {
        await _databaseService.database.customStatement('UPDATE fstocks SET qs = ?, qst = ? WHERE art = ?',
            [qsActuel + quantite, qstActuel - quantite, designation]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Mouvement de Stock',
      width: 600,
      height: 550,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _enregistrerMouvement,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Valider'),
        ),
      ],
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
