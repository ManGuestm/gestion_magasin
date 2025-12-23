import '../constants/vente_types.dart';
import '../database/database.dart';
import '../database/database_service.dart';

/// Service dédié à la validation des ventes
/// Encapsule toute la logique de validation métier
class VenteValidationService {
  final DatabaseService _databaseService = DatabaseService();

  /// Valide qu'une vente contient au moins une ligne
  bool hasValidLines(List<Map<String, dynamic>> lignesVente) {
    return lignesVente.isNotEmpty;
  }

  /// Valide que le client est sélectionné
  bool isClientSelected(String? clientName) {
    return clientName != null && clientName.isNotEmpty;
  }

  /// Valide que la quantité est positive
  bool isQuantiteValid(double quantite) {
    return quantite > 0;
  }

  /// Valide que le prix est positif
  bool isPrixValid(double prix) {
    return prix > 0;
  }

  /// Valide que le montant reçu ne dépasse pas le total TTC
  bool isMontantRecuValid(double montantRecu, double totalTTC) {
    return montantRecu >= 0 && montantRecu <= totalTTC;
  }

  /// Valide une unité pour un article
  bool isUniteValid(String? unite, Article article) {
    if (unite == null || unite.isEmpty) return false;

    final unitesValides = [
      if (article.u1?.isNotEmpty == true) article.u1,
      if (article.u2?.isNotEmpty == true) article.u2,
      if (article.u3?.isNotEmpty == true) article.u3,
    ].whereType<String>().toList();

    return unitesValides.contains(unite);
  }

  /// Valide un dépôt existe dans la base
  Future<bool> isDepotValid(String depot) async {
    if (depot.isEmpty) return false;

    try {
      final depots = await _databaseService.getAllDepots();
      return depots.any((d) => d.depots == depot);
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si le statut de vente est brouillard
  bool isVenteBrouillard(StatutVente? statut) {
    return statut == StatutVente.brouillard;
  }

  /// Vérifie si la vente peut être contrepassée
  Future<bool> canCounterpassSale(String numVentes) async {
    if (numVentes.isEmpty) return false;

    try {
      final ventes = await _databaseService.getVentesWithModeAwareness();
      final vente = ventes.firstWhere((v) => v['numventes'] == numVentes, orElse: () => {});
      return vente.isNotEmpty && vente['contre'] != '1';
    } catch (e) {
      return false;
    }
  }

  /// Valide la modification d'une ligne brouillard
  bool canModifyDraftLine(StatutVente? statut) {
    return isVenteBrouillard(statut);
  }

  /// Vérifie si une vente existante peut être modifiée
  bool canModifyVente(bool isExistingPurchase, StatutVente? statut) {
    return isExistingPurchase && isVenteBrouillard(statut);
  }
}
