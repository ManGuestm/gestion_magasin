import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../database/database_service.dart';
import '../models/vente_state.dart';
import '../services/price_calculation_service.dart';
import '../services/stock_management_service.dart';
import '../services/vente_validation_service.dart';
import '../utils/cache_service.dart';

// ============================================================================
// PROVIDERS POUR LES SERVICES
// ============================================================================

/// Provider pour le service de validation
final venteValidationServiceProvider = Provider<VenteValidationService>((ref) {
  return VenteValidationService();
});

/// Provider pour le service de calcul de prix
final priceCalculationServiceProvider = Provider<PriceCalculationService>((ref) {
  return PriceCalculationService();
});

/// Provider pour le service de gestion des stocks
final stockManagementServiceProvider = Provider<StockManagementService>((ref) {
  return StockManagementService();
});

/// Provider pour la base de données
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// ============================================================================
// PROVIDERS POUR LES DONNÉES
// ============================================================================

/// Provider pour tous les articles
final articlesProvider = FutureProvider<List<Article>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getAllArticles();
});

/// Provider pour tous les clients
final clientsProvider = FutureProvider<List<CltData>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getAllClients();
});

/// Provider pour tous les dépôts
final depotsProvider = FutureProvider<List<Depot>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getAllDepots();
});

/// Provider pour les ventes avec statut
final ventesAvecStatutProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final cache = CacheService<List<Map<String, dynamic>>>(cacheDuration: const Duration(seconds: 30));

  return cache.getOrLoad(() async {
    final ventes = await dbService.getVentesWithModeAwareness();
    return ventes;
  });
});

/// Provider pour un article spécifique
final articleByNameProvider = FutureProvider.family<Article?, String>((ref, designation) async {
  final dbService = ref.watch(databaseServiceProvider);
  try {
    final articles = await dbService.getAllArticles();
    return articles.firstWhere((a) => a.designation == designation);
  } catch (e) {
    return null;
  }
});

/// Provider pour les stocks d'un article dans un dépôt
final articleStockProvider = FutureProvider.family<Map<String, double>, ({Article article, String depot})>((
  ref,
  params,
) async {
  final stockService = ref.watch(stockManagementServiceProvider);
  return stockService.getStockParDepot(params.article.designation);
});

/// Provider pour un client par nom
final clientByNameProvider = FutureProvider.family<CltData?, String>((ref, clientName) async {
  final dbService = ref.watch(databaseServiceProvider);
  try {
    final clients = await dbService.getAllClients();
    return clients.firstWhere((c) => c.rsoc == clientName);
  } catch (e) {
    return null;
  }
});

/// Provider pour le solde d'un client
final clientBalanceProvider = FutureProvider.family<double, String>((ref, clientName) async {
  try {
    final client = await ref.watch(clientByNameProvider(clientName).future);
    return client?.soldes ?? 0.0;
  } catch (e) {
    return 0.0;
  }
});

// ============================================================================
// STATE NOTIFIERS
// ============================================================================

/// StateNotifier pour gérer l'état des ventes
class VenteStateNotifier extends StateNotifier<VenteState?> {
  VenteStateNotifier() : super(null);

  void setState(VenteState newState) {
    state = newState;
  }

  void updateSelectedArticle(Article? article) {
    if (state == null) return;
    state = state!.copyWith(selectedArticle: article);
  }

  void updateSelectedUnite(String? unite) {
    if (state == null) return;
    state = state!.copyWith(selectedUnite: unite);
  }

  void updateSelectedDepot(String? depot) {
    if (state == null) return;
    state = state!.copyWith(selectedDepot: depot);
  }

  void updateClientName(String? clientName) {
    if (state == null) return;
    state = state!.copyWith(clientName: clientName);
  }

  void updateModePaiement(String modePaiement) {
    if (state == null) return;
    state = state!.copyWith(modePaiement: modePaiement);
  }

  void addLine(Map<String, dynamic> ligne) {
    if (state == null) return;
    state = state!.addLine(ligne);
  }

