# Architecture InventaireModal - Audit Complet

## 📊 Vue d'ensemble

**Fichier principal**: `lib/widgets/modals/inventaire_modal.dart`
- **Taille**: 2504 lignes
- **Classes**: 2 (InventaireModal, _InventaireModalState)
- **Mixins**: TickerProviderStateMixin, LoadingMixin
- **État global**: 40+ variables

---

## 🏗️ Structure Actuelle

### Hiérarchie Widget
```
Dialog (PopScope)
├─ ScaffoldMessenger
│  └─ Scaffold
│     └─ Column
│        ├─ _buildHeader() → 40 lignes
│        ├─ _buildTabBar() → 20 lignes
│        └─ TabBarView (4 onglets)
│           ├─ _buildStockTab() → ReusableWidget(StockTab)
│           ├─ _buildInventaireTab() → Custom Column
│           ├─ _buildMouvementsTab() → Custom Column
│           └─ _buildRapportsTab() → ReusableWidget(RapportsTab)
```

### Distribution des Responsabilités (Analyse Lignes)

| Composant | Lignes | % | Responsabilité |
|-----------|--------|---|-----------------|
| **Gestion État Global** | 100 | 4% | initState, dispose, variables d'état |
| **Chargement Données** | 120 | 5% | _loadData*, _loadArticles*, _processMetadata* |
| **Filtrage & Recherche** | 180 | 7% | _applyFilters*, _applyMouvementsFilters() |
| **Tab Stock** | 450 | 18% | _buildStockTab(), buildArticleRow(), pagination |
| **Tab Inventaire** | 650 | 26% | _buildInventaireTab(), _buildInventaireListItem(), saisie |
| **Tab Mouvements** | 480 | 19% | _buildMouvementsTab(), _buildMouvementListItem(), filtres |
| **Tab Rapports** | 50 | 2% | Délégué à RapportsTab (widget séparé) |
| **Exports Excel/PDF** | 380 | 15% | _exportStock(), _exportToExcel(), _exportToPdf() |
| **Gestion Erreurs** | 40 | 2% | _showError(), _showSuccess() |
| **Utilitaires** | 24 | 1% | _isVendeur(), _getController(), _scrollToArticle() |

---

## 📋 État Global - 40+ Variables

### Données Principales
```dart
List<Article> _articles = [];                    // Tous les articles
List<Article> _filteredArticles = [];            // Filtrés
List<DepartData> stock = [];                     // Stocks par dépôt
List<Stock> _mouvements = [];                    // Historique
List<Stock> _filteredMouvements = [];            // Filtrés
```

### État UI - Stock Tab
```dart
String _searchQuery = '';                        // Recherche
String _selectedDepot = 'Tous';                  // Filtre dépôt
String _selectedCategorie = 'Toutes';            // Filtre catégorie
int _currentPage = 0;                            // Pagination
bool _isLoadingPage = false;                     // Loading flag
bool hasMoreData = true;                         // Pagination state
```

### État UI - Inventaire Tab
```dart
bool _inventaireMode = false;                    // Mode inventaire actif?
DateTime? _dateInventaire;                       // Date de l'inventaire
String _selectedDepotInventaire = '';            // Dépôt inventorié
Map<String, Map<String, double>> _inventairePhysique = {}; // Données saisies
Map<String, TextEditingController> _inventaireControllers = {}; // Controllers
int _inventairePage = 0;                         // Pagination inventaire
bool _isLoadingInventairePage = false;           // Loading flag
```

### État UI - Mouvements Tab
```dart
String _mouvementsSearchQuery = '';              // Recherche
String _selectedMouvementType = 'Tous';          // Filtre type
DateTime? _dateDebutMouvement;                   // Plage dates
DateTime? _dateFinMouvement;                     // Plage dates
int _mouvementsPage = 0;                         // Pagination
bool _isLoadingMouvements = false;               // Loading flag
```

### Cache & Optimisation
```dart
String _lastSearchQuery = '';                    // Cache search
String _lastSelectedCategorie = '';              // Cache categorie
String _lastSelectedDepot = '';                  // Cache depot
List<Article> cachedFilteredArticles = [];       // Cache articles filtrés
```

### Contrôleurs & Focus
```dart
late TabController _tabController;               // 4 onglets
ScrollController _scrollController = ScrollController();
ScrollController _inventaireScrollController = ScrollController();
ScrollController _mouvementsScrollController = ScrollController();
FocusNode _inventaireSearchFocusNode = FocusNode();
```

### Métadonnées
```dart
List<String> _depots = [];                       // Dépôts disponibles
List<String> _categories = [];                   // Catégories
Map<String, dynamic> _companyInfo = {};          // Infos entreprise
Map<String, dynamic> _stats = {};                // Statistiques
```

### Flags Hover
```dart
int? _hoveredStockIndex;                         // Hover stock
int? _hoveredInventaireIndex;                    // Hover inventaire
int? _hoveredMouvementIndex;                     // Hover mouvement
```

