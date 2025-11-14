import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/database_service.dart';

class CMUPCalculator {
  static final DatabaseService _db = DatabaseService();

  /// Calcule et met à jour le CMUP d'un article après un achat
  /// Le CMUP est toujours calculé en unité de base (u3)
  static Future<double> calculerEtMettreAJourCMUP({
    required String designation,
    required String uniteAchat,
    required double quantiteAchat,
    required double prixUnitaireAchat,
    required Article article,
  }) async {
    // 1. Convertir la quantité achetée en unité de base (u3)
    double quantiteEnU3 = _convertirVersU3(
      quantite: quantiteAchat,
      uniteSource: uniteAchat,
      article: article,
    );

    // 2. Convertir le prix unitaire d'achat en prix pour u3
    double prixU3 = _convertirPrixVersU3(
      prixUnitaire: prixUnitaireAchat,
      uniteSource: uniteAchat,
      article: article,
    );

    // 3. Récupérer le stock actuel en u3
    double stockActuelU3 = article.stocksu3 ?? 0.0;
    double cmupActuel = article.cmup ?? 0.0;

    // 4. Calculer le nouveau CMUP
    double valeurStockActuel = stockActuelU3 * cmupActuel;
    double valeurNouvelAchat = quantiteEnU3 * prixU3;
    double nouveauStockU3 = stockActuelU3 + quantiteEnU3;

    double nouveauCMUP = 0.0;
    if (nouveauStockU3 > 0) {
      nouveauCMUP = (valeurStockActuel + valeurNouvelAchat) / nouveauStockU3;
    }

    // 5. Mettre à jour le CMUP dans la base de données
    await _db.database.customUpdate(
      'UPDATE articles SET cmup = ? WHERE designation = ?',
      variables: [Variable.withReal(nouveauCMUP), Variable.withString(designation)],
    );

    return nouveauCMUP;
  }

  /// Convertit une quantité vers l'unité de base (u3)
  static double _convertirVersU3({
    required double quantite,
    required String uniteSource,
    required Article article,
  }) {
    if (uniteSource == article.u3) {
      return quantite; // Déjà en u3
    } else if (uniteSource == article.u2) {
      // u2 vers u3 : diviser par tu3u2
      return quantite / (article.tu3u2 ?? 1.0);
    } else if (uniteSource == article.u1) {
      // u1 vers u3 : diviser par (tu2u1 × tu3u2)
      double tu2u1 = article.tu2u1 ?? 1.0;
      double tu3u2 = article.tu3u2 ?? 1.0;
      return quantite / (tu2u1 * tu3u2);
    }
    return quantite; // Par défaut
  }

  /// Convertit un prix unitaire vers le prix pour u3
  static double _convertirPrixVersU3({
    required double prixUnitaire,
    required String uniteSource,
    required Article article,
  }) {
    if (uniteSource == article.u3) {
      return prixUnitaire; // Déjà pour u3
    } else if (uniteSource == article.u2) {
      // Prix u2 vers prix u3 : diviser par tu3u2
      return prixUnitaire / (article.tu3u2 ?? 1.0);
    } else if (uniteSource == article.u1) {
      // Prix u1 vers prix u3 : diviser par (tu2u1 × tu3u2)
      double tu2u1 = article.tu2u1 ?? 1.0;
      double tu3u2 = article.tu3u2 ?? 1.0;
      return prixUnitaire / (tu2u1 * tu3u2);
    }
    return prixUnitaire; // Par défaut
  }

  /// Calcule le prix de vente basé sur le CMUP et l'unité demandée
  static double calculerPrixVente({
    required Article article,
    required String unite,
    double margePercent = 20.0,
  }) {
    double cmup = article.cmup ?? 0.0;
    if (cmup == 0.0) return 0.0;

    // Le CMUP est en u3, convertir vers l'unité demandée
    double prixBase = cmup;

    if (unite == article.u1) {
      // Prix u1 = CMUP × (tu2u1 × tu3u2)
      double tu2u1 = article.tu2u1 ?? 1.0;
      double tu3u2 = article.tu3u2 ?? 1.0;
      prixBase = cmup * tu2u1 * tu3u2;
    } else if (unite == article.u2) {
      // Prix u2 = CMUP × tu3u2
      prixBase = cmup * (article.tu3u2 ?? 1.0);
    }
    // Pour u3 : prix = CMUP directement

    // Appliquer la marge
    return prixBase * (1 + margePercent / 100);
  }
}
