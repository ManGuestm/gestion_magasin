import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';

class RetoursAchatsModal extends StatefulWidget {
  const RetoursAchatsModal({super.key});

  @override
  State<RetoursAchatsModal> createState() => _RetoursAchatsModalState();
}

class _RetoursAchatsModalState extends State<RetoursAchatsModal> {
  final DatabaseService _databaseService = DatabaseService();

  // Controllers
  final TextEditingController _numAchatsController = TextEditingController();
  final TextEditingController _nFactController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _echeanceController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();

  List<Frn> _fournisseurs = [];
  List<MpData> _modesPaiement = [];
  List<Article> _articles = [];
  List<Depot> _depots = [];
  List<Achat> _achats = [];
  final List<Map<String, dynamic>> _articlesAchetes = [];
  final List<Map<String, dynamic>> _articlesRetour = [];

  String? _selectedFournisseur;
  String? _selectedModePaiement;
  String? _selectedArticle;
  String? _selectedUnite;
  String? _selectedDepot;
  String? _selectedNumAchats;
  double _totalHT = 0;
  double _totalTTC = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeForm();
  }

  void _initializeForm() {
    final now = DateTime.now();
    _dateController.text = app_date.AppDateUtils.formatDate(now);
    _echeanceController.text = app_date.AppDateUtils.formatDate(now);
  }

  Future<void> _loadData() async {
    try {
      final db = _databaseService.database;
      final fournisseurs = await db.getAllFournisseurs();
      final modesPaiement = await db.select(db.mp).get();
      final articles = await db.getAllArticles();
      final depots = await db.getAllDepots();
      final achats = await db.getAllAchats();

      setState(() {
        _fournisseurs = fournisseurs;
        _modesPaiement = modesPaiement;
        _articles = articles;
        _depots = depots;
        _achats = achats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  /// Charger les articles d'un achat en fonction du numéro de l'achat sélectionné.
  ///
  /// Si le numéro de l'achat est null, la fonction ne fait rien.
  ///
  /// La fonction charge les détails des articles d'un achat via la base de données, puis les stocke dans `_articlesAchetes`.
  /// En cas d'erreur, un message d'erreur est affiché via un `SnackBar`.
  Future<void> _chargerArticlesAchetes() async {
    if (_selectedNumAchats == null) return;

    try {
      final db = _databaseService.database;

      // Méthode alternative: Utiliser une requête directe
      final detailsAchats =
          await (db.select(db.detachats)..where((d) => d.numachats.equals(_selectedNumAchats!))).get();

      final List<Map<String, dynamic>> articlesData = <Map<String, dynamic>>[];
      for (final d in detailsAchats) {
        final item = <String, dynamic>{
          'designation': d.designation ?? '',
          'unite': d.unites ?? '',
          'quantite': d.q ?? 0.0,
          'prix': d.pu ?? 0.0,
          'depot': d.depots ?? '',
          'quantiteRetournee': 0.0,
        };
        articlesData.add(item);
      }

      if (mounted) {
        setState(() {
          _articlesAchetes.clear();
          _articlesAchetes.addAll(articlesData);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des articles: $e')),
        );
      }
    }
  }

  void _retournerArticle(int index, double quantiteRetour) {
    final article = _articlesAchetes[index];
    final quantiteDisponible = (article['quantite'] ?? 0) - (article['quantiteRetournee'] ?? 0);

    if (quantiteRetour <= 0 || quantiteRetour > quantiteDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantité invalide. Maximum disponible: $quantiteDisponible')),
      );
      return;
    }

    setState(() {
      _articlesAchetes[index]['quantiteRetournee'] = (article['quantiteRetournee'] ?? 0) + quantiteRetour;

      _articlesRetour.add({
        'designation': article['designation'],
        'unite': article['unite'],
        'quantite': quantiteRetour,
        'prix': article['prix'],
        'montant': quantiteRetour * (article['prix'] ?? 0),
        'depot': article['depot'],
      });
      _calculerTotaux();
    });
  }

  void _ajouterArticleRetour() {
    if (_selectedArticle == null || _selectedUnite == null || _selectedDepot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un article, une unité et un dépôt')),
      );
      return;
    }

    final quantite = double.tryParse(_quantiteController.text) ?? 0;
    final prix = double.tryParse(_prixController.text) ?? 0;

    if (quantite <= 0 || prix <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une quantité et un prix valides')),
      );
      return;
    }

    setState(() {
      _articlesRetour.add({
        'designation': _selectedArticle!,
        'unite': _selectedUnite!,
        'quantite': quantite,
        'prix': prix,
        'montant': quantite * prix,
        'depot': _selectedDepot!,
      });
      _calculerTotaux();
    });

    _quantiteController.clear();
    _prixController.clear();
  }

  void _supprimerArticleRetour(int index) {
    setState(() {
      _articlesRetour.removeAt(index);
      _calculerTotaux();
    });
  }

  void _clearForm() {
    setState(() {
      _selectedFournisseur = null;
      _selectedModePaiement = null;
      _selectedArticle = null;
      _selectedUnite = null;
      _selectedDepot = null;
      _selectedNumAchats = null;
      _articlesAchetes.clear();
      _articlesRetour.clear();
      _totalHT = 0;
      _totalTTC = 0;
    });

    _numAchatsController.clear();
    _nFactController.clear();
    _quantiteController.clear();
    _prixController.clear();
    _initializeForm();
  }

  void _calculerTotaux() {
    double total = 0;
    for (var article in _articlesRetour) {
      total += article['montant'] ?? 0;
    }
    setState(() {
      _totalHT = total;
      _totalTTC = total;
    });
  }

  Future<void> _saveRetour() async {
    if (_selectedFournisseur == null || _articlesRetour.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fournisseur et ajouter des articles')),
      );
      return;
    }

    try {
      final numRetour = 'RET${DateTime.now().millisecondsSinceEpoch}';
      List<String> dateParts = _dateController.text.split('-');
      DateTime dateForDB =
          DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));

      DateTime? echeanceForDB;
      if (_echeanceController.text.isNotEmpty) {
        List<String> echeanceParts = _echeanceController.text.split('-');
        echeanceForDB =
            DateTime(int.parse(echeanceParts[2]), int.parse(echeanceParts[1]), int.parse(echeanceParts[0]));
      }

      final retourCompanion = RetachatsCompanion(
        numachats: Value(numRetour),
        nfact: Value(_nFactController.text.trim()),
        daty: Value(dateForDB),
        frns: Value(_selectedFournisseur!),
        modepai: Value(_selectedModePaiement),
        echeance: Value(echeanceForDB),
        totalnt: Value(_totalHT),
        totalttc: Value(_totalTTC),
        tva: const Value(0),
        verification: const Value(null),
      );

      await _databaseService.database.into(_databaseService.database.retachats).insert(retourCompanion);

      for (var article in _articlesRetour) {
        final detailCompanion = RetdetachatsCompanion(
          numachats: Value(numRetour),
          designation: Value(article['designation']),
          unite: Value(article['unite']),
          depots: Value(article['depot']),
          q: Value(article['quantite']),
          pu: Value(article['prix']),
        );
        await _databaseService.database.into(_databaseService.database.retdetachats).insert(detailCompanion);

        // Mettre à jour le stock
        await _mettreAJourStock(
          article['designation'],
          article['depot'],
          article['unite'],
          article['quantite'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retour d\'achat enregistré avec succès')),
        );
      }

      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'RETOUR SUR ACHATS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Header section
            Container(
              color: const Color(0xFFE6E6FA),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                          width: 80,
                          child: Text('N° Achats:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      SizedBox(
                        width: 120,
                        height: 20,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedNumAchats,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                          items: _achats
                              .map((achat) => DropdownMenuItem<String>(
                                    value: achat.numachats,
                                    child: Text(achat.numachats ?? '', style: const TextStyle(fontSize: 10)),
                                  ))
                              .toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedNumAchats = value;
                              _numAchatsController.text = value ?? '';
                            });
                            if (value != null) {
                              _chargerArticlesAchetes(); // Appel direct sans utiliser la valeur de retour
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Text('Date:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 100,
                        height: 20,
                        child: TextField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                          style: const TextStyle(fontSize: 10),
                          readOnly: true,
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
                      const SizedBox(width: 20),
                      const Text('N° Facture/ BL:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        height: 20,
                        child: TextField(
                          controller: _nFactController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Fournisseurs:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 20,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedFournisseur,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            items: _fournisseurs
                                .map((frn) => DropdownMenuItem<String>(
                                      value: frn.rsoc,
                                      child: Text(frn.rsoc, style: const TextStyle(fontSize: 10)),
                                    ))
                                .toList(),
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

            Expanded(
              child: Column(
                children: [
                  // Articles section with dropdowns
                  Container(
                    color: Colors.blue.shade100,
                    padding: const EdgeInsets.all(4),
                    child: const Row(
                      children: [
                        Text('Désignation Articles',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(width: 20),
                        Text('Unités', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(width: 20),
                        Text('Quantités', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(width: 20),
                        Text('P.U HT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(width: 20),
                        Text('Dépôts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.blue.shade50,
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 20,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedArticle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            items: _articles
                                .map((article) => DropdownMenuItem<String>(
                                      value: article.designation,
                                      child: Text(article.designation, style: const TextStyle(fontSize: 10)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedArticle = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 60,
                          height: 20,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedUnite,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Pck', child: Text('Pck', style: TextStyle(fontSize: 10))),
                              DropdownMenuItem(
                                  value: 'Kg', child: Text('Kg', style: TextStyle(fontSize: 10))),
                              DropdownMenuItem(value: 'L', child: Text('L', style: TextStyle(fontSize: 10))),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedUnite = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 60,
                          height: 20,
                          child: TextField(
                            controller: _quantiteController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            style: const TextStyle(fontSize: 10),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 80,
                          height: 20,
                          child: TextField(
                            controller: _prixController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            style: const TextStyle(fontSize: 10),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 80,
                          height: 20,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedDepot,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            items: _depots
                                .map((depot) => DropdownMenuItem<String>(
                                      value: depot.depots,
                                      child: Text(depot.depots, style: const TextStyle(fontSize: 10)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDepot = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _ajouterArticleRetour,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(50, 20),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const Text('Ajouter', style: TextStyle(fontSize: 9)),
                        ),
                      ],
                    ),
                  ),

                  // Articles achetés section
                  if (_articlesAchetes.isNotEmpty) ...[
                    Container(
                      color: Colors.green.shade100,
                      padding: const EdgeInsets.all(4),
                      child: const Text('Articles achetés - Cliquez pour retourner',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      height: 150,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        itemCount: _articlesAchetes.length,
                        itemBuilder: (context, index) {
                          final article = _articlesAchetes[index];
                          final quantiteDisponible =
                              (article['quantite'] ?? 0) - (article['quantiteRetournee'] ?? 0);
                          return Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(article['designation'] ?? '',
                                        style: const TextStyle(fontSize: 9)),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('${article['unite']}',
                                      style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('$quantiteDisponible',
                                      style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('${article['prix']}',
                                      style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                      hintText: 'Qté',
                                    ),
                                    style: const TextStyle(fontSize: 8),
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (value) {
                                      final qte = double.tryParse(value) ?? 0;
                                      if (qte > 0) _retournerArticle(index, qte);
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: quantiteDisponible > 0
                                      ? () {
                                          _retournerArticle(index, quantiteDisponible);
                                        }
                                      : null,
                                  icon: const Icon(Icons.keyboard_return, size: 12),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Articles à retourner table
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          // Table header
                          Container(
                            color: Colors.grey.shade200,
                            padding: const EdgeInsets.all(4),
                            child: const Row(
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: Text('ARTICLES À RETOURNER',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 1,
                                    child: Text('UNITES',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 1,
                                    child: Text('QUANTITES',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text('PRIX UNITAIRE (HT)',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text('MONTANT',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 1,
                                    child: Text('DEPOTS',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          // Table content
                          Expanded(
                            child: _articlesRetour.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Aucun article à retourner.\nSélectionnez un N° Achats et retournez des articles.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _articlesRetour.length,
                                    itemBuilder: (context, index) {
                                      final article = _articlesRetour[index];
                                      return Container(
                                        height: 25,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
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
                                                  article['designation'],
                                                  style: const TextStyle(fontSize: 9),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                article['unite'],
                                                style: const TextStyle(fontSize: 9),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                NumberUtils.formatNumber(article['quantite']),
                                                style: const TextStyle(fontSize: 9),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                NumberUtils.formatNumber(article['prix']),
                                                style: const TextStyle(fontSize: 9),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                NumberUtils.formatNumber(article['montant']),
                                                style:
                                                    const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                article['depot'],
                                                style: const TextStyle(fontSize: 9),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 20,
                                              child: IconButton(
                                                onPressed: () => _supprimerArticleRetour(index),
                                                icon: const Icon(Icons.delete, size: 12, color: Colors.red),
                                                padding: EdgeInsets.zero,
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

                  // Bottom section
                  Container(
                    color: const Color(0xFFE6E6FA),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        // Left side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Mode de paiement:',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 150,
                                    height: 20,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedModePaiement,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      ),
                                      items: _modesPaiement
                                          .map((mp) => DropdownMenuItem<String>(
                                                value: mp.mp,
                                                child: Text(mp.mp, style: const TextStyle(fontSize: 10)),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedModePaiement = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Echéance (Date):',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 100,
                                    height: 20,
                                    child: TextField(
                                      controller: _echeanceController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      ),
                                      style: const TextStyle(fontSize: 10),
                                      readOnly: true,
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
                            ],
                          ),
                        ),
                        // Right side - Totals
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Text('Total HT:',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    NumberUtils.formatNumber(_totalHT),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            const Row(
                              children: [
                                Text('TVA:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    '00',
                                    style: TextStyle(fontSize: 11),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Total TTC:',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    NumberUtils.formatNumber(_totalTTC),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
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
                    color: Colors.orange.shade200,
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: _saveRetour,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(50, 20),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Créer', style: TextStyle(fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _clearForm,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 20),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Contre Passer', style: TextStyle(fontSize: 10)),
                        ),
                        const Spacer(),
                        const Text('Aperçu BL', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 20),
                        const Text('Actualiser', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 20),
                        const Text('Imprimer BL', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(50, 20),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Fermer', style: TextStyle(fontSize: 10)),
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
    );
  }

  Future<void> _mettreAJourStock(String designation, String depot, String unite, double quantite) async {
    try {
      // Créer un mouvement de stock pour le retour
      final ref = 'RET${DateTime.now().millisecondsSinceEpoch}';
      await _databaseService.database.into(_databaseService.database.stocks).insert(
            StocksCompanion(
              ref: Value(ref),
              daty: Value(DateTime.now()),
              lib: Value('RETOUR ACHAT - $designation'),
              refart: Value(designation),
              qe: Value(quantite),
              entres: Value(quantite),
              ue: Value(unite),
              depots: Value(depot),
            ),
          );

      // Mettre à jour le stock dans la table depart
      final query = _databaseService.database.select(_databaseService.database.depart);
      query.where((d) => d.designation.equals(designation) & d.depots.equals(depot));
      final stockDepart = await query.getSingleOrNull();

      if (stockDepart != null) {
        double nouvelleQuantiteU1 = stockDepart.stocksu1 ?? 0;
        double nouvelleQuantiteU2 = stockDepart.stocksu2 ?? 0;
        double nouvelleQuantiteU3 = stockDepart.stocksu3 ?? 0;

        // Ajouter la quantité retournée selon l'unité
        if (unite == 'Pck') {
          nouvelleQuantiteU1 += quantite;
        } else if (unite == 'Kg') {
          nouvelleQuantiteU2 += quantite;
        } else if (unite == 'L') {
          nouvelleQuantiteU3 += quantite;
        }

        await (_databaseService.database.update(_databaseService.database.depart)
              ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
            .write(DepartCompanion(
          stocksu1: Value(nouvelleQuantiteU1),
          stocksu2: Value(nouvelleQuantiteU2),
          stocksu3: Value(nouvelleQuantiteU3),
        ));
      } else {
        // Créer une nouvelle entrée si elle n'existe pas
        double stockU1 = 0, stockU2 = 0, stockU3 = 0;
        if (unite == 'Pck') {
          stockU1 = quantite;
        } else if (unite == 'Kg') {
          stockU2 = quantite;
        } else if (unite == 'L') {
          stockU3 = quantite;
        }

        await _databaseService.database.into(_databaseService.database.depart).insert(
              DepartCompanion(
                designation: Value(designation),
                depots: Value(depot),
                stocksu1: Value(stockU1),
                stocksu2: Value(stockU2),
                stocksu3: Value(stockU3),
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

  @override
  void dispose() {
    _numAchatsController.dispose();
    _nFactController.dispose();
    _dateController.dispose();
    _echeanceController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    super.dispose();
  }
}