### Constantes
```dart
static const int _itemsPerPage = 25;             // Pagination size
final String inventaireSearchQuery = '';         // Inutilisé?
final List<String> _typesMovement = [...];       // Types de mouvements
```

---

## 🔄 Flux de Données

### 1. Initialization
```
initState()
├─ Check permission (_isVendeur)
├─ Create TabController(4 tabs)
└─ _loadData()
    ├─ _loadArticlesAsync()     → getActiveArticles()
    ├─ _loadStocksAsync()       → select depart
    ├─ _loadCompanyInfoAsync()  → select soc
    ├─ _processMetadataAsync()  → depots + categories
    ├─ setState() → update UI
    ├─ _calculateStatsAsync()   → stats
    ├─ _applyFiltersAsync()     → filtrage initial
    └─ _loadMouvementsAsync()   → chargement mouvements
```

### 2. Filtrage
```
User Input (Search/Filter)
├─ setState() → update query
├─ Debounce (300ms)
└─ _applyFiltersAsync()
    ├─ Check cache (search + dept + cat)
    ├─ Batch filter articles (200 items/batch)
    ├─ setState() → update filtered
    └─ Update pagination
```

### 3. Export
```
_exportStock() → showDialog
├─ User chooses format
├─ IF Excel: _exportToExcel()
│  ├─ Create Excel
│  ├─ Add headers + metadata
│  ├─ Populate rows
│  └─ Save to Documents
└─ IF PDF: _exportToPdf()
   ├─ Create PDF
   ├─ Paginate (40 items/page)
   └─ Save to Documents
```

### 4. Inventaire Physique
```
_startInventaire()
├─ Set mode = true
├─ Clear physique map
├─ User saisit données (inventaireControllers)
├─ Optional: _importInventaire() (Excel)
└─ _saveInventaire()
   ├─ Batch insert DB
   └─ Reload _loadData()
```

---

## 🔍 Méthodes par Catégorie

### Lifecycle (3 méthodes)
- `initState()` - Initialization
- `dispose()` - Cleanup
- `build()` - Render

### Chargement Données (4 méthodes)
- `_loadData()` - Orchestration
- `_loadArticlesAsync()` - Articles actifs
- `_loadStocksAsync()` - Stocks par dépôt
- `_loadCompanyInfoAsync()` - Infos entreprise
- `_processMetadataAsync()` - Dépôts + catégories
- `_calculateStatsAsync()` - Statistiques
- `_loadMouvementsAsync()` - Mouvements historiques

### Filtrage (3 méthodes)
- `_applyFilters()` - Wrapper asynce
- `_applyFiltersAsync()` - Logique filtrage articles
- `_applyMouvementsFilters()` - Logique filtrage mouvements

### Tab Stock (5 méthodes)
- `_buildStockTab()` - Wrapper StockTab widget
- `buildArticleRow()` - DataRow pour chaque article
- `_changePage()` - Pagination
- `_scrollController` - Gestion scroll

### Tab Inventaire (8 méthodes)
- `_buildInventaireTab()` - Container column
- `_buildInventaireHeader()` - En-tête + boutons
- `_buildInventaireList()` - Conditional layout
- `_buildVirtualizedInventaireList()` - ListView pagifiée
- `_buildInventaireTableHeader()` - En-têtes colonnes
- `_buildInventaireListItem()` - Row inventaire
- `_startInventaire()` - Activation mode
- `_cancelInventaire()` - Annulation
- `_saveInventaire()` - Sauvegarde DB
- `_importInventaire()` - Import Excel
- `_scrollToArticle()` - Scroll to item
- `_changeInventairePage()` - Pagination

### Tab Mouvements (7 méthodes)
- `_buildMouvementsTab()` - Container column
- `_buildMouvementsHeader()` - En-tête + export
- `_buildMouvementsFilters()` - Filtres (type, date, search)
- `_buildMouvementsList()` - Conditional layout
- `_buildVirtualizedMouvementsList()` - ListView pagifiée
- `_buildMouvementsTableHeader()` - En-têtes colonnes
- `_buildMouvementListItem()` - Row mouvement
- `_changeMouvementsPage()` - Pagination
- `_selectDateRange()` - Date picker
- `_applyMouvementsFilters()` - Filtrage avancé

### Tab Rapports (1 méthode)
- `_buildRapportsTab()` - Délégué à RapportsTab

### Exports (5 méthodes)
- `_exportStock()` - Choose format dialog
- `_exportToExcel()` - Excel generation
- `_exportToPdf()` - PDF generation
- `_exportMouvements()` - Choose format dialog
- `_exportMouvementsToExcel()` - Mouvement Excel
- `_exportMouvementsToPdf()` - Mouvement PDF

### Utilitaires (6 méthodes)
- `_isVendeur()` - Check role
- `_getController()` - Create TextEditingController
- `_showError()` - SnackBar error
- `_showSuccess()` - SnackBar success
- `_scrollToArticle()` - Animate to item
- `_formatStockDisplay()` - Format stock string

