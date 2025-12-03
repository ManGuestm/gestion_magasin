import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';
import '../common/article_navigation_autocomplete.dart';

class SurVentesModal extends StatefulWidget {
  const SurVentesModal({super.key});

  @override
  State<SurVentesModal> createState() => _SurVentesModalState();
}

class _SurVentesModalState extends State<SurVentesModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _numRetourController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final FocusNode _clientFocusNode = FocusNode();
  final TextEditingController _motifController = TextEditingController();
  final FocusNode _venteFocusNode = FocusNode();
  final FocusNode _motifFocusNode = FocusNode();

  List<CltData> _clients = [];
  List<Vente> _ventes = [];
  String? _selectedClient;
  String? _selectedVente;
  final List<Map<String, dynamic>> _lignesRetour = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeForm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clientFocusNode.requestFocus();
    });
  }

  void _initializeForm() {
    final now = DateTime.now();
    _dateController.text = app_date.AppDateUtils.formatDate(now);
    _generateNextNumRetour();
  }

  Future<void> _generateNextNumRetour() async {
    // Générer le prochain numéro de retour sur ventes
    final nextNum = 'RV${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _numRetourController.text = nextNum;
  }

  Future<void> _loadData() async {
    try {
      final clients = await _databaseService.database.getAllClients();
      setState(() {
        _clients = clients;
      });
    } catch (e) {
      // Error handled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _loadVentesForClient(String client) async {
    try {
      final ventes = await (_databaseService.database.select(_databaseService.database.ventes)
            ..where((v) => v.clt.equals(client))
            ..orderBy([(v) => drift.OrderingTerm.desc(v.daty)]))
          .get();
      setState(() {
        _ventes = ventes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des ventes: $e')),
        );
      }
    }
  }

  Future<void> _chargerArticlesVente() async {
    if (_selectedVente == null) return;

    try {
      final detailsVente = await (_databaseService.database.select(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(_selectedVente!)))
          .get();

      setState(() {
        _lignesRetour.clear();
        for (var detail in detailsVente) {
          final montant = (detail.q ?? 0.0) * (detail.pu ?? 0.0);
          _lignesRetour.add({
            'designation': detail.designation ?? '',
            'unite': detail.unites ?? '',
            'quantite': detail.q ?? 0.0,
            'quantiteRetour': detail.q ?? 0.0,
            'prixUnitaire': detail.pu ?? 0.0,
            'montant': montant,
            'montantRetour': montant,
            'depot': detail.depots ?? '',
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${detailsVente.length} article(s) chargé(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des articles: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            color: Colors.grey[100],
          ),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Title bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Retour sur Ventes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
              const Divider(height: 1),

              // Form section
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFE6E6FA),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // N° Retour
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('N° Retour:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _numRetourController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  fillColor: Color(0xFFF5F5F5),
                                  filled: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _dateController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  suffixIcon: Icon(Icons.calendar_today, size: 16),
                                ),
                                style: const TextStyle(fontSize: 12),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Client
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Client:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 32,
                                child: ArticleNavigationAutocomplete(
                                  articles: _clients.map((c) => Article(
                                    designation: c.rsoc,
                                    u1: '',
                                    u2: '',
                                    u3: '',
                                  )).toList(),
                                  onArticleChanged: (article) {
                                    if (article != null) {
                                      setState(() {
                                        _selectedClient = article.designation;
                                        _selectedVente = null;
                                        _ventes.clear();
                                      });
                                      _loadVentesForClient(article.designation);
                                    }
                                  },
                                  onTabPressed: () {
                                    debugPrint('Client: Tab pressed, moving to Vente');
                                    _venteFocusNode.requestFocus();
                                  },
                                  onShiftTabPressed: () {
                                    debugPrint('Client: Shift+Tab pressed, staying on Client');
                                    _clientFocusNode.requestFocus();
                                  },
                                  focusNode: _clientFocusNode,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    hintText: 'Sélectionner un client...',
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Vente de référence
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Vente de référence:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Focus(
                                focusNode: _venteFocusNode,
                                onKeyEvent: (node, event) {
                                  if (event.logicalKey == LogicalKeyboardKey.tab) {
                                    if (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                                        HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight)) {
                                      debugPrint('Vente: Shift+Tab pressed, moving to Client');
                                      _clientFocusNode.requestFocus();
                                    } else {
                                      debugPrint('Vente: Tab pressed, moving to Motif');
                                      _motifFocusNode.requestFocus();
                                    }
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedVente,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  items: _ventes.map((vente) {
                                    return DropdownMenuItem<String>(
                                      value: vente.numventes,
                                      child: Text('${vente.numventes} - ${vente.nfact ?? ''}',
                                          style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedVente = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Motif
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Motif du retour:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _motifController,
                          focusNode: _motifFocusNode,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            hintText: 'Saisir le motif du retour...',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Articles section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text('Désignation',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text('Unité',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text('Qté Retour',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text('Prix Unitaire',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text('Montant',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text('Action',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: _lignesRetour.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun article à retourner.\nSélectionnez une vente pour charger les articles.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _lignesRetour.length,
                                itemBuilder: (context, index) {
                                  final ligne = _lignesRetour[index];
                                  return Container(
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                      border: const Border(
                                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              ligne['designation'] ?? '',
                                              style: const TextStyle(fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Text(
                                              ligne['unite'] ?? '',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: TextField(
                                              controller: TextEditingController(
                                                text: NumberUtils.formatNumber(ligne['quantiteRetour'] ?? ligne['quantite'] ?? 0)
                                              ),
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              ),
                                              style: const TextStyle(fontSize: 10),
                                              textAlign: TextAlign.center,
                                              onChanged: (value) {
                                                final qte = double.tryParse(value.replaceAll(' ', '')) ?? 0;
                                                final qteMax = ligne['quantite'] ?? 0;
                                                if (qte > qteMax) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Quantité max: $qteMax')),
                                                  );
                                                  return;
                                                }
                                                setState(() {
                                                  ligne['quantiteRetour'] = qte;
                                                  ligne['montantRetour'] = qte * (ligne['prixUnitaire'] ?? 0);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Center(
                                            child: Text(
                                              NumberUtils.formatNumber(ligne['prixUnitaire'] ?? 0),
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Center(
                                            child: Text(
                                              NumberUtils.formatNumber(ligne['montantRetour'] ?? ligne['montant'] ?? 0),
                                              style:
                                                  const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                              onPressed: () {
                                                setState(() {
                                                  _lignesRetour.removeAt(index);
                                                });
                                              },
                                              padding: EdgeInsets.zero,
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
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedVente != null) {
                          _chargerArticlesVente();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez sélectionner une vente')),
                          );
                        }
                      },
                      child: const Text('Charger Articles'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _lignesRetour.isNotEmpty ? _saveRetourVente : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Valider Retour'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
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

  Future<void> _saveRetourVente() async {
    if (_selectedClient == null || _selectedVente == null || _lignesRetour.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    try {
      final numRetour = _numRetourController.text;
      List<String> dateParts = _dateController.text.split('/');
      DateTime dateForDB =
          DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

      double totalMontant = 0;
      for (var ligne in _lignesRetour) {
        totalMontant += ligne['montantRetour'] ?? 0;
      }

      // Enregistrer le retour sur vente
      final retourCompanion = RetventesCompanion(
        numventes: drift.Value(numRetour),
        daty: drift.Value(dateForDB),
        clt: drift.Value(_selectedClient!),
        totalttc: drift.Value(totalMontant),
      );

      await _databaseService.database.into(_databaseService.database.retventes).insert(retourCompanion);

      // Enregistrer les détails et mettre à jour le stock
      for (var ligne in _lignesRetour) {
        if ((ligne['quantiteRetour'] ?? 0) > 0) {
          final detailCompanion = RetdeventesCompanion(
            numventes: drift.Value(numRetour),
            designation: drift.Value(ligne['designation']),
            unites: drift.Value(ligne['unite']),
            depots: drift.Value(ligne['depot']),
            q: drift.Value(ligne['quantiteRetour']),
            pu: drift.Value(ligne['prixUnitaire']),
          );
          await _databaseService.database.into(_databaseService.database.retdeventes).insert(detailCompanion);

          // Mettre à jour le stock (ENTRÉE pour retour sur vente)
          await _mettreAJourStockRetourVente(
            ligne['designation'],
            ligne['depot'],
            ligne['unite'],
            ligne['quantiteRetour'],
          );
        }
      }

      // Ajuster le compte client (DIMINUER la dette)
      await _ajusterCompteClient(_selectedClient!, totalMontant);

      // Enregistrer le décaissement en caisse
      await _enregistrerDecaissement(numRetour, totalMontant);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retour sur vente enregistré avec succès')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _mettreAJourStockRetourVente(
      String designation, String depot, String unite, double quantite) async {
    try {
      // Créer un mouvement d'ENTRÉE de stock pour le retour sur vente
      final ref = 'RV${DateTime.now().millisecondsSinceEpoch}';
      await _databaseService.database.into(_databaseService.database.stocks).insert(
            StocksCompanion(
              ref: drift.Value(ref),
              daty: drift.Value(DateTime.now()),
              lib: drift.Value('RETOUR VENTE - $designation'),
              refart: drift.Value(designation),
              qe: drift.Value(quantite),
              entres: drift.Value(quantite),
              ue: drift.Value(unite),
              depots: drift.Value(depot),
            ),
          );

      // Récupérer l'article pour mettre à jour le stock global
      final article = await _databaseService.database.getArticleByDesignation(designation);
      if (article != null) {
        double nouvelleQuantiteU1 = article.stocksu1 ?? 0;
        double nouvelleQuantiteU2 = article.stocksu2 ?? 0;
        double nouvelleQuantiteU3 = article.stocksu3 ?? 0;

        // AJOUTER la quantité retournée selon l'unité dans la table articles
        if (unite == 'Ctn' || unite == 'Pck') {
          nouvelleQuantiteU1 += quantite;
        } else if (unite == 'Kg') {
          nouvelleQuantiteU2 += quantite;
        } else if (unite == 'L') {
          nouvelleQuantiteU3 += quantite;
        }

        // Mettre à jour le stock global dans la table articles
        await (_databaseService.database.update(_databaseService.database.articles)
              ..where((a) => a.designation.equals(designation)))
            .write(ArticlesCompanion(
          stocksu1: drift.Value(nouvelleQuantiteU1),
          stocksu2: drift.Value(nouvelleQuantiteU2),
          stocksu3: drift.Value(nouvelleQuantiteU3),
        ));
      }

      // Mettre à jour le stock dans la table depart (AUGMENTER le stock)
      final query = _databaseService.database.select(_databaseService.database.depart);
      query.where((d) => d.designation.equals(designation) & d.depots.equals(depot));
      final stockDepart = await query.getSingleOrNull();

      if (stockDepart != null) {
        double nouvelleQuantiteU1 = stockDepart.stocksu1 ?? 0;
        double nouvelleQuantiteU2 = stockDepart.stocksu2 ?? 0;
        double nouvelleQuantiteU3 = stockDepart.stocksu3 ?? 0;

        // AJOUTER la quantité retournée selon l'unité
        if (unite == 'Ctn' || unite == 'Pck') {
          nouvelleQuantiteU1 += quantite;
        } else if (unite == 'Kg') {
          nouvelleQuantiteU2 += quantite;
        } else if (unite == 'L') {
          nouvelleQuantiteU3 += quantite;
        }

        await (_databaseService.database.update(_databaseService.database.depart)
              ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
            .write(DepartCompanion(
          stocksu1: drift.Value(nouvelleQuantiteU1),
          stocksu2: drift.Value(nouvelleQuantiteU2),
          stocksu3: drift.Value(nouvelleQuantiteU3),
        ));
      } else {
        // Créer une nouvelle entrée si elle n'existe pas
        double stockU1 = 0, stockU2 = 0, stockU3 = 0;
        if (unite == 'Ctn' || unite == 'Pck') {
          stockU1 = quantite;
        } else if (unite == 'Kg') {
          stockU2 = quantite;
        } else if (unite == 'L') {
          stockU3 = quantite;
        }

        await _databaseService.database.into(_databaseService.database.depart).insert(
              DepartCompanion(
                designation: drift.Value(designation),
                depots: drift.Value(depot),
                stocksu1: drift.Value(stockU1),
                stocksu2: drift.Value(stockU2),
                stocksu3: drift.Value(stockU3),
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur mise à jour stock: $e')),
        );
      }
    }
  }

  Future<void> _ajusterCompteClient(String client, double montant) async {
    try {
      final compteClient = await (_databaseService.database.select(_databaseService.database.compteclt)
            ..where((c) => c.clt.equals(client)))
          .getSingleOrNull();

      if (compteClient != null) {
        final nouveauSolde = (compteClient.solde ?? 0) - montant;
        await (_databaseService.database.update(_databaseService.database.compteclt)
              ..where((c) => c.clt.equals(client)))
            .write(ComptecltCompanion(
          solde: drift.Value(nouveauSolde),
        ));
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _enregistrerDecaissement(String numRetour, double montant) async {
    try {
      await _databaseService.database.into(_databaseService.database.caisse).insert(
            CaisseCompanion(
              ref: drift.Value('RV${DateTime.now().millisecondsSinceEpoch}'),
              daty: drift.Value(DateTime.now()),
              lib: drift.Value('Retour sur ventes - $numRetour'),
              debit: drift.Value(montant),
              type: drift.Value('Retour sur ventes'),
            ),
          );
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _numRetourController.dispose();
    _dateController.dispose();
    _clientController.dispose();
    _clientFocusNode.dispose();
    _venteFocusNode.dispose();
    _motifController.dispose();
    _motifFocusNode.dispose();
    super.dispose();
  }
}
