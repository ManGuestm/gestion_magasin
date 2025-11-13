import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class VentesModal extends StatefulWidget {
  final bool tousDepots;

  const VentesModal({super.key, required this.tousDepots});

  @override
  State<VentesModal> createState() => _VentesModalState();
}

class _VentesModalState extends State<VentesModal> {
  final DatabaseService _databaseService = DatabaseService();

  // Controllers
  final TextEditingController _numVentesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nFactureController = TextEditingController();
  final TextEditingController _heureController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _totalHTController = TextEditingController();
  final TextEditingController _remiseController = TextEditingController();
  final TextEditingController _tvaController = TextEditingController();
  final TextEditingController _totalTTCController = TextEditingController();
  final TextEditingController _avanceController = TextEditingController();
  final TextEditingController _resteController = TextEditingController();
  final TextEditingController _nouveauSoldeController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  TextEditingController? _autocompleteController;

  // Lists
  List<Article> _articles = [];
  List<CltData> _clients = [];
  List<Depot> _depots = [];
  final List<Map<String, dynamic>> _lignesVente = [];

  // Selected values
  Article? _selectedArticle;
  String? _selectedUnite;
  String? _selectedDepot;
  String _selectedModePaiement = 'A crédit';
  int? _selectedRowIndex;
  bool _isExistingPurchase = false;

  // Stock management
  double _stockDisponible = 0.0;
  bool _stockInsuffisant = false;

  @override
  void initState() {
    super.initState();
    _loadData().then((_) => _initializeForm());
  }

