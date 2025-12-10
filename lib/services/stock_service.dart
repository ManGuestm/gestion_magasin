import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';
import '../utils/stock_converter.dart';

/// Service spécialisé pour la gestion des stocks
class StockService {
  final DatabaseService _databaseService = DatabaseService();

  /// Vérifie la disponibilité d'un article dans tous les dépôts
  Future<Map<String, Map<String, double>>> verifierDisponibiliteArticle(String designation) async {
    return await _databaseService.database.getStockDetailleArticle(designation);
  }

  /// Calcule le stock total d'un article en unité de base
  Future<double> calculerStockTotalArticle(Article article) async {
    final stocksDepots = await verifierDisponibiliteArticle(article.designation);

    double totalU3 = 0;

    for (var stockDepot in stocksDepots.values) {
      totalU3 += StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockDepot['u1'] ?? 0,
        stockU2: stockDepot['u2'] ?? 0,
        stockU3: stockDepot['u3'] ?? 0,
      );
    }

    return totalU3;
  }

  /// Suggère la meilleure répartition de stock pour une vente
  Future<List<Map<String, dynamic>>> suggererRepartitionVente(
    Article article,
    String uniteVente,
    double quantiteVente,
  ) async {
    final stocksDepots = await verifierDisponibiliteArticle(article.designation);
    List<Map<String, dynamic>> suggestions = [];

    double quantiteRestante = quantiteVente;

    for (var entry in stocksDepots.entries) {
      String depot = entry.key;
      Map<String, double> stocks = entry.value;

      // Vérifier si le stock est suffisant pour cette vente
      bool stockSuffisant = StockConverter.verifierStockSuffisant(
        article: article,
        stockU1: stocks['u1'] ?? 0,
        stockU2: stocks['u2'] ?? 0,
        stockU3: stocks['u3'] ?? 0,
        uniteVente: uniteVente,
        quantiteVente: quantiteRestante,
      );

      if (stockSuffisant && quantiteRestante > 0) {
        double quantiteAPrendre = quantiteRestante;

        // Calculer le stock total disponible en unité de vente
        double stockTotalU3 = StockConverter.calculerStockTotalU3(
          article: article,
          stockU1: stocks['u1'] ?? 0,
          stockU2: stocks['u2'] ?? 0,
          stockU3: stocks['u3'] ?? 0,
        );

        // Convertir en unité de vente pour affichage
        double stockDisponibleUniteVente = stockTotalU3;
        if (uniteVente == article.u2 && article.tu3u2 != null) {
          stockDisponibleUniteVente = stockTotalU3 / article.tu3u2!;
        } else if (uniteVente == article.u1 && article.tu2u1 != null && article.tu3u2 != null) {
          stockDisponibleUniteVente = stockTotalU3 / (article.tu2u1! * article.tu3u2!);
        }

        if (quantiteAPrendre > stockDisponibleUniteVente) {
          quantiteAPrendre = stockDisponibleUniteVente;
        }

        suggestions.add({
          'depot': depot,
          'quantite': quantiteAPrendre,
          'unite': uniteVente,
          'stockDisponible': stockDisponibleUniteVente,
          'affichageStock': StockConverter.formaterAffichageStock(
            article: article,
            stockU1: stocks['u1'] ?? 0,
            stockU2: stocks['u2'] ?? 0,
            stockU3: stocks['u3'] ?? 0,
          ),
        });

        quantiteRestante -= quantiteAPrendre;
      }
    }

    return suggestions;
  }

  /// Initialise les stocks d'un nouvel article dans tous les dépôts
  Future<void> initialiserStocksNouvelArticle(Article article) async {
    final depots = await _databaseService.database.getAllDepots();

    for (var depot in depots) {
      await _databaseService.database.initialiserStockArticleDepot(
        article.designation,
        depot.depots,
        stockU1: 0,
        stockU2: 0,
        stockU3: 0,
      );
    }
  }

  /// Effectue un transfert de stock entre dépôts
  Future<void> transfererStock({
    required String designation,
    required String depotSource,
    required String depotDestination,
    required String unite,
    required double quantite,
  }) async {
    await _databaseService.database.transaction(() async {
      // Déduire du dépôt source
      final stockSource = await (_databaseService.database.select(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(designation) & d.depots.equals(depotSource))).getSingleOrNull();

      if (stockSource != null) {
        Map<String, double> nouveauxStocksSource = {
          'u1': stockSource.stocksu1 ?? 0,
          'u2': stockSource.stocksu2 ?? 0,
          'u3': stockSource.stocksu3 ?? 0,
        };

        // Déduire selon l'unité
        final article = await _databaseService.database.getArticleByDesignation(designation);
        if (article != null) {
          if (unite == article.u1) {
            nouveauxStocksSource['u1'] = (nouveauxStocksSource['u1']!) - quantite;
          } else if (unite == article.u2) {
            nouveauxStocksSource['u2'] = (nouveauxStocksSource['u2']!) - quantite;
          } else if (unite == article.u3) {
            nouveauxStocksSource['u3'] = (nouveauxStocksSource['u3']!) - quantite;
          }
        }

        await (_databaseService.database.update(
          _databaseService.database.depart,
        )..where((d) => d.designation.equals(designation) & d.depots.equals(depotSource))).write(
          DepartCompanion(
            stocksu1: Value(nouveauxStocksSource['u1']!),
            stocksu2: Value(nouveauxStocksSource['u2']!),
            stocksu3: Value(nouveauxStocksSource['u3']!),
          ),
        );
      }

      // Ajouter au dépôt destination
      final stockDestination =
          await (_databaseService.database.select(_databaseService.database.depart)
                ..where((d) => d.designation.equals(designation) & d.depots.equals(depotDestination)))
              .getSingleOrNull();

      if (stockDestination != null) {
        Map<String, double> nouveauxStocksDestination = {
          'u1': stockDestination.stocksu1 ?? 0,
          'u2': stockDestination.stocksu2 ?? 0,
          'u3': stockDestination.stocksu3 ?? 0,
        };

        // Ajouter selon l'unité
        final article = await _databaseService.database.getArticleByDesignation(designation);
        if (article != null) {
          if (unite == article.u1) {
            nouveauxStocksDestination['u1'] = (nouveauxStocksDestination['u1']!) + quantite;
          } else if (unite == article.u2) {
            nouveauxStocksDestination['u2'] = (nouveauxStocksDestination['u2']!) + quantite;
          } else if (unite == article.u3) {
            nouveauxStocksDestination['u3'] = (nouveauxStocksDestination['u3']!) + quantite;
          }
        }

        await (_databaseService.database.update(
          _databaseService.database.depart,
        )..where((d) => d.designation.equals(designation) & d.depots.equals(depotDestination))).write(
          DepartCompanion(
            stocksu1: Value(nouveauxStocksDestination['u1']!),
            stocksu2: Value(nouveauxStocksDestination['u2']!),
            stocksu3: Value(nouveauxStocksDestination['u3']!),
          ),
        );
      } else {
        // Créer l'entrée si elle n'existe pas
        Map<String, double> stocksInitiaux = {'u1': 0, 'u2': 0, 'u3': 0};

        final article = await _databaseService.database.getArticleByDesignation(designation);
        if (article != null) {
          if (unite == article.u1) {
            stocksInitiaux['u1'] = quantite;
          } else if (unite == article.u2) {
            stocksInitiaux['u2'] = quantite;
          } else if (unite == article.u3) {
            stocksInitiaux['u3'] = quantite;
          }
        }

        await _databaseService.database.initialiserStockArticleDepot(
          designation,
          depotDestination,
          stockU1: stocksInitiaux['u1'],
          stockU2: stocksInitiaux['u2'],
          stockU3: stocksInitiaux['u3'],
        );
      }
    });
  }

  /// Génère un rapport de stock critique
  Future<List<Map<String, dynamic>>> genererRapportStockCritique({double seuilCritique = 10}) async {
    final articles = await _databaseService.database.getActiveArticles();
    List<Map<String, dynamic>> articlesCritiques = [];

    for (var article in articles) {
      final stockTotal = await calculerStockTotalArticle(article);

      if (stockTotal <= seuilCritique) {
        final stocksDepots = await verifierDisponibiliteArticle(article.designation);

        articlesCritiques.add({
          'designation': article.designation,
          'stockTotal': stockTotal,
          'unite': article.u3 ?? 'Pce',
          'stocksParDepot': stocksDepots,
          'critique': stockTotal == 0 ? 'RUPTURE' : 'CRITIQUE',
        });
      }
    }

    return articlesCritiques;
  }
}
