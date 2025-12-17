import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';

class StockSyncService {
  static final StockSyncService _instance = StockSyncService._internal();
  factory StockSyncService() => _instance;
  StockSyncService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Synchronise tous les stocks globaux à partir des stocks par dépôt
  Future<void> synchroniserTousLesStocks() async {
    try {
      // Récupérer tous les articles
      final articles = await _databaseService.database.getAllArticles();
      
      for (final article in articles) {
        await synchroniserStockArticle(article.designation);
      }
    } catch (e) {
      throw Exception('Erreur lors de la synchronisation des stocks: $e');
    }
  }

  /// Synchronise le stock global d'un article spécifique
  Future<void> synchroniserStockArticle(String designation) async {
    try {
      // Récupérer tous les stocks par dépôt pour cet article
      final stocksDepots = await (_databaseService.database.select(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(designation))).get();
      
      // Calculer les totaux
      double totalU1 = 0;
      double totalU2 = 0;
      double totalU3 = 0;
      
      for (final stock in stocksDepots) {
        totalU1 += stock.stocksu1 ?? 0;
        totalU2 += stock.stocksu2 ?? 0;
        totalU3 += stock.stocksu3 ?? 0;
      }
      
      // Mettre à jour l'article avec les totaux calculés
      await (_databaseService.database.update(
        _databaseService.database.articles,
      )..where((a) => a.designation.equals(designation))).write(
        ArticlesCompanion(
          stocksu1: Value(totalU1),
          stocksu2: Value(totalU2),
          stocksu3: Value(totalU3),
        ),
      );
    } catch (e) {
      throw Exception('Erreur lors de la synchronisation du stock pour $designation: $e');
    }
  }

  /// Vérifie la cohérence entre les stocks globaux et par dépôt
  Future<List<Map<String, dynamic>>> verifierCoherenceStocks() async {
    final incoherences = <Map<String, dynamic>>[];
    
    try {
      // Récupérer tous les articles
      final articles = await _databaseService.database.getAllArticles();
      
      for (final article in articles) {
        // Calculer le total des stocks par dépôt
        final stocksDepots = await (_databaseService.database.select(
          _databaseService.database.depart,
        )..where((d) => d.designation.equals(article.designation))).get();
        
        double totalDepotsU1 = 0;
        double totalDepotsU2 = 0;
        double totalDepotsU3 = 0;
        
        for (final stock in stocksDepots) {
          totalDepotsU1 += stock.stocksu1 ?? 0;
          totalDepotsU2 += stock.stocksu2 ?? 0;
          totalDepotsU3 += stock.stocksu3 ?? 0;
        }
        
        // Comparer avec les stocks globaux
        final stockGlobalU1 = article.stocksu1 ?? 0;
        final stockGlobalU2 = article.stocksu2 ?? 0;
        final stockGlobalU3 = article.stocksu3 ?? 0;
        
        if (totalDepotsU1 != stockGlobalU1 || 
            totalDepotsU2 != stockGlobalU2 || 
            totalDepotsU3 != stockGlobalU3) {
          incoherences.add({
            'designation': article.designation,
            'stockGlobal': {
              'u1': stockGlobalU1,
              'u2': stockGlobalU2,
              'u3': stockGlobalU3,
            },
            'totalDepots': {
              'u1': totalDepotsU1,
              'u2': totalDepotsU2,
              'u3': totalDepotsU3,
            },
            'difference': {
              'u1': totalDepotsU1 - stockGlobalU1,
              'u2': totalDepotsU2 - stockGlobalU2,
              'u3': totalDepotsU3 - stockGlobalU3,
            },
          });
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la vérification de cohérence: $e');
    }
    
    return incoherences;
  }

  /// Corrige automatiquement les incohérences détectées
  Future<int> corrigerIncoherences() async {
    final incoherences = await verifierCoherenceStocks();
    
    for (final incoherence in incoherences) {
      final designation = incoherence['designation'] as String;
      await synchroniserStockArticle(designation);
    }
    
    return incoherences.length;
  }
}