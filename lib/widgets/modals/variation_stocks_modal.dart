import 'package:flutter/material.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart';
import '../common/tab_navigation_widget.dart';

class VariationStocksModal extends StatefulWidget {
  const VariationStocksModal({super.key});

  @override
  State<VariationStocksModal> createState() => _VariationStocksModalState();
}

class _VariationStocksModalState extends State<VariationStocksModal> with TabNavigationMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Stock> mouvements = [];
  List<Map<String, dynamic>> _mouvementsAvecStock = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Aujourd\'hui';
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _loadMouvements();
  }

  Future<void> _loadMouvements() async {
    setState(() => _isLoading = true);

    try {
      final allStocks = await _databaseService.database.getAllStocks();
      List<Stock> filteredStocks = [];

      final now = DateTime.now();
      switch (_selectedPeriod) {
        case 'Aujourd\'hui':
          filteredStocks = allStocks.where((s) {
            if (s.daty == null) return false;
            DateTime date = s.daty is int
                ? DateTime.fromMillisecondsSinceEpoch((s.daty as int) * 1000)
                : s.daty as DateTime;
            return date.year == now.year && date.month == now.month && date.day == now.day;
          }).toList();
          break;
        case 'Hier':
          final yesterday = now.subtract(const Duration(days: 1));
          filteredStocks = allStocks.where((s) {
            if (s.daty == null) return false;
            DateTime date = s.daty is int
                ? DateTime.fromMillisecondsSinceEpoch((s.daty as int) * 1000)
                : s.daty as DateTime;
            return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
          }).toList();
          break;
        case 'Cette semaine':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          filteredStocks = allStocks.where((s) {
            if (s.daty == null) return false;
            DateTime date = s.daty is int
                ? DateTime.fromMillisecondsSinceEpoch((s.daty as int) * 1000)
                : s.daty as DateTime;
            return date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
          }).toList();
          break;
        case 'Semaine dernière':
          final endLastWeek = now.subtract(Duration(days: now.weekday));
          final startLastWeek = endLastWeek.subtract(const Duration(days: 6));
          filteredStocks = allStocks.where((s) {
            if (s.daty == null) return false;
            DateTime date = s.daty is int
                ? DateTime.fromMillisecondsSinceEpoch((s.daty as int) * 1000)
                : s.daty as DateTime;
            return date.isAfter(startLastWeek.subtract(const Duration(days: 1))) &&
                date.isBefore(endLastWeek.add(const Duration(days: 1)));
          }).toList();
          break;
        case 'Ce mois':
          filteredStocks = allStocks.where((s) {
            if (s.daty == null) return false;
            DateTime date = s.daty is int
                ? DateTime.fromMillisecondsSinceEpoch((s.daty as int) * 1000)
                : s.daty as DateTime;
            return date.year == now.year && date.month == now.month;
          }).toList();
          break;
        case 'Plage de dates':
          if (_dateDebut != null && _dateFin != null) {
            filteredStocks = allStocks.where((s) {
              if (s.daty == null) return false;
              DateTime date = s.daty is int
                  ? DateTime.fromMillisecondsSinceEpoch((s.daty as int) * 1000)
                  : s.daty as DateTime;
              return date.isAfter(_dateDebut!.subtract(const Duration(days: 1))) &&
                  date.isBefore(_dateFin!.add(const Duration(days: 1)));
            }).toList();
          } else {
            filteredStocks = [];
          }
          break;
        default:
          filteredStocks = allStocks;
      }

      // Trier par date
      filteredStocks.sort((a, b) {
        if (a.daty == null && b.daty == null) return 0;
        if (a.daty == null) return 1;
        if (b.daty == null) return -1;

        DateTime dateA =
            a.daty is int ? DateTime.fromMillisecondsSinceEpoch((a.daty as int) * 1000) : a.daty as DateTime;
        DateTime dateB =
            b.daty is int ? DateTime.fromMillisecondsSinceEpoch((b.daty as int) * 1000) : b.daty as DateTime;

        return dateB.compareTo(dateA); // Plus récent en premier
      });

      // Calculer les stocks cumulés par article/dépôt pour chaque unité
      Map<String, Map<String, double>> stocksParArticle = {};
      List<Map<String, dynamic>> mouvementsAvecStock = [];

      // Obtenir les articles et stocks initiaux
      final articles = await _databaseService.database.getAllArticles();
      final stocksDepart = await _databaseService.database.select(_databaseService.database.depart).get();

      // Initialiser les stocks par dépôt et par unité
      for (var stockDepart in stocksDepart) {
        String cle = '${stockDepart.designation}_${stockDepart.depots}';
        stocksParArticle[cle] = {
          'u1': stockDepart.stocksu1 ?? 0,
          'u2': stockDepart.stocksu2 ?? 0,
          'u3': stockDepart.stocksu3 ?? 0,
        };
      }

      // Traiter les mouvements en ordre chronologique inverse pour calculer les variations
      for (var mouvement in filteredStocks.reversed) {
        String cle = '${mouvement.refart}_${mouvement.depots}';
        Map<String, double> stocksActuels = stocksParArticle[cle] ?? {'u1': 0, 'u2': 0, 'u3': 0};

        double qe = mouvement.qe ?? 0.0;
        double qs = mouvement.qs ?? 0.0;
        double variation = qe - qs;

        // Déterminer quelle unité est affectée par le mouvement
        String unite = mouvement.ue ?? mouvement.us ?? 'u1';
        String uniteKey = 'u1'; // Par défaut
        
        // Trouver l'article pour déterminer l'unité correcte
        final article = articles.firstWhere(
          (a) => a.designation == mouvement.refart,
          orElse: () => Article(designation: mouvement.refart ?? ''),
        );
        
        if (unite == article.u2) {
          uniteKey = 'u2';
        } else if (unite == article.u3) {
          uniteKey = 'u3';
        }

        // Calculer le stock avant mouvement pour cette unité
        double stockActuelUnite = stocksActuels[uniteKey] ?? 0;
        double stockAvantMouvement = stockActuelUnite - variation;
        
        // Mettre à jour le stock pour cette unité
        stocksActuels[uniteKey] = stockAvantMouvement;
        stocksParArticle[cle] = stocksActuels;

        mouvementsAvecStock.insert(0, {
          'mouvement': mouvement,
          'article': article,
          'stocksApres': Map<String, double>.from(stocksActuels),
          'variation': variation,
        });
      }

      setState(() {
        mouvements = filteredStocks;
        _mouvementsAvecStock = mouvementsAvecStock;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e'), backgroundColor: Colors.red),
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
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[100],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Variation des stocks',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Période: '),
                        DropdownButton<String>(
                          value: _selectedPeriod,
                          items: const [
                            DropdownMenuItem(value: 'Aujourd\'hui', child: Text('Aujourd\'hui')),
                            DropdownMenuItem(value: 'Hier', child: Text('Hier')),
                            DropdownMenuItem(value: 'Cette semaine', child: Text('Cette semaine')),
                            DropdownMenuItem(value: 'Semaine dernière', child: Text('Semaine dernière')),
                            DropdownMenuItem(value: 'Ce mois', child: Text('Ce mois')),
                            DropdownMenuItem(value: 'Plage de dates', child: Text('Plage de dates')),
                            DropdownMenuItem(value: 'Tout', child: Text('Tout')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriod = value ?? 'Aujourd\'hui';
                              if (value != 'Plage de dates') {
                                _dateDebut = null;
                                _dateFin = null;
                              }
                              _isLoading = true;
                            });
                            if (value == 'Plage de dates') {
                              _selectDateRange();
                            } else {
                              _loadMouvements();
                            }
                          },
                        ),
                      ],
                    ),
                    if (_selectedPeriod == 'Plage de dates') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dateDebut != null && _dateFin != null
                                          ? '${AppDateUtils.formatDate(_dateDebut!)} - ${AppDateUtils.formatDate(_dateFin!)}'
                                          : 'Sélectionner les dates',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                      child: Center(
                                          child: Text('Date',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                  Expanded(
                                      flex: 2,
                                      child: Center(
                                          child: Text('Article',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Dépôt',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Type',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Entrées',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Sorties',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Variation',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                  Expanded(
                                      child: Center(
                                          child: Text('Stock Après',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _mouvementsAvecStock.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inbox, size: 48, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Aucun mouvement de stock pour cette période'),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _mouvementsAvecStock.length,
                                      itemBuilder: (context, index) {
                                        final item = _mouvementsAvecStock[index];
                                        final mouvement = item['mouvement'] as Stock;
                                        final article = item['article'] as Article;
                                        final stocksApres = item['stocksApres'] as Map<String, double>;
                                        final variation = item['variation'] as double;

                                        DateTime? date;
                                        if (mouvement.daty != null) {
                                          date = mouvement.daty is int
                                              ? DateTime.fromMillisecondsSinceEpoch(
                                                  (mouvement.daty as int) * 1000)
                                              : mouvement.daty as DateTime;
                                        }

                                        Color variationColor = Colors.grey;
                                        if (variation > 0) variationColor = Colors.green;
                                        if (variation < 0) variationColor = Colors.red;

                                        return Container(
                                          height: 35,
                                          decoration: BoxDecoration(
                                            color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                            border: const Border(
                                                bottom: BorderSide(color: Colors.grey, width: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    date != null ? AppDateUtils.formatDate(date) : 'N/A',
                                                    style: const TextStyle(fontSize: 10),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: Text(
                                                    mouvement.refart ?? 'N/A',
                                                    style: const TextStyle(fontSize: 10),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    mouvement.depots ?? 'N/A',
                                                    style: const TextStyle(fontSize: 10),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: _getTypeColor(mouvement.verification)
                                                          .withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                          color: _getTypeColor(mouvement.verification),
                                                          width: 0.5),
                                                    ),
                                                    child: Text(
                                                      mouvement.verification ?? 'N/A',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: _getTypeColor(mouvement.verification),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    (mouvement.qe ?? 0) > 0
                                                        ? '+${AppFunctions.formatNumber(mouvement.qe ?? 0)} ${mouvement.ue ?? ''}'
                                                        : '',
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    (mouvement.qs ?? 0) > 0
                                                        ? '-${AppFunctions.formatNumber(mouvement.qs ?? 0)} ${mouvement.us ?? ''}'
                                                        : '',
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    variation != 0
                                                        ? '${variation > 0 ? '+' : ''}${AppFunctions.formatNumber(variation)} ${mouvement.ue ?? mouvement.us ?? ''}'
                                                        : '0',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: variationColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    _buildStockDisplay(article, stocksApres),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: _hasNegativeStock(stocksApres) ? Colors.red : Colors.black,
                                                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _dateDebut != null && _dateFin != null ? DateTimeRange(start: _dateDebut!, end: _dateFin!) : null,
    );

    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = picked.end;
      });
      _loadMouvements();
    }
  }

  String _buildStockDisplay(Article article, Map<String, double> stocks) {
    List<String> stockParts = [];
    
    // Afficher les stocks pour chaque unité disponible
    if (article.u1 != null && article.u1!.isNotEmpty) {
      stockParts.add('${AppFunctions.formatNumber(stocks['u1'] ?? 0)} ${article.u1}');
    }
    if (article.u2 != null && article.u2!.isNotEmpty) {
      stockParts.add('${AppFunctions.formatNumber(stocks['u2'] ?? 0)} ${article.u2}');
    }
    if (article.u3 != null && article.u3!.isNotEmpty) {
      stockParts.add('${AppFunctions.formatNumber(stocks['u3'] ?? 0)} ${article.u3}');
    }
    
    if (stockParts.isEmpty) {
      double total = (stocks['u1'] ?? 0) + (stocks['u2'] ?? 0) + (stocks['u3'] ?? 0);
      return AppFunctions.formatNumber(total);
    }
    
    return stockParts.join(' / ');
  }

  bool _hasNegativeStock(Map<String, double> stocks) {
    return (stocks['u1'] ?? 0) < 0 || (stocks['u2'] ?? 0) < 0 || (stocks['u3'] ?? 0) < 0;
  }

  Color _getTypeColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'ACHAT':
      case 'INVENTAIRE':
        return Colors.green;
      case 'VENTE':
      case 'CP VENTE':
        return Colors.red;
      case 'TRANSFERT':
        return Colors.blue;
      case 'AJUSTEMENT':
        return Colors.orange;
      case 'CP ACHAT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
