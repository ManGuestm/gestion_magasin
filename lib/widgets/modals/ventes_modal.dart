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

  @override
  void initState() {
    super.initState();
    _loadData().then((_) => _initializeForm());
  }

  Future<String> _getNextNumVentes() async {
    try {
      // Récupérer toutes les ventes et trouver le plus grand numventes
      final ventes = await _databaseService.database.select(_databaseService.database.ventes).get();

      if (ventes.isEmpty) {
        return '10001';
      }

      // Trouver le plus grand numéro de vente
      int maxNum = 10000;
      for (var vente in ventes) {
        if (vente.numventes != null) {
          final num = int.tryParse(vente.numventes!) ?? 0;
          if (num > maxNum) {
            maxNum = num;
          }
        }
      }

      return (maxNum + 1).toString();
    } catch (e) {
      // En cas d'erreur, commencer à 10001
      return '10001';
    }
  }

  void _initializeForm() async {
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _heureController.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    // Générer les prochains numéros auto-incrémentés
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

  void _onArticleSelected(Article? article) {
    setState(() {
      _selectedArticle = article;
      if (article != null) {
        _selectedUnite = article.u1;
        if (!widget.tousDepots) {
          _selectedDepot = 'MAG';
        }

        // Calculer le prix de vente basé sur le CMUP
        double cmup = article.cmup ?? 0.0;
        if (cmup > 0) {
          double prixVente = cmup * 1.2; // Marge de 20%
          if (article.tu2u1 != null && _selectedUnite == article.u1) {
            prixVente = cmup * article.tu2u1! * 1.2;
          }
          _prixController.text = _formatNumber(prixVente);
        } else {
          _prixController.text = '';
        }
        _quantiteController.text = '';
        _montantController.text = '';
      }
    });
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
        _quantiteController.text.isNotEmpty &&
        double.tryParse(_quantiteController.text) != null &&
        double.tryParse(_quantiteController.text)! > 0;
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                    // First row
                    Row(
                      children: [
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
                    // Second row - Clients
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
                    // Designation Articles
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unités
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Unités', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 25,
                            child: TextField(
                              controller: TextEditingController(text: _selectedUnite ?? ''),
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
                    const SizedBox(width: 8),
                    // Quantités
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
                                _calculerMontant();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // P.U HT
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
                    // Montant
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
                      // Dépôts
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
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepot = value;
                                  });
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
                      // Table header
                      Container(
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.orange[300],
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
                                  'UNITES',
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
                                  'QUANTITES',
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
                                  'PRIX UNITAIRE (HT)',
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
                            if (widget.tousDepots)
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
                                    'DEPOTS',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Table content
                      Expanded(
                        child: _lignesVente.isEmpty
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
                                              (ligne['quantite'] as double?)?.round().toString() ?? '0',
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
                                              _formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                                              style: const TextStyle(fontSize: 11),
                                            ),
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
                                            child: Text(
                                              _formatNumber(ligne['montant']?.toDouble() ?? 0),
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ),
                                        if (widget.tousDepots)
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
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section with totals and payment info
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
                                  initialValue: _selectedModePaiement,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'A crédit',
                                        child: Text('A crédit', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(
                                        value: 'Espèces',
                                        child: Text('Espèces', style: TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedModePaiement = value ?? 'A crédit';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Commerciaux', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                height: 25,
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Commercial',
                                        child: Text('Commercial', style: TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Commission', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                height: 25,
                                child: TextField(
                                  controller: _commissionController,
                                  textAlign: TextAlign.right,
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
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Remise (%)', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 100,
                              height: 25,
                              child: TextField(
                                controller: _remiseController,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (value) => _calculerTotaux(),
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
                                style: const TextStyle(fontSize: 12),
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
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Avance', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 100,
                              height: 25,
                              child: TextField(
                                controller: _avanceController,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (value) => _calculerTotaux(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Reste', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 100,
                              height: 25,
                              child: TextField(
                                controller: _resteController,
                                textAlign: TextAlign.right,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Nouveau Solde', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 100,
                              height: 25,
                              child: TextField(
                                controller: _nouveauSoldeController,
                                textAlign: TextAlign.right,
                                readOnly: true,
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
                  ],
                ),
              ),

              // Action buttons
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  color: Color(0xFFFFB6C1),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
                      child: const Text('Créer', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(minimumSize: const Size(80, 30)),
                      child: const Text('Contre Passer', style: TextStyle(fontSize: 12)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
                      child: const Text('Valider', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(minimumSize: const Size(70, 30)),
                      child: const Text('Aperçu FACTURE', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(minimumSize: const Size(70, 30)),
                      child: const Text('Aperçu BL', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(minimumSize: const Size(80, 30)),
                      child: const Text('Imprimer FACTURE', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(minimumSize: const Size(80, 30)),
                      child: const Text('Imprimer BL', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
                      child: const Text('Fermer', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(minimumSize: const Size(80, 30)),
                      child: const Text('Gestion Emballages', style: TextStyle(fontSize: 12)),
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
