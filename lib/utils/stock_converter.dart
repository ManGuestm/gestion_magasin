import '../database/database.dart';

/// Utilitaire pour la conversion automatique des stocks entre unités
/// Gère la conversion automatique des excédents vers les unités supérieures
class StockConverter {
  /// Convertit automatiquement les stocks en optimisant l'affichage
  /// Exemple: 230 Grs = 4 Ctn + 30 Grs (si 1 Ctn = 50 Grs)
  static Map<String, double> convertirStockOptimal({
    required Article article,
    required double quantiteU1,
    required double quantiteU2,
    required double quantiteU3,
  }) {
    double u1 = quantiteU1;
    double u2 = quantiteU2;
    double u3 = quantiteU3;

    // Conversion u3 vers u2 si possible
    if (article.tu3u2 != null && article.tu3u2! > 0) {
      double excedentU3 = u3;
      double conversionU2 = (excedentU3 / article.tu3u2!).floor().toDouble();
      
      if (conversionU2 > 0) {
        u2 += conversionU2;
        u3 = excedentU3 % article.tu3u2!;
      }
    }

    // Conversion u2 vers u1 si possible
    if (article.tu2u1 != null && article.tu2u1! > 0) {
      double excedentU2 = u2;
      double conversionU1 = (excedentU2 / article.tu2u1!).floor().toDouble();
      
      if (conversionU1 > 0) {
        u1 += conversionU1;
        u2 = excedentU2 % article.tu2u1!;
      }
    }

    return {
      'u1': u1,
      'u2': u2,
      'u3': u3,
    };
  }

  /// Convertit une quantité d'achat vers les unités optimales
  /// Exemple: Achat de 230 Grs → 4 Ctn + 30 Grs
  static Map<String, double> convertirQuantiteAchat({
    required Article article,
    required String uniteAchat,
    required double quantiteAchat,
  }) {
    double u1 = 0, u2 = 0, u3 = 0;

    // Placer la quantité dans l'unité correspondante
    if (uniteAchat == article.u1) {
      u1 = quantiteAchat;
    } else if (uniteAchat == article.u2) {
      u2 = quantiteAchat;
    } else if (uniteAchat == article.u3) {
      u3 = quantiteAchat;
    }

    // Appliquer la conversion optimale
    return convertirStockOptimal(
      article: article,
      quantiteU1: u1,
      quantiteU2: u2,
      quantiteU3: u3,
    );
  }

  /// Formate l'affichage du stock selon l'exemple
  /// Retourne: "52 Ctn / 31 Grs / 3 Pcs"
  static String formaterAffichageStock({
    required Article article,
    required double stockU1,
    required double stockU2,
    required double stockU3,
  }) {
    final stockOptimal = convertirStockOptimal(
      article: article,
      quantiteU1: stockU1,
      quantiteU2: stockU2,
      quantiteU3: stockU3,
    );

    String u1Label = article.u1 ?? 'U1';
    String u2Label = article.u2 ?? 'U2';
    String u3Label = article.u3 ?? 'U3';

    return '${stockOptimal['u1']!.toInt()} $u1Label / ${stockOptimal['u2']!.toInt()} $u2Label / ${stockOptimal['u3']!.toInt()} $u3Label';
  }

  /// Calcule le stock total en unité de base (u3)
  static double calculerStockTotalU3({
    required Article article,
    required double stockU1,
    required double stockU2,
    required double stockU3,
  }) {
    double totalU3 = stockU3;

    // Convertir u2 vers u3
    if (article.tu3u2 != null && article.tu3u2! > 0) {
      totalU3 += stockU2 * article.tu3u2!;
    }

    // Convertir u1 vers u3
    if (article.tu2u1 != null && article.tu3u2 != null && 
        article.tu2u1! > 0 && article.tu3u2! > 0) {
      totalU3 += stockU1 * article.tu2u1! * article.tu3u2!;
    }

    return totalU3;
  }

  /// Vérifie si un stock est suffisant pour une vente
  static bool verifierStockSuffisant({
    required Article article,
    required double stockU1,
    required double stockU2,
    required double stockU3,
    required String uniteVente,
    required double quantiteVente,
  }) {
    double stockTotalU3 = calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    // Convertir la quantité de vente en u3
    double quantiteVenteU3 = 0;
    
    if (uniteVente == article.u3) {
      quantiteVenteU3 = quantiteVente;
    } else if (uniteVente == article.u2) {
      quantiteVenteU3 = quantiteVente * (article.tu3u2 ?? 1);
    } else if (uniteVente == article.u1) {
      quantiteVenteU3 = quantiteVente * (article.tu2u1 ?? 1) * (article.tu3u2 ?? 1);
    }

    return stockTotalU3 >= quantiteVenteU3;
  }

  /// Décompose une vente en unités optimales pour déduction du stock
  /// Retourne les quantités à déduire de chaque unité
  static Map<String, double> decomposerVentePourDeduction({
    required Article article,
    required double stockU1,
    required double stockU2,
    required double stockU3,
    required String uniteVente,
    required double quantiteVente,
  }) {
    // Convertir tout en u3 pour simplifier
    double stockTotalU3 = calculerStockTotalU3(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
    );

    double quantiteVenteU3 = 0;
    if (uniteVente == article.u3) {
      quantiteVenteU3 = quantiteVente;
    } else if (uniteVente == article.u2) {
      quantiteVenteU3 = quantiteVente * (article.tu3u2 ?? 1);
    } else if (uniteVente == article.u1) {
      quantiteVenteU3 = quantiteVente * (article.tu2u1 ?? 1) * (article.tu3u2 ?? 1);
    }

    if (quantiteVenteU3 > stockTotalU3) {
      throw Exception('Stock insuffisant');
    }

    // Déduire en priorité des unités les plus petites
    double resteADeduire = quantiteVenteU3;
    double deductionU1 = 0, deductionU2 = 0, deductionU3 = 0;

    // 1. Déduire d'abord de u3
    if (resteADeduire > 0 && stockU3 > 0) {
      double deduction = resteADeduire > stockU3 ? stockU3 : resteADeduire;
      deductionU3 = deduction;
      resteADeduire -= deduction;
    }

    // 2. Déduire de u2 si nécessaire
    if (resteADeduire > 0 && stockU2 > 0 && article.tu3u2 != null) {
      double deductionU2Possible = stockU2 * article.tu3u2!;
      double deduction = resteADeduire > deductionU2Possible ? deductionU2Possible : resteADeduire;
      deductionU2 = deduction / article.tu3u2!;
      resteADeduire -= deduction;
    }

    // 3. Déduire de u1 si nécessaire
    if (resteADeduire > 0 && stockU1 > 0 && 
        article.tu2u1 != null && article.tu3u2 != null) {
      double facteurConversion = article.tu2u1! * article.tu3u2!;
      double deductionU1Possible = stockU1 * facteurConversion;
      double deduction = resteADeduire > deductionU1Possible ? deductionU1Possible : resteADeduire;
      deductionU1 = deduction / facteurConversion;
      resteADeduire -= deduction;
    }

    return {
      'u1': deductionU1,
      'u2': deductionU2,
      'u3': deductionU3,
    };
  }
}