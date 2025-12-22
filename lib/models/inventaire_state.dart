import 'package:flutter/material.dart';

import '../database/database.dart';
import 'inventaire_physique.dart';
import 'inventaire_stats.dart';

/// Classe représentant l'état complet et immuable de l'inventaire
///
/// Gère la centralisation de toutes les données et métadonnées pour:
/// - Filtrage des articles (search, dépôt, catégorie)
/// - Pagination (25 articles/page)
/// - Saisie d'inventaire physique
/// - Gestion des mouvements historiques
///
/// Cette classe utilise l'immutabilité pour garantir la cohérence de l'état
/// et faciliter la détection de changements avec Provider.
@immutable
class InventaireState {
  // === DONNÉES PRINCIPALES ===
  final List<Article> articles;
  final List<DepartData> stocks;
  final List<Stock> mouvements;

  // === ARTICLES FILTRÉS ===
  final List<Article> filteredArticles;
  final List<Stock> filteredMouvements;

  // === FILTRES STOCK ===
  final String searchQuery;
  final String selectedDepot;
  final String selectedCategorie;

  // === PAGINATION STOCK ===
  final int stockPage;
  final bool stockHasMoreData;

  // === INVENTAIRE PHYSIQUE ===
  final Map<String, InventairePhysique> physique;
  final DateTime? dateInventaire;
  final bool inventaireMode;
  final String selectedDepotInventaire;
  final int inventairePage;

  // === PAGINATION INVENTAIRE ===
  final int itemsPerPage;

  // === FILTRES MOUVEMENTS ===
  final String mouvementsSearchQuery;
  final String selectedMouvementType;
  final DateTimeRange? dateRangeMouvement;

  // === PAGINATION MOUVEMENTS ===
  final int mouvementsPage;

  // === ÉTATS DE CHARGEMENT ===
  final bool isLoading;
  final bool isLoadingPage;
  final bool isLoadingMouvements;
  final bool isLoadingInventairePage;

  // === MÉTADONNÉES ===
  final List<String> depots;
  final List<String> categories;
  final Map<String, dynamic> companyInfo;

  // === STATISTIQUES ===
  final InventaireStats stats;

  // === GESTION ERREURS ===
  final String? errorMessage;

  // === STATES DE HOVER ===
  final int? hoveredStockIndex;
  final int? hoveredInventaireIndex;
  final int? hoveredMouvementIndex;

  const InventaireState({
    required this.articles,
    required this.stocks,
    required this.mouvements,
    required this.filteredArticles,
    required this.filteredMouvements,
    required this.searchQuery,
    required this.selectedDepot,
    required this.selectedCategorie,
    required this.stockPage,
    required this.stockHasMoreData,
    required this.physique,
    required this.dateInventaire,
    required this.inventaireMode,
    required this.selectedDepotInventaire,
    required this.inventairePage,
    required this.itemsPerPage,
    required this.mouvementsSearchQuery,
    required this.selectedMouvementType,
    required this.dateRangeMouvement,
    required this.mouvementsPage,
    required this.isLoading,
    required this.isLoadingPage,
    required this.isLoadingMouvements,
    required this.isLoadingInventairePage,
    required this.depots,
    required this.categories,
    required this.companyInfo,
    required this.stats,
    required this.errorMessage,
    required this.hoveredStockIndex,
    required this.hoveredInventaireIndex,
    required this.hoveredMouvementIndex,
  });

  /// État initial vierge
  factory InventaireState.initial() {
    return InventaireState(
      articles: [],
      stocks: [],
      mouvements: [],
      filteredArticles: [],
      filteredMouvements: [],
      searchQuery: '',
      selectedDepot: 'Tous',
      selectedCategorie: 'Toutes',
      stockPage: 0,
      stockHasMoreData: false,
      physique: {},
      dateInventaire: null,
      inventaireMode: false,
      selectedDepotInventaire: '',
      inventairePage: 0,
      itemsPerPage: 25,
      mouvementsSearchQuery: '',
      selectedMouvementType: 'Tous',
      dateRangeMouvement: null,
      mouvementsPage: 0,
      isLoading: true,
      isLoadingPage: false,
      isLoadingMouvements: false,
      isLoadingInventairePage: false,
      depots: [],
      categories: [],
      companyInfo: {},
      stats: InventaireStats.zero(),
      errorMessage: null,
      hoveredStockIndex: null,
      hoveredInventaireIndex: null,
      hoveredMouvementIndex: null,
    );
  }