### UI Builders Principaux (8 méthodes)
- `build()` - Main widget tree
- `_buildHeader()` - Top header
- `_buildTabBar()` - Tab navigation
- `_buildStockTab()` - Stock content
- `_buildInventaireTab()` - Inventaire content
- `_buildMouvementsTab()` - Mouvements content
- `_buildRapportsTab()` - Rapports content

---

## ⚠️ Problèmes Identifiés

### 1. **État Global Éclaté** (Critique)
- 40+ variables d'état
- Cache dupliquée (_searchQuery + _lastSearchQuery)
- Pas de validation d'état cohérent
- Risque de desynchronisation

**Exemple**:
```dart
_searchQuery = 'test'      // User input
_lastSearchQuery = 'test'  // Cache
_filteredArticles = [...]  // Résultat
// Si l'un de ces 3 desync → bug
```

### 2. **Ressources Non Libérées** (Critique)
```dart
dispose() {
  _tabController.dispose();
  _scrollController.dispose();
  // ❌ Manquent:
  // - _mouvementsScrollController
  // - TextEditingControllers du Tab Mouvements?
  // - FocusNodes additionnels?
}
```

### 3. **Fichier Énorme** (Élevé)
- 2504 lignes = 1 responsabilité = unmaintainable
- Difficile à tester
- Difficile à réutiliser
- Profiling VS Code ralenti

### 4. **setState() Excessif** (Élevé)
- Appelé 25+ fois
- Rebuild entier le Dialog
- Performance: O(n) à chaque filtre
- Pas de granularité

**Occurrences setState()**:
1. `initState` chargement initial
2. `_loadData` metadata update
3. `_applyFiltersAsync` filtrage
4. `_changePage` pagination stock
5. `_applyMouvementsFilters` filtrage mouvements
6. `_changeMouvementsPage` pagination
7. `_changeInventairePage` pagination inventaire
8. `_selectDateRange` date selection
9. + multiples dans callbacks onChanged
10. + hovers (3 index hover)

### 5. **Gestion Erreurs Minimaliste** (Moyen)
```dart
catch (e) {
  _showError('Erreur lors du chargement: $e'); // Générique
  // ❌ Pas de logging
  // ❌ Pas de retry
  // ❌ Pas de distinction erreur type
  // ❌ Pas de stack trace
}
```

### 6. **Logique Métier Mélangée à l'UI** (Moyen)
- Filtrage articles dans State
- Calcul statistiques inline
- Formatage Excel/PDF sans séparation
- Pas de services spécialisés

### 7. **Pas de Tests** (Moyen)
- Aucun test unitaire
- Aucun test widget
- Aucun test de filtrage
- Aucun test d'export

### 8. **Cache Inefficace** (Faible)
```dart
if (_searchQuery == _lastSearchQuery &&
    _selectedCategorie == _lastSelectedCategorie &&
    _selectedDepot == _lastSelectedDepot) {
  return; // Cache hit
}
// Problème: Condition à 3 comparaisons = fragile
```

---

## 📦 Dépendances Externes

### Services/Providers
- `DatabaseService` - Accès DB (articles, stocks, mouvements)
- `AuthService` - Check rôle utilisateur
- `AppDateUtils` - Formatage dates

### Widgets Réutilisés
- `StockTab` (importé de `tabs/stock_tab.dart`)
- `RapportsTab` (importé de `tabs/rapports_tab.dart`)

### Packages
- `excel` - Export Excel
- `file_picker` - Sélection fichiers
- `path_provider` - Accès Documents
- `pdf/widgets` - Export PDF

---

## 🎯 Points Critiques d'Amélioration

| Point | Impact | Effort | Priorité |
|-------|--------|--------|----------|
| **État centralisé** | ⭐⭐⭐⭐⭐ | 4h | 🔴 CRITIQUE |
| **Extraction tabs** | ⭐⭐⭐⭐ | 12h | 🔴 CRITIQUE |
| **Services métier** | ⭐⭐⭐⭐ | 8h | 🟡 ÉLEVÉE |
| **State Management** | ⭐⭐⭐ | 10h | 🟡 ÉLEVÉE |
| **Tests** | ⭐⭐⭐ | 12h | 🟡 ÉLEVÉE |
| **Gestion erreurs** | ⭐⭐ | 4h | 🟢 MOYEN |
| **Documentation** | ⭐ | 3h | 🟢 MOYEN |

---

## ✅ Checklist Phase 1

- [x] Analyser taille fichier & structure
- [x] Dénombrer variables état
- [x] Compter setState() appels
- [x] Identifier méthodes par catégorie
- [x] Documenter flux données
- [x] Lister problèmes critiques
- [x] Identifier dépendances
- [x] Créer matrice responsabilités

---

## 📄 Documents Connexes

- [ARCHITECTURE_CLIENT_SERVEUR.md](../ARCHITECTURE_CLIENT_SERVEUR.md) - Architecture générale app
- [REALTIME_SYNC_GUIDE.md](../REALTIME_SYNC_GUIDE.md) - Sync temps réel
- Plan d'action phase 2 → État centralisé