  void removeLine(int index) {
    if (state == null) return;
    state = state!.removeLine(index);
  }

  void updateLine(int index, Map<String, dynamic> ligne) {
    if (state == null) return;
    state = state!.updateLine(index, ligne);
  }

  void clearLines() {
    if (state == null) return;
    state = state!.clearLines();
  }

  void startModifyingLine(int index) {
    if (state == null || index < 0 || index >= state!.lignesVente.length) return;
    state = state!.copyWith(
      isModifyingLine: true,
      modifyingLineIndex: index,
      originalLineData: Map<String, dynamic>.from(state!.lignesVente[index]),
    );
  }

  void cancelModifyingLine() {
    if (state == null) return;
    state = state!.resetModification();
  }

  void updateStockInfo(double disponible, bool insuffisant, String uniteAffichage) {
    if (state == null) return;
    state = state!.copyWith(
      stockDisponible: disponible,
      stockInsuffisant: insuffisant,
      uniteAffichage: uniteAffichage,
    );
  }

  void updateSoldeAnterieur(double solde) {
    if (state == null) return;
    state = state!.copyWith(soldeAnterieur: solde);
  }

  void resetForm(String newNumVentes, String newNumBL, DateTime newDate) {
    if (state == null) return;
    state = state!.reset(newNumVentes: newNumVentes, newNumBL: newNumBL, newDate: newDate);
  }
}

/// Provider StateNotifier pour l'état des ventes
final venteStateNotifierProvider = StateNotifierProvider<VenteStateNotifier, VenteState?>((ref) {
  return VenteStateNotifier();
});

// ============================================================================
// DERIVED PROVIDERS
// ============================================================================

/// Calcule le total HT à partir de l'état actuel
final totalHTProvider = Provider<double>((ref) {
  final venteState = ref.watch(venteStateNotifierProvider);
  if (venteState == null) return 0.0;

  final priceService = ref.watch(priceCalculationServiceProvider);
  return priceService.calculateTotalHT(venteState.lignesVente);
});

/// Calcule le total TTC à partir de l'état actuel
final totalTTCProvider = Provider<double>((ref) {
  final venteState = ref.watch(venteStateNotifierProvider);
  if (venteState == null) return 0.0;

  final priceService = ref.watch(priceCalculationServiceProvider);
  final totalHT = ref.watch(totalHTProvider);
  final remisePercentage = double.tryParse(venteState.remiseController.text) ?? 0.0;

  return priceService.calculateTotalTTC(totalHT, remisePercentage);
});

/// Calcule le reste à payer
final resteProvider = Provider<double>((ref) {
  final venteState = ref.watch(venteStateNotifierProvider);
  if (venteState == null) return 0.0;

  final priceService = ref.watch(priceCalculationServiceProvider);
  final totalTTC = ref.watch(totalTTCProvider);
  final avance = double.tryParse(venteState.avanceController.text) ?? 0.0;

  return priceService.calculateReste(totalTTC, avance);
});

/// Calcule le nouveau solde client
final newClientBalanceProvider = Provider<double>((ref) {
  final venteState = ref.watch(venteStateNotifierProvider);
  if (venteState == null) return 0.0;

  final priceService = ref.watch(priceCalculationServiceProvider);
  final totalTTC = ref.watch(totalTTCProvider);

  return priceService.calculateNewClientBalance(venteState.soldeAnterieur, totalTTC, venteState.modePaiement);
});

/// Fournit les détails d'un article et ses stocks
final articleDetailsProvider =
    FutureProvider.family<
      ({Article? article, Map<String, double> stocks}),
      ({String designation, String depot})
    >((ref, params) async {
      final article = await ref.watch(articleByNameProvider(params.designation).future);

      final stocks = article != null
          ? await ref.watch(articleStockProvider((article: article, depot: params.depot)).future)
          : <String, double>{};

      return (article: article, stocks: stocks);
    });
