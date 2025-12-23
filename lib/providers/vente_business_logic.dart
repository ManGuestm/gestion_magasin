import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/vente_state.dart';
import '../providers/vente_providers.dart';
import '../services/price_calculation_service.dart';
import '../services/stock_management_service.dart';
import '../services/vente_validation_service.dart';
import '../utils/focus_node_manager.dart';

/// Wrapper Riverpod qui encapsule la logique des ventes
/// Permet à ventes_modal.dart d'être plus simple et réactif
class VenteBusinessLogic {
  final Ref ref;
  final FocusNodeManager focusNodeManager;
  late final VenteValidationService validationService;
  late final PriceCalculationService priceService;
  late final StockManagementService stockService;

  VenteBusinessLogic({required this.ref, required this.focusNodeManager}) {
    validationService = ref.read(venteValidationServiceProvider);
    priceService = ref.read(priceCalculationServiceProvider);
    stockService = ref.read(stockManagementServiceProvider);
  }

  /// Valide qu'une ligne peut être ajoutée
  bool validateLineForAddition({
    required Article? article,
    required double quantite,
    required double prix,
    required String? unite,
  }) {
    if (article == null) return false;
    if (!validationService.isQuantiteValid(quantite)) return false;
    if (!validationService.isPrixValid(prix)) return false;
    if (!validationService.isUniteValid(unite, article)) return false;
    return true;
  }

  /// Valide la vente complète avant soumission
  bool validateCompleteSale({
    required List<Map<String, dynamic>> lignesVente,
    required String? clientName,
    required double totalTTC,
  }) {
    if (!validationService.isClientSelected(clientName)) return false;
    if (!validationService.hasValidLines(lignesVente)) return false;
    return totalTTC > 0;
  }

  /// Calcule les totaux de la vente
  Map<String, double> calculateTotals({
    required List<Map<String, dynamic>> lignesVente,
    required double remisePercentage,
    required double avance,
  }) {
    final totalHT = priceService.calculateTotalHT(lignesVente);
    final totalTTC = priceService.calculateTotalTTC(totalHT, remisePercentage);
    final reste = priceService.calculateReste(totalTTC, avance);

    return {
      'totalHT': totalHT,
      'totalTTC': totalTTC,
      'reste': reste,
      'remiseAmount': priceService.calculateRemiseAmount(totalHT, remisePercentage),
    };
  }

  /// Vérifie le stock disponible pour un article
  Future<bool> checkStockAvailability({
    required Article article,
    required String depot,
    required double quantity,
    required String unite,
  }) async {
    final hasStock = await stockService.verifierStockSuffisant(article.designation, depot, quantity);
    return hasStock;
  }

  /// Récupère les stocks pour tous les dépôts
  Future<Map<String, double>> getStockInOtherDepots({
    required Article article,
    required String currentDepot,
  }) async {
    final allStocks = await stockService.getStockParDepot(article.designation);
    final filtered = <String, double>{};
    allStocks.forEach((depot, stock) {
      if (depot != currentDepot) filtered[depot] = stock;
    });
    return filtered;
  }

  /// Formate les unités disponibles pour affichage
  String formatAvailableUnits(Article article) {
    // Format: "u1 (qty1) / u2 (qty2) / u3 (qty3)"
    final units = <String>[];
    if (article.u1 != null && (article.stocksu1 ?? 0) > 0) {
      units.add('${article.u1} (${article.stocksu1})');
    }
    if (article.u2 != null && (article.stocksu2 ?? 0) > 0) {
      units.add('${article.u2} (${article.stocksu2})');
    }
    if (article.u3 != null && (article.stocksu3 ?? 0) > 0) {
      units.add('${article.u3} (${article.stocksu3})');
    }
    return units.join(' / ');
  }

  /// Ajoute une ligne de vente à l'état
  void addLineToState(Map<String, dynamic> ligne) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.addLine(ligne);
  }

  /// Supprime une ligne de vente de l'état
  void removeLineFromState(int index) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.removeLine(index);
  }

  /// Met à jour une ligne de vente dans l'état
  void updateLineInState(int index, Map<String, dynamic> ligne) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.updateLine(index, ligne);
  }

  /// Met à jour l'article sélectionné
  void setSelectedArticle(Article? article) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.updateSelectedArticle(article);
  }

  /// Met à jour l'unité sélectionnée
  void setSelectedUnite(String? unite) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.updateSelectedUnite(unite);
  }

  /// Met à jour le dépôt sélectionné
  void setSelectedDepot(String? depot) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.updateSelectedDepot(depot);
  }

  /// Met à jour le client sélectionné
  void setClientName(String? clientName) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.updateClientName(clientName);
  }

  /// Met à jour le mode de paiement
  void setModePaiement(String modePaiement) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.updateModePaiement(modePaiement);
  }

  /// Commence la modification d'une ligne
  void startModifyingLine(int index) {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.startModifyingLine(index);
  }

  /// Annule la modification d'une ligne
  void cancelModifyingLine() {
    final stateNotifier = ref.read(venteStateNotifierProvider.notifier);
    stateNotifier.cancelModifyingLine();
  }

  /// Obtient l'état actuel des ventes
  VenteState? getVenteState() {
    return ref.read(venteStateNotifierProvider);
  }

  /// Demande le focus au champ client
  void focusOnClient() {
    focusNodeManager.focusOnClient();
  }

  /// Demande le focus au champ quantité
  void focusOnQuantite() {
    focusNodeManager.focusOnQuantite();
  }

  /// Navigue au champ suivant
  void focusNext() {
    focusNodeManager.focusNext();
  }

  /// Navigue au champ précédent
  void focusPrevious() {
    focusNodeManager.focusPrevious();
  }
}

/// Provider pour accéder à la logique métier
final venteBusinessLogicProvider = Provider((ref) {
  final focusManager = FocusNodeManager();
  return VenteBusinessLogic(ref: ref, focusNodeManager: focusManager);
});
