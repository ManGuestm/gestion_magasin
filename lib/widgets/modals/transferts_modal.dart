import 'package:drift/drift.dart' as drift hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';
import '../common/article_navigation_autocomplete.dart';
import 'bon_transfert_preview.dart';

class TransfertsModal extends StatefulWidget {
  const TransfertsModal({super.key});

  @override
  State<TransfertsModal> createState() => _TransfertsModalState();
}

class _TransfertsModalState extends State<TransfertsModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();

  // Controllers
  final TextEditingController _numTransfertController = TextEditingController();
  final TextEditingController _bonExpeditionController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _articleFocusNode = FocusNode();

  // Focus nodes for tab navigation
  final FocusNode _bonExpeditionFocusNode = FocusNode();
  final FocusNode _depotVenantFocusNode = FocusNode();
  final FocusNode _depotVersFocusNode = FocusNode();
  final FocusNode _uniteFocusNode = FocusNode();
  final FocusNode _quantiteFocusNode = FocusNode();
  final FocusNode _ajouterFocusNode = FocusNode();
  final FocusNode _validerFocusNode = FocusNode();
  final FocusNode _nouveauFocusNode = FocusNode();
  final FocusNode _apercuFocusNode = FocusNode();

  late final List<FocusNode> _focusNodes;

  // Lists
  List<Article> _articlesAvecStock = [];
  List<Depot> _depots = [];
  List<TransfData> _transfertsEffectues = [];
  List<TransfData> _transfertsFiltres = [];
  final List<Map<String, dynamic>> _lignesTransfert = [];

  // Selected values
  Article? _selectedArticle;
  String? _selectedUnite;
  String? _selectedDepotVenant;
  String? _selectedDepotVers;
  DateTime _selectedDate = DateTime.now();

  // Stock management
  final Map<String, double> _stocksDisponibles = {};

  // Transfer state
  String _selectedFormat = 'A5';

  @override
  void initState() {
    super.initState();
    _focusNodes = [
      _bonExpeditionFocusNode,
      _depotVenantFocusNode,
      _depotVersFocusNode,
      _articleFocusNode,
      _uniteFocusNode,
      _quantiteFocusNode,
      _ajouterFocusNode,
      _validerFocusNode,
      _nouveauFocusNode,
      _apercuFocusNode,
    ];
    _loadData();
    _initializeForm();
  }

  @override
  void dispose() {
    _numTransfertController.dispose();
    _bonExpeditionController.dispose();
    _quantiteController.dispose();
    _searchController.dispose();
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<String> _getNextNumTransfert() async {
    try {
      // Récupérer tous les transferts qui commencent par T
      final transferts = await _databaseService.database.customSelect('SELECT numtransf FROM transf').get();

      debugPrint('Nombre total de transferts: ${transferts.length}');

      // Filtrer et extraire les numéros
      int maxNum = 1000;
      for (var row in transferts) {
        final numtransf = row.data['numtransf'] as String?;
        debugPrint('Transfert trouvé: $numtransf');

        if (numtransf != null && numtransf.startsWith('T')) {
          final numStr = numtransf.substring(1);
          final num = int.tryParse(numStr);
          if (num != null && num > maxNum) {
            maxNum = num;
          }
        }
      }

      final nextNum = maxNum + 1;
      debugPrint('Prochain numéro: T$nextNum');
      return 'T$nextNum';
    } catch (e) {
      debugPrint('Erreur lors de la génération du numéro: $e');
      return 'T1001';
    }
  }

  Future<void> _initializeForm() async {
    final nextNum = await _getNextNumTransfert();
    if (mounted) {
      setState(() {
        _numTransfertController.text = nextNum;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final depots = await _databaseService.database.getAllDepots();

      // Utiliser une requête SQL directe pour récupérer les transferts
      final transfertsResult = await _databaseService.database
          .customSelect('SELECT * FROM transf ORDER BY daty DESC, numtransf DESC')
          .get();

      final transferts = transfertsResult.map((row) {
        DateTime? date;
        final datyValue = row.data['daty'];
        if (datyValue != null) {
          if (datyValue is String) {
            date = DateTime.tryParse(datyValue);
          } else if (datyValue is int) {
            // Convertir en millisecondes si nécessaire
            date = datyValue > 1000000000000
                ? DateTime.fromMillisecondsSinceEpoch(datyValue)
                : DateTime.fromMillisecondsSinceEpoch(datyValue * 1000);
          }
        }
        date ??= DateTime.now();

        return TransfData(
          num: row.data['num'] as int? ?? 0,
          numtransf: row.data['numtransf'] as String?,
          daty: date,
          de: row.data['de'] as String?,
          au: row.data['au'] as String?,
          contre: row.data['contre'] as String?,
        );
      }).toList();

      setState(() {
        _depots = depots;
        _transfertsEffectues = transferts;
        _transfertsFiltres = _transfertsEffectues;
      });

      // Debug: afficher le nombre de transferts trouvés
      debugPrint('Transferts chargés: ${transferts.length}');
      for (var t in transferts) {
        debugPrint('Transfert: ${t.numtransf} - ${t.de} → ${t.au} - ${t.daty}');
      }
    } catch (e) {
      debugPrint('Erreur chargement transferts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _chargerArticlesAvecStock() async {
    if (_selectedDepotVenant == null) return;

    try {
      final stocksDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) =>
                d.depots.equals(_selectedDepotVenant!) &
                ((d.stocksu1.isNotNull() & d.stocksu1.isBiggerThanValue(0)) |
                    (d.stocksu2.isNotNull() & d.stocksu2.isBiggerThanValue(0)) |
                    (d.stocksu3.isNotNull() & d.stocksu3.isBiggerThanValue(0)))))
          .get();

      final articlesAvecStock = <Article>[];
      for (var stock in stocksDepart) {
        final article = await _databaseService.database.getArticleByDesignation(stock.designation);
        if (article != null) {
          articlesAvecStock.add(article);
        }
      }

      setState(() {
        _articlesAvecStock = articlesAvecStock;
      });
    } catch (e) {
      setState(() {
        _articlesAvecStock = [];
      });
    }
  }

  void _onArticleSelected(Article? article) async {
    setState(() {
      _selectedArticle = article;
      if (article != null) {
        _selectedUnite = article.u1;
        _quantiteController.clear();
      }
    });

    if (article != null) {
      await _chargerStocksDepots(article);
    }
  }

  Future<void> _chargerStocksDepots(Article article) async {
    try {
      final stocksDepart = await (_databaseService.database.select(_databaseService.database.depart)
            ..where((d) => d.designation.equals(article.designation)))
          .get();

      setState(() {
        _stocksDisponibles.clear();
        for (var stock in stocksDepart) {
          double stockTotal = 0;
          if (_selectedUnite == article.u1) {
            stockTotal = stock.stocksu1 ?? 0;
          } else if (_selectedUnite == article.u2) {
            stockTotal = stock.stocksu2 ?? 0;
          } else if (_selectedUnite == article.u3) {
            stockTotal = stock.stocksu3 ?? 0;
          }
          _stocksDisponibles[stock.depots] = stockTotal;
        }
      });
    } catch (e) {
      setState(() {
        _stocksDisponibles.clear();
      });
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
        ? [const DropdownMenuItem(value: 'Pce', child: Text('Pce', style: TextStyle(fontSize: 12)))]
        : units;
  }

  void _onUniteChanged(String? unite) async {
    if (_selectedArticle == null || unite == null) return;

    setState(() {
      _selectedUnite = unite;
      _quantiteController.clear();
    });

    await _chargerStocksDepots(_selectedArticle!);
  }

  bool _peutAjouterLigne() {
    if (_selectedArticle == null ||
        _selectedDepotVenant == null ||
        _selectedDepotVers == null ||
        _quantiteController.text.isEmpty) {
      return false;
    }

    double quantite = double.tryParse(_quantiteController.text) ?? 0.0;
    if (quantite <= 0) return false;

    double stockDisponible = _stocksDisponibles[_selectedDepotVenant] ?? 0;
    return quantite <= stockDisponible;
  }

  void _ajouterLigne() {
    if (!_peutAjouterLigne()) return;

    double quantite = double.tryParse(_quantiteController.text) ?? 0.0;

    setState(() {
      _lignesTransfert.add({
        'designation': _selectedArticle!.designation,
        'unites': _selectedUnite,
        'quantite': quantite,
      });
    });

    _resetArticleForm();
  }

  void _resetArticleForm() {
    setState(() {
      _selectedArticle = null;
      _selectedUnite = null;
      _quantiteController.clear();
      _stocksDisponibles.clear();
    });
  }

  void _supprimerLigne(int index) {
    setState(() {
      _lignesTransfert.removeAt(index);
    });
  }

  Future<void> _validerTransfert() async {
    if (_lignesTransfert.isEmpty || _selectedDepotVenant == null || _selectedDepotVers == null) return;

    try {
      await _databaseService.database.transaction(() async {
        // 1. Insérer le transfert principal
        await _databaseService.database.into(_databaseService.database.transf).insert(
              TransfCompanion.insert(
                numtransf: drift.Value(_numTransfertController.text),
                daty: drift.Value(_selectedDate),
                de: drift.Value(_selectedDepotVenant!),
                au: drift.Value(_selectedDepotVers!),
                bonExpedition: _bonExpeditionController.text.isNotEmpty 
                    ? drift.Value(_bonExpeditionController.text) 
                    : const drift.Value.absent(),
              ),
            );

        // 2. Insérer les détails du transfert et mettre à jour les stocks
        for (var ligne in _lignesTransfert) {
          await _databaseService.database.into(_databaseService.database.dettransf).insert(
                DettransfCompanion.insert(
                  numtransf: drift.Value(_numTransfertController.text),
                  designation: drift.Value(ligne['designation']),
                  unites: drift.Value(ligne['unites']),
                  q: drift.Value(ligne['quantite']),
                ),
              );

          // 3. Mettre à jour les stocks
          await _mettreAJourStocksTransfert(
            ligne['designation'],
            ligne['unites'],
            ligne['quantite'],
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfert enregistré avec succès'), backgroundColor: Colors.green),
        );
        await _loadData(); // Recharger les données d'abord
        await _creerNouveauTransfert(); // Puis créer nouveau transfert
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _mettreAJourStocksTransfert(String designation, String unite, double quantite) async {
    // Trouver l'article pour les conversions
    final article = await _databaseService.database.getArticleByDesignation(designation);
    if (article == null) return;

    // Convertir la quantité selon l'unité
    double quantiteU1 = 0, quantiteU2 = 0, quantiteU3 = 0;

    if (unite == article.u1) {
      quantiteU1 = quantite;
    } else if (unite == article.u2) {
      quantiteU2 = quantite;
    } else if (unite == article.u3) {
      quantiteU3 = quantite;
    }

    // Déduire du dépôt source
    final stockSource = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(designation) & d.depots.equals(_selectedDepotVenant!)))
        .getSingleOrNull();

    if (stockSource != null) {
      await (_databaseService.database.update(_databaseService.database.depart)
            ..where((d) => d.designation.equals(designation) & d.depots.equals(_selectedDepotVenant!)))
          .write(DepartCompanion(
        stocksu1: drift.Value((stockSource.stocksu1 ?? 0) - quantiteU1),
        stocksu2: drift.Value((stockSource.stocksu2 ?? 0) - quantiteU2),
        stocksu3: drift.Value((stockSource.stocksu3 ?? 0) - quantiteU3),
      ));
    }

    // Ajouter au dépôt destination
    final stockDest = await (_databaseService.database.select(_databaseService.database.depart)
          ..where((d) => d.designation.equals(designation) & d.depots.equals(_selectedDepotVers!)))
        .getSingleOrNull();

    if (stockDest != null) {
      await (_databaseService.database.update(_databaseService.database.depart)
            ..where((d) => d.designation.equals(designation) & d.depots.equals(_selectedDepotVers!)))
          .write(DepartCompanion(
        stocksu1: drift.Value((stockDest.stocksu1 ?? 0) + quantiteU1),
        stocksu2: drift.Value((stockDest.stocksu2 ?? 0) + quantiteU2),
        stocksu3: drift.Value((stockDest.stocksu3 ?? 0) + quantiteU3),
      ));
    } else {
      // Créer l'entrée si elle n'existe pas
      await _databaseService.database.into(_databaseService.database.depart).insert(
            DepartCompanion.insert(
              designation: designation,
              depots: _selectedDepotVers!,
              stocksu1: drift.Value(quantiteU1),
              stocksu2: drift.Value(quantiteU2),
              stocksu3: drift.Value(quantiteU3),
            ),
          );
    }

    // Mettre à jour les stocks globaux dans la table articles
    await _mettreAJourStocksGlobaux(article, quantiteU1, quantiteU2, quantiteU3);
  }

  Future<void> _mettreAJourStocksGlobaux(
      Article article, double quantiteU1, double quantiteU2, double quantiteU3) async {
    // Les stocks globaux ne changent pas lors d'un transfert (juste déplacement entre dépôts)
    // Cette méthode est gardée pour cohérence mais ne fait rien
    // car un transfert ne modifie que la répartition entre dépôts
  }

  Future<void> _creerNouveauTransfert() async {
    setState(() {
      _lignesTransfert.clear();
      _selectedDepotVenant = null;
      _selectedDepotVers = null;
      _selectedDate = DateTime.now();
      _bonExpeditionController.clear();
    });
    _resetArticleForm();
    await _initializeForm(); // Générer le nouveau numéro
  }

  void _filtrerTransferts(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _transfertsFiltres = _transfertsEffectues;
      } else {
        _transfertsFiltres = _transfertsEffectues.where((transfert) {
          final numTransfert = transfert.numtransf?.toLowerCase() ?? '';
          final depotDe = transfert.de?.toLowerCase() ?? '';
          final depotAu = transfert.au?.toLowerCase() ?? '';
          final searchLower = searchText.toLowerCase();

          return numTransfert.contains(searchLower) ||
              depotDe.contains(searchLower) ||
              depotAu.contains(searchLower);
        }).toList();
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        final currentIndex = _focusNodes.indexOf(node);
        if (currentIndex != -1) {
          int nextIndex;
          if (HardwareKeyboard.instance.isShiftPressed) {
            nextIndex = (currentIndex - 1) % _focusNodes.length;
            if (nextIndex < 0) nextIndex = _focusNodes.length - 1;
          } else {
            nextIndex = (currentIndex + 1) % _focusNodes.length;
          }
          _focusNodes[nextIndex].requestFocus();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _chargerTransfertExistant(TransfData transfert) async {
    if (transfert.numtransf == null) return;

    try {
      // Charger les détails du transfert
      final details = await (_databaseService.database.select(_databaseService.database.dettransf)
            ..where((d) => d.numtransf.equals(transfert.numtransf!)))
          .get();

      setState(() {
        _numTransfertController.text = transfert.numtransf!;
        _selectedDate = transfert.daty ?? DateTime.now();
        _selectedDepotVenant = transfert.de;
        _selectedDepotVers = transfert.au;
        _bonExpeditionController.text = transfert.bonExpedition ?? '';

        _lignesTransfert.clear();
        for (var detail in details) {
          _lignesTransfert.add({
            'designation': detail.designation ?? '',
            'unites': detail.unites ?? '',
            'quantite': detail.q ?? 0.0,
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfert ${transfert.numtransf} chargé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _ouvrirApercuBT() async {
    if (_lignesTransfert.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun article à afficher dans le bon de transfert')),
      );
      return;
    }

    try {
      final societe =
          await (_databaseService.database.select(_databaseService.database.soc)).getSingleOrNull();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => BonTransfertPreview(
            numTransfert: _numTransfertController.text,
            date: _selectedDate,
            depotVenant: _selectedDepotVenant ?? '',
            depotVers: _selectedDepotVers ?? '',
            lignesTransfert: _lignesTransfert,
            societe: societe,
            format: _selectedFormat,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ouverture de l\'aperçu: $e')),
        );
      }
    }
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
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              // Title bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 35,
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          'Transfert',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

              // Main content
              Expanded(
                child: Container(
                  color: const Color(0xFFE6E6FA),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      // Section gauche - Liste des transferts
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                              child: const Center(
                                child: Text('Transferts Effectués',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            // Search field
                            Container(
                              height: 30,
                              padding: const EdgeInsets.all(4),
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Rechercher...',
                                  hintStyle: TextStyle(fontSize: 10),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  prefixIcon: Icon(Icons.search, size: 16),
                                ),
                                style: const TextStyle(fontSize: 10),
                                onChanged: _filtrerTransferts,
                              ),
                            ),
                            Expanded(
                              child: _transfertsFiltres.isEmpty
                                  ? const Center(
                                      child: Text('Aucun transfert', style: TextStyle(fontSize: 11)))
                                  : ListView.builder(
                                      itemCount: _transfertsFiltres.length,
                                      itemBuilder: (context, index) {
                                        final transfert = _transfertsFiltres[index];
                                        return Focus(
                                          autofocus: true,
                                          onKeyEvent: (node, event) => handleTabNavigation(event),
                                          child: InkWell(
                                            onTap: () => _chargerTransfertExistant(transfert),
                                            child: Container(
                                              height: 55,
                                              decoration: BoxDecoration(
                                                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                                border: const Border(
                                                    bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(transfert.numtransf ?? 'N/A',
                                                        style: const TextStyle(
                                                            fontSize: 11, fontWeight: FontWeight.bold)),
                                                    Text('${transfert.de ?? ''} → ${transfert.au ?? ''}',
                                                        style: const TextStyle(
                                                            fontSize: 10, color: Colors.blue)),
                                                    Text(_formatDate(transfert.daty),
                                                        style:
                                                            const TextStyle(fontSize: 9, color: Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Section droite - Formulaire
                      Expanded(
                        child: Column(
                          children: [
                            // Header section
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('N° Transfert', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 120,
                                      height: 25,
                                      child: TextField(
                                        controller: _numTransfertController,
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
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('N° Bon d\'expédition', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 120,
                                      height: 25,
                                      child: Focus(
                                        focusNode: _bonExpeditionFocusNode,
                                        onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                        child: TextField(
                                          controller: _bonExpeditionController,
                                          focusNode: _bonExpeditionFocusNode,
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 100,
                                      height: 25,
                                      child: InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _selectedDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              _selectedDate = date;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _formatDate(_selectedDate),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Depot selection
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Venant de', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 150,
                                      height: 25,
                                      child: Focus(
                                        focusNode: _depotVenantFocusNode,
                                        onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedDepotVenant,
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
                                              _selectedDepotVenant = value;
                                              _selectedDepotVers = null;
                                              _selectedArticle = null;
                                              _articlesAvecStock = [];
                                            });
                                            _chargerArticlesAvecStock();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Au', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 150,
                                      height: 25,
                                      child: Focus(
                                        focusNode: _depotVersFocusNode,
                                        onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedDepotVers,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          ),
                                          items: _depots
                                              .where((depot) => depot.depots != _selectedDepotVenant)
                                              .map((depot) {
                                            return DropdownMenuItem<String>(
                                              value: depot.depots,
                                              child: Text(depot.depots, style: const TextStyle(fontSize: 12)),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedDepotVers = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Article selection section
                            Row(
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
                                        child: Focus(
                                          focusNode: _articleFocusNode,
                                          onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                          child: ArticleNavigationAutocomplete(
                                            articles: _articlesAvecStock,
                                            selectedArticle: _selectedArticle,
                                            onArticleChanged: _onArticleSelected,
                                            focusNode: _articleFocusNode,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            ),
                                            style: const TextStyle(fontSize: 12),
                                          ),
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
                                        child: Focus(
                                          focusNode: _uniteFocusNode,
                                          onKeyEvent: (node, event) => _handleKeyEvent(node, event),
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
                                      const Text('Quantités', style: TextStyle(fontSize: 12)),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        height: 25,
                                        child: Focus(
                                          focusNode: _quantiteFocusNode,
                                          onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                          child: TextField(
                                            controller: _quantiteController,
                                            focusNode: _quantiteFocusNode,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            ),
                                            style: const TextStyle(fontSize: 12),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                                            ],
                                            onChanged: (value) {
                                              if (_selectedDepotVenant != null && value.isNotEmpty) {
                                                double quantite = double.tryParse(value) ?? 0.0;
                                                double stockDisponible =
                                                    _stocksDisponibles[_selectedDepotVenant] ?? 0;
                                                if (quantite > stockDisponible && stockDisponible > 0) {
                                                  _quantiteController.text = stockDisponible.toInt().toString();
                                                  _quantiteController.selection = TextSelection.fromPosition(
                                                    TextPosition(offset: _quantiteController.text.length),
                                                  );
                                                }
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Focus(
                                      focusNode: _ajouterFocusNode,
                                      onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                      child: ElevatedButton(
                                        onPressed: _peutAjouterLigne() ? _ajouterLigne : null,
                                        focusNode: _ajouterFocusNode,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(60, 25),
                                        ),
                                        child: const Text('Ajouter', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stock display section
                            if (_selectedArticle != null && _stocksDisponibles.isNotEmpty) ...[
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 25,
                                      decoration: BoxDecoration(color: Colors.orange[300]),
                                      child: const Row(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: Text('DEPOTS',
                                                  style:
                                                      TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: Text('STOCKS DISPONIBLES',
                                                  style:
                                                      TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _stocksDisponibles.length,
                                        itemBuilder: (context, index) {
                                          final depot = _stocksDisponibles.keys.elementAt(index);
                                          final stock = _stocksDisponibles[depot] ?? 0;
                                          return Container(
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                              border: const Border(
                                                  bottom: BorderSide(color: Colors.grey, width: 1)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Text(depot, style: const TextStyle(fontSize: 11)),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Center(
                                                    child: Text(
                                                      '${stock.toStringAsFixed(0)} ${_selectedUnite ?? ''}',
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
                              const SizedBox(height: 16),
                            ],

                            // Transfer lines table
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 25,
                                      decoration: BoxDecoration(color: Colors.orange[300]),
                                      child: const Row(
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            child: Center(
                                              child: Icon(Icons.delete, size: 12),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text('DESIGNATION',
                                                  style:
                                                      TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Text('UNITES',
                                                  style:
                                                      TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Text('QUANTITES',
                                                  style:
                                                      TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: _lignesTransfert.isEmpty
                                          ? const Center(
                                              child: Text('Aucun article ajouté',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey)))
                                          : ListView.builder(
                                              itemCount: _lignesTransfert.length,
                                              itemBuilder: (context, index) {
                                                final ligne = _lignesTransfert[index];
                                                return Container(
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                                    border: const Border(
                                                        bottom: BorderSide(color: Colors.grey, width: 1)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 30,
                                                        child: IconButton(
                                                          onPressed: () => _supprimerLigne(index),
                                                          icon: const Icon(Icons.delete,
                                                              size: 12, color: Colors.red),
                                                          padding: EdgeInsets.zero,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(left: 4),
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
                                                            ligne['unites'] ?? '',
                                                            style: const TextStyle(fontSize: 11),
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Center(
                                                          child: Text(
                                                            (ligne['quantite'] ?? 0).toString(),
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
                            const SizedBox(height: 16),

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Focus(
                                  focusNode: _nouveauFocusNode,
                                  onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                  child: ElevatedButton(
                                    onPressed: _creerNouveauTransfert,
                                    focusNode: _nouveauFocusNode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(60, 30),
                                    ),
                                    child: const Text('Créer', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                Focus(
                                  focusNode: _validerFocusNode,
                                  onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                  child: ElevatedButton(
                                    onPressed: _lignesTransfert.isNotEmpty ? _validerTransfert : null,
                                    focusNode: _validerFocusNode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(60, 30),
                                    ),
                                    child: const Text('Enregistrer', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                Focus(
                                  focusNode: _apercuFocusNode,
                                  onKeyEvent: (node, event) => _handleKeyEvent(node, event),
                                  child: ElevatedButton(
                                    onPressed: _lignesTransfert.isNotEmpty ? _ouvrirApercuBT : null,
                                    focusNode: _apercuFocusNode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(70, 30),
                                    ),
                                    child: const Text('Aperçu BT', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(60, 30),
                                  ),
                                  child: const Text('Fermer', style: TextStyle(fontSize: 12)),
                                ),
                                Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Format:', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 6),
                                      DropdownButton<String>(
                                        value: _selectedFormat,
                                        underline: const SizedBox(),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'A4',
                                            child: Text('A4', style: TextStyle(fontSize: 12)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'A5',
                                            child: Text('A5', style: TextStyle(fontSize: 12)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'A6',
                                            child: Text('A6', style: TextStyle(fontSize: 12)),
                                          ),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
