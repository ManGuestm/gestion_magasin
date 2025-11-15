import '../database/database.dart';

/// Utilitaire pour la conversion automatique des stocks entre unités
/// Gère la conversion automatique des excédents vers les unités supérieures
class StockConverter {
  /// Convertit automatiquement les stocks en optimisant l'affichage
  /// Exemple: 230 Grs = 4 Ctn + 30 Grs (si 1 Ctn = 50 Grs)
  /// Exemple: 33 Pqt = 16 Ctn + 1 Pqt (si 1 Ctn = 2 Pqt)
  static Map<String, double> convertirStockOptimal({
    required Article article,
    required double quantiteU1,
    required double quantiteU2,
    required double quantiteU3,
  }) {
    double u1 = quantiteU1;
    double u2 = quantiteU2;
    double u3 = quantiteU3;

    // Conversion u3 vers u2 si possible (Pcs vers Grs)
    if (article.tu3u2 != null && article.tu3u2! > 0 && u3 >= article.tu3u2!) {
      double conversionU2 = (u3 / article.tu3u2!).floor().toDouble();
      u2 += conversionU2;
      u3 = u3 % article.tu3u2!;
    }

    // Conversion u2 vers u1 si possible (Grs vers Ctn ou Pqt vers Ctn)
    // MAIS seulement si on a assez d'unités pour une conversion complète
    if (article.tu2u1 != null && article.tu2u1! > 0 && u2 >= article.tu2u1!) {
      double conversionU1 = (u2 / article.tu2u1!).floor().toDouble();
      u1 += conversionU1;
      u2 = u2 % article.tu2u1!;
    }

    return {
      'u1': u1,
      'u2': u2,
      'u3': u3,
    };
  }

  /// Convertit une quantité d'achat vers les unités optimales
  /// Exemple: Achat de 230 Grs → 4 Ctn + 30 Grs
  /// Exemple: Achat de 33 Pqt → 16 Ctn + 1 Pqt
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
  /// Retourne: "52 Ctn / 31 Grs / 3 Pcs" ou "28 Ctn / 1 Pqt"
  static String formaterAffichageStock({
    required Article article,
    required double stockU1,
    required double stockU2,
    required double stockU3,
  }) {
    List<String> parts = [];
    
    // Ajouter U1 si défini et non nul
    if (article.u1?.isNotEmpty == true) {
      parts.add('${stockU1.toInt()} ${article.u1}');
    }
    
    // Ajouter U2 si défini et non nul
    if (article.u2?.isNotEmpty == true) {
      parts.add('${stockU2.toInt()} ${article.u2}');
    }
    
    // Ajouter U3 si défini et non nul
    if (article.u3?.isNotEmpty == true) {
      parts.add('${stockU3.toInt()} ${article.u3}');
    }
    
    return parts.isEmpty ? '0' : parts.join(' / ');
  }

  /// Calcule le stock total en unité de base (u3 ou u2 selon l'article)
  /// Exemple: 48 Ctn + 0 Grs + 0 Pcs = 48*50*10 + 0*10 + 0 = 24000 Pcs
  /// Exemple: 22 Ctn + 0 Pqt = 22*2 + 0 = 44 Pqt (pour articles à 2 unités)
  static double calculerStockTotalU3({
    required Article article,
    required double stockU1,
    required double stockU2,
    required double stockU3,
  }) {
    // Pour les articles à 3 unités (u1, u2, u3)
    if (article.u3?.isNotEmpty == true && article.tu3u2 != null && article.tu2u1 != null) {
      double totalU3 = stockU3;
      totalU3 += stockU2 * article.tu3u2!;
      totalU3 += stockU1 * article.tu2u1! * article.tu3u2!;
      return totalU3;
    }
    
    // Pour les articles à 2 unités (u1, u2) comme Gauffrette
    if (article.u2?.isNotEmpty == true && article.tu2u1 != null) {
      return stockU1 * article.tu2u1! + stockU2;
    }
    
    // Pour les articles à 1 unité
    return stockU1;
  }

  /// Vérifie si un stock est suffisant pour une vente
  /// Compare le stock total converti avec la quantité demandée
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
  /// Utilise la logique de conversion automatique pour déduire intelligemment
  static Map<String, double> decomposerVentePourDeduction({
    required Article article,
    required double stockU1,
    required double stockU2,
    required double stockU3,
    required String uniteVente,
    required double quantiteVente,
  }) {
    // Vérifier d'abord si le stock est suffisant
    if (!verifierStockSuffisant(
      article: article,
      stockU1: stockU1,
      stockU2: stockU2,
      stockU3: stockU3,
      uniteVente: uniteVente,
      quantiteVente: quantiteVente,
    )) {
      throw Exception('Stock insuffisant');
    }

    // Convertir la quantité vendue vers les unités de stock optimales
    final venteConvertie = convertirQuantiteAchat(
      article: article,
      uniteAchat: uniteVente,
      quantiteAchat: quantiteVente,
    );

    return {
      'u1': venteConvertie['u1']!,
      'u2': venteConvertie['u2']!,
      'u3': venteConvertie['u3']!,
    };
  }
}