  Future<String> _getNextNumVentes() async {
    try {
      final ventes = await _databaseService.database.select(_databaseService.database.ventes).get();
      if (ventes.isEmpty) return '10001';

      int maxNum = 10000;
      for (var vente in ventes) {
        if (vente.numventes != null) {
          final num = int.tryParse(vente.numventes!) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
      return (maxNum + 1).toString();
    } catch (e) {
      return '10001';
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
    _nFactureController.text = nextNumVentes;

    _totalHTController.text = '0';
    _remiseController.text = '0';
    _tvaController.text = '0';
    _totalTTCController.text = '0';
    _avanceController.text = '0';
    _resteController.text = '0';
    _nouveauSoldeController.text = '0';
    _commissionController.text = '0';
  }

  Future<void> _loadData() async {
    try {
      final articles = await _databaseService.database.getAllArticles();
      final clients = await _databaseService.database.getAllClients();
      final depots = await _databaseService.database.getAllDepots();
      await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();

      setState(() {
        _articles = articles;
        _clients = clients;
        _depots = depots;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _onArticleSelected(Article? article) async {
    setState(() {
      _selectedArticle = article;
      if (article != null) {
        _selectedUnite = article.u1;
        _selectedDepot = 'MAG';
        _quantiteController.text = '';
        _montantController.text = '';
      }
    });

    if (article != null) {
      await _verifierStockEtBasculer(article);
    }
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

  void _onUniteChanged(String? unite) async {
    if (_selectedArticle == null || unite == null) return;

    setState(() {
      _selectedUnite = unite;
      _calculerPrixPourUnite(_selectedArticle!, unite);
      _quantiteController.text = '';
    });

    await _verifierStock(_selectedArticle!);
  }

  Future<void> _verifierStockEtBasculer(Article article) async {
    try {
      String depot = _selectedDepot ?? 'MAG';

      // Récupérer le stock depuis la table depart
      final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .getSingleOrNull();

      // Vérifier les stocks pour chaque unité
      Map<String, double> stocksParUnite = {};

      if (stockDepart != null) {
        if (article.u1?.isNotEmpty == true) stocksParUnite[article.u1!] = stockDepart.stocksu1 ?? 0.0;
        if (article.u2?.isNotEmpty == true) stocksParUnite[article.u2!] = stockDepart.stocksu2 ?? 0.0;
        if (article.u3?.isNotEmpty == true) stocksParUnite[article.u3!] = stockDepart.stocksu3 ?? 0.0;
      } else {
        // Fallback sur les stocks de l'article
        if (article.u1?.isNotEmpty == true) stocksParUnite[article.u1!] = article.stocksu1 ?? 0.0;
        if (article.u2?.isNotEmpty == true) stocksParUnite[article.u2!] = article.stocksu2 ?? 0.0;
        if (article.u3?.isNotEmpty == true) stocksParUnite[article.u3!] = article.stocksu3 ?? 0.0;
      }

      // Trouver une unité avec stock disponible
      String? uniteAvecStock;
      double stockMax = 0.0;

      for (var entry in stocksParUnite.entries) {
        if (entry.value > 0 && entry.value > stockMax) {
          uniteAvecStock = entry.key;
          stockMax = entry.value;
        }
      }

      setState(() {
        if (uniteAvecStock != null) {
          // Basculer vers l'unité avec stock
          _selectedUnite = uniteAvecStock;
          _stockDisponible = stockMax;
          _stockInsuffisant = false;

          // Recalculer le prix pour la nouvelle unité
          _calculerPrixPourUnite(article, uniteAvecStock);
        } else {
          // Aucun stock disponible
          _stockDisponible = 0.0;
          _stockInsuffisant = true;
          _quantiteController.text = '0';
        }
      });

      if (_stockInsuffisant) {
        _afficherModalStockInsuffisant();
      }
    } catch (e) {
      setState(() {
        _stockDisponible = 0.0;
        _stockInsuffisant = true;
        _quantiteController.text = '0';
      });
    }
  }

  Future<void> _verifierStock(Article article) async {
    try {
      String depot = _selectedDepot ?? 'MAG';
      String unite = _selectedUnite ?? article.u1 ?? 'Pce';

      // Récupérer le stock depuis la table depart
      final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .getSingleOrNull();

      setState(() {
        if (stockDepart != null) {
          // Sélectionner le stock selon l'unité
          if (unite == article.u1) {
            _stockDisponible = stockDepart.stocksu1 ?? 0.0;
          } else if (unite == article.u2) {
            _stockDisponible = stockDepart.stocksu2 ?? 0.0;
          } else if (unite == article.u3) {
            _stockDisponible = stockDepart.stocksu3 ?? 0.0;
          } else {
            _stockDisponible = stockDepart.stocksu1 ?? 0.0;
          }
        } else {
          // Fallback sur le stock de l'article
          if (unite == article.u1) {
            _stockDisponible = article.stocksu1 ?? 0.0;
          } else if (unite == article.u2) {
            _stockDisponible = article.stocksu2 ?? 0.0;
          } else if (unite == article.u3) {
            _stockDisponible = article.stocksu3 ?? 0.0;
          } else {
            _stockDisponible = article.stocksu1 ?? 0.0;
          }
        }

        _stockInsuffisant = _stockDisponible <= 0;

        if (_stockInsuffisant) {
          _quantiteController.text = '0';
        }
      });
    } catch (e) {
      setState(() {
        _stockDisponible = 0.0;
        _stockInsuffisant = true;
        _quantiteController.text = '0';
      });
    }
  }

  void _calculerPrixPourUnite(Article article, String unite) {
    double cmup = article.cmup ?? 0.0;
    if (cmup == 0.0) {
      _prixController.text = '';
    } else {
      double prixUnitaire = cmup;
      if (unite == article.u1 && article.tu2u1 != null) {
        prixUnitaire = cmup * article.tu2u1! * 1.2;
      } else if (unite == article.u2 && article.tu3u2 != null) {
        prixUnitaire = cmup * article.tu3u2! * 1.2;
      } else {
        prixUnitaire = cmup * 1.2;
      }
      _prixController.text = _formatNumber(prixUnitaire);
    }
  }

  void _afficherModalStockInsuffisant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock insuffisant'),
        content: Text('Stock épuisé pour l\'article "${_selectedArticle?.designation}".\nVente impossible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _validerQuantite(String value) {
    if (_selectedArticle == null) return;

    double quantite = double.tryParse(value) ?? 0.0;

    if (quantite > _stockDisponible) {
      setState(() {
        _quantiteController.text = _stockDisponible.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantité maximale disponible: ${_stockDisponible.toStringAsFixed(0)}'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    _calculerMontant();
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

  void _calculerMontant() {
    double quantite = double.tryParse(_quantiteController.text) ?? 0.0;
    double prix = double.tryParse(_prixController.text.replaceAll(' ', '')) ?? 0.0;
    double montant = quantite * prix;
    _montantController.text = _formatNumber(montant);
  }

  void _ajouterLigne() {
    if (_selectedArticle == null) return;

    double quantite = double.tryParse(_quantiteController.text) ?? 0.0;
    double prix = double.tryParse(_prixController.text.replaceAll(' ', '')) ?? 0.0;
    double montant = quantite * prix;

    setState(() {
      _lignesVente.add({
        'designation': _selectedArticle!.designation,
        'unites': _selectedUnite ?? _selectedArticle!.u1,
        'quantite': quantite,
        'prixUnitaire': prix,
        'montant': montant,
        'depot': _selectedDepot ?? 'MAG',
      });
    });

    _calculerTotaux();
    _resetArticleForm();
  }

  void _calculerTotaux() {
    double totalHT = 0;
    for (var ligne in _lignesVente) {
      totalHT += ligne['montant'] ?? 0;
    }

    double remise = double.tryParse(_remiseController.text) ?? 0;
    double totalApresRemise = totalHT - (totalHT * remise / 100);
    double tva = double.tryParse(_tvaController.text) ?? 0;
    double totalTTC = totalApresRemise + (totalApresRemise * tva / 100);
    double avance = double.tryParse(_avanceController.text) ?? 0;
    double reste = totalTTC - avance;

    setState(() {
      _totalHTController.text = _formatNumber(totalHT);
      _totalTTCController.text = _formatNumber(totalTTC);
      _resteController.text = _formatNumber(reste);
    });
  }

  void _resetArticleForm() {
    setState(() {
      _selectedArticle = null;
      _selectedUnite = null;
      if (widget.tousDepots) {
        _selectedDepot = null;
      }
      if (_autocompleteController != null) {
        _autocompleteController!.clear();
      }
      _quantiteController.clear();
      _prixController.clear();
      _montantController.clear();
      _stockDisponible = 0.0;
      _stockInsuffisant = false;
    });
  }

  void _supprimerLigne(int index) {
    setState(() {
      _lignesVente.removeAt(index);
    });
    _calculerTotaux();
  }

  bool _isArticleFormValid() {
    return _selectedArticle != null &&
        !_stockInsuffisant &&
        _quantiteController.text.isNotEmpty &&
        double.tryParse(_quantiteController.text) != null &&
        double.tryParse(_quantiteController.text)! > 0;
  }

  Future<void> _validerVente() async {
    if (_lignesVente.isEmpty) return;

    try {
      double totalHT = 0;
      for (var ligne in _lignesVente) {
        totalHT += ligne['montant'] ?? 0;
      }

      double remise = double.tryParse(_remiseController.text) ?? 0;
      double totalApresRemise = totalHT - (totalHT * remise / 100);
      double tva = double.tryParse(_tvaController.text) ?? 0;
      double totalTTC = totalApresRemise + (totalApresRemise * tva / 100);
      double avance = double.tryParse(_avanceController.text) ?? 0;
      double commission = double.tryParse(_commissionController.text) ?? 0;

      final venteCompanion = VentesCompanion(
        numventes: drift.Value(_numVentesController.text),
        nfact: drift.Value(_nFactureController.text),
        daty: drift.Value(DateTime.now()),
        clt: drift.Value(_clientController.text),
        modepai: drift.Value(_selectedModePaiement),
        totalnt: drift.Value(totalApresRemise),
        totalttc: drift.Value(totalTTC),
        tva: drift.Value(tva),
        avance: drift.Value(avance),
        commission: drift.Value(commission),
        remise: drift.Value(remise),
        heure: drift.Value(_heureController.text),
        verification: const drift.Value('Non vérifié'),
      );

      await _databaseService.database.insertVente(venteCompanion);

      // for (var ligne in _lignesVente) {
      //   final detailCompanion = DetventsCompanion(
      //     numventes: drift.Value(_numVentesController.text),
      //     designation: drift.Value(ligne['designation']),
      //     unites: drift.Value(ligne['unites']),
      //     q: drift.Value(ligne['quantite']),
      //     pu: drift.Value(ligne['prixUnitaire']),
      //     daty: drift.Value(DateTime.now()),
      //     depots: drift.Value(ligne['depot']),
      //   );

      //   await _databaseService.database.into(_databaseService.database.detventes).insert(detailCompanion);
      // }

      setState(() {
        _isExistingPurchase = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente enregistrée avec succès'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _creerNouvelleVente() async {
    setState(() {
      _isExistingPurchase = false;
      _selectedRowIndex = null;
      _lignesVente.clear();
      _clientController.clear();
    });

    _totalHTController.text = '0';
    _remiseController.text = '0';
    _tvaController.text = '0';
    _totalTTCController.text = '0';
    _avanceController.text = '0';
    _resteController.text = '0';
    _nouveauSoldeController.text = '0';
    _commissionController.text = '0';

    _resetArticleForm();
    _initializeForm();
  }

  Future<void> _contrePasserVente() async {
    if (!_isExistingPurchase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune vente sélectionnée à contre-passer')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment contre-passer la vente N° ${_numVentesController.text} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await (_databaseService.database.delete(_databaseService.database.detventes)
            ..where((d) => d.numventes.equals(_numVentesController.text)))
          .go();

      await (_databaseService.database.delete(_databaseService.database.ventes)
            ..where((v) => v.numventes.equals(_numVentesController.text)))
          .go();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente contre-passée avec succès')),
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

  void _apercuFacture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aperçu facture - Fonctionnalité à implémenter')),
    );
  }

  void _imprimerFacture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impression facture - Fonctionnalité à implémenter')),
    );
  }

  void _apercuBL() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aperçu BL - Fonctionnalité à implémenter')),
    );
  }

  void _imprimerBL() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imprimer BL - Fonctionnalité à implémenter')),
    );
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
          width: 1118,
          height: MediaQuery.of(context).size.height * 0.9,
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
                        child: Text(
                          'VENTES (${widget.tousDepots ? 'Tous dépôts' : 'Dépôt MAG'})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              color: Colors.green,
                              child: const Text('Enregistrement',
                                  style: TextStyle(color: Colors.white, fontSize: 12)),
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
                                ],
                                onChanged: (value) {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              const Text('N° ventes', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                height: 25,
                                child: TextField(
                                  controller: _numVentesController,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    fillColor: Color(0xFFF5F5F5),
                                    filled: true,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('Date', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                height: 25,
                                child: TextField(
                                  controller: _dateController,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('N° Facture/ BL', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                height: 25,
                                child: TextField(
                                  controller: _nFactureController,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('Heure', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                height: 25,
                                child: TextField(
                                  controller: _heureController,
                                  textAlign: TextAlign.center,
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
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                              items: _clients.map((client) {
                                return DropdownMenuItem<String>(
                                  value: client.rsoc,
                                  child: Text(client.rsoc, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {});
                              },
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
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Désignation Articles', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 25,
                            child: Autocomplete<Article>(
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _articles.take(10);
                                }
                                return _articles.where((article) {
                                  return article.designation
                                      .toLowerCase()
                                      .contains(textEditingValue.text.toLowerCase());
                                }).take(10);
                              },
                              displayStringForOption: (article) => article.designation,
                              onSelected: _onArticleSelected,
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final article = options.elementAt(index);
                                          return ListTile(
                                            dense: true,
                                            title: Text(article.designation,
                                                style: const TextStyle(fontSize: 11)),
                                            subtitle: Text(
                                                'Stock: ${article.stocksu1?.toStringAsFixed(0) ?? "0"}',
                                                style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                            onTap: () => onSelected(article),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                _autocompleteController = controller;
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    hintText: 'Rechercher un article...',
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Unités', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 25,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnite,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                              items: _getUnitsForSelectedArticle(),
                              onChanged: _onUniteChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Quantités', style: TextStyle(fontSize: 12)),
                              if (_selectedArticle != null && _stockDisponible > 0)
                                Text(' (Stock: ${_stockDisponible.toStringAsFixed(0)})',
                                    style: const TextStyle(fontSize: 10, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 25,
                            child: TextField(
                              controller: _quantiteController,
                              enabled: !_stockInsuffisant,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                fillColor: _stockInsuffisant ? Colors.grey[300] : null,
                                filled: _stockInsuffisant,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: _stockInsuffisant ? Colors.grey[600] : null,
                              ),
                              onChanged: _validerQuantite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                              onChanged: (value) => _calculerMontant(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Montant', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 25,
                            child: TextField(
                              controller: _montantController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                              style: const TextStyle(fontSize: 12),
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.tousDepots) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dépôts', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 25,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedDepot,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                ),
                                items: _depots.map((depot) {
                                  return DropdownMenuItem<String>(
                                    value: depot.depots,
                                    child: Text(depot.depots, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  setState(() {
                                    _selectedDepot = value;
                                  });
                                  if (_selectedArticle != null) {
                                    await _verifierStock(_selectedArticle!);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isArticleFormValid()) ...[
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _ajouterLigne,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(60, 25),
                            ),
                            child: const Text('Ajouter', style: TextStyle(fontSize: 12)),
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
                                child: const Text('DESIGNATION',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                child: const Text('UNITES',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                child: const Text('QUANTITES',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                child: const Text('PRIX UNITAIRE (HT)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                child: const Text('MONTANT',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            if (widget.tousDepots)
                              Expanded(
                                flex: 1,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
                                  ),
                                  child: const Text('DEPOTS',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _lignesVente.isEmpty
                            ? const Center(
                                child: Text('Aucun article ajouté',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
                              )
                            : ListView.builder(
                                itemCount: _lignesVente.length,
                                itemExtent: 18,
                                itemBuilder: (context, index) {
                                  final ligne = _lignesVente[index];
                                  return Container(
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: _selectedRowIndex == index
                                          ? Colors.blue[200]
                                          : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
                                    ),
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
                                            child: Text(ligne['designation'] ?? '',
                                                style: const TextStyle(fontSize: 11),
                                                overflow: TextOverflow.ellipsis),
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
                                            child: Text(ligne['unites'] ?? '',
                                                style: const TextStyle(fontSize: 11)),
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
                                                (ligne['quantite'] as double?)?.round().toString() ?? '0',
                                                style: const TextStyle(fontSize: 11)),
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
                                            child: Text(_formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                                style: const TextStyle(fontSize: 11)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: widget.tousDepots
                                                    ? const BorderSide(color: Colors.grey, width: 1)
                                                    : BorderSide.none,
                                                bottom: const BorderSide(color: Colors.grey, width: 1),
                                              ),
                                            ),
                                            child: Text(_formatNumber(ligne['montant']?.toDouble() ?? 0),
                                                style: const TextStyle(fontSize: 11)),
                                          ),
                                        ),
                                        if (widget.tousDepots)
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                border:
                                                    Border(bottom: BorderSide(color: Colors.grey, width: 1)),
                                              ),
                                              child: Text(ligne['depot'] ?? '',
                                                  style: const TextStyle(fontSize: 11)),
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

              // Bottom section - Totals and payment
              Container(
                color: const Color(0xFFE6E6FA),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Total HT', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                height: 25,
                                child: TextField(
                                  controller: _totalHTController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    fillColor: Color(0xFFF5F5F5),
                                    filled: true,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('Remise %', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                height: 25,
                                child: TextField(
                                  controller: _remiseController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  onChanged: (value) => _calculerTotaux(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('TVA %', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                height: 25,
                                child: TextField(
                                  controller: _tvaController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  onChanged: (value) => _calculerTotaux(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('Total TTC', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                height: 25,
                                child: TextField(
                                  controller: _totalTTCController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    fillColor: Color(0xFFF5F5F5),
                                    filled: true,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  readOnly: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Mode de paiement', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          height: 25,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedModePaiement,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'A crédit', child: Text('A crédit', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Espèces', child: Text('Espèces', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Chèque', child: Text('Chèque', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Virement', child: Text('Virement', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedModePaiement = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('Avance', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          height: 25,
                          child: TextField(
                            controller: _avanceController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            style: const TextStyle(fontSize: 12),
                            onChanged: (value) => _calculerTotaux(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('Reste', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          height: 25,
                          child: TextField(
                            controller: _resteController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              fillColor: Color(0xFFF5F5F5),
                              filled: true,
                            ),
                            style: const TextStyle(fontSize: 12),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('Nouveau solde', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          height: 25,
                          child: TextField(
                            controller: _nouveauSoldeController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              fillColor: Color(0xFFF5F5F5),
                              filled: true,
                            ),
                            style: const TextStyle(fontSize: 12),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('Commission', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          height: 25,
                          child: TextField(
                            controller: _commissionController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _lignesVente.isNotEmpty ? _validerVente : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 32),
                      ),
                      child: const Text('Valider', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isExistingPurchase ? _contrePasserVente : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 32),
                      ),
                      child: const Text('Contre Passer', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _creerNouvelleVente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 32),
                      ),
                      child: const Text('Créer', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _lignesVente.isNotEmpty ? _apercuFacture : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 32),
                      ),
                      child: const Text('Aperçu Facture', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _lignesVente.isNotEmpty ? _imprimerFacture : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(110, 32),
                      ),
                      child: const Text('Impression facture', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _lignesVente.isNotEmpty ? _apercuBL : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 32),
                      ),
                      child: const Text('Aperçu BL', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _lignesVente.isNotEmpty ? _imprimerBL : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(90, 32),
                      ),
                      child: const Text('Imprimer BL', style: TextStyle(fontSize: 12)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 32),
                      ),
                      child: const Text('Fermer', style: TextStyle(fontSize: 12)),
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
    _numVentesController.dispose();
    _dateController.dispose();
    _nFactureController.dispose();
    _heureController.dispose();
    _clientController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _montantController.dispose();
    _totalHTController.dispose();
    _remiseController.dispose();
    _tvaController.dispose();
    _totalTTCController.dispose();
    _avanceController.dispose();
    _resteController.dispose();
    _nouveauSoldeController.dispose();
    _commissionController.dispose();
    super.dispose();
  }
}