  /// Crée une copie avec modifications (immutable pattern)
  InventaireState copyWith({
    List<Article>? articles,
    List<DepartData>? stocks,
    List<Stock>? mouvements,
    List<Article>? filteredArticles,
    List<Stock>? filteredMouvements,
    String? searchQuery,
    String? selectedDepot,
    String? selectedCategorie,
    int? stockPage,
    bool? stockHasMoreData,
    Map<String, InventairePhysique>? physique,
    DateTime? dateInventaire,
    bool? inventaireMode,
    String? selectedDepotInventaire,
    int? inventairePage,
    int? itemsPerPage,
    String? mouvementsSearchQuery,
    String? selectedMouvementType,
    DateTimeRange? dateRangeMouvement,
    int? mouvementsPage,
    bool? isLoading,
    bool? isLoadingPage,
    bool? isLoadingMouvements,
    bool? isLoadingInventairePage,
    List<String>? depots,
    List<String>? categories,
    Map<String, dynamic>? companyInfo,
    InventaireStats? stats,
    String? errorMessage,
    int? hoveredStockIndex,
    int? hoveredInventaireIndex,
    int? hoveredMouvementIndex,
  }) {
    return InventaireState(
      articles: articles ?? this.articles,
      stocks: stocks ?? this.stocks,
      mouvements: mouvements ?? this.mouvements,
      filteredArticles: filteredArticles ?? this.filteredArticles,
      filteredMouvements: filteredMouvements ?? this.filteredMouvements,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDepot: selectedDepot ?? this.selectedDepot,
      selectedCategorie: selectedCategorie ?? this.selectedCategorie,
      stockPage: stockPage ?? this.stockPage,
      stockHasMoreData: stockHasMoreData ?? this.stockHasMoreData,
      physique: physique ?? this.physique,
      dateInventaire: dateInventaire ?? this.dateInventaire,
      inventaireMode: inventaireMode ?? this.inventaireMode,
      selectedDepotInventaire: selectedDepotInventaire ?? this.selectedDepotInventaire,
      inventairePage: inventairePage ?? this.inventairePage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      mouvementsSearchQuery: mouvementsSearchQuery ?? this.mouvementsSearchQuery,
      selectedMouvementType: selectedMouvementType ?? this.selectedMouvementType,
      dateRangeMouvement: dateRangeMouvement ?? this.dateRangeMouvement,
      mouvementsPage: mouvementsPage ?? this.mouvementsPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingPage: isLoadingPage ?? this.isLoadingPage,
      isLoadingMouvements: isLoadingMouvements ?? this.isLoadingMouvements,
      isLoadingInventairePage: isLoadingInventairePage ?? this.isLoadingInventairePage,
      depots: depots ?? this.depots,
      categories: categories ?? this.categories,
      companyInfo: companyInfo ?? this.companyInfo,
      stats: stats ?? this.stats,
      errorMessage: errorMessage ?? this.errorMessage,
      hoveredStockIndex: hoveredStockIndex ?? this.hoveredStockIndex,
      hoveredInventaireIndex: hoveredInventaireIndex ?? this.hoveredInventaireIndex,
      hoveredMouvementIndex: hoveredMouvementIndex ?? this.hoveredMouvementIndex,
    );
  }

  /// Propriétés dérivées (computed)

  /// Nombre total de pages pour le tab Stock
  int get totalStockPages => (filteredArticles.length / itemsPerPage).ceil();

  /// Indice de la première ligne du stock sur la page actuelle
  int get stockPageStartIndex => stockPage * itemsPerPage;

  /// Indice de la dernière ligne du stock sur la page actuelle
  int get stockPageEndIndex => (stockPageStartIndex + itemsPerPage).clamp(0, filteredArticles.length);

  /// Articles affichés sur la page actuelle
  List<Article> get stockPageItems => filteredArticles.sublist(stockPageStartIndex, stockPageEndIndex);

  /// Nombre total de pages pour le tab Inventaire
  int get totalInventairePages => (filteredArticles.length / itemsPerPage).ceil();

  /// Indice de la première ligne de l'inventaire sur la page actuelle
  int get inventairePageStartIndex => inventairePage * itemsPerPage;

  /// Indice de la dernière ligne de l'inventaire sur la page actuelle
  int get inventairePageEndIndex =>
      (inventairePageStartIndex + itemsPerPage).clamp(0, filteredArticles.length);

  /// Articles affichés pour l'inventaire sur la page actuelle
  List<Article> get inventairePageItems =>
      filteredArticles.sublist(inventairePageStartIndex, inventairePageEndIndex);

