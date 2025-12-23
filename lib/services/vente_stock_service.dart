import 'package:drift/drift.dart' as drift;
import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/stock_converter.dart';

/// Service pour la gestion du stock dans les ventes
class VenteStockService {
  final DatabaseService _databaseService = DatabaseService();

  /// Vérifie le stock disponible pour un article
  Future<Map<String, dynamic>> verifierStock({
    required Article article,
    required String depot,
    required String unite,
  }) async {
    try {
      final stockDepart = await (_databaseService.database.select(
        _databaseService.database.depart,
      )..where((d) => d.designation.equals(article.designation) & d.depots.equals(depot)))
          .getSingleOrNull();

      final stockTotalU3 = StockConverter.calculerStockTotalU3(
        article: article,
        stockU1: stockDepart?.stocksu1 ?? 0.0,
        stockU2: stockDepart?.stocksu2 ?? 0.0,
        stockU3: stockDepart?.stocksu3 ?? 0.0,
      );

      final stockPourUnite = _calculerStockPourUnite(article, unite, stockTotalU3);

      return {
        'stockDisponible': stockPourUnite,
        'stockInsuffisant': stockTotalU3 <= 0,
        'stockTotalU3': stockTotalU3,
      };
    } catch (e) {
      return {
        'stockDisponible': 0.0,
        'stockInsuffisant': true,
        'stockTotalU3': 0.0,
      };
    }
  }

  /// Calcule le stock pour une unité donnée
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

  /// Obtient le prix d'achat (CMUP) pour une unité
  Future<double> getPrixAchatPourUnite(Article article, String unite) async {
    double cmup = article.cmup ?? 0.0;
    if (cmup == 0.0) return 0.0;

    if (unite == article.u1 && article.tu2u1 != null && article.tu3u2 != null) {
      return cmup * (article.tu2u1! * article.tu3u2!);
    } else if (unite == article.u2 && article.tu3u2 != null) {
      return cmup * article.tu3u2!;
    } else if (unite == article.u3) {
      return cmup;
    }
    return cmup;
  }

  /// Obtient le prix de vente standard pour une unité
  Future<double> getPrixVenteStandard(Article article, String unite) async {
    if (unite == article.u1) {
      return article.pvu1 ?? 0.0;
    } else if (unite == article.u2) {
      return article.pvu2 ?? 0.0;
    } else if (unite == article.u3) {
      return article.pvu3 ?? 0.0;
    }
    return 0.0;
  }

  /// Formate l'affichage des unités
  String formaterUniteAffichage(Article article) {
    final unites = <String>[];
    if (article.u1?.isNotEmpty == true) unites.add(article.u1!);
    if (article.u2?.isNotEmpty == true) unites.add(article.u2!);
    if (article.u3?.isNotEmpty == true) unites.add(article.u3!);
    return unites.join(' / ');
  }

  /// Vérifie si une unité est valide pour un article
  bool isUniteValide(Article article, String unite) {
    final unitesValides = [
      article.u1,
      article.u2,
      article.u3,
    ].where((u) => u != null && u.isNotEmpty).toList();

    return unitesValides.contains(unite.trim());
  }
}
