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

class _RetoursAchatsModalState extends State<RetoursAchatsModal>
    with SingleTickerProviderStateMixin, TabNavigationMixin {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
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
          'totalTTC': retour.totalttc ?? 0.0,
        });
      }

      setState(() {
        _historiqueRetours.clear();
        _historiqueRetours.addAll(historiqueData);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement de l\'historique: $e')));
      }
    }
  }

  /// Charger les données d'un achat (articles, fournisseur, facture) selon le numéro sélectionné.
  Future<void> _chargerArticlesAchetes() async {
    if (_selectedNumAchats == null) return;

    try {
      final db = _databaseService.database;

      // Charger les informations de l'achat principal
      final achat = await (db.select(
        db.achats,
      )..where((a) => a.numachats.equals(_selectedNumAchats!))).getSingleOrNull();

      if (achat != null) {
        // Remplir automatiquement le fournisseur et N° Facture
        setState(() {
          _selectedFournisseur = achat.frns;
          _nFactController.text = achat.nfact ?? '';
        });
      }

      // Charger les détails des articles
      final detailsAchats = await (db.select(
        db.detachats,
      )..where((d) => d.numachats.equals(_selectedNumAchats!))).get();

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement des données: $e')));
      }
    }
  }

  void _retournerArticle(int index, double quantiteRetour) {
    final article = _articlesAchetes[index];
    final quantiteDisponible = (article['quantite'] ?? 0) - (article['quantiteRetournee'] ?? 0);

    if (quantiteRetour <= 0 || quantiteRetour > quantiteDisponible) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Quantité invalide. Maximum disponible: $quantiteDisponible')));
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
      DateTime dateForDB = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );

      DateTime? echeanceForDB;
      if (_echeanceController.text.isNotEmpty) {
        List<String> echeanceParts = _echeanceController.text.split('-');
        echeanceForDB = DateTime(
          int.parse(echeanceParts[2]),
          int.parse(echeanceParts[1]),
          int.parse(echeanceParts[0]),
        );
      }

      final retourCompanion = RetachatsCompanion(
        numachats: Value(numRetour),
        nfact: Value(_nFactController.text.trim()),
        daty: Value(dateForDB),
        frns: Value(_selectedFournisseur!),
        modepai: Value(_selectedModePaiement),
        echeance: Value(echeanceForDB),
        totalttc: Value(_totalTTC),
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

      // Comptabilisation financière du retour
      await _comptabiliserRetour(numRetour, dateForDB, _selectedFournisseur!, _totalTTC);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Retour d\'achat enregistré avec succès')));
      }

      _clearForm();
      _loadHistoriqueRetours();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade600, Colors.indigo.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.keyboard_return, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'RETOUR SUR ACHATS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.indigo.shade700,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Colors.indigo.shade600,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                  children: [_buildNouveauRetourTab(), _buildHistoriqueTab()],
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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      'N° Achats:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 30,
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
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.indigo.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            hintText: 'Tapez ou sélectionnez...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 12),
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
                    height: 30,
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
                    height: 30,
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
                      height: 30,
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
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Articles achetés - Cliquez pour retourner',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                                child: Text(
                                  article['designation'] ?? '',
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${article['unite']}',
                                style: const TextStyle(fontSize: 9),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '$quantiteDisponible',
                                style: const TextStyle(fontSize: 9),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${article['prix']}',
                                style: const TextStyle(fontSize: 9),
                                textAlign: TextAlign.center,
                              ),
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
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade50, Colors.indigo.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'ARTICLES À RETOURNER',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'UNITES',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'QUANTITES',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'PRIX UNITAIRE (HT)',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'MONTANT',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'DEPOTS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
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
                              const Text(
                                'Mode de paiement:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
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
                                      .map(
                                        (mp) => DropdownMenuItem<String>(
                                          value: mp.mp,
                                          child: Text(mp.mp, style: const TextStyle(fontSize: 10)),
                                        ),
                                      )
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
                              const Text(
                                'Echéance (Date):',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
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
                            const Text(
                              'Total HT:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
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
                              child: Text('00', style: TextStyle(fontSize: 11), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Total TTC:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _articlesRetour.isNotEmpty && _selectedFournisseur != null
                          ? _saveRetour
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        backgroundColor: _articlesRetour.isNotEmpty && _selectedFournisseur != null
                            ? Colors.green.shade600
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: _articlesRetour.isNotEmpty && _selectedFournisseur != null ? 3 : 0,
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text(
                        'Valider Retour',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _clearForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: Colors.orange.shade500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(
                        'Réinitialiser',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text(
                        'Fermer',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
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
                child: Text('N° Retour', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: Text('Fournisseur', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('N° Facture', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('Total HT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('Total TTC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _historiqueRetours.isEmpty
              ? const Center(
                  child: Text('Aucun retour enregistré', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                            child: Text(
                              retour['date'],
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
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
                            child: Text(
                              retour['nFacture'],
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              NumberUtils.formatNumber(retour['totalHT']),
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              NumberUtils.formatNumber(retour['totalTTC']),
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.right,
                            ),
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
      final db = _databaseService.database;

      // Rechercher l'article dans le stock par dépôt
      final stockItem = await (db.select(
        db.depart,
      )..where((s) => s.designation.equals(designation) & s.depots.equals(depot))).getSingleOrNull();

      if (stockItem != null) {
        // Diminuer le stock (retour = sortie de stock)
        final newQuantity = (stockItem.stocksu1 ?? 0) - quantite;
        await (db.update(db.depart)..where((s) => s.designation.equals(designation) & s.depots.equals(depot)))
            .write(DepartCompanion(stocksu1: Value(newQuantity)));
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du stock: $e');
    }
  }

  Future<void> _comptabiliserRetour(
    String numRetour,
    DateTime date,
    String fournisseur,
    double montant,
  ) async {
    try {
      final db = _databaseService.database;

      // 1. Encaissement (remboursement du fournisseur)
      final dernierSoldeCaisse =
          await (db.select(db.caisse)
                ..orderBy([(c) => OrderingTerm.desc(c.daty)])
                ..limit(1))
              .getSingleOrNull();
      final nouveauSoldeCaisse = (dernierSoldeCaisse?.soldes ?? 0) + montant;

      await db
          .into(db.caisse)
          .insert(
            CaisseCompanion(
              ref: Value('RET-$numRetour'),
              daty: Value(date),
              lib: Value('Retour sur achats - $fournisseur'),
              credit: Value(montant),
              debit: const Value(0),
              soldes: Value(nouveauSoldeCaisse),
              type: const Value('Retour sur achats'),
              frns: Value(fournisseur),
              verification: const Value('JOURNAL'),
            ),
          );

      // 2. Compte fournisseur (diminution de la dette)
      await db
          .into(db.comptefrns)
          .insert(
            ComptefrnsCompanion(
              ref: Value('RET-$numRetour'),
              daty: Value(date),
              lib: Value('Retour sur achats N°$numRetour'),
              sortie: Value(montant),
              entres: const Value(0),
              frns: Value(fournisseur),
              solde: Value(-montant),
            ),
          );
    } catch (e) {
      debugPrint('Erreur comptabilisation retour: $e');
    }
  }
}