  /// Nombre total de pages pour le tab Mouvements
  int get totalMouvementsPages => (filteredMouvements.length / itemsPerPage).ceil();

  /// Indice de la première ligne des mouvements sur la page actuelle
  int get mouvementsPageStartIndex => mouvementsPage * itemsPerPage;

  /// Indice de la dernière ligne des mouvements sur la page actuelle
  int get mouvementsPageEndIndex =>
      (mouvementsPageStartIndex + itemsPerPage).clamp(0, filteredMouvements.length);

  /// Mouvements affichés sur la page actuelle
  List<Stock> get mouvementsPageItems =>
      filteredMouvements.sublist(mouvementsPageStartIndex, mouvementsPageEndIndex);

  /// Nombre d'articles en cours de saisie d'inventaire
  int get inventaireItemsCount => physique.length;

  /// Nombre d'écarts détectés
  int get ecartCount => physique.values.where((inv) => inv.hasEcart).length;

  /// Booléen: Doit-on afficher le bouton "Continuer" pour inventaire?
  bool get canSaveInventaire => inventaireMode && physique.isNotEmpty;

  @override
  String toString() =>
      '''
InventaireState(
  articles: ${articles.length},
  filteredArticles: ${filteredArticles.length},
  searchQuery: '$searchQuery',
  selectedDepot: '$selectedDepot',
  stockPage: $stockPage,
  inventaireMode: $inventaireMode,
  physique: ${physique.length},
  isLoading: $isLoading,
)
  ''';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventaireState &&
          runtimeType == other.runtimeType &&
          articles == other.articles &&
          stocks == other.stocks &&
          mouvements == other.mouvements &&
          filteredArticles == other.filteredArticles &&
          filteredMouvements == other.filteredMouvements &&
          searchQuery == other.searchQuery &&
          selectedDepot == other.selectedDepot &&
          selectedCategorie == other.selectedCategorie &&
          stockPage == other.stockPage &&
          stockHasMoreData == other.stockHasMoreData &&
          physique == other.physique &&
          dateInventaire == other.dateInventaire &&
          inventaireMode == other.inventaireMode &&
          selectedDepotInventaire == other.selectedDepotInventaire &&
          inventairePage == other.inventairePage &&
          itemsPerPage == other.itemsPerPage &&
          mouvementsSearchQuery == other.mouvementsSearchQuery &&
          selectedMouvementType == other.selectedMouvementType &&
          dateRangeMouvement == other.dateRangeMouvement &&
          mouvementsPage == other.mouvementsPage &&
          isLoading == other.isLoading &&
          isLoadingPage == other.isLoadingPage &&
          isLoadingMouvements == other.isLoadingMouvements &&
          isLoadingInventairePage == other.isLoadingInventairePage &&
          depots == other.depots &&
          categories == other.categories &&
          companyInfo == other.companyInfo &&
          stats == other.stats &&
          errorMessage == other.errorMessage &&
          hoveredStockIndex == other.hoveredStockIndex &&
          hoveredInventaireIndex == other.hoveredInventaireIndex &&
          hoveredMouvementIndex == other.hoveredMouvementIndex;

  @override
  int get hashCode =>
      articles.hashCode ^
      stocks.hashCode ^
      mouvements.hashCode ^
      filteredArticles.hashCode ^
      filteredMouvements.hashCode ^
      searchQuery.hashCode ^
      selectedDepot.hashCode ^
      selectedCategorie.hashCode ^
      stockPage.hashCode ^
      stockHasMoreData.hashCode ^
      physique.hashCode ^
      dateInventaire.hashCode ^
      inventaireMode.hashCode ^
      selectedDepotInventaire.hashCode ^
      inventairePage.hashCode ^
      itemsPerPage.hashCode ^
      mouvementsSearchQuery.hashCode ^
      selectedMouvementType.hashCode ^
      dateRangeMouvement.hashCode ^
      mouvementsPage.hashCode ^
      isLoading.hashCode ^
      isLoadingPage.hashCode ^
      isLoadingMouvements.hashCode ^
      isLoadingInventairePage.hashCode ^
      depots.hashCode ^
      categories.hashCode ^
      companyInfo.hashCode ^
      stats.hashCode ^
      errorMessage.hashCode ^
      hoveredStockIndex.hashCode ^
      hoveredInventaireIndex.hashCode ^
      hoveredMouvementIndex.hashCode;
}
