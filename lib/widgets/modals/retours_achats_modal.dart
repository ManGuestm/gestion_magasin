import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';
import '../common/tab_navigation_widget.dart';

class RetoursAchatsModal extends StatefulWidget {
  const RetoursAchatsModal({super.key});

  @override
  State<RetoursAchatsModal> createState() => _RetoursAchatsModalState();
}

class _RetoursAchatsModalState extends State<RetoursAchatsModal> with SingleTickerProviderStateMixin, TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  final List<Map<String, dynamic>> _historiqueRetours = [];

  // Controllers
  final TextEditingController _numAchatsController = TextEditingController();
  final TextEditingController _nFactController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _echeanceController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();

  late List<Frn> fournisseurs = [];
  List<MpData> _modesPaiement = [];

  List<Achat> _achats = [];
  final List<Map<String, dynamic>> _articlesAchetes = [];
  final List<Map<String, dynamic>> _articlesRetour = [];

  String? _selectedFournisseur;
  String? _selectedModePaiement;

  String? _selectedNumAchats;
  double _totalHT = 0;
  double _totalTTC = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadHistoriqueRetours();
    _initializeForm();
  }

  @override
  void dispose() {
    _numAchatsController.dispose();
    _nFactController.dispose();
    _dateController.dispose();
    _echeanceController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final now = DateTime.now();
    _dateController.text = app_date.AppDateUtils.formatDate(now);
    _echeanceController.text = app_date.AppDateUtils.formatDate(now);
  }

  Future<void> _loadData() async {
    try {
      final db = _databaseService.database;
      final fournisseur = await db.getAllFournisseurs();
      final modesPaiement = await db.select(db.mp).get();
      final achats = await db.getAllAchats();

      setState(() {
        fournisseurs = fournisseur;
        _modesPaiement = modesPaiement;
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

  Future<void> _loadHistoriqueRetours() async {
    try {
      final db = _databaseService.database;
      final retours = await db.select(db.retachats).get();

      final List<Map<String, dynamic>> historiqueData = [];
      for (final retour in retours) {
        historiqueData.add({
          'numRetour': retour.numachats ?? '',
          'date': retour.daty != null ? app_date.AppDateUtils.formatDate(retour.daty!) : '',
          'fournisseur': retour.frns ?? '',
          'nFacture': retour.nfact ?? '',
          'totalHT': retour.totalnt ?? 0.0,
          'totalTTC': retour.totalttc ?? 0.0,
        });
      }

      setState(() {
        _historiqueRetours.clear();
        _historiqueRetours.addAll(historiqueData);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement de l\'historique: $e')),
        );
      }
    }
  }

  /// Charger les données d'un achat (articles, fournisseur, facture) selon le numéro sélectionné.
  Future<void> _chargerArticlesAchetes() async {
    if (_selectedNumAchats == null) return;

    try {
      final db = _databaseService.database;

      // Charger les informations de l'achat principal
      final achat = await (db.select(db.achats)..where((a) => a.numachats.equals(_selectedNumAchats!)))
          .getSingleOrNull();

      if (achat != null) {
        // Remplir automatiquement le fournisseur et N° Facture
        setState(() {
          _selectedFournisseur = achat.frns;
          _nFactController.text = achat.nfact ?? '';
        });
      }

      // Charger les détails des articles
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
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
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
      _loadHistoriqueRetours();
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
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
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

              // Tab bar
              Container(
                color: Colors.blue.shade50,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'Nouveau Retour'),
                    Tab(text: 'Historique Retours'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNouveauRetourTab(),
                    _buildHistoriqueTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNouveauRetourTab() {
    return Column(
      children: [
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
                      child: Text('N° Achats:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(
                    width: 120,
                    height: 20,
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _achats.map((achat) => achat.numachats ?? '').where((s) => s.isNotEmpty);
                        }
                        return _achats
                            .map((achat) => achat.numachats ?? '')
                            .where((s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                            .where((s) => s.isNotEmpty);
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _selectedNumAchats = selection;
                          _numAchatsController.text = selection;
                        });
                        _chargerArticlesAchetes();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        controller.text = _numAchatsController.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            hintText: 'Tapez ou sélectionnez...',
                          ),
                          style: const TextStyle(fontSize: 10),
                          onChanged: (value) {
                            _numAchatsController.text = value;
                            if (_achats.any((achat) => achat.numachats == value)) {
                              setState(() {
                                _selectedNumAchats = value;
                              });
                              _chargerArticlesAchetes();
                            }
                          },
                        );
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
                  const Text('N° Facture/ BL:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    height: 20,
                    child: TextField(
                      controller: _nFactController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        hintText: 'Auto-rempli selon N° Achats',
                      ),
                      style: const TextStyle(fontSize: 10),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Fournisseurs:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 20,
                      child: TextField(
                        controller: TextEditingController(text: _selectedFournisseur ?? ''),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          hintText: 'Auto-rempli selon N° Achats',
                        ),
                        style: const TextStyle(fontSize: 10),
                        readOnly: true,
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
                                child:
                                    Text(article['designation'] ?? '', style: const TextStyle(fontSize: 9)),
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
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
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
                      onPressed:
                          _articlesRetour.isNotEmpty && _selectedFournisseur != null ? _saveRetour : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 25),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: _articlesRetour.isNotEmpty && _selectedFournisseur != null
                            ? Colors.green
                            : Colors.grey.shade300,
                        foregroundColor: _articlesRetour.isNotEmpty && _selectedFournisseur != null
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save, size: 12),
                          SizedBox(width: 4),
                          Text('Valider Retour', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
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
    );
  }

  Widget _buildHistoriqueTab() {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.all(8),
          child: const Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text('N° Retour', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 3,
                  child: Text('Fournisseur', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('N° Facture', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('Total HT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('Total TTC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        // List
        Expanded(
          child: _historiqueRetours.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun retour enregistré',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _historiqueRetours.length,
                  itemBuilder: (context, index) {
                    final retour = _historiqueRetours[index];
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(retour['numRetour'], style: const TextStyle(fontSize: 9)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(retour['date'],
                                style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(retour['fournisseur'], style: const TextStyle(fontSize: 9)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(retour['nFacture'],
                                style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(NumberUtils.formatNumber(retour['totalHT']),
                                style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(NumberUtils.formatNumber(retour['totalTTC']),
                                style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _mettreAJourStock(String designation, String depot, String unite, double quantite) async {
    try {
      debugPrint('DEBUG: Mise à jour stock - Désignation: $designation, Unité: $unite, Quantité: $quantite');

      // Créer un mouvement de SORTIE de stock pour le retour d'achat
      final ref = 'RET${DateTime.now().millisecondsSinceEpoch}';
      await _databaseService.database.into(_databaseService.database.stocks).insert(
            StocksCompanion(
              ref: Value(ref),
              daty: Value(DateTime.now()),
              lib: Value('RETOUR ACHAT - $designation'),
              refart: Value(designation),
              qs: Value(quantite),
              sortie: Value(quantite),
              us: Value(unite),
              depots: Value(depot),
            ),
          );

      // Récupérer l'article pour mettre à jour le stock global
      final article = await _databaseService.database.getArticleByDesignation(designation);
      if (article != null) {
        debugPrint(
            'DEBUG: Stock avant - U1: ${article.stocksu1}, U2: ${article.stocksu2}, U3: ${article.stocksu3}');

        double nouvelleQuantiteU1 = article.stocksu1 ?? 0;
        double nouvelleQuantiteU2 = article.stocksu2 ?? 0;
        double nouvelleQuantiteU3 = article.stocksu3 ?? 0;

        // SOUSTRAIRE la quantité retournée selon l'unité dans la table articles
        if (unite == 'Ctn' || unite == 'Pck' || unite == 'CTN' || unite == 'PCK') {
          nouvelleQuantiteU1 -= quantite;
          debugPrint('DEBUG: Soustraction U1 (Ctn/Pck): $nouvelleQuantiteU1');
        } else if (unite == 'Kg' || unite == 'KG') {
          nouvelleQuantiteU2 -= quantite;
          debugPrint('DEBUG: Soustraction U2 (Kg): $nouvelleQuantiteU2');
        } else if (unite == 'L' || unite == 'l') {
          nouvelleQuantiteU3 -= quantite;
          debugPrint('DEBUG: Soustraction U3 (L): $nouvelleQuantiteU3');
        } else {
          debugPrint('DEBUG: Unité non reconnue: $unite - Utilisation U1 par défaut');
          nouvelleQuantiteU1 -= quantite;
        }

        // S'assurer que les stocks ne deviennent pas négatifs
        nouvelleQuantiteU1 = nouvelleQuantiteU1 < 0 ? 0 : nouvelleQuantiteU1;
        nouvelleQuantiteU2 = nouvelleQuantiteU2 < 0 ? 0 : nouvelleQuantiteU2;
        nouvelleQuantiteU3 = nouvelleQuantiteU3 < 0 ? 0 : nouvelleQuantiteU3;

        debugPrint(
            'DEBUG: Stock après - U1: $nouvelleQuantiteU1, U2: $nouvelleQuantiteU2, U3: $nouvelleQuantiteU3');

        // Mettre à jour le stock global dans la table articles
        final updateResult = await (_databaseService.database.update(_databaseService.database.articles)
              ..where((a) => a.designation.equals(designation)))
            .write(ArticlesCompanion(
          stocksu1: Value(nouvelleQuantiteU1),
          stocksu2: Value(nouvelleQuantiteU2),
          stocksu3: Value(nouvelleQuantiteU3),
        ));

        debugPrint('DEBUG: Lignes mises à jour dans articles: $updateResult');
      } else {
        debugPrint('DEBUG: Article non trouvé: $designation');
      }

      // Mettre à jour le stock dans la table depart (DIMINUER le stock)
      final query = _databaseService.database.select(_databaseService.database.depart);
      query.where((d) => d.designation.equals(designation) & d.depots.equals(depot));
      final stockDepart = await query.getSingleOrNull();

      if (stockDepart != null) {
        debugPrint(
            'DEBUG: Stock depart avant - U1: ${stockDepart.stocksu1}, U2: ${stockDepart.stocksu2}, U3: ${stockDepart.stocksu3}');

        double nouvelleQuantiteU1 = stockDepart.stocksu1 ?? 0;
        double nouvelleQuantiteU2 = stockDepart.stocksu2 ?? 0;
        double nouvelleQuantiteU3 = stockDepart.stocksu3 ?? 0;

        // SOUSTRAIRE la quantité retournée selon l'unité
        if (unite == 'Ctn' || unite == 'Pck' || unite == 'CTN' || unite == 'PCK') {
          nouvelleQuantiteU1 -= quantite;
        } else if (unite == 'Kg' || unite == 'KG') {
          nouvelleQuantiteU2 -= quantite;
        } else if (unite == 'L' || unite == 'l') {
          nouvelleQuantiteU3 -= quantite;
        } else {
          nouvelleQuantiteU1 -= quantite;
        }

        // S'assurer que les stocks ne deviennent pas négatifs
        nouvelleQuantiteU1 = nouvelleQuantiteU1 < 0 ? 0 : nouvelleQuantiteU1;
        nouvelleQuantiteU2 = nouvelleQuantiteU2 < 0 ? 0 : nouvelleQuantiteU2;
        nouvelleQuantiteU3 = nouvelleQuantiteU3 < 0 ? 0 : nouvelleQuantiteU3;

        debugPrint(
            'DEBUG: Stock depart après - U1: $nouvelleQuantiteU1, U2: $nouvelleQuantiteU2, U3: $nouvelleQuantiteU3');

        final departUpdateResult = await (_databaseService.database.update(_databaseService.database.depart)
              ..where((d) => d.designation.equals(designation) & d.depots.equals(depot)))
            .write(DepartCompanion(
          stocksu1: Value(nouvelleQuantiteU1),
          stocksu2: Value(nouvelleQuantiteU2),
          stocksu3: Value(nouvelleQuantiteU3),
        ));

        debugPrint('DEBUG: Lignes mises à jour dans depart: $departUpdateResult');
      } else {
        debugPrint('DEBUG: Stock depart non trouvé pour: $designation dans $depot');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock mis à jour: -$quantite $unite pour $designation')),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Erreur mise à jour stock: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur mise à jour stock: $e')),
        );
      }
    }
  }
}
