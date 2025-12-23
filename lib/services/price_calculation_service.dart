import '../database/database.dart';

/// Service dédié aux calculs de prix et montants
class PriceCalculationService {
  double calculateLineAmount(double quantite, double prix) =>
      (quantite > 0 && prix > 0) ? quantite * prix : 0.0;

  double calculateTotalHT(List<Map<String, dynamic>> lignesVente) {
    return lignesVente.fold<double>(0.0, (sum, ligne) {
      final quantite = ligne['quantite'] as double? ?? 0.0;
      final prixUnitaire = ligne['prixUnitaire'] as double? ?? 0.0;
      return sum + (quantite * prixUnitaire);
    });
  }

  double calculateRemiseAmount(double totalHT, double remisePercentage) =>
      (totalHT > 0 && remisePercentage >= 0) ? (totalHT * remisePercentage) / 100 : 0.0;

  double calculateTotalTTC(double totalHT, double remisePercentage) =>
      totalHT - calculateRemiseAmount(totalHT, remisePercentage);

  double calculateReste(double totalTTC, double avance) => totalTTC - avance;

  double calculateNewClientBalance(double soldeAnterieur, double totalTTC, String modePaiement) =>
      modePaiement == 'A crédit' ? soldeAnterieur + totalTTC : soldeAnterieur;

  double calculatePriceDifference(double prixVente, double prixStandard) => prixVente - prixStandard;

  double calculateTotalPriceDifference(List<Map<String, dynamic>> lignesVente) {
    return lignesVente.fold<double>(0.0, (sum, ligne) {
      final diffPrix = ligne['diffPrix'] as double? ?? 0.0;
      return sum + diffPrix;
    });
  }

  double getPriceForUnit(Article article, String unite) {
    if (unite == article.u1) return article.pvu1 ?? 0.0;
    if (unite == article.u2) return article.pvu2 ?? 0.0;
    if (unite == article.u3) return article.pvu3 ?? 0.0;
    return 0.0;
  }

  double getPurchasePriceForUnit(Article article, String unite) {
    double cmup = article.cmup ?? 0.0;
    if (cmup == 0.0) return 0.0;
    if (unite == article.u1 && article.tu2u1 != null && article.tu3u2 != null) {
      return cmup * (article.tu2u1! * article.tu3u2!);
    } else if (unite == article.u2 && article.tu3u2 != null) {
      return cmup * article.tu3u2!;
    }
    return cmup;
  }

  bool isPriceAcceptable(double priceVente, double prixAchat, {double minMarginPercent = 0.0}) {
    if (priceVente == 0) return false;
    if (minMarginPercent <= 0) return priceVente > 0;
    return priceVente >= prixAchat * (1 + (minMarginPercent / 100));
  }
}
