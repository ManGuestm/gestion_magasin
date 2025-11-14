import 'package:drift/drift.dart' as drift hide Column;
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
  final TextEditingController _montantRecuController = TextEditingController();
  final TextEditingController _montantARendreController = TextEditingController();
  TextEditingController? _autocompleteController;
  final TextEditingController _searchVentesController = TextEditingController();

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
  String? _selectedClient;
  int? _selectedRowIndex;
  bool _isExistingPurchase = false;
  List<String> _ventesNumbers = [];
  String _searchVentesText = '';

  // Stock management
  double _stockDisponible = 0.0;
  bool _stockInsuffisant = false;

  // Client balance
  double _soldeAnterieur = 0.0;
  final TextEditingController _soldeAnterieurController = TextEditingController();

  // Paper format
  String _selectedFormat = 'A5';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadVentesNumbers().then((_) => _initializeForm());
    _searchVentesController.addListener(() {
      setState(() {
        _searchVentesText = _searchVentesController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadVentesNumbers() async {
    try {
      final ventes = await (_databaseService.database.select(_databaseService.database.ventes)
            ..orderBy([(v) => drift.OrderingTerm.asc(v.numventes)]))
          .get();
      setState(() {
        _ventesNumbers = ventes.map((v) => v.numventes ?? '').where((n) => n.isNotEmpty).toList();
      });
    } catch (e) {
      // Ignore errors
    }
  }

  List<String> _getFilteredVentesNumbers() {
    if (_searchVentesText.isEmpty) {
      return _ventesNumbers;
    }
    return _ventesNumbers.where((numVente) => numVente.toLowerCase().contains(_searchVentesText)).toList();
  }

  Future<void> _chargerVenteExistante(String numVentes) async {
    if (numVentes.isEmpty) {
      setState(() {
        _isExistingPurchase = false;
      });
      return;
    }

    try {
      final vente = await (_databaseService.database.select(_databaseService.database.ventes)
            ..where((v) => v.numventes.equals(numVentes)))
          .getSingleOrNull();

      setState(() {
        _isExistingPurchase = vente != null;
      });

      if (vente != null) {
        final details = await (_databaseService.database.select(_databaseService.database.detventes)
              ..where((d) => d.numventes.equals(numVentes)))
            .get();

        setState(() {
          _nFactureController.text = vente.nfact ?? '';
          if (vente.daty != null) {
            _dateController.text =
                '${vente.daty!.day.toString().padLeft(2, '0')}/${vente.daty!.month.toString().padLeft(2, '0')}/${vente.daty!.year}';
          }
          _clientController.text = vente.clt ?? '';
          _selectedClient = vente.clt;
          _selectedModePaiement = vente.modepai ?? 'A crédit';
          _heureController.text = vente.heure ?? '';
          _chargerSoldeClient(vente.clt);
          _tvaController.text = (vente.tva ?? 0).toString();
          _remiseController.text = (vente.remise ?? 0).toString();
          _avanceController.text = (vente.avance ?? 0).toString();
          _commissionController.text = (vente.commission ?? 0).toString();
          _montantRecuController.text = (vente.montantRecu ?? 0) > 0 ? _formatNumber(vente.montantRecu!) : '';
          _montantARendreController.text = (vente.monnaieARendre ?? 0) > 0 ? _formatNumber(vente.monnaieARendre!) : '';

          _lignesVente.clear();
          for (var detail in details) {
            _lignesVente.add({
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
            SnackBar(content: Text('Vente N° $numVentes chargée')),
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
    _montantRecuController.dispose();
    _montantARendreController.dispose();
    _searchVentesController.dispose();
    _soldeAnterieurController.dispose();
    super.dispose();
  }

  Future<String> _getNextNumVentes() async {
    try {
      final ventes = await _databaseService.database.select(_databaseService.database.ventes).get();
      if (ventes.isEmpty) return '2607';

      int maxNum = 2606;
      for (var vente in ventes) {
        if (vente.numventes != null) {
          final num = int.tryParse(vente.numventes!) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
      return (maxNum + 1).toString();
    } catch (e) {
      return '2607';
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

      // Récupérer les stocks par unité selon le mode
      double stockU1 = 0.0, stockU2 = 0.0, stockU3 = 0.0;

      if (widget.tousDepots) {
        // Mode tous dépôts: utiliser les stocks globaux
        stockU1 = article.stocksu1 ?? 0.0;
        stockU2 = article.stocksu2 ?? 0.0;
        stockU3 = article.stocksu3 ?? 0.0;
      } else {
        // Mode dépôt spécifique: utiliser uniquement le stock du dépôt sélectionné
        final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
              ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
            .getSingleOrNull();

        if (stockDepart != null) {
          stockU1 = stockDepart.stocksu1 ?? 0.0;
          stockU2 = stockDepart.stocksu2 ?? 0.0;
          stockU3 = stockDepart.stocksu3 ?? 0.0;
        }
      }

      // Calculer le stock total disponible en unité de base (u3)
      double stockTotalU3 = _calculerStockTotalEnU3(article, stockU1, stockU2, stockU3);

      // Calculer le stock disponible pour l'unité sélectionnée
      double stockPourUniteSelectionnee =
          _calculerStockPourUnite(article, _selectedUnite ?? article.u1!, stockTotalU3);

      setState(() {
        _stockDisponible = stockPourUniteSelectionnee;
        _stockInsuffisant = stockTotalU3 <= 0;

        if (_stockInsuffisant) {
          _quantiteController.text = '0';
        }

        // Recalculer le prix pour l'unité sélectionnée
        _calculerPrixPourUnite(article, _selectedUnite ?? article.u1!);
      });

      if (_stockInsuffisant) {
        await _gererStockInsuffisant(article, depot);
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

      // Récupérer les stocks par unité selon le mode
      double stockU1 = 0.0, stockU2 = 0.0, stockU3 = 0.0;

      if (widget.tousDepots) {
        // Mode tous dépôts: utiliser les stocks globaux
        stockU1 = article.stocksu1 ?? 0.0;
        stockU2 = article.stocksu2 ?? 0.0;
        stockU3 = article.stocksu3 ?? 0.0;
      } else {
        // Mode dépôt spécifique: utiliser uniquement le stock du dépôt sélectionné
        final stockDepart = await (_databaseService.database.select(_databaseService.database.depart)
              ..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
            .getSingleOrNull();

        if (stockDepart != null) {
          stockU1 = stockDepart.stocksu1 ?? 0.0;
          stockU2 = stockDepart.stocksu2 ?? 0.0;
          stockU3 = stockDepart.stocksu3 ?? 0.0;
        }
      }

      // Calculer le stock total disponible en unité de base (u3)
      double stockTotalU3 = _calculerStockTotalEnU3(article, stockU1, stockU2, stockU3);

      // Calculer le stock disponible pour l'unité sélectionnée
      double stockPourUniteSelectionnee = _calculerStockPourUnite(article, unite, stockTotalU3);

      setState(() {
        _stockDisponible = stockPourUniteSelectionnee;
        _stockInsuffisant = stockTotalU3 <= 0;

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

  void _calculerPrixPourUnite(Article article, String unite) async {
    try {
      // Utiliser la nouvelle méthode de calcul de prix
      final prix = await _databaseService.database.getPrixVenteArticle(article.designation);

      double prixUnitaire = 0;
      if (unite == article.u1) {
        prixUnitaire = prix['u1'] ?? 0;
      } else if (unite == article.u2) {
        prixUnitaire = prix['u2'] ?? 0;
      } else if (unite == article.u3) {
        prixUnitaire = prix['u3'] ?? 0;
      }

      _prixController.text = prixUnitaire > 0 ? _formatNumber(prixUnitaire) : '';
    } catch (e) {
      // Fallback sur l'ancien calcul
      double cmup = article.cmup ?? 0.0;
      if (cmup == 0.0) {
        _prixController.text = '';
      } else {
        double prixUnitaire = cmup * 1.2;

        if (unite == article.u1) {
          double facteur = (article.tu2u1 ?? 1.0) * (article.tu3u2 ?? 1.0);
          prixUnitaire = cmup * facteur * 1.2;
        } else if (unite == article.u2) {
          prixUnitaire = cmup * (article.tu3u2 ?? 1.0) * 1.2;
        } else if (unite == article.u3) {
          prixUnitaire = cmup * 1.2;
        }

        _prixController.text = _formatNumber(prixUnitaire);
      }
    }
  }

  // Calcule le stock total en unité de base (u3)
  double _calculerStockTotalEnU3(Article article, double stockU1, double stockU2, double stockU3) {
    double total = stockU3; // Stock direct en u3

    // Convertir u2 vers u3
    if (stockU2 > 0 && article.tu3u2 != null) {
      total += stockU2 * article.tu3u2!;
    }

    // Convertir u1 vers u3
    if (stockU1 > 0 && article.tu2u1 != null && article.tu3u2 != null) {
      total += stockU1 * article.tu2u1! * article.tu3u2!;
    }

    return total;
  }

  // Calcule le stock disponible pour une unité donnée
  double _calculerStockPourUnite(Article article, String unite, double stockTotalU3) {
    if (stockTotalU3 <= 0) return 0.0;

    if (unite == article.u3) {
      return stockTotalU3;
    } else if (unite == article.u2 && article.tu3u2 != null) {
      return stockTotalU3 / article.tu3u2!;
    } else if (unite == article.u1 && article.tu2u1 != null && article.tu3u2 != null) {
      return stockTotalU3 / (article.tu2u1! * article.tu3u2!);
    }

    return 0.0;
  }

  // Construit un résumé du stock pour l'autocomplete
  String _buildStockSummary(Article article) {
    // Afficher les stocks réels par unité (pas de conversion)
    double stockU1 = article.stocksu1 ?? 0.0;
    double stockU2 = article.stocksu2 ?? 0.0;
    double stockU3 = article.stocksu3 ?? 0.0;
    
    // Vérifier s'il y a du stock
    if (stockU1 <= 0 && stockU2 <= 0 && stockU3 <= 0) return 'Stock: 0';
    
    // Afficher les stocks réels par unité
    List<String> stocks = [];
    
    if (article.u1?.isNotEmpty == true) {
      stocks.add('${stockU1.toStringAsFixed(0)} ${article.u1}');
    }
    
    if (article.u2?.isNotEmpty == true) {
      stocks.add('${stockU2.toStringAsFixed(0)} ${article.u2}');
    }
    
    if (article.u3?.isNotEmpty == true) {
      stocks.add('${stockU3.toStringAsFixed(0)} ${article.u3}');
    }
    
    return stocks.isEmpty ? 'Stock: 0' : stocks.join(' / ');
  }

  // Construit l'info de stock détaillée
  Widget _buildStockInfo() {
    if (_selectedArticle == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Tooltip(
        message: _buildDetailedStockInfo(_selectedArticle!),
        child: const Icon(Icons.info_outline, size: 10, color: Colors.blue),
      ),
    );
  }

  // Construit l'information détaillée du stock avec conversions
  String _buildDetailedStockInfo(Article article) {
    double stockU1 = article.stocksu1 ?? 0.0;
    double stockU2 = article.stocksu2 ?? 0.0;
    double stockU3 = article.stocksu3 ?? 0.0;

    double stockTotalU3 = _calculerStockTotalEnU3(article, stockU1, stockU2, stockU3);

    List<String> infos = [];
    infos.add('Stock détaillé:');

    if (article.u1?.isNotEmpty == true) {
      infos.add('${article.u1}: ${stockU1.toStringAsFixed(0)}');
    }
    if (article.u2?.isNotEmpty == true) {
      infos.add('${article.u2}: ${stockU2.toStringAsFixed(0)}');
    }
    if (article.u3?.isNotEmpty == true) {
      infos.add('${article.u3}: ${stockU3.toStringAsFixed(0)}');
    }

    infos.add('');
    infos.add('Total disponible:');
    if (article.u1?.isNotEmpty == true) {
      double totalU1 = _calculerStockPourUnite(article, article.u1!, stockTotalU3);
      infos.add('${totalU1.toStringAsFixed(0)} ${article.u1}');
    }
    if (article.u2?.isNotEmpty == true) {
      double totalU2 = _calculerStockPourUnite(article, article.u2!, stockTotalU3);
      infos.add('${totalU2.toStringAsFixed(0)} ${article.u2}');
    }
    if (article.u3?.isNotEmpty == true) {
      infos.add('${stockTotalU3.toStringAsFixed(0)} ${article.u3}');
    }

    return infos.join('\n');
  }

  Future<void> _gererStockInsuffisant(Article article, String depotActuel) async {
    // Vérifier les stocks dans les autres dépôts
    final autresStocks = await _verifierStocksAutresDepots(article, depotActuel);
    
    if (widget.tousDepots && autresStocks.isNotEmpty) {
      // Mode tous dépôts: basculer automatiquement vers un dépôt disponible
      await _basculerVersDepotDisponible(article, depotActuel, autresStocks);
    } else {
      // Mode dépôt MAG ou aucun stock disponible: afficher modal d'information
      _afficherModalStockInsuffisant(article, depotActuel, autresStocks);
    }
  }

  Future<List<Map<String, dynamic>>> _verifierStocksAutresDepots(Article article, String depotActuel) async {
    final autresStocks = <Map<String, dynamic>>[];
    
    try {
      final tousStocksDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation) & d.depots.isNotValue(depotActuel)))
          .get();
      
      for (var stock in tousStocksDepart) {
        double stockTotalU3 = _calculerStockTotalEnU3(
          article, 
          stock.stocksu1 ?? 0.0, 
          stock.stocksu2 ?? 0.0, 
          stock.stocksu3 ?? 0.0
        );
        
        if (stockTotalU3 > 0) {
          double stockPourUnite = _calculerStockPourUnite(article, _selectedUnite ?? article.u1!, stockTotalU3);
          autresStocks.add({
            'depot': stock.depots,
            'stockDisponible': stockPourUnite,
            'unite': _selectedUnite ?? article.u1!,
          });
        }
      }
    } catch (e) {
      // Ignore errors
    }
    
    return autresStocks;
  }

  Future<void> _basculerVersDepotDisponible(Article article, String depotEpuise, List<Map<String, dynamic>> autresStocks) async {
    final depotDisponible = autresStocks.first;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock épuisé - Basculement automatique'),
        content: Text(
          'Stock épuisé dans le dépôt "$depotEpuise" pour l\'article "${article.designation}".\n\n'
          'Basculement automatique vers le dépôt "${depotDisponible['depot']}" '
          '(Stock disponible: ${depotDisponible['stockDisponible'].toStringAsFixed(0)} ${depotDisponible['unite']}).\n\n'
          'Continuer avec ce dépôt?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _selectedDepot = depotDisponible['depot'];
        _stockDisponible = depotDisponible['stockDisponible'];
        _stockInsuffisant = false;
      });
    }
  }

  void _afficherModalStockInsuffisant(Article article, String depotActuel, List<Map<String, dynamic>> autresStocks) {
    String message;
    
    if (widget.tousDepots) {
      message = 'Stock épuisé dans tous les dépôts pour l\'article "${article.designation}".\nVente impossible.';
    } else {
      message = 'Stock épuisé dans le dépôt "$depotActuel" pour l\'article "${article.designation}".\nVente impossible.';
      
      if (autresStocks.isNotEmpty) {
        message += '\n\nStock disponible dans d\'autres dépôts:';
        for (var stock in autresStocks) {
          message += '\n• ${stock['depot']}: ${stock['stockDisponible'].toStringAsFixed(0)} ${stock['unite']}';
        }
        message += '\n\nUtilisez le mode "Tous dépôts" pour accéder à ces stocks.';
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock insuffisant'),
        content: Text(message),
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
    String unite = _selectedUnite ?? _selectedArticle!.u1 ?? 'Pce';

    if (quantite > _stockDisponible) {
      setState(() {
        _quantiteController.text = _stockDisponible.toStringAsFixed(0);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantité maximale disponible: ${_stockDisponible.toStringAsFixed(0)} $unite'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    _calculerMontant();
    setState(() {}); // Trigger rebuild to show/hide add button
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

  String _calculateRemiseAmount() {
    double totalHT = double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0;
    double remise = double.tryParse(_remiseController.text) ?? 0;
    double remiseAmount = totalHT * remise / 100;
    return _formatNumber(remiseAmount);
  }

  String _calculateTvaAmount() {
    double totalHT = double.tryParse(_totalHTController.text.replaceAll(' ', '')) ?? 0;
    double remise = double.tryParse(_remiseController.text) ?? 0;
    double totalApresRemise = totalHT - (totalHT * remise / 100);
    double tva = double.tryParse(_tvaController.text) ?? 0;
    double tvaAmount = totalApresRemise * tva / 100;
    return _formatNumber(tvaAmount);
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
    String unite = _selectedUnite ?? _selectedArticle!.u1!;

    // Vérifier une dernière fois le stock disponible
    if (quantite > _stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock insuffisant. Disponible: ${_stockDisponible.toStringAsFixed(0)} $unite'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _lignesVente.add({
        'designation': _selectedArticle!.designation,
        'unites': unite,
        'quantite': quantite,
        'prixUnitaire': prix,
        'montant': montant,
        'depot': _selectedDepot ?? 'MAG',
        'article': _selectedArticle, // Garder référence pour conversions
      });
    });

    _calculerTotaux();
    _resetArticleForm();
  }

  Future<void> _chargerSoldeClient(String? client) async {
    if (client == null || client.isEmpty) {
      setState(() {
        _soldeAnterieur = 0.0;
        _soldeAnterieurController.text = '0';
      });
      return;
    }

    try {
      double solde = await _databaseService.database.calculerSoldeClient(client);

      // Si on charge une vente existante, exclure cette vente du solde
      if (_isExistingPurchase && _numVentesController.text.isNotEmpty) {
        final venteActuelle = await (_databaseService.database.select(_databaseService.database.ventes)
              ..where((v) => v.numventes.equals(_numVentesController.text)))
            .getSingleOrNull();

        if (venteActuelle != null && venteActuelle.modepai == 'A crédit') {
          double montantVenteActuelle = (venteActuelle.totalttc ?? 0) - (venteActuelle.avance ?? 0);
          solde -= montantVenteActuelle; // Exclure cette vente du solde antérieur
        }
      }

      setState(() {
        _soldeAnterieur = solde;
        _soldeAnterieurController.text = _formatNumber(solde);
      });
      _calculerTotaux();
    } catch (e) {
      setState(() {
        _soldeAnterieur = 0.0;
        _soldeAnterieurController.text = '0';
      });
    }
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

    // Calculer le nouveau solde selon le mode de paiement
    double nouveauSolde = _soldeAnterieur; // Commencer par le solde antérieur
    if (_selectedModePaiement == 'A crédit') {
      nouveauSolde += reste; // Ajouter le reste à payer
    } else {
      // Pour les paiements comptant, le nouveau solde reste le solde antérieur
      nouveauSolde = _soldeAnterieur;
    }

    setState(() {
      _totalHTController.text = _formatNumber(totalHT);
      _totalTTCController.text = _formatNumber(totalTTC);
      _resteController.text = _formatNumber(reste);
      _nouveauSoldeController.text = _formatNumber(nouveauSolde);
    });
  }

  void _calculerMonnaie() {
    double totalTTC = double.tryParse(_totalTTCController.text.replaceAll(' ', '')) ?? 0;
    double montantRecu = double.tryParse(_montantRecuController.text.replaceAll(' ', '')) ?? 0;
    double monnaie = montantRecu - totalTTC;
    _montantARendreController.text = _formatNumber(monnaie > 0 ? monnaie : 0);
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

  bool _shouldShowAddButton() {
    return _selectedArticle != null && _quantiteController.text.isNotEmpty;
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

      double montantRecu = double.tryParse(_montantRecuController.text.replaceAll(' ', '')) ?? 0;
      double monnaieARendre = double.tryParse(_montantARendreController.text.replaceAll(' ', '')) ?? 0;

      final venteCompanion = VentesCompanion(
        numventes: drift.Value(_numVentesController.text),
        nfact: drift.Value(_nFactureController.text),
        daty: drift.Value(DateTime.now()),
        clt: drift.Value(_selectedClient ?? ''),
        modepai: drift.Value(_selectedModePaiement),
        totalnt: drift.Value(totalApresRemise),
        totalttc: drift.Value(totalTTC),
        tva: drift.Value(tva),
        avance: drift.Value(avance),
        commission: drift.Value(commission),
        remise: drift.Value(remise),
        heure: drift.Value(_heureController.text),
        verification: const drift.Value('Non vérifié'),
        montantRecu: drift.Value(montantRecu),
        monnaieARendre: drift.Value(monnaieARendre),
      );

      // Utiliser la nouvelle méthode intégrée
      await _databaseService.database.enregistrerVenteComplete(
        vente: venteCompanion,
        lignesVente: _lignesVente,
      );

      // Ajouter la nouvelle vente à la liste
      setState(() {
        if (!_ventesNumbers.contains(_numVentesController.text)) {
          _ventesNumbers.add(_numVentesController.text);
          _ventesNumbers.sort();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente enregistrée avec succès'), backgroundColor: Colors.green),
        );
        // Créer une nouvelle vente au lieu de fermer le modal
        await _creerNouvelleVente();
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
      _selectedClient = null;
      if (_autocompleteController != null) {
        _autocompleteController!.clear();
      }
    });

    _totalHTController.text = '0';
    _remiseController.text = '0';
    _tvaController.text = '0';
    _totalTTCController.text = '0';
    _avanceController.text = '0';
    _resteController.text = '0';
    _nouveauSoldeController.text = '0';
    _commissionController.text = '0';
    _montantRecuController.text = '0';
    _montantARendreController.text = '0';

    _resetArticleForm();
    _initializeForm();
    _chargerSoldeClient(null);
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

  void _apercuBL() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aperçu BL - Fonctionnalité à implémenter')),
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
          width: MediaQuery.of(context).size.width * 0.7,
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

              // Main content with sidebar
              Expanded(
                child: Row(
                  children: [
                    // Left sidebar - Sales list
                    Container(
                      width: 250,
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey, width: 1)),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          // Search field
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _searchVentesController,
                              decoration: const InputDecoration(
                                hintText: 'Rechercher vente...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                prefixIcon: Icon(Icons.search, size: 16),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          // Sales list
                          Expanded(
                            child: ListView.builder(
                              itemCount: _getFilteredVentesNumbers().length,
                              itemBuilder: (context, index) {
                                final numVente = _getFilteredVentesNumbers()[index];
                                final isSelected = numVente == _numVentesController.text;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  child: ListTile(
                                    dense: true,
                                    title: Text('Vente N° $numVente', style: const TextStyle(fontSize: 11)),
                                    selected: isSelected,
                                    selectedTileColor: Colors.blue[100],
                                    onTap: () {
                                      _numVentesController.text = numVente;
                                      _chargerVenteExistante(numVente);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right side - Main form
                    Expanded(
                      child: Column(
                        children: [
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
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                        child: Autocomplete<CltData>(
                                          optionsBuilder: (textEditingValue) {
                                            if (textEditingValue.text.isEmpty) {
                                              return _clients;
                                            }
                                            return _clients.where((client) {
                                              return client.rsoc
                                                  .toLowerCase()
                                                  .contains(textEditingValue.text.toLowerCase());
                                            });
                                          },
                                          displayStringForOption: (client) => client.rsoc,
                                          onSelected: (client) {
                                            setState(() {
                                              _selectedClient = client.rsoc;
                                              _clientController.text = client.rsoc;
                                            });
                                            _chargerSoldeClient(client.rsoc);
                                          },
                                          fieldViewBuilder:
                                              (context, controller, focusNode, onEditingComplete) {
                                            if (_selectedClient != null &&
                                                controller.text != _selectedClient) {
                                              controller.text = _selectedClient!;
                                            }
                                            if (_selectedClient == null) {
                                              controller.clear();
                                            }
                                            return TextField(
                                              controller: controller,
                                              focusNode: focusNode,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                hintText: 'Rechercher un client...',
                                              ),
                                              style: const TextStyle(fontSize: 12),
                                            );
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
                                              return _articles;
                                            }
                                            return _articles.where((article) {
                                              return article.designation
                                                  .toLowerCase()
                                                  .contains(textEditingValue.text.toLowerCase());
                                            });
                                          },
                                          displayStringForOption: (article) => article.designation,
                                          onSelected: _onArticleSelected,
                                          optionsViewBuilder: (context, onSelected, options) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                elevation: 4.0,
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(maxHeight: 200, maxWidth: 300),
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount: options.length,
                                                    itemBuilder: (context, index) {
                                                      final article = options.elementAt(index);
                                                      return ListTile(
                                                        dense: true,
                                                        title: Text(article.designation,
                                                            style: const TextStyle(fontSize: 11)),
                                                        subtitle: Text(_buildStockSummary(article),
                                                            style: const TextStyle(
                                                                fontSize: 9, color: Colors.grey)),
                                                        onTap: () => onSelected(article),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
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
                                            Flexible(
                                              child: Text(
                                                  ' (Stock: ${_stockDisponible.toStringAsFixed(0)} ${_selectedUnite ?? ''})',
                                                  style: const TextStyle(fontSize: 9, color: Colors.green),
                                                  overflow: TextOverflow.ellipsis),
                                            ),
                                          if (_selectedArticle != null && _stockDisponible > 0)
                                            _buildStockInfo(),
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
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            ),
                                            items: _depots.map((depot) {
                                              return DropdownMenuItem<String>(
                                                value: depot.depots,
                                                child:
                                                    Text(depot.depots, style: const TextStyle(fontSize: 12)),
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
                                if (_shouldShowAddButton()) ...[
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _isArticleFormValid() ? _ajouterLigne : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isArticleFormValid() ? Colors.green : Colors.grey,
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
                                                border:
                                                    Border(bottom: BorderSide(color: Colors.grey, width: 1)),
                                              ),
                                              child: const Text('DEPOTS',
                                                  style:
                                                      TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                    fontStyle: FontStyle.italic)),
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
                                                            (ligne['quantite'] as double?)
                                                                    ?.round()
                                                                    .toString() ??
                                                                '0',
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
                                                        child: Text(
                                                            _formatNumber(
                                                                ligne['prixUnitaire']?.toDouble() ?? 0),
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
                                                                ? const BorderSide(
                                                                    color: Colors.grey, width: 1)
                                                                : BorderSide.none,
                                                            bottom: const BorderSide(
                                                                color: Colors.grey, width: 1),
                                                          ),
                                                        ),
                                                        child: Text(
                                                            _formatNumber(ligne['montant']?.toDouble() ?? 0),
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
                                                            border: Border(
                                                                bottom:
                                                                    BorderSide(color: Colors.grey, width: 1)),
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

                          // Bottom section - Invoice-style totals and payment
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left side - Payment details
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('MODE DE PAIEMENT',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 25,
                                          child: DropdownButtonFormField<String>(
                                            initialValue: _selectedModePaiement,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'A crédit',
                                                  child: Text('A crédit', style: TextStyle(fontSize: 12))),
                                              DropdownMenuItem(
                                                  value: 'Espèces',
                                                  child: Text('Espèces', style: TextStyle(fontSize: 12))),
                                              DropdownMenuItem(
                                                  value: 'Chèque',
                                                  child: Text('Chèque', style: TextStyle(fontSize: 12))),
                                              DropdownMenuItem(
                                                  value: 'Virement',
                                                  child: Text('Virement', style: TextStyle(fontSize: 12))),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedModePaiement = value!;
                                                if (value != 'Espèces') {
                                                  _montantRecuController.text = '0';
                                                  _montantARendreController.text = '0';
                                                }
                                              });
                                              _calculerTotaux();
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Text('Avance:', style: TextStyle(fontSize: 12)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SizedBox(
                                                height: 25,
                                                child: TextField(
                                                  controller: _avanceController,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  ),
                                                  style: const TextStyle(fontSize: 12),
                                                  onChanged: (value) => _calculerTotaux(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text('Commission:', style: TextStyle(fontSize: 12)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SizedBox(
                                                height: 25,
                                                child: TextField(
                                                  controller: _commissionController,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  ),
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Text('Solde antérieur:', style: TextStyle(fontSize: 12)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SizedBox(
                                                height: 25,
                                                child: TextField(
                                                  controller: _soldeAnterieurController,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    fillColor: Color(0xFFF5F5F5),
                                                    filled: true,
                                                  ),
                                                  style: const TextStyle(fontSize: 12),
                                                  textAlign: TextAlign.right,
                                                  readOnly: true,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              _selectedModePaiement == 'A crédit'
                                                  ? 'Solde dû client:'
                                                  : 'Nouveau solde:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _selectedModePaiement == 'A crédit'
                                                    ? Colors.red
                                                    : Colors.black,
                                                fontWeight: _selectedModePaiement == 'A crédit'
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SizedBox(
                                                height: 25,
                                                child: TextField(
                                                  controller: _nouveauSoldeController,
                                                  decoration: InputDecoration(
                                                    border: const OutlineInputBorder(),
                                                    contentPadding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 4),
                                                    fillColor: _selectedModePaiement == 'A crédit'
                                                        ? Colors.red.shade50
                                                        : const Color(0xFFF5F5F5),
                                                    filled: true,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _selectedModePaiement == 'A crédit'
                                                        ? Colors.red
                                                        : Colors.black,
                                                    fontWeight: _selectedModePaiement == 'A crédit'
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                  ),
                                                  readOnly: true,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right side - Invoice totals
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('RÉCAPITULATIF FACTURE',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 12),
                                        // Total HT
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Total HT:', style: TextStyle(fontSize: 12)),
                                            SizedBox(
                                              width: 100,
                                              height: 25,
                                              child: TextField(
                                                controller: _totalHTController,
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                ),
                                                style: const TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w500),
                                                textAlign: TextAlign.right,
                                                readOnly: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Remise
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Remise:', style: TextStyle(fontSize: 12)),
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  width: 40,
                                                  height: 25,
                                                  child: TextField(
                                                    controller: _remiseController,
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                      suffixText: '%',
                                                    ),
                                                    style: const TextStyle(fontSize: 12),
                                                    textAlign: TextAlign.center,
                                                    onChanged: (value) => _calculerTotaux(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: 100,
                                              height: 25,
                                              child: TextField(
                                                controller: TextEditingController(
                                                  text: _calculateRemiseAmount(),
                                                ),
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                ),
                                                style: const TextStyle(fontSize: 12),
                                                textAlign: TextAlign.right,
                                                readOnly: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // TVA
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('TVA:', style: TextStyle(fontSize: 12)),
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  width: 40,
                                                  height: 25,
                                                  child: TextField(
                                                    controller: _tvaController,
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                      suffixText: '%',
                                                    ),
                                                    style: const TextStyle(fontSize: 12),
                                                    textAlign: TextAlign.center,
                                                    onChanged: (value) => _calculerTotaux(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: 100,
                                              height: 25,
                                              child: TextField(
                                                controller: TextEditingController(
                                                  text: _calculateTvaAmount(),
                                                ),
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                ),
                                                style: const TextStyle(fontSize: 12),
                                                textAlign: TextAlign.right,
                                                readOnly: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 16),
                                        // Total TTC
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('TOTAL TTC:',
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            SizedBox(
                                              width: 100,
                                              height: 30,
                                              child: TextField(
                                                controller: _totalTTCController,
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                                textAlign: TextAlign.right,
                                                readOnly: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Reste à payer
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Reste à payer:',
                                                style: TextStyle(fontSize: 12, color: Colors.red)),
                                            SizedBox(
                                              width: 100,
                                              height: 25,
                                              child: TextField(
                                                controller: _resteController,
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                ),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w500),
                                                textAlign: TextAlign.right,
                                                readOnly: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_selectedModePaiement == 'Espèces') ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Montant reçu:', style: TextStyle(fontSize: 12)),
                                              SizedBox(
                                                width: 100,
                                                height: 25,
                                                child: TextField(
                                                  controller: _montantRecuController,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    fillColor: Colors.white,
                                                    filled: true,
                                                  ),
                                                  style: const TextStyle(fontSize: 12),
                                                  textAlign: TextAlign.right,
                                                  onChanged: (value) => _calculerMonnaie(),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Monnaie à rendre:',
                                                  style: TextStyle(fontSize: 12, color: Colors.green)),
                                              SizedBox(
                                                width: 100,
                                                height: 25,
                                                child: TextField(
                                                  controller: _montantARendreController,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    fillColor: Color(0xFFF0F8FF),
                                                    filled: true,
                                                  ),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w500),
                                                  textAlign: TextAlign.right,
                                                  readOnly: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
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
                                  onPressed: _lignesVente.isNotEmpty ? _apercuBL : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(80, 32),
                                  ),
                                  child: const Text('Aperçu BL', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  initialValue: _selectedFormat,
                                  onSelected: (String format) {
                                    setState(() {
                                      _selectedFormat = format;
                                    });
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'A4',
                                      child: Text('Format A4', style: TextStyle(fontSize: 12)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'A5',
                                      child: Text('Format A5', style: TextStyle(fontSize: 12)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'A6',
                                      child: Text('Format A6', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.brown,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.format_size, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(_selectedFormat,
                                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                                      ],
                                    ),
                                  ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